import 'package:equatable/equatable.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';

class CreateUserState extends Equatable {
  final bool success;
  final bool loading;
  final String? error;
  final User? user;

  const CreateUserState({
    required this.success,
    required this.loading,
    this.error,
    this.user,
  });

  factory CreateUserState.initial() =>
      const CreateUserState(success: false, loading: false);

  CreateUserState copyWith({
    bool? success,
    bool? loading,
    String? error,
    User? user,
  }) {
    return CreateUserState(
      success: success ?? this.success,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [success, loading, error, user];
}
