import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../repositories/session_repository.dart';

/// Authenticates the user and persists the session only after a successful
/// login response.
class LoginUseCase {
  const LoginUseCase(this._authRepository, this._sessionRepository);

  final AuthRepository _authRepository;
  final SessionRepository _sessionRepository;

  Future<AuthSession> call({
    required String username,
    required String password,
  }) async {
    final session = await _authRepository.login(
      username: username.trim(),
      password: password,
    );
    await _sessionRepository.save(session);

    return session;
  }
}
