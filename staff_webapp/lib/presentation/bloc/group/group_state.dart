// lib/presentation/bloc/group/group_state.dart

import 'package:equatable/equatable.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';

// ── Auto-grouping suggestion ─────────────────────────────────────────────────

/// A cluster of reports that share at least one bully name and fall within
/// [windowDays] of each other. Used to suggest potential groupings to the user.
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

/// Base class for all group-related states in the Bloc. Extends Equatable to
/// support state equality checks.
abstract class GroupState extends Equatable {
  const GroupState();
  @override
  List<Object?> get props => [];
}

/// Initial state when the group list is first loaded.
class GroupInitial extends GroupState {
  const GroupInitial();
}

/// State indicating the group list is currently being fetched.
class GroupLoading extends GroupState {
  const GroupLoading();
}

/// State containing the full list of incident groups and optional filtering.
/// Used to display group data in the UI.
class GroupLoaded extends GroupState {
  final List<IncidentGroup> groups;
  final GroupStatus? statusFilter;
  final List<AutoGroupSuggestion> suggestions;

  const GroupLoaded({
    required this.groups,
    this.statusFilter,
    this.suggestions = const [],
  });

  /// Returns a filtered version of [groups] based on [statusFilter]
  List<IncidentGroup> get filtered => statusFilter == null
      ? groups
      : groups.where((g) => g.status == statusFilter).toList();

  @override
  List<Object?> get props => [groups, statusFilter, suggestions];
}

/// State indicating detailed data for a specific group is being fetched.
class GroupDetailLoading extends GroupState {
  final String groupId;
  const GroupDetailLoading(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

/// State containing detailed information about a specific incident group.
class GroupDetailLoaded extends GroupState {
  final IncidentGroup group;
  final List<GroupTimelineEntry> timeline;

  const GroupDetailLoaded({required this.group, required this.timeline});

  @override
  List<Object?> get props => [group, timeline];
}

/// State indicating an error occurred during group operations.
class GroupError extends GroupState {
  final String message;
  const GroupError(this.message);
  @override
  List<Object?> get props => [message];
}

/// State indicating a group action (like update/delete) was successful.
class GroupActionSuccess extends GroupState {
  final String message;
  const GroupActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

/// State indicating an error occurred during a group action.
class GroupActionError extends GroupState {
  final String message;
  const GroupActionError(this.message);
  @override
  List<Object?> get props => [message];
}