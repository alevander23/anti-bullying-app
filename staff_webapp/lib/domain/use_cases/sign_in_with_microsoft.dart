// lib/domain/use_cases/sign_in_with_microsoft.dart
import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';
import 'package:staff_webapp/domain/use_cases/use_case.dart';

/// Use case for initiating Microsoft authentication flow
/// Uses the AuthRepository to handle the actual sign-in implementation
class SignInWithMicrosoft extends UseCase<User, NoParams> {
  final AuthRepository repository;
  SignInWithMicrosoft(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) =>
      repository.signInWithMicrosoft();
}