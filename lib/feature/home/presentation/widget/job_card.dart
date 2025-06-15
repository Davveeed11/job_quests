import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/skills/presentation/screens/job_detail_screen.dart'; // Ensure this path is correct
import 'package:provider/provider.dart';

/// Helper Widget for Job Cards (for recommended jobs and community jobs)
class JobCard extends StatefulWidget {
  final Map<String, dynamic> job;
  final String?
  jobId; // Pass jobId for potential bookmarking from detail screen

  const JobCard({super.key, required this.job, this.jobId});

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.95;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
    // Navigate to JobDetailScreen on tap
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(
          job: widget.job, // Pass the entire job map
          jobId: widget.jobId, // Pass the jobId
        ),
      ),
    );
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);

    // Prioritize widget.jobId if provided, otherwise use 'id' from job map, then 'jobId'
    final String? currentJobId =
        widget.jobId ?? widget.job['id'] ?? widget.job['jobId'];

    // Check if bookmarked ONLY if currentJobId is not null
    final bool isBookmarked =
        currentJobId != null &&
        authProvider.state.bookmarkedJobIds.contains(currentJobId);

    // Use null-aware operators or default values for job properties from the job map
    final String jobTitle =
        widget.job['jobTitle'] ??
        widget.job['title'] ??
        'Job Title Not Provided';
    final String company =
        widget.job['company'] ??
        widget.job['posterName'] ??
        'Community Post'; // Use posterName as fallback

    // FIX: Handle location as List<dynamic> or String
    final dynamic rawLocation = widget.job['location'];
    final String location;
    if (rawLocation is List) {
      location = rawLocation
          .map((e) => e.toString())
          .join(', '); // Join list elements
    } else {
      location =
          rawLocation as String? ?? 'Anywhere'; // Fallback to String or default
    }

    final String salary = widget.job['salary'] ?? 'Negotiable';
    final String jobType =
        widget.job['jobType'] ?? widget.job['type'] ?? 'Full-time';
    final String logoChar =
        widget.job['logoChar'] ??
        (company.isNotEmpty
            ? company[0].toUpperCase()
            : '?'); // Use company first letter

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: 220.0, // Fixed height for consistency in horizontal list
          margin: const EdgeInsets.only(right: 16.0),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Theme.of(
              context,
            ).colorScheme.surface, // Use theme surface color
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.15),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        radius: 18,
                        child: Text(
                          logoChar,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          company,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface
                                .withOpacity(0.7), // Use onSurface
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Tooltip(
                        message: isBookmarked ? 'Unsave Job' : 'Save Job',
                        child: IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isBookmarked
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                            size: 22,
                          ),
                          onPressed: () {
                            if (currentJobId != null) {
                              // Only allow bookmarking if we have a valid ID
                              if (isBookmarked) {
                                authProvider.removeBookmark(currentJobId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Unsaved "$jobTitle"'),
                                  ),
                                );
                              } else {
                                authProvider.addBookmark(currentJobId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Saved "$jobTitle"')),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cannot bookmark this job (ID missing).',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    jobTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface, // Use onSurface
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ), // Use onSurface
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ), // Use onSurface
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.work_outline,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ), // Use onSurface
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          jobType,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ), // Use onSurface
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        salary,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      // The "Apply Now" button is removed from JobCard as it's now on JobDetailScreen.
                      // This space can be adjusted or removed if no other content is needed here.
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
