// domain/usecases/sign_in_with_google.dart
import 'package:dartz/dartz.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';
import 'package:staff_webapp/domain/use_cases/use_case.dart';

// TODO: I want to replace the string with a proper failure class

class SignInWithGoogle extends UseCase<User, GoogleParams> {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  @override
  Future<Either<String, User>> call(GoogleParams googleParams) async {
    return await repository.signInWithGoogle();
  }
}

class GoogleParams {}
