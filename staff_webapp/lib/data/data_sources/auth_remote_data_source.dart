import 'package:staff_webapp/data/data_models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithMicrosoft();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}