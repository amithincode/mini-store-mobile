import '../../domain/entities/product_page.dart';
import '../../domain/entities/product_query.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';

/// Coordinates the authenticated API with the persistent product cache.
///
/// A cache write failure never fails a successful API request: the fresh page
/// is still returned to the UI and the previous cache stays intact.
class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;

  @override
  Future<ProductPage> fetchPage({
    required String query,
    required int skip,
    required int limit,
  }) async {
    final normalized = normalizeProductQuery(query);
    final response = normalized.isEmpty
        ? await _remoteDataSource.fetchProducts(skip: skip, limit: limit)
        : await _remoteDataSource.searchProducts(
            query: normalized,
            skip: skip,
            limit: limit,
          );

    final page = response.toPage();
    await _cachePage(query: normalized, page: page, requestedSkip: skip);

    return page;
  }

  @override
  Future<ProductPage> fetchCategoryPage({
    required String slug,
    required int skip,
    required int limit,
  }) async {
    final response = await _remoteDataSource.fetchCategoryProducts(
      slug: slug,
      skip: skip,
      limit: limit,
    );

    final page = response.toPage();
    await _cachePage(query: 'category:$slug', page: page, requestedSkip: skip);

    return page;
  }

  @override
  Future<ProductPage?> readCached({required String query}) async {
    try {
      final cached = await _localDataSource.read(normalizeProductQuery(query));
      if (cached == null) {
        return null;
      }

      return ProductPage(
        products: cached.products,
        total: cached.total,
        skip: 0,
        limit: cached.limit,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _cachePage({
    required String query,
    required ProductPage page,
    required int requestedSkip,
  }) async {
    try {
      if (page.products.isEmpty && requestedSkip == 0) {
        await _localDataSource.clearQuery(query);
        return;
      }

      await _localDataSource.savePage(
        query: query,
        products: page.products,
        total: page.total,
        limit: page.limit,
        replace: requestedSkip == 0,
      );
    } catch (_) {
      // Caching is best-effort; never hide successfully fetched products.
    }
  }
}
