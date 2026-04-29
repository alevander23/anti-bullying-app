import 'package:dartz/dartz.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';
import 'package:staff_webapp/domain/use_cases/use_case.dart';

// TODO: I want to replace the string with a proper failure class

// domain/usecases/sign_in_with_microsoft.dart
class SignInWithMicrosoft extends UseCase<User, MicrosoftParams> {
  final AuthRepository repository;

  SignInWithMicrosoft(this.repository);

  @override
  Future<Either<String, User>> call(MicrosoftParams microsoftParams) async {
    return await repository.signInWithMicrosoft();
  }
}

class MicrosoftParams {}