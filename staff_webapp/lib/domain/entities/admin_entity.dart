enum AdminRole { admin, superAdmin }

class Admin {
  final String id;         // Firebase Auth uid
  final String email;
  final String name;
  final AdminRole role;    // The role of the admin, determining their permissions and access levels
  final String? schoolId;  // null for super_admin
  final bool isActive;     // Indicates whether the admin account is active
  final DateTime createdAt; // Timestamp when the admin account was created

  const Admin({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.schoolId,
    required this.isActive,
    required this.createdAt,
  });

  // Checks if the admin is a super admin
  bool get isSuperAdmin => role == AdminRole.superAdmin;

  // Determines if the admin can access data for a specific school
  // Super admins have access to all schools, while regular admins can only access their assigned school
  bool canAccessSchool(String schoolId) =>
      isSuperAdmin || this.schoolId == schoolId;
}