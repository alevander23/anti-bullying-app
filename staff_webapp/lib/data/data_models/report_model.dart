import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:staff_webapp/core/constants/firestore_constants.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';

class ReportModel extends Report {
  const ReportModel({
    required super.id,
    required super.schoolId,
    required super.title,
    required super.description,
    required super.category,
    required super.status,
    required super.priority,
    required super.isFlagged,
    required super.submittedAt,
    required super.updatedAt,
    super.reviewedBy,
    super.notes,
    super.closedAt,
    super.resolvedBy,
    super.deviceIdentifier,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      schoolId: data['schoolId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: _parseCategory(data['category'] as String?),
      status: _parseStatus(data['status'] as String?),
      priority: data['priority'] == FirestoreConstants.priorityHigh
          ? ReportPriority.high
          : ReportPriority.normal,
      isFlagged: data['isFlagged'] as bool? ?? false,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: data['reviewedBy'] as String?,
      notes: data['notes'] as String?,
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'] as String?,
      deviceIdentifier: data['deviceIdentifier'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'schoolId': schoolId,
    'title': title,
    'description': description,
    'category': _categoryToString(category),
    'status': _statusToString(status),
    'priority': priority == ReportPriority.high
        ? FirestoreConstants.priorityHigh
        : FirestoreConstants.priorityNormal,
    'isFlagged': isFlagged,
    'submittedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'reviewedBy': reviewedBy,
    'notes': notes,
    'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
    'resolvedBy': resolvedBy,
    'deviceIdentifier': deviceIdentifier,
  };

  // Update map — only fields that can change after creation
  static Map<String, dynamic> toUpdateMap({
    ReportStatus? status,
    ReportPriority? priority,
    bool? isFlagged,
    String? reviewedBy,
    String? notes,
    DateTime? closedAt,
    String? resolvedBy,
    bool clearResolvedBy = false,
    bool clearClosedAt = false,
  }) {
    final map = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status != null)    map['status'] = _statusToString(status);
    if (priority != null)  {map['priority'] = priority == ReportPriority.high
        ? FirestoreConstants.priorityHigh
        : FirestoreConstants.priorityNormal;
    }
    if (isFlagged != null) map['isFlagged'] = isFlagged;
    if (reviewedBy != null) map['reviewedBy'] = reviewedBy;
    if (notes != null)     map['notes'] = notes;
    if (clearClosedAt) {
      map['closedAt'] = FieldValue.delete();
    } else if (closedAt != null) {
      map['closedAt'] = Timestamp.fromDate(closedAt);
    }
    if (clearResolvedBy) {
      map['resolvedBy'] = FieldValue.delete();
    } else if (resolvedBy != null) {
      map['resolvedBy'] = resolvedBy;
    }
    return map;
  }

  static ReportStatus _parseStatus(String? s) => switch (s) {
    FirestoreConstants.statusReviewed  => ReportStatus.reviewed,
    FirestoreConstants.statusEscalated => ReportStatus.escalated,
    FirestoreConstants.statusResolved  => ReportStatus.resolved,
    _                                  => ReportStatus.newReport,
  };

  static String _statusToString(ReportStatus s) => switch (s) {
    ReportStatus.newReport  => FirestoreConstants.statusNew,
    ReportStatus.reviewed   => FirestoreConstants.statusReviewed,
    ReportStatus.escalated  => FirestoreConstants.statusEscalated,
    ReportStatus.resolved   => FirestoreConstants.statusResolved,
  };

  static ReportCategory _parseCategory(String? s) => switch (s) {
    FirestoreConstants.categoryBullying   => ReportCategory.bullying,
    FirestoreConstants.categoryHarassment => ReportCategory.harassment,
    FirestoreConstants.categorySafety     => ReportCategory.safety,
    _                                     => ReportCategory.other,
  };

  static String _categoryToString(ReportCategory c) => switch (c) {
    ReportCategory.bullying   => FirestoreConstants.categoryBullying,
    ReportCategory.harassment => FirestoreConstants.categoryHarassment,
    ReportCategory.safety     => FirestoreConstants.categorySafety,
    ReportCategory.other      => FirestoreConstants.categoryOther,
  };
}
