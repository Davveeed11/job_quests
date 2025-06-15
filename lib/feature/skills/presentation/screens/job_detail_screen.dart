import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  final String?
  jobId; // Pass jobId for potential bookmarking from detail screen

  const JobDetailScreen({super.key, required this.job, this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  // Local state to track bookmark status, updated by stream listener
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _listenToBookmarkStatus();
  }

  // Listens to the auth provider's saved jobs stream to update bookmark status
  void _listenToBookmarkStatus() {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    if (authProvider.state.user != null && widget.jobId != null) {
      authProvider.getSavedJobsStream().listen((savedJobIds) {
        if (mounted) {
          setState(() {
            _isBookmarked = savedJobIds.contains(widget.jobId);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);

    // Safely extract job details, providing fallback values and handling types
    final String jobTitle =
        widget.job['jobTitle'] ??
        widget.job['title'] ??
        'Job Title Not Provided';
    final String company =
        widget.job['company'] ?? widget.job['posterName'] ?? 'Company Unknown';

    // Handle 'location' which might be String or List<dynamic>
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
    final String jobDescription =
        widget.job['jobDescription'] ?? 'No description provided.';
    final String logoChar =
        widget.job['logoChar'] ??
        (company.isNotEmpty ? company[0].toUpperCase() : '?');
    final String difficultyRank =
        widget.job['difficultyRank'] ??
        'Not specified'; // Added difficulty rank

    // Handle 'requiredSkills' which might be String or List<dynamic>
    final dynamic rawRequiredSkills = widget.job['requiredSkills'];
    final List<String> requiredSkills;
    if (rawRequiredSkills is List) {
      requiredSkills = rawRequiredSkills.map((e) => e.toString()).toList();
    } else if (rawRequiredSkills is String && rawRequiredSkills.isNotEmpty) {
      requiredSkills = rawRequiredSkills
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      requiredSkills = [];
    }

    // For bookmarking, prioritize widget.jobId, then 'id', then 'jobId' from map
    final String? currentJobId =
        widget.jobId ?? widget.job['id'] ?? widget.job['jobId'];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        title: Text(
          jobTitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (currentJobId != null)
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked
                    ? Theme.of(context)
                          .colorScheme
                          .onPrimary // Bookmarked color
                    : Colors.white70, // Unbookmarked color
              ),
              tooltip: _isBookmarked ? 'Unsave Job' : 'Save Job',
              onPressed: () async {
                if (_isBookmarked) {
                  await authProvider.removeBookmark(currentJobId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unsaved "$jobTitle"')),
                  );
                } else {
                  await authProvider.addBookmark(
                    currentJobId,
                    widget.job,
                  ); // Pass the full job data
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Saved "$jobTitle"')));
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company and Title
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.15),
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                  radius: 28, // Slightly larger avatar
                  child: Text(
                    logoChar,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Job Metadata (Location, Type, Salary, Difficulty Rank)
            Wrap(
              spacing: 12.0, // Reduced spacing
              runSpacing: 10.0,
              children: [
                _buildInfoChip(context, Icons.location_on, location),
                _buildInfoChip(context, Icons.work_outline, jobType),
                _buildInfoChip(context, Icons.attach_money, salary),
                _buildInfoChip(
                  context,
                  Icons.bar_chart,
                  'Difficulty: $difficultyRank',
                ), // Difficulty Rank chip
              ],
            ),
            const SizedBox(height: 32),

            // Required Skills Section (NEW)
            if (requiredSkills.isNotEmpty) ...[
              Text(
                'Required Skills',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: requiredSkills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),
            ],

            // Job Description Header
            Text(
              'Job Description',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            // Job Description Content
            Text(
              jobDescription,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Application submitted! Employer will contact you.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            elevation: 8,
          ),
          child: const Text('Apply Now'),
        ),
      ),
    );
  }

  // Helper method to create info chips
  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface, // Use surface color for chips
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Wrap content tightly
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            // Use Flexible to prevent overflow if text is too long
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis, // Add ellipsis for long text
            ),
          ),
        ],
      ),
    );
  }
}
