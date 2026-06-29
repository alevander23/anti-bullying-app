import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';
import 'package:staff_webapp/domain/use_cases/use_case.dart';

/// Use case for handling user sign-out operations
/// Delegates to the auth repository to perform the actual sign-out
class SignOutUseCase extends UseCase<void, NoParams> {
  final AuthRepository repository;
  SignOutUseCase(this.repository);

  @override
  /// Executes the sign-out process
  /// Returns a Future that completes with either a Failure or void
  Future<Either<Failure, void>> call(NoParams params) => repository.signOut();
}