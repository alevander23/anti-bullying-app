import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';
import 'package:staff_webapp/domain/use_cases/use_case.dart';

class SignOutUseCase extends UseCase<void, NoParams> {
  final AuthRepository repository;
  SignOutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) => repository.signOut();
}
