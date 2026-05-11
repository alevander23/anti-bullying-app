// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/presentation/bloc/auth_cubit.dart';
import 'package:staff_webapp/presentation/bloc/auth_state.dart';
import 'package:staff_webapp/presentation/bloc/report/report_cubit.dart';
import 'package:staff_webapp/presentation/bloc/school/school_cubit.dart';
import 'package:staff_webapp/presentation/pages/dashboard/dashboard_page.dart';
import 'package:staff_webapp/presentation/pages/splash_page.dart';
import 'package:staff_webapp/presentation/pages/accounts/SSO_login_page.dart';
import 'firebase_options.dart';
import 'di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => getIt<AuthCubit>(),
      child: MaterialApp(
        title: 'Staff Portal',
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        // SplashPage checks for an existing session then routes accordingly.
        home: const SplashPage(),
        routes: {
          '/login': (_) => const SSOLoginPage(),
          '/home': (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => getIt<SchoolCubit>()),
                  BlocProvider(create: (_) => getIt<ReportCubit>()),
                ],
                child: const DashboardPage(),
              ),
        },
      ),
    );
  }
}
