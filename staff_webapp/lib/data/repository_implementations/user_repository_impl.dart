import 'package:staff_webapp/data/data_sources/user_remote_data_source.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _dataSource;

  UserRepositoryImpl(this._dataSource);

  @override
  Future<User?> getCurrentUser() => _dataSource.getCurrentUser();

  @override
  Future<User?> signInWithMicrosoft() => _dataSource.signInWithMicrosoft();
}
