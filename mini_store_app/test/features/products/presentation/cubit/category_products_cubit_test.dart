import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/products/domain/entities/product_list_source.dart';
import 'package:mini_store_app/features/products/domain/entities/product_page.dart';
import 'package:mini_store_app/features/products/domain/failures/product_failure.dart';
import 'package:mini_store_app/features/products/presentation/cubit/product_list_state.dart';

import '../../product_fixtures.dart';
import '../../support/product_test_doubles.dart';

const String _slug = 'home-decoration';

ProductPage _page({required int skip, required int total, required int count}) {
  return ProductPage(
    products: testProductsFrom(skip + 1, count),
    total: total,
    skip: skip,
    limit: 10,
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('loads category products with the slug instead of the name', () async {
    final repository = FakeProductRepository();
    repository
        .onFetchCategory = ({required slug, required skip, required limit}) {
      expect(slug, _slug);
      return Future<ProductPage>.value(_page(skip: skip, total: 10, count: 10));
    };
    final cubit = createTestProductListCubit(
      repository: repository,
      source: const ProductListSource.category(_slug),
    );

    await cubit.loadInitial();

    expect(repository.categoryCalls.single.slug, _slug);
    expect(repository.calls, isEmpty);
    final state = cubit.state as ProductListLoaded;
    expect(state.products, hasLength(10));
    await cubit.close();
  });

  test('shows the category cache before the network refresh', () async {
    final repository = FakeProductRepository()
      ..cachedByQuery = {
        'category:$_slug': _page(skip: 0, total: 20, count: 10),
      };
    final completer = Completer<ProductPage>();
    repository.onFetchCategory =
        ({required slug, required skip, required limit}) {
          return completer.future;
        };
    final cubit = createTestProductListCubit(
      repository: repository,
      source: const ProductListSource.category(_slug),
    );

    final loading = cubit.loadInitial();
    await _flush();

    final cached = cubit.state as ProductListLoaded;
    expect(cached.isRefreshing, isTrue);
    expect(cached.products, hasLength(10));

    completer.complete(_page(skip: 0, total: 20, count: 10));
    await loading;

    final refreshed = cubit.state as ProductListLoaded;
    expect(refreshed.isRefreshing, isFalse);
    expect(refreshed.total, 20);
    await cubit.close();
  });

  test(
    'paginates with the slug and keeps products when the next page fails',
    () async {
      var failNextPage = true;
      final repository = FakeProductRepository();
      repository.onFetchCategory =
          ({required slug, required skip, required limit}) {
            if (skip == 10 && failNextPage) {
              return Future<ProductPage>.error(const ProductServerFailure());
            }
            return Future<ProductPage>.value(
              _page(skip: skip, total: 15, count: skip == 0 ? 10 : 5),
            );
          };
      final cubit = createTestProductListCubit(
        repository: repository,
        source: const ProductListSource.category(_slug),
      );

      await cubit.loadInitial();
      await cubit.loadMore();

      var state = cubit.state as ProductListLoaded;
      expect(state.products, hasLength(10));
      expect(state.paginationFailure, isA<ProductServerFailure>());
      expect(state.isLoadingMore, isFalse);

      failNextPage = false;
      await cubit.retryPagination();

      state = cubit.state as ProductListLoaded;
      expect(state.products, hasLength(15));
      expect(state.paginationFailure, isNull);
      expect(repository.categoryCalls.map((call) => call.skip), [0, 10, 10]);
      expect(
        repository.categoryCalls.every((call) => call.slug == _slug),
        isTrue,
      );
      await cubit.close();
    },
  );

  test('never mixes one category cache with another', () async {
    final repository = FakeProductRepository()
      ..cachedByQuery = {
        'category:beauty': _page(skip: 0, total: 10, count: 10),
      };
    final completer = Completer<ProductPage>();
    repository.onFetchCategory =
        ({required slug, required skip, required limit}) {
          return completer.future;
        };

    final beauty = createTestProductListCubit(
      repository: repository,
      source: const ProductListSource.category('beauty'),
    );
    final home = createTestProductListCubit(
      repository: repository,
      source: const ProductListSource.category(_slug),
    );

    final beautyLoading = beauty.loadInitial();
    await _flush();

    expect(beauty.state, isA<ProductListLoaded>());
    expect((beauty.state as ProductListLoaded).isRefreshing, isTrue);

    final homeLoading = home.loadInitial();
    await _flush();

    expect(home.state, isA<ProductListLoading>());

    completer.complete(_page(skip: 0, total: 10, count: 10));
    await beautyLoading;
    await homeLoading;
    await beauty.close();
    await home.close();
  });

  test('reports a first-page failure without cache', () async {
    final repository = FakeProductRepository();
    repository.onFetchCategory =
        ({required slug, required skip, required limit}) {
          return Future<ProductPage>.error(const ProductOfflineFailure());
        };
    final cubit = createTestProductListCubit(
      repository: repository,
      source: const ProductListSource.category(_slug),
    );

    await cubit.loadInitial();

    expect(cubit.state, isA<ProductListOfflineEmpty>());
    await cubit.close();
  });

  test('ignores search input in a category listing', () async {
    final repository = FakeProductRepository();
    repository
        .onFetchCategory = ({required slug, required skip, required limit}) {
      return Future<ProductPage>.value(_page(skip: skip, total: 10, count: 10));
    };
    final cubit = createTestProductListCubit(
      repository: repository,
      source: const ProductListSource.category(_slug),
    );
    await cubit.loadInitial();

    cubit
      ..search('shoes')
      ..submitSearch('shoes')
      ..clearSearch();
    await _flush();

    expect(repository.calls, isEmpty);
    expect(repository.categoryCalls, hasLength(1));
    await cubit.close();
  });
}
