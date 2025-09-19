import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

// Import your files
import 'firebase_options.dart';
import 'presentation/pages/create_ticket_page.dart';
import 'domain/use_cases/create_ticket_use_case.dart';
import 'domain/repository_contracts/ticket_repository.dart';
import 'data/repository_implementations/ticket_repository_impl.dart';
import 'data/data_sources/ticket_remote_data_source.dart';

final GetIt getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Setup dependency injection
  setupDependencies();
  
  runApp(MyApp());
}

void setupDependencies() {
  // Register Firebase Functions instance
  getIt.registerSingleton<FirebaseFunctions>(
    FirebaseFunctions.instanceFor(region: 'australia-southeast1'),
  );

  // Register data sources (now using Functions, not Firestore)
  getIt.registerSingleton<TicketRemoteDataSource>(
    TicketRemoteDataSourceImpl(getIt<FirebaseFunctions>())
  );

  // Repositories
  getIt.registerSingleton<TicketRepository>(
    TicketRepositoryImpl(getIt<TicketRemoteDataSource>())
  );

  // Use Cases
  getIt.registerSingleton<CreateTicketUseCase>(
    CreateTicketUseCase(getIt<TicketRepository>())
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anti-Bullying Report App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: RepositoryProvider<CreateTicketUseCase>(
        create: (context) => getIt<CreateTicketUseCase>(),
        child: CreateTicketPage(),
      ),
    );
  }
}