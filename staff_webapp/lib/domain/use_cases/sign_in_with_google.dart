// lib/domain/use_cases/sign_in_with_google.dart
import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';
import 'package:staff_webapp/domain/use_cases/use_case.dart';

class SignInWithGoogle extends UseCase<User, NoParams> {
  final AuthRepository repository;
  SignInWithGoogle(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) =>
      repository.signInWithGoogle();
}
