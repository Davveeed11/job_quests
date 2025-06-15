import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_job_quest/feature/auth/domain/user_model.dart';

abstract class AuthRepo {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp(String email, String password, String username);
  Future<void> signOut();
  Stream<User?> get authStateChanges;
  Future<UserModel> forgetPassword(String email);
}
