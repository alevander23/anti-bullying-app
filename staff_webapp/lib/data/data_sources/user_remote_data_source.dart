import '../../domain/entities/user_entity.dart';

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
}
