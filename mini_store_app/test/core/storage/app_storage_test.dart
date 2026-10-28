import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/storage/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('reads and writes supported value types', () async {
    final storage = await AppStorage.create();

    expect(await storage.write<String>('name', 'Mini Store'), isTrue);
    expect(await storage.write<bool>('enabled', true), isTrue);
    expect(await storage.write<int>('count', 3), isTrue);
    expect(await storage.write<double>('ratio', 2.5), isTrue);
    expect(
      await storage.write<List<String>>('tags', <String>['new', 'sale']),
      isTrue,
    );

    expect(storage.read<String>('name'), 'Mini Store');
    expect(storage.read<bool>('enabled'), isTrue);
    expect(storage.read<int>('count'), 3);
    expect(storage.read<double>('ratio'), 2.5);
    expect(storage.read<List<String>>('tags'), <String>['new', 'sale']);
    expect(storage.containsKey('name'), isTrue);
  });

  test('removes and clears values', () async {
    final storage = await AppStorage.create();
    await storage.write<String>('name', 'Mini Store');
    await storage.write<int>('count', 3);

    expect(await storage.remove('count'), isTrue);
    expect(storage.containsKey('count'), isFalse);
    expect(await storage.clear(), isTrue);
    expect(storage.keys, isEmpty);
  });

  test('rejects unsupported value types', () async {
    final storage = await AppStorage.create();

    expect(
      () => storage.write<Map<String, int>>('map', <String, int>{'a': 1}),
      throwsArgumentError,
    );
  });
}
