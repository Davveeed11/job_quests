import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  // ---------------------------------------------------------------------------
  // 1. Authentication & User Session State
  //    (Fields directly related to user login status and basic credentials)
  // ---------------------------------------------------------------------------
  String email = '';
  String password = '';
  String name = ''; // User's display name, often part of auth context
  String confirmPassword = ''; // For registration/password confirmation
  String? currentDeviceId; // Unique ID for the current device

  User? user; // The Firebase User object, representing the authenticated user

  // ---------------------------------------------------------------------------
  // 2. User Profile State
  //    (Detailed user information, separate from core authentication)
  // ---------------------------------------------------------------------------
  String skillRank = '';
  bool hasSkillRank = false; // Indicates if a skill rank has been set
  bool profileLoaded = false; // Status of whether the user profile has been fetched

  // User's General Skills (e.g., "Flutter", "Backend", "UI/UX")
  List<String> userSkills = [];
  // User's Preferred Job Locations
  List<String> preferredLocations = [];
  // User's Preferred Job Types (e.g., "Full-time", "Contract", "Remote")
  List<String> preferredJobTypes = [];

  // ---------------------------------------------------------------------------
  // 3. Job Posting Form State
  //    (Fields representing the data for a new job listing being created)
  // ---------------------------------------------------------------------------
  String jobTitle = '';
  String jobDescription = '';
  String jobDifficultyRank = ''; // E-SSS rank for the job being posted
  String company = '';
  String location = ''; // Location for the job posting
  String salary = '';
  String jobType = ''; // Type for the job posting
  String requiredSkills = ''; // Comma-separated string of skills for the job

  // ---------------------------------------------------------------------------
  // 4. Job Search/Recommendation Optimization State
  //    (Internal cache to optimize stream updates for job recommendations)
  // ---------------------------------------------------------------------------
  List<String> lastFetchedPreferredLocations = [];
  List<String> lastFetchedPreferredJobTypes = [];
  String lastFetchedSkillRank = '';

  // ---------------------------------------------------------------------------
  // 5. Bookmarking State
  //    (List of IDs for jobs bookmarked by the current user)
  // ---------------------------------------------------------------------------
  List<String> bookmarkedJobIds = [];

  // ---------------------------------------------------------------------------
  // 6. General UI/Operation State
  //    (Flags for loading indicators and error messages across various operations)
  // ---------------------------------------------------------------------------
  bool isLoading = false;
  String errorMessage = '';

  // ---------------------------------------------------------------------------
  // 7. Constructor and Initializer List
  //    (Initializes all fields, ensuring mutable lists are created properly)
  // ---------------------------------------------------------------------------
  AuthState({
    this.email = '',
    this.password = '',
    this.name = '',
    this.confirmPassword = '',
    this.skillRank = '',
    this.hasSkillRank = false,
    this.profileLoaded = false,
    List<String>? bookmarkedJobIds, // Make it nullable for safe initialization
    this.currentDeviceId,
    this.user,
    this.jobTitle = '',
    this.jobDescription = '',
    this.jobDifficultyRank = '',
    this.company = '',
    this.location = '',
    this.salary = '',
    this.jobType = '',
    this.requiredSkills = '',
    List<String>? userSkills, // Make it nullable for safe initialization
    List<String>? preferredLocations, // Make it nullable for safe initialization
    List<String>? preferredJobTypes, // Make it nullable for safe initialization
    List<String>? lastFetchedPreferredLocations, // Make it nullable
    List<String>? lastFetchedPreferredJobTypes, // Make it nullable
    this.lastFetchedSkillRank = '',
    this.isLoading = false,
    this.errorMessage = '',
  }) : // Initialize the lists in the initializer list to ensure mutability
  // If a list parameter is null, an empty mutable list is assigned.
        bookmarkedJobIds = bookmarkedJobIds ?? [],
        userSkills = userSkills ?? [],
        preferredLocations = preferredLocations ?? [],
        preferredJobTypes = preferredJobTypes ?? [],
        lastFetchedPreferredLocations = lastFetchedPreferredLocations ?? [],
        lastFetchedPreferredJobTypes = lastFetchedPreferredJobTypes ?? [];
}