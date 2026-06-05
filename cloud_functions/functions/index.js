import admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { beforeUserCreated } from "firebase-functions/v2/identity";

admin.initializeApp();

const db = admin.firestore();

const REGION = "australia-southeast1";

const VALID_CATEGORIES = [
  "bullying",
  "harassment",
  "safety",
  "other",
] as const;

type Category = typeof VALID_CATEGORIES[number];

// ============================================================================
// AUTH FUNCTIONS
// ============================================================================

export const beforeCreated = beforeUserCreated(async (event) => {
  const user = event.data;

  if (!user) return;

  user.customClaims = {
    ...user.customClaims,
    role: "default",
  };

  console.log(
    `Setting custom claim 'role: default' for user: ${user.uid}`
  );

  return user;
});

export const checkUserRole = onCall(
  { region: REGION },
  async (request) => {
    try {
      if (!request.auth) {
        return { allowed: false };
      }

      const userRecord = await admin
        .auth()
        .getUser(request.auth.uid);

      const claims = userRecord.customClaims || {};
      const role = claims.role;

      return {
        allowed: role === "staff" || role === "admin",
      };
    } catch (error) {
      console.error("Error checking user role:", error);

      throw new HttpsError(
        "internal",
        "Failed to verify user role"
      );
    }
  }
);

// ============================================================================
// TICKET FUNCTIONS
// ============================================================================

export const createTicket = onCall(
  { region: REGION },
  async (request) => {
    try {
      const data = request.data || {};

      const title = data.title;
      const description = data.description;
      const studentId = data.studentID || "anon";

      if (
        !title ||
        typeof title !== "string" ||
        title.length > 200
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Title must be provided (1-200 chars)"
        );
      }

      if (
        !description ||
        typeof description !== "string" ||
        description.length > 2000
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Description must be provided (1-2000 chars)"
        );
      }

      if (studentId !== "anon") {
        const studentDoc = await db
          .collection("students")
          .doc(studentId)
          .get();

        if (!studentDoc.exists) {
          throw new HttpsError(
            "invalid-argument",
            `Student ID "${studentId}" not found`
          );
        }
      }

      const newTicket = {
        title,
        description,
        studentID: studentId,
        status: "open",
        resolution: null,
        createdAt:
          admin.firestore.FieldValue.serverTimestamp(),
        closedAt: null,
        resolvedAt: null,
        resolvedBy: null,
      };

      const docRef = await db
        .collection("tickets")
        .add(newTicket);

      console.log(
        `Created ticket ${docRef.id} for student ${studentId}`
      );

      return {
        ticket_id: docRef.id,
        status: "open",
      };
    } catch (error: any) {
      console.error("Failed to create ticket:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error?.message || "Failed to create ticket"
      );
    }
  }
);

export const getTicketInfo = onCall(
  { region: REGION },
  async (request) => {
    try {
      const { ticketId } = request.data;

      if (
        !ticketId ||
        typeof ticketId !== "string"
      ) {
        throw new HttpsError(
          "invalid-argument",
          "A valid ticketId must be provided."
        );
      }

      const ticketDoc = await db
        .collection("tickets")
        .doc(ticketId)
        .get();

      if (!ticketDoc.exists) {
        throw new HttpsError(
          "not-found",
          `Ticket ${ticketId} does not exist`
        );
      }

      const data = ticketDoc.data()!;

      return {
        id: ticketDoc.id,
        title: data.title || "",
        description: data.description || "",
        createdAt: data.createdAt
          ? data.createdAt.toDate().toISOString()
          : null,
        status: data.status || "open",
      };
    } catch (error: any) {
      console.error("getTicketInfo error:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error?.message || "Failed to fetch ticket"
      );
    }
  }
);

