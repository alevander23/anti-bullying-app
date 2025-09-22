import 'package:equatable/equatable.dart';
import 'package:staff_webapp/domain/entities/user_entity.dart';

class LoginState extends Equatable {
  final bool success;
  final bool loading;
  final String? error;
  final User? user;

  const LoginState({
    required this.success,
    required this.loading,
    this.error,
    this.user,
  });

  factory LoginState.initial() =>
      const LoginState(success: false, loading: false);

  LoginState copyWith({
    bool? success,
    bool? loading,
    String? error,
    User? user,
  }) {
    return LoginState(
      success: success ?? this.success,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [success, loading, error, user];
}
