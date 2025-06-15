import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary, // Use theme's primary color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image.asset(
            //   'lib/assets/job_quests.jpg', // Path to your app's icon image
            //   width: 120,
            //   height: 120,
            //   fit: BoxFit.contain,
            // ),
            const SizedBox(height: 24),
            Text(
              'Job Quest',
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary, // Text color adapts to primary background
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
              ), // Spinner color adapts
              strokeWidth: 4,
            ),
          ],
        ),
      ),
    );
  }
}
