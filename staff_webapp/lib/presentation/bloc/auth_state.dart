import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';

abstract class AuthState {
  const AuthState();
}

/// App has just started session check in progress
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Actively checking the session or performing a sign-in / sign-out
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User signed in via a button tap
class AuthSuccess extends AuthState {
  final User user;
  const AuthSuccess(this.user);
}

/// Session was restored on cold start
class AuthSessionRestored extends AuthState {
  final User user;
  const AuthSessionRestored(this.user);
}

/// No authenticated user, route to login screen
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Something went wrong. Message comes from the typed Failure
class AuthError extends AuthState {
  final Failure failure;
  const AuthError(this.failure);

  String get message => failure.message;
}
