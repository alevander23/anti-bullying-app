class User {
  final String id;
  final String name;
  final bool isAuthorized;

  const User({
    required this.id,
    required this.name,
    required this.isAuthorized,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        isAuthorized,
      ];
}