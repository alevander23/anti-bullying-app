// lib/data/repository_implementations/group_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/data/data_models/group_model.dart';
import 'package:staff_webapp/data/data_sources/group_remote_data_source.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupRemoteDataSource _dataSource;

  GroupRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<IncidentGroup>>> getGroups(String? schoolId) =>
      _run(() => schoolId != null
          ? _dataSource.getGroupsForSchool(schoolId)
          : _dataSource.getAllGroups());

  @override
  Future<Either<Failure, IncidentGroup>> getGroup(String groupId) =>
      _run(() async {
        final g = await _dataSource.getGroup(groupId);
        if (g == null) throw Exception('Group not found');
        return g;
      });

  @override
  Future<Either<Failure, String>> createGroup(IncidentGroup group) =>
      _run(() => _dataSource.createGroup(group));

  @override
  Future<Either<Failure, void>> updateGroup(
      String groupId,
      Map<String, dynamic> data,
      GroupTimelineEntry? timelineEntry) =>
      _run(() async {
        await _dataSource.updateGroup(groupId, data);
        if (timelineEntry != null) {
          await _dataSource.addTimelineEntry(groupId, timelineEntry);
        }
      });

  @override
  Future<Either<Failure, void>> deleteGroup(String groupId) =>
      _run(() => _dataSource.deleteGroup(groupId));

  @override
  Future<Either<Failure, List<GroupTimelineEntry>>> getTimeline(
          String groupId) =>
      _run(() => _dataSource.getTimeline(groupId));

  Future<Either<Failure, T>> _run<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return Left(const PermissionFailure());
      }
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    } catch (_) {
      return Left(const UnexpectedFailure());
    }
  }
}
