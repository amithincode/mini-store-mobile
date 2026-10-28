import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/storage/app_storage.dart';
import 'package:mini_store_app/features/products/data/datasources/product_local_data_source.dart';
import 'package:mini_store_app/features/products/domain/entities/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../product_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStorage storage;
  late SharedPreferencesProductLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    storage = await AppStorage.create();
    local = SharedPreferencesProductLocalDataSource(
      storage,
      now: () => DateTime.utc(2026, 2, 3, 4, 5),
    );
  });

  Future<void> save(
    String query,
    List<Product> products, {
    int? total,
    bool replace = true,
    int limit = 10,
  }) {
    return local.savePage(
      query: query,
      products: products,
      total: total ?? products.length,
      limit: limit,
      replace: replace,
    );
  }

  test('writes each product under its own key and reads it back', () async {
    final products = testProductsFrom(1, 10);
    await save('', products, total: 30);

    expect(storage.read<int>('mini_store.products.v1.schema'), 1);
    expect(
      storage.keys.where(
        (key) => key.startsWith('mini_store.products.v1.item.'),
      ),
      hasLength(10),
    );

    final cached = await local.read('');
    expect(cached, isNotNull);
    expect(cached!.products, hasLength(10));
    expect(cached.products.first.title, 'Product 1');
    expect(cached.total, 30);
    expect(cached.limit, 10);
    expect(cached.updatedAt, DateTime.utc(2026, 2, 3, 4, 5).toLocal());
  });

  test('keeps search caches separate by normalized query', () async {
    await save('Phone', testProductsFrom(1, 2), total: 2);
    await save('laptop', testProductsFrom(20, 3), total: 3);
    await save('', testProductsFrom(50, 1), total: 1);

    expect((await local.read('phone'))!.products, hasLength(2));
    expect((await local.read('  PHONE  '))!.products, hasLength(2));
    expect((await local.read('laptop'))!.products, hasLength(3));
    expect((await local.read(''))!.products, hasLength(1));
    expect(await local.read('tablet'), isNull);
  });

  test('appends pages and deduplicates ids', () async {
    await save('', testProductsFrom(1, 10), total: 20);
    await save('', testProductsFrom(11, 10), total: 20, replace: false);

    expect((await local.read(''))!.products, hasLength(20));

    await save('', testProductsFrom(19, 2), total: 20, replace: false);
    final cached = await local.read('');
    expect(cached!.products, hasLength(20));
    expect(cached.products.map((product) => product.id).toSet(), hasLength(20));
  });

  test('replaces the cached collection for a fresh first page', () async {
    await save('', testProductsFrom(1, 10), total: 30);
    await save('', testProductsFrom(31, 5), total: 35, replace: true);

    final cached = await local.read('');
    expect(cached!.products, hasLength(5));
    expect(cached.products.first.id, 31);
    expect(cached.total, 35);
  });

  test('clears one query without touching the others', () async {
    await save('phone', testProductsFrom(1, 2), total: 2);
    await save('laptop', testProductsFrom(20, 2), total: 2);

    await local.clearQuery('phone');

    expect(await local.read('phone'), isNull);
    expect((await local.read('laptop'))!.products, hasLength(2));
  });

  test('clearing a query removes its metadata entry', () async {
    await save('phone', testProductsFrom(1, 2), total: 2);
    await local.clearQuery('phone');

    final rawIndex = storage.read<String>('mini_store.products.v1.index');
    expect(rawIndex, isNotNull);
    expect(jsonDecode(rawIndex!), isEmpty);
  });

  test('skips a corrupted cached product instead of failing', () async {
    await save('', testProductsFrom(1, 3), total: 3);
    final itemKey = storage.keys.firstWhere(
      (key) => key.startsWith('mini_store.products.v1.item.'),
    );
    await storage.write<String>(itemKey, '{not json');

    final cached = await local.read('');
    expect(cached, isNotNull);
    expect(cached!.products, hasLength(2));
  });

  test('keeps at most ten query caches', () async {
    for (var index = 0; index < 11; index++) {
      await save('query$index', testProductsFrom(index * 10 + 1, 1), total: 1);
    }

    final metaKeys = storage.keys.where(
      (key) => key.startsWith('mini_store.products.v1.meta.'),
    );
    expect(metaKeys, hasLength(10));
  });

  test('replacing a query prunes items no longer referenced', () async {
    await save('', testProductsFrom(1, 5), total: 5);
    await save('phone', testProductsFrom(3, 2), total: 2);

    await save('', testProductsFrom(10, 2), total: 2, replace: true);

    expect(storage.containsKey('mini_store.products.v1.item.1'), isFalse);
    expect(storage.containsKey('mini_store.products.v1.item.2'), isFalse);
    expect(
      storage.containsKey('mini_store.products.v1.item.3'),
      isTrue,
      reason: 'still referenced by the phone search cache',
    );
    expect(storage.containsKey('mini_store.products.v1.item.4'), isTrue);
    expect(storage.containsKey('mini_store.products.v1.item.10'), isTrue);
    expect(storage.containsKey('mini_store.products.v1.item.11'), isTrue);
  });

  test('ignores caches written with an unknown schema', () async {
    await save('', testProductsFrom(1, 2), total: 2);
    await storage.write<int>('mini_store.products.v1.schema', 99);

    expect(await local.read(''), isNull);
  });
}
