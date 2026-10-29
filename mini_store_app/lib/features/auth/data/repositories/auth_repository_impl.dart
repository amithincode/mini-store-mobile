import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/refresh_result.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      username: username,
      password: password,
    );
    final user = response.user;

    if (user == null) {
      throw const MalformedResponseFailure();
    }

    return AuthSession(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      user: user.toEntity(),
    );
  }

  @override
  Future<RefreshResult> refresh({required String refreshToken}) async {
    final response = await _remoteDataSource.refresh(
      refreshToken: refreshToken,
    );

    return RefreshResult(
      tokens: AuthTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      ),
      user: response.user?.toEntity(),
    );
  }
}
