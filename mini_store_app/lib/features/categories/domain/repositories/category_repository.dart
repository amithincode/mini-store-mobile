import '../entities/product_category.dart';

/// Domain contract for the category list.
abstract interface class CategoryRepository {
  /// Fetches the latest categories from the API and caches them.
  Future<List<ProductCategory>> fetchCategories();

  /// Returns previously saved categories, or an empty list.
  Future<List<ProductCategory>> readCached();

  /// Returns locally saved category preview image URLs keyed by slug.
  Future<Map<String, String>> readCachedPreviewImages();

  /// Resolves the first product image for [slug], or `null`.
  Future<String?> fetchPreviewImage(String slug);

  /// Persists the resolved preview URL map; failures are best-effort.
  Future<void> savePreviewImages(Map<String, String> images);
}
