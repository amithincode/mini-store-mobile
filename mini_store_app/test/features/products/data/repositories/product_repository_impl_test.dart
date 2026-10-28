import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/products/data/datasources/product_local_data_source.dart';
import 'package:mini_store_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:mini_store_app/features/products/domain/failures/product_failure.dart';

import '../../product_fixtures.dart';
import '../../support/product_data_source_fakes.dart';

void main() {
  late FakeProductRemoteDataSource remote;
  late FakeProductLocalDataSource local;
  late ProductRepositoryImpl repository;

  setUp(() {
    remote = FakeProductRemoteDataSource();
    local = FakeProductLocalDataSource();
    repository = ProductRepositoryImpl(remote, local);
  });

  test('loads the first list page and caches it', () async {
    remote.onList = (skip, limit) => responseWith(
      testProductsFrom(1, 10),
      total: 30,
      skip: skip,
      limit: limit,
    );

    final page = await repository.fetchPage(query: '', skip: 0, limit: 10);

    expect(page.products, hasLength(10));
    expect(page.total, 30);
    expect(page.hasMore, isTrue);
    expect(remote.calls.single.isSearch, isFalse);
    expect(remote.calls.single.skip, 0);
    expect(local.saves.single.replace, isTrue);
    expect(local.cache[''], isNotNull);
    expect(local.cache['']!.products, hasLength(10));
  });

  test('normalizes search queries and uses the search endpoint', () async {
    remote.onSearch = (query, skip, limit) => responseWith(
      testProductsFrom(50, 2),
      total: 2,
      skip: skip,
      limit: limit,
    );

    final page = await repository.fetchPage(
      query: '  PHONE  ',
      skip: 0,
      limit: 10,
    );

    expect(page.products, hasLength(2));
    expect(remote.calls.single.isSearch, isTrue);
    expect(remote.calls.single.query, 'phone');
    expect(local.cache['phone'], isNotNull);
  });

  test('appends pagination pages to the cached collection', () async {
    remote.onList = (skip, limit) => responseWith(
      testProductsFrom(skip + 1, 10),
      total: 30,
      skip: skip,
      limit: limit,
    );

    await repository.fetchPage(query: '', skip: 0, limit: 10);
    await repository.fetchPage(query: '', skip: 10, limit: 10);

    expect(local.saves.last.replace, isFalse);
    expect(local.cache['']!.products, hasLength(20));
    expect(local.cache['']!.total, 30);
  });

  test('clears the query cache after a successful empty search', () async {
    remote.onSearch = (query, skip, limit) => responseWith(
      testProductsFrom(1, 2),
      total: 2,
      skip: skip,
      limit: limit,
    );
    await repository.fetchPage(query: 'phone', skip: 0, limit: 10);
    expect(local.cache['phone'], isNotNull);

    remote.onSearch = (query, skip, limit) =>
        responseWith(const [], total: 0, skip: skip, limit: limit);
    await repository.fetchPage(query: 'phone', skip: 0, limit: 10);

    expect(local.cache['phone'], isNull);
    expect(local.cleared, contains('phone'));
  });

  test('keeps the cache untouched when a refresh fails offline', () async {
    remote.onList = (skip, limit) => responseWith(
      testProductsFrom(1, 10),
      total: 30,
      skip: skip,
      limit: limit,
    );
    await repository.fetchPage(query: '', skip: 0, limit: 10);

    remote.onList = (skip, limit) => throw const ProductOfflineFailure();

    await expectLater(
      repository.fetchPage(query: '', skip: 0, limit: 10),
      throwsA(isA<ProductOfflineFailure>()),
    );
    expect(local.cache['']!.products, hasLength(10));
    expect(local.saves, hasLength(1));
  });

  test('returns fresh products even when the cache write fails', () async {
    local.throwOnSave = true;
    remote.onList = (skip, limit) => responseWith(
      testProductsFrom(1, 5),
      total: 5,
      skip: skip,
      limit: limit,
    );

    final page = await repository.fetchPage(query: '', skip: 0, limit: 10);

    expect(page.products, hasLength(5));
  });

  test('reads cached products as a page with pagination metadata', () async {
    local.cache['phone'] = CachedProductPage(
      products: testProductsFrom(1, 4),
      total: 12,
      limit: 10,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    final page = await repository.readCached(query: ' PHONE ');

    expect(page, isNotNull);
    expect(page!.products, hasLength(4));
    expect(page.total, 12);
    expect(page.skip, 0);
    expect(page.hasMore, isTrue);
  });
}
