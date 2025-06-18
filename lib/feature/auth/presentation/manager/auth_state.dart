import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  String email = '';
  String password = '';
  String name = '';
  String confirmPassword = '';
  String skillRank = '';
  bool hasSkillRank = false;
  bool profileLoaded = false;
  // These are already initialized as mutable empty lists at the field level
  List<String> bookmarkedJobIds = [];
  String? currentDeviceId;

  User? user;

  // Fields for Job Posting
  String jobTitle = '';
  String jobDescription = '';
  String jobDifficultyRank = '';
  String company = '';
  String location = '';
  String salary = '';
  String jobType = '';
  String requiredSkills = '';

  // Fields for User's Preferences (for recommendations)
  List<String> userSkills = [];
  List<String> preferredLocations = [];
  List<String> preferredJobTypes = [];

  // For caching last fetched preferences for recommended jobs stream optimization
  List<String> lastFetchedPreferredLocations = [];
  List<String> lastFetchedPreferredJobTypes = [];
  String lastFetchedSkillRank = '';

  bool isLoading = false;
  String errorMessage = '';

  AuthState({
    this.email = '',
    this.password = '',
    this.name = '',
    this.confirmPassword = '',
    this.skillRank = '',
    this.hasSkillRank = false,
    this.profileLoaded = false,
    // FIX THESE: Remove `const` or ensure a new mutable list is used
    // Best practice is to use a nullable parameter, and then initialize in the initializer list.
    List<String>? bookmarkedJobIds, // Make it nullable
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
    List<String>? userSkills, // Make it nullable
    List<String>? preferredLocations, // Make it nullable
    List<String>? preferredJobTypes, // Make it nullable
    List<String>? lastFetchedPreferredLocations, // Make it nullable
    List<String>? lastFetchedPreferredJobTypes, // Make it nullable
    this.lastFetchedSkillRank = '',
    this.isLoading = false,
    this.errorMessage = '',
  }) : // Initialize the lists in the initializer list to ensure mutability
       bookmarkedJobIds = bookmarkedJobIds ?? [],
       userSkills = userSkills ?? [],
       preferredLocations = preferredLocations ?? [],
       preferredJobTypes = preferredJobTypes ?? [],
       lastFetchedPreferredLocations = lastFetchedPreferredLocations ?? [],
       lastFetchedPreferredJobTypes = lastFetchedPreferredJobTypes ?? [];
}
