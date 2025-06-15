import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Import for StreamSubscription

// Import all your relevant screens
import 'package:my_job_quest/feature/auth/presentation/screen/login_or_register.dart'; // Handles login/signup switch
import 'package:my_job_quest/feature/skills/presentation/screens/skill_rank_selection_screen.dart';
import 'package:my_job_quest/feature/home/presentation/home_screen.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/splashscreen/presentation/splash_screen.dart';

/// This widget serves as the main router/initializer for the application,
/// deciding which screen to show based on the user's authentication state
/// and whether their profile (including skill rank) has been set.
class AuthChanges extends StatefulWidget {
  const AuthChanges({super.key});

  @override
  State<AuthChanges> createState() => _AuthChangesState();
}

class _AuthChangesState extends State<AuthChanges> {
  StreamSubscription<User?>? _authStateChangesSubscription;
  late final MyAuthProvider _myAuthProvider; // Declare as late final

  @override
  void initState() {
    super.initState();
    _myAuthProvider = Provider.of<MyAuthProvider>(context, listen: false);

    // *** FIX: Defer the call to load user profile using addPostFrameCallback ***
    // This ensures the state update (notifyListeners) happens after the
    // initial build of AuthChanges is complete, preventing the setState during build error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myAuthProvider.loadUserProfile();
      print(
        'AuthChanges: User profile initialization triggered via post-frame callback.',
      ); // Debug print
    });

    // Listen to Firebase Auth state changes to react to user login/logout
    _authStateChangesSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (mounted) {
        // When auth state changes (e.g., user signs in or out), re-check their profile.
        // Also defer this call if it might cause setState during an ongoing build phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _myAuthProvider.loadUserProfile();
          print(
            'AuthChanges: Auth state changed, user profile re-check triggered via post-frame callback.',
          ); // Debug print
        });
      }
    });
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel(); // Cancel the subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We listen to both Firebase Auth state and MyAuthProvider's state
    // to make routing decisions.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(), // Primary auth state listener
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          // Show a SplashScreen while Firebase Auth is initializing
          return const SplashScreen(); // Show SplashScreen during initial auth loading
        }

        final user = authSnapshot.data; // The current Firebase user
        final authProvider = Provider.of<MyAuthProvider>(
          context,
        ); // Get the auth provider state

        // Added print statement to debug flow
        print(
          'AuthChanges: User: ${user?.uid}, hasSkillRank: ${authProvider.state.hasSkillRank}, profileLoaded: ${authProvider.state.profileLoaded}',
        );

        if (user == null) {
          // User is not authenticated, show the Login/Register screen.
          return const LoginOrRegister(); // Use LoginOrRegisterScreen as the entry point
        } else {
          // User is authenticated. Now check if their profile (including skill rank) is loaded.
          if (!authProvider.state.profileLoaded) {
            // Profile is still loading, show a loading indicator or SplashScreen
            print(
              'AuthChanges: User authenticated but profile not loaded, showing SplashScreen...',
            );
            return const SplashScreen();
          } else if (authProvider.state.hasSkillRank) {
            // Skill rank is set, navigate to the main Home Screen.
            print(
              'AuthChanges: User authenticated and skill rank set, navigating to HomeScreen.',
            );
            return const HomeScreen();
          } else {
            // Skill rank is NOT set, navigate to the Skill Rank Selection Screen.
            print(
              'AuthChanges: User authenticated but skill rank NOT set, navigating to SkillRankSelectionScreen.',
            );
            return const SkillRankSelectionScreen();
          }
        }
      },
    );
  }
}
