enum AuthProvider { microsoft, unknown }

/// Domain entity representing a user with core attributes and authentication status.
class User {
  /// Unique identifier for the user.
  final String id;

  /// Display name of the user.
  final String name;

  /// Email address associated with the user account.
  final String email;

  /// Whether the user has completed authorization verification.
  final bool isAuthorized;

  /// Authentication provider used to create the account.
  final AuthProvider authProvider;

  /// Optional URL for user profile photo (may be null).
  final String? photoUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAuthorized,
    required this.authProvider,
    this.photoUrl,
  });

  /// Properties used for value comparison.
  @override
  List<Object?> get props => [id, name, email, isAuthorized, authProvider, photoUrl];

  /// Generates a string representation of the user for debugging purposes.
  @override
  String toString() =>
      'User(id: $id, name: $name, email: $email, provider: ${authProvider.name})';
}