// lib/presentation/bloc/settings/settings_state.dart

import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/pending_admin_entity.dart';
import 'package:staff_webapp/domain/entities/school_entity.dart';

/// Base class for all settings state objects
abstract class SettingsState {
  const SettingsState();
}

/// Initial state when the settings screen is first loaded
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// State indicating data is currently being fetched
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// State containing fully loaded settings data
class SettingsLoaded extends SettingsState {
  final School school;
  final List<Admin> admins;
  final List<PendingAdmin> pendingAdmins;
  /// Only populated for super admins - contains all schools in the system
  final List<School> allSchools;
  /// Only populated for super admins - contains all admins in the system
  final List<Admin> allAdmins;

  const SettingsLoaded({
    required this.school,
    required this.admins,
    this.pendingAdmins = const [],
    this.allSchools = const [],
    this.allAdmins = const [],
  });

  /// Creates a copy of this state with specified fields updated
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

/// State indicating an error occurred during settings operations
class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
}

/// State indicating a settings action (create/edit/delete) is in progress
class SettingsActionInProgress extends SettingsState {
  const SettingsActionInProgress();
}

/// State indicating a settings action was successful
class SettingsActionSuccess extends SettingsState {
  final String message;
  final SettingsLoaded previousData;
  const SettingsActionSuccess(this.message, this.previousData);
}

/// State indicating a settings action failed
class SettingsActionError extends SettingsState {
  final String message;
  final SettingsLoaded previousData;
  const SettingsActionError(this.message, this.previousData);
}