import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:staff_webapp/data/data_models/user_model.dart';
import 'package:staff_webapp/data/data_sources/auth_remote_data_source.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';


class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  static const String _tenantId = 'common';

  AuthRemoteDataSourceImpl({
    required fb.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

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
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw fb.FirebaseAuthException(
        code: 'cancelled-by-user',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final fbUser = userCredential.user;

    if (fbUser == null) {
      throw fb.FirebaseAuthException(
        code: 'null-user',
        message: 'Google sign-in returned no user.',
      );
    }

    return UserModel.fromFirebaseUser(
      fbUser,
      isAuthorized: await _checkAuthorization(fbUser),
      provider: AuthProvider.google,
    );
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
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
      if (info.providerId == 'google.com') return AuthProvider.google;
      if (info.providerId == 'password') return AuthProvider.email;
    }
    return AuthProvider.unknown;
  }

  // AI stuff here

  /// Authorization check — plug in your logic here.
  /// Options:
  ///   A) Custom Firebase claim: (await fbUser.getIdTokenResult()).claims?['isStaff'] == true
  ///   B) Firestore lookup: FirebaseFirestore.instance.collection('staff').doc(fbUser.uid).get()
  ///   C) Email domain:    fbUser.email?.endsWith('@yourcompany.com') ?? false
  Future<bool> _checkAuthorization(fb.User fbUser) async {
    // TODO: replace with A, B, or C before production
    return true;
  }
}
