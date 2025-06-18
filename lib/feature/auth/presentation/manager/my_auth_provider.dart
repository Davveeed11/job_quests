import 'dart:async';
import 'dart:io';
import 'dart:math'; // Import 'dart:math' for clamp()

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_job_quest/feature/auth/data/auth_repo_impl.dart';
// NOTE: Assuming this path is correct for your AuthState class.
// Typically, state classes are in 'presentation/state/' folder.
import 'package:my_job_quest/feature/auth/presentation/manager/auth_state.dart';

class MyAuthProvider extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // 1. Dependencies & Initialization
  // ---------------------------------------------------------------------------

  final AuthRepoImpl _authRepo = AuthRepoImpl();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthState _state = AuthState();
  AuthState get state => _state;

  // ---------------------------------------------------------------------------
  // 2. Skill Rank Definition & Helper Methods
  //    (Used for job recommendations)
  // ---------------------------------------------------------------------------

  // Define the order of skill/difficulty ranks for comparison
  // Lower index means higher/harder rank
  static const List<String> _rankOrder = [
    'SSS',
    'SS',
    'S',
    'A',
    'B',
    'C',
    'D',
    'E',
  ];

  // Helper function to calculate acceptable job difficulty ranks based on user's skill rank.
  // It determines a range (1 rank above to 2 ranks below) from the user's skill.
  List<String> _getAcceptableDifficultyRanks(String userSkillRank) {
    // Find the index of the user's primary rank (e.g., 'A' from 'A Rank')
    final int userRankIndex = _rankOrder.indexOf(userSkillRank.split(' ')[0]);

    // If the user's rank isn't in our list, we can't recommend anything.
    if (userRankIndex == -1) {
      return [];
    }

    // Define the range: 1 rank above to 2 ranks below the user's rank.
    // clamp() ensures the index stays within valid bounds of _rankOrder.
    final int startIndex = (userRankIndex - 1).clamp(0, _rankOrder.length - 1);
    final int endIndex = (userRankIndex + 3).clamp(
      0,
      _rankOrder.length,
    ); // +3 because sublist's end is exclusive

    // Create the list of acceptable ranks from the calculated range.
    final List<String> acceptableRanks = _rankOrder.sublist(
      startIndex,
      endIndex,
    );

    return acceptableRanks;
  }

  // ---------------------------------------------------------------------------
  // 3. Job Listing Streams
  //    (Provide data for community jobs and recommended jobs)
  // ---------------------------------------------------------------------------

  // Stream for ALL job postings, returning QueryDocumentSnapshot to include doc.id.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  get allJobsDocsStream {
    return _firestore
        .collection('jobs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Helper stream to map QueryDocumentSnapshot to Map<String, dynamic> for easier consumption.
  // This stream prepares data for HomeScreen's Community Jobs section.
  Stream<List<Map<String, dynamic>>> get communityJobsStream {
    return allJobsDocsStream.map((docs) {
      return docs.map((doc) {
        final data = doc.data();
        final Map<String, dynamic> processedData = {
          'id': doc.id,
          'jobId': doc.id, // Ensure jobId is always available
          ...data,
          'company':
          data['company'] ??
              (data['posterName'] ?? 'Community Post').toString(),
          'logoChar': (data['company'] as String?)?.isNotEmpty == true
              ? (data['company'] as String)[0].toUpperCase()
              : (data['posterName'] as String?)?.isNotEmpty == true
              ? (data['posterName'] as String)[0].toUpperCase()
              : '?',
          'jobTitle': data['jobTitle'] ?? 'No Title',
          'location': (data['location'] is List)
              ? (data['location'] as List).map((e) => e.toString()).join(', ')
              : data['location'] as String? ?? 'Remote',
          'salary': data['salary'] ?? 'Negotiable',
          'jobType': data['jobType'] ?? 'Full-time',
          'difficultyRank':
          data['jobDifficultyRank'] ??
              'Not specified', // Ensuring this key is set
          'jobDescription': data['jobDescription'] ?? '',
          'requiredSkills': (data['requiredSkills'] is List)
              ? (data['requiredSkills'] as List)
              .map((e) => e.toString())
              .join(', ')
              : data['requiredSkills'] as String? ?? '',
        };
        return processedData;
      }).toList();
    });
  }

  // REVISED: Stream for Recommended Jobs.
  // It now depends ONLY on the user's skill rank, filtering out location and job type preferences.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  get recommendedJobsStream {
    // --- START DEBUGGING ---
    print('--- Checking recommendedJobsStream ---');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_state.profileLoaded || _state.skillRank.isEmpty) {
      print('DEBUG: Stream cancelled. Reason:');
      if (user == null) print('-> User is not logged in.');
      if (!_state.profileLoaded) print('-> User profile is not loaded yet.');
      if (_state.skillRank.isEmpty) print('-> User skill rank is empty.');
      print('------------------------------------');
      return Stream.value([]); // Return an empty stream if conditions not met
    }

    print('DEBUG: User is logged in and profile is loaded.');
    print('DEBUG: User Skill Rank: "${_state.skillRank}"');
    // Debug info for preferred locations/job types are kept for context,
    // but they are no longer used for filtering in this stream.
    print('DEBUG: User Preferred Locations: ${_state.preferredLocations}');
    print('DEBUG: User Preferred Job Types: ${_state.preferredJobTypes}');

    final acceptableDifficultyRanks = _getAcceptableDifficultyRanks(
      _state.skillRank,
    );

    print('DEBUG: Calculated acceptable job ranks: $acceptableDifficultyRanks');

    if (acceptableDifficultyRanks.isEmpty) {
      print(
        'DEBUG: Stream cancelled. No acceptable job ranks could be calculated.',
      );
      print('------------------------------------');
      return Stream.value([]); // Return an empty stream if no ranks
    }

    print('DEBUG: Querying Firestore for jobs with those ranks...');

    return _firestore
        .collection('jobs')
        .where('jobDifficultyRank', whereIn: acceptableDifficultyRanks)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      print(
        'DEBUG: Firestore returned ${snapshot.docs.length} documents matching the rank criteria.',
      );

      List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('---');
        print(
          'DEBUG: Evaluating Job ID: ${doc.id} | Title: ${data['jobTitle']}',
        );

        // The following lines related to job locations and job types
        // are kept for data processing if needed elsewhere, but their
        // filtering logic below is removed as per user request.
        final List<String> jobLocations = (data['location'] is List)
            ? List<String>.from(data['location'])
            : [data['location']?.toString() ?? ''];
        final String jobType = data['jobType'] as String? ?? '';

        print('DEBUG: Job Locations: $jobLocations | Job Type: "$jobType"');

        // --- REVISION START ---
        // As per user request, remove dependency on location and job type.
        // All jobs returned by the Firestore query (filtered by rank)
        // will now be included in the recommended list.
        bool locationMatches = true; // Always true
        bool jobTypeMatches = true; // Always true

        print(
          'DEBUG: Location Match? $locationMatches (Bypassed) | Job Type Match? $jobTypeMatches (Bypassed)',
        );

        // The condition now effectively always adds the document if it passed the Firestore rank filter.
        if (locationMatches && jobTypeMatches) {
          print('DEBUG: -> SUCCESS: Job added to recommendations (Location/Job Type filters bypassed).');
          filteredDocs.add(doc);
        } else {
          // This else block will effectively never be reached with the current logic
          print('DEBUG: -> FAIL: Job filtered out (should not happen with bypassed filters).');
        }
        // --- REVISION END ---
      }
      print('---');
      print(
        'DEBUG: Final recommendation count for this update: ${filteredDocs.length}',
      );
      print('------------------------------------');
      return filteredDocs;
    });
  }

  // ---------------------------------------------------------------------------
  // 4. Saved Jobs (Bookmarks) Streams
  //    (Provide bookmarked job IDs and their full data)
  // ---------------------------------------------------------------------------

  // Stream that fetches only the IDs of jobs bookmarked by the current user.
  Stream<List<String>> getSavedJobsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]); // Return empty list if no user
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bookmarked_jobs')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Stream that fetches the actual job data for saved jobs based on their IDs.
  Stream<List<Map<String, dynamic>>> getSavedJobDataStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]); // Return empty list if no user
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bookmarked_jobs')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final Map<String, dynamic> processedData = {
          'id': doc.id,
          'jobId': doc.id,
          ...data,
          'company':
          data['company'] ??
              (data['posterName'] ?? 'Community Post').toString(),
          'logoChar': (data['company'] as String?)?.isNotEmpty == true
              ? (data['company'] as String)[0].toUpperCase()
              : (data['posterName'] as String?)?.isNotEmpty == true
              ? (data['posterName'] as String)[0].toUpperCase()
              : '?',
          'jobTitle': data['jobTitle'] ?? 'No Title',
          'location': (data['location'] is List)
              ? (data['location'] as List)
              .map((e) => e.toString())
              .join(', ')
              : data['location'] as String? ?? 'Remote',
          'salary': data['salary'] ?? 'Negotiable',
          'jobType': data['jobType'] ?? 'Full-time',
          'difficultyRank':
          data['difficultyRank'] ??
              data['jobDifficultyRank'] ??
              'Not specified',
          'jobDescription': data['jobDescription'] ?? '',
          'requiredSkills': (data['requiredSkills'] is List)
              ? (data['requiredSkills'] as List)
              .map((e) => e.toString())
              .join(', ')
              : data['requiredSkills'] as String? ?? '',
        };
        return processedData;
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // 5. Device ID Management
  //    (Retrieves and stores a unique device ID)
  // ---------------------------------------------------------------------------

  // Fetches a unique device ID and stores it securely.
  // It also updates the 'currentDeviceId' in the AuthState.
  Future<String?> _getDeviceId() async {
    String? deviceId = await _secureStorage.read(key: 'device_id');
    if (deviceId == null) {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      try {
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
          deviceId = iosInfo.identifierForVendor;
        } else {
          // Fallback for web or other platforms if specific device info not available
          deviceId = 'web_device_${DateTime.now().microsecondsSinceEpoch}';
        }
        if (deviceId != null) {
          await _secureStorage.write(key: 'device_id', value: deviceId);
        }
      } catch (e) {
        // Handle potential errors if device info is not available
        print("Failed to get device ID: $e");
        deviceId = 'fallback_device_${DateTime.now().microsecondsSinceEpoch}';
        await _secureStorage.write(key: 'device_id', value: deviceId);
      }
    }
    _state.currentDeviceId = deviceId; // Update state directly
    return deviceId;
  }

  // ---------------------------------------------------------------------------
  // 6. Core Authentication Methods
  //    (Sign-in, Sign-up, Sign-out, Device Login Management)
  // ---------------------------------------------------------------------------

  // Handles user sign-in with email and password, including device ID validation.
  Future<void> signIn() async {
    _state.isLoading = true;
    _state.errorMessage = '';
    notifyListeners();

    try {
      final currentDeviceId = await _getDeviceId();
      if (currentDeviceId == null) {
        _state.errorMessage = 'Could not retrieve device ID. Please try again.';
        _state.isLoading = false;
        notifyListeners();
        return;
      }

      UserCredential userCredential = await _authRepo.signIn(
        _state.email,
        _state.password,
      );
      _state.user = userCredential.user;

      if (_state.user != null) {
        final userDocRef = _firestore.collection('users').doc(_state.user!.uid);
        DocumentSnapshot userDoc = await userDocRef.get();

        if (userDoc.exists) {
          final storedDeviceId = userDoc.data() as Map<String, dynamic>?;
          final existingDeviceId = storedDeviceId?['device_id'] as String?;

          // Check if user is already logged in on another device
          if (existingDeviceId != null && existingDeviceId != currentDeviceId) {
            _state.isLoading = false;
            notifyListeners();
            _state.errorMessage =
            'You are already logged in on another device. Sign in here to log out the other device.';
            print(
              'MyAuthProvider: Login attempt from different device. Existing: $existingDeviceId, Current: $currentDeviceId',
            );
            return; // Exit here, user needs to decide to force login
          } else {
            // Update or set device ID for this user
            await userDocRef.set({
              'device_id': currentDeviceId,
            }, SetOptions(merge: true));
            print(
              'MyAuthProvider: Device ID updated/set for user: $currentDeviceId',
            );
          }
        } else {
          // New user document (should ideally be created during sign-up)
          await userDocRef.set({
            'device_id': currentDeviceId,
            'email': _state.email,
            'name': _state.name,
            'skillRank': '',
            'hasSkillRank': false,
            'userSkills': [],
            'preferredLocations': [],
            'preferredJobTypes': [],
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print(
            'MyAuthProvider: New user document created with device ID: $currentDeviceId',
          );
        }
      }

      _state.isLoading = false;
      _state.errorMessage = '';
      notifyListeners();
      await loadUserProfile(); // Load user profile data after successful login
    } on FirebaseAuthException catch (e) {
      String message = 'An unknown error occurred.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials. Please check your email and password.';
      }
      _state.errorMessage = message;
      _state.isLoading = false;
      notifyListeners();
    } catch (e) {
      _state.errorMessage = e.toString();
      _state.isLoading = false;
      notifyListeners();
    }
  }

  // Forces sign-in on a new device, overriding any existing device login.
  Future<void> forceSignInNewDevice() async {
    _state.isLoading = true;
    _state.errorMessage = '';
    notifyListeners();

    try {
      final currentDeviceId = await _getDeviceId();
      if (currentDeviceId == null || _state.user == null) {
        _state.errorMessage =
        'Error retrieving device ID or user not authenticated.';
        _state.isLoading = false;
        notifyListeners();
        return;
      }

      final userDocRef = _firestore.collection('users').doc(_state.user!.uid);
      await userDocRef.set({
        'device_id': currentDeviceId, // Overwrite existing device ID
      }, SetOptions(merge: true));
      print(
        'MyAuthProvider: Force sign-in: Device ID updated to $currentDeviceId.',
      );

      _state.isLoading = false;
      _state.errorMessage = '';
      notifyListeners();
      await loadUserProfile(); // Reload user profile after force sign-in
    } catch (e) {
      _state.errorMessage = 'Failed to sign in on new device: $e';
      _state.isLoading = false;
      notifyListeners();
    }
  }

  // Handles user registration with email and password.
  Future<void> signUp() async {
    _state.isLoading = true;
    _state.errorMessage = '';
    notifyListeners();

    if (_state.password != _state.confirmPassword) {
      _state.errorMessage = 'Passwords do not match.';
      _state.isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final currentDeviceId = await _getDeviceId();
      if (currentDeviceId == null) {
        _state.errorMessage = 'Could not retrieve device ID. Please try again.';
        _state.isLoading = false;
        notifyListeners();
        return;
      }

      UserCredential userCredential = await _authRepo.signUp(
        _state.email,
        _state.password,
        _state.name,
      );

      _state.user = userCredential.user;
      _state.isLoading = false;
      _state.errorMessage = '';
      notifyListeners();

      if (userCredential.user != null) {
        // Create user document in Firestore upon successful registration
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': _state.name,
          'skillRank': '', // Initialize profile fields
          'hasSkillRank': false,
          'userSkills': [],
          'preferredLocations': [],
          'preferredJobTypes': [],
          'device_id': currentDeviceId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await loadUserProfile(); // Load the newly created profile
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An unknown error occurred during sign up.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      _state.errorMessage = message;
      _state.isLoading = false;
      notifyListeners();
    } catch (e) {
      _state.errorMessage = e.toString();
      _state.isLoading = false;
      notifyListeners();
    }
  }

  // Handles user sign-out and clears device ID information.
  Future<void> signout() async {
    _state.isLoading = true;
    _state.errorMessage = '';
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Clear device ID from Firestore when user signs out
        await _firestore.collection('users').doc(user.uid).update({
          'device_id': FieldValue.delete(),
        });
        print(
          'MyAuthProvider: Device ID cleared from Firestore for user: ${user.uid}',
        );
      }

      await _authRepo.signOut();
      // Reset AuthState to initial values after sign out
      _state = AuthState();
      await _secureStorage.delete(key: 'device_id'); // Clear local device ID
      _state.profileLoaded = true; // Indicate that profile state is now 'empty' but loaded
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to sign out. Please try again.';
      _state.errorMessage = message;
      _state.isLoading = false;
      notifyListeners();
    } catch (e) {
      _state.errorMessage = e.toString();
      _state.isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 7. User Profile Management Methods
  //    (Load user profile data and save user preferences)
  // ---------------------------------------------------------------------------

  // Loads the current user's profile data from Firestore, including bookmarked jobs.
  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If no user, reset state to default, representing logged-out state
      _state.user = null;
      _state.hasSkillRank = false;
      _state.profileLoaded = true; // Indicate that the "empty" profile is loaded
      _state.errorMessage = '';
      _state.currentDeviceId = await _getDeviceId(); // Still get device ID even if logged out
      _state.bookmarkedJobIds.clear();
      _state.userSkills.clear();
      _state.preferredLocations.clear();
      _state.preferredJobTypes.clear();
      _state.lastFetchedSkillRank = '';
      _state.lastFetchedPreferredLocations = [];
      _state.lastFetchedPreferredJobTypes = [];
      notifyListeners();
      return;
    }

    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      // Fetch bookmarked job IDs
      List<String> fetchedBookmarkedJobIds = [];
      try {
        final bookmarkSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('bookmarked_jobs')
            .get();
        fetchedBookmarkedJobIds = bookmarkSnapshot.docs
            .map((doc) => doc.id)
            .toList();
        print(
          'MyAuthProvider: Fetched ${fetchedBookmarkedJobIds.length} bookmarked jobs.',
        );
      } catch (e) {
        print('MyAuthProvider: Error fetching bookmarked job IDs: $e');
      }

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        String fetchedSkillRank = data['skillRank'] as String? ?? '';
        bool hasRank = fetchedSkillRank.isNotEmpty;
        List<String> fetchedUserSkills = List<String>.from(
          data['userSkills'] ?? [],
        );
        List<String> fetchedPreferredLocations =
            (data['preferredLocations'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
                [];
        List<String> fetchedPreferredJobTypes =
            (data['preferredJobTypes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
                [];

        // Update AuthState with fetched profile data
        _state.user = user;
        _state.name = data['name'] as String? ?? user.displayName ?? '';
        _state.email = data['email'] as String? ?? user.email ?? '';
        _state.skillRank = fetchedSkillRank;
        _state.hasSkillRank = hasRank;
        _state.profileLoaded = true;
        _state.errorMessage = '';
        _state.currentDeviceId = await _getDeviceId();
        _state.bookmarkedJobIds = fetchedBookmarkedJobIds;
        _state.userSkills = fetchedUserSkills;
        _state.preferredLocations = fetchedPreferredLocations;
        _state.preferredJobTypes = fetchedPreferredJobTypes;

        // Update last fetched values for optimization
        _state.lastFetchedSkillRank = fetchedSkillRank;
        _state.lastFetchedPreferredLocations = List.from(
          fetchedPreferredLocations,
        );
        _state.lastFetchedPreferredJobTypes = List.from(
          fetchedPreferredJobTypes,
        );

        print(
          'MyAuthProvider: Profile loaded. SkillRank: $fetchedSkillRank, HasRank: $hasRank, DeviceID: ${_state.currentDeviceId}, Bookmarks: ${_state.bookmarkedJobIds.length}, UserSkills: ${_state.userSkills.length}, Preferred Locations: ${_state.preferredLocations}, Preferred Job Types: ${_state.preferredJobTypes}',
        );
      } else {
        // If user document doesn't exist, initialize with default values
        _state.user = user;
        _state.name = user.displayName ?? '';
        _state.email = user.email ?? '';
        _state.skillRank = '';
        _state.hasSkillRank = false;
        _state.profileLoaded = true;
        _state.errorMessage = '';
        _state.currentDeviceId = await _getDeviceId();
        _state.bookmarkedJobIds = fetchedBookmarkedJobIds; // Still load bookmarks if any
        _state.userSkills = [];
        _state.preferredLocations = [];
        _state.preferredJobTypes = [];
        _state.lastFetchedSkillRank = '';
        _state.lastFetchedPreferredLocations = [];
        _state.lastFetchedPreferredJobTypes = [];
        print(
          'MyAuthProvider: User document not found. Profile loaded as empty. DeviceID: ${_state.currentDeviceId}, Bookmarks: ${_state.bookmarkedJobIds.length}, UserSkills: ${_state.userSkills.length}',
        );

        // Create a basic user document if it doesn't exist
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? '',
          'skillRank': '',
          'hasSkillRank': false,
          'userSkills': [],
          'preferredLocations': [],
          'preferredJobTypes': [],
          'createdAt': FieldValue.serverTimestamp(),
          'device_id': '', // Will be updated on next signIn/forceSignIn
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('MyAuthProvider: Error loading user profile: $e');
      _state.errorMessage = 'Failed to load user profile: $e';
      _state.profileLoaded = true; // Still mark as loaded to avoid infinite attempts
    } finally {
      notifyListeners();
    }
  }

  // Saves the user's skill rank, user skills, preferred locations, and job types to Firestore.
  Future<void> saveUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.errorMessage = 'No authenticated user to save preferences.';
      _state.isLoading = false;
      notifyListeners();
      return;
    }

    if (_state.skillRank.isEmpty) {
      _state.errorMessage = 'Please select a skill rank.';
      _state.isLoading = false;
      notifyListeners();
      return;
    }

    _state.isLoading = true;
    _state.errorMessage = '';
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'skillRank': _state.skillRank,
        'hasSkillRank': true,
        'userSkills': _state.userSkills,
        'preferredLocations': _state.preferredLocations,
        'preferredJobTypes': _state.preferredJobTypes,
      }, SetOptions(merge: true));

      _state.isLoading = false;
      _state.hasSkillRank = true;
      _state.errorMessage = '';
      // Update last fetched values to reflect the saved state for optimization
      _state.lastFetchedSkillRank = _state.skillRank;
      _state.lastFetchedPreferredLocations = List.from(
        _state.preferredLocations,
      );
      _state.lastFetchedPreferredJobTypes = List.from(_state.preferredJobTypes);
      notifyListeners();
    } catch (e) {
      _state.errorMessage = 'Failed to save preferences: $e';
      _state.isLoading = false;
      notifyListeners();
      print('MyAuthProvider: Error saving user preferences: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 8. Job Posting Methods
  //    (Handles the submission of a new job listing)
  // ---------------------------------------------------------------------------

  // Posts a new job listing to Firestore using the data stored in AuthState.
  Future<void> postJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.errorMessage = 'You must be logged in to post a job.';
      notifyListeners();
      return;
    }

    // Basic validation for job posting fields
    if (_state.jobTitle.isEmpty ||
        _state.jobDescription.isEmpty ||
        _state.jobDifficultyRank.isEmpty ||
        _state.company.isEmpty ||
        _state.location.isEmpty ||
        _state.salary.isEmpty ||
        _state.jobType.isEmpty ||
        _state.requiredSkills.isEmpty) {
      _state.errorMessage =
      'Please fill in all job details, including required skills.';
      notifyListeners();
      return;
    }

    _state.isLoading = true;
    _state.errorMessage = '';
    notifyListeners();

    try {
      String logoChar = _state.company.isNotEmpty
          ? _state.company[0].toUpperCase()
          : '?';

      // Convert comma-separated location string to a list
      List<String> locationsList = _state.location
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Add job listing to 'jobs' collection
      DocumentReference docRef = await _firestore.collection('jobs').add({
        'postedByUserId': user.uid,
        'posterName': _state.name.isNotEmpty
            ? _state.name
            : user.displayName ?? 'Anonymous',
        'jobTitle': _state.jobTitle,
        'jobDescription': _state.jobDescription,
        'jobDifficultyRank': _state.jobDifficultyRank,
        'company': _state.company,
        'location': locationsList, // Store as a list
        'salary': _state.salary,
        'jobType': _state.jobType,
        'logoChar': logoChar,
        'requiredSkills': _state.requiredSkills
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(), // Store as a list
        'timestamp': FieldValue.serverTimestamp(),
      });

      _state.isLoading = false;
      _state.errorMessage = '';
      // Clear job posting form fields after successful submission
      _state.jobTitle = '';
      _state.jobDescription = '';
      _state.jobDifficultyRank = '';
      _state.company = '';
      _state.location = '';
      _state.salary = '';
      _state.jobType = '';
      _state.requiredSkills = '';
      notifyListeners();
    } catch (e) {
      _state.errorMessage = 'Failed to post job: $e';
      _state.isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 9. Bookmark Action Methods
  //    (Add/Remove job from user's bookmarks)
  // ---------------------------------------------------------------------------

  // Adds a job to the user's bookmarked jobs in Firestore.
  Future<void> addBookmark(String jobId, Map<String, dynamic> jobData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.errorMessage = 'You must be logged in to bookmark jobs.';
      notifyListeners();
      return;
    }
    if (_state.bookmarkedJobIds.contains(jobId)) {
      print('MyAuthProvider: Job $jobId is already bookmarked.');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarked_jobs')
          .doc(jobId) // Use jobId as document ID for easy retrieval
          .set({...jobData, 'bookmarkedAt': FieldValue.serverTimestamp()});

      // Update local state to reflect the change
      _state.bookmarkedJobIds.add(jobId);
      print('MyAuthProvider: Bookmarked job: $jobId');
      notifyListeners();
    } catch (e) {
      _state.errorMessage = 'Failed to bookmark job: $e';
      print('MyAuthProvider: Error bookmarking job: $e');
      notifyListeners();
    }
  }

  // Removes a job from the user's bookmarked jobs in Firestore.
  Future<void> removeBookmark(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.errorMessage = 'You must be logged in to unbookmark jobs.';
      notifyListeners();
      return;
    }
    if (!_state.bookmarkedJobIds.contains(jobId)) {
      print('MyAuthProvider: Job $jobId is not bookmarked.');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarked_jobs')
          .doc(jobId)
          .delete();

      // Update local state to reflect the change
      _state.bookmarkedJobIds.remove(jobId);
      print('MyAuthProvider: Unbookmarked job: $jobId');
      notifyListeners();
    } catch (e) {
      _state.errorMessage = 'Failed to unbookmark job: $e';
      print('MyAuthProvider: Error unbookmarking job: $e');
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 10. Setter Methods for AuthState Properties (for form inputs)
  // ---------------------------------------------------------------------------

  void setName(String name) {
    _state.name = name;
    _state.errorMessage = ''; // Clear error on input change
    notifyListeners();
  }

  void setEmail(String email) {
    _state.email = email;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setPassword(String password) {
    _state.password = password;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setConfirmPassword(String confirmPassword) {
    _state.confirmPassword = confirmPassword;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setSkillRank(String rank) {
    _state.skillRank = rank;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setUserSkills(String skills) {
    _state.userSkills = skills
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    _state.errorMessage = '';
    notifyListeners();
  }

  void setPreferredLocations(List<String> locations) {
    _state.preferredLocations = locations;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setPreferredJobTypes(List<String> jobTypes) {
    _state.preferredJobTypes = jobTypes;
    _state.errorMessage = '';
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 11. Setter Methods for Job Posting Properties (for form inputs)
  // ---------------------------------------------------------------------------

  void setJobTitle(String title) {
    _state.jobTitle = title;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setJobDescription(String description) {
    _state.jobDescription = description;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setJobDifficultyRank(String rank) {
    _state.jobDifficultyRank = rank;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setCompany(String company) {
    _state.company = company;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setLocation(String location) {
    _state.location = location;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setSalary(String salary) {
    _state.salary = salary;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setJobType(String type) {
    _state.jobType = type;
    _state.errorMessage = '';
    notifyListeners();
  }

  void setRequiredSkills(String skills) {
    _state.requiredSkills = skills;
    _state.errorMessage = '';
    notifyListeners();
  }
}