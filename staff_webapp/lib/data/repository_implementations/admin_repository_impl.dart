import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/data/data_models/admin_model.dart';
import 'package:staff_webapp/data/data_models/report_model.dart';
import 'package:staff_webapp/data/data_models/school_model.dart';
import 'package:staff_webapp/data/data_sources/admin_remote_data_source.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/pending_admin_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/domain/entities/school_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _dataSource;

  AdminRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Admin?>> getCurrentAdmin() =>
      _run(() => _dataSource.getCurrentAdmin());

  @override
  Stream<Admin?> watchCurrentAdmin() => _dataSource.watchCurrentAdmin();

  @override
  Future<Either<Failure, List<School>>> getAllSchools() =>
      _run(() => _dataSource.getAllSchools());

  @override
  Future<Either<Failure, List<School>>> getAllSchoolsIncludingInactive() =>
      _run(() => _dataSource.getAllSchoolsIncludingInactive());

  @override
  Future<Either<Failure, School?>> getSchool(String schoolId) =>
      _run(() => _dataSource.getSchool(schoolId));

  @override
  Future<Either<Failure, String>> createSchool({
    required String name,
    required String address,
  }) =>
      _run(() => _dataSource.createSchool(SchoolModel(
            id: '',
            name: name,
            address: address,
            isActive: true,
            createdAt: DateTime.now(),
          )));

  @override
  Future<Either<Failure, void>> updateSchool(
    String schoolId, {
    String? name,
    String? address,
    bool? isActive,
    int? resolvedReportRetentionDays,
    int? autoGroupWindowDays,
  }) =>
      _run(() => _dataSource.updateSchool(schoolId, {
            if (name != null) 'name': name,
            if (address != null) 'address': address,
            if (isActive != null) 'isActive': isActive,
            if (resolvedReportRetentionDays != null)
              'resolvedReportRetentionDays': resolvedReportRetentionDays,
            if (autoGroupWindowDays != null)
              'autoGroupWindowDays': autoGroupWindowDays,
          }));

  @override
  Future<Either<Failure, List<Admin>>> getAllAdmins() =>
      _run(() => _dataSource.getAllAdmins());

  @override
  Future<Either<Failure, List<Admin>>> getAdminsForSchool(String schoolId) =>
      _run(() => _dataSource.getAdminsForSchool(schoolId));

  @override
  Future<Either<Failure, void>> createAdmin({
    required String uid,
    required String email,
    required String name,
    required AdminRole role,
    String? schoolId,
  }) =>
      _run(() => _dataSource.upsertAdmin(AdminModel(
            id: uid,
            email: email,
            name: name,
            role: role,
            schoolId: schoolId,
            isActive: true,
            createdAt: DateTime.now(),
          )));

  @override
  Future<Either<Failure, void>> inviteAdmin({
    required String email,
    required String name,
    required AdminRole role,
    String? schoolId,
  }) =>
      _run(() => _dataSource.inviteAdmin(
            email: email,
            name: name,
            role: role,
            schoolId: schoolId,
          ));

  @override
  Future<Either<Failure, void>> assignAdminToSchool(
          String adminUid, String schoolId) =>
      _run(() => _dataSource.assignAdminToSchool(adminUid, schoolId));

  @override
  Future<Either<Failure, void>> deactivateAdmin(String adminUid) =>
      _run(() => _dataSource.deactivateAdmin(adminUid));

  // ── Pending admins ───────────────────────────────────────────────────────────

  @override
  Stream<List<PendingAdmin>> watchPendingAdmins() =>
      _dataSource.watchPendingAdmins();

  @override
  Future<Either<Failure, void>> approvePendingAdmin({
    required String uid,
    required String email,
    required String name,
    required AdminRole role,
    required String schoolId,
  }) =>
      _run(() => _dataSource.approvePendingAdmin(
            uid: uid,
            email: email,
            name: name,
            role: role,
            schoolId: schoolId,
          ));

  @override
  Future<Either<Failure, void>> rejectPendingAdmin(String uid) =>
      _run(() => _dataSource.rejectPendingAdmin(uid));

  // ── Report cleanup ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> cleanupOldReports({
    required String schoolId,
    required int retentionDays,
  }) =>
      _run(() => _dataSource.cleanupOldReports(
            schoolId: schoolId,
            retentionDays: retentionDays,
          ));

  // ── Reports ──────────────────────────────────────────────────────────────────

  @override
  Stream<List<Report>> watchReportsForSchool(String schoolId) =>
      _dataSource.watchReportsForSchool(schoolId);

  @override
  Stream<List<Report>> watchAllReports() => _dataSource.watchAllReports();

  @override
  Future<Either<Failure, Map<String, int>>> getReportStats(String? schoolId) =>
      _run(() => _dataSource.getReportStats(schoolId));

  @override
  Future<Either<Failure, ({List<Report> reports, DocumentSnapshot? lastDoc})>>
      getReportPage({
    required String? schoolId,
    required List<ReportStatus> statuses,
    ReportPriority? priority,
    bool? isFlagged,
    DocumentSnapshot? startAfter,
    int pageSize = 20,
    ReportSortField sortField = ReportSortField.updatedAt,
    bool sortAscending = false,
  }) =>
          _run(() async {
            final result = await _dataSource.getReportPage(
              schoolId: schoolId,
              statuses: statuses,
              priority: priority,
              isFlagged: isFlagged,
              startAfter: startAfter,
              pageSize: pageSize,
              sortField: sortField,
              sortAscending: sortAscending,
            );
            return (
              reports: result.models.cast<Report>(),
              lastDoc: result.lastDoc,
            );
          });

  @override
  Future<Either<Failure, List<Report>>> getFilteredReports({
    required String schoolId,
    ReportStatus? status,
    ReportPriority? priority,
    bool? isFlagged,
  }) =>
      _run(() => _dataSource.getFilteredReports(
            schoolId: schoolId,
            status: status,
            priority: priority,
            isFlagged: isFlagged,
          ));

  @override
  Future<Either<Failure, List<Report>>> getRecentReports(String schoolId,
          {int limit = 5}) =>
      _run(() => _dataSource.getRecentReports(schoolId, limit: limit));

  @override
  Future<Either<Failure, Report?>> getReport(String reportId) =>
      _run(() => _dataSource.getReport(reportId));

  @override
  Future<Either<Failure, void>> updateReportStatus(String reportId,
          ReportStatus status, String reviewerUid, String reviewerName) =>
      _run(() => _dataSource.updateReport(
            reportId,
            ReportModel.toUpdateMap(
              status: status,
              reviewedBy: reviewerUid,
              resolvedBy:
                  status == ReportStatus.resolved ? reviewerName : null,
              closedAt:
                  status == ReportStatus.resolved ? DateTime.now() : null,
              clearResolvedBy: status != ReportStatus.resolved,
              clearClosedAt: status != ReportStatus.resolved,
            ),
          ));

  @override
  Future<Either<Failure, void>> updateReportPriority(
          String reportId, ReportPriority priority) =>
      _run(() => _dataSource.updateReport(
            reportId,
            ReportModel.toUpdateMap(priority: priority),
          ));

  @override
  Future<Either<Failure, void>> toggleReportFlag(
          String reportId, bool isFlagged) =>
      _run(() => _dataSource.updateReport(
            reportId,
            ReportModel.toUpdateMap(isFlagged: isFlagged),
          ));

  @override
  Future<Either<Failure, void>> addReportNotes(
          String reportId, String notes, String reviewerUid) =>
      _run(() => _dataSource.updateReport(
            reportId,
            ReportModel.toUpdateMap(notes: notes, reviewedBy: reviewerUid),
          ));

  @override
  Future<Either<Failure, int>> getNewReportCount(String schoolId) =>
      _run(() => _dataSource.getNewReportCount(schoolId));

  // ── Helper ───────────────────────────────────────────────────────────────────

  Future<Either<Failure, T>> _run<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on FirebaseException catch (e) {
      print('[AdminRepository] FirebaseException: code=${e.code} message=${e.message}');
      if (e.code == 'permission-denied') {
        return Left(const PermissionFailure());
      }
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    } catch (e) {
      print('[AdminRepository] Unexpected error: $e');
      return Left(const UnexpectedFailure());
    }
  }
}
