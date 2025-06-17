import '../../../auth/data/models/auth_models.dart';

abstract class AuthRepositoryInterface {
  Future<AuthResult> signIn(String email, String password);
  Future<AuthResult> signUp(String email, String password, String displayName);
  Future<void> signOut();
  Future<AuthResult?> getCurrentUser();
  Future<void> resetPassword(String email);
}