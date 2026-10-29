import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/product_details/domain/repositories/product_detail_repository.dart';
import 'package:mini_store_app/features/product_details/domain/usecases/get_product_detail_use_case.dart';
import 'package:mini_store_app/features/product_details/presentation/cubit/product_detail_cubit.dart';
import 'package:mini_store_app/features/product_details/presentation/cubit/product_detail_state.dart';
import 'package:mini_store_app/features/products/domain/entities/product.dart';
import 'package:mini_store_app/features/products/domain/failures/product_failure.dart';

import '../../../products/product_fixtures.dart';

class _FakeDetailRepository implements ProductDetailRepository {
  final Map<int, Product> cache = <int, Product>{};
  Future<Product> Function(int id)? onFetch;
  final List<int> fetchCalls = <int>[];

  @override
  Future<Product> fetchDetail(int id) {
    fetchCalls.add(id);
    final fetcher = onFetch;
    if (fetcher == null) {
      return Future<Product>.value(testProduct(id));
    }
    return fetcher(id);
  }

  @override
  Future<Product?> readCached(int id) async => cache[id];
}

ProductDetailCubit _cubit(_FakeDetailRepository repository) {
  return ProductDetailCubit(
    getDetail: GetProductDetailUseCase(repository),
    repository: repository,
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('first visit without cache shows a loader then the product', () async {
    final repository = _FakeDetailRepository();
    final cubit = _cubit(repository);
    final states = <ProductDetailState>[];
    cubit.stream.listen(states.add);

    await cubit.load(7);
    await _flush();

    expect(states.first, isA<ProductDetailLoading>());
    expect(states.last, isA<ProductDetailLoaded>());
    expect((states.last as ProductDetailLoaded).product.id, 7);
    expect(repository.fetchCalls, [7]);
    await cubit.close();
  });

  test('cached details render before the refresh completes', () async {
    final repository = _FakeDetailRepository()..cache[7] = testProduct(7);
    final completer = Completer<Product>();
    repository.onFetch = (_) => completer.future;
    final cubit = _cubit(repository);

    final loading = cubit.load(7);
    await _flush();

    final cached = cubit.state as ProductDetailLoaded;
    expect(cached.product.id, 7);
    expect(cached.isRefreshing, isTrue);
    expect(repository.fetchCalls, [7]);

    final fresh = Product(
      id: 7,
      title: 'Fresh title',
      category: 'groceries',
      price: 7.99,
      rating: 4,
      imageUrl: 'https://example.com/product-7.webp',
    );
    completer.complete(fresh);
    await loading;

    final refreshed = cubit.state as ProductDetailLoaded;
    expect(refreshed.isRefreshing, isFalse);
    expect(refreshed.product.title, 'Fresh title');
    await cubit.close();
  });

  test('a failed background refresh keeps the cached product', () async {
    final repository = _FakeDetailRepository()..cache[7] = testProduct(7);
    repository.onFetch = (_) =>
        Future<Product>.error(const ProductOfflineFailure());
    final cubit = _cubit(repository);

    await cubit.load(7);

    final state = cubit.state as ProductDetailLoaded;
    expect(state.product.id, 7);
    expect(state.isRefreshing, isFalse);
    expect(state.refreshFailure, isA<ProductOfflineFailure>());
    await cubit.close();
  });

  test('a first-visit server error is retryable', () async {
    final repository = _FakeDetailRepository();
    repository.onFetch = (_) =>
        Future<Product>.error(const ProductServerFailure());
    final cubit = _cubit(repository);

    await cubit.load(7);

    final state = cubit.state as ProductDetailFailure;
    expect(state.failure, isA<ProductServerFailure>());
    expect(state.canRetry, isTrue);
    await cubit.close();
  });

  test('a first-visit offline error has a dedicated state', () async {
    final repository = _FakeDetailRepository();
    repository.onFetch = (_) =>
        Future<Product>.error(const ProductOfflineFailure());
    final cubit = _cubit(repository);

    await cubit.load(7);

    expect(cubit.state, isA<ProductDetailOffline>());
    await cubit.close();
  });

  test('products are isolated by id and never leak between visits', () async {
    final repository = _FakeDetailRepository()..cache[1] = testProduct(1);
    final completer = Completer<Product>();
    repository.onFetch = (id) =>
        id == 1 ? Future<Product>.value(testProduct(1)) : completer.future;
    final cubit = _cubit(repository);

    await cubit.load(1);
    expect((cubit.state as ProductDetailLoaded).product.id, 1);

    final second = cubit.load(2);
    await _flush();

    expect(cubit.state, isA<ProductDetailLoading>());

    completer.complete(testProduct(2));
    await second;
    expect((cubit.state as ProductDetailLoaded).product.id, 2);
    await cubit.close();
  });

  test('duplicate load calls share one request', () async {
    final repository = _FakeDetailRepository();
    final completer = Completer<Product>();
    repository.onFetch = (_) => completer.future;
    final cubit = _cubit(repository);

    final first = cubit.load(7);
    final second = cubit.load(7);
    await _flush();

    expect(repository.fetchCalls, [7]);

    completer.complete(testProduct(7));
    await Future.wait([first, second]);
    await cubit.close();
  });

  test('does not emit after the cubit is closed', () async {
    final repository = _FakeDetailRepository();
    final completer = Completer<Product>();
    repository.onFetch = (_) => completer.future;
    final cubit = _cubit(repository);

    final loading = cubit.load(7);
    await _flush();
    await cubit.close();
    completer.complete(testProduct(7));

    await expectLater(loading, completes);
  });
}
