import '../repositories/auth_repository_interface.dart';
import '../../../../core/logging/logger.dart';

class SignOutUseCase {
  final AuthRepositoryInterface _repository;

  SignOutUseCase({required AuthRepositoryInterface repository})
      : _repository = repository;

  Future<void> execute() async {
    Logger.auth('Executing sign out use case');
    await _repository.signOut();
  }
}