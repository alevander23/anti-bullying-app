import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/data/data_sources/media_remote_data_source.dart';
import 'package:staff_webapp/domain/repository_contracts/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaRemoteDataSource remoteDataSource;

  MediaRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Uint8List>> fetchMediaBytes(String url) async {
    try {
      final bytes = await remoteDataSource.fetchProtectedBytes(url);
      return Right(bytes);
    } on NotSignedInException catch (e) {
      return Left(AuthFailure(e.message));
    } on MediaFetchException catch (e) {
      return Left(MediaFailure(e.message));
    } catch (e) {
      return Left(MediaFailure('Failed to load media: $e'));
    }
  }
}