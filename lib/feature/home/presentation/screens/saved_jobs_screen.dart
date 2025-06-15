import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/home/presentation/widget/job_card.dart'; // Assuming JobCard is here

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        title: Text(
          'Saved Jobs',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: authProvider.state.user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 80,
                      color: theme.colorScheme.onBackground.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sign In to Save Jobs',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log in to your account to view and manage your saved job listings.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Optionally add a button to navigate to sign-in
                    // ElevatedButton(onPressed: () {}, child: Text('Sign In')),
                  ],
                ),
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: authProvider
                  .getSavedJobDataStream(), // Use the new stream
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.secondary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  print(
                    'Error fetching saved jobs: ${snapshot.error}',
                  ); // For debugging
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error Loading Saved Jobs',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onBackground,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Something went wrong while fetching your saved jobs. Please try again later.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(
                                0.7,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final List<Map<String, dynamic>> savedJobs =
                    snapshot.data ?? [];

                if (savedJobs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_add,
                            size: 80,
                            color: theme.colorScheme.onBackground.withOpacity(
                              0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Saved Jobs Yet!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onBackground,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bookmark jobs from the home screen to see them here.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(
                                0.7,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: savedJobs.length,
                  itemBuilder: (context, index) {
                    final job = savedJobs[index];
                    final jobId =
                        job['id'] as String?; // Ensure 'id' is extracted

                    if (jobId == null) {
                      // This should ideally not happen if data is consistently saved
                      return const SizedBox(); // Or a small error indicator
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: JobCard(job: job, jobId: jobId),
                    );
                  },
                );
              },
            ),
    );
  }
}
