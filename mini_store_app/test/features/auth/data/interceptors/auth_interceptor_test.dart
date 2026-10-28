import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/auth/data/interceptors/auth_interceptor.dart';
import 'package:mini_store_app/features/auth/domain/entities/refresh_result.dart';
import 'package:mini_store_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:mini_store_app/features/auth/domain/failures/auth_failure.dart';

import '../../../../support/auth_test_doubles.dart';
import '../../../../support/fake_http_adapter.dart';

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _Harness {
  _Harness({bool signedIn = true})
    : dependencies = TestAuthDependencies(
        session: signedIn ? testSession() : null,
      ) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://dummyjson.test',
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        sessionRepository: dependencies.sessionRepository,
        refreshSession: dependencies.refreshSessionUseCase,
        expirationNotifier: dependencies.expirationNotifier,
      ),
    );
    dio.httpClientAdapter = adapter;
    subscription = dependencies.expirationNotifier.stream.listen(
      (event) => expirationMessages.add(event.message),
    );
  }

  final TestAuthDependencies dependencies;
  final FakeHttpAdapter adapter = FakeHttpAdapter(
    (options) async => jsonResponse(<String, Object>{'ok': true}),
  );
  final List<String> expirationMessages = <String>[];

  late final Dio dio;
  late final StreamSubscription<dynamic> subscription;

  Future<void> dispose() async {
    await subscription.cancel();
    await dependencies.dispose();
  }
}

String? _authorization(RequestOptions options) {
  final value = options.headers['Authorization'];
  return value is String ? value : null;
}

ResponseBody _unauthorized() {
  return jsonResponse(<String, Object>{'message': 'Expired'}, statusCode: 401);
}

void main() {
  test('attaches the latest access token to protected requests', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);

    final response = await harness.dio.get<Object?>('/products');

    expect(response.statusCode, 200);
    expect(
      _authorization(harness.adapter.requests.single),
      'Bearer access-token',
    );
  });

  test('never attaches a token to login or refresh requests', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);

    await harness.dio.post<Object?>('/auth/login', data: <String, Object>{});
    await harness.dio.post<Object?>('/auth/refresh', data: <String, Object>{});

    expect(harness.adapter.requests, hasLength(2));
    for (final request in harness.adapter.requests) {
      expect(_authorization(request), isNull, reason: request.path);
    }
  });

  test('does not attach a stale token when signed out', () async {
    final harness = _Harness(signedIn: false);
    addTearDown(harness.dispose);

    await harness.dio.get<Object?>('/products');

    expect(_authorization(harness.adapter.requests.single), isNull);
  });

  test('refreshes after a 401 and retries once with the new token', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.adapter.handler = (options) async {
      if (_authorization(options) == 'Bearer refreshed-access-token') {
        return jsonResponse(<String, Object>{'ok': true});
      }
      return _unauthorized();
    };

    final response = await harness.dio.get<Object?>('/products');

    expect(response.statusCode, 200);
    expect(harness.dependencies.authRepository.refreshCalls, 1);
    expect(harness.dependencies.sessionRepository.saveCalls, 1);
    expect(
      harness.dependencies.sessionRepository.session?.accessToken,
      'refreshed-access-token',
    );
    expect(
      harness.dependencies.sessionRepository.session?.refreshToken,
      'refreshed-refresh-token',
    );
    expect(harness.adapter.requests, hasLength(2));
    expect(
      _authorization(harness.adapter.requests.last),
      'Bearer refreshed-access-token',
    );
    expect(harness.expirationMessages, isEmpty);
  });

  test('shares one refresh between simultaneous 401 responses', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.dependencies.authRepository.refreshCompleter =
        Completer<RefreshResult>();
    final bothRequested = Completer<void>();
    harness.adapter.handler = (options) async {
      if (_authorization(options) == 'Bearer refreshed-access-token') {
        return jsonResponse(<String, Object>{'ok': true});
      }
      if (harness.adapter.requests.length >= 2 && !bothRequested.isCompleted) {
        bothRequested.complete();
      }
      await bothRequested.future;
      return _unauthorized();
    };

    final first = harness.dio.get<Object?>('/one');
    final second = harness.dio.get<Object?>('/two');

    await pumpEventQueue();

    harness.dependencies.authRepository.refreshCompleter!.complete(
      const RefreshResult(
        tokens: AuthTokens(
          accessToken: 'refreshed-access-token',
          refreshToken: 'refreshed-refresh-token',
        ),
      ),
    );

    final responses = await Future.wait(<Future<Response<Object?>>>[
      first,
      second,
    ]);

    expect(responses.map((response) => response.statusCode), everyElement(200));
    expect(harness.dependencies.authRepository.refreshCalls, 1);
    expect(harness.dependencies.sessionRepository.saveCalls, 1);
    expect(harness.expirationMessages, isEmpty);
  });

  test('clears the session when refresh is rejected', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.dependencies.authRepository.refreshFailure =
        const UnauthorizedFailure('Invalid refresh token');
    harness.adapter.handler = (_) async => _unauthorized();

    await expectLater(
      harness.dio.get<Object?>('/products'),
      throwsA(isA<DioException>()),
    );
    await _flush();

    expect(harness.dependencies.sessionRepository.clearCalls, 1);
    expect(harness.dependencies.sessionRepository.session, isNull);
    expect(harness.expirationMessages, <String>[
      AuthInterceptor.sessionExpiredMessage,
    ]);
  });

  test('keeps the session when refresh fails transiently', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.dependencies.authRepository.refreshFailure = const NetworkFailure();
    harness.adapter.handler = (_) async => _unauthorized();

    await expectLater(
      harness.dio.get<Object?>('/products'),
      throwsA(isA<DioException>()),
    );
    await _flush();

    expect(harness.dependencies.sessionRepository.clearCalls, 0);
    expect(harness.dependencies.sessionRepository.session, isNotNull);
    expect(harness.expirationMessages, isEmpty);
  });

  test(
    'expires the session when the retried request is also rejected',
    () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.adapter.handler = (_) async => _unauthorized();

      await expectLater(
        harness.dio.get<Object?>('/products'),
        throwsA(isA<DioException>()),
      );
      await _flush();

      expect(harness.dependencies.authRepository.refreshCalls, 1);
      expect(harness.adapter.requests.length, greaterThanOrEqualTo(2));
      expect(harness.dependencies.sessionRepository.clearCalls, 1);
      expect(harness.dependencies.sessionRepository.session, isNull);
      expect(harness.expirationMessages, <String>[
        AuthInterceptor.sessionExpiredMessage,
      ]);
    },
  );

  test('does not try to refresh a rejected refresh request', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.adapter.handler = (_) async => _unauthorized();

    await expectLater(
      harness.dio.post<Object?>('/auth/refresh', data: <String, Object>{}),
      throwsA(isA<DioException>()),
    );
    await _flush();

    expect(harness.dependencies.authRepository.refreshCalls, 0);
    expect(harness.dependencies.sessionRepository.clearCalls, 0);
  });
}
