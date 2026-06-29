import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:staff_webapp/domain/entities/school_entity.dart';

/// Data model for Firestore representation of a school entity
/// Maps directly to the SchoolEntity in the domain layer
/// Handles serialization/deserialization between Firestore and domain objects
class SchoolModel extends School {
  const SchoolModel({
    required super.id,
    required super.name,
    required super.address,
    required super.isActive,
    required super.createdAt,
    super.resolvedReportRetentionDays,
    super.lastCleanupDate,
    super.autoGroupWindowDays = 5,
  });

  /// Creates a SchoolModel from a Firestore document snapshot
  /// Handles default values for optional fields and type conversions
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
      autoGroupWindowDays: data['autoGroupWindowDays'] as int? ?? 5,
    );
  }

  /// Converts this model to a Firestore-compatible map
  /// Uses server timestamp for createdAt and includes optional fields conditionally
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'address': address,
    'isActive': isActive,
    'createdAt': FieldValue.serverTimestamp(),
    if (resolvedReportRetentionDays != null)
      'resolvedReportRetentionDays': resolvedReportRetentionDays,
    'autoGroupWindowDays': autoGroupWindowDays,
  };
}