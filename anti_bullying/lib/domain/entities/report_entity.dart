import 'package:equatable/equatable.dart';

enum ReportCategory { bullying, harassment, safety, other }
enum ReportStatus { newReport, reviewed, escalated, resolved }
enum ReportPriority { normal, high }

class ReportEntity extends Equatable {
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

  const ReportEntity({
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

  @override
  List<Object?> get props => [
        id, schoolId, title, description, category, status, priority,
        isFlagged, submittedAt, updatedAt, reviewedBy, notes,
        closedAt, resolvedBy, deviceIdentifier, bullyNames,
      ];
}
