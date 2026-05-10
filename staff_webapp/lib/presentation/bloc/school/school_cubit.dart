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

  // Watch the current admin's document — picks up school reassignments live
  void watchCurrentAdmin() {
    _adminSubscription?.cancel();
    _adminSubscription = _repository.watchCurrentAdmin().listen(
      (admin) {
        if (admin == null) {
          emit(const SchoolError('Admin profile not found'));
          return;
        }
        if (!admin.isActive) {
          emit(const SchoolError('Your account has been deactivated'));
          return;
        }
        emit(SchoolLoaded(admin: admin));
      },
      onError: (_) => emit(const SchoolError('Failed to load admin profile')),
    );
  }

  Future<void> createSchool(String name, String address) async {
    final result = await _repository.createSchool(name: name, address: address);
    result.fold(
      (f) => emit(SchoolActionError(f.message)),
      (_) => emit(const SchoolActionSuccess('School created')),
    );
  }

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
