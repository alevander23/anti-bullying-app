import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart' as pkuser;

class UserRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  UserRemoteDataSource(this.firebaseAuth);

  Future<pkuser.User?> fetchUser(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) return null;

      return pkuser.User(
        id: fbUser.uid,
        name: fbUser.email ?? '',
        isAuthorized: true,
      );
    } on FirebaseAuthException catch (e) {
      print('Login error: ${e.code}');
      return null;
    }
  }

  // Create user (signup)
  Future<pkuser.User?> createUser(String email, String password) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user;

      if (fbUser == null) return null;

      return pkuser.User(
        id: fbUser.uid,
        name: fbUser.email ?? '',
        isAuthorized: false,
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      } else {
        print('FirebaseAuthException: ${e.code}');
      }
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      return null;
    }
  }
}
