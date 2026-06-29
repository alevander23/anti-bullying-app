// lib/domain/repository_contracts/group_repository.dart

import 'package:dartz/dartz.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';

/* Contract defining repository operations for managing groups. 
   Implementations handle data access and business rules. */

abstract class GroupRepository {
  // Fetches all groups, optionally filtered by school ID.
  Future<Either<Failure, List<IncidentGroup>>> getGroups(String? schoolId);

  // Retrieves a single group by ID.
  Future<Either<Failure, IncidentGroup>> getGroup(String groupId);

  // Creates a new group with the provided data.
  Future<Either<Failure, String>> createGroup(IncidentGroup group);

  // Updates an existing group with new data and optional timeline entry.
  Future<Either<Failure, void>> updateGroup(
      String groupId, Map<String, dynamic> data, GroupTimelineEntry? timelineEntry);

  // Deletes a group by ID.
  Future<Either<Failure, void>> deleteGroup(String groupId);

  // Retrieves the timeline history for a specific group.
  Future<Either<Failure, List<GroupTimelineEntry>>> getTimeline(String groupId);
}