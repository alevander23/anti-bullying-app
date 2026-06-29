// lib/domain/repository_contracts/auth_repository.dart
//
// WHY: The contract lives in the domain layer so use-cases and cubits depend
// only on this abstraction — never on Firebase or MSAL directly. This makes
// swapping providers or mocking in tests trivial.
//
// We add:
//   - signOut()           — needed for a complete auth lifecycle
//   - getCurrentUser()    — needed to restore session on cold start
//   - authStateChanges    — stream so the app reacts to token expiry / sign-out

import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Returns the currently signed-in user, or null if not authenticated.
  /// Used to restore the session state when the app starts cold.
  Future<Either<Failure, User?>> getCurrentUser();

  /// A stream that emits a new value whenever auth state changes.
  /// Allows the app to react to events like token expiry or sign-out
  /// without actively polling for state updates.
  Stream<User?> get authStateChanges;

  /// Authenticates the user via Microsoft's MSAL implementation.
  /// Returns the authenticated user entity on success.
  Future<Either<Failure, User>> signInWithMicrosoft();

  /// Signs the current user out of the application.
  /// Returns void on success, or a Failure if sign-out fails.
  Future<Either<Failure, void>> signOut();
}