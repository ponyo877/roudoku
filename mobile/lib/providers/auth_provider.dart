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
      // Create a local user without backend interaction for now
      _currentUser = User(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );
      
      // Try to sync with backend in background without blocking
      _syncUserInBackground(_currentUser!);
    } else {
      _currentUser = null;
    }
    
    notifyListeners();
  }

  void _syncUserInBackground(User user) async {
    try {
      // Try to create user in background - don't block UI if it fails
      await _userService.createUser(user);
    } catch (e) {
      // Silently ignore background sync failures
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.signInWithGoogle();
    } catch (e) {
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
      
      await _authService.signInAnonymously();
    } catch (e) {
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