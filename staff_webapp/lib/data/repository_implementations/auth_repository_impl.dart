import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/data/data_models/user_model.dart';
import 'package:staff_webapp/data/data_sources/auth_remote_data_source.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final fb.FirebaseAuth _firebaseAuth;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required fb.FirebaseAuth firebaseAuth,
  })  : _remoteDataSource = remoteDataSource,
        _firebaseAuth = firebaseAuth;

  // Stream

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return UserModel.fromFirebaseUser(fbUser);
    });
  }

  // Sign in

  @override
  Future<Either<Failure, User>> signInWithMicrosoft() =>
      _runAuthAction(
        () => _remoteDataSource.signInWithMicrosoft(),
        provider: AuthProvider.microsoft,
      );
  // Sign out

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(SignOutFailure(e.message ?? 'Sign-out failed'));
    } catch (_) {
      return Left(const SignOutFailure('An unexpected error occurred during sign-out'));
    }
  }

  // Current user

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Failed to restore session'));
    } catch (_) {
      return Left(const UnexpectedFailure());
    }
  }

  // Helpers

  Future<Either<Failure, User>> _runAuthAction(
    Future<UserModel> Function() action, {
    required AuthProvider provider,
  }) async {
    try {
      final user = await action();
      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e, provider));
    } catch (_) {
      return Left(const UnexpectedFailure());
    }
  }

  Failure _mapFirebaseError(fb.FirebaseAuthException e, AuthProvider provider) {
    final message = switch (e.code) {
      'cancelled-by-user'                          => 'Sign-in was cancelled.',
      'account-exists-with-different-credential'   => 'An account already exists with the same email using a different sign-in method.',
      'popup-closed-by-user'                       => 'Sign-in window was closed before completing.',
      'network-request-failed'                     => 'Network error. Please check your connection.',
      'too-many-requests'                          => 'Too many attempts. Please try again later.',
      'user-disabled'                              => 'This account has been disabled.',
      'invalid-credential'                         => 'Invalid credentials. Please try again.',
      _                                            => e.message ?? 'Authentication failed.',
    };

    return MicrosoftAuthFailure(message, errorCode: e.code);
  }
}
