import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/domain/entities/school_entity.dart';

abstract class AdminRepository {
  // Current admin
  Future<Either<Failure, Admin?>> getCurrentAdmin();
  Stream<Admin?> watchCurrentAdmin();

  // Schools
  Future<Either<Failure, List<School>>> getAllSchools();
  Future<Either<Failure, School?>> getSchool(String schoolId);
  Future<Either<Failure, String>> createSchool({required String name, required String address});
  Future<Either<Failure, void>> updateSchool(String schoolId, {String? name, String? address, bool? isActive});

  // Admin management
  Future<Either<Failure, List<Admin>>> getAllAdmins();
  Future<Either<Failure, List<Admin>>> getAdminsForSchool(String schoolId);
  Future<Either<Failure, void>> createAdmin({
    required String uid,
    required String email,
    required String name,
    required AdminRole role,
    String? schoolId,
  });
  Future<Either<Failure, void>> assignAdminToSchool(String adminUid, String schoolId);
  Future<Either<Failure, void>> deactivateAdmin(String adminUid);

  // Reports
  Stream<List<Report>> watchReportsForSchool(String schoolId);
  Stream<List<Report>> watchAllReports();
  Future<Either<Failure, List<Report>>> getFilteredReports({
    required String schoolId,
    ReportStatus? status,
    ReportPriority? priority,
    bool? isFlagged,
  });
  Future<Either<Failure, List<Report>>> getRecentReports(String schoolId, {int limit});
  Future<Either<Failure, Report?>> getReport(String reportId);
  Future<Either<Failure, void>> updateReportStatus(String reportId, ReportStatus status, String reviewerUid);
  Future<Either<Failure, void>> updateReportPriority(String reportId, ReportPriority priority);
  Future<Either<Failure, void>> toggleReportFlag(String reportId, bool isFlagged);
  Future<Either<Failure, void>> addReportNotes(String reportId, String notes, String reviewerUid);
  Future<Either<Failure, int>> getNewReportCount(String schoolId);
}
