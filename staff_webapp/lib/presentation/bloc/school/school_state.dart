// lib/presentation/bloc/school/school_state.dart

import 'package:staff_webapp/domain/entities/admin_entity.dart';

abstract class SchoolState {
  const SchoolState();
}
class SchoolInitial extends SchoolState { const SchoolInitial(); }
class SchoolLoading extends SchoolState { const SchoolLoading(); }
class SchoolLoaded extends SchoolState {
  final Admin admin;
  const SchoolLoaded({required this.admin});
}
class SchoolError extends SchoolState {
  final String message;
  const SchoolError(String message) : message = message;
}
class SchoolActionSuccess extends SchoolState {
  final String message;
  const SchoolActionSuccess(String message) : message = message;
}
class SchoolActionError extends SchoolState {
  final String message;
  const SchoolActionError(String message) : message = message;
}
