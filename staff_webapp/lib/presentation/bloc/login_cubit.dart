import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/use_cases/login_use_case.dart';
import 'package:staff_webapp/presentation/bloc/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase _loginUseCase;

  LoginCubit(this._loginUseCase):super(LoginState.initial());
  
  Future<void> attemptLogin(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      emit(state.copyWith(error: "Not all inputs filled"));
      return;
    }
    emit(state.copyWith(loading: true, error: null));
    try {
      await _loginUseCase.execute(username, password);
      emit(state.copyWith(loading: false, success: true));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}