import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/home/presentation/widget/button.dart';
import 'package:my_job_quest/feature/home/presentation/widget/text_field.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  final Function()? onSwitched;

  const SignUpScreen({super.key, this.onSwitched});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers for text fields, managed by the state
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController =
      TextEditingController(); // Corrected: New controller for confirm password

  @override
  void dispose() {
    // Dispose of controllers to prevent memory leaks
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose(); // Dispose new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          // Ensures content shifts up when the keyboard appears
          resizeToAvoidBottomInset: true,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.background, // Use theme background
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 32,
                      ), // Reduced vertical spacing at the top
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28, // Slightly smaller heading
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced spacing
                      Text(
                        'Join us and find your dream job!',
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(0.7),
                        ), // Use onBackground
                      ),
                      const SizedBox(height: 24), // Reduced spacing
                      Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onBackground
                              .withOpacity(0.9), // Use onBackground
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced spacing
                      TextFieldWidget(
                        hint: 'Enter your name',
                        onchange: provider.setName,
                        controller: nameController,
                        keyboardType: TextInputType.name,
                        isPassword: false, // Explicitly false for name field
                      ),
                      const SizedBox(height: 18), // Reduced spacing
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onBackground
                              .withOpacity(0.9), // Use onBackground
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced spacing
                      TextFieldWidget(
                        hint: 'Enter your email',
                        onchange: provider.setEmail,
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        isPassword: false, // Explicitly false for email field
                      ),
                      const SizedBox(height: 18), // Reduced spacing
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onBackground
                              .withOpacity(0.9), // Use onBackground
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced spacing
                      TextFieldWidget(
                        hint: 'Create a password',
                        onchange: provider.setPassword,
                        controller: passwordController,
                        isPassword:
                            true, // Set to true for password field to enable toggle
                      ),
                      const SizedBox(
                        height: 18,
                      ), // Reduced spacing between password fields
                      Text(
                        'Confirm Password', // New label for confirm password
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onBackground
                              .withOpacity(0.9), // Use onBackground
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced spacing
                      TextFieldWidget(
                        hint: 'Confirm password',
                        onchange: provider
                            .setConfirmPassword, // Corrected: Use setConfirmPassword
                        controller:
                            confirmPasswordController, // Corrected: Use new confirmPasswordController
                        isPassword:
                            true, // Set to true for password field to enable toggle
                      ),
                      // Display error message here if it's not empty
                      if (provider
                          .state
                          .errorMessage
                          .isNotEmpty) // Display error message if any
                        Column(
                          // Use Column to ensure vertical spacing
                          children: [
                            const SizedBox(
                              height: 16.0,
                            ), // Space above the error message
                            Text(
                              provider.state.errorMessage,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: 16.0,
                            ), // Space below the error message
                          ],
                        ),
                      const SizedBox(
                        height: 24,
                      ), // Standard spacing when no error message
                      Button(
                        ontap: () async {
                          await provider.signUp();
                          // No direct navigation from SignUpScreen either.
                          // AuthChanges will handle routing based on updated MyAuthProvider state.
                        },
                        title: 'Sign Up',
                        isloading: provider.state.isLoading,
                        isEnabled:
                            !provider.state.isLoading &&
                            provider.state.name.trim().isNotEmpty &&
                            provider.state.email.trim().isNotEmpty &&
                            provider.state.password.trim().isNotEmpty &&
                            provider.state.confirmPassword
                                .trim()
                                .isNotEmpty, // Add confirm password to validation
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              // Changed to Text for theme compatibility
                              "Already have an account? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onBackground,
                              ), // Use onBackground
                            ),
                            GestureDetector(
                              onTap: widget.onSwitched,
                              child: Text(
                                "Sign in",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
