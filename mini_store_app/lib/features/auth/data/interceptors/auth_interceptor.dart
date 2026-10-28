import 'package:dio/dio.dart';

import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/session/session_expiration_notifier.dart';
import '../../domain/usecases/refresh_session_use_case.dart';

/// Adds the latest access token and transparently renews it after a 401.
///
/// A single in-flight refresh is shared by every concurrent failure. The
/// interceptor never navigates; session loss is published through
/// [SessionExpirationNotifier] so the router can react declaratively.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required SessionRepository sessionRepository,
    required RefreshSessionUseCase refreshSession,
    required SessionExpirationNotifier expirationNotifier,
  }) : _dio = dio,
       _sessionRepository = sessionRepository,
       _refreshSession = refreshSession,
       _expirationNotifier = expirationNotifier;

  static const String skipAuthKey = 'mini_store.skip_auth';
  static const String retriedKey = 'mini_store.auth_retried';
  static const String sessionExpiredMessage =
      'Your session expired. Please sign in again.';

  final Dio _dio;
  final SessionRepository _sessionRepository;
  final RefreshSessionUseCase _refreshSession;
  final SessionExpirationNotifier _expirationNotifier;

  Future<String?>? _refreshInFlight;
  Future<void>? _expirationInFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldSkip(options)) {
      handler.next(options);
      return;
    }

    try {
      final session = await _sessionRepository.read();
      if (session == null || session.accessToken.trim().isEmpty) {
        options.headers.remove('Authorization');
      } else {
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
    } catch (_) {
      options.headers.remove('Authorization');
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    if (err.response?.statusCode != 401 || _shouldSkip(options)) {
      handler.next(err);
      return;
    }

    if (options.extra[retriedKey] == true) {
      await _expireSession();
      handler.next(err);
      return;
    }

    options.extra[retriedKey] = true;
    final accessToken = await _refreshOnce();

    if (accessToken == null) {
      handler.next(err);
      return;
    }

    options.headers['Authorization'] = 'Bearer $accessToken';

    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      // The retried request re-enters onError, where a 401 expires the session.
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String?> _refreshOnce() {
    final existing = _refreshInFlight;
    if (existing != null) {
      return existing;
    }

    final future = _performRefresh();
    _refreshInFlight = future;
    future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });

    return future;
  }

  Future<String?> _performRefresh() async {
    try {
      final session = await _sessionRepository.read();
      if (session == null || session.refreshToken.trim().isEmpty) {
        await _expireSession();
        return null;
      }

      final refreshed = await _refreshSession();
      return refreshed.accessToken;
    } on AuthFailure catch (failure) {
      if (failure.requiresReauthentication) {
        await _expireSession();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _expireSession() {
    final existing = _expirationInFlight;
    if (existing != null) {
      return existing;
    }

    final future = _performExpiration();
    _expirationInFlight = future;
    future.whenComplete(() {
      if (identical(_expirationInFlight, future)) {
        _expirationInFlight = null;
      }
    });

    return future;
  }

  Future<void> _performExpiration() async {
    try {
      await _sessionRepository.clear();
    } catch (_) {
      // The auth state must still be cleared even if storage cleanup fails.
    }
    _expirationNotifier.notifyExpired(sessionExpiredMessage);
  }

  bool _shouldSkip(RequestOptions options) {
    if (options.extra[skipAuthKey] == true) {
      return true;
    }

    final path = options.path;
    return path.endsWith('/auth/login') || path.endsWith('/auth/refresh');
  }
}
