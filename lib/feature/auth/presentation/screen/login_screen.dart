import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/home/presentation/widget/button.dart';
import 'package:my_job_quest/feature/home/presentation/widget/text_field.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  final Function()? onSwitched;
  const LoginScreen({super.key, this.onSwitched});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Function to show the device conflict dialog
  void _showDeviceConflictDialog(
    BuildContext context,
    MyAuthProvider provider,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Already Logged In',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(
            provider.state.errorMessage, // Use the message from the provider
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                provider.setEmail(''); // Clear email to reset form
                provider.setPassword(''); // Clear password
                emailController.clear();
                passwordController.clear();
                provider.state.errorMessage = ''; // Clear error message
                provider.state.isLoading = false; // Ensure loading is false
                provider.notifyListeners(); // Notify listeners of state change
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                // Proceed with force sign-in for the new device
                await provider.forceSignInNewDevice();
                // AuthChanges will handle navigation after forceSignInNewDevice updates state
              },
              child: Text(
                'Sign In Anyway',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, provider, child) {
        // Listen for error message changes to show the dialog
        if (provider.state.errorMessage.contains(
          'already logged in on another device',
        )) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showDeviceConflictDialog(context, provider);
          });
        }

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
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
                      const SizedBox(height: 32),
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to your account to continue your job quest.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFieldWidget(
                        hint: 'Enter your email',
                        onchange: provider.setEmail,
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        isPassword: false,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFieldWidget(
                        hint: 'Enter your password',
                        onchange: provider.setPassword,
                        controller: passwordController,
                        isPassword: true,
                      ),
                      // Only show error message if it's NOT the device conflict message
                      if (provider.state.errorMessage.isNotEmpty &&
                          !provider.state.errorMessage.contains(
                            'already logged in on another device',
                          ))
                        Column(
                          children: [
                            const SizedBox(height: 16.0),
                            Text(
                              provider.state.errorMessage,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16.0),
                          ],
                        )
                      else
                        const SizedBox(height: 24),
                      Button(
                        ontap: () async {
                          // Clear previous error message if it was a device conflict message
                          if (provider.state.errorMessage.contains(
                            'already logged in on another device',
                          )) {
                            provider.state.errorMessage = '';
                            provider.notifyListeners();
                          }
                          await provider.signIn();
                        },
                        title: 'Login',
                        isloading: provider.state.isLoading,
                        isEnabled:
                            !provider.state.isLoading &&
                            provider.state.email.trim().isNotEmpty &&
                            provider.state.password.trim().isNotEmpty,
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            GestureDetector(
                              onTap: widget.onSwitched,
                              child: Text(
                                "Sign up",
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
