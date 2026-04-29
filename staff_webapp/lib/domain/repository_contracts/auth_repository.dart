// domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<String, User>> signInWithGoogle();
  Future<Either<String, User>> signInWithMicrosoft();
  // Future<Either<String, User>> signInWithEmail({
  //   required String email,
  //   required String password,
  // });
}