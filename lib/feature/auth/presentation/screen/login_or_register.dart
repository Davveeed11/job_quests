import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/auth/presentation/screen/login_screen.dart';
import 'package:my_job_quest/feature/auth/presentation/screen/sign_up_screen.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});
  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool defaultPage = true;
  void toggleScreen() {
    setState(() {
      defaultPage = !defaultPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (defaultPage) {
      return LoginScreen(onSwitched: toggleScreen);
    } else {
      return SignUpScreen(onSwitched: toggleScreen);
    }
  }
}
