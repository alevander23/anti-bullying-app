import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:staff_webapp/core/constants/firestore_constants.dart';
import 'package:staff_webapp/data/data_models/user_model.dart';
import 'package:staff_webapp/data/data_sources/auth_remote_data_source.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  static const String _tenantId = 'common';

  AuthRemoteDataSourceImpl({
    required fb.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  @override
  Future<UserModel> signInWithMicrosoft() async {
    final provider = fb.OAuthProvider('microsoft.com')
      ..setCustomParameters({'tenant': _tenantId})
      ..addScope('email')
      ..addScope('openid')
      ..addScope('profile');

    final fb.UserCredential credential;
    try {
      credential = await _firebaseAuth.signInWithPopup(provider);
    } on fb.FirebaseAuthException catch (e) {
      print('FirebaseAuthException: code=${e.code} message=${e.message}');
      rethrow;
    } catch (e, stack) {
      print('Unknown error: $e');
      print(stack);
      rethrow;
    }

    final fbUser = credential.user;
    if (fbUser == null) {
      throw fb.FirebaseAuthException(
        code: 'null-user',
        message: 'Microsoft sign-in returned no user.',
      );
    }

    return UserModel.fromFirebaseUser(
      fbUser,
      isAuthorized: await _checkAuthorization(fbUser),
      provider: AuthProvider.microsoft,
    );
  }


  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut()
    ]);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;

    await fbUser.reload();
    final refreshed = _firebaseAuth.currentUser;
    if (refreshed == null) return null;

    final provider = _providerFromUser(refreshed);
    return UserModel.fromFirebaseUser(
      refreshed,
      isAuthorized: await _checkAuthorization(refreshed),
      provider: provider,
    );
  }

  AuthProvider _providerFromUser(fb.User fbUser) {
    for (final info in fbUser.providerData) {
      if (info.providerId == 'microsoft.com') return AuthProvider.microsoft;
    }
    return AuthProvider.unknown;
  }

  /// Checks if the signed-in user has an active admin document.
  /// If not, writes a pendingAdmins doc so an existing admin can approve them.
  Future<bool> _checkAuthorization(fb.User fbUser) async {
    try {
      final adminDoc = await _firestore
          .collection(FirestoreConstants.admins)
          .doc(fbUser.uid)
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>;
        final isActive = data['isActive'] as bool? ?? false;
        return isActive;
      }

      // Not an admin — write/update a pending request so admins can approve them
      await _firestore
          .collection(FirestoreConstants.pendingAdmins)
          .doc(fbUser.uid)
          .set({
        'email': fbUser.email ?? '',
        'name': fbUser.displayName ?? fbUser.email ?? 'Unknown',
        if (fbUser.photoURL != null) 'photoUrl': fbUser.photoURL,
        'requestedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return false;
    } catch (_) {
      // If Firestore fails, deny access rather than accidentally granting it
      return false;
    }
  }
}
