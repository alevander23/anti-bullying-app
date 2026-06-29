// lib/data/data_models/pending_admin_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:staff_webapp/domain/entities/pending_admin_entity.dart';

/// Model for handling pending admin data persistence and retrieval from Firestore
/// This class maps between Firestore documents and the domain entity
class PendingAdminModel extends PendingAdmin {
  const PendingAdminModel({
    required super.id,
    required super.email,
    required super.name,
    super.photoUrl,
    required super.requestedAt,
  });

  /// Creates a model instance from a Firestore document
  /// Handles null values and default fallbacks for required fields
  factory PendingAdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PendingAdminModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts model to Firestore-compatible map for persistence
  /// Uses server timestamp for requestedAt field
  Map<String, dynamic> toFirestore() => {
        'email': email,
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'requestedAt': FieldValue.serverTimestamp(),
      };
}