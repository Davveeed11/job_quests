import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_job_quest/feature/auth/data/auth_repo_impl.dart';
import 'package:device_info_plus/device_info_plus.dart'; // New import
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // New import
import 'dart:io'; // New import for Platform check

import 'package:my_job_quest/feature/auth/presentation/manager/auth_state.dart';

class MyAuthProvider extends ChangeNotifier {
  final AuthRepoImpl _authRepo = AuthRepoImpl();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthState _state = AuthState(); // Private state object
  AuthState get state => _state; // Public getter for AuthState

  // --- Stream for ALL job postings, now returning QueryDocumentSnapshot to include doc.id ---
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  get allJobsDocsStream {
    return _firestore
        .collection('jobs')
        .orderBy('timestamp', descending: true) // Ensure ordering by timestamp
        .snapshots() // Listen for real-time changes
        .map(
          (snapshot) =>
              snapshot.docs, // Return the list of DocumentSnapshots directly
        );
  }

  // Helper stream to map QueryDocumentSnapshot to Map<String, dynamic> for easier consumption by widgets
  // This stream will be used by HomeScreen's Community Jobs section
  Stream<List<Map<String, dynamic>>> get jobsStream {
    return allJobsDocsStream.map((docs) {
      return docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id, // Include the document ID
          ...data,
          // Ensure 'logo_char' or 'company' for JobCard is always present
          'company':
              data['company'] ??
              (data['posterName'] ?? 'Community Post').toString(),
          'logoChar': (data['company'] as String?)?.isNotEmpty == true
              ? (data['company'] as String)[0].toUpperCase()
              : (data['posterName'] as String?)?.isNotEmpty == true
              ? (data['posterName'] as String)[0].toUpperCase()
              : '?', // Default if company/poster name is missing
          'jobTitle': data['jobTitle'] ?? 'No Title',
          'location': data['location'] ?? 'Remote',
          'salary': data['salary'] ?? 'Negotiable',
          'jobType': data['jobType'] ?? 'Full-time',
          // Ensure other fields are present, using defaults if needed
          'jobDescription': data['jobDescription'] ?? '',
          'jobDifficultyRank': data['jobDifficultyRank'] ?? '',
        };
      }).toList();
    });
  }

  // --- Stream for current user's bookmarked job IDs ---
  Stream<List<String>> get bookmarkedJobIdsStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]); // Return an empty stream if no user
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bookmarked_jobs')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // --- NEW: Method to fetch full job details for a list of job IDs ---
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchJobsByIds(
    List<String> jobIds,
  ) async {
    if (jobIds.isEmpty) {
      return [];
    }
    // Firestore 'whereIn' query has a limit of 10 items.
    // For more than 10, you'd need to break it into multiple queries.
    // For simplicity, this example assumes a small number of bookmarked jobs.
    // In a real app, for large lists, consider batching queries or a different data model.
    try {
      final querySnapshot = await _firestore
          .collection('jobs')
          .where(FieldPath.documentId, whereIn: jobIds)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      print('MyAuthProvider: Error fetching jobs by IDs: $e');
      _state.errorMessage = 'Failed to load saved jobs: $e';
      notifyListeners();
      return [];
    }
  }

  // --- Device ID Management ---
  Future<String?> _getDeviceId() async {
    String? deviceId = await _secureStorage.read(key: 'device_id');
    if (deviceId == null) {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      } else {
        // Fallback for web, desktop, etc. You might use a UUID generator here.
        deviceId = 'web_device_${DateTime.now().microsecondsSinceEpoch}';
      }
      if (deviceId != null) {
        await _secureStorage.write(key: 'device_id', value: deviceId);
      }
    }
    _state.currentDeviceId = deviceId; // Update state with current device ID
    print('MyAuthProvider: Current Device ID: ${deviceId ?? "N/A"}');
    return deviceId;
  }

  // --- Authentication Methods ---

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

          if (existingDeviceId != null && existingDeviceId != currentDeviceId) {
            // User is logged in on another device
            _state.isLoading = false;
            notifyListeners();
            _state.errorMessage =
                'You are already logged in on another device. Sign in here to log out the other device.';
            print(
              'MyAuthProvider: Login attempt from different device. Existing: $existingDeviceId, Current: $currentDeviceId',
            );
            return; // Exit here, let UI handle the error/prompt for force sign-in
          } else {
            // Either no existing device ID, or it matches the current one
            await userDocRef.set({
              'device_id': currentDeviceId,
            }, SetOptions(merge: true));
            print(
              'MyAuthProvider: Device ID updated/set for user: $currentDeviceId',
            );
          }
        } else {
          // New user document (should ideally be created on sign up, but handle if not)
          await userDocRef.set({
            'device_id': currentDeviceId,
            'email': _state.email,
            'name': _state.name, // Will be empty if not set on login form
            'skillRank': '',
            'hasSkillRank': false,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print(
            'MyAuthProvider: New user document created with device ID: $currentDeviceId',
          );
        }
      }

      _state.isLoading = false;
      _state.errorMessage = ''; // Clear error on success
      notifyListeners();
      await loadUserProfile(); // Load user profile data and bookmarks after successful sign-in
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

  // --- NEW: Method to force sign-in on a new device (clears previous device ID) ---
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
        'device_id': currentDeviceId, // Overwrite previous device ID
      }, SetOptions(merge: true));
      print(
        'MyAuthProvider: Force sign-in: Device ID updated to $currentDeviceId.',
      );

      _state.isLoading = false;
      _state.errorMessage = '';
      notifyListeners();
      await loadUserProfile(); // Reload profile after update
    } catch (e) {
      _state.errorMessage = 'Failed to sign in on new device: $e';
      _state.isLoading = false;
      notifyListeners();
    }
  }

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
        // Create user document with initial data and device_id
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': _state.name,
          'skillRank': '', // Initialize skillRank as empty
          'hasSkillRank': false, // Explicitly set hasSkillRank to false
          'device_id': currentDeviceId, // Store device ID on sign up
          'createdAt': FieldValue.serverTimestamp(),
        });
        await loadUserProfile(); // Load profile including initial empty bookmarks
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

  /// Handles user sign-out from Firebase.
  /// Resets provider state and clears error messages.
  Future<void> signout() async {
    _state.isLoading = true;
    _state.errorMessage = '';
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Clear the device_id from Firestore when signing out
        await _firestore.collection('users').doc(user.uid).update({
          'device_id': FieldValue.delete(), // Remove the field
        });
        print(
          'MyAuthProvider: Device ID cleared from Firestore for user: ${user.uid}',
        );
      }

      await _authRepo.signOut(); // Perform Firebase sign-out
      _state = AuthState(); // Reset AuthState to initial values
      await _secureStorage.delete(
        key: 'device_id',
      ); // Clear device ID from secure storage
      _state.profileLoaded = true; // Mark profile as loaded even if reset
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

  // --- Profile Management (Includes loading bookmarked jobs) ---
  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.user = null;
      _state.hasSkillRank = false;
      _state.profileLoaded = true; // Mark as loaded, no user profile to fetch
      _state.errorMessage = '';
      _state.currentDeviceId = await _getDeviceId(); // Still get device ID
      _state.bookmarkedJobIds.clear(); // Clear bookmarks if no user
      notifyListeners();
      return;
    }

    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      List<String> fetchedBookmarkedJobIds = [];
      try {
        // Fetch bookmarked job IDs from the 'bookmarked_jobs' subcollection
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
        // Continue loading profile even if bookmarks fail
      }

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        String fetchedSkillRank = data['skillRank'] as String? ?? '';
        bool hasRank = fetchedSkillRank.isNotEmpty;

        _state.user = user;
        _state.name = data['name'] as String? ?? user.displayName ?? '';
        _state.email = data['email'] as String? ?? user.email ?? '';
        _state.skillRank = fetchedSkillRank;
        _state.hasSkillRank = hasRank;
        _state.profileLoaded = true; // Mark profile as loaded
        _state.errorMessage = '';
        _state.currentDeviceId =
            await _getDeviceId(); // Get and update device ID
        _state.bookmarkedJobIds =
            fetchedBookmarkedJobIds; // Update bookmarked IDs
        print(
          'MyAuthProvider: Profile loaded. SkillRank: $fetchedSkillRank, HasRank: $hasRank, DeviceID: ${_state.currentDeviceId}, Bookmarks: ${_state.bookmarkedJobIds.length}',
        );
      } else {
        // If user document does not exist, initialize state with defaults
        _state.user = user;
        _state.name = user.displayName ?? '';
        _state.email = user.email ?? '';
        _state.skillRank = '';
        _state.hasSkillRank = false;
        _state.profileLoaded = true;
        _state.errorMessage = '';
        _state.currentDeviceId = await _getDeviceId();
        _state.bookmarkedJobIds =
            fetchedBookmarkedJobIds; // Still set fetched bookmarks (might be empty)
        print(
          'MyAuthProvider: User document not found. Profile loaded as empty. DeviceID: ${_state.currentDeviceId}, Bookmarks: ${_state.bookmarkedJobIds.length}',
        );
        // Optionally create a basic user document if it's missing (though signup should handle this)
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? '',
          'skillRank': '',
          'hasSkillRank': false,
          'createdAt': FieldValue.serverTimestamp(),
          'device_id': _state.currentDeviceId,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('MyAuthProvider: Error loading user profile: $e');
      _state.errorMessage = 'Failed to load user profile: $e';
      _state.profileLoaded =
          true; // Still mark as loaded to prevent infinite loading
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveSkillRank() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.errorMessage = 'No authenticated user to save skill rank.';
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
        'hasSkillRank': true, // Explicitly set to true when rank is saved
      }, SetOptions(merge: true));

      _state.isLoading = false;
      _state.hasSkillRank = true;
      _state.errorMessage = '';
      notifyListeners();
    } catch (e) {
      _state.errorMessage = 'Failed to save skill rank: $e';
      _state.isLoading = false;
      notifyListeners();
    }
  }

  // --- Job Posting Methods ---

  Future<void> postJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.errorMessage = 'You must be logged in to post a job.';
      notifyListeners();
      return;
    }

    if (_state.jobTitle.isEmpty ||
        _state.jobDescription.isEmpty ||
        _state.jobDifficultyRank.isEmpty ||
        _state.company.isEmpty ||
        _state.location.isEmpty ||
        _state.salary.isEmpty ||
        _state.jobType.isEmpty) {
      _state.errorMessage = 'Please fill in all job details.';
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

      // Add a new document to the 'jobs' collection
      DocumentReference docRef = await _firestore.collection('jobs').add({
        'postedByUserId': user.uid,
        'posterName': _state.name.isNotEmpty
            ? _state.name
            : user.displayName ?? 'Anonymous',
        'jobTitle': _state.jobTitle,
        'jobDescription': _state.jobDescription,
        'jobDifficultyRank': _state.jobDifficultyRank,
        'company': _state.company,
        'location': _state.location,
        'salary': _state.salary,
        'jobType': _state.jobType,
        'logoChar': logoChar, // Use the generated logoChar
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Optionally, update the document with its own ID (though Firestore doc.id is always available)
      await docRef.update(
        {'jobId': docRef.id},
      ); // This 'jobId' field is redundant if you always use doc.id, but good for clarity if needed in data model.

      _state.isLoading = false;
      _state.errorMessage = ''; // Clear error on success
      // Clear job posting fields after successful post
      _state.jobTitle = '';
      _state.jobDescription = '';
      _state.jobDifficultyRank = '';
      _state.company = '';
      _state.location = '';
      _state.salary = '';
      _state.jobType = '';
      notifyListeners();
    } catch (e) {
      _state.errorMessage = 'Failed to post job: $e';
      _state.isLoading = false;
      notifyListeners();
    }
  }

  // --- Bookmarking Methods ---

  Future<void> addBookmark(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.errorMessage = 'You must be logged in to bookmark jobs.';
      notifyListeners();
      return;
    }
    if (_state.bookmarkedJobIds.contains(jobId)) {
      print('MyAuthProvider: Job $jobId is already bookmarked.');
      return; // Already bookmarked, no action needed
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarked_jobs')
          .doc(jobId) // Use the jobId as the document ID for the bookmark
          .set({
            'timestamp': FieldValue.serverTimestamp(),
          }); // Store timestamp for when it was bookmarked

      _state.bookmarkedJobIds.add(jobId); // Add to local state
      print('MyAuthProvider: Bookmarked job: $jobId');
      notifyListeners();
    } catch (e) {
      _state.errorMessage = 'Failed to bookmark job: $e';
      print('MyAuthProvider: Error bookmarking job: $e');
      notifyListeners();
    }
  }

  Future<void> removeBookmark(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.errorMessage = 'You must be logged in to unbookmark jobs.';
      notifyListeners();
      return;
    }
    if (!_state.bookmarkedJobIds.contains(jobId)) {
      print('MyAuthProvider: Job $jobId is not bookmarked.');
      return; // Not bookmarked, no action needed
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarked_jobs')
          .doc(jobId)
          .delete(); // Delete the bookmark document

      _state.bookmarkedJobIds.remove(jobId); // Remove from local state
      print('MyAuthProvider: Unbookmarked job: $jobId');
      notifyListeners();
    } catch (e) {
      _state.errorMessage = 'Failed to unbookmark job: $e';
      print('MyAuthProvider: Error unbookmarking job: $e');
      notifyListeners();
    }
  }

  // --- Setter Methods for AuthState Properties ---
  void setName(String name) {
    _state.name = name;
    _state.errorMessage = ''; // Clear error message when user types
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

  // --- Setter Methods for Job Posting Properties ---
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
}
