import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Important Disclaimer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '**IMPORTANT: MVP DEMONSTRATION ONLY**',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error, // Use error color for emphasis
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to My Job Quest MVP! We are thrilled to show you the core functionalities of our platform. Please read this critical disclaimer carefully:',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildDisclaimerPoint(
              context,
              'NO REAL MONEY HANDLING:',
              'This Minimum Viable Product (MVP) **DOES NOT** process or handle any real financial transactions. All mentions of "payments," "salary," "escrow," or "wallet" within the app are purely conceptual and for demonstration purposes only.',
            ),
            _buildDisclaimerPoint(
              context,
              'ESCROW FEATURE IS A SIMULATION:',
              'The "escrow system" presented in this app is a **SIMULATION**. It is designed to illustrate how a secure payment mechanism would function in a full-scale product. No funds are collected, held, or disbursed in any real-world capacity.',
            ),
            _buildDisclaimerPoint(
              context,
              'DATA IS FOR DEMONSTRATION:',
              'Any job postings, user profiles, or other data you see or create within this MVP are for demonstration and testing purposes only. Do not input any sensitive or real personal financial information.',
            ),
            _buildDisclaimerPoint(
              context,
              'FUTURE DEVELOPMENT:',
              'Our full product aims to include robust, secure payment processing and a functional escrow system, implemented by trusted financial partners. This MVP serves as a proof of concept for the user experience.',
            ),
            const SizedBox(height: 24),
            Text(
              'By continuing to use this MVP, you acknowledge and agree to these terms.',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Understood',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerPoint(
    BuildContext context,
    String title,
    String content,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
