import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/home/presentation/screens/home.dart';
import 'package:my_job_quest/feature/home/presentation/screens/saved_jobs_screen.dart';
import 'package:my_job_quest/feature/search/search_screen.dart';
import 'package:my_job_quest/feature/skills/presentation/screens/job_posting_screen.dart';
import 'package:my_job_quest/feature/profile/presentation/screen/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _pages {
    return [
      Home(),
      // Spiced up Search placeholder
      SearchScreen(),
      const SavedJobsScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        // Enhanced bottom navigation bar container
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.1), // More prominent shadow
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, -7), // Deeper shadow effect
            ),
          ],
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(25),
          ), // More rounded top corners
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors
              .transparent, // Make background transparent to show container decoration
          elevation: 0, // No default elevation
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13, // Slightly larger selected label
            color: Theme.of(
              context,
            ).colorScheme.primary, // Ensure color is consistent
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home_outlined,
              ), // Outlined for unselected, filled for selected if needed
              activeIcon: Icon(Icons.home), // Filled icon for active state
              label: 'Home',
              tooltip: 'Go to Home', // Added tooltip
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
              tooltip: 'Search for Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.bookmark_border,
              ), // Changed to border for consistency
              activeIcon: Icon(Icons.bookmark),
              label: 'Saved',
              tooltip: 'View Saved Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
              tooltip: 'App Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface
              .withOpacity(0.6), // Slightly darker unselected
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'The search feature is currently under development. Please check back later!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JobPostingScreen(),
                  ),
                );
              },
              label: Text(
                'Post a Job',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold, // Make label bolder
                ),
              ),
              icon: Icon(
                Icons.add_business_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  20,
                ), // Slightly more rounded shape
              ),
              elevation: 10, // Increased elevation for more pop
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
