// my_job_quest/feature/core/screens/initial_screen.dart
import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/splashscreen/rank_onboarding_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/auth_changes.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _showOnboarding = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasSeenOnboarding =
          prefs.getBool('hasSeenOnboarding') ?? false;

      if (mounted) {
        setState(() {
          _showOnboarding = !hasSeenOnboarding;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle SharedPreferences error gracefully
      debugPrint('Error checking first launch: $e');
      if (mounted) {
        setState(() {
          _showOnboarding = true; // Default to showing onboarding on error
          _isLoading = false;
        });
      }
    }
  }

  // This method will be called when onboarding is completed
  Future<void> _onOnboardingComplete() async {
    try {
      // First, set the SharedPreferences flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);

      if (!mounted) return;

      // Use pushReplacement instead of pushAndRemoveUntil for better performance
      // and to avoid potential navigation stack issues
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthChanges(),
          settings: const RouteSettings(name: '/auth'),
        ),
      );
    } catch (e) {
      debugPrint('Error completing onboarding: $e');

      // Still navigate even if SharedPreferences fails
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthChanges(),
            settings: const RouteSettings(name: '/auth'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking SharedPreferences
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_showOnboarding) {
      return RankOnboardingSlider(onOnboardingComplete: _onOnboardingComplete);
    } else {
      // If onboarding has been seen, go directly to the authentication flow
      return const AuthChanges();
    }
  }
}
