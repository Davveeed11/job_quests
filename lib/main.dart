import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/auth_changes.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => MyAuthProvider(),
      builder: (context, child) => MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: AuthChanges(), debugShowCheckedModeBanner: false);
  }
}
