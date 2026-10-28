import '../entities/auth_session.dart';

/// Local persistence for the active session.
abstract interface class SessionRepository {
  Future<AuthSession?> read();

  Future<void> save(AuthSession session);

  Future<void> clear();
}
