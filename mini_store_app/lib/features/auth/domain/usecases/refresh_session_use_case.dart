import '../entities/auth_session.dart';
import '../failures/auth_failure.dart';
import '../repositories/auth_repository.dart';
import '../repositories/session_repository.dart';

/// Renews the stored tokens and persists them before the caller retries.
class RefreshSessionUseCase {
  const RefreshSessionUseCase(this._authRepository, this._sessionRepository);

  final AuthRepository _authRepository;
  final SessionRepository _sessionRepository;

  Future<AuthSession> call() async {
    final current = await _sessionRepository.read();

    if (current == null || current.refreshToken.trim().isEmpty) {
      throw const UnauthorizedFailure(
        'Your session expired. Please sign in again.',
      );
    }

    final result = await _authRepository.refresh(
      refreshToken: current.refreshToken,
    );
    final updated = current.copyWith(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
      user: result.user == null
          ? current.user
          : current.user.mergedWith(result.user!),
    );

    await _sessionRepository.save(updated);

    return updated;
  }
}
