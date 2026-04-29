import 'package:dartz/dartz.dart'; // Optional: for Either type
import '../entities/user_entity.dart';
// import '../../core/error/failures.dart';

// TODO: I want to replace the string with a proper failure class

abstract class UseCase<Type, Params> {
  Future<Either<String, Type>> call(Params params);
}