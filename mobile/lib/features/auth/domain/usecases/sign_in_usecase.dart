import '../repositories/auth_repository_interface.dart';
import '../../data/models/auth_models.dart';
import '../../../../core/logging/logger.dart';

class SignInUseCase {
  final AuthRepositoryInterface _repository;

  SignInUseCase({required AuthRepositoryInterface repository})
      : _repository = repository;

  Future<AuthResult> execute(String email, String password) async {
    if (email.isEmpty) {
      throw AuthException(message: 'Email cannot be empty');
    }

    if (password.isEmpty) {
      throw AuthException(message: 'Password cannot be empty');
    }

    if (!_isValidEmail(email)) {
      throw AuthException(message: 'Please enter a valid email address');
    }

    if (password.length < 6) {
      throw AuthException(message: 'Password must be at least 6 characters');
    }

    Logger.auth('Executing sign in use case for: $email');
    return await _repository.signIn(email, password);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}