// lib/domain/use_cases/use_case.dart
//
// WHY: Replacing `String` with `Failure` makes error handling exhaustive and
// type-safe. `NoParams` is a standard sentinel for use-cases that need no
// input (e.g. SignOut, GetCurrentUser).

import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Sentinel for use-cases that take no parameters
class NoParams {
  const NoParams();
}
