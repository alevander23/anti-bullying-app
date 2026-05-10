enum AdminRole { admin, superAdmin }

class Admin {
  final String id;         // Firebase Auth uid
  final String email;
  final String name;
  final AdminRole role;
  final String? schoolId;  // null for super_admin
  final bool isActive;
  final DateTime createdAt;

  const Admin({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.schoolId,
    required this.isActive,
    required this.createdAt,
  });

  bool get isSuperAdmin => role == AdminRole.superAdmin;

  // Can this admin access a given school's data?
  bool canAccessSchool(String schoolId) =>
      isSuperAdmin || this.schoolId == schoolId;
}
