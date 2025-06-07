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
      
      await _authService.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
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