enum AuthProvider { microsoft, unknown }

class User {
  final String id;
  final String name;
  final String email;
  final bool isAuthorized;
  final AuthProvider authProvider;
  final String? photoUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAuthorized,
    required this.authProvider,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, name, email, isAuthorized, authProvider, photoUrl];

  @override
  String toString() =>
      'User(id: $id, name: $name, email: $email, provider: ${authProvider.name})';
}
