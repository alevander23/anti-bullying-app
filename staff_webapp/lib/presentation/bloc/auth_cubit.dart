import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/core/error/failures.dart';
import 'package:staff_webapp/domain/use_cases/sign_in_with_microsoft.dart';
import 'package:staff_webapp/domain/use_cases/sign_out_use_case.dart';
import 'package:staff_webapp/domain/use_cases/get_current_user_use_case.dart';
import 'package:staff_webapp/domain/use_cases/use_case.dart';
import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';
import 'package:staff_webapp/presentation/bloc/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInWithMicrosoft _microsoftUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AuthRepository _authRepository; // for stream subscription

  StreamSubscription<dynamic>? _authSubscription;

  AuthCubit({
    required SignInWithMicrosoft microsoftUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required AuthRepository authRepository,
  })  : _microsoftUseCase = microsoftUseCase,
        _signOutUseCase = signOutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _authRepository = authRepository,
        super(const AuthInitial()) {
    _listenToAuthChanges();
  }

  // Startup: restore session

  Future<void> checkCurrentUser() async {
    emit(const AuthLoading());
    final result = await _getCurrentUserUseCase(const NoParams());
    result.fold(
      (failure) => emit(AuthUnauthenticated()), // treat error as unauthenticated
      (user) => user != null
          ? emit(AuthSessionRestored(user))
          : emit(const AuthUnauthenticated()),
    );
  }

  // Sign in

  Future<void> signInWithMicrosoft() async {
    emit(const AuthLoading());
    final result = await _microsoftUseCase(const NoParams());
    result.fold(
      (failure) => _handleFailure(failure),
      (user) => emit(AuthSuccess(user)),
    );
  }

  //Sign out

  Future<void> signOut() async {
    emit(const AuthLoading());
    final result = await _signOutUseCase(const NoParams());
    result.fold(
      (failure) => emit(AuthError(failure)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  // Auth state stream

  /// Subscribes to Firebase's token stream. If the token is revoked remotely,
  /// this will automatically emit AuthUnauthenticated and the router will
  /// redirect to login, no polling required.
  void _listenToAuthChanges() {
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) {
        // Only react if we're in a stable state (not mid-sign-in)
        if (state is AuthLoading || state is AuthInitial) return;
        if (user == null && state is! AuthUnauthenticated) {
          emit(const AuthUnauthenticated());
        }
      },
      onError: (_) {
        // Stream errors are non-fatal; don't crash the app.
      },
    );
  }

  // Helpers

  void _handleFailure(Failure failure) {
    if (failure is MicrosoftAuthFailure && failure.errorCode == 'cancelled-by-user') {
      emit(const AuthInitial());
      return;
    }
    emit(AuthError(failure));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
