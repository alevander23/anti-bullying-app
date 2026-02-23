import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/use_cases/create_user_use_case.dart';
import 'create_user_state.dart';

class CreateUserCubit extends Cubit<CreateUserState> {
  final CreateUserUseCase _createUserUseCase;

  CreateUserCubit(this._createUserUseCase) : super(CreateUserState.initial());

  Future<void> createUser(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      emit(state.copyWith(error: "Not all inputs filled"));
      return;
    }

    emit(state.copyWith(loading: true, error: null));

    try {
      final user = await _createUserUseCase.execute(email, password);

      if (user != null) {
        emit(state.copyWith(
          loading: false,
          success: true,
          user: user,
        ));
      } else {
        emit(state.copyWith(
          loading: false,
          error: "❌ Failed to create user",
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString(),
      ));
    }
  }
}
