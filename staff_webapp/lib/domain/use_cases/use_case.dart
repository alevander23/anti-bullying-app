import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';

abstract class UseCase<Type, Params> {
  // Executes the use case with the provided parameters.
  Future<Either<Failure, Type>> call(Params params);
}

// Sentinel for use-cases that take no parameters
class NoParams {
  const NoParams();
}