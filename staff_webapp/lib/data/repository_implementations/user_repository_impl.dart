import 'package:staff_webapp/domain/entities/user_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/user_repository.dart';
import 'package:staff_webapp/data/data_sources/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl(this.remoteDataSource);

  @override
  Future<User?> getCurrentUser() async {
    return null;
  }

  @override
  Future<User?> login(String username, String password) {
    return remoteDataSource.fetchUser(username, password);
  }
}
