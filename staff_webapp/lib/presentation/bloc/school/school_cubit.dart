// lib/presentation/bloc/school/school_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/admin_repository.dart';
import 'school_state.dart';

class SchoolCubit extends Cubit<SchoolState> {
  final AdminRepository _repository;
  StreamSubscription<Admin?>? _adminSubscription;

  SchoolCubit(this._repository) : super(const SchoolInitial());

  /// Watch the current admin's document — picks up school reassignments live.
  /// Also triggers a daily cleanup of old resolved reports when the school loads.
  void watchCurrentAdmin() {
    _adminSubscription?.cancel();
    _adminSubscription = _repository.watchCurrentAdmin().listen(
      (admin) async {
        if (admin == null) {
          emit(const SchoolError('Admin profile not found'));
          return;
        }
        if (!admin.isActive) {
          emit(const SchoolError('Your account has been deactivated'));
          return;
        }

        // Fetch school to get per-school settings
        int windowDays = 5;
        if (admin.schoolId != null) {
          final schoolResult = await _repository.getSchool(admin.schoolId!);
          schoolResult.fold(
            (_) => null,
            (school) {
              if (school != null) windowDays = school.autoGroupWindowDays;
            },
          );
        }

        emit(SchoolLoaded(admin: admin, autoGroupWindowDays: windowDays));

        // Trigger daily cleanup for regular admins with a school assigned
        if (!admin.isSuperAdmin && admin.schoolId != null) {
          _maybeRunDailyCleanup(admin.schoolId!);
        }
      },
      onError: (_) => emit(const SchoolError('Failed to load admin profile')),
    );
  }

  /// Checks if a cleanup has already run today; if not, fetches school settings
  /// and runs the cleanup if a retention period is configured.
  /// This is a best-effort operation that should not block UI or user actions.
  Future<void> _maybeRunDailyCleanup(String schoolId) async {
    final schoolResult = await _repository.getSchool(schoolId);
    schoolResult.fold(
      (_) => null, // silently ignore errors — cleanup is best-effort
      (school) async {
        if (school == null) return;
        if (school.resolvedReportRetentionDays == null) return;

        // Check if we've already cleaned up today
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (school.lastCleanupDate != null) {
          final lastCleanup = DateTime(
            school.lastCleanupDate!.year,
            school.lastCleanupDate!.month,
            school.lastCleanupDate!.day,
          );
          if (!lastCleanup.isBefore(today)) return; // already ran today
        }

        // Run the cleanup silently in the background
        await _repository.cleanupOldReports(
          schoolId: schoolId,
          retentionDays: school.resolvedReportRetentionDays!,
        );
      },
    );
  }

  /// Creates a new school with the given name and address.
  /// Emits success or error state based on repository response.
  Future<void> createSchool(String name, String address) async {
    final result = await _repository.createSchool(name: name, address: address);
    result.fold(
      (f) => emit(SchoolActionError(f.message)),
      (_) => emit(const SchoolActionSuccess('School created')),
    );
  }

  /// Assigns an admin to a school.
  /// Emits success or error state based on repository response.
  Future<void> assignAdminToSchool(String adminUid, String schoolId) async {
    final result = await _repository.assignAdminToSchool(adminUid, schoolId);
    result.fold(
      (f) => emit(SchoolActionError(f.message)),
      (_) => emit(const SchoolActionSuccess('Admin assigned to school')),
    );
  }

  @override
  Future<void> close() {
    _adminSubscription?.cancel();
    return super.close();
  }
}