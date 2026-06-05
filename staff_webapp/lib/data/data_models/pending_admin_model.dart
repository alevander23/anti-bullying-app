// lib/data/data_models/pending_admin_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:staff_webapp/domain/entities/pending_admin_entity.dart';

class PendingAdminModel extends PendingAdmin {
  const PendingAdminModel({
    required super.id,
    required super.email,
    required super.name,
    super.photoUrl,
    required super.requestedAt,
  });

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

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'requestedAt': FieldValue.serverTimestamp(),
      };
}
