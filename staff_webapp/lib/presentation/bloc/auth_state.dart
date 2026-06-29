import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';

abstract class AuthState {
  const AuthState();
}

/// Initial state before authentication checks begin
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Transient state indicating authentication process is active
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authentication successful via user-initiated action
class AuthSuccess extends AuthState {
  final User user;
  const AuthSuccess(this.user);
}

/// Authentication restored automatically on app launch
class AuthSessionRestored extends AuthState {
  final User user;
  const AuthSessionRestored(this.user);
}

/// No active session - triggers navigation to login screen
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error state with typed failure for UI display
class AuthError extends AuthState {
  final Failure failure;
  const AuthError(this.failure);

  /// Returns the error message from the failure
  String get message => failure.message;
}