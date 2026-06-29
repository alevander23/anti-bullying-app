import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_database/firebase_database.dart';
import 'package:staff_webapp/data/data_models/user_model.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';

class UserRemoteDataSource {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseDatabase _database;

  // Realtime Database node: /users/{uid}
  // This structure allows per-user data storage and retrieval
  static const String _usersNode = 'users';

  UserRemoteDataSource({
    required fb.FirebaseAuth firebaseAuth,
    FirebaseDatabase? database,
  })  // Database is optional, defaulting to FirebaseDatabase.instance
      : _firebaseAuth = firebaseAuth,
        _database = database ?? FirebaseDatabase.instance;

  // Retrieves the current user's profile from Firebase Authentication and Realtime Database

  Future<UserModel?> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    return _fetchOrCreateProfile(fbUser);
  }

  // Handles email/password login using Firebase Authentication

  Future<UserModel?> login(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = credential.user;
    if (fbUser == null) return null;
    return _fetchOrCreateProfile(fbUser);
  }

  // Handles Microsoft SSO login using Firebase Authentication

  Future<UserModel?> signInWithMicrosoft() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    return _fetchOrCreateProfile(fbUser, provider: AuthProvider.microsoft);
  }

  // Helpers

  /// Reads the user profile from /users/{uid}.
  /// If no profile exists yet (first SSO login), creates one automatically.
  /// Merges Firebase user data with database-stored values when available
  Future<UserModel?> _fetchOrCreateProfile(
    fb.User fbUser, {
    AuthProvider provider = AuthProvider.unknown,
  }) async {
    final ref = _database.ref('$_usersNode/${fbUser.uid}');
    final snapshot = await ref.get();

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return UserModel(
        id: fbUser.uid,
        name: data['name'] as String? ?? fbUser.displayName ?? fbUser.email ?? 'Unknown',
        email: data['email'] as String? ?? fbUser.email ?? '',
        isAuthorized: data['isAuthorized'] as bool? ?? false,
        authProvider: _providerFromString(data['provider'] as String?),
        photoUrl: data['photoUrl'] as String?,
      );
    }

    // First login write a new profile
    await _writeProfile(fbUser, provider: provider);
    return UserModel.fromFirebaseUser(
      fbUser,
      isAuthorized: false, // default to false; an admin grants access
      provider: provider,
    );
  }

  /// Writes (or overwrites) a user profile node in Realtime Database.
  /// Used to initialize or update user data during login/registration
  Future<void> _writeProfile(fb.User fbUser, {required AuthProvider provider}) async {
    final ref = _database.ref('$_usersNode/${fbUser.uid}');
    await ref.set({
      'name': fbUser.displayName ?? fbUser.email ?? 'Unknown',
      'email': fbUser.email ?? '',
      'isAuthorized': false, // admin sets this to true manually
      'provider': provider.name,
      'photoUrl': fbUser.photoURL,
      'createdAt': ServerValue.timestamp,
    });
  }

  AuthProvider _providerFromString(String? value) {
    return AuthProvider.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AuthProvider.unknown,
    );
  }
}