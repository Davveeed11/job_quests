import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/presentation/home_screen.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen(),debugShowCheckedModeBanner: false,);
  }
}
