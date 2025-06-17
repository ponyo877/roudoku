import '../datasources/auth_remote_datasource.dart';
import '../models/auth_models.dart';
import '../../domain/repositories/auth_repository_interface.dart';
import '../../../../core/logging/logger.dart';

class AuthRepository implements AuthRepositoryInterface {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepository({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<AuthResult> signIn(String email, String password) async {
    try {
      Logger.auth('Attempting sign in for user: $email');
      final result = await _remoteDataSource.signIn(email, password);
      Logger.auth('Sign in successful for user: $email');
      return result;
    } catch (e) {
      Logger.error('Sign in failed for user: $email', e);
      rethrow;
    }
  }

  @override
  Future<AuthResult> signUp(String email, String password, String displayName) async {
    try {
      Logger.auth('Attempting sign up for user: $email');
      final result = await _remoteDataSource.signUp(email, password, displayName);
      Logger.auth('Sign up successful for user: $email');
      return result;
    } catch (e) {
      Logger.error('Sign up failed for user: $email', e);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      Logger.auth('Attempting sign out');
      await _remoteDataSource.signOut();
      Logger.auth('Sign out successful');
    } catch (e) {
      Logger.error('Sign out failed', e);
      rethrow;
    }
  }

  @override
  Future<AuthResult?> getCurrentUser() async {
    try {
      return await _remoteDataSource.getCurrentUser();
    } catch (e) {
      Logger.error('Failed to get current user', e);
      return null;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      Logger.auth('Attempting password reset for user: $email');
      await _remoteDataSource.resetPassword(email);
      Logger.auth('Password reset email sent to: $email');
    } catch (e) {
      Logger.error('Password reset failed for user: $email', e);
      rethrow;
    }
  }
}