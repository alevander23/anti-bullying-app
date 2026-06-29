import 'package:staff_webapp/data/data_sources/user_remote_data_source.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/user_repository.dart';

// Concrete implementation of UserRepository in the data layer.
// Delegates all operations to the UserRemoteDataSource, adhering to Clean Architecture
// principles by keeping business logic separate from data access concerns.
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _dataSource;

  UserRepositoryImpl(this._dataSource);

  @override
  // Retrieves the currently signed-in user from the remote data source.
  Future<User?> getCurrentUser() => _dataSource.getCurrentUser();

  @override
  // Signs in a user using Microsoft authentication through the remote data source.
  Future<User?> signInWithMicrosoft() => _dataSource.signInWithMicrosoft();
}