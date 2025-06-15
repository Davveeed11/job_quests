import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/auth_changes.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/core/theme/app_themes.dart';
import 'package:my_job_quest/feature/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAuthProvider()),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ), // Add ThemeProvider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the ThemeProvider for changes
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Job Quest',
      theme: AppThemes.lightTheme, // Define light theme
      darkTheme: AppThemes.darkTheme, // Define dark theme
      themeMode:
          themeProvider.themeMode, // Use the theme mode from ThemeProvider
      home: const AuthChanges(),
    );
  }
}
