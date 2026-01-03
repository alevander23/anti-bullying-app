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
  Future<User?> login(String email, String password) async {
    return await remoteDataSource.fetchUser(email, password);
  }

  @override
  Future<User?> createUser(String email, String password) async {
    return await remoteDataSource.createUser(email, password); // Dart was complaining and was confused so asked chatGPT and it said to do this
  }
}
