// lib/domain/use_cases/use_case.dart
//
// WHY: Replacing `String` with `Failure` makes error handling exhaustive and
// type-safe. `NoParams` is a standard sentinel for use-cases that need no
// input (e.g. SignOut, GetCurrentUser).

import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';

/// Abstract base class for all use cases in the domain layer. Enforces a consistent
/// structure where use cases accept parameters and return either a success value
/// or a failure, ensuring type-safe error handling.
abstract class UseCase<Type, Params> {
  // Executes the use case with the provided parameters.
  Future<Either<Failure, Type>> call(Params params);
}

// Sentinel for use-cases that take no parameters
class NoParams {
  const NoParams();
}