export const updateTicketResolution = onCall(
  { region: REGION },
  async (request) => {
    try {
      const { ticketId, resolution } =
        request.data || {};

      if (
        !ticketId ||
        typeof ticketId !== "string"
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Invalid or missing ticketId"
        );
      }

      const validResolutions = [
        "genuine",
        "malicious",
      ];

      if (
        !resolution ||
        !validResolutions.includes(resolution)
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Resolution must be either 'genuine' or 'malicious'"
        );
      }

      const ticketRef = db
        .collection("tickets")
        .doc(ticketId);

      const ticketDoc = await ticketRef.get();

      if (!ticketDoc.exists) {
        throw new HttpsError(
          "not-found",
          `Ticket ${ticketId} does not exist`
        );
      }

      await ticketRef.update({
        resolution,
        status: "resolved",
        resolvedAt:
          admin.firestore.FieldValue.serverTimestamp(),
        resolvedBy: request.auth?.uid || null,
      });

      return {
        success: true,
        ticketId,
        resolution,
      };
    } catch (error: any) {
      console.error(
        "Failed to resolve ticket:",
        error
      );

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error?.message || "Unknown error"
      );
    }
  }
);

// ============================================================================
// TRUST FACTOR TRIGGER
// ============================================================================

export const onTicketStatusChanged =
  onDocumentUpdated(
    {
      region: REGION,
      document: "tickets/{ticketId}",
      maxInstances: 10,
    },
    async (event) => {
      const ticketId = event.params.ticketId;

      const beforeData =
        event.data?.before.data();
      const afterData =
        event.data?.after.data();

      if (!beforeData || !afterData) {
        return null;
      }

      const validResolutions = [
        "genuine",
        "malicious",
      ];

      if (
        afterData.status === "resolved" &&
        !validResolutions.includes(
          afterData.resolution
        )
      ) {
        throw new HttpsError(
          "invalid-argument",
          `Invalid resolution value: ${afterData.resolution}`
        );
      }

      if (
        beforeData.status !== "resolved" &&
        afterData.status === "resolved"
      ) {
        const studentId =
          afterData.studentID || "anon";

        if (studentId === "anon") {
          return null;
        }

        try {
          const studentRef = db
            .collection("students")
            .doc(studentId);

          const studentTicketRef =
            studentRef
              .collection("tickets")
              .doc(ticketId);

          const studentTicketData = {
            ticketId,
            title: afterData.title,
            description: afterData.description,
            status: afterData.status,
            resolution: afterData.resolution,
            createdAt: afterData.createdAt,
            resolvedAt:
              admin.firestore.Timestamp.now(),
          };

          const snapshot = await studentRef
            .collection("tickets")
            .orderBy("resolvedAt", "desc")
            .get();

          const allTickets = [
            ...snapshot.docs,
            {
              data: () => studentTicketData,
            },
          ];

          const newTrustFactor =
            calculateTrustFactor(allTickets);

          const batch = db.batch();

          batch.set(
            studentTicketRef,
            studentTicketData
          );

          batch.update(studentRef, {
            trust_factor: newTrustFactor,
            last_ticket_date:
              admin.firestore.FieldValue.serverTimestamp(),
            total_tickets:
              admin.firestore.FieldValue.increment(
                1
              ),
            [`ticket_stats.${afterData.resolution}`]:
              admin.firestore.FieldValue.increment(
                1
              ),
          });

          batch.update(studentRef, {
            trust_history:
              admin.firestore.FieldValue.arrayUnion(
                {
                  date:
                    admin.firestore.Timestamp.now(),
                  factor: newTrustFactor,
                  ticket_id: ticketId,
                  change_reason:
                    afterData.resolution,
                }
              ),
          });

          await batch.commit();

          return {
            success: true,
            newTrustFactor,
          };
        } catch (error) {
          console.error(error);

          throw new HttpsError(
            "internal",
            "Failed to update trust factor"
          );
        }
      }

      return null;
    }
  );

// ============================================================================
// SCHOOL REPORTING FUNCTIONS
// ============================================================================

