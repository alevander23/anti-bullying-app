// lib/domain/entities/pending_admin_entity.dart
//
// Represents a user who has signed in via SSO but has not yet been approved
// as an admin for any school. This entity is used to track pending admin requests
// in the domain layer.

class PendingAdmin {
  final String id;        // Firebase Auth uid
  final String email;
  final String name;
  final String? photoUrl; // Optional profile photo URL
  final DateTime requestedAt; // Timestamp when admin request was initiated

  const PendingAdmin({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.requestedAt,
  });
}