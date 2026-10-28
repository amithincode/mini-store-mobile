import 'package:mini_store_app/features/products/domain/entities/product_page.dart';
import 'package:mini_store_app/features/products/domain/entities/product_query.dart';
import 'package:mini_store_app/features/products/domain/repositories/product_repository.dart';
import 'package:mini_store_app/features/products/domain/usecases/get_cached_products_use_case.dart';
import 'package:mini_store_app/features/products/domain/usecases/get_products_use_case.dart';
import 'package:mini_store_app/features/products/domain/usecases/search_products_use_case.dart';
import 'package:mini_store_app/features/products/presentation/cubit/product_list_cubit.dart';

typedef ProductPageFetcher =
    Future<ProductPage> Function({
      required String query,
      required int skip,
      required int limit,
    });

/// Repository double used by cubit and widget tests.
class FakeProductRepository implements ProductRepository {
  FakeProductRepository({
    this.onFetch,
    this.cached,
    this.cachedByQuery = const <String, ProductPage>{},
  });

  ProductPageFetcher? onFetch;
  ProductPage? cached;
  Map<String, ProductPage> cachedByQuery;
  bool throwOnCached = false;

  final List<({String query, int skip, int limit})> calls =
      <({String query, int skip, int limit})>[];

  @override
  Future<ProductPage> fetchPage({
    required String query,
    required int skip,
    required int limit,
  }) {
    final normalized = normalizeProductQuery(query);
    calls.add((query: normalized, skip: skip, limit: limit));

    final fetcher = onFetch;
    if (fetcher == null) {
      return Future<ProductPage>.value(
        ProductPage(products: const [], total: 0, skip: skip, limit: limit),
      );
    }

    return fetcher(query: normalized, skip: skip, limit: limit);
  }

  @override
  Future<ProductPage?> readCached({required String query}) async {
    if (throwOnCached) {
      throw StateError('Cache read failed');
    }
    return cachedByQuery[normalizeProductQuery(query)] ?? cached;
  }
}

ProductListCubit createTestProductListCubit({
  required FakeProductRepository repository,
  Duration searchDebounce = const Duration(milliseconds: 500),
  int pageSize = 10,
}) {
  return ProductListCubit(
    getProducts: GetProductsUseCase(repository),
    searchProducts: SearchProductsUseCase(repository),
    getCachedProducts: GetCachedProductsUseCase(repository),
    searchDebounce: searchDebounce,
    pageSize: pageSize,
  );
}
