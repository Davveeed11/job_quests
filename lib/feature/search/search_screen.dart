import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/home/presentation/widget/job_card.dart';
import 'package:provider/provider.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // Holds the current search text
  List<Map<String, dynamic>> _allJobs = []; // Stores all fetched jobs
  List<Map<String, dynamic>> _filteredJobs =
      []; // Stores jobs filtered by search query
  late MyAuthProvider _authProvider; // Declare as late

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<MyAuthProvider>(context, listen: false);

    // Listen to the communityJobsStream to get all jobs
    _authProvider.communityJobsStream.listen((jobs) {
      setState(() {
        _allJobs = jobs; // Store all jobs
        _filterJobs(); // Filter jobs initially
      });
    });

    // Add listener to search controller for real-time filtering
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterJobs(); // Re-filter whenever search query changes
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Client-side filtering logic
  void _filterJobs() {
    if (_searchQuery.isEmpty) {
      _filteredJobs = _allJobs; // If no search query, show all jobs
    } else {
      _filteredJobs = _allJobs.where((job) {
        final jobTitle = job['jobTitle']?.toLowerCase() ?? '';
        final company = job['company']?.toLowerCase() ?? '';
        final jobDescription = job['jobDescription']?.toLowerCase() ?? '';
        final requiredSkills = job['requiredSkills']?.toLowerCase() ?? '';
        final location = job['location']?.toLowerCase() ?? '';

        return jobTitle.contains(_searchQuery) ||
            company.contains(_searchQuery) ||
            jobDescription.contains(_searchQuery) ||
            requiredSkills.contains(_searchQuery) ||
            location.contains(_searchQuery);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Jobs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, company, skills...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _filterJobs(); // Clear search and re-filter
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: Consumer<MyAuthProvider>(
        builder: (context, authProvider, child) {
          // Listen to bookmarked jobs stream to update bookmark status in UI
          return StreamBuilder<List<String>>(
            stream: authProvider.getSavedJobsStream(),
            builder: (context, snapshot) {
              // No longer directly used to pass to JobCard, as JobCard handles its own bookmark state.
              // Set<String> bookmarkedJobIds = snapshot.data?.toSet() ?? {};

              if (_allJobs.isEmpty && _searchQuery.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_filteredJobs.isEmpty && _searchQuery.isNotEmpty) {
                return Center(
                  child: Text(
                    'No jobs found for "${_searchController.text}"',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = _filteredJobs[index];
                  // Removed: final isBookmarked = bookmarkedJobIds.contains(job['id']); // JobCard manages its own bookmark state internally

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: JobCard(
                      job:
                          job, // Corrected: Passed 'job' (Map<String, dynamic>)
                      jobId:
                          job['id'], // Added: Passed the 'id' for JobCard's internal bookmark logic
                      onBookmarkToggled: (jobId, isBookmarkedStatus) {
                        // Corrected: Parameter name and signature
                        // This callback is triggered when the bookmark icon in JobCard is pressed.
                        // We handle the actual bookmark/unbookmark action here in SearchScreen.
                        if (isBookmarkedStatus) {
                          authProvider.addBookmark(jobId, job);
                        } else {
                          authProvider.removeBookmark(jobId);
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
