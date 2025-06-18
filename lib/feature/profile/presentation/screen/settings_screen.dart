import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/auth/presentation/screen/login_or_register.dart';
import 'package:my_job_quest/feature/core/theme/theme_provider.dart';
import 'package:my_job_quest/feature/profile/presentation/screen/rank_faq_page.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Get the user's display name, or a default if not available
    final String accountName =
        authProvider.state.user?.displayName ?? 'Job Seeker';
    final String userEmail = authProvider.state.user?.email ?? 'No Email';
    final String userSkillRank = authProvider.state.skillRank.isNotEmpty
        ? authProvider.state.skillRank
        : 'Not set';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Name Section
            GestureDetector(
              // onTap: () {
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) {
              //         return ProfileScreen();
              //       },
              //     ),
              //   );
              // },
              child: Container(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Text(
                        accountName.isNotEmpty
                            ? accountName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accountName,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Theme Switcher Section
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.brightness_medium,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'App Theme',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    underline: const SizedBox.shrink(),
                    onChanged: (ThemeMode? newValue) {
                      if (newValue != null) {
                        themeProvider.setThemeMode(newValue);
                      }
                    },
                    items: const <DropdownMenuItem<ThemeMode>>[
                      DropdownMenuItem<ThemeMode>(
                        value: ThemeMode.system,
                        child: Text('System Default'),
                      ),
                      DropdownMenuItem<ThemeMode>(
                        value: ThemeMode.light,
                        child: Text('Light Mode'),
                      ),
                      DropdownMenuItem<ThemeMode>(
                        value: ThemeMode.dark,
                        child: Text('Dark Mode'),
                      ),
                    ],
                    selectedItemBuilder: (BuildContext context) {
                      return <Widget>[
                        Text(
                          'System Default',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Light Mode',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Dark Mode',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'My Skill Rank:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    userSkillRank,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // General Settings Section (Example)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.notifications_active,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'Notification Settings',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notification settings coming soon!'),
                        ),
                      );
                    },
                  ),
                  Divider(
                    height: 0,
                    indent: 20,
                    endIndent: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Privacy Policy coming soon!')),
                      );
                    },
                  ),
                  Divider(
                    height: 0,
                    indent: 20,
                    endIndent: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                  ),
                  // FAQ Tile
                  ListTile(
                    leading: Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'FAQ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RankFaqPage(),
                        ),
                      );
                    },
                  ),
                  Divider(
                    height: 0,
                    indent: 20,
                    endIndent: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.info,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'About App',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('About app info coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            Center(
              child: SizedBox(
                width:
                    MediaQuery.of(context).size.width *
                    0.7, // Make it a bit narrower
                child: ElevatedButton.icon(
                  icon: authProvider.state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    'Log Out',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  onPressed: authProvider.state.isLoading
                      ? null
                      : () async {
                          bool confirmSignOut =
                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      'Confirm Sign Out',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to sign out?',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.8),
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text(
                                          'Sign Out',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ) ??
                              false;
                          if (confirmSignOut) {
                            await authProvider.signout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginOrRegister(),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.error, // Use error color for logout
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
