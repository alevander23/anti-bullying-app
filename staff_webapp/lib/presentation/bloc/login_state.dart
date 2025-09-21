import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final bool success;
  final bool loading;
  final String? error;

  const LoginState({
    required this.success,
    required this.loading,
    this.error,
  });

  factory LoginState.initial() =>
      const LoginState(success: false, loading: false);

  LoginState copyWith({
    bool? success,
    bool? loading,
    String? error,
  }) {
    return LoginState(
      success: success ?? this.success,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [success, loading, error];
}
