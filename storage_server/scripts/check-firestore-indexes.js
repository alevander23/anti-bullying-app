const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const admin = require('firebase-admin');

const serviceAccountPath = path.resolve(
  __dirname,
  '..',
  process.env.FIREBASE_SERVICE_ACCOUNT_PATH
);

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
});

const db = admin.firestore();
const reports = db.collection('reports');

// ── Results tracking ─────────────────────────────────────────────────────
const results = {
  passed: [],
  failed: [],
};

/**
 * Runs a single query, catches FAILED_PRECONDITION (missing index) errors,
 * and logs the Firestore console URL needed to create it.
 */
async function checkQuery(label, buildQuery) {
  try {
    const query = buildQuery();
    await query.limit(1).get(); // limit(1) — we only care if it *can* run, not the data
    console.log(`✅ OK   — ${label}`);
    results.passed.push(label);
  } catch (err) {
    if (err.code === 9 || /FAILED_PRECONDITION/.test(err.message)) {
      // Firestore embeds a direct "create this index" URL inside the error message
      const urlMatch = err.message.match(/https:\/\/console\.firebase\.google\.com\S+/);
      const indexUrl = urlMatch ? urlMatch[0] : '(no URL found in error — see raw message below)';

      console.log(`❌ MISSING INDEX — ${label}`);
      console.log(`   URL: ${indexUrl}`);
      if (!urlMatch) console.log(`   Raw error: ${err.message}`);

      results.failed.push({ label, url: indexUrl, rawError: err.message });
    } else {
      console.log(`⚠️  UNEXPECTED ERROR — ${label}`);
      console.log(`   ${err.message}`);
      results.failed.push({ label, url: null, rawError: err.message });
    }
  }
}

// ── Status combinations actually used by ReportCubit ─────────────────────
// _kDefaultStatuses on initial load; individual statuses are also reachable
// by toggling filters one at a time down to a single status or all four.
const STATUS_COMBOS = {
  defaultThree: ['new', 'reviewed', 'escalated'],
  allFour: ['new', 'reviewed', 'escalated', 'resolved'],
  singleNew: ['new'],
  singleResolved: ['resolved'],
};

const SORT_FIELDS = ['updatedAt', 'submittedAt'];
const SORT_DIRECTIONS = [true, false]; // ascending, descending
const SCHOOL_ID_SAMPLE = 'school_greenfield'; // ← replace with a real schoolId from your data if you want guaranteed-realistic results

