import 'package:mini_store_app/features/products/data/datasources/product_local_data_source.dart';
import 'package:mini_store_app/features/products/data/datasources/product_remote_data_source.dart';
import 'package:mini_store_app/features/products/data/models/product_list_response_model.dart';
import 'package:mini_store_app/features/products/data/models/product_model.dart';
import 'package:mini_store_app/features/products/domain/entities/product.dart';

ProductListResponseModel responseWith(
  List<Product> products, {
  required int total,
  int skip = 0,
  int limit = 10,
}) {
  return ProductListResponseModel(
    products: products.map(ProductModel.fromEntity).toList(growable: false),
    total: total,
    skip: skip,
    limit: limit,
  );
}

/// Remote double that records search vs list requests.
class FakeProductRemoteDataSource implements ProductRemoteDataSource {
  FakeProductRemoteDataSource({this.onList, this.onSearch});

  ProductListResponseModel Function(int skip, int limit)? onList;
  ProductListResponseModel Function(String query, int skip, int limit)?
  onSearch;
  ProductListResponseModel Function(String slug, int skip, int limit)?
  onCategory;

  final List<({String query, int skip, int limit, bool isSearch})> calls =
      <({String query, int skip, int limit, bool isSearch})>[];
  final List<({String slug, int skip, int limit})> categoryCalls =
      <({String slug, int skip, int limit})>[];

  @override
  Future<ProductListResponseModel> fetchProducts({
    required int skip,
    required int limit,
  }) async {
    calls.add((query: '', skip: skip, limit: limit, isSearch: false));
    return onList?.call(skip, limit) ??
        ProductListResponseModel(
          products: const [],
          total: 0,
          skip: skip,
          limit: limit,
        );
  }

  @override
  Future<ProductListResponseModel> searchProducts({
    required String query,
    required int skip,
    required int limit,
  }) async {
    calls.add((query: query, skip: skip, limit: limit, isSearch: true));
    return onSearch?.call(query, skip, limit) ??
        ProductListResponseModel(
          products: const [],
          total: 0,
          skip: skip,
          limit: limit,
        );
  }

  @override
  Future<ProductListResponseModel> fetchCategoryProducts({
    required String slug,
    required int skip,
    required int limit,
  }) async {
    categoryCalls.add((slug: slug, skip: skip, limit: limit));
    return onCategory?.call(slug, skip, limit) ??
        ProductListResponseModel(
          products: const [],
          total: 0,
          skip: skip,
          limit: limit,
        );
  }
}

/// In-memory local double with append/replace semantics.
class FakeProductLocalDataSource implements ProductLocalDataSource {
  final Map<String, CachedProductPage> cache = <String, CachedProductPage>{};
  final List<({String query, int count, bool replace})> saves =
      <({String query, int count, bool replace})>[];
  final List<String> cleared = <String>[];
  bool throwOnSave = false;

  @override
  Future<CachedProductPage?> read(String query) async => cache[query];

  @override
  Future<void> savePage({
    required String query,
    required List<Product> products,
    required int total,
    required int limit,
    required bool replace,
  }) async {
    saves.add((query: query, count: products.length, replace: replace));
    if (throwOnSave) {
      throw StateError('Cache write failed');
    }

    if (products.isEmpty && replace) {
      cache.remove(query);
      return;
    }

    final existing = replace ? <Product>[] : (cache[query]?.products ?? []);
    final seen = existing.map((product) => product.id).toSet();
    final merged = <Product>[...existing];
    for (final product in products) {
      if (seen.add(product.id)) {
        merged.add(product);
      }
    }

    cache[query] = CachedProductPage(
      products: List<Product>.unmodifiable(merged),
      total: total < merged.length ? merged.length : total,
      limit: limit,
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  Future<void> clearQuery(String query) async {
    cleared.add(query);
    cache.remove(query);
  }
}
