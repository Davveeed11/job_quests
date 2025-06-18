import 'dart:async';
import 'dart:io';
import 'dart:math'; // Import 'dart:math' for clamp()

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

  // --- REVISED HELPER for more focused recommendations ---
  List<String> _getAcceptableDifficultyRanks(String userSkillRank) {
    // Find the index of the user's primary rank (e.g., 'A' from 'A Rank')
    final int userRankIndex = _rankOrder.indexOf(userSkillRank.split(' ')[0]);

    // If the user's rank isn't in our list, we can't recommend anything.
    if (userRankIndex == -1) {
      return [];
    }

    // Define the range: 1 rank above to 2 ranks below the user's rank.
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

    // Example: User is 'A' (index 3).
    // startIndex = (3 - 1) = 2.
    // endIndex = (3 + 3) = 6.
    // Resulting list will be from index 2 up to (but not including) index 6:
    // ['S', 'A', 'B', 'C'].

    return acceptableRanks;
  }

  // --- Stream for ALL job postings, returning QueryDocumentSnapshot to include doc.id ---
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  get allJobsDocsStream {
    return _firestore
        .collection('jobs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Helper stream to map QueryDocumentSnapshot to Map<String, dynamic> for easier consumption
  // This stream prepares data for HomeScreen's Community Jobs section
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

  // --- REVISED: Stream for Recommended Jobs with primary Firestore filter and secondary client-side filtering ---
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  get recommendedJobsStream {
    // ===== START DEBUGGING =====
    print('--- Checking recommendedJobsStream ---');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_state.profileLoaded || _state.skillRank.isEmpty) {
      print('DEBUG: Stream cancelled. Reason:');
      if (user == null) print('-> User is not logged in.');
      if (!_state.profileLoaded) print('-> User profile is not loaded yet.');
      if (_state.skillRank.isEmpty) print('-> User skill rank is empty.');
      print('------------------------------------');
      return Stream.value([]);
    }

    print('DEBUG: User is logged in and profile is loaded.');
    print('DEBUG: User Skill Rank: "${_state.skillRank}"');
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
      return Stream.value([]);
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

            final List<String> jobLocations = (data['location'] is List)
                ? List<String>.from(data['location'])
                : [data['location']?.toString() ?? ''];
            final String jobType = data['jobType'] as String? ?? '';

            print('DEBUG: Job Locations: $jobLocations | Job Type: "$jobType"');

            bool locationMatches = true;
            if (_state.preferredLocations.isNotEmpty) {
              if (_state.preferredLocations.contains('Anywhere')) {
                locationMatches = true;
              } else {
                locationMatches = jobLocations.any(
                  (loc) => _state.preferredLocations.contains(loc),
                );
              }
            }

            bool jobTypeMatches = true;
            if (_state.preferredJobTypes.isNotEmpty) {
              jobTypeMatches = _state.preferredJobTypes.contains(jobType);
            }

            print(
              'DEBUG: Location Match? $locationMatches | Job Type Match? $jobTypeMatches',
            );

            if (locationMatches && jobTypeMatches) {
              print('DEBUG: -> SUCCESS: Job added to recommendations.');
              filteredDocs.add(doc);
            } else {
              print('DEBUG: -> FAIL: Job filtered out.');
            }
          }
          print('---');
          print(
            'DEBUG: Final recommendation count for this update: ${filteredDocs.length}',
          );
          print('------------------------------------');
          return filteredDocs;
        });
  }

  // --- Stream for current user's bookmarked job IDs ---
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

  // Stream that fetches the actual job data for saved jobs
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

  // --- Device ID Management ---
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
          // Fallback for web or other platforms
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
    _state.currentDeviceId = deviceId;
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
            _state.isLoading = false;
            notifyListeners();
            _state.errorMessage =
                'You are already logged in on another device. Sign in here to log out the other device.';
            print(
              'MyAuthProvider: Login attempt from different device. Existing: $existingDeviceId, Current: $currentDeviceId',
            );
            return;
          } else {
            await userDocRef.set({
              'device_id': currentDeviceId,
            }, SetOptions(merge: true));
            print(
              'MyAuthProvider: Device ID updated/set for user: $currentDeviceId',
            );
          }
        } else {
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
      await loadUserProfile();
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
      print(
        'MyAuthProvider: Force sign-in: Device ID updated to $currentDeviceId.',
      );

      _state.isLoading = false;
      _state.errorMessage = '';
      notifyListeners();
      await loadUserProfile();
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
        await loadUserProfile();
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

  Future<void> signout() async {
    _state.isLoading = true;
    _state.errorMessage = '';
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'device_id': FieldValue.delete(),
        });
        print(
          'MyAuthProvider: Device ID cleared from Firestore for user: ${user.uid}',
        );
      }

      await _authRepo.signOut();
      _state = AuthState();
      await _secureStorage.delete(key: 'device_id');
      _state.profileLoaded = true;
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
      _state.profileLoaded = true;
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

        print(
          'MyAuthProvider: Profile loaded. SkillRank: $fetchedSkillRank, HasRank: $hasRank, DeviceID: ${_state.currentDeviceId}, Bookmarks: ${_state.bookmarkedJobIds.length}, UserSkills: ${_state.userSkills.length}, Preferred Locations: ${_state.preferredLocations}, Preferred Job Types: ${_state.preferredJobTypes}',
        );
      } else {
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
        print(
          'MyAuthProvider: User document not found. Profile loaded as empty. DeviceID: ${_state.currentDeviceId}, Bookmarks: ${_state.bookmarkedJobIds.length}, UserSkills: ${_state.userSkills.length}',
        );

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
          'device_id': '',
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('MyAuthProvider: Error loading user profile: $e');
      _state.errorMessage = 'Failed to load user profile: $e';
      _state.profileLoaded = true;
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
      print('MyAuthProvider: Error saving user preferences: $e');
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

      DocumentReference docRef = await _firestore.collection('jobs').add({
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

  // --- Bookmarking Methods ---
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
          .doc(jobId)
          .set({...jobData, 'bookmarkedAt': FieldValue.serverTimestamp()});

      _state.bookmarkedJobIds.add(jobId);
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

  void setRequiredSkills(String skills) {
    _state.requiredSkills = skills;
    _state.errorMessage = '';
    notifyListeners();
  }
}
