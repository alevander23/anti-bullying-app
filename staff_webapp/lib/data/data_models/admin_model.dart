import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:staff_webapp/core/constants/firestore_constants.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';

class AdminModel extends Admin {
  const AdminModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.schoolId,
    required super.isActive,
    required super.createdAt,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] == FirestoreConstants.roleSuperAdmin
          ? AdminRole.superAdmin
          : AdminRole.admin,
      schoolId: data['schoolId'] as String?,
      isActive: data['isActive'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'name': name,
    'role': role == AdminRole.superAdmin
        ? FirestoreConstants.roleSuperAdmin
        : FirestoreConstants.roleAdmin,
    'schoolId': schoolId,
    'isActive': isActive,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
