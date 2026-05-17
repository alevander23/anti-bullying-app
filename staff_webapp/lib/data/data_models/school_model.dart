import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:staff_webapp/domain/entities/school_entity.dart';

class SchoolModel extends School {
  const SchoolModel({
    required super.id,
    required super.name,
    required super.address,
    required super.isActive,
    required super.createdAt,
    super.resolvedReportRetentionDays,
    super.lastCleanupDate,
  });

  factory SchoolModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedReportRetentionDays: data['resolvedReportRetentionDays'] as int?,
      lastCleanupDate: (data['lastCleanupDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'address': address,
    'isActive': isActive,
    'createdAt': FieldValue.serverTimestamp(),
    if (resolvedReportRetentionDays != null)
      'resolvedReportRetentionDays': resolvedReportRetentionDays,
  };
}
