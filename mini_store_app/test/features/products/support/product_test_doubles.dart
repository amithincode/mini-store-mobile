import 'package:mini_store_app/features/products/domain/entities/product_list_source.dart';
import 'package:mini_store_app/features/products/domain/entities/product_page.dart';
import 'package:mini_store_app/features/products/domain/entities/product_query.dart';
import 'package:mini_store_app/features/products/domain/repositories/product_repository.dart';
import 'package:mini_store_app/features/products/domain/usecases/get_cached_products_use_case.dart';
import 'package:mini_store_app/features/products/domain/usecases/get_category_products_use_case.dart';
import 'package:mini_store_app/features/products/domain/usecases/get_products_use_case.dart';
import 'package:mini_store_app/features/products/domain/usecases/search_products_use_case.dart';
import 'package:mini_store_app/features/products/presentation/cubit/product_list_cubit.dart';

typedef ProductPageFetcher =
    Future<ProductPage> Function({
      required String query,
      required int skip,
      required int limit,
    });

typedef CategoryPageFetcher =
    Future<ProductPage> Function({
      required String slug,
      required int skip,
      required int limit,
    });

/// Repository double used by cubit and widget tests.
class FakeProductRepository implements ProductRepository {
  FakeProductRepository({
    this.onFetch,
    this.onFetchCategory,
    this.cached,
    this.cachedByQuery = const <String, ProductPage>{},
  });

  ProductPageFetcher? onFetch;
  CategoryPageFetcher? onFetchCategory;
  ProductPage? cached;
  Map<String, ProductPage> cachedByQuery;
  bool throwOnCached = false;

  final List<({String query, int skip, int limit})> calls =
      <({String query, int skip, int limit})>[];
  final List<({String slug, int skip, int limit})> categoryCalls =
      <({String slug, int skip, int limit})>[];

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

  @override
  Future<ProductPage> fetchCategoryPage({
    required String slug,
    required int skip,
    required int limit,
  }) {
    categoryCalls.add((slug: slug, skip: skip, limit: limit));
    final fetcher = onFetchCategory;
    if (fetcher == null) {
      return Future<ProductPage>.value(
        ProductPage(products: const [], total: 0, skip: skip, limit: limit),
      );
    }
    return fetcher(slug: slug, skip: skip, limit: limit);
  }
}

ProductListCubit createTestProductListCubit({
  required FakeProductRepository repository,
  Duration searchDebounce = const Duration(milliseconds: 500),
  int pageSize = 10,
  ProductListSource source = const ProductListSource.catalogue(),
}) {
  return ProductListCubit(
    getProducts: GetProductsUseCase(repository),
    searchProducts: SearchProductsUseCase(repository),
    getCachedProducts: GetCachedProductsUseCase(repository),
    getCategoryProducts: GetCategoryProductsUseCase(repository),
    searchDebounce: searchDebounce,
    pageSize: pageSize,
    source: source,
  );
}
