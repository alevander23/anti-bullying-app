// lib/presentation/bloc/group/group_state.dart

import 'package:equatable/equatable.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';

abstract class GroupState extends Equatable {
  const GroupState();
  @override
  List<Object?> get props => [];
}

class GroupInitial extends GroupState {
  const GroupInitial();
}

class GroupLoading extends GroupState {
  const GroupLoading();
}

class GroupLoaded extends GroupState {
  final List<IncidentGroup> groups;
  final GroupStatus? statusFilter;

  const GroupLoaded({required this.groups, this.statusFilter});

  List<IncidentGroup> get filtered => statusFilter == null
      ? groups
      : groups.where((g) => g.status == statusFilter).toList();

  @override
  List<Object?> get props => [groups, statusFilter];
}

class GroupDetailLoaded extends GroupState {
  final IncidentGroup group;
  final List<GroupTimelineEntry> timeline;

  const GroupDetailLoaded({required this.group, required this.timeline});

  @override
  List<Object?> get props => [group, timeline];
}

class GroupError extends GroupState {
  final String message;
  const GroupError(this.message);
  @override
  List<Object?> get props => [message];
}

class GroupActionSuccess extends GroupState {
  final String message;
  const GroupActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class GroupActionError extends GroupState {
  final String message;
  const GroupActionError(this.message);
  @override
  List<Object?> get props => [message];
}
