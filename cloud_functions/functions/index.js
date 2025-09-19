import admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';

admin.initializeApp();
const db = admin.firestore();

export const getTicketInfo = onCall(
  { region: "australia-southeast1" },
  async (request) => {
    try {
      const { ticketId } = request.data;

      if (!ticketId || typeof ticketId !== "string") {
        throw new HttpsError("invalid-argument", "A valid ticketId must be provided.");
      }

      // Optional: restrict to staff accounts only
      // if (!request.auth || request.auth.token?.role !== "staff") {
      //   throw new HttpsError("permission-denied", "Staff only can access ticket details.");
      // }

      const ticketDoc = await db.collection("tickets").doc(ticketId).get();
      if (!ticketDoc.exists) {
        throw new HttpsError("not-found", `Ticket ${ticketId} does not exist`);
      }

      const data = ticketDoc.data();

      // Return only safe fields (hide studentID and anything sensitive)
      const response = {
        id: ticketDoc.id,
        title: data.title || "",
        description: data.description || "",
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
        status: data.status || "open",
      };

      return response;
    } catch (error) {
      console.error("❌ getTicketInfo error:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message || "Failed to fetch ticket");
    }
  }
);

export const updateTicketResolution = onCall(
  { region: "australia-southeast1" },
  async (request) => {
    try {
      const data = request.data || {};
      const { ticketId, resolution } = data;

      // ---------- Validation ----------
      if (!ticketId || typeof ticketId !== "string") {
        throw new HttpsError("invalid-argument", "Invalid or missing ticketId");
      }

      const validResolutions = ["genuine", "malicious"];
      if (!resolution || !validResolutions.includes(resolution)) {
        throw new HttpsError(
          "invalid-argument",
          "Resolution must be either 'genuine' or 'malicious'"
        );
      }

      // ---------- Auth Check ----------
      // If you want only staff to resolve:
      // if (!request.auth || request.auth.token?.role !== "staff") {
      //   throw new HttpsError("permission-denied", "Staff only");
      // }

      // ---------- Firestore Update ----------
      const ticketRef = db.collection("tickets").doc(ticketId);

      const ticketDoc = await ticketRef.get();
      if (!ticketDoc.exists) {
        throw new HttpsError("not-found", `Ticket ${ticketId} does not exist`);
      }

      await ticketRef.update({
        resolution: resolution,
        status: "resolved",
        resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
        resolvedBy: request.auth?.uid || null, // optional
      });

      console.log(`✅ Ticket ${ticketId} resolved as ${resolution}`);

      return { success: true, ticketId, resolution };
    } catch (error) {
      console.error("❌ Failed to resolve ticket:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message || "Unknown error");
    }
  }
);

/**
 * Callable function that creates a new support ticket
 */
export const createTicket = onCall({ region: 'australia-southeast1' }, async (request) => {
  try {
    const data = request.data;
    const title = data.title;
    const description = data.description;
    const studentId = data.studentID || 'anon';

    // ---------- Validation ----------
    if (!title || typeof title !== 'string' || title.length > 200) {
      throw new HttpsError('invalid-argument', 'Title must be provided (1-200 chars)');
    }
    if (!description || typeof description !== 'string' || description.length > 2000) {
      throw new HttpsError('invalid-argument', 'Description must be provided (1-2000 chars)');
    }

    const studentDoc = await db.collection('students').doc(studentId).get();
    if (!studentDoc.exists && studentId !== 'anon') {
      throw new HttpsError('invalid-argument', `Student ID "${studentId}" not found`);
    }
    
    // Default structure for new ticket
    const newTicket = {
      title: title,
      description: description,
      studentID: studentId,
      status: 'open',
      resolution: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      closedAt: null,
      resolved_by: null,
    };

    // Insert into Firestore
    const docRef = await db.collection('tickets').add(newTicket);
    console.log(`✅ Created ticket ${docRef.id} for student ${studentId}`);

    return { ticket_id: docRef.id, status: 'open' };
  } catch (error) {
    console.error('❌ Failed to create ticket:', error);
    throw new HttpsError('internal', error.message || 'Failed to create ticket');
  }
});

/**
 * Firestore trigger when ticket status changes
 */
export const onTicketStatusChanged = onDocumentUpdated(
  { region: 'australia-southeast1', document: 'tickets/{ticketId}', maxInstances: 10 },
  async (event) => {
    const ticketId = event.params.ticketId;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // ✅ Validate resolution
    const validResolutions = ['genuine', 'malicious'];
    if (!validResolutions.includes(afterData.resolution)) {
      console.warn(`❌ Ticket ${ticketId} resolved with invalid resolution: ${afterData.resolution}`);
      throw new HttpsError(
        'invalid-argument',
        `Invalid resolution value: ${afterData.resolution}`
      );
    }

    // ✅ Only act when moving into "resolved"
    if (beforeData.status !== 'resolved' && afterData.status === 'resolved') {
      console.log(`Ticket ${ticketId} has been resolved.`);

      const studentId = afterData.studentID || 'anon';
      if (studentId === 'anon') return null;

      try {
        // 1. Reference student + subcollection
        const studentRef = db.collection('students').doc(studentId);
        const studentTicketRef = studentRef.collection('tickets').doc(ticketId);

        const studentTicketData = {
          ticketId,
          title: afterData.title,
          description: afterData.description,
          status: afterData.status,
          resolution: afterData.resolution,
          createdAt: afterData.createdAt,
          resolvedAt: admin.firestore.Timestamp.now(),
        };

        // 2. Fetch all previous tickets (resolved already) for this student
        const studentTicketsSnapshot = await studentRef
          .collection('tickets')
          .orderBy('resolvedAt', 'desc')
          .get();

        // 3. Assemble "all tickets" INCLUDING the current one
        //    → Append manually since it won’t exist in DB until after commit
        const allTickets = [...studentTicketsSnapshot.docs, { data: () => studentTicketData }];

        // 4. Calculate trust factor based on full history (including this resolution)
        const newTrustFactor = calculateTrustFactor(allTickets, afterData.resolution);

        // 5. Run all updates in a batch
        const batch = db.batch();

        // Save this ticket into the student's tickets subcollection
        batch.set(studentTicketRef, studentTicketData);

        // Update trust stats on the student doc
        batch.update(studentRef, {
          trust_factor: newTrustFactor,
          last_ticket_date: admin.firestore.FieldValue.serverTimestamp(),
          total_tickets: admin.firestore.FieldValue.increment(1),
          [`ticket_stats.${afterData.resolution}`]: admin.firestore.FieldValue.increment(1),
        });

        // Append a trust history log
        batch.update(studentRef, {
          trust_history: admin.firestore.FieldValue.arrayUnion({
            date: admin.firestore.Timestamp.now(),
            factor: newTrustFactor,
            ticket_id: ticketId,
            change_reason: afterData.resolution,
          }),
        });

        await batch.commit();
        console.log(`✅ Updated trust factor for student ${studentId} → ${newTrustFactor}`);
        return { success: true, newTrustFactor };
      } catch (error) {
        console.error('❌ Error updating trust factor:', error);
        throw new HttpsError('internal', 'Failed to update trust factor');
      }
    }

    return null;
  }
);

// ---------- Trust Factor Calculation --------------
function calculateTrustFactor(ticketDocs, currentResolution) {
  const MIN_TRUST = 0.0;
  const MAX_TRUST = 1.0;

  // Count all tickets
  let genuineCount = 0;
  let maliciousCount = 0;

  ticketDocs.forEach(doc => {
    const resolution = doc.data().resolution;
    if (resolution === "genuine") genuineCount++;
    else if (resolution === "malicious") maliciousCount++;
  });

  // Net score (#genuine - #malicious)
  const netScore = genuineCount - maliciousCount;

  // Logistic growth parameters
  const k = 0.6;      // steepness of curve
  const x0 = 0;       // midpoint bias
  let trustFactor = MIN_TRUST + (MAX_TRUST - MIN_TRUST) /
    (1 + Math.exp(-k * (netScore - x0)));

  // --- Optional streak adjustments (based on most recent 5) ---
  const recentTickets = ticketDocs.slice(0, Math.min(5, ticketDocs.length)); 
  const recentGenuine = recentTickets.filter(doc => doc.data().resolution === 'genuine').length;

  if (recentTickets.length >= 3) {
    if (recentGenuine === recentTickets.length) {
      trustFactor += 0.05; // reward consistent honesty
    } else if (recentGenuine === 0) {
      trustFactor -= 0.1; // penalize consistent maliciousness
    }
  }

  // Clamp to [0,1]
  trustFactor = Math.max(MIN_TRUST, Math.min(MAX_TRUST, trustFactor));

  return trustFactor;
}