export const submitReport = onCall(
  {
    region: REGION,
    enforceAppCheck: false,
  },
  async (request) => {
    const data =
      request.data as Record<string, unknown>;

    const schoolId = asNonEmptyString(
      data,
      "schoolId"
    );

    const title = asNonEmptyString(
      data,
      "title"
    );

    const description = asNonEmptyString(
      data,
      "description"
    );

    const category = asNonEmptyString(
      data,
      "category"
    );

    if (title.length > 120) {
      throw new HttpsError(
        "invalid-argument",
        "title must be 120 characters or fewer."
      );
    }

    if (description.length > 2000) {
      throw new HttpsError(
        "invalid-argument",
        "description must be 2000 characters or fewer."
      );
    }

    if (
      !VALID_CATEGORIES.includes(
        category as Category
      )
    ) {
      throw new HttpsError(
        "invalid-argument",
        `category must be one of: ${VALID_CATEGORIES.join(
          ", "
        )}`
      );
    }

    const bullyNames = parseBullyNames(
      data["bullyNames"]
    );

    const schoolDoc = await db
      .collection("schools")
      .doc(schoolId)
      .get();

    if (!schoolDoc.exists) {
      throw new HttpsError(
        "not-found",
        "School not found."
      );
    }

    const schoolData =
      schoolDoc.data() ?? {};

    if (schoolData.active === false) {
      throw new HttpsError(
        "failed-precondition",
        "This school is not currently active."
      );
    }

    const reportDoc = await db
      .collection("schools")
      .doc(schoolId)
      .collection("reports")
      .add({
        schoolId,
        title,
        description,
        category,
        bullyNames,
        status: "new",
        priority: "normal",
        isFlagged: false,
        submittedAt:
          admin.firestore.FieldValue.serverTimestamp(),
        updatedAt:
          admin.firestore.FieldValue.serverTimestamp(),
        reviewedBy: null,
        notes: null,
        closedAt: null,
        resolvedBy: null,
      });

    return {
      reportId: reportDoc.id,
    };
  }
);

export const getSchoolConfig = onCall(
  {
    region: REGION,
    enforceAppCheck: false,
  },
  async (request) => {
    const data =
      request.data as Record<string, unknown>;

    const schoolId = asNonEmptyString(
      data,
      "schoolId"
    );

    const schoolDoc = await db
      .collection("schools")
      .doc(schoolId)
      .get();

    if (!schoolDoc.exists) {
      throw new HttpsError(
        "not-found",
        `No school found with ID "${schoolId}".`
      );
    }

    const schoolData =
      schoolDoc.data() ?? {};

    return {
      schoolId,
      schoolName:
        (schoolData.name as string) ??
        schoolId,
      active:
        (schoolData.active as boolean) ??
        true,
    };
  }
);

// ============================================================================
// HELPERS
// ============================================================================

function calculateTrustFactor(
  ticketDocs: any[]
): number {
  const MIN_TRUST = 0.0;
  const MAX_TRUST = 1.0;

  let genuineCount = 0;
  let maliciousCount = 0;

  ticketDocs.forEach((doc) => {
    const resolution =
      doc.data().resolution;

    if (resolution === "genuine") {
      genuineCount++;
    } else if (
      resolution === "malicious"
    ) {
      maliciousCount++;
    }
  });

  const netScore =
    genuineCount - maliciousCount;

  const k = 0.6;
  const x0 = 0;

  let trustFactor =
    MIN_TRUST +
    (MAX_TRUST - MIN_TRUST) /
      (1 +
        Math.exp(
          -k * (netScore - x0)
        ));

  const recentTickets =
    ticketDocs.slice(
      0,
      Math.min(5, ticketDocs.length)
    );

  const recentGenuine =
    recentTickets.filter(
      (doc) =>
        doc.data().resolution ===
        "genuine"
    ).length;

  if (recentTickets.length >= 3) {
    if (
      recentGenuine ===
      recentTickets.length
    ) {
      trustFactor += 0.05;
    } else if (recentGenuine === 0) {
      trustFactor -= 0.1;
    }
  }

  return Math.max(
    MIN_TRUST,
    Math.min(MAX_TRUST, trustFactor)
  );
}

function asNonEmptyString(
  data: Record<string, unknown>,
  key: string
): string {
  const val = data[key];

  if (
    typeof val !== "string" ||
    val.trim().length === 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      `"${key}" must be a non-empty string.`
    );
  }

  return val.trim();
}

function parseBullyNames(
  raw: unknown
): string[] {
  if (!Array.isArray(raw)) {
    return [];
  }

  return (raw as unknown[])
    .filter(
      (n): n is string =>
        typeof n === "string" &&
        n.trim().length > 0
    )
    .map((n) => n.trim())
    .slice(0, 20);
}