import 'package:staff_webapp/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<User?> getCurrentUser();
  Future<User?> login(String email, String password);
  Future<User?> createUser(String email, String password);
}