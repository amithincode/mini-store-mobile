import '../entities/product_page.dart';

/// Domain contract for product listing, search, and cached reads.
///
/// Implementations coordinate the remote API with the persistent cache; the
/// presentation layer never touches Dio or storage directly.
abstract interface class ProductRepository {
  /// Fetches one page for [query]. An empty query loads the normal list.
  Future<ProductPage> fetchPage({
    required String query,
    required int skip,
    required int limit,
  });

  /// Fetches one page of products for a category slug.
  Future<ProductPage> fetchCategoryPage({
    required String slug,
    required int skip,
    required int limit,
  });

  /// Reads previously cached products for [query], or `null` when absent.
  Future<ProductPage?> readCached({required String query});
}
