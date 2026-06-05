// lib/domain/entities/pending_admin_entity.dart
//
// Represents a user who has signed in via SSO but has not yet been approved
// as an admin for any school.

class PendingAdmin {
  final String id;        // Firebase Auth uid
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime requestedAt;

  const PendingAdmin({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.requestedAt,
  });
}
