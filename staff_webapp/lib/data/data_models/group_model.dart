// lib/data/data_models/group_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';

class GroupModel {
  static IncidentGroup fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    List<PersonInvolved> people = [];
    if (d['peopleInvolved'] is List) {
      people = (d['peopleInvolved'] as List).map((e) {
        final m = e as Map<String, dynamic>;
        return PersonInvolved(
          name: m['name'] as String? ?? '',
          role: m['role'] as String? ?? 'Other',
          notes: m['notes'] as String?,
        );
      }).toList();
    }

    List<GroupTimelineEntry> timeline = [];
    if (d['timeline'] is List) {
      timeline = (d['timeline'] as List).map((e) {
        final m = e as Map<String, dynamic>;
        return GroupTimelineEntry(
          id: m['id'] as String? ?? '',
          message: m['message'] as String? ?? '',
          adminName: m['adminName'] as String? ?? '',
          timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    }

    return IncidentGroup(
      id: doc.id,
      schoolId: d['schoolId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      notes: d['notes'] as String? ?? '',
      status: _statusFromString(d['status'] as String?),
      priority: _priorityFromString(d['priority'] as String?),
      peopleInvolved: people,
      connectedReportIds: List<String>.from(d['connectedReports'] ?? []),
      tags: List<String>.from(d['tags'] ?? []),
      createdBy: d['createdBy'] as String? ?? '',
      createdById: d['createdById'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toFirestore(IncidentGroup g) => {
    'schoolId': g.schoolId,
    'title': g.title,
    'description': g.description,
    'notes': g.notes,
    'status': _statusToString(g.status),
    'priority': _priorityToString(g.priority),
    'peopleInvolved': g.peopleInvolved.map(_personToMap).toList(),
    'connectedReports': g.connectedReportIds,
    'tags': g.tags,
    'createdBy': g.createdBy,
    'createdById': g.createdById,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static Map<String, dynamic> toUpdateMap({
    String? title,
    String? description,
    String? notes,
    GroupStatus? status,
    GroupPriority? priority,
    List<PersonInvolved>? peopleInvolved,
    List<String>? connectedReportIds,
    List<String>? tags,
    GroupTimelineEntry? timelineEntry,
  }) {
    final map = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (notes != null) map['notes'] = notes;
    if (status != null) map['status'] = _statusToString(status);
    if (priority != null) map['priority'] = _priorityToString(priority);
    if (peopleInvolved != null) {
      map['peopleInvolved'] = peopleInvolved.map(_personToMap).toList();
    }
    if (connectedReportIds != null) {
      map['connectedReports'] = connectedReportIds;
    }
    if (tags != null) map['tags'] = tags;
    if (timelineEntry != null) {
      map['timeline'] = FieldValue.arrayUnion([_timelineEntryToMap(timelineEntry)]);
    }
    return map;
  }

  static Map<String, dynamic> _personToMap(PersonInvolved p) => {
    'name': p.name,
    'role': p.role,
    if (p.notes != null) 'notes': p.notes,
  };

  static Map<String, dynamic> _timelineEntryToMap(GroupTimelineEntry e) => {
    'id': e.id,
    'message': e.message,
    'adminName': e.adminName,
    'timestamp': Timestamp.fromDate(e.timestamp),
  };

  static GroupStatus _statusFromString(String? s) => switch (s) {
    'under_review' => GroupStatus.underReview,
    'closed'       => GroupStatus.closed,
    _              => GroupStatus.open,
  };

  static String _statusToString(GroupStatus s) => switch (s) {
    GroupStatus.open        => 'open',
    GroupStatus.underReview => 'under_review',
    GroupStatus.closed      => 'closed',
  };

  static GroupPriority _priorityFromString(String? s) =>
      s == 'high' ? GroupPriority.high : GroupPriority.normal;

  static String _priorityToString(GroupPriority p) =>
      p == GroupPriority.high ? 'high' : 'normal';
}
