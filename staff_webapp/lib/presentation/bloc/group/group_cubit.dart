// lib/presentation/bloc/group/group_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/data/data_models/group_model.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/group_repository.dart';
import 'group_state.dart';

class GroupCubit extends Cubit<GroupState> {
  final GroupRepository _repository;

  String? _schoolId;
  List<IncidentGroup> _groups = [];
  List<AutoGroupSuggestion> _suggestions = [];

  GroupCubit(this._repository) : super(const GroupInitial());

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadGroups(String? schoolId) async {
    _schoolId = schoolId;
    emit(const GroupLoading());
    final result = await _repository.getGroups(schoolId);
    result.fold(
      (f) => emit(GroupError(f.message)),
      (groups) {
        _groups = groups;
        emit(GroupLoaded(groups: _groups, suggestions: _suggestions));
      },
    );
  }

  Future<void> loadGroupDetail(String groupId) async {
    emit(GroupDetailLoading(groupId));
    final groupResult = await _repository.getGroup(groupId);
    final timelineResult = await _repository.getTimeline(groupId);

    groupResult.fold(
      (f) => emit(GroupError(f.message)),
      (group) {
        timelineResult.fold(
          (f) => emit(GroupDetailLoaded(group: group, timeline: [])),
          (timeline) => emit(GroupDetailLoaded(group: group, timeline: timeline)),
        );
      },
    );
  }

  void setStatusFilter(GroupStatus? status) {
    if (state is GroupLoaded) {
      final s = state as GroupLoaded;
      emit(GroupLoaded(groups: _groups, statusFilter: status, suggestions: _suggestions));
    }
  }

