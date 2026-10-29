import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/products/domain/entities/product.dart';
import 'package:mini_store_app/features/products/domain/entities/product_page.dart';
import 'package:mini_store_app/features/products/domain/failures/product_failure.dart';
import 'package:mini_store_app/features/products/presentation/cubit/product_list_state.dart';

import '../../product_fixtures.dart';
import '../../support/product_test_doubles.dart';

ProductPage _page(
  List<Product> products, {
  required int total,
  int skip = 0,
  int limit = 10,
}) {
  return ProductPage(
    products: products,
    total: total,
    skip: skip,
    limit: limit,
  );
}

/// Lets queued async work (cache reads and fetches) progress.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('loads the first page', () async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async =>
          _page(testProductsFrom(1, 10), total: 30, skip: skip, limit: limit),
    );
    final cubit = createTestProductListCubit(repository: repository);

    await cubit.loadInitial();

    final state = cubit.state;
    expect(state, isA<ProductListLoaded>());
    state as ProductListLoaded;
    expect(state.products, hasLength(10));
    expect(state.total, 30);
    expect(state.hasMore, isTrue);
    expect(state.isRefreshing, isFalse);
    expect(repository.calls.single.query, isEmpty);
    expect(repository.calls.single.skip, 0);
    expect(repository.calls.single.limit, 10);

    await cubit.close();
  });

  test('shows cached products first, then refreshes them', () async {
    final completer = Completer<ProductPage>();
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) =>
          completer.future,
      cachedByQuery: <String, ProductPage>{
        '': _page(testProductsFrom(1, 3), total: 3),
      },
    );
    final cubit = createTestProductListCubit(repository: repository);

    final load = cubit.loadInitial();
    await _flush();

    final cachedState = cubit.state as ProductListLoaded;
    expect(cachedState.products, hasLength(3));
    expect(cachedState.isRefreshing, isTrue);

    completer.complete(_page(testProductsFrom(1, 10), total: 20));
    await load;

    final freshState = cubit.state as ProductListLoaded;
    expect(freshState.products, hasLength(10));
    expect(freshState.total, 20);
    expect(freshState.isRefreshing, isFalse);

    await cubit.close();
  });

  test('shows an offline state without cache and retries', () async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async =>
          throw const ProductOfflineFailure(),
    );
    final cubit = createTestProductListCubit(repository: repository);

    await cubit.loadInitial();

    expect(cubit.state, isA<ProductListOfflineEmpty>());
    expect((cubit.state as ProductListOfflineEmpty).isSearch, isFalse);

    repository.onFetch =
        ({required query, required skip, required limit}) async =>
            _page(testProductsFrom(1, 4), total: 4, skip: skip, limit: limit);

    await cubit.retryInitial();

    expect(cubit.state, isA<ProductListLoaded>());
    expect((cubit.state as ProductListLoaded).products, hasLength(4));

    await cubit.close();
  });

  test('keeps cached products when an offline refresh fails', () async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async =>
          throw const ProductOfflineFailure(),
      cachedByQuery: <String, ProductPage>{
        '': _page(testProductsFrom(1, 5), total: 5),
      },
    );
    final cubit = createTestProductListCubit(repository: repository);

    await cubit.loadInitial();

    final state = cubit.state as ProductListLoaded;
    expect(state.products, hasLength(5));
    expect(state.notice, isNotNull);
    expect(state.notice!.type, ProductListNoticeType.offlineShowingSaved);

    await cubit.close();
  });

  test(
    'keeps cached products when a refresh fails for another reason',
    () async {
      final repository = FakeProductRepository(
        onFetch: ({required query, required skip, required limit}) async =>
            throw const ProductServerFailure(),
        cachedByQuery: <String, ProductPage>{
          '': _page(testProductsFrom(1, 5), total: 8),
        },
      );
      final cubit = createTestProductListCubit(repository: repository);

      await cubit.loadInitial();

      final state = cubit.state as ProductListLoaded;
      expect(state.products, hasLength(5));
      expect(state.notice!.type, ProductListNoticeType.refreshFailed);
      expect(state.hasMore, isTrue);

      await cubit.close();
    },
  );

  test('keeps cached search results when the search refresh fails', () async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async =>
          throw const ProductServerFailure(),
      cachedByQuery: <String, ProductPage>{
        'phone': _page(testProductsFrom(1, 2), total: 2),
      },
    );
    final cubit = createTestProductListCubit(repository: repository);

    cubit.submitSearch('Phone');
    await _flush();
    await _flush();

    final state = cubit.state as ProductListLoaded;
    expect(state.query, 'phone');
    expect(state.products, hasLength(2));
    expect(state.notice!.type, ProductListNoticeType.searchRefreshFailed);

    await cubit.close();
  });

  test('never treats an authentication failure as offline', () async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async =>
          throw const ProductAuthFailure(),
    );
    final cubit = createTestProductListCubit(repository: repository);

    await cubit.loadInitial();

    final state = cubit.state as ProductListFailure;
    expect(state.failure, isA<ProductAuthFailure>());
    expect(state.failure.isOffline, isFalse);
    expect(state.canRetry, isFalse);

    await cubit.close();
  });

  test('debounces search input by 500 ms and skips intermediate terms', () {
    fakeAsync((async) {
      final repository = FakeProductRepository(
        onFetch: ({required query, required skip, required limit}) async =>
            _page(testProductsFrom(1, 2), total: 2, skip: skip, limit: limit),
      );
      final cubit = createTestProductListCubit(repository: repository);

      unawaited(cubit.loadInitial());
      async.flushMicrotasks();
      repository.calls.clear();

      cubit.search('p');
      async.elapse(const Duration(milliseconds: 250));
      cubit.search('ph');
      async.elapse(const Duration(milliseconds: 490));

      expect(repository.calls, isEmpty);

      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();

      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.query, 'ph');
    });
  });

  test('ignores stale search responses', () async {
    final completers = <String, Completer<ProductPage>>{};
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) {
        final completer = Completer<ProductPage>();
        completers[query] = completer;
        return completer.future;
      },
    );
    final cubit = createTestProductListCubit(repository: repository);

    final initial = cubit.loadInitial();
    await _flush();
    completers['']!.complete(_page(testProductsFrom(1, 2), total: 2));
    await initial;

    cubit.submitSearch('phone');
    await _flush();
    cubit.submitSearch('tablet');
    await _flush();

    expect(completers.containsKey('phone'), isTrue);
    expect(completers.containsKey('tablet'), isTrue);

    completers['phone']!.complete(_page(testProductsFrom(10, 3), total: 3));
    await _flush();

    final whileStale = cubit.state;
    expect(whileStale.query, 'tablet');

    completers['tablet']!.complete(_page(testProductsFrom(20, 4), total: 4));
    await _flush();

    final state = cubit.state as ProductListLoaded;
    expect(state.query, 'tablet');
    expect(state.products.first.id, 20);

    await cubit.close();
  });

  test('clear search cancels the debounce and keeps the catalogue visible', () {
    fakeAsync((async) {
      final repository = FakeProductRepository(
        onFetch: ({required query, required skip, required limit}) async =>
            _page(
              query.isEmpty ? testProductsFrom(1, 4) : testProductsFrom(20, 2),
              total: query.isEmpty ? 4 : 2,
              skip: skip,
              limit: limit,
            ),
      );
      final cubit = createTestProductListCubit(repository: repository);

      unawaited(cubit.loadInitial());
      async.flushMicrotasks();
      repository.calls.clear();

      cubit.search('phone');
      cubit.clearSearch();
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();

      expect(repository.calls, isEmpty);
      expect(cubit.state.query, isEmpty);
      expect(cubit.state, isA<ProductListLoaded>());
      expect((cubit.state as ProductListLoaded).products, hasLength(4));
    });
  });

  test('distinguishes an empty search from an empty catalogue', () async {
    final searchRepository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async =>
          _page(const <Product>[], total: 0, skip: skip, limit: limit),
    );
    final searchCubit = createTestProductListCubit(
      repository: searchRepository,
    );

    searchCubit.submitSearch('zzzz');
    await _flush();
    await _flush();

    final searchState = searchCubit.state as ProductListEmpty;
    expect(searchState.isSearch, isTrue);
    expect(searchState.query, 'zzzz');

    final catalogueCubit = createTestProductListCubit(
      repository: FakeProductRepository(
        onFetch: ({required query, required skip, required limit}) async =>
            _page(const <Product>[], total: 0, skip: skip, limit: limit),
      ),
    );

    await catalogueCubit.loadInitial();

    final catalogueState = catalogueCubit.state as ProductListEmpty;
    expect(catalogueState.isSearch, isFalse);

    await searchCubit.close();
    await catalogueCubit.close();
  });

  test('appends pages using the loaded count and stops at total', () async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async {
        final remaining = (25 - skip).clamp(0, 10).toInt();
        return _page(
          testProductsFrom(skip + 1, remaining),
          total: 25,
          skip: skip,
          limit: limit,
        );
      },
    );
    final cubit = createTestProductListCubit(repository: repository);

    await cubit.loadInitial();
    expect((cubit.state as ProductListLoaded).products, hasLength(10));

    await cubit.loadMore();

    var state = cubit.state as ProductListLoaded;
    expect(repository.calls.last.skip, 10);
    expect(state.products, hasLength(20));
    expect(state.hasMore, isTrue);

    await cubit.loadMore();

    state = cubit.state as ProductListLoaded;
    expect(repository.calls.last.skip, 20);
    expect(state.products, hasLength(25));
    expect(state.hasMore, isFalse);

    final callCount = repository.calls.length;
    await cubit.loadMore();
    expect(repository.calls, hasLength(callCount));

    await cubit.close();
  });

  test('deduplicates products across pages', () async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async {
        if (skip == 0) {
          return _page(testProductsFrom(1, 10), total: 12);
        }
        return _page(testProductsFrom(10, 3), total: 12, skip: skip);
      },
    );
    final cubit = createTestProductListCubit(repository: repository);

    await cubit.loadInitial();
    await cubit.loadMore();

    final state = cubit.state as ProductListLoaded;
    expect(state.products, hasLength(12));
    expect(state.products.map((product) => product.id).toSet(), hasLength(12));
    expect(state.hasMore, isFalse);

    await cubit.close();
  });

  test(
    'retains products when a page fails and retries the same offset',
    () async {
      var failNextPage = true;
      final repository = FakeProductRepository(
        onFetch: ({required query, required skip, required limit}) async {
          if (skip > 0 && failNextPage) {
            throw const ProductOfflineFailure();
          }
          return _page(
            testProductsFrom(skip + 1, 10),
            total: 20,
            skip: skip,
            limit: limit,
          );
        },
      );
      final cubit = createTestProductListCubit(repository: repository);

      await cubit.loadInitial();
      await cubit.loadMore();

      var state = cubit.state as ProductListLoaded;
      expect(state.products, hasLength(10));
      expect(state.paginationFailure, isA<ProductOfflineFailure>());
      expect(state.isLoadingMore, isFalse);

      failNextPage = false;
      await cubit.retryPagination();

      state = cubit.state as ProductListLoaded;
      expect(state.paginationFailure, isNull);
      expect(state.products, hasLength(20));
      expect(state.hasMore, isFalse);
      expect(repository.calls.last.skip, 10);

      await cubit.close();
    },
  );

  test('does not update the UI after logout', () async {
    final completer = Completer<ProductPage>();
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) =>
          completer.future,
    );
    final cubit = createTestProductListCubit(repository: repository);

    final load = cubit.loadInitial();
    await _flush();
    expect(cubit.state, isA<ProductListLoading>());

    await cubit.close();
    completer.complete(_page(testProductsFrom(1, 5), total: 5));
    await load;

    expect(cubit.state, isA<ProductListLoading>());
  });
}
