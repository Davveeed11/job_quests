import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/home/presentation/widget/app_disclaimer_dialog.dart';
import 'package:my_job_quest/feature/home/presentation/widget/custom_search_bar.dart';
import 'package:my_job_quest/feature/home/presentation/widget/header_icon_button.dart';
import 'package:my_job_quest/feature/home/presentation/widget/horizontal_scrollable_section.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Local Imports (make sure these paths are correct in your project)
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/home/presentation/widget/category_card.dart';
import 'package:my_job_quest/feature/home/presentation/widget/job_card.dart';

import 'package:my_job_quest/feature/home/presentation/screens/recommended_jobs_screen.dart';
import 'package:my_job_quest/feature/home/presentation/screens/community_jobs_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  StreamSubscription<User?>? _authStateChangesSubscription;
  String userName = 'Loading...';
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeUserName();

    _authStateChangesSubscription = FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) {
          if (mounted) {
            setState(() {
              userName = user?.displayName ?? 'Job Seeker';
              if (user != null && user.displayName != null) {
                analytics.setUserProperty(
                  name: 'user_name',
                  value: user.displayName,
                );
              }
            });
          }
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use the extracted function for the disclaimer dialog
      showAppDisclaimerDialog(context);
      _fadeAnimationController.forward();
      _slideAnimationController.forward();
    });
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _initializeUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userName = user.displayName ?? 'Job Seeker';
        analytics.setUserProperty(name: 'user_name', value: user.displayName);
      });
      analytics.setUserId(id: user.uid);
    } else {
      analytics.setUserId(id: null);
      analytics.setUserProperty(name: 'user_name', value: 'guest');
    }
  }

  String _getTimeOfDayGreeting() {
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

  PageRouteBuilder _buildPageRoute(Widget page, String routeName) {
    return PageRouteBuilder(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(
              curve: curve,
            ), // Use easeOutCubic for fade as well for consistency
          ),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double responsiveHeaderHeight = (screenHeight * 0.25).clamp(
      180.0,
      250.0,
    );
    const double searchBarHeight = 56.0;
    final double horizontalPadding = screenWidth * 0.05;

    final double searchBarTopPosition =
        responsiveHeaderHeight - (searchBarHeight * 0.6);
    final double scrollableContentTopPadding =
        searchBarTopPosition + searchBarHeight + 24.0;

    final authProvider = Provider.of<MyAuthProvider>(context);

    final List<Map<String, dynamic>> jobCategories = [
      {
        'name': 'Software Development',
        'icon': Icons.code,
        'jobCount': 120,
        'color': Colors.blue,
      },
      {
        'name': 'Marketing',
        'icon': Icons.campaign,
        'jobCount': 85,
        'color': Colors.orange,
      },
      {
        'name': 'Design',
        'icon': Icons.palette,
        'jobCount': 60,
        'color': Colors.purple,
      },
      {
        'name': 'Data Science',
        'icon': Icons.analytics,
        'jobCount': 45,
        'color': Colors.green,
      },
      {
        'name': 'Finance',
        'icon': Icons.attach_money,
        'jobCount': 90,
        'color': Colors.teal,
      },
      {
        'name': 'Healthcare',
        'icon': Icons.local_hospital,
        'jobCount': 75,
        'color': Colors.red,
      },
      {
        'name': 'Education',
        'icon': Icons.school,
        'jobCount': 110,
        'color': Colors.indigo,
      },
      {
        'name': 'Sales',
        'icon': Icons.storefront,
        'jobCount': 50,
        'color': Colors.amber,
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            _buildEnhancedBackground(responsiveHeaderHeight),
            _buildFloatingShapes(),
            _buildCustomHeader(responsiveHeaderHeight),
            CustomSearchBar(
              // Using extracted CustomSearchBar widget
              topPosition: searchBarTopPosition,
              horizontalPadding: horizontalPadding,
              height: searchBarHeight,
            ),
            _buildMainContent(
              scrollableContentTopPadding,
              authProvider,
              jobCategories,
              horizontalPadding,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBackground(double headerHeight) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: headerHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.6),
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingShapes() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomHeader(double headerHeight) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: headerHeight * 0.7,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getTimeOfDayGreeting(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 28,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              blurRadius: 8.0,
                              color: Colors.black26,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find your dream job today',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Row(
                //   children: [
                //     HeaderIconButton(
                //       // Using extracted HeaderIconButton
                //       icon: Icons.notifications_outlined,
                //       onPressed: () {
                //         ScaffoldMessenger.of(context).showSnackBar(
                //           SnackBar(
                //             content: const Text('Notifications opened'),
                //             behavior: SnackBarBehavior.floating,
                //             shape: RoundedRectangleBorder(
                //               borderRadius: BorderRadius.circular(10),
                //             ),
                //           ),
                //         );
                //         analytics.logEvent(name: 'notifications_tapped');
                //       },
                //     ),
                //     const SizedBox(width: 12),
                //     const ProfileAvatar(), // Using extracted ProfileAvatar
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    double topPadding,
    MyAuthProvider authProvider,
    List<Map<String, dynamic>> jobCategories,
    double horizontalPadding,
  ) {
    return Positioned.fill(
      top: topPadding,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explicitly define the generic type here: <Map<String, dynamic>>
              HorizontalScrollableSection<Map<String, dynamic>>(
                title: 'Recommended for you',
                onSeeAllPressed: () {
                  Navigator.of(context).push(
                    _buildPageRoute(
                      const RecommendedJobsScreen(),
                      '/recommended_jobs',
                    ),
                  );
                  analytics.logEvent(name: 'see_all_recommended_jobs');
                },
                stream: authProvider.recommendedJobsStream,
                itemBuilder: (context, jobData) {
                  // jobData is now correctly inferred as Map<String, dynamic>
                  // jobData is already processed by HorizontalScrollableSection
                  return JobCard(
                    job: jobData,
                    jobId:
                        jobData['jobId'], // jobId is now guaranteed to be in jobData
                    onTap: () {
                      analytics.logSelectContent(
                        contentType: 'job_recommendation',
                        itemId: jobData['jobId'],
                      );
                    },
                  );
                },
                itemWidth: 200, // Adjusted to show more of the next card
                listHeight: 240,
                emptyMessage:
                    authProvider.state.user != null &&
                        authProvider.state.skillRank.isEmpty
                    ? 'Please set your skill rank in Settings to see recommendations!'
                    : 'No recommended jobs found.',
                emptyIcon: Icons.star_half,
              ),
              // Explicitly define the generic type here: <Map<String, dynamic>>
              HorizontalScrollableSection<Map<String, dynamic>>(
                title: 'Community Job Board',
                onSeeAllPressed: () {
                  Navigator.of(context).push(
                    _buildPageRoute(
                      const CommunityJobsScreen(),
                      '/community_jobs',
                    ),
                  );
                  analytics.logEvent(name: 'see_all_community_jobs');
                },
                stream: authProvider.allJobsDocsStream,
                itemBuilder: (context, jobData) {
                  // jobData is now correctly inferred as Map<String, dynamic>
                  return JobCard(
                    job: jobData, // This assignment is now valid
                    jobId:
                        jobData['jobId'], // jobId is now guaranteed to be in jobData
                    onTap: () {
                      analytics.logSelectContent(
                        contentType: 'community_job',
                        itemId: jobData['jobId'],
                      );
                    },
                  );
                },
                itemWidth: 200, // Adjusted to show more of the next card
                listHeight: 240,
                emptyMessage:
                    'No community jobs posted yet. Be the first to share one!',
                emptyIcon: Icons.person_add_alt_1,
              ),
              const SizedBox(height: 2), // Reduced spacing
              // This one was already correctly typed
              HorizontalScrollableSection<Map<String, dynamic>>(
                title: 'Browse Categories',
                onSeeAllPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('See All Categories tapped!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  analytics.logEvent(name: 'see_all_categories');
                },
                staticItems: jobCategories, // Pass static items
                itemBuilder: (context, category) {
                  // Category is already inferred as Map<String, dynamic> due to staticItems
                  return CategoryCard(
                    name: category['name'],
                    icon: category['icon'],
                    jobCount: category['jobCount'],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tapped on ${category['name']}'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      analytics.logEvent(
                        name: 'category_tapped',
                        parameters: {'category_name': category['name']},
                      );
                    },
                  );
                },
                itemWidth: 150, // This width generally allows multiple to show
                listHeight: 150,
                emptyMessage: 'No categories available.',
                emptyIcon: Icons.category,
              ),
              const SizedBox(height: 20), // Reduced spacing
            ],
          ),
        ),
      ),
    );
  }
}
