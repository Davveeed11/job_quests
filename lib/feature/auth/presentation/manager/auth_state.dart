import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  String email = '';
  String password = '';
  String name = '';
  String confirmPassword = '';
  String skillRank = '';
  bool hasSkillRank = false;
  bool profileLoaded = false;
  List<String> bookmarkedJobIds = []; // Stores IDs of bookmarked jobs
  String?
  currentDeviceId; // Stores the device ID for multi-device login management

  User? user;

  // Fields for Job Posting
  String jobTitle = '';
  String jobDescription = '';
  String jobDifficultyRank = '';
  String company = '';
  String location =
      ''; // This will be the raw string from input, converted to List<String> on post
  String salary = '';
  String jobType = '';
  String requiredSkills =
      ''; // For skills required by a job (input as comma-separated string)

  // Fields for User's Preferences (for recommendations)
  List<String> userSkills = []; // List of skills the user possesses
  List<String> preferredLocations = []; // User's preferred job locations
  List<String> preferredJobTypes = []; // User's preferred job types

  // For caching last fetched preferences for recommended jobs stream optimization
  String lastFetchedSkillRank = '';
  List<String> lastFetchedPreferredLocations = [];
  List<String> lastFetchedPreferredJobTypes = [];

  bool isLoading = false;
  String errorMessage = '';

  // Constructor for easier state initialization if needed, though often default is fine.
  AuthState({
    this.email = '',
    this.password = '',
    this.name = '',
    this.confirmPassword = '',
    this.skillRank = '',
    this.hasSkillRank = false,
    this.profileLoaded = false,
    this.bookmarkedJobIds = const [],
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
    this.userSkills = const [],
    this.preferredLocations = const [],
    this.preferredJobTypes = const [],
    this.lastFetchedSkillRank = '',
    this.lastFetchedPreferredLocations = const [],
    this.lastFetchedPreferredJobTypes = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });
}
