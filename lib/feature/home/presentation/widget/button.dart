import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final Function()? ontap;
  final String title;
  final bool isEnabled;
  final bool isloading;

  const Button({
    super.key,
    this.ontap,
    required this.title,
    this.isEnabled = true, // Default to enabled
    this.isloading = false, // Default to not loading
  });

  @override
  Widget build(BuildContext context) {
    // Determine the background color based on enabled state
    final Color backgroundColor = isEnabled
        ? Theme.of(context)
              .colorScheme
              .primary // Use theme's primary color
        : Theme.of(context).colorScheme.onSurface.withOpacity(
            0.1,
          ); // Lighter, themed disabled background

    // Determine the text color based on enabled state
    final Color textColor = isEnabled
        ? Theme.of(context)
              .colorScheme
              .onPrimary // Use theme's onPrimary for enabled
        : Theme.of(context).colorScheme.onSurface.withOpacity(
            0.4,
          ); // Themed disabled text color

    return SizedBox(
      height: 52, // Slightly taller button
      width: double.infinity, // Full width
      child: ElevatedButton(
        onPressed: isEnabled && !isloading
            ? ontap
            : null, // Disable if not enabled or loading
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor, // Set the background color
          foregroundColor: textColor, // Set the text/icon color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ), // Slightly less rounded corners
          ),
          elevation: isEnabled ? 4 : 0, // Add shadow when enabled
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: isloading
            ? SizedBox(
                width: 24, // Size of the circular progress indicator
                height: 24,
                child: CircularProgressIndicator(
                  color: textColor, // Match text color for the spinner
                  strokeWidth: 2.5, // Thinner progress indicator
                ),
              )
            : Text(title), // Display the title text
      ),
    );
  }
}
