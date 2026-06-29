import 'package:staff_webapp/data/data_models/user_model.dart';

// Defines the contract for remote authentication operations, including methods for signing in with Microsoft, signing out, and retrieving the current user.
abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithMicrosoft();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}