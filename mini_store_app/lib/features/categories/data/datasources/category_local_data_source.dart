import 'dart:convert';

import '../../../../core/storage/app_storage.dart';
import '../../domain/entities/product_category.dart';
import '../models/product_category_model.dart';

abstract interface class CategoryLocalDataSource {
  Future<List<ProductCategory>> read();
  Future<void> save(List<ProductCategory> categories);

  /// Locally resolved preview image URLs keyed by category slug.
  Future<Map<String, String>> readPreviewImages();
  Future<void> savePreviewImages(Map<String, String> images);
}

/// The full category list is small (about two dozen short records), so a single
/// JSON value is appropriate; product payloads remain in the chunked cache.
class SharedPreferencesCategoryLocalDataSource
    implements CategoryLocalDataSource {
  SharedPreferencesCategoryLocalDataSource(this._storage);

  static const String _key = 'mini_store.categories.v1';
  static const String _previewKey = 'mini_store.category_images.v1';

  final AppStorage _storage;

  @override
  Future<List<ProductCategory>> read() async {
    final raw = _storage.read<String>(_key);
    if (raw == null) {
      return const <ProductCategory>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ProductCategory>[];
      }
      return List<ProductCategory>.unmodifiable(
        decoded.map(ProductCategoryModel.fromJson).whereType<ProductCategory>(),
      );
    } on FormatException {
      return const <ProductCategory>[];
    }
  }

  @override
  Future<void> save(List<ProductCategory> categories) async {
    final encoded = jsonEncode(
      categories.map(ProductCategoryModel.toJson).toList(growable: false),
    );
    final saved = await _storage.write<String>(_key, encoded);
    if (!saved) {
      throw StateError('Could not cache categories.');
    }
  }

  @override
  Future<Map<String, String>> readPreviewImages() async {
    final raw = _storage.read<String>(_previewKey);
    if (raw == null) {
      return const <String, String>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const <String, String>{};
      }

      final images = <String, String>{};
      for (final entry in decoded.entries) {
        final slug = entry.key;
        final url = entry.value;
        if (slug is String &&
            slug.trim().isNotEmpty &&
            url is String &&
            url.trim().isNotEmpty) {
          images[slug.trim()] = url.trim();
        }
      }
      return Map<String, String>.unmodifiable(images);
    } on FormatException {
      return const <String, String>{};
    }
  }

  @override
  Future<void> savePreviewImages(Map<String, String> images) async {
    final encoded = jsonEncode(images);
    final saved = await _storage.write<String>(_previewKey, encoded);
    if (!saved) {
      throw StateError('Could not cache category previews.');
    }
  }
}
