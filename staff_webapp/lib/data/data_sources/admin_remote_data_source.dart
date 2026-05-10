import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:staff_webapp/core/constants/firestore_constants.dart';
import 'package:staff_webapp/data/data_models/admin_model.dart';
import 'package:staff_webapp/data/data_models/report_model.dart';
import 'package:staff_webapp/data/data_models/school_model.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';

class AdminRemoteDataSource {
  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;

  AdminRemoteDataSource({
    required FirebaseFirestore firestore,
    required fb.FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // Shortcuts

  CollectionReference get _schools =>
      _firestore.collection(FirestoreConstants.schools);
  CollectionReference get _admins =>
      _firestore.collection(FirestoreConstants.admins);
  CollectionReference get _reports =>
      _firestore.collection(FirestoreConstants.reports);

  // Current admin

  /// Fetches the Admin document for the currently signed-in user.
  /// Returns null if no admin doc exists (user not yet provisioned).
  Future<AdminModel?> getCurrentAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _admins.doc(uid).get();
    if (!doc.exists) return null;
    return AdminModel.fromFirestore(doc);
  }

  /// Real-time stream of the current admin's document.
  /// The dashboard listens to this so role/school changes take effect instantly.
  Stream<AdminModel?> watchCurrentAdmin() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _admins.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AdminModel.fromFirestore(doc);
    });
  }

  // Schools

  Future<List<SchoolModel>> getAllSchools() async {
    final snap = await _schools
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    return snap.docs.map(SchoolModel.fromFirestore).toList();
  }

  Future<SchoolModel?> getSchool(String schoolId) async {
    final doc = await _schools.doc(schoolId).get();
    if (!doc.exists) return null;
    return SchoolModel.fromFirestore(doc);
  }

  Future<String> createSchool(SchoolModel school) async {
    final ref = await _schools.add(school.toFirestore());
    return ref.id;
  }

  Future<void> updateSchool(String schoolId, Map<String, dynamic> data) =>
      _schools.doc(schoolId).update(data);

  // Admin management (super admin only)

  Future<List<AdminModel>> getAllAdmins() async {
    final snap = await _admins.orderBy('name').get();
    return snap.docs.map(AdminModel.fromFirestore).toList();
  }

  Future<List<AdminModel>> getAdminsForSchool(String schoolId) async {
    final snap = await _admins
        .where('schoolId', isEqualTo: schoolId)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map(AdminModel.fromFirestore).toList();
  }

  /// Creates or overwrites an admin document.
  /// The document ID is the user's Firebase Auth UID.
  Future<void> upsertAdmin(AdminModel admin) =>
      _admins.doc(admin.id).set(admin.toFirestore(), SetOptions(merge: true));

  Future<void> assignAdminToSchool(String adminUid, String schoolId) =>
      _admins.doc(adminUid).update({'schoolId': schoolId, 'isActive': true});

  Future<void> deactivateAdmin(String adminUid) =>
      _admins.doc(adminUid).update({'isActive': false});

  // Reports

  /// Real-time stream of all reports for a school, newest first.
  /// This is the primary feed for the dashboard.
  Stream<List<ReportModel>> watchReportsForSchool(String schoolId) {
    return _reports
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ReportModel.fromFirestore).toList());
  }

  Future<List<ReportModel>> getFilteredReports({
    required String schoolId,
    ReportStatus? status,
    ReportPriority? priority,
    bool? isFlagged,
  }) async {
    Query query = _reports.where('schoolId', isEqualTo: schoolId);

    if (status != null) {
      query = query.where('status',
          isEqualTo: _statusString(status));
    }
    if (priority != null) {
      query = query.where('priority',
          isEqualTo: priority == ReportPriority.high
              ? FirestoreConstants.priorityHigh
              : FirestoreConstants.priorityNormal);
    }
    if (isFlagged != null) {
      query = query.where('isFlagged', isEqualTo: isFlagged);
    }

    query = query.orderBy('submittedAt', descending: true);
    final snap = await query.get();
    return snap.docs.map(ReportModel.fromFirestore).toList();
  }

  Future<List<ReportModel>> getRecentReports(String schoolId,
      {int limit = 5}) async {
    final snap = await _reports
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('submittedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(ReportModel.fromFirestore).toList();
  }

  Future<ReportModel?> getReport(String reportId) async {
    final doc = await _reports.doc(reportId).get();
    if (!doc.exists) return null;
    return ReportModel.fromFirestore(doc);
  }

  Future<void> updateReport(String reportId, Map<String, dynamic> data) =>
      _reports.doc(reportId).update(data);

  Future<int> getNewReportCount(String schoolId) async {
    final snap = await _reports
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: FirestoreConstants.statusNew)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // Helpers

  String _statusString(ReportStatus s) => switch (s) {
    ReportStatus.newReport  => FirestoreConstants.statusNew,
    ReportStatus.reviewed   => FirestoreConstants.statusReviewed,
    ReportStatus.escalated  => FirestoreConstants.statusEscalated,
    ReportStatus.resolved   => FirestoreConstants.statusResolved,
  };
}
