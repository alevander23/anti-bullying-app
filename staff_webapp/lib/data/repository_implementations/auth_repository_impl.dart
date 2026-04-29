// data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo; // Helper to check internet

  AuthRepositoryImpl({
    required this.remoteDataSource,
    // required this.networkInfo,
  });

  @override
  Future<Either<String, User>> signInWithGoogle() async {
    return await _performAuth(() => remoteDataSource.signInWithGoogle());
  }

  @override
  Future<Either<String, User>> signInWithMicrosoft() async {
    return await _performAuth(() => remoteDataSource.signInWithMicrosoft());
  }

  // @override
  // Future<Either<Failure, User>> signInWithEmail({
  //   required String email, 
  //   required String password
  // }) async {
  //   return await _performAuth(() => remoteDataSource.signInWithEmail(email, password));
  // }

  // Helper method to keep code DRY and handle errors globally
  Future<Either<String, User>> _performAuth(Future<UserModel> Function() action) async {
    if (true /* await networkInfo.isConnected */) {
      try {
        final remoteUser = await action();
        return Right(remoteUser);
      } on FirebaseAuthException catch (e) {
        return Left(e.message ?? 'Authentication Failed');
      } catch (e) {
        return Left('An unexpected error occurred');
      }
    } else {
      return Left('No internet connection');
    }
  }
}