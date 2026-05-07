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
  Future<Either<Failure, User?>> getCurrentUser();

  /// A stream that emits a new value whenever auth state changes.
  Stream<User?> get authStateChanges;

  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, User>> signInWithMicrosoft();

  Future<Either<Failure, void>> signOut();
}
