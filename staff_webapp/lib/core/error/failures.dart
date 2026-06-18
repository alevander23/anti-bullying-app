// This entire file was written by Claude

// lib/core/error/failures.dart
//
// WHY: Replacing raw `String` errors with typed Failures gives you:
//   - Exhaustive pattern matching in the UI (no forgotten cases)
//   - Richer metadata (e.g. original exception, codes) without coupling layers
//   - Easy extension: add NetworkFailure, etc. independently

abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

// Authentication-specific failures
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class MicrosoftAuthFailure extends AuthFailure {
  final String? errorCode;
  const MicrosoftAuthFailure(super.message, {this.errorCode});
}

class SignOutFailure extends Failure {
  const SignOutFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred']);
}

// Admin System
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'You do not have permission to perform this action']);
}
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested resource was not found']);
}
class SchoolAccessFailure extends Failure {
  const SchoolAccessFailure([super.message = 'You do not have access to this school\'s data']);
}
class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message);
}