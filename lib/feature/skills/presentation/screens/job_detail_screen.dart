import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  final String? jobId;

  const JobDetailScreen({super.key, required this.job, this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with TickerProviderStateMixin {
  late bool _isBookmarked;
  StreamSubscription? _bookmarkSubscription;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _bookmarkAnimationController;
  late Animation<double> _bookmarkScaleAnimation;

  @override
  void initState() {
    super.initState();
    _isBookmarked = false;
    _setupAnimations();
    _listenToBookmarkStatus();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _bookmarkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bookmarkScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _bookmarkAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant JobDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jobId != oldWidget.jobId) {
      _bookmarkSubscription?.cancel();
      _listenToBookmarkStatus();
    }
  }

  void _listenToBookmarkStatus() {
    Future.microtask(() {
      if (!mounted) return;
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);

      if (authProvider.state.user != null && widget.jobId != null) {
        _bookmarkSubscription?.cancel();
        _bookmarkSubscription = authProvider.getSavedJobsStream().listen((
          savedJobIds,
        ) {
          if (mounted) {
            setState(() {
              _isBookmarked = savedJobIds.contains(widget.jobId);
            });
          }
        });
      } else if (mounted) {
        setState(() => _isBookmarked = false);
      }
    });
  }

  @override
  void dispose() {
    _bookmarkSubscription?.cancel();
    _animationController.dispose();
    _bookmarkAnimationController.dispose();
    super.dispose();
  }

  // Theme-aware gradient builder
  LinearGradient _buildBackgroundGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return const LinearGradient(
        colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.5, 1.0],
      );
    } else {
      return LinearGradient(
        colors: [Colors.blue.shade50, Colors.white, Colors.grey.shade50],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      );
    }
  }

  // Theme-aware card color
  Color _getCardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.7);
  }

  // Theme-aware text colors
  Color _getPrimaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.grey.shade800;
  }

  Color _getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Job Data Extraction
    final String jobTitle = widget.job['jobTitle'] ?? 'Job Title Not Provided';
    final String company = widget.job['company'] ?? 'Company Unknown';
    final String jobDescription =
        widget.job['jobDescription'] ?? 'No description available.';
    final String salary = widget.job['salary'] ?? 'Not Disclosed';
    final String jobType = widget.job['jobType'] ?? 'Full-time';

    final dynamic rawRequiredSkills = widget.job['requiredSkills'];
    final String requiredSkills = (rawRequiredSkills is List)
        ? rawRequiredSkills.map((e) => e.toString()).join(', ')
        : rawRequiredSkills?.toString() ?? 'No specific skills listed.';

    final dynamic rawLocation = widget.job['location'];
    final String location = (rawLocation is List)
        ? rawLocation.map((e) => e.toString()).join(', ')
        : rawLocation?.toString() ?? 'Remote';

    final String difficultyRank =
        widget.job['difficultyRank']?.toString() ??
        widget.job['jobDifficultyRank']?.toString() ??
        'N/A';

    final String logoChar = company.isNotEmpty ? company[0].toUpperCase() : '?';

    final String postedByUserId = widget.job['postedByUserId'] ?? '';
    final bool isOwner =
        authProvider.state.user?.uid != null &&
        authProvider.state.user!.uid == postedByUserId;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: _buildBackgroundGradient(context),
          ),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 140,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  title: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      jobTitle,
                      style: GoogleFonts.montserrat(
                        color: _getPrimaryTextColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: isDark
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: _getPrimaryTextColor(context),
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                actions: [
                  if (!isOwner &&
                      authProvider.state.user != null &&
                      widget.jobId != null)
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCardColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: ScaleTransition(
                        scale: _bookmarkScaleAnimation,
                        child: IconButton(
                          icon: Icon(
                            _isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: _isBookmarked
                                ? Theme.of(context).primaryColor
                                : _getSecondaryTextColor(context),
                            size: 24,
                          ),
                          onPressed: () {
                            if (widget.jobId != null) {
                              _bookmarkAnimationController.forward().then((_) {
                                _bookmarkAnimationController.reverse();
                              });

                              if (_isBookmarked) {
                                authProvider.removeBookmark(widget.jobId!);
                              } else {
                                authProvider.addBookmark(
                                  widget.jobId!,
                                  widget.job,
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company Avatar & Info
                      Center(
                        child: Column(
                          children: [
                            Hero(
                              tag: 'company-$company',
                              child: Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    logoChar,
                                    style: GoogleFonts.inter(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              company,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: _getSecondaryTextColor(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Enhanced Info Tags
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildEnhancedInfoTag(
                              context,
                              Icons.location_on_outlined,
                              location,
                            ),
                            _buildEnhancedInfoTag(
                              context,
                              Icons.work_outline,
                              jobType,
                            ),
                            _buildEnhancedInfoTag(
                              context,
                              Icons.monetization_on_outlined,
                              salary,
                            ),
                            _buildEnhancedInfoTag(
                              context,
                              Icons.bar_chart,
                              'Rank: $difficultyRank',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Job Description
                      _buildEnhancedSection(
                        context,
                        'Job Description',
                        Icons.description_outlined,
                        jobDescription,
                      ),
                      const SizedBox(height: 32),

                      // Required Skills
                      _buildEnhancedSection(
                        context,
                        'Required Skills',
                        Icons.psychology_outlined,
                        requiredSkills,
                      ),
                      const SizedBox(height: 40),

                      // Enhanced Apply Button
                      Center(child: _buildEnhancedApplyButton(context)),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSection(
    BuildContext context,
    String title,
    IconData icon,
    String content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  color: _getPrimaryTextColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            content,
            style: GoogleFonts.inter(
              color: _getSecondaryTextColor(context),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedInfoTag(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: _getPrimaryTextColor(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedApplyButton(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.rocket_launch, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Application feature coming soon!'),
                  ],
                ),
                backgroundColor: Theme.of(context).primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Apply Now',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
