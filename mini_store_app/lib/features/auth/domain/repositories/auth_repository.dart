import '../entities/auth_session.dart';
import '../entities/refresh_result.dart';

/// Remote authentication operations. Persistence belongs to
/// `SessionRepository`.
abstract interface class AuthRepository {
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<RefreshResult> refresh({required String refreshToken});
}
