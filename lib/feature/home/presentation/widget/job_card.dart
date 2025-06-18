import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/skills/presentation/screens/job_detail_screen.dart';
import 'dart:async'; // Required for StreamSubscription

class JobCard extends StatefulWidget {
  final Map<String, dynamic> job;
  final String? jobId;
  final Function(String, bool)?
  onBookmarkToggled; // Kept for potential external use, but not strictly needed for internal bookmark logic anymore

  const JobCard({
    super.key,
    required this.job,
    this.jobId,
    this.onBookmarkToggled,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> with SingleTickerProviderStateMixin {
  late bool _isBookmarked;
  StreamSubscription? _bookmarkSubscription;

  // For the scale animation when tapping the card
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isBookmarked = false; // Default state, will be updated by stream
    _listenToBookmarkStatus();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Quick animation
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut, // Smooth ease-out effect
      ),
    );
  }

  @override
  void didUpdateWidget(covariant JobCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the jobId changes (e.g., in a dynamic list where items are replaced),
    // cancel the old subscription and set up a new one for the new jobId.
    if (widget.jobId != oldWidget.jobId) {
      _bookmarkSubscription?.cancel();
      _listenToBookmarkStatus();
    }
  }

  // Listens to the auth provider's saved jobs stream to update bookmark status in real-time
  void _listenToBookmarkStatus() {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    if (authProvider.state.user != null && widget.jobId != null) {
      // It's crucial to cancel the previous subscription before creating a new one
      // to prevent memory leaks if this widget's ID changes or it's reused.
      _bookmarkSubscription
          ?.cancel(); // Ensure any existing subscription is cancelled

      _bookmarkSubscription = authProvider.getSavedJobsStream().listen((
        savedJobIds,
      ) {
        if (mounted) {
          // Only update state if the widget is still in the widget tree
          setState(() {
            _isBookmarked = savedJobIds.contains(widget.jobId);
          });
        }
      });
    } else {
      // If no user or no jobId, ensure the bookmark status is false
      if (mounted) {
        setState(() {
          _isBookmarked = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bookmarkSubscription?.cancel(); // Always cancel stream subscriptions
    _animationController.dispose(); // Always dispose animation controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We listen to the provider here to get the current user state for `authProvider.state.user`
    // but without rebuilding the entire JobCard if only other provider state changes.
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final theme = Theme.of(context);

    // Safely extract job details, providing fallback values and handling types
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

    // Use jobDifficultyRank from Firestore, fallback to difficultyRank, then 'N/A'
    final String difficultyRank =
        widget.job['jobDifficultyRank'] ??
        widget.job['difficultyRank'] ??
        'N/A';

    return Center(
      // Center the card on wider screens, allowing it to take less than full width if needed
      child: ConstrainedBox(
        // Allows it to be responsive, but sets max/min width
        constraints: const BoxConstraints(
          maxWidth:
              360, // Maximum width for the card (e.g., on tablets/desktops)
          minWidth:
              280, // Minimum width, prevents it from getting too small on tiny screens
        ),
        child: ScaleTransition(
          // Apply scale animation here
          scale: _scaleAnimation,
          child: Card(
            elevation: 10, // Increased elevation for a more pronounced shadow
            shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                22,
              ), // Even more rounded corners
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(
                  0.1,
                ), // Very subtle border
                width: 0.5,
              ),
            ),
            margin: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 10,
            ), // Ensures some padding from edges
            clipBehavior:
                Clip.antiAlias, // Ensures content is clipped to rounded corners
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              // Animation callbacks for press down/up
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        JobDetailScreen(job: widget.job, jobId: widget.jobId),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Slightly reduced padding
                child: Column(
                  mainAxisSize: MainAxisSize
                      .min, // Column should shrink-wrap its content vertically
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      // This is the problematic row, line ~123
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer
                              .withOpacity(0.7),
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          radius: 28, // Slightly smaller avatar
                          child: Text(
                            logoChar,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ), // Slightly smaller font for logo
                          ),
                        ),
                        const SizedBox(width: 14), // Slightly reduced spacing
                        Expanded(
                          // This is the flexible child
                          child: LayoutBuilder(
                            // REQUIRED: Constrain the inner Column for Text widgets
                            builder: (context, constraints) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    jobTitle,
                                    style: TextStyle(
                                      fontSize:
                                          19, // Slightly smaller job title
                                      fontWeight: FontWeight.w800, // Extra bold
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ), // Slightly reduced spacing
                                  Text(
                                    company,
                                    style: TextStyle(
                                      fontSize:
                                          14, // Slightly smaller company name
                                      color: theme
                                          .colorScheme
                                          .onSurfaceVariant, // More muted color
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        // Bookmark Icon - ensure user is logged in
                        if (widget.jobId != null &&
                            authProvider.state.user != null)
                          Align(
                            // Use Align to position the icon if needed, though IconButton is usually fine
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: Icon(
                                _isBookmarked
                                    ? Icons.bookmark_sharp
                                    : Icons.bookmark_border_sharp,
                                size: 26, // Slightly smaller icon
                              ),
                              color: _isBookmarked
                                  ? theme
                                        .colorScheme
                                        .tertiary // A distinct accent color for bookmark
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ), // Lighter grey when not bookmarked
                              onPressed: () async {
                                // Direct calls to add/remove bookmark
                                if (authProvider.state.user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please log in to save jobs.',
                                        style: TextStyle(
                                          color: theme.colorScheme.onError,
                                        ),
                                      ),
                                      backgroundColor: theme.colorScheme.error,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                if (_isBookmarked) {
                                  await authProvider.removeBookmark(
                                    widget.jobId!,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Job unsaved.',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSecondary,
                                        ),
                                      ),
                                      backgroundColor:
                                          theme.colorScheme.secondary,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                } else {
                                  await authProvider.addBookmark(
                                    widget.jobId!,
                                    widget.job,
                                  ); // Pass the full job data
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Job saved!',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSecondary,
                                        ),
                                      ),
                                      backgroundColor:
                                          theme.colorScheme.secondary,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                                // The _listenToBookmarkStatus stream will automatically update _isBookmarked state.
                                // If the parent needs to know, call the callback:
                                widget.onBookmarkToggled?.call(
                                  widget.jobId!,
                                  !_isBookmarked,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20), // Increased vertical spacing

                    Wrap(
                      spacing:
                          8.0, // Slightly reduced horizontal spacing for chips
                      runSpacing:
                          8.0, // Slightly reduced vertical spacing for chips
                      children: [
                        _buildInfoChip(
                          context,
                          Icons
                              .location_on_rounded, // Rounded icon for consistency
                          location,
                          theme.colorScheme.onSurface,
                          theme.colorScheme.secondary,
                        ),
                        _buildInfoChip(
                          context,
                          Icons.work_rounded, // Rounded icon
                          jobType,
                          theme.colorScheme.onSurface,
                          theme.colorScheme.primary,
                        ),
                        _buildInfoChip(
                          context,
                          Icons.attach_money_rounded, // Rounded icon
                          salary,
                          theme.colorScheme.onSurface,
                          theme.colorScheme.tertiary,
                        ),
                        _buildInfoChip(
                          context,
                          Icons.bar_chart_rounded, // Rounded icon
                          'Difficulty: $difficultyRank',
                          theme.colorScheme.onSurface,
                          theme
                              .colorScheme
                              .error, // Stronger color for difficulty
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create info chips
  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String text,
    Color textColor,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ), // Smaller padding for chips
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(
          0.35,
        ), // Lighter background for chips
        borderRadius: BorderRadius.circular(
          16,
        ), // Slightly less rounded for smaller size
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min, // Ensure chips only take up needed space
        children: [
          Icon(
            icon,
            size: 18,
            color: iconColor,
          ), // Slightly smaller icon in chip
          const SizedBox(width: 6), // Slightly reduced spacing
          Flexible(
            // Crucial for preventing overflow in chips if text is long
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5, // Slightly smaller font for chips
                color: textColor.withOpacity(0.9), // Slightly muted text color
                fontWeight: FontWeight.w600, // Semi-bold
              ),
              overflow: TextOverflow.ellipsis, // Truncate text if it's too long
              maxLines: 1, // Ensure it's a single line
            ),
          ),
        ],
      ),
    );
  }
}
