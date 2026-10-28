import '../repositories/session_repository.dart';

/// Removes the saved session. The router reacts to the resulting auth state.
class LogoutUseCase {
  const LogoutUseCase(this._sessionRepository);

  final SessionRepository _sessionRepository;

  Future<void> call() => _sessionRepository.clear();
}
