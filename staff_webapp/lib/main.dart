// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/presentation/bloc/auth_cubit.dart';
import 'package:staff_webapp/presentation/bloc/auth_state.dart';
import 'package:staff_webapp/presentation/bloc/group/group_cubit.dart';
import 'package:staff_webapp/presentation/bloc/report/report_cubit.dart';
import 'package:staff_webapp/presentation/bloc/school/school_cubit.dart';
import 'package:staff_webapp/presentation/pages/dashboard/dashboard_page.dart';
import 'package:staff_webapp/presentation/pages/groups/groups_page.dart';
import 'package:staff_webapp/presentation/pages/splash_page.dart';
import 'package:staff_webapp/presentation/pages/accounts/SSO_login_page.dart';
import 'package:staff_webapp/presentation/pages/waiting_page.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/presentation/pages/groups/group_detail_page.dart';
import 'package:staff_webapp/presentation/pages/groups/create_edit_group_page.dart';
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
        home: const SplashPage(),
        routes: {
          '/login': (_) => const SSOLoginPage(),
          '/waiting': (_) => BlocProvider.value(
                value: getIt<AuthCubit>(),
                child: const WaitingPage(),
              ),
          '/home': (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => getIt<SchoolCubit>()),
                  BlocProvider(create: (_) => getIt<ReportCubit>()),
                ],
                child: const DashboardPage(),
              ),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/groups') {
            // Route for group list page with admin context and report data
            final args = settings.arguments as Map<String, dynamic>;
            final admin = args['admin'] as Admin;
            final allReports = args['allReports'] as List<Report>;
            final reportCubit = args['reportCubit'] as ReportCubit;
            final windowDays = args['windowDays'] as int? ?? 5;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => getIt<GroupCubit>()),
                  BlocProvider.value(value: reportCubit),
                ],
                child: GroupsPage(
                  admin: admin,
                  allReports: allReports,
                  windowDays: windowDays,
                ),
              ),
            );
          }
          if (settings.name == '/groups/detail') {
            // Route for group detail page with specific group data
            final args = settings.arguments as Map<String, dynamic>;
            final groupId = args['groupId'] as String;
            final admin = args['admin'] as Admin;
            final allReports = args['allReports'] as List<Report>;
            final groupCubit = args['groupCubit'] as GroupCubit;
            final reportCubit = args['reportCubit'] as ReportCubit;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: groupCubit),
                  BlocProvider.value(value: reportCubit),
                ],
                child: GroupDetailPage(
                  groupId: groupId,
                  admin: admin,
                  allReports: allReports,
                ),
              ),
            );
          }
          if (settings.name == '/groups/detail/edit') {
            // Route for editing an existing group
            final args = settings.arguments as Map<String, dynamic>;
            final admin = args['admin'] as Admin;
            final allReports = args['allReports'] as List<Report>;
            final existing = args['existing'] as IncidentGroup;
            final groupCubit = args['groupCubit'] as GroupCubit;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => BlocProvider.value(
                value: groupCubit,
                child: CreateEditGroupPage(
                  admin: admin,
                  allReports: allReports,
                  existing: existing,
                ),
              ),
            );
          }
          if (settings.name == '/groups/create') {
            // Route for creating a new group
            final args = settings.arguments as Map<String, dynamic>;
            final admin = args['admin'] as Admin;
            final allReports = args['allReports'] as List<Report>;
            final groupCubit = args['groupCubit'] as GroupCubit;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => BlocProvider.value(
                value: groupCubit,
                child: CreateEditGroupPage(
                  admin: admin,
                  allReports: allReports,
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}