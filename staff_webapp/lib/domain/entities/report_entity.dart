enum ReportStatus { newReport, reviewed, escalated, resolved }
enum ReportPriority { normal, high }
enum ReportCategory { bullying, harassment, safety, other }

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
  });

  bool get isNew        => status == ReportStatus.newReport;
  bool get isHighPriority => priority == ReportPriority.high || isFlagged;

  Report copyWith({
    ReportStatus? status,
    ReportPriority? priority,
    bool? isFlagged,
    String? reviewedBy,
    String? notes,
    DateTime? updatedAt,
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
    );
  }
}
