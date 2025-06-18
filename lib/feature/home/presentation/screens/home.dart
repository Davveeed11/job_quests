import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/home/presentation/widget/category_card.dart';
import 'package:my_job_quest/feature/home/presentation/widget/job_card.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<User?>? _authStateChangesSubscription;
  String userName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initializeUserName();
    _authStateChangesSubscription = FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) {
          if (mounted) {
            setState(() {
              userName = user?.displayName ?? 'Job Seeker';
            });
          }
        });
    // Add listener to search controller for dynamic clear button visibility
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userName = user.displayName ?? 'Job Seeker';
      });
    }
  }

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
  Widget build(BuildContext context) {
    const double customHeaderHeight = 180.0;
    const double searchBarHeight = 60.0;
    const double searchBarHorizontalPadding = 16.0;
    const double searchBarTopPosition =
        customHeaderHeight - (searchBarHeight * 0.75);
    final double scrollableContentTopPadding =
        searchBarTopPosition + searchBarHeight + 20.0;
    final authProvider = Provider.of<MyAuthProvider>(context);
    final List<Map<String, dynamic>> jobCategories = [
      {'name': 'Software Development', 'icon': Icons.code, 'jobCount': 120},
      {'name': 'Marketing', 'icon': Icons.campaign, 'jobCount': 85},
      {'name': 'Design', 'icon': Icons.palette, 'jobCount': 60},
      {'name': 'Data Science', 'icon': Icons.analytics, 'jobCount': 45},
      {'name': 'Finance', 'icon': Icons.attach_money, 'jobCount': 90},
      {'name': 'Healthcare', 'icon': Icons.local_hospital, 'jobCount': 75},
      {'name': 'Education', 'icon': Icons.school, 'jobCount': 110},
      {'name': 'Sales', 'icon': Icons.storefront, 'jobCount': 50},
    ];

    return Stack(
      children: [
        // Background Header Area
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

        // Floating background shapes (for visual flair)
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

        // Custom Header Content (Greeting, Name, Profile, Notifications)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120.0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          getTimeOfDayGreeting(),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                            shadows: [
                              Shadow(
                                blurRadius: 2.0,
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 24,
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black45,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 28,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications tapped!'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile tapped!')),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        // You can use a NetworkImage or AssetImage here for a real profile picture
                        // backgroundImage: NetworkImage('https://example.com/your_profile_pic.jpg'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Fixed Search Bar
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
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 20.0,
                ),
              ),
              onSubmitted: (query) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching for: "$query"...')),
                );
              },
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
                // Job Categories Section
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
                // SizedBox(
                //   height: 138, // Increased height for better visibility
                //   child: ListView.builder(
                //     scrollDirection: Axis.horizontal,
                //     padding: const EdgeInsets.symmetric(horizontal: 16.0),
                //     itemCount: jobCategories.length,
                //     itemBuilder: (context, index) {
                //       final category = jobCategories[index];
                //       return Padding(
                //         padding: const EdgeInsets.only(
                //           right: 12.0,
                //         ), // Spacing between cards
                //         child: SizedBox(
                //           width: 180.0, // Example width, adjust as needed
                //           child: CategoryCard(
                //             name: category['name']!,
                //             icon: category['icon']!,
                //             jobCount:
                //                 category['jobCount']!, // Pass the job count
                //           ),
                //         ),
                //       );
                //     },
                //   ),
                // ),
                const SizedBox(height: 24),

                // Recommended for you section
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
                  child:
                      StreamBuilder<
                        List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      >(
                        stream: authProvider.recommendedJobsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading recommended jobs: ${snapshot.error}',
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            String message = 'No recommended jobs found.';
                            if (authProvider.state.user != null &&
                                authProvider.state.skillRank.isEmpty) {
                              message =
                                  'Please set your skill rank in Settings to see recommendations!';
                            }
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star_half,
                                      size: 40,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withOpacity(0.4),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      message,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground
                                            .withOpacity(0.6),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final recommendedJobsDocs = snapshot.data!;
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            itemCount: recommendedJobsDocs.length,
                            itemBuilder: (context, index) {
                              final jobDoc = recommendedJobsDocs[index];
                              final jobData = jobDoc.data();
                              print(recommendedJobsDocs.length);
                              return Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: JobCard(
                                  job: jobData,
                                  jobId:
                                      jobDoc.id, // Pass the actual document ID
                                ),
                              );
                            },
                          );
                        },
                      ),
                ),
                const SizedBox(height: 24),

                // Community Job Board section
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
                      .allJobsDocsStream, // Use the stream for all jobs
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_alt_1,
                                size: 40,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onBackground.withOpacity(0.4),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No community jobs posted yet. Be the first to share one!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onBackground.withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
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
                          final jobData = jobDoc.data();
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: JobCard(
                              job: jobData,
                              jobId: jobDoc.id, // Pass the actual document ID
                            ),
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
}
