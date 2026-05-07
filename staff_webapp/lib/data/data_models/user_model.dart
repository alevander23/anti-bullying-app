import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:staff_webapp/domain/entities/user_entity.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.isAuthorized,
    required super.authProvider,
    super.photoUrl,
  });

  factory UserModel.fromFirebaseUser(
    fb.User firebaseUser, {
    bool isAuthorized = true,
    AuthProvider provider = AuthProvider.unknown,
  }) {
    return UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? firebaseUser.email ?? 'Unknown',
      email: firebaseUser.email ?? '',
      isAuthorized: isAuthorized,
      authProvider: provider,
      photoUrl: firebaseUser.photoURL,
    );
  }
}
