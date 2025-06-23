import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/core/theme/app_themes.dart';
import 'package:my_job_quest/feature/core/theme/theme_provider.dart';
import 'package:my_job_quest/feature/splashscreen/presentation/initial_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
      analytics: analytics,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Questify career',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      navigatorObservers: [observer],

      themeMode: themeProvider.themeMode,
      home: InitialScreen(),
    );
  }
}
