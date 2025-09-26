import '../../domain/entities/user_entity.dart';
import 'dart:math';

class UserRemoteDataSource {
  Future<User?> fetchUser(String username, String password) async {
    // For now, mock user
    if (username == 'test' && password == 'password') {
      return User(id: '1', name: 'Test User', isAuthorized: false);
    }
    if (username == 'authorized' && password == 'password') {
      return User(id: '2', name: 'authorised User', isAuthorized: true);
    }
    return null;
  }

  Future<User?> createUser(String username, String password) async { // written by chatGPT to make it compile
    // fake creation — generate random ID
    final randomId = Random().nextInt(10000).toString();
    return User(
      id: randomId,
      name: username,
      isAuthorized: false, // new accounts need approval?
    );
  }
}
