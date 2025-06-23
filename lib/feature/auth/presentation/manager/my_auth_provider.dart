import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_job_quest/feature/auth/data/auth_repo_impl.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/auth_state.dart';

class MyAuthProvider extends ChangeNotifier {
  final AuthRepoImpl _authRepo = AuthRepoImpl();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthState _state = AuthState();
  AuthState get state => _state;

  StreamSubscription<User?>? _authStateSubscription;

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

  MyAuthProvider() {
    _initializeAuthListener();
    _getDeviceId(); // Initial device ID fetch
  }

  void _initializeAuthListener() {
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      if (user != null) {
        // User is logged in
        // Only load the profile if it's a new user or the current user changed
        if (!_state.profileLoaded || _state.user?.uid != user.uid) {
          _state.user = user; // Update the user in the state
          // Ensure profileLoaded is set to false BEFORE async load
          // so AuthChanges knows to show loading if needed
          _state.profileLoaded = false;
          notifyListeners(); // Notify immediately that profile is about to load

          await _loadUserProfileAndBookmarks(); // Load full user profile and bookmarks
        }
      } else {
        // User logged out or no user is logged in
        // This block ensures the state is fully reset when Firebase reports no user.
        _state = AuthState(); // Reset the entire AuthState to default
        _state.profileLoaded = false; // Explicitly set profileLoaded to false
        _state.currentDeviceId =
            await _getDeviceId(); // Re-fetch device ID if needed (async)
        notifyListeners(); // Notify listeners of the state reset
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  List<String> _getAcceptableDifficultyRanks(String userSkillRank) {
    final int userRankIndex = _rankOrder.indexOf(userSkillRank.split(' ')[0]);

    if (userRankIndex == -1) {
      return []; // Return empty if rank is not found
    }

    final int startIndex = (userRankIndex - 1).clamp(0, _rankOrder.length - 1);
    final int endIndex = (userRankIndex + 1).clamp(0, _rankOrder.length);

    return _rankOrder.sublist(startIndex, endIndex);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  get allJobsDocsStream {
    return _firestore
        .collection('jobs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<List<Map<String, dynamic>>> get communityJobsStream {
    return allJobsDocsStream.map((docs) {
      return docs.map((doc) {
        final data = doc.data();
        return {
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
              ? (data['location'] as List).map((e) => e.toString()).join(', ')
              : data['location'] as String? ?? 'Remote',
          'salary': data['salary'] ?? 'Negotiable',
          'jobType': data['jobType'] ?? 'Full-time',
          'difficultyRank': data['jobDifficultyRank'] ?? 'Not specified',
          'jobDescription': data['jobDescription'] ?? '',
          'requiredSkills': (data['requiredSkills'] is List)
              ? (data['requiredSkills'] as List)
                    .map((e) => e.toString())
                    .join(', ')
              : data['requiredSkills'] as String? ?? '',
        };
      }).toList();
    });
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  get recommendedJobsStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_state.profileLoaded || _state.skillRank.isEmpty) {
      return Stream.value([]);
    }

    final acceptableDifficultyRanks = _getAcceptableDifficultyRanks(
      _state.skillRank,
    );

    if (acceptableDifficultyRanks.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('jobs')
        .where('jobDifficultyRank', whereIn: acceptableDifficultyRanks)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<List<String>> getSavedJobsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bookmarked_jobs')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Stream<List<Map<String, dynamic>>> getSavedJobDataStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bookmarked_jobs')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
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
          }).toList();
        });
  }

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
          deviceId = 'web_device_${DateTime.now().microsecondsSinceEpoch}';
        }
        if (deviceId != null) {
          await _secureStorage.write(key: 'device_id', value: deviceId);
        }
      } catch (e) {
        deviceId = 'fallback_device_${DateTime.now().microsecondsSinceEpoch}';
        await _secureStorage.write(key: 'device_id', value: deviceId);
      }
    }
    _state.currentDeviceId = deviceId;
    return deviceId;
  }

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
            _state.isLoading = false;
            // Set error message for device conflict to be handled by UI
            _state.errorMessage =
                'You are already logged in on another device. Sign in here to log out the other device.';
            notifyListeners();
            return; // Exit here, let UI handle the prompt
          } else {
            // Update device_id if it's the same device or first login on this device
            await userDocRef.set({
              'device_id': currentDeviceId,
            }, SetOptions(merge: true));
          }
        } else {
          // New user document (should ideally be created on signup, but good fallback)
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
        }
      }
      _state.isLoading = false;
      notifyListeners();
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
        'device_id': currentDeviceId,
      }, SetOptions(merge: true));

      _state.isLoading = false;
      _state.errorMessage = '';
      notifyListeners();
      await _loadUserProfileAndBookmarks(); // Reload profile after force sign-in
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

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': _state.name,
          'skillRank': '',
          'hasSkillRank': false,
          'userSkills': [],
          'preferredLocations': [],
          'preferredJobTypes': [],
          'device_id': currentDeviceId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _state.isLoading = false;
      _state.errorMessage = '';
      notifyListeners();
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

  Future<void> signOut() async {
    // Renamed from signout to signOut for consistency with Dart conventions
    _state.isLoading = true;
    _state.errorMessage = '';
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final String? userId = user?.uid; // Safely capture UID before sign out

      if (userId != null) {
        // Attempt to clear the device_id from Firestore BEFORE signing out Firebase Auth
        await _firestore
            .collection('users')
            .doc(userId) // Use captured userId
            .update({'device_id': FieldValue.delete()})
            .catchError((e) {
              debugPrint("Error deleting device_id on logout: $e");
              // Don't throw, continue with sign out
            });
      }

      await _authRepo.signOut(); // Perform the Firebase sign out

      // Reset MyAuthProvider's internal state after successful Firebase sign out.
      _state = AuthState(); // Reset ALL state variables to initial values
      _state.profileLoaded = false; // Explicitly set to false for clarity
      await _secureStorage.delete(key: 'device_id'); // Clear local device ID
      // Re-fetch device ID after local storage cleared, for the next potential login attempt
      _state.currentDeviceId = await _getDeviceId();

      notifyListeners(); // Notify immediately after all state reset
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to sign out. Please try again.';
      if (e.code == 'no-current-user') {
        message = 'No user was logged in to sign out.';
      }
      _state.errorMessage = message;
      notifyListeners(); // Notify if there's an error in sign out
    } catch (e) {
      _state.errorMessage = 'An unexpected error occurred during sign out: $e';
      notifyListeners(); // Notify if there's an unexpected error
    } finally {
      _state.isLoading = false; // Ensure loading is always false at the end
      notifyListeners(); // A final notification for good measure
    }
  }

  Future<void> _loadUserProfileAndBookmarks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.user = null;
      _state.hasSkillRank = false;
      _state.profileLoaded = false;
      _state.errorMessage = '';
      _state.currentDeviceId = await _getDeviceId();
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
      } catch (e) {
        debugPrint('MyAuthProvider: Error fetching bookmarked job IDs: $e');
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

        _state.lastFetchedSkillRank = fetchedSkillRank;
        _state.lastFetchedPreferredLocations = List.from(
          fetchedPreferredLocations,
        );
        _state.lastFetchedPreferredJobTypes = List.from(
          fetchedPreferredJobTypes,
        );
      } else {
        // If user document does not exist, create a basic one
        _state.user = user;
        _state.name = user.displayName ?? '';
        _state.email = user.email ?? '';
        _state.skillRank = '';
        _state.hasSkillRank = false;
        _state.profileLoaded = true;
        _state.errorMessage = '';
        _state.currentDeviceId = await _getDeviceId();
        _state.bookmarkedJobIds = fetchedBookmarkedJobIds;
        _state.userSkills = [];
        _state.preferredLocations = [];
        _state.preferredJobTypes = [];
        _state.lastFetchedSkillRank = '';
        _state.lastFetchedPreferredLocations = [];
        _state.lastFetchedPreferredJobTypes = [];

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
          'device_id': '', // Initialize device_id
        }, SetOptions(merge: true));
      }
    } catch (e) {
      _state.errorMessage = 'Failed to load user profile: $e';
      _state.profileLoaded =
          true; // Still mark as loaded to prevent infinite loading state
      debugPrint('Error in _loadUserProfileAndBookmarks: $e');
    } finally {
      notifyListeners();
    }
  }

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
    }
  }

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

      List<String> locationsList = _state.location
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await _firestore.collection('jobs').add({
        'postedByUserId': user.uid,
        'posterName': _state.name.isNotEmpty
            ? _state.name
            : user.displayName ?? 'Anonymous',
        'jobTitle': _state.jobTitle,
        'jobDescription': _state.jobDescription,
        'jobDifficultyRank': _state.jobDifficultyRank,
        'company': _state.company,
        'location': locationsList,
        'salary': _state.salary,
        'jobType': _state.jobType,
        'logoChar': logoChar,
        'requiredSkills': _state.requiredSkills
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _state.isLoading = false;
      _state.errorMessage = '';
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

  Future<void> deleteJob(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.errorMessage = 'You must be logged in to delete a job.';
      notifyListeners();
      return;
    }

    _state.isLoading = true;
    _state.errorMessage = '';
    notifyListeners();

    try {
      final jobDocRef = _firestore.collection('jobs').doc(jobId);
      final jobDoc = await jobDocRef.get();

      if (jobDoc.exists) {
        final jobData = jobDoc.data() as Map<String, dynamic>;
        if (jobData['postedByUserId'] == user.uid) {
          await jobDocRef.delete();
        } else {
          _state.errorMessage =
              'You can only delete jobs that you have posted.';
        }
      } else {
        _state.errorMessage = 'This job no longer exists.';
      }
    } catch (e) {
      _state.errorMessage = 'An error occurred while deleting the job: $e';
    } finally {
      _state.isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cleanUpOrphanedJobs() async {
    _state.isLoading = true;
    _state.errorMessage = '';
    notifyListeners();

    try {
      final jobsSnapshot = await _firestore.collection('jobs').get();
      int deletedCount = 0;

      for (var jobDoc in jobsSnapshot.docs) {
        final jobData = jobDoc.data();
        final String? postedByUserId = jobData['postedByUserId'] as String?;

        if (postedByUserId != null && postedByUserId.isNotEmpty) {
          final userDoc = await _firestore
              .collection('users')
              .doc(postedByUserId)
              .get();

          if (!userDoc.exists) {
            await jobDoc.reference.delete();
            deletedCount++;
          }
        }
      }
      _state.errorMessage = '$deletedCount orphaned jobs deleted successfully.';
    } catch (e) {
      _state.errorMessage = 'Failed to clean up orphaned jobs: $e';
    } finally {
      _state.isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBookmark(String jobId, Map<String, dynamic> jobData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _state.errorMessage = 'You must be logged in to bookmark jobs.';
      notifyListeners();
      return;
    }
    if (_state.bookmarkedJobIds.contains(jobId)) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarked_jobs')
          .doc(jobId)
          .set({...jobData, 'bookmarkedAt': FieldValue.serverTimestamp()});

      _state.bookmarkedJobIds.add(jobId);
      notifyListeners();
    } catch (e) {
      _state.errorMessage = 'Failed to bookmark job: $e';
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
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarked_jobs')
          .doc(jobId)
          .delete();

      _state.bookmarkedJobIds.remove(jobId);
      notifyListeners();
    } catch (e) {
      _state.errorMessage = 'Failed to unbookmark job: $e';
      notifyListeners();
    }
  }

  void setName(String name) {
    _state.name = name;
    _state.errorMessage = '';
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
