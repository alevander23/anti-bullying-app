// lib/presentation/bloc/group/group_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/data/data_models/group_model.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/group_repository.dart';
import 'group_state.dart';

class GroupCubit extends Cubit<GroupState> {
  final GroupRepository _repository;

  String? _schoolId;
  List<IncidentGroup> _groups = [];

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
        emit(GroupLoaded(groups: _groups));
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
      emit(GroupLoaded(groups: _groups, statusFilter: status));
    }
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
        // Update local list
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

        // Reload detail with fresh timeline
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
        emit(GroupLoaded(groups: _groups));
      },
    );
  }

  // ── Back to list ──────────────────────────────────────────────────────────

  void backToList() => emit(GroupLoaded(groups: _groups));

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _statusLabel(GroupStatus s) => switch (s) {
    GroupStatus.open        => 'open',
    GroupStatus.underReview => 'under review',
    GroupStatus.closed      => 'closed',
  };

  String _priorityLabel(GroupPriority p) =>
      p == GroupPriority.high ? 'high' : 'normal';
}