import '../entities/user_entity.dart';
import '../repository_contracts/user_repository.dart';

class LoginUseCase {
  final UserRepository userRepository;

  LoginUseCase(this.userRepository);

  Future<User?> execute(String email, String password) {
    return userRepository.login(email, password);
  }
}