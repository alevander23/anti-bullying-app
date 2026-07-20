import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'di.dart';
import 'presentation/pages/startup_page.dart';

Future<void> main() async {
  // needed before any firebase or plugin calls since we're doing async setup pre-runApp
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupDependencies();
  runApp(const UserReportApp());
}

class UserReportApp extends StatelessWidget {
  const UserReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Incident Reporter',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      // startup page decides whether to go to the report form based on the school config
      home: const StartupPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
