import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/core/theme/theme_provider.dart';
import 'package:my_job_quest/feature/home/presentation/screens/saved_jobs_screen.dart';
import 'package:my_job_quest/feature/profile/presentation/screen/settings_screen.dart';
import 'package:my_job_quest/feature/skills/presentation/screens/job_posting_screen.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // For StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart'; // For QueryDocumentSnapshot

import 'package:my_job_quest/feature/home/presentation/widget/job_card.dart';
import 'package:my_job_quest/feature/home/presentation/widget/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = 'Loading...';
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<User?>? _authStateChangesSubscription;

  int _selectedIndex = 0;
  List<Widget> get _pages {
    return [
      _buildHomeContent(context),
      const Center(child: Text('Search Screen Content Coming Soon!')),
      const SavedJobsScreen(), // Your Saved Jobs Screen
      const SettingsScreen(), // Placeholder for Profile
    ];
  }

  final List<Map<String, dynamic>> _jobCategories = [
    {'name': 'Software Development', 'icon': Icons.code},
    {'name': 'Marketing', 'icon': Icons.campaign},
    {'name': 'Design', 'icon': Icons.palette},
    {'name': 'Data Science', 'icon': Icons.analytics},
    {'name': 'Finance', 'icon': Icons.attach_money},
    {'name': 'Healthcare', 'icon': Icons.local_hospital},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Sales', 'icon': Icons.storefront},
  ];

  final List<Map<String, dynamic>> _recommendedJobs = [
    {
      'jobId': 'rec_flutter_1',
      'jobTitle': 'Senior Flutter Developer',
      'company': 'Tech Solutions Inc.',
      'location': 'Remote',
      'salary': '\$120K - \$150K',
      'jobType': 'Full-time',
      'logoChar': 'T',
    },
    {
      'jobId': 'rec_ux_2',
      'jobTitle': 'UX Designer',
      'company': 'Creative Minds Studio',
      'location': 'New York, NY',
      'salary': '\$90K - \$110K',
      'jobType': 'Full-time',
      'logoChar': 'C',
    },
    {
      'jobId': 'rec_data_3',
      'jobTitle': 'Data Analyst',
      'company': 'Quant Insights LLC',
      'location': 'Austin, TX',
      'salary': '\$70K - \$90K',
      'jobType': 'Hybrid',
      'logoChar': 'Q',
    },
    {
      'jobId': 'rec_pm_4',
      'jobTitle': 'Product Manager',
      'company': 'Innovate Corp.',
      'location': 'San Francisco, CA',
      'salary': '\$130K - \$160K',
      'jobType': 'Full-time',
      'logoChar': 'I',
    },
    {
      'jobId': 'rec_marketing_5',
      'jobTitle': 'Digital Marketing Specialist',
      'company': 'Global Reach Media',
      'location': 'Remote',
      'salary': '\$60K - \$80K',
      'jobType': 'Contract',
      'logoChar': 'G',
    },
    {
      'jobId': 'rec_cloud_6',
      'jobTitle': 'Cloud Architect',
      'company': 'Azure Solutions',
      'location': 'Seattle, WA',
      'salary': '\$140K - \$170K',
      'jobType': 'Full-time',
      'logoChar': 'A',
    },
  ];

  String getTimeOfDayGreeting() {
    final now = DateTime.now().hour;
    if (now >= 5 && now < 12) {
      return 'Good morning';
    } else if (now >= 12 && now < 17) {
      return 'Good afternoon';
    } else if (now >= 17 && now < 22) {
      return 'Good evening';
    } else {
      return 'Hello';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeUserName();

    // REMOVED: _pages initialization from initState, as it's now a getter.

    _authStateChangesSubscription = FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) {
          if (mounted) {
            setState(() {
              userName = user?.displayName ?? 'Job Seeker';
            });
          }
        });
  }

  void _initializeUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userName = user.displayName ?? 'Job Seeker';
      });
    }
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to build the content for the "Home" tab
  Widget _buildHomeContent(BuildContext context) {
    const double customHeaderHeight = 180.0;
    const double searchBarHeight = 60.0;
    const double searchBarHorizontalPadding = 16.0;
    const double searchBarTopPosition =
        customHeaderHeight - (searchBarHeight * 0.75);
    final double scrollableContentTopPadding =
        searchBarTopPosition + searchBarHeight + 20.0;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<MyAuthProvider>(context);

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: customHeaderHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  spreadRadius: 0,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -MediaQuery.of(context).size.width * 0.4,
          left: -MediaQuery.of(context).size.width * 0.2,
          child: Container(
            width: MediaQuery.of(context).size.width * 1.2,
            height: MediaQuery.of(context).size.width * 1.2,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -MediaQuery.of(context).size.width * 0.4,
          right: -MediaQuery.of(context).size.width * 0.2,
          child: Container(
            width: MediaQuery.of(context).size.width * 1.0,
            height: MediaQuery.of(context).size.width * 1.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: searchBarTopPosition,
          left: searchBarHorizontalPadding,
          right: searchBarHorizontalPadding,
          child: Container(
            height: searchBarHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for jobs, companies...',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 20.0,
                ),
              ),
              onChanged: (text) {
                setState(() {});
              },
              onSubmitted: (query) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching for: "$query"...')),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120.0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTimeOfDayGreeting(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Tooltip(
                          message: 'Toggle Light/Dark Mode',
                          child: Switch(
                            value: themeProvider.themeMode == ThemeMode.dark,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                            activeColor: Colors.white,
                            inactiveTrackColor: Colors.white38,
                            activeTrackColor: Colors.white70,
                            inactiveThumbColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: authProvider.state.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 28,
                                ),
                          tooltip: 'Logout',
                          onPressed: authProvider.state.isLoading
                              ? null
                              : () async {
                                  bool confirmSignOut =
                                      await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.surface,
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
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(false),
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
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(true),
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
                                    // AuthChanges will handle navigation after signout
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Main Scrollable Content
        Positioned.fill(
          top: scrollableContentTopPadding,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Job Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('See All Categories tapped!'),
                            ),
                          );
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120, // Increased height for better visibility
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _jobCategories.length,
                    itemBuilder: (context, index) {
                      final category = _jobCategories[index];
                      // Using the imported CategoryCard
                      return SizedBox(
                        width: 180.0, // Example width, adjust as needed
                        child: CategoryCard(
                          name: category['name']!,
                          icon: category['icon']!,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recommended for you',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('See All Recommended tapped!'),
                            ),
                          );
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220, // Height matching JobCard
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _recommendedJobs.length,
                    itemBuilder: (context, index) {
                      final job = _recommendedJobs[index];
                      // Using the imported JobCard
                      return JobCard(job: job, jobId: job['jobId'] as String);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Community Job Board',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('See All Community Jobs tapped!'),
                            ),
                          );
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<
                  List<QueryDocumentSnapshot<Map<String, dynamic>>>
                >(
                  stream: authProvider
                      .allJobsDocsStream, // Assuming this stream exists in MyAuthProvider
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'No community jobs posted yet. Be the first!',
                        ),
                      );
                    }
                    final communityJobsDocs = snapshot.data!;
                    return SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: communityJobsDocs.length,
                        itemBuilder: (context, index) {
                          final jobDoc = communityJobsDocs[index];
                          // Using the imported JobCard
                          return JobCard(
                            job: jobDoc.data(),
                            jobId:
                                jobDoc.id, // Pass the actual document ID here
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _pages[_selectedIndex], // Access the _pages getter here
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(
              // NEW: Saved Jobs Item
              icon: Icon(Icons.bookmark_outline),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.5),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 1 || index == 3) {
              String screenName;
              switch (index) {
                case 1:
                  screenName = 'Search';
                  break;
                case 3:
                  screenName = 'Profile';
                  break;
                default:
                  screenName = '';
                  break;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$screenName Screen Coming Soon!')),
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
                ),
              ),
              icon: Icon(
                Icons.add_business_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
