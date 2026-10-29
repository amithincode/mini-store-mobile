import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/network/api_log_interceptor.dart';

import '../../support/fake_http_adapter.dart';

Dio _dioWith(
  FakeHttpAdapter adapter,
  List<String> logs, {
  bool enabled = true,
  int maxBodyLength = 8000,
}) {
  return Dio(
      BaseOptions(
        baseUrl: 'https://dummyjson.test',
        responseType: ResponseType.json,
      ),
    )
    ..httpClientAdapter = adapter
    ..interceptors.add(
      ApiLogInterceptor(
        enabled: enabled,
        logger: logs.add,
        maxBodyLength: maxBodyLength,
      ),
    );
}

Map<String, Object> _loginResponse() {
  return <String, Object>{
    'accessToken': 'access-secret',
    'refreshToken': 'refresh-secret',
    'id': 1,
    'username': 'emilys',
  };
}

void main() {
  test('prints request and response as formatted JSON blocks', () async {
    final logs = <String>[];
    final dio = _dioWith(
      FakeHttpAdapter((options) async => jsonResponse(_loginResponse())),
      logs,
    );

    await dio.post<Object?>(
      '/auth/login',
      data: <String, dynamic>{'username': 'emilys', 'password': 'emilyspass'},
    );

    expect(logs, hasLength(2));

    final request = logs.first;
    expect(request, contains('┌─ API REQUEST #1'));
    expect(request, contains('│ POST https://dummyjson.test/auth/login'));
    expect(request, contains('│ Request body'));
    expect(request, contains('\n│ {\n'));
    expect(request, contains('\n│   "username": "emilys",\n'));
    expect(request, contains('\n│   "password": "[REDACTED]"\n│ }'));
    expect(request, contains('\n└──'));

    final response = logs.last;
    expect(response, contains('┌─ API RESPONSE #1 · 200'));
    expect(response, contains('│ POST https://dummyjson.test/auth/login'));
    expect(response, contains('│ Time: '));
    expect(response, contains('│ Response body'));
    expect(response, contains('\n│   "accessToken": "[REDACTED]",\n'));
    expect(response, contains('\n│   "refreshToken": "[REDACTED]",\n'));
    expect(response, contains('\n│   "username": "emilys"\n'));
    expect(response, contains('\n└──'));

    final joined = logs.join('\n');
    expect(joined, isNot(contains('emilyspass')));
    expect(joined, isNot(contains('access-secret')));
    expect(joined, isNot(contains('refresh-secret')));
  });

  test('redacts nested credential fields', () async {
    final logs = <String>[];
    final dio = _dioWith(
      FakeHttpAdapter((options) async => jsonResponse(<String, Object>{})),
      logs,
    );

    await dio.post<Object?>(
      '/auth/login',
      data: <String, dynamic>{
        'user': <String, dynamic>{
          'password': 'nested-secret',
          'token': 'nested-token',
          'access_token': 'snake-secret',
        },
        'items': <Object?>[
          <String, dynamic>{'refreshToken': 'list-secret'},
        ],
      },
    );

    final joined = logs.join('\n');
    expect(joined, contains('"password": "[REDACTED]"'));
    expect(joined, contains('"token": "[REDACTED]"'));
    expect(joined, contains('"access_token": "[REDACTED]"'));
    expect(joined, contains('"refreshToken": "[REDACTED]"'));
    expect(joined, isNot(contains('nested-secret')));
    expect(joined, isNot(contains('nested-token')));
    expect(joined, isNot(contains('snake-secret')));
    expect(joined, isNot(contains('list-secret')));
  });

  test('prints failures as formatted error blocks', () async {
    final logs = <String>[];
    final dio = _dioWith(
      FakeHttpAdapter(
        (options) async => jsonResponse(<String, Object>{
          'message': 'Invalid credentials',
        }, statusCode: 400),
      ),
      logs,
    );

    await expectLater(
      dio.post<Object?>('/auth/login', data: <String, Object>{}),
      throwsA(isA<DioException>()),
    );

    final joined = logs.join('\n');
    expect(joined, contains('┌─ API ERROR #1 · 400'));
    expect(joined, contains('│ POST https://dummyjson.test/auth/login'));
    expect(joined, contains('│ Error body'));
    expect(joined, contains('\n│   "message": "Invalid credentials"\n'));
  });

  test('uses a new number for each request', () async {
    final logs = <String>[];
    final dio = _dioWith(
      FakeHttpAdapter((options) async => jsonResponse(<String, Object>{})),
      logs,
    );

    await dio.get<Object?>('/auth/me');
    await dio.get<Object?>('/auth/me');

    expect(logs[0], contains('API REQUEST #1'));
    expect(logs[2], contains('API REQUEST #2'));
    expect(logs[1], contains('API RESPONSE #1'));
    expect(logs[3], contains('API RESPONSE #2'));
  });

  test('keeps numbering when clients share one logger', () async {
    final logs = <String>[];
    final logger = ApiLogInterceptor(logger: logs.add);

    Dio client() {
      return Dio(
          BaseOptions(
            baseUrl: 'https://dummyjson.test',
            responseType: ResponseType.json,
          ),
        )
        ..httpClientAdapter = FakeHttpAdapter(
          (options) async => jsonResponse(<String, Object>{}),
        )
        ..interceptors.add(logger);
    }

    await client().get<Object?>('/one');
    await client().get<Object?>('/two');

    expect(logs[0], contains('API REQUEST #1'));
    expect(logs[2], contains('API REQUEST #2'));
    expect(logs[1], contains('API RESPONSE #1'));
    expect(logs[3], contains('API RESPONSE #2'));
  });

  test('omits bodies larger than the configured limit', () async {
    final logs = <String>[];
    final dio = _dioWith(
      FakeHttpAdapter((options) async => jsonResponse(<String, Object>{})),
      logs,
      maxBodyLength: 40,
    );

    await dio.post<Object?>(
      '/auth/login',
      data: <String, dynamic>{'description': 'x' * 100},
    );

    expect(logs.first, contains('[Body omitted:'));
    expect(logs.first, contains('log limit]'));
    expect(logs.first, isNot(contains('xxxx')));
  });

  test('does not log when disabled', () async {
    final logs = <String>[];
    final dio = _dioWith(
      FakeHttpAdapter((options) async => jsonResponse(_loginResponse())),
      logs,
      enabled: false,
    );

    await dio.get<Object?>('/auth/me');

    expect(logs, isEmpty);
  });
}
