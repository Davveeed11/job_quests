import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  String email = '';
  String password = '';
  String name = '';
  String confirmPassword = '';
  String skillRank = '';
  bool hasSkillRank = false;
  bool profileLoaded = false;

  User? user;

  // Fields for Job Posting
  String jobTitle = '';
  String jobDescription = '';
  String jobDifficultyRank = '';
  String company = '';
  String location = '';
  String salary = '';
  String jobType = '';

  String? currentDeviceId;

  List<String> bookmarkedJobIds = []; // NEW: To store IDs of bookmarked jobs

  bool isLoading = false;
  String errorMessage = '';

  // You can add more fields as your user profile grows
}
