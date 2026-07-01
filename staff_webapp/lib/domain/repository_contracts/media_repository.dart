import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';

abstract class MediaRepository {
  /// Fetches the raw bytes of a protected media file at [url].
  /// The implementation is responsible for attaching the current admin's
  /// auth token to the request.
  Future<Either<Failure, Uint8List>> fetchMediaBytes(String url);
}