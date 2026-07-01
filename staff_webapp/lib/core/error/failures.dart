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

// Microsoft authentication specific failures
class MicrosoftAuthFailure extends AuthFailure {
  final String? errorCode;
  const MicrosoftAuthFailure(super.message, {this.errorCode});
}

// Failure related to signing out
class SignOutFailure extends Failure {
  const SignOutFailure(super.message);
}

// Generic network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

// Fallback for unhandled errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred']);
}

// Admin System related failures
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'You do not have permission to perform this action']);
}

// Failure when a requested resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested resource was not found']);
}

// Failure when a user does not have access to a school's data
class SchoolAccessFailure extends Failure {
  const SchoolAccessFailure([super.message = 'You do not have access to this school\'s data']);
}

// Firestore operation failures
class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message);
}

// Failure fetching a protected media file (photo/video) from the storage server
class MediaFailure extends Failure {
  const MediaFailure([super.message = 'Failed to load media']);
}