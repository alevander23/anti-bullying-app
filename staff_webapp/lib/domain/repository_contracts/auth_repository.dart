import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';

abstract class AuthRepository {
  // Returns the currently signed-in user, or null if not authenticated.
  Future<Either<Failure, User?>> getCurrentUser();

  // A stream that emits a new value whenever auth state changes.
  Stream<User?> get authStateChanges;

  // Returns the authenticated user entity on success.
  Future<Either<Failure, User>> signInWithMicrosoft();

  // Signs the current user out of the application.
  Future<Either<Failure, void>> signOut();
}