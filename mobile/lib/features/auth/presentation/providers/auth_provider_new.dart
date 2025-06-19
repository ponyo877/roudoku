import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../data/models/auth_models.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../../../core/logging/logger.dart';

class AuthProviderNew extends ChangeNotifier {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final AuthRemoteDataSource _authDataSource;

  AuthStateData _authState = AuthStateData(state: AuthState.initial);
  StreamSubscription<AuthResult?>? _authSubscription;

  AuthProviderNew({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required AuthRemoteDataSource authDataSource,
  }) : _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _signOutUseCase = signOutUseCase,
       _authDataSource = authDataSource {
    _initializeAuthListener();
  }

  AuthStateData get authState => _authState;
  bool get isAuthenticated => _authState.state == AuthState.authenticated;
  bool get isLoading => _authState.state == AuthState.loading;
  AuthResult? get currentUser => _authState.user;
  String? get errorMessage => _authState.errorMessage;

  void _initializeAuthListener() {
    _authSubscription = _authDataSource.authStateChanges.listen(
      (user) {
        if (user != null) {
          _updateAuthState(
            AuthStateData(state: AuthState.authenticated, user: user),
          );
          Logger.auth('User authenticated: ${user.email}');
        } else {
          _updateAuthState(AuthStateData(state: AuthState.unauthenticated));
          Logger.auth('User unauthenticated');
        }
      },
      onError: (error) {
        Logger.error('Auth state stream error', error);
        _updateAuthState(
          AuthStateData(state: AuthState.error, errorMessage: error.toString()),
        );
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    try {
      _updateAuthState(_authState.copyWith(state: AuthState.loading));

      final user = await _signInUseCase.execute(email, password);

      _updateAuthState(
        AuthStateData(state: AuthState.authenticated, user: user),
      );

      Logger.auth('Sign in successful: ${user.email}');
    } on AuthException catch (e) {
      Logger.error('Sign in failed: ${e.message}');
      _updateAuthState(
        AuthStateData(state: AuthState.error, errorMessage: e.message),
      );
    } catch (e) {
      Logger.error('Unexpected sign in error', e);
      _updateAuthState(
        AuthStateData(
          state: AuthState.error,
          errorMessage: 'An unexpected error occurred. Please try again.',
        ),
      );
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    try {
      _updateAuthState(_authState.copyWith(state: AuthState.loading));

      final user = await _signUpUseCase.execute(email, password, displayName);

      _updateAuthState(
        AuthStateData(state: AuthState.authenticated, user: user),
      );

      Logger.auth('Sign up successful: ${user.email}');
    } on AuthException catch (e) {
      Logger.error('Sign up failed: ${e.message}');
      _updateAuthState(
        AuthStateData(state: AuthState.error, errorMessage: e.message),
      );
    } catch (e) {
      Logger.error('Unexpected sign up error', e);
      _updateAuthState(
        AuthStateData(
          state: AuthState.error,
          errorMessage: 'An unexpected error occurred. Please try again.',
        ),
      );
    }
  }

  Future<void> signOut() async {
    try {
      _updateAuthState(_authState.copyWith(state: AuthState.loading));

      await _signOutUseCase.execute();

      _updateAuthState(AuthStateData(state: AuthState.unauthenticated));

      Logger.auth('Sign out successful');
    } catch (e) {
      Logger.error('Sign out failed', e);
      _updateAuthState(
        AuthStateData(
          state: AuthState.error,
          errorMessage: 'Failed to sign out. Please try again.',
        ),
      );
    }
  }

  void clearError() {
    if (_authState.state == AuthState.error) {
      _updateAuthState(
        _authState.copyWith(
          state: AuthState.unauthenticated,
          errorMessage: null,
        ),
      );
    }
  }

  void _updateAuthState(AuthStateData newState) {
    _authState = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
