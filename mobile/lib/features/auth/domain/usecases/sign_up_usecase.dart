import '../repositories/auth_repository_interface.dart';
import '../../data/models/auth_models.dart';
import '../../../../core/logging/logger.dart';

class SignUpUseCase {
  final AuthRepositoryInterface _repository;

  SignUpUseCase({required AuthRepositoryInterface repository})
      : _repository = repository;

  Future<AuthResult> execute(String email, String password, String displayName) async {
    if (email.isEmpty) {
      throw AuthException(message: 'Email cannot be empty');
    }

    if (password.isEmpty) {
      throw AuthException(message: 'Password cannot be empty');
    }

    if (displayName.isEmpty) {
      throw AuthException(message: 'Display name cannot be empty');
    }

    if (!_isValidEmail(email)) {
      throw AuthException(message: 'Please enter a valid email address');
    }

    if (password.length < 6) {
      throw AuthException(message: 'Password must be at least 6 characters');
    }

    if (displayName.length < 2) {
      throw AuthException(message: 'Display name must be at least 2 characters');
    }

    if (displayName.length > 50) {
      throw AuthException(message: 'Display name cannot exceed 50 characters');
    }

    Logger.auth('Executing sign up use case for: $email');
    return await _repository.signUp(email, password, displayName);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}