import 'package:cloud_functions/cloud_functions.dart';
import 'package:get_it/get_it.dart';
import 'package:staff_webapp/data/data_sources/staff_remote_data_source.dart';
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

  // Repository
  getIt.registerSingleton<TicketRepository>(
    TicketRepositoryImpl(getIt<TicketRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerSingleton<ResolveTicketUseCase>(
    ResolveTicketUseCase(getIt<TicketRepository>()),
  );
  getIt.registerSingleton<GetTicketByIdUseCase>(    // <-- FIX HERE
    GetTicketByIdUseCase(getIt<TicketRepository>()),
  );
}