async function run() {
  console.log('Checking Firestore composite indexes for "reports" queries...\n');

  // ── getReportPage(): the big one — schoolId + status(in) + priority + isFlagged + orderBy
  for (const [comboName, statuses] of Object.entries(STATUS_COMBOS)) {
    for (const sortField of SORT_FIELDS) {
      for (const ascending of SORT_DIRECTIONS) {
        // schoolId scoped, statuses only
        await checkQuery(
          `getReportPage: schoolId + status[${comboName}] + orderBy(${sortField}, asc=${ascending})`,
          () =>
            reports
              .where('schoolId', '==', SCHOOL_ID_SAMPLE)
              .where('status', 'in', statuses)
              .orderBy(sortField, ascending ? 'asc' : 'desc')
        );

        // schoolId scoped, statuses + priority
        await checkQuery(
          `getReportPage: schoolId + status[${comboName}] + priority + orderBy(${sortField}, asc=${ascending})`,
          () =>
            reports
              .where('schoolId', '==', SCHOOL_ID_SAMPLE)
              .where('status', 'in', statuses)
              .where('priority', '==', 'high')
              .orderBy(sortField, ascending ? 'asc' : 'desc')
        );

        // schoolId scoped, statuses + isFlagged
        await checkQuery(
          `getReportPage: schoolId + status[${comboName}] + isFlagged + orderBy(${sortField}, asc=${ascending})`,
          () =>
            reports
              .where('schoolId', '==', SCHOOL_ID_SAMPLE)
              .where('status', 'in', statuses)
              .where('isFlagged', '==', true)
              .orderBy(sortField, ascending ? 'asc' : 'desc')
        );

        // schoolId scoped, statuses + priority + isFlagged (all filters active)
        await checkQuery(
          `getReportPage: schoolId + status[${comboName}] + priority + isFlagged + orderBy(${sortField}, asc=${ascending})`,
          () =>
            reports
              .where('schoolId', '==', SCHOOL_ID_SAMPLE)
              .where('status', 'in', statuses)
              .where('priority', '==', 'high')
              .where('isFlagged', '==', true)
              .orderBy(sortField, ascending ? 'asc' : 'desc')
        );

        // Super admin: no schoolId, statuses + orderBy (loadAllReports path)
        await checkQuery(
          `getReportPage [super admin]: status[${comboName}] + orderBy(${sortField}, asc=${ascending})`,
          () =>
            reports
              .where('status', 'in', statuses)
              .orderBy(sortField, ascending ? 'asc' : 'desc')
        );
      }
    }
  }

  // ── getFilteredReports(): single status (not whereIn) + priority + isFlagged + orderBy(submittedAt)
  const SINGLE_STATUSES = ['new', 'reviewed', 'escalated', 'resolved'];
  for (const status of SINGLE_STATUSES) {
    await checkQuery(
      `getFilteredReports: schoolId + status=${status} + orderBy(submittedAt)`,
      () =>
        reports
          .where('schoolId', '==', SCHOOL_ID_SAMPLE)
          .where('status', '==', status)
          .orderBy('submittedAt', 'desc')
    );

    await checkQuery(
      `getFilteredReports: schoolId + status=${status} + priority + orderBy(submittedAt)`,
      () =>
        reports
          .where('schoolId', '==', SCHOOL_ID_SAMPLE)
          .where('status', '==', status)
          .where('priority', '==', 'high')
          .orderBy('submittedAt', 'desc')
    );

    await checkQuery(
      `getFilteredReports: schoolId + status=${status} + isFlagged + orderBy(submittedAt)`,
      () =>
        reports
          .where('schoolId', '==', SCHOOL_ID_SAMPLE)
          .where('status', '==', status)
          .where('isFlagged', '==', true)
          .orderBy('submittedAt', 'desc')
    );
  }

  // ── cleanupOldReports(): schoolId + status=resolved + updatedAt range
  await checkQuery(
    'cleanupOldReports: schoolId + status=resolved + updatedAt<cutoff',
    () =>
      reports
        .where('schoolId', '==', SCHOOL_ID_SAMPLE)
        .where('status', '==', 'resolved')
        .where('updatedAt', '<', admin.firestore.Timestamp.now())
  );

  // ── watchReportsForSchool(): schoolId + orderBy(submittedAt) — simple, rarely needs a composite index
  await checkQuery(
    'watchReportsForSchool: schoolId + orderBy(submittedAt)',
    () => reports.where('schoolId', '==', SCHOOL_ID_SAMPLE).orderBy('submittedAt', 'desc')
  );

  // ── getNewReportCount(): schoolId + status=new (count query, no orderBy — simple, but check anyway)
  await checkQuery(
    'getNewReportCount: schoolId + status=new',
    () => reports.where('schoolId', '==', SCHOOL_ID_SAMPLE).where('status', '==', 'new')
  );

  console.log('\n──────────────────────────────────────────');
  console.log(`Done. ${results.passed.length} passed, ${results.failed.length} need attention.\n`);

  if (results.failed.length > 0) {
    console.log('Indexes to create:\n');
    results.failed.forEach(({ label, url }) => {
      console.log(`• ${label}`);
      if (url) console.log(`  ${url}\n`);
    });
  } else {
    console.log('All query combinations are covered by existing indexes. 🎉');
  }

  process.exit(results.failed.length > 0 ? 1 : 0);
}

run().catch((err) => {
  console.error('Script crashed:', err);
  process.exit(1);
});