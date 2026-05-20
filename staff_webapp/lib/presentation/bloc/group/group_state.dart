// lib/presentation/bloc/group/group_state.dart

import 'package:equatable/equatable.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';

// ── Auto-grouping suggestion ─────────────────────────────────────────────────

/// A cluster of reports that share at least one bully name and fall within
/// [windowDays] of each other.
class AutoGroupSuggestion {
  final String id; // stable key derived from sorted bully names
  final List<String> bullyNames;
  final List<Report> reports;
  final DateTime earliest;
  final DateTime latest;

  const AutoGroupSuggestion({
    required this.id,
    required this.bullyNames,
    required this.reports,
    required this.earliest,
    required this.latest,
  });

  int get daySpan => latest.difference(earliest).inDays;
}

// ── States ───────────────────────────────────────────────────────────────────

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
  final List<AutoGroupSuggestion> suggestions;

  const GroupLoaded({
    required this.groups,
    this.statusFilter,
    this.suggestions = const [],
  });

  List<IncidentGroup> get filtered => statusFilter == null
      ? groups
      : groups.where((g) => g.status == statusFilter).toList();

  @override
  List<Object?> get props => [groups, statusFilter, suggestions];
}

class GroupDetailLoading extends GroupState {
  final String groupId;
  const GroupDetailLoading(this.groupId);
  @override
  List<Object?> get props => [groupId];
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