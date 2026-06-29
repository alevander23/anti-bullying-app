import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';
import 'package:staff_webapp/domain/use_cases/use_case.dart';

// Use case to retrieve the current user from the authentication repository.
// This is a domain-layer implementation that depends on AuthRepository.
class GetCurrentUserUseCase extends UseCase<User?, NoParams> {
  final AuthRepository repository;
  GetCurrentUserUseCase(this.repository);

  @override
  // Executes the use case by calling the repository's getCurrentUser method.
  // Returns a Future that resolves to either a Failure or the current User (if any).
  Future<Either<Failure, User?>> call(NoParams params) =>
      repository.getCurrentUser();
}