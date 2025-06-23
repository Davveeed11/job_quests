import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/skills/presentation/screens/job_detail_screen.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class JobCard extends StatefulWidget {
  final Map<String, dynamic> job;
  final String? jobId;
  final Function(String, bool)? onBookmarkToggled;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.job,
    this.jobId,
    this.onBookmarkToggled,
    this.onTap,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> with TickerProviderStateMixin {
  late bool _isBookmarked;
  StreamSubscription? _bookmarkSubscription;

  // Made nullable to avoid LateInitializationError
  AnimationController? _animationController;
  AnimationController? _bookmarkAnimationController;
  AnimationController? _hoverController;

  Animation<double>? _scaleAnimation;
  Animation<double>? _bookmarkScaleAnimation;
  Animation<double>? _elevationAnimation;
  Animation<Color?>? _colorAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _isBookmarked = false;
    _setupAnimations();
    _listenToBookmarkStatus();
  }

  void _setupAnimations() {
    // Press animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );

    // Bookmark animation
    _bookmarkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bookmarkScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _bookmarkAnimationController!,
        curve: Curves.elasticOut,
      ),
    );

    // Hover animation
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _elevationAnimation = Tween<double>(begin: 8.0, end: 16.0).animate(
      CurvedAnimation(parent: _hoverController!, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    _colorAnimation =
        ColorTween(
          begin: theme.colorScheme.surface,
          end: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
        ).animate(
          CurvedAnimation(parent: _hoverController!, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(covariant JobCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jobId != oldWidget.jobId) {
      _bookmarkSubscription?.cancel();
      _listenToBookmarkStatus();
    }
  }

  void _listenToBookmarkStatus() {
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
    } else {
      if (mounted) {
        setState(() {
          _isBookmarked = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bookmarkSubscription?.cancel();
    _animationController?.dispose();
    _bookmarkAnimationController?.dispose();
    _hoverController?.dispose();
    super.dispose();
  }

  // Theme-aware gradient for hover effect
  LinearGradient _getCardGradient(BuildContext context, bool isHovered) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!isHovered) {
      return LinearGradient(
        colors: [theme.colorScheme.surface, theme.colorScheme.surface],
      );
    }

    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.surface,
          theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          theme.colorScheme.surface,
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.surface,
          theme.primaryColor.withOpacity(0.02),
          theme.colorScheme.surface,
        ],
        stops: const [0.0, 0.5, 1.0],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return early if animations aren't initialized
    if (_animationController == null || _hoverController == null) {
      return const SizedBox.shrink();
    }

    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final theme = Theme.of(context);

    final String jobTitle =
        widget.job['jobTitle'] ??
        widget.job['title'] ??
        'Job Title Not Provided';
    final String company =
        widget.job['company'] ?? widget.job['posterName'] ?? 'Company Unknown';

    final dynamic rawLocation = widget.job['location'];
    final String location;
    if (rawLocation is List) {
      location = rawLocation.map((e) => e.toString()).join(', ');
    } else {
      location = rawLocation as String? ?? 'Remote / Anywhere';
    }

    final String salary = widget.job['salary'] ?? 'Negotiable';
    final String jobType =
        widget.job['jobType'] ?? widget.job['type'] ?? 'Full-time';
    final String logoChar =
        widget.job['logoChar'] ??
        (company.isNotEmpty ? company[0].toUpperCase() : '?');

    final String difficultyRank =
        widget.job['jobDifficultyRank'] ??
        widget.job['difficultyRank'] ??
        'N/A';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340, minWidth: 280),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _animationController!,
            _hoverController!,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation?.value ?? 1.0,
              child: MouseRegion(
                onEnter: (_) {
                  setState(() => _isHovered = true);
                  _hoverController?.forward();
                },
                onExit: (_) {
                  setState(() => _isHovered = false);
                  _hoverController?.reverse();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ), // Reduced margin
                  decoration: BoxDecoration(
                    gradient: _getCardGradient(context, _isHovered),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isHovered
                          ? theme.primaryColor.withOpacity(0.3)
                          : theme.colorScheme.outline.withOpacity(0.08),
                      width: _isHovered ? 1.2 : 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.12),
                        blurRadius: _elevationAnimation?.value ?? 8.0,
                        offset: Offset(
                          0,
                          (_elevationAnimation?.value ?? 8.0) * 0.3,
                        ),
                        spreadRadius: _isHovered ? 2 : 0,
                      ),
                      if (_isHovered)
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTapDown: (_) => _animationController?.forward(),
                      onTapUp: (_) => _animationController?.reverse(),
                      onTapCancel: () => _animationController?.reverse(),
                      splashColor: theme.primaryColor.withOpacity(0.1),
                      highlightColor: theme.primaryColor.withOpacity(0.05),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onTap?.call();

                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    JobDetailScreen(
                                      job: widget.job,
                                      jobId: widget.jobId,
                                    ),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOutCubic;

                                  var tween = Tween(
                                    begin: begin,
                                    end: end,
                                  ).chain(CurveTween(curve: curve));

                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                            transitionDuration: const Duration(
                              milliseconds: 350,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0), // Reduced padding
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Enhanced Company Avatar
                                Hero(
                                  tag:
                                      'company-avatar-${widget.jobId ?? company}-${widget.hashCode}',
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.primaryColor.withOpacity(0.8),
                                          theme.primaryColor,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.primaryColor.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        logoChar,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(
                                        jobTitle,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onSurface,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.business_rounded,
                                            size: 16,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              company,
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Enhanced Bookmark Button
                                if (widget.jobId != null &&
                                    authProvider.state.user != null)
                                  ScaleTransition(
                                    scale:
                                        _bookmarkScaleAnimation ??
                                        const AlwaysStoppedAnimation(1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _isBookmarked
                                            ? theme.primaryColor.withOpacity(
                                                0.1,
                                              )
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _isBookmarked
                                              ? theme.primaryColor.withOpacity(
                                                  0.3,
                                                )
                                              : theme.colorScheme.outline
                                                    .withOpacity(0.2),
                                        ),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _isBookmarked
                                              ? Icons.bookmark_rounded
                                              : Icons.bookmark_outline_rounded,
                                          size: 24,
                                        ),
                                        color: _isBookmarked
                                            ? theme.primaryColor
                                            : theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                        onPressed: () => _handleBookmarkTap(
                                          authProvider,
                                          theme,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16), // Reduced spacing
                            // Enhanced Info Chips with better wrapping
                            Flexible(
                              child: Wrap(
                                spacing: 8.0, // Reduced spacing
                                runSpacing: 8.0, // Reduced spacing
                                children: [
                                  _buildEnhancedInfoChip(
                                    context,
                                    Icons.location_on_rounded,
                                    location,
                                    theme.colorScheme.secondary,
                                  ),
                                  _buildEnhancedInfoChip(
                                    context,
                                    Icons.work_outline_rounded,
                                    jobType,
                                    theme.primaryColor,
                                  ),
                                  _buildEnhancedInfoChip(
                                    context,
                                    Icons.payments_rounded,
                                    salary,
                                    theme.colorScheme.tertiary,
                                  ),
                                  _buildEnhancedInfoChip(
                                    context,
                                    Icons.trending_up_rounded,
                                    difficultyRank,
                                    theme.colorScheme.error,
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
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleBookmarkTap(
    MyAuthProvider authProvider,
    ThemeData theme,
  ) async {
    HapticFeedback.mediumImpact();

    // Animate bookmark button safely
    if (_bookmarkAnimationController != null) {
      _bookmarkAnimationController!.forward().then((_) {
        _bookmarkAnimationController!.reverse();
      });
    }

    if (authProvider.state.user == null) {
      _showSnackBar(
        'Please log in to save jobs.',
        theme.colorScheme.error,
        theme.colorScheme.onError,
        Icons.login_rounded,
      );
      return;
    }

    try {
      if (_isBookmarked) {
        await authProvider.removeBookmark(widget.jobId!);
        _showSnackBar(
          'Job removed from saved list',
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurface,
          Icons.bookmark_remove_rounded,
        );
      } else {
        await authProvider.addBookmark(widget.jobId!, widget.job);
        _showSnackBar(
          'Job saved successfully!',
          theme.primaryColor,
          theme.colorScheme.onPrimary,
          Icons.bookmark_added_rounded,
        );
      }
      widget.onBookmarkToggled?.call(widget.jobId!, !_isBookmarked);
    } catch (e) {
      _showSnackBar(
        'Something went wrong. Please try again.',
        theme.colorScheme.error,
        theme.colorScheme.onError,
        Icons.error_outline_rounded,
      );
    }
  }

  void _showSnackBar(
    String message,
    Color backgroundColor,
    Color textColor,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildEnhancedInfoChip(
    BuildContext context,
    IconData icon,
    String text,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ), // Reduced padding
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16), // Smaller border radius
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 3, // Reduced blur
            offset: const Offset(0, 1), // Reduced offset
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14, // Smaller icon
            color: accentColor,
          ),
          const SizedBox(width: 4), // Reduced spacing
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12, // Smaller font
                color: theme.colorScheme.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
