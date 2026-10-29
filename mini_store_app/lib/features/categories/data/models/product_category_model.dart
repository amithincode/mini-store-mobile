import '../../domain/entities/product_category.dart';

/// Transport parsing for the plain category list endpoint.
abstract final class ProductCategoryModel {
  static List<ProductCategory> listFromJson(Object? payload) {
    if (payload is! List) {
      throw const FormatException('The categories payload is missing.');
    }

    final categories = <ProductCategory>[];
    final seen = <String>{};

    for (final raw in payload) {
      if (raw is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(raw);
      final name = _readString(map['name']);
      final slug = _readString(map['slug']).isNotEmpty
          ? _readString(map['slug'])
          : _slugify(name);

      if (slug.isEmpty || !seen.add(slug)) {
        continue;
      }

      categories.add(
        ProductCategory(
          slug: slug,
          name: name.isEmpty ? _titleize(slug) : name,
          imageUrl: _readString(map['imageUrl']),
        ),
      );
    }

    return List<ProductCategory>.unmodifiable(categories);
  }

  static Map<String, dynamic> toJson(ProductCategory category) {
    return <String, dynamic>{
      'slug': category.slug,
      'name': category.name,
      if (category.imageUrl.isNotEmpty) 'imageUrl': category.imageUrl,
    };
  }

  static ProductCategory? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    final slug = _readString(map['slug']);
    final name = _readString(map['name']);
    if (slug.isEmpty) {
      return null;
    }
    return ProductCategory(
      slug: slug,
      name: name.isEmpty ? _titleize(slug) : name,
      imageUrl: _readString(map['imageUrl']),
    );
  }

  static String _readString(Object? value) {
    return value is String ? value.trim() : '';
  }

  static String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String _titleize(String slug) {
    return slug
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
