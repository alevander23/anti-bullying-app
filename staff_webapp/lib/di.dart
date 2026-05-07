import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:staff_webapp/data/data_sources/staff_remote_data_source.dart';
import 'package:staff_webapp/data/data_sources/user_remote_data_source.dart';
import 'package:staff_webapp/data/data_sources/auth_remote_data_source.dart';
import 'package:staff_webapp/data/data_sources/auth_remote_data_source_impl.dart';
import 'package:staff_webapp/data/repository_implementations/user_repository_impl.dart';
import 'data/repository_implementations/ticket_repository_impl.dart';
import 'package:staff_webapp/data/repository_implementations/auth_repository_impl.dart';
import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';
import 'package:staff_webapp/domain/repository_contracts/user_repository.dart';
import 'domain/repository_contracts/ticket_repository.dart';
import 'package:staff_webapp/domain/use_cases/login_use_case.dart';
import 'package:staff_webapp/domain/use_cases/create_user_use_case.dart';
import 'domain/use_cases/resolve_ticket_use_case.dart';
import 'domain/use_cases/get_ticket_by_id_use_case.dart';
import 'package:staff_webapp/domain/use_cases/sign_in_with_google.dart';
import 'package:staff_webapp/domain/use_cases/sign_in_with_microsoft.dart';
import 'package:staff_webapp/domain/use_cases/sign_out_use_case.dart';
import 'package:staff_webapp/domain/use_cases/get_current_user_use_case.dart';
import 'package:staff_webapp/presentation/bloc/auth_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final firebaseApp = Firebase.app();

  // Firebase singletons
  getIt.registerSingleton<FirebaseAuth>(
    FirebaseAuth.instanceFor(app: firebaseApp),
  );
  getIt.registerSingleton<FirebaseFunctions>(
    FirebaseFunctions.instanceFor(region: 'australia-southeast1', app: firebaseApp),
  );

  getIt.registerSingleton<GoogleSignIn>(GoogleSignIn());

  // Data sources
  getIt.registerSingleton<TicketRemoteDataSource>(
    TicketRemoteDataSourceImpl(getIt<FirebaseFunctions>()),
  );
  getIt.registerSingleton<UserRemoteDataSource>(
    UserRemoteDataSource(getIt<FirebaseAuth>()),
  );
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(
      firebaseAuth: getIt<FirebaseAuth>(),
      googleSignIn: getIt<GoogleSignIn>(),
    ),
  );

  // Repositories
  getIt.registerSingleton<TicketRepository>(
    TicketRepositoryImpl(getIt<TicketRemoteDataSource>()),
  );
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(getIt<UserRemoteDataSource>()),
  );
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      firebaseAuth: getIt<FirebaseAuth>(),
    ),
  );

  // Use cases
  getIt.registerSingleton<ResolveTicketUseCase>(
    ResolveTicketUseCase(getIt<TicketRepository>()),
  );
  getIt.registerSingleton<GetTicketByIdUseCase>(
    GetTicketByIdUseCase(getIt<TicketRepository>()),
  );
  getIt.registerSingleton<LoginUseCase>(
    LoginUseCase(getIt<UserRepository>()),
  );
  getIt.registerSingleton<CreateUserUseCase>(
    CreateUserUseCase(getIt<UserRepository>()),
  );
  getIt.registerSingleton<SignInWithGoogle>(
    SignInWithGoogle(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<SignInWithMicrosoft>(
    SignInWithMicrosoft(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<SignOutUseCase>(
    SignOutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<GetCurrentUserUseCase>(
    GetCurrentUserUseCase(getIt<AuthRepository>()),
  );

  // Cubit
  getIt.registerSingleton<AuthCubit>(
    AuthCubit(
      googleUseCase: getIt<SignInWithGoogle>(),
      microsoftUseCase: getIt<SignInWithMicrosoft>(),
      signOutUseCase: getIt<SignOutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );
}
