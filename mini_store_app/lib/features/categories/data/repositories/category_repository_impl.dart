import '../../domain/entities/product_category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_data_source.dart';
import '../datasources/category_remote_data_source.dart';

/// Cache-first category repository.
///
/// A cache write failure never hides successfully fetched categories.
class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._remote, this._local);

  final CategoryRemoteDataSource _remote;
  final CategoryLocalDataSource _local;

  @override
  Future<List<ProductCategory>> fetchCategories() async {
    final categories = await _remote.fetchCategories();
    if (categories.isEmpty) {
      return categories;
    }

    try {
      await _local.save(categories);
    } catch (_) {
      // Caching is best-effort.
    }
    return categories;
  }

  @override
  Future<List<ProductCategory>> readCached() async {
    try {
      return await _local.read();
    } catch (_) {
      return const <ProductCategory>[];
    }
  }

  @override
  Future<Map<String, String>> readCachedPreviewImages() async {
    try {
      return await _local.readPreviewImages();
    } catch (_) {
      return const <String, String>{};
    }
  }

  @override
  Future<String?> fetchPreviewImage(String slug) async {
    if (slug.trim().isEmpty) {
      return null;
    }
    try {
      final image = await _remote.fetchPreviewImage(slug);
      final trimmed = image?.trim() ?? '';
      if (trimmed.isEmpty || !trimmed.startsWith('http')) {
        return null;
      }
      return trimmed;
    } catch (_) {
      // Previews are decorative: a failed lookup leaves the icon fallback.
      return null;
    }
  }

  @override
  Future<void> savePreviewImages(Map<String, String> images) async {
    try {
      await _local.savePreviewImages(images);
    } catch (_) {
      // Caching is best-effort.
    }
  }
}
