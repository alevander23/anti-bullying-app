// lib/presentation/bloc/school/school_state.dart

import 'package:staff_webapp/domain/entities/admin_entity.dart';

abstract class SchoolState {
  const SchoolState();
}

// Initial state before any data is loaded
class SchoolInitial extends SchoolState { const SchoolInitial(); }

// Indicates data loading is in progress
class SchoolLoading extends SchoolState { const SchoolLoading(); }

// Holds data after successful load from the backend
class SchoolLoaded extends SchoolState {
  final Admin admin;
  final int autoGroupWindowDays;
  const SchoolLoaded({required this.admin, this.autoGroupWindowDays = 5});
}

// Error state when data loading fails
class SchoolError extends SchoolState {
  final String message;
  const SchoolError(String message) : message = message;
}

// State after a successful administrative action (e.g. save settings)
class SchoolActionSuccess extends SchoolState {
  final String message;
  const SchoolActionSuccess(String message) : message = message;
}

// State after a failed administrative action
class SchoolActionError extends SchoolState {
  final String message;
  const SchoolActionError(String message) : message = message;
}