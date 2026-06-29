/// Enum representing the possible statuses of a report in the domain layer.
enum ReportStatus { newReport, reviewed, escalated, resolved }
/// Enum representing the priority level of a report.
enum ReportPriority { normal, high }
/// Enum representing the category of a report.
enum ReportCategory { bullying, harassment, safety, other }

/// Which Firestore field to sort the report list by.
enum ReportSortField { updatedAt, submittedAt }

/// Domain entity representing a report, encapsulating all necessary data and behavior.
class Report {
  final String id;
  final String schoolId;
  final String title;
  final String description;
  final ReportCategory category;
  final ReportStatus status;
  final ReportPriority priority;
  final bool isFlagged;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final String? reviewedBy;
  final String? notes;
  final DateTime? closedAt;
  final String? resolvedBy;
  final String? deviceIdentifier;
  final List<String> bullyNames;

  const Report({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.isFlagged,
    required this.submittedAt,
    required this.updatedAt,
    this.reviewedBy,
    this.notes,
    this.closedAt,
    this.resolvedBy,
    this.deviceIdentifier,
    this.bullyNames = const [],
  });

  /// Returns true if the report is in the 'newReport' status.
  bool get isNew => status == ReportStatus.newReport;

  /// Returns true if the report has high priority or is flagged.
  /// High priority or flagged reports require urgent attention.
  bool get isHighPriority => priority == ReportPriority.high || isFlagged;

  /// Creates a copy of this report with optional updates.
  /// Use clearResolvedBy and clearClosedAt flags to explicitly clear those fields.
  Report copyWith({
    ReportStatus? status,
    ReportPriority? priority,
    bool? isFlagged,
    String? reviewedBy,
    String? notes,
    DateTime? updatedAt,
    DateTime? closedAt,
    String? resolvedBy,
    String? deviceIdentifier,
    List<String>? bullyNames,
    bool clearResolvedBy = false,
    bool clearClosedAt = false,
  }) {
    return Report(
      id: id,
      schoolId: schoolId,
      title: title,
      description: description,
      category: category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      isFlagged: isFlagged ?? this.isFlagged,
      submittedAt: submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      notes: notes ?? this.notes,
      closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
      resolvedBy: clearResolvedBy ? null : (resolvedBy ?? this.resolvedBy),
      deviceIdentifier: deviceIdentifier ?? this.deviceIdentifier,
      bullyNames: bullyNames ?? this.bullyNames,
    );
  }
}