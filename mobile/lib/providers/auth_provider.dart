import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  firebase_auth.User? _firebaseUser;
  User? _currentUser;
  bool _isLoading = false;

  firebase_auth.User? get firebaseUser => _firebaseUser;
  User? get currentUser => _currentUser;
  User? get user => _currentUser; // Alias for backward compatibility
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    
    if (firebaseUser != null) {
      // Load user data from backend
      _currentUser = await _userService.getUser(firebaseUser.uid);
      if (_currentUser == null) {
        // Create new user if doesn't exist
        _currentUser = User(
          id: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );
        await _userService.createUser(_currentUser!);
      }
    } else {
      _currentUser = null;
    }
    
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.signInWithGoogle();
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInAnonymously() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('AuthProvider: Starting anonymous sign in...');
      final result = await _authService.signInAnonymously();
      print('AuthProvider: Anonymous sign in completed for user: ${result.user?.uid}');
    } catch (e) {
      print('AuthProvider: Error signing in anonymously: $e');
      if (e is firebase_auth.FirebaseAuthException) {
        print('AuthProvider: Firebase Error Code: ${e.code}');
        print('AuthProvider: Firebase Error Message: ${e.message}');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(User updatedUser) async {
    if (_currentUser?.id != updatedUser.id) return;
    
    try {
      await _userService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }
}