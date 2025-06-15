import 'package:firebase_auth/firebase_auth.dart'; // Import Firestore if you use it directly here, though MyAuthProvider handles user docs

class AuthRepoImpl {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Re-throw specific FirebaseAuthException to be handled by the provider
      rethrow;
    } catch (e) {
      // Generic error for unexpected issues
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Creates a new user with email and password, and sets their display name.
  /// Returns a [UserCredential] on success.
  Future<UserCredential> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Set display name for the newly created user
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        // Reload user to get the updated display name immediately
        await userCredential.user!.reload();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Re-throw specific FirebaseAuthException
      throw e;
    } catch (e) {
      // Generic error
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}
