import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/home/presentation/widget/job_card.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Header/Title for Saved Jobs
          Padding(
            padding: const EdgeInsets.fromLTRB(
              24.0,
              48.0,
              24.0,
              16.0,
            ), // Increased top padding
            child: Text(
              'Your Saved Jobs',
              style: TextStyle(
                fontSize: 28, // Larger title
                fontWeight: FontWeight.bold,
                color: Theme.of(
                  context,
                ).colorScheme.primary, // Use primary color
              ),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search saved jobs...',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
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
                          // _searchQuery will be updated by listener
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      BorderSide.none, // No border needed with filled color
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surface, // Use theme surface color
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 20.0,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                // Add subtle shadow for depth
                isDense: true,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 16.0), // Spacing below search bar

          Expanded(
            child: StreamBuilder<List<String>>(
              stream: authProvider.bookmarkedJobIdsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading saved job IDs: ${snapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 80,
                            color: Theme.of(
                              context,
                            ).colorScheme.onBackground.withOpacity(0.4),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No saved jobs yet!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onBackground.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap the bookmark icon on any job to save it here.',
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

                final bookmarkedIds = snapshot.data!;
                return FutureBuilder<
                  List<QueryDocumentSnapshot<Map<String, dynamic>>>
                >(
                  future: authProvider.fetchJobsByIds(bookmarkedIds),
                  builder: (context, jobSnapshot) {
                    if (jobSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (jobSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error fetching saved jobs: ${jobSnapshot.error}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      );
                    }
                    if (!jobSnapshot.hasData || jobSnapshot.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No details found for your saved jobs. They might have been removed or unavailable.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onBackground.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    // Apply search filter
                    final allSavedJobs = jobSnapshot.data!;
                    final filteredJobs = allSavedJobs.where((jobDoc) {
                      final jobData = jobDoc.data();
                      final query = _searchQuery.toLowerCase();

                      // Check against job title, company, location, type, description
                      return (jobData['jobTitle']?.toLowerCase().contains(
                                query,
                              ) ??
                              false) ||
                          (jobData['company']?.toLowerCase().contains(query) ??
                              false) ||
                          (jobData['location']?.toLowerCase().contains(query) ??
                              false) ||
                          (jobData['jobType']?.toLowerCase().contains(query) ??
                              false) ||
                          (jobData['jobDescription']?.toLowerCase().contains(
                                query,
                              ) ??
                              false);
                    }).toList();

                    if (filteredJobs.isEmpty && _searchQuery.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sentiment_dissatisfied,
                                size: 60,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onBackground.withOpacity(0.4),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No results for "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onBackground.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Try a different search term or check your spelling.',
                                style: TextStyle(
                                  fontSize: 14,
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
                    } else if (filteredJobs.isEmpty) {
                      return const SizedBox.shrink(); // Should not happen here
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                      ), // Padding for job cards
                      itemCount: filteredJobs.length,
                      itemBuilder: (context, index) {
                        final jobDoc = filteredJobs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: JobCard(job: jobDoc.data(), jobId: jobDoc.id),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
