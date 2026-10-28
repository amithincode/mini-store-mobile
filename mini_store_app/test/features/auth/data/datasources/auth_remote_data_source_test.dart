import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mini_store_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mini_store_app/features/auth/domain/failures/auth_failure.dart';

import '../../../../support/fake_http_adapter.dart';

Dio _dioWith(FakeHttpAdapter adapter) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://dummyjson.test',
      responseType: ResponseType.json,
    ),
  )..httpClientAdapter = adapter;
}

Map<String, Object> _loginBody({String username = 'emilys'}) {
  return <String, Object>{
    'id': 1,
    'username': username,
    'email': 'emily.johnson@x.dummyjson.com',
    'firstName': 'Emily',
    'lastName': 'Johnson',
    'gender': 'female',
    'image': 'https://dummyjson.test/icon/emilys/128',
    'accessToken': 'access-1',
    'refreshToken': 'refresh-1',
  };
}

void main() {
  group('DioAuthRemoteDataSource', () {
    test('parses the top-level login response', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(_loginBody()),
      );
      final dataSource = DioAuthRemoteDataSource(_dioWith(adapter));

      final response = await dataSource.login(
        username: ' emilys ',
        password: 'emilyspass',
      );

      expect(response.accessToken, 'access-1');
      expect(response.refreshToken, 'refresh-1');
      expect(response.user?.id, 1);
      expect(response.user?.username, 'emilys');
      expect(response.user?.email, 'emily.johnson@x.dummyjson.com');
      expect(response.user?.firstName, 'Emily');
      expect(response.user?.lastName, 'Johnson');
      expect(response.user?.gender, 'female');
      expect(response.user?.image, 'https://dummyjson.test/icon/emilys/128');

      final request = adapter.requests.single;
      expect(request.path, '/auth/login');
      expect(request.data, <String, dynamic>{
        'username': ' emilys ',
        'password': 'emilyspass',
      });
    });

    test('surfaces the API message for invalid credentials', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(<String, Object>{
          'message': 'Invalid credentials',
        }, statusCode: 400),
      );
      final dataSource = DioAuthRemoteDataSource(_dioWith(adapter));

      await expectLater(
        dataSource.login(username: 'wrong', password: 'wrong'),
        throwsA(
          isA<InvalidCredentialsFailure>().having(
            (failure) => failure.message,
            'message',
            'Invalid credentials',
          ),
        ),
      );
    });

    test(
      'maps an unauthorized refresh to a re-authentication failure',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async => jsonResponse(<String, Object>{
            'message': 'Invalid refresh token',
          }, statusCode: 401),
        );
        final dataSource = DioAuthRemoteDataSource(_dioWith(adapter));

        await expectLater(
          dataSource.refresh(refreshToken: 'expired'),
          throwsA(
            isA<UnauthorizedFailure>()
                .having(
                  (failure) => failure.message,
                  'message',
                  'Invalid refresh token',
                )
                .having(
                  (failure) => failure.requiresReauthentication,
                  'requiresReauthentication',
                  isTrue,
                ),
          ),
        );
      },
    );

    test('sends the refresh token and a 30 minute expiry', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(<String, Object>{
          'accessToken': 'access-2',
          'refreshToken': 'refresh-2',
        }),
      );
      final dataSource = DioAuthRemoteDataSource(_dioWith(adapter));

      final response = await dataSource.refresh(refreshToken: 'refresh-1');

      expect(response.accessToken, 'access-2');
      expect(response.refreshToken, 'refresh-2');
      expect(response.user, isNull);
      expect(adapter.requests.single.path, '/auth/refresh');
      expect(adapter.requests.single.data, <String, dynamic>{
        'refreshToken': 'refresh-1',
        'expiresInMins': 30,
      });
    });

    test('rejects a successful response without tokens', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(<String, Object>{'ok': true}),
      );
      final dataSource = DioAuthRemoteDataSource(_dioWith(adapter));

      await expectLater(
        dataSource.login(username: 'emilys', password: 'emilyspass'),
        throwsA(isA<MalformedResponseFailure>()),
      );
    });

    test('accepts a raw JSON string body', () async {
      final adapter = FakeHttpAdapter(
        (options) async => ResponseBody.fromString(
          jsonEncode(_loginBody()),
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['text/plain'],
          },
        ),
      );
      final dataSource = DioAuthRemoteDataSource(_dioWith(adapter));

      final response = await dataSource.login(
        username: 'emilys',
        password: 'emilyspass',
      );

      expect(response.user?.username, 'emilys');
    });
  });

  group('AuthRepositoryImpl', () {
    test('requires a user profile on login', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(<String, Object>{
          'accessToken': 'access-1',
          'refreshToken': 'refresh-1',
        }),
      );
      final repository = AuthRepositoryImpl(
        DioAuthRemoteDataSource(_dioWith(adapter)),
      );

      await expectLater(
        repository.login(username: 'emilys', password: 'emilyspass'),
        throwsA(isA<MalformedResponseFailure>()),
      );
    });

    test('returns the login session and refresh tokens', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(_loginBody()),
      );
      final repository = AuthRepositoryImpl(
        DioAuthRemoteDataSource(_dioWith(adapter)),
      );

      final session = await repository.login(
        username: 'emilys',
        password: 'emilyspass',
      );

      expect(session.accessToken, 'access-1');
      expect(session.refreshToken, 'refresh-1');
      expect(session.user.fullName, 'Emily Johnson');
    });
  });
}
