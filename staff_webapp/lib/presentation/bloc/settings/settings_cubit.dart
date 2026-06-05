// lib/presentation/bloc/settings/settings_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/pending_admin_entity.dart';
import 'package:staff_webapp/domain/entities/school_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/admin_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final AdminRepository _repository;
  StreamSubscription<List<PendingAdmin>>? _pendingSub;

  SettingsCubit(this._repository) : super(const SettingsInitial());

  /// Load settings for a regular admin — their school + its admins + pending.
  Future<void> loadForAdmin(Admin admin) async {
    emit(const SettingsLoading());

    if (admin.schoolId == null) {
      emit(const SettingsError('No school assigned to your account.'));
      return;
    }

    final schoolResult  = await _repository.getSchool(admin.schoolId!);
    final adminsResult  = await _repository.getAdminsForSchool(admin.schoolId!);

    School? school;
    schoolResult.fold((f) => emit(SettingsError(f.message)), (s) => school = s);
    if (school == null) return;

    List<Admin> admins = [];
    adminsResult.fold((f) => null, (a) => admins = a);

    emit(SettingsLoaded(school: school!, admins: admins));

    // Subscribe to pending admins stream so the badge updates live
    _watchPending();
  }

  /// Load settings for a super admin — all schools + all admins + pending.
  Future<void> loadForSuperAdmin(String focusSchoolId) async {
    emit(const SettingsLoading());
    print('[SettingsCubit] loadForSuperAdmin: focusSchoolId=$focusSchoolId');

    final schoolResult      = await _repository.getSchool(focusSchoolId);
    final adminsResult      = await _repository.getAdminsForSchool(focusSchoolId);
    final allSchoolsResult  = await _repository.getAllSchoolsIncludingInactive();
    final allAdminsResult   = await _repository.getAllAdmins();

    School? school;
    schoolResult.fold(
      (f) { print('[SettingsCubit] getSchool error: ${f.message}'); emit(SettingsError(f.message)); },
      (s) { school = s; print('[SettingsCubit] getSchool: ${s?.name}'); },
    );
    if (school == null) return;

    List<Admin> admins = [];
    adminsResult.fold(
      (f) => print('[SettingsCubit] getAdminsForSchool error: ${f.message}'),
      (a) { admins = a; print('[SettingsCubit] loaded ${a.length} admins for school'); },
    );

    List<School> allSchools = [];
    allSchoolsResult.fold(
      (f) => print('[SettingsCubit] getAllSchools error: ${f.message}'),
      (s) { allSchools = s; print('[SettingsCubit] loaded ${s.length} total schools'); },
    );

    List<Admin> allAdmins = [];
    allAdminsResult.fold(
      (f) => print('[SettingsCubit] getAllAdmins error: ${f.message}'),
      (a) { allAdmins = a; print('[SettingsCubit] loaded ${a.length} total admins'); },
    );

    emit(SettingsLoaded(
      school: school!,
      admins: admins,
      allSchools: allSchools,
      allAdmins: allAdmins,
    ));

    _watchPending();
  }

  /// Load for a super admin who has no schoolId assigned.
  /// Loads all schools and all admins globally, with no focused school.
  Future<void> loadForSuperAdminNoSchool() async {
    emit(const SettingsLoading());

    final allSchoolsResult = await _repository.getAllSchoolsIncludingInactive();
    final allAdminsResult  = await _repository.getAllAdmins();

    List<School> allSchools = [];
    String? schoolError;
    allSchoolsResult.fold(
      (f) { schoolError = f.message; print('[SettingsCubit] schools error: ${f.message}'); },
      (s) { allSchools = s; print('[SettingsCubit] loaded ${s.length} schools'); },
    );

    List<Admin> allAdmins = [];
    allAdminsResult.fold(
      (f) => print('[SettingsCubit] admins error: ${f.message}'),
      (a) { allAdmins = a; print('[SettingsCubit] loaded ${a.length} admins'); },
    );

    if (schoolError != null) {
      emit(SettingsError('Could not load schools: $schoolError'));
      return;
    }

    emit(SettingsLoaded(
      school: School(
        id: '',
        name: '',
        address: '',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      admins: [],
      allSchools: allSchools,
      allAdmins: allAdmins,
    ));

    _watchPending();
  }

  /// Streams pending admin list and patches it into the current state live.
  void _watchPending() {
    _pendingSub?.cancel();
    _pendingSub = _repository.watchPendingAdmins().listen((pending) {
      final current = _currentLoaded();
      if (current == null) return;
      emit(current.copyWith(pendingAdmins: pending));
    });
  }

  // ── School actions ───────────────────────────────────────────────────────────

  Future<void> updateSchoolInfo(String schoolId, {String? name, String? address}) async {
    final current = _currentLoaded();
    if (current == null) return;

    emit(const SettingsActionInProgress());
    final result = await _repository.updateSchool(schoolId, name: name, address: address);
    result.fold(
      (f) => emit(SettingsActionError(f.message, current)),
      (_) {
        final updated = current.copyWith(
          school: _patchSchool(current.school, name: name, address: address),
        );
        emit(SettingsActionSuccess('School info updated', updated));
        emit(updated);
      },
    );
  }

  Future<void> updateAutoGroupWindow(String schoolId, int days) async {
    final current = _currentLoaded();
    if (current == null) return;

    emit(const SettingsActionInProgress());
    final result = await _repository.updateSchool(
      schoolId,
      autoGroupWindowDays: days,
    );
    result.fold(
      (f) => emit(SettingsActionError(f.message, current)),
      (_) {
        final updated = current.copyWith(
          school: _patchSchool(current.school, autoGroupWindowDays: days),
        );
        emit(SettingsActionSuccess(
            'Auto-group window set to $days day${days == 1 ? '' : 's'}', updated));
        emit(updated);
      },
    );
  }

  Future<void> updateRetentionPolicy(String schoolId, int? days) async {
    final current = _currentLoaded();
    if (current == null) return;

    emit(const SettingsActionInProgress());
    final result = await _repository.updateSchool(
      schoolId,
      resolvedReportRetentionDays: days ?? -1,
    );
    result.fold(
      (f) => emit(SettingsActionError(f.message, current)),
      (_) {
        final updated = current.copyWith(
          school: _patchSchool(current.school,
              retentionDays: days, clearRetention: days == null),
        );
        final msg = days == null
            ? 'Auto-deletion disabled — reports kept forever'
            : 'Reports will be deleted $days days after resolution';
        emit(SettingsActionSuccess(msg, updated));
        emit(updated);
      },
    );
  }

  Future<void> createSchool(String name, String address) async {
    final current = _currentLoaded();
    if (current == null) return;

    emit(const SettingsActionInProgress());
    final result = await _repository.createSchool(name: name, address: address);
    result.fold(
      (f) => emit(SettingsActionError(f.message, current)),
      (_) async {
        final schoolsResult = await _repository.getAllSchoolsIncludingInactive();
        List<School> allSchools = current.allSchools;
        schoolsResult.fold((f) => null, (s) => allSchools = s);
        final updated = current.copyWith(allSchools: allSchools);
        emit(SettingsActionSuccess('School "$name" created', updated));
        emit(updated);
      },
    );
  }

  Future<void> toggleSchoolActive(String schoolId, bool isActive) async {
    final current = _currentLoaded();
    if (current == null) return;

    emit(const SettingsActionInProgress());
    final result = await _repository.updateSchool(schoolId, isActive: isActive);
    result.fold(
      (f) => emit(SettingsActionError(f.message, current)),
      (_) async {
        final schoolsResult = await _repository.getAllSchoolsIncludingInactive();
        List<School> allSchools = current.allSchools;
        schoolsResult.fold((f) => null, (s) => allSchools = s);
        final updated = current.copyWith(
          allSchools: allSchools,
          school: _patchSchool(current.school, isActive: isActive),
        );
        emit(SettingsActionSuccess(
            isActive ? 'School activated' : 'School deactivated', updated));
        emit(updated);
      },
    );
  }

  // ── Admin actions ────────────────────────────────────────────────────────────

  Future<void> removeAdmin(String adminUid) async {
    final current = _currentLoaded();
    if (current == null) return;

    emit(const SettingsActionInProgress());
    final result = await _repository.deactivateAdmin(adminUid);
    result.fold(
      (f) => emit(SettingsActionError(f.message, current)),
      (_) {
        final updated = current.copyWith(
          admins:    current.admins.where((a) => a.id != adminUid).toList(),
          allAdmins: current.allAdmins.where((a) => a.id != adminUid).toList(),
        );
        emit(SettingsActionSuccess('Admin removed', updated));
        emit(updated);
      },
    );
  }

  Future<void> inviteAdmin({
    required String email,
    required String name,
    required AdminRole role,
    String? schoolId,
  }) async {
    final current = _currentLoaded();
    if (current == null) return;

    emit(const SettingsActionInProgress());
    final result = await _repository.inviteAdmin(
      email: email,
      name: name,
      role: role,
      schoolId: schoolId,
    );
    result.fold(
      (f) => emit(SettingsActionError('Invite failed: ${f.message}', current)),
      (_) {
        emit(SettingsActionSuccess('Invite sent to $email', current));
        emit(current);
      },
    );
  }

  Future<void> assignAdminToSchool(String adminUid, String schoolId) async {
    final current = _currentLoaded();
    if (current == null) return;

    emit(const SettingsActionInProgress());
    final result = await _repository.assignAdminToSchool(adminUid, schoolId);
    result.fold(
      (f) => emit(SettingsActionError(f.message, current)),
      (_) async {
        final adminsResult = await _repository.getAllAdmins();
        List<Admin> allAdmins = current.allAdmins;
        adminsResult.fold((f) => null, (a) => allAdmins = a);
        final updated = current.copyWith(allAdmins: allAdmins);
        emit(SettingsActionSuccess('Admin assigned to school', updated));
        emit(updated);
      },
    );
  }

  // ── Pending admin actions ────────────────────────────────────────────────────

  Future<void> approvePendingAdmin({
    required PendingAdmin pending,
    required AdminRole role,
    required String schoolId,
  }) async {
    final current = _currentLoaded();
    if (current == null) return;

    emit(const SettingsActionInProgress());
    final result = await _repository.approvePendingAdmin(
      uid: pending.id,
      email: pending.email,
      name: pending.name,
      role: role,
      schoolId: schoolId,
    );
    result.fold(
      (f) => emit(SettingsActionError('Approval failed: ${f.message}', current)),
      (_) {
        // The pending stream will update automatically; reload school admins too
        _refreshAdmins(current);
        emit(SettingsActionSuccess('${pending.name} approved as admin', current));
      },
    );
  }

  Future<void> rejectPendingAdmin(PendingAdmin pending) async {
    final current = _currentLoaded();
    if (current == null) return;

    emit(const SettingsActionInProgress());
    final result = await _repository.rejectPendingAdmin(pending.id);
    result.fold(
      (f) => emit(SettingsActionError(f.message, current)),
      (_) {
        // The pending stream will update automatically
        emit(SettingsActionSuccess('${pending.name} rejected', current));
        emit(current);
      },
    );
  }

  Future<void> _refreshAdmins(SettingsLoaded current) async {
    final adminsResult = await _repository.getAdminsForSchool(current.school.id);
    List<Admin> admins = current.admins;
    adminsResult.fold((f) => null, (a) => admins = a);
    emit(current.copyWith(admins: admins));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  SettingsLoaded? _currentLoaded() {
    final s = state;
    if (s is SettingsLoaded) return s;
    if (s is SettingsActionSuccess) return s.previousData;
    if (s is SettingsActionError) return s.previousData;
    return null;
  }

  School _patchSchool(
    School old, {
    String? name,
    String? address,
    bool? isActive,
    int? retentionDays,
    bool clearRetention = false,
    int? autoGroupWindowDays,
  }) =>
      School(
        id:        old.id,
        name:      name ?? old.name,
        address:   address ?? old.address,
        isActive:  isActive ?? old.isActive,
        createdAt: old.createdAt,
        resolvedReportRetentionDays:
            clearRetention ? null : (retentionDays ?? old.resolvedReportRetentionDays),
        lastCleanupDate: old.lastCleanupDate,
        autoGroupWindowDays: autoGroupWindowDays ?? old.autoGroupWindowDays,
      );

  @override
  Future<void> close() {
    _pendingSub?.cancel();
    return super.close();
  }
}