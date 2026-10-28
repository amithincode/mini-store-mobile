import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/storage/app_storage.dart';
import 'package:mini_store_app/features/auth/data/repositories/session_repository_impl.dart';
import 'package:mini_store_app/features/auth/data/storage/auth_session_codec.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/auth_test_doubles.dart';

Future<AppStorage> _storageWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return AppStorage.create();
}

void main() {
  test('saves, reads, and clears a session', () async {
    final storage = await _storageWith(<String, Object>{});
    final repository = SessionRepositoryImpl(storage);

    expect(await repository.read(), isNull);

    await repository.save(testSession());
    final restored = await repository.read();

    expect(restored, testSession());
    expect(storage.containsKey(AuthSessionCodec.key), isTrue);

    await repository.clear();

    expect(await repository.read(), isNull);
    expect(storage.containsKey(AuthSessionCodec.key), isFalse);
  });

  test('removes a corrupt session instead of returning it', () async {
    final storage = await _storageWith(<String, Object>{
      AuthSessionCodec.key: '{"version":1,"accessToken":"a"}',
    });
    final repository = SessionRepositoryImpl(storage);

    expect(await repository.read(), isNull);
    expect(storage.containsKey(AuthSessionCodec.key), isFalse);
  });

  test('does not touch unrelated stored values', () async {
    final storage = await _storageWith(<String, Object>{
      'unrelated': 'keep me',
      AuthSessionCodec.key: 'broken',
    });
    final repository = SessionRepositoryImpl(storage);

    await repository.read();
    await repository.save(testSession());
    await repository.clear();

    expect(storage.read<String>('unrelated'), 'keep me');
  });
}
