import '../entities/auth_session.dart';
import '../repositories/session_repository.dart';

/// Reads the saved session without contacting the API.
class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._sessionRepository);

  final SessionRepository _sessionRepository;

  Future<AuthSession?> call() => _sessionRepository.read();
}
