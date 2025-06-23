import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_job_quest/feature/core/theme/presentation/profile_loading_shimmer.dart';
import 'package:my_job_quest/feature/skills/presentation/screens/skill_rank_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_job_quest/feature/auth/presentation/screen/login_or_register.dart';
import 'package:my_job_quest/feature/home/presentation/home_screen.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/splashscreen/presentation/splash_screen.dart'; // Keep for initial splash

class AuthChanges extends StatefulWidget {
  const AuthChanges({super.key});

  @override
  State<AuthChanges> createState() => _AuthChangesState();
}

class _AuthChangesState extends State<AuthChanges> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          // Show the initial SplashScreen while Firebase Auth is determining the user state
          return const SplashScreen();
        }

        final user = authSnapshot.data;
        final authProvider = Provider.of<MyAuthProvider>(context);

        if (user == null) {
          // User is not authenticated, show the Login/Register screen.
          return const LoginOrRegister();
        } else {
          // User is authenticated. Now check if their profile (including skill rank) is loaded by MyAuthProvider.
          if (!authProvider.state.profileLoaded) {
            // User is authenticated, but profile data is still loading.
            // Show the shimmer loading screen instead of the static SplashScreen.
            return const ProfileLoadingShimmer();
          } else if (authProvider.state.hasSkillRank) {
            // Skill rank is set, navigate to the main Home Screen.
            return const HomeScreen();
          } else {
            // Skill rank is NOT set, navigate to the Skill Rank Selection Screen.
            return const SkillRankSelectionScreen();
          }
        }
      },
    );
  }
}
