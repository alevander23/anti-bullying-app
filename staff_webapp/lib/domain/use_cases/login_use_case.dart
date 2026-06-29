import '../entities/user_entity.dart';
import '../repository_contracts/user_repository.dart';

// Use case for handling user login, encapsulating the interaction with the user repository
class LoginUseCase {
  final UserRepository userRepository;

  LoginUseCase(this.userRepository);

  // Initiates Microsoft login and returns the authenticated user if successful
  Future<User?> loginWithMicrosoft() async {
  return await userRepository.signInWithMicrosoft();
  }
}