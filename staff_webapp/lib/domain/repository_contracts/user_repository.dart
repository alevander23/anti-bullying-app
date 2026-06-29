import 'package:staff_webapp/domain/entities/user_entity.dart';

/// Contract defining user-related operations that data layer implementations must adhere to.
/// This abstraction ensures separation of concerns between domain logic and data access.
abstract class UserRepository {
  /// Retrieves the currently authenticated user's data from the data layer.
  /// Returns null if no user is authenticated.
  Future<User?> getCurrentUser();

  /// Initiates Microsoft authentication flow and returns the authenticated user.
  /// Returns null if authentication fails or is not completed.
  Future<User?> signInWithMicrosoft();
}