  void computeSuggestions(List<Report> allReports, {int windowDays = 5}) {
    // Only consider reports that name at least one bully.
    final withBullies = allReports.where((r) => r.bullyNames.isNotEmpty).toList();

    // We do a union-find style merge: iterate each report and see if it overlaps (shared name + within windowDays) with any existing cluster.
    final List<_Cluster> clusters = [];

    for (final report in withBullies) {
      // Find all clusters that share at least one bully name with this report.
      final matching = <int>[];
      for (int i = 0; i < clusters.length; i++) {
        final cluster = clusters[i];
        final sharesBully = report.bullyNames.any((n) =>
            cluster.bullyNames.contains(n.toLowerCase().trim()));
        if (!sharesBully) continue;

        // Check temporal proximity: report must be within windowDays of the
        // cluster's current date range.
        final clusterEarliest = cluster.reports
            .map((r) => r.submittedAt)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        final clusterLatest = cluster.reports
            .map((r) => r.submittedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        final reportDate = report.submittedAt;
        final withinWindow =
            reportDate.difference(clusterEarliest).inDays.abs() <= windowDays ||
            reportDate.difference(clusterLatest).inDays.abs() <= windowDays;

        if (withinWindow) matching.add(i);
      }

      if (matching.isEmpty) {
        clusters.add(_Cluster(
          bullyNames: report.bullyNames.map((n) => n.toLowerCase().trim()).toSet(),
          reports: [report],
        ));
      } else {
        final primary = clusters[matching.first];
        for (final name in report.bullyNames) {
          primary.bullyNames.add(name.toLowerCase().trim());
        }
        primary.reports.add(report);

        for (final idx in matching.skip(1).toList().reversed) {
          primary.bullyNames.addAll(clusters[idx].bullyNames);
          primary.reports.addAll(clusters[idx].reports);
          clusters.removeAt(idx);
        }
      }
    }

    // Filter to only clusters with ≥2 reports (single reports aren't interesting).
    // Also skip clusters whose report IDs are all already covered by an existing group.
    final existingReportIds = _groups
        .expand((g) => g.connectedReportIds)
        .toSet();

    _suggestions = clusters
        .where((c) => c.reports.length >= 2)
        .where((c) => c.reports.any((r) => !existingReportIds.contains(r.id)))
        .map((c) {
          final sortedNames = c.bullyNames.toList()..sort();
          final dates = c.reports.map((r) => r.submittedAt).toList()..sort();
          return AutoGroupSuggestion(
            id: sortedNames.join('|'),
            bullyNames: sortedNames,
            reports: c.reports,
            earliest: dates.first,
            latest: dates.last,
          );
        })
        .toList();

    // Re-emit loaded state with suggestions if we're already loaded.
    if (state is GroupLoaded) {
      final s = state as GroupLoaded;
      emit(GroupLoaded(
        groups: _groups,
        statusFilter: s.statusFilter,
        suggestions: _suggestions,
      ));
    }
  }

  /// Promotes an [AutoGroupSuggestion] to a real [IncidentGroup].
  Future<void> confirmSuggestion({
    required AutoGroupSuggestion suggestion,
    required String adminName,
    required String adminId,
    required String schoolId,
  }) async {
    // Build a sensible title from bully names.
    final nameDisplay = suggestion.bullyNames
        .map((n) => _capitalize(n))
        .join(', ');
    final title = 'Incidents involving $nameDisplay';

    // Build people-involved list from bully names.
    final people = suggestion.bullyNames
        .map((n) => PersonInvolved(name: _capitalize(n), role: 'Student'))
        .toList();

    final group = IncidentGroup(
      id: '',
      schoolId: schoolId,
      title: title,
      description:
          'Auto-generated group. ${suggestion.reports.length} reports '
          'spanning ${suggestion.daySpan} day(s) involving: $nameDisplay.',
      notes: '',
      status: GroupStatus.open,
      priority: GroupPriority.normal,
      peopleInvolved: people,
      connectedReportIds: suggestion.reports.map((r) => r.id).toList(),
      tags: ['auto-grouped'],
      createdBy: adminName,
      createdById: adminId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _repository.createGroup(group);
    result.fold(
      (f) => emit(GroupActionError(f.message)),
      (id) {
        // Remove the suggestion from local list.
        _suggestions = _suggestions.where((s) => s.id != suggestion.id).toList();
        // Add new group to local list.
        _groups = [group.copyWith(), ..._groups];
        emit(const GroupActionSuccess('Group created from suggestion'));
        emit(GroupLoaded(groups: _groups, suggestions: _suggestions));
      },
    );
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<String?> createGroup(IncidentGroup group) async {
    final result = await _repository.createGroup(group);
    return result.fold(
      (f) {
        emit(GroupActionError(f.message));
        return null;
      },
      (id) {
        _groups = [group.copyWith(), ..._groups];
        emit(const GroupActionSuccess('Group created'));
        return id;
      },
    );
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> updateGroup({
    required String groupId,
    required IncidentGroup original,
    String? title,
    String? description,
    String? notes,
    GroupStatus? status,
    GroupPriority? priority,
    List<PersonInvolved>? peopleInvolved,
    List<String>? connectedReportIds,
    List<String>? tags,
    required String adminName,
  }) async {
    final changes = <String>[];
    if (title != null && title != original.title) changes.add('title updated');
    if (description != null && description != original.description) changes.add('description updated');
    if (notes != null && notes != original.notes) changes.add('notes updated');
    if (status != null && status != original.status) changes.add('status changed to ${_statusLabel(status)}');
    if (priority != null && priority != original.priority) changes.add('priority changed to ${_priorityLabel(priority)}');
    if (peopleInvolved != null) changes.add('people involved updated');
    if (connectedReportIds != null) {
      final added = connectedReportIds.length - original.connectedReportIds.length;
      if (added > 0) changes.add('$added report(s) linked');
      if (added < 0) changes.add('${added.abs()} report(s) unlinked');
    }
    if (tags != null) changes.add('tags updated');

    if (changes.isEmpty) return;

    final timelineEntry = GroupTimelineEntry(
      id: '',
      message: changes.join(', '),
      adminName: adminName,
      timestamp: DateTime.now(),
    );

    final data = GroupModel.toUpdateMap(
      title: title,
      description: description,
      notes: notes,
      status: status,
      priority: priority,
      peopleInvolved: peopleInvolved,
      connectedReportIds: connectedReportIds,
      tags: tags,
    );

    final result = await _repository.updateGroup(groupId, data, timelineEntry);
    result.fold(
      (f) => emit(GroupActionError(f.message)),
      (_) {
        _groups = _groups.map((g) {
          if (g.id != groupId) return g;
          return g.copyWith(
            title: title,
            description: description,
            notes: notes,
            status: status,
            priority: priority,
            peopleInvolved: peopleInvolved,
            connectedReportIds: connectedReportIds,
            tags: tags,
            updatedAt: DateTime.now(),
          );
        }).toList();

        loadGroupDetail(groupId);
        emit(const GroupActionSuccess('Group updated'));
      },
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteGroup(String groupId) async {
    final result = await _repository.deleteGroup(groupId);
    result.fold(
      (f) => emit(GroupActionError(f.message)),
      (_) {
        _groups = _groups.where((g) => g.id != groupId).toList();
        emit(const GroupActionSuccess('Group deleted'));
        emit(GroupLoaded(groups: _groups, suggestions: _suggestions));
      },
    );
  }

  // ── Back to list ──────────────────────────────────────────────────────────

  void backToList() => emit(GroupLoaded(groups: _groups, suggestions: _suggestions));

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _statusLabel(GroupStatus s) => switch (s) {
    GroupStatus.open        => 'open',
    GroupStatus.underReview => 'under review',
    GroupStatus.closed      => 'closed',
  };

  String _priorityLabel(GroupPriority p) =>
      p == GroupPriority.high ? 'high' : 'normal';

  String _capitalize(String s) => s.isEmpty
      ? s
      : s[0].toUpperCase() + s.substring(1);
}

// ── Internal cluster builder ──────────────────────────────────────────────────

class _Cluster {
  final Set<String> bullyNames;
  final List<Report> reports;
  _Cluster({required this.bullyNames, required this.reports});
}