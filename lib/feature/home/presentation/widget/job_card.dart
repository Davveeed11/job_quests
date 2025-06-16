import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/skills/presentation/screens/job_detail_screen.dart';
import 'dart:async';

class JobCard extends StatefulWidget {
  final Map<String, dynamic> job;
  final String? jobId;
  final Function(String, bool)? onBookmarkToggled;

  const JobCard({
    super.key,
    required this.job,
    this.jobId,
    this.onBookmarkToggled,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  late bool _isBookmarked;
  StreamSubscription? _bookmarkSubscription;

  @override
  void initState() {
    super.initState();
    _isBookmarked = false;
    _listenToBookmarkStatus();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        widget.job['difficultyRank'] ??
        widget.job['jobDifficultyRank'] ??
        'Not specified';

    return SizedBox(
      // *** ADDED: Explicitly set the width of each job card item ***
      width: 250, // You can adjust this width as needed for your design
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
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
            padding: const EdgeInsets.all(12.0),
            // *** REMOVED: The inner SizedBox that was here previously, as it's now redundant ***
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  // This is line 123
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary.withOpacity(
                        0.15,
                      ),
                      foregroundColor: theme.colorScheme.secondary,
                      radius: 24,
                      child: Text(
                        logoChar,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                jobTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                company,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (widget.jobId != null && authProvider.state.user != null)
                      IconButton(
                        icon: Icon(
                          _isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _isBookmarked
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () async {
                          if (authProvider.state.user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please log in to save jobs.'),
                              ),
                            );
                            return;
                          }
                          if (_isBookmarked) {
                            await authProvider.removeBookmark(widget.jobId!);
                          } else {
                            await authProvider.addBookmark(
                              widget.jobId!,
                              widget.job,
                            );
                          }
                          widget.onBookmarkToggled?.call(
                            widget.jobId!,
                            !_isBookmarked,
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildInfoChip(
                      context,
                      Icons.location_on,
                      location,
                      theme.colorScheme.onSurface.withOpacity(0.8),
                      theme.colorScheme.primary,
                    ),
                    _buildInfoChip(
                      context,
                      Icons.work_outline,
                      jobType,
                      theme.colorScheme.onSurface.withOpacity(0.8),
                      theme.colorScheme.secondary,
                    ),
                    _buildInfoChip(
                      context,
                      Icons.attach_money,
                      salary,
                      theme.colorScheme.onSurface.withOpacity(0.8),
                      theme.colorScheme.tertiary,
                    ),
                    _buildInfoChip(
                      context,
                      Icons.bar_chart,
                      'Difficulty: $difficultyRank',
                      theme.colorScheme.onSurface.withOpacity(0.8),
                      Colors.blueGrey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String text,
    Color textColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
