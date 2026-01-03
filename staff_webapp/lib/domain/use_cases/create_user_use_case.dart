import '../entities/user_entity.dart';
import '../repository_contracts/user_repository.dart';

class CreateUserUseCase {
  final UserRepository userRepository;

  CreateUserUseCase(this.userRepository);

  Future<User?> execute(String email, String password) {
    return userRepository.createUser(email, password);
  }
}
