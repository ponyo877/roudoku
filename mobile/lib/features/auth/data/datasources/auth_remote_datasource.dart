import 'package:firebase_auth/firebase_auth.dart';
import '../models/auth_models.dart';
import '../../../../core/logging/logger.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  AuthRemoteDataSource({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<AuthResult> signIn(String email, String password) async {
    try {
      Logger.auth('Attempting Firebase sign in');
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw AuthException(message: 'Sign in failed: no user returned');
      }

      return _mapFirebaseUserToAuthResult(credential.user!);
    } on FirebaseAuthException catch (e) {
      Logger.error('Firebase sign in error: ${e.code}', e);
      throw AuthException(
        message: _getErrorMessage(e.code),
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      Logger.error('Unexpected sign in error', e);
      throw AuthException(
        message: 'An unexpected error occurred during sign in',
        originalException: e,
      );
    }
  }

  Future<AuthResult> signUp(String email, String password, String displayName) async {
    try {
      Logger.auth('Attempting Firebase sign up');
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw AuthException(message: 'Sign up failed: no user returned');
      }

      // Update display name
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();

      return _mapFirebaseUserToAuthResult(credential.user!);
    } on FirebaseAuthException catch (e) {
      Logger.error('Firebase sign up error: ${e.code}', e);
      throw AuthException(
        message: _getErrorMessage(e.code),
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      Logger.error('Unexpected sign up error', e);
      throw AuthException(
        message: 'An unexpected error occurred during sign up',
        originalException: e,
      );
    }
  }

  Future<void> signOut() async {
    try {
      Logger.auth('Attempting Firebase sign out');
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      Logger.error('Firebase sign out error: ${e.code}', e);
      throw AuthException(
        message: 'Failed to sign out',
        code: e.code,
        originalException: e,
      );
    }
  }

  Future<AuthResult?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return null;
      }

      await user.reload();
      return _mapFirebaseUserToAuthResult(user);
    } catch (e) {
      Logger.error('Error getting current user', e);
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      Logger.auth('Attempting password reset');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      Logger.error('Firebase password reset error: ${e.code}', e);
      throw AuthException(
        message: _getErrorMessage(e.code),
        code: e.code,
        originalException: e,
      );
    }
  }

  Stream<AuthResult?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return _mapFirebaseUserToAuthResult(user);
    });
  }

  AuthResult _mapFirebaseUserToAuthResult(User user) {
    return AuthResult(
      userId: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      isEmailVerified: user.emailVerified,
    );
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Invalid password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An authentication error occurred.';
    }
  }
}