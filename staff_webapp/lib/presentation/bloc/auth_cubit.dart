// auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/use_cases/sign_in_with_google.dart';
import 'package:staff_webapp/domain/use_cases/sign_in_with_microsoft.dart';
import 'package:staff_webapp/presentation/bloc/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInWithGoogle googleUseCase;
  final SignInWithMicrosoft microsoftUseCase;
  // final SignInWithEmailUseCase emailUseCase;

  AuthCubit({required this.googleUseCase, required this.microsoftUseCase}) : super(AuthInitial());

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    final result = await googleUseCase(GoogleParams());
    result.fold(
      (failure) => emit(AuthFailure(failure)),
      (user) => emit(AuthSuccess(user)),
    );
  }

  // Similar methods for Microsoft and Email...
}