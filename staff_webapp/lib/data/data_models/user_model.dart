import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:staff_webapp/domain/entities/user_entity.dart';

/// Data model representing a user, mapping Firebase User to the domain's [UserEntity]
/// This class lives in the data layer and contains implementation details
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.isAuthorized,
    required super.authProvider,
    super.photoUrl,
  });

  /// Factory method to convert Firebase User to UserModel
  /// Handles default values for optional fields and provider setup
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