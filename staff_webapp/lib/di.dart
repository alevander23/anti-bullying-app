import 'package:cloud_functions/cloud_functions.dart';
import 'package:get_it/get_it.dart';
import 'package:staff_webapp/data/data_sources/staff_remote_data_source.dart';
import 'package:staff_webapp/data/data_sources/user_remote_data_source.dart';
import 'package:staff_webapp/data/repository_implementations/user_repository_impl.dart';
import 'package:staff_webapp/domain/repository_contracts/user_repository.dart';
import 'package:staff_webapp/domain/use_cases/login_use_case.dart';
import 'package:staff_webapp/domain/use_cases/create_user_use_case.dart';
import 'data/repository_implementations/ticket_repository_impl.dart';
import 'domain/use_cases/resolve_ticket_use_case.dart';
import 'domain/use_cases/get_ticket_by_id_use_case.dart';   // <-- ADD THIS
import 'domain/repository_contracts/ticket_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Cloud Functions (region aware)
  getIt.registerSingleton<FirebaseFunctions>(
    FirebaseFunctions.instanceFor(region: 'australia-southeast1'),
  );

  // Data source
  getIt.registerSingleton<TicketRemoteDataSource>(
    TicketRemoteDataSourceImpl(getIt<FirebaseFunctions>()),
  );
  getIt.registerSingleton<UserRemoteDataSource>(
    UserRemoteDataSource(),
  );

  // Repository
  getIt.registerSingleton<TicketRepository>(
    TicketRepositoryImpl(getIt<TicketRemoteDataSource>()),
  );
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(getIt<UserRemoteDataSource>()),
  );

  // Use Cases
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
}