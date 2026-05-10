import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/data/data_models/admin_model.dart';
import 'package:staff_webapp/data/data_models/report_model.dart';
import 'package:staff_webapp/data/data_models/school_model.dart';
import 'package:staff_webapp/data/data_sources/admin_remote_data_source.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/domain/entities/school_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _dataSource;

  AdminRepositoryImpl(this._dataSource);

  // Current admin

  @override
  Future<Either<Failure, Admin?>> getCurrentAdmin() =>
      _run(() => _dataSource.getCurrentAdmin());

  @override
  Stream<Admin?> watchCurrentAdmin() => _dataSource.watchCurrentAdmin();

  // Schools

  @override
  Future<Either<Failure, List<School>>> getAllSchools() =>
      _run(() => _dataSource.getAllSchools());

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
  }) =>
      _run(() => _dataSource.updateSchool(schoolId, {
            if (name != null) 'name': name,
            if (address != null) 'address': address,
            if (isActive != null) 'isActive': isActive,
          }));

  // Admin management

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
  Future<Either<Failure, void>> assignAdminToSchool(
          String adminUid, String schoolId) =>
      _run(() => _dataSource.assignAdminToSchool(adminUid, schoolId));

  @override
  Future<Either<Failure, void>> deactivateAdmin(String adminUid) =>
      _run(() => _dataSource.deactivateAdmin(adminUid));

  // Reports

  @override
  Stream<List<Report>> watchReportsForSchool(String schoolId) =>
      _dataSource.watchReportsForSchool(schoolId);
  
  @override
  Stream<List<Report>> watchAllReports() =>
      _dataSource.watchAllReports();

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
  Future<Either<Failure, void>> updateReportStatus(
          String reportId, ReportStatus status, String reviewerUid) =>
      _run(() => _dataSource.updateReport(
            reportId,
            ReportModel.toUpdateMap(status: status, reviewedBy: reviewerUid),
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

  Future<Either<Failure, T>> _run<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return Left(const PermissionFailure());
      }
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    } catch (_) {
      return Left(const UnexpectedFailure());
    }
  }
}
