// lib/presentation/bloc/settings/settings_state.dart

import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/pending_admin_entity.dart';
import 'package:staff_webapp/domain/entities/school_entity.dart';

abstract class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final School school;
  final List<Admin> admins;
  final List<PendingAdmin> pendingAdmins;
  /// Only populated for super admins
  final List<School> allSchools;
  final List<Admin> allAdmins;

  const SettingsLoaded({
    required this.school,
    required this.admins,
    this.pendingAdmins = const [],
    this.allSchools = const [],
    this.allAdmins = const [],
  });

  SettingsLoaded copyWith({
    School? school,
    List<Admin>? admins,
    List<PendingAdmin>? pendingAdmins,
    List<School>? allSchools,
    List<Admin>? allAdmins,
  }) =>
      SettingsLoaded(
        school: school ?? this.school,
        admins: admins ?? this.admins,
        pendingAdmins: pendingAdmins ?? this.pendingAdmins,
        allSchools: allSchools ?? this.allSchools,
        allAdmins: allAdmins ?? this.allAdmins,
      );
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
}

class SettingsActionInProgress extends SettingsState {
  const SettingsActionInProgress();
}

class SettingsActionSuccess extends SettingsState {
  final String message;
  final SettingsLoaded previousData;
  const SettingsActionSuccess(this.message, this.previousData);
}

class SettingsActionError extends SettingsState {
  final String message;
  final SettingsLoaded previousData;
  const SettingsActionError(this.message, this.previousData);
}
