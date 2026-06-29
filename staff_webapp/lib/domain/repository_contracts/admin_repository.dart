import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/pending_admin_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/domain/entities/school_entity.dart';

abstract class AdminRepository {
  // Provides access to the currently authenticated admin's data
  Future<Either<Failure, Admin?>> getCurrentAdmin();
  Stream<Admin?> watchCurrentAdmin();

  // Manages school-related operations such as retrieval, creation, and updates
  Future<Either<Failure, List<School>>> getAllSchools();
  Future<Either<Failure, List<School>>> getAllSchoolsIncludingInactive();
  Future<Either<Failure, School?>> getSchool(String schoolId);
  Future<Either<Failure, String>> createSchool({required String name, required String address});
  Future<Either<Failure, void>> updateSchool(String schoolId, {String? name, String? address, bool? isActive, int? resolvedReportRetentionDays, int? autoGroupWindowDays});

  // Manages administrative user operations including creation, assignment, and deactivation
  Future<Either<Failure, List<Admin>>> getAllAdmins();
  Future<Either<Failure, List<Admin>>> getAdminsForSchool(String schoolId);
  Future<Either<Failure, void>> createAdmin({
    required String uid,
    required String email,
    required String name,
    required AdminRole role,
    String? schoolId,
  });
  Future<Either<Failure, void>> inviteAdmin({
    required String email,
    required String name,
    required AdminRole role,
    String? schoolId,
  });
  Future<Either<Failure, void>> assignAdminToSchool(String adminUid, String schoolId);
  Future<Either<Failure, void>> deactivateAdmin(String adminUid);

  // Manages pending admin approvals through the SSO onboarding process
  Stream<List<PendingAdmin>> watchPendingAdmins();
  Future<Either<Failure, void>> approvePendingAdmin({
    required String uid,
    required String email,
    required String name,
    required AdminRole role,
    required String schoolId,
  });
  Future<Either<Failure, void>> rejectPendingAdmin(String uid);

  // Handles automated report cleanup based on retention policies
  Future<Either<Failure, void>> cleanupOldReports({
    required String schoolId,
    required int retentionDays,
  });

  // Provides access to report management functionality including querying, filtering, and updating reports
  Stream<List<Report>> watchReportsForSchool(String schoolId);
  Stream<List<Report>> watchAllReports();
  Future<Either<Failure, Map<String, int>>> getReportStats(String? schoolId);
  Future<Either<Failure, ({List<Report> reports, DocumentSnapshot? lastDoc})>> getReportPage({
    required String? schoolId,
    required List<ReportStatus> statuses,
    ReportPriority? priority,
    bool? isFlagged,
    DocumentSnapshot? startAfter,
    int pageSize,
    ReportSortField sortField,
    bool sortAscending,
  });
  Future<Either<Failure, List<Report>>> getFilteredReports({
    required String schoolId,
    ReportStatus? status,
    ReportPriority? priority,
    bool? isFlagged,
  });
  Future<Either<Failure, List<Report>>> getRecentReports(String schoolId, {int limit});
  Future<Either<Failure, Report?>> getReport(String reportId);
  Future<Either<Failure, void>> updateReportStatus(String reportId, ReportStatus status, String reviewerUid, String reviewerName);
  Future<Either<Failure, void>> updateReportPriority(String reportId, ReportPriority priority);
  Future<Either<Failure, void>> toggleReportFlag(String reportId, bool isFlagged);
  Future<Either<Failure, void>> addReportNotes(String reportId, String notes, String reviewerUid);
  Future<Either<Failure, int>> getNewReportCount(String schoolId);
}