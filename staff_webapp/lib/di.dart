import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';

import 'package:staff_webapp/data/data_sources/auth_remote_data_source.dart';
import 'package:staff_webapp/data/data_sources/auth_remote_data_source_impl.dart';
import 'package:staff_webapp/data/data_sources/user_remote_data_source.dart';
import 'package:staff_webapp/data/data_sources/admin_remote_data_source.dart';
import 'package:staff_webapp/data/data_sources/group_remote_data_source.dart';
import 'package:staff_webapp/data/data_sources/media_remote_data_source.dart';
import 'package:staff_webapp/data/repository_implementations/auth_repository_impl.dart';
import 'package:staff_webapp/data/repository_implementations/user_repository_impl.dart';

import 'package:staff_webapp/data/repository_implementations/admin_repository_impl.dart';
import 'package:staff_webapp/data/repository_implementations/group_repository_impl.dart';
import 'package:staff_webapp/data/repository_implementations/media_repository_impl.dart';

import 'package:staff_webapp/domain/repository_contracts/auth_repository.dart';
import 'package:staff_webapp/domain/repository_contracts/user_repository.dart';
import 'package:staff_webapp/domain/repository_contracts/admin_repository.dart';
import 'package:staff_webapp/domain/repository_contracts/group_repository.dart';
import 'package:staff_webapp/domain/repository_contracts/media_repository.dart';

import 'package:staff_webapp/domain/use_cases/login_use_case.dart';
import 'package:staff_webapp/domain/use_cases/sign_in_with_microsoft.dart';
import 'package:staff_webapp/domain/use_cases/sign_out_use_case.dart';
import 'package:staff_webapp/domain/use_cases/get_current_user_use_case.dart';

import 'package:staff_webapp/presentation/bloc/auth_cubit.dart';
import 'package:staff_webapp/presentation/bloc/media/media_cubit.dart';
import 'package:staff_webapp/presentation/bloc/report/report_cubit.dart';
import 'package:staff_webapp/presentation/bloc/school/school_cubit.dart';
import 'package:staff_webapp/presentation/bloc/group/group_cubit.dart';
import 'package:staff_webapp/presentation/bloc/settings/settings_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final firebaseApp = Firebase.app();

  // Register Firebase singletons - these are shared across the app and should not be recreated
  getIt.registerSingleton<FirebaseAuth>(
    FirebaseAuth.instanceFor(app: firebaseApp),
  );
  getIt.registerSingleton<FirebaseFunctions>(
    FirebaseFunctions.instanceFor(region: 'australia-southeast1', app: firebaseApp),
  );
  getIt.registerSingleton<FirebaseDatabase>(
    FirebaseDatabase.instanceFor(app: firebaseApp),
  );
  getIt.registerSingleton<FirebaseFirestore>(
    FirebaseFirestore.instanceFor(app: firebaseApp),
  );

  // Register data layer remote data sources - implementations that interact with Firebase
  getIt.registerSingleton<UserRemoteDataSource>(
    UserRemoteDataSource(
      firebaseAuth: getIt<FirebaseAuth>(),
      database: getIt<FirebaseDatabase>(),
    ),
  );
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(
      firebaseAuth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerSingleton<AdminRemoteDataSource>(
    AdminRemoteDataSource(
      firestore: getIt<FirebaseFirestore>(),
      auth: getIt<FirebaseAuth>(),
      functions: getIt<FirebaseFunctions>(),
    ),
  );
  getIt.registerSingleton<GroupRemoteDataSource>(
    GroupRemoteDataSource(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerSingleton<MediaRemoteDataSource>(
    MediaRemoteDataSourceImpl(firebaseAuth: getIt<FirebaseAuth>()),
  );

  // Register domain layer repositories - implementations that use data sources
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(getIt<UserRemoteDataSource>()),
  );
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      firebaseAuth: getIt<FirebaseAuth>(),
    ),
  );
  getIt.registerSingleton<AdminRepository>(
    AdminRepositoryImpl(getIt<AdminRemoteDataSource>()),
  );
  getIt.registerSingleton<GroupRepository>(
    GroupRepositoryImpl(getIt<GroupRemoteDataSource>()),
  );
  getIt.registerSingleton<MediaRepository>(
    MediaRepositoryImpl(getIt<MediaRemoteDataSource>()),
  );

  // Register domain layer use cases - business logic that uses repositories
  getIt.registerSingleton<LoginUseCase>(
    LoginUseCase(getIt<UserRepository>()),
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

  // Register presentation layer blocs - UI state management
  getIt.registerSingleton<AuthCubit>(
    AuthCubit(
      microsoftUseCase: getIt<SignInWithMicrosoft>(),
      signOutUseCase: getIt<SignOutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );
  getIt.registerFactory<ReportCubit>(
    () => ReportCubit(getIt<AdminRepository>()),
  );
  getIt.registerFactory<SchoolCubit>(
    () => SchoolCubit(getIt<AdminRepository>()),
  );
  getIt.registerFactory<GroupCubit>(
    () => GroupCubit(getIt<GroupRepository>()),
  );
  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(getIt<AdminRepository>()),
  );
  getIt.registerFactory<MediaCubit>(
    () => MediaCubit(getIt<MediaRepository>()),
  );
}