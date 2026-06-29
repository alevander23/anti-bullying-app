// lib/domain/entities/group_entity.dart

enum GroupStatus { open, underReview, closed }
enum GroupPriority { normal, high }

/// Represents a person involved in an incident group, including their role and notes.
class PersonInvolved {
  final String name;
  final String role; // 'Student', 'Staff', 'Other'
  final String? notes;

  const PersonInvolved({
    required this.name,
    required this.role,
    this.notes,
  });

  /// Creates a copy of this object with optional updates to its properties.
  PersonInvolved copyWith({String? name, String? role, String? notes}) =>
      PersonInvolved(
        name: name ?? this.name,
        role: role ?? this.role,
        notes: notes ?? this.notes,
      );
}

/// Represents a timeline entry for an incident group, capturing administrative actions.
class GroupTimelineEntry {
  final String id;
  final String message;
  final String adminName;
  final DateTime timestamp;

  const GroupTimelineEntry({
    required this.id,
    required this.message,
    required this.adminName,
    required this.timestamp,
  });
}

/// Encapsulates all details of an incident group, including status, priority, involved people, and related reports.
class IncidentGroup {
  final String id;
  final String schoolId;
  final String title;
  final String description;
  final String notes;
  final GroupStatus status;
  final GroupPriority priority;
  final List<PersonInvolved> peopleInvolved;
  final List<String> connectedReportIds;
  final List<String> tags;
  final String createdBy;     // admin name
  final String createdById;   // admin uid
  final DateTime createdAt;
  final DateTime updatedAt;

  const IncidentGroup({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.description,
    required this.notes,
    required this.status,
    required this.priority,
    required this.peopleInvolved,
    required this.connectedReportIds,
    required this.tags,
    required this.createdBy,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this object with optional updates to its properties.
  IncidentGroup copyWith({
    String? title,
    String? description,
    String? notes,
    GroupStatus? status,
    GroupPriority? priority,
    List<PersonInvolved>? peopleInvolved,
    List<String>? connectedReportIds,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return IncidentGroup(
      id: id,
      schoolId: schoolId,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      peopleInvolved: peopleInvolved ?? this.peopleInvolved,
      connectedReportIds: connectedReportIds ?? this.connectedReportIds,
      tags: tags ?? this.tags,
      createdBy: createdBy,
      createdById: createdById,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}