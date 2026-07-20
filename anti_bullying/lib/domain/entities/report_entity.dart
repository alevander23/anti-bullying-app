import 'package:equatable/equatable.dart';

// what kind of incident this report is about
enum ReportCategory { bullying, harassment, safety, other }
// tracks where the report is in the review workflow
enum ReportStatus { newReport, reviewed, escalated, resolved }
enum ReportPriority { normal, high }

// core domain object for a submitted report, kept free of any Firestore specifics
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
  // these are only set once a staff member has actually looked at it
  final String? reviewedBy;
  final String? notes;
  final DateTime? closedAt;
  final String? resolvedBy;
  final String? deviceIdentifier;
  final List<String> bullyNames;
  final List<String> mediaUrls; // ← ADDED

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
    this.mediaUrls = const [], // ← ADDED
  });

  // every field goes in here so equatable can diff old vs new state properly
  @override
  List<Object?> get props => [
        id, schoolId, title, description, category, status, priority,
        isFlagged, submittedAt, updatedAt, reviewedBy, notes,
        closedAt, resolvedBy, deviceIdentifier, bullyNames, mediaUrls, // ← ADDED
      ];
}