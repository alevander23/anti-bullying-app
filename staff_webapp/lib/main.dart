// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/presentation/bloc/auth_cubit.dart';
import 'package:staff_webapp/presentation/bloc/auth_state.dart';
import 'package:staff_webapp/presentation/pages/splash_page.dart';
import 'package:staff_webapp/presentation/pages/sso_login_page.dart';
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
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        // SplashPage checks for an existing session then routes accordingly.
        home: const SplashPage(),
        routes: {
          '/login': (_) => const SSOLoginPage(),
          '/home':  (_) => const HomePage(),
        },
      ),
    );
  }
}

// ─── Home page placeholder ────────────────────────────────────────────────────
// Replace the body with your real home page widget once auth is wired up.

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        child: const Center(
          child: Text('✅ Authorized', style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
