import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/auth/data/storage/auth_session_codec.dart';
import 'package:mini_store_app/features/auth/domain/entities/user.dart';

import '../../../../support/auth_test_doubles.dart';

void main() {
  test('round-trips a session without persisting a password', () {
    final session = testSession();
    final raw = AuthSessionCodec.encode(session);

    expect(raw, isNot(contains('password')));
    expect(raw, isNot(contains('emilyspass')));

    final decoded = AuthSessionCodec.decode(raw);

    expect(decoded, session);
    expect(decoded?.user.email, testUser.email);
    expect(decoded?.user.gender, testUser.gender);
    expect(decoded?.user.image, testUser.image);
  });

  test('round-trips a session with optional profile fields missing', () {
    const user = User(id: 7, username: 'minimal');
    final raw = AuthSessionCodec.encode(
      testSession(user: user, accessToken: 'a', refreshToken: 'r'),
    );

    final decoded = AuthSessionCodec.decode(raw);

    expect(decoded?.user, user);
    expect(decoded?.user.email, isNull);
    expect(decoded?.user.firstName, isNull);
    expect(decoded?.user.image, isNull);
  });

  test('rejects invalid JSON', () {
    expect(AuthSessionCodec.decode('not-json'), isNull);
  });

  test('rejects an unknown schema version', () {
    final raw = jsonEncode(<String, dynamic>{
      'version': AuthSessionCodec.version + 1,
      'accessToken': 'a',
      'refreshToken': 'r',
      'user': <String, dynamic>{'id': 1, 'username': 'emilys'},
    });

    expect(AuthSessionCodec.decode(raw), isNull);
  });

  test('rejects a session missing required values', () {
    final base = <String, dynamic>{
      'version': AuthSessionCodec.version,
      'accessToken': 'a',
      'refreshToken': 'r',
      'user': <String, dynamic>{'id': 1, 'username': 'emilys'},
    };

    for (final key in <String>['accessToken', 'refreshToken']) {
      final broken = Map<String, dynamic>.from(base)..remove(key);
      expect(AuthSessionCodec.decode(jsonEncode(broken)), isNull, reason: key);
    }

    final missingId = Map<String, dynamic>.from(base)
      ..['user'] = <String, dynamic>{'username': 'emilys'};
    expect(AuthSessionCodec.decode(jsonEncode(missingId)), isNull);

    final missingUsername = Map<String, dynamic>.from(base)
      ..['user'] = <String, dynamic>{'id': 1};
    expect(AuthSessionCodec.decode(jsonEncode(missingUsername)), isNull);

    final blankToken = Map<String, dynamic>.from(base)..['accessToken'] = '   ';
    expect(AuthSessionCodec.decode(jsonEncode(blankToken)), isNull);
  });

  test('normalizes string ids from older stored values', () {
    final raw = jsonEncode(<String, dynamic>{
      'version': AuthSessionCodec.version,
      'accessToken': 'a',
      'refreshToken': 'r',
      'user': <String, dynamic>{'id': '42', 'username': ' emilys '},
    });

    final decoded = AuthSessionCodec.decode(raw);

    expect(decoded?.user.id, 42);
    expect(decoded?.user.username, 'emilys');
  });
}
