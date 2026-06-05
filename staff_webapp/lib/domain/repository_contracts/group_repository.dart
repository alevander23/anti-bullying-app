// lib/domain/repository_contracts/group_repository.dart

import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';

abstract class GroupRepository {
  Future<Either<Failure, List<IncidentGroup>>> getGroups(String? schoolId);

  Future<Either<Failure, IncidentGroup>> getGroup(String groupId);

  Future<Either<Failure, String>> createGroup(IncidentGroup group);

  Future<Either<Failure, void>> updateGroup(
      String groupId, Map<String, dynamic> data, GroupTimelineEntry? timelineEntry);

  Future<Either<Failure, void>> deleteGroup(String groupId);

  Future<Either<Failure, List<GroupTimelineEntry>>> getTimeline(String groupId);
}
