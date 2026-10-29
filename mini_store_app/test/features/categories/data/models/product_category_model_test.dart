import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/categories/data/models/product_category_model.dart';

void main() {
  test('parses the plain category list and keeps the API slug', () {
    final categories = ProductCategoryModel.listFromJson([
      {'slug': 'home-decoration', 'name': 'Home Decoration', 'url': 'ignored'},
      {'slug': 'beauty', 'name': 'Beauty'},
    ]);

    expect(categories, hasLength(2));
    expect(categories.first.slug, 'home-decoration');
    expect(categories.first.name, 'Home Decoration');
    expect(categories.last.slug, 'beauty');
  });

  test('deduplicates slugs and derives a slug when only a name is present', () {
    final categories = ProductCategoryModel.listFromJson([
      {'slug': 'beauty', 'name': 'Beauty'},
      {'slug': 'beauty', 'name': 'Beauty again'},
      {'name': 'Kitchen Accessories'},
    ]);

    expect(categories.map((category) => category.slug), [
      'beauty',
      'kitchen-accessories',
    ]);
  });

  test('rejects a payload that is not a list', () {
    expect(
      () => ProductCategoryModel.listFromJson({'categories': <Object>[]}),
      throwsFormatException,
    );
  });

  test('round-trips through JSON', () {
    final decoded = ProductCategoryModel.fromJson({
      'slug': 'mens-shoes',
      'name': 'Mens Shoes',
    });

    expect(decoded, isNotNull);
    expect(decoded!.slug, 'mens-shoes');
    expect(ProductCategoryModel.toJson(decoded), {
      'slug': 'mens-shoes',
      'name': 'Mens Shoes',
    });
  });

  test('parses and serializes a locally resolved preview image', () {
    final decoded = ProductCategoryModel.fromJson({
      'slug': 'beauty',
      'name': 'Beauty',
      'imageUrl': 'https://cdn.test/beauty.webp',
    });

    expect(decoded, isNotNull);
    expect(decoded!.imageUrl, 'https://cdn.test/beauty.webp');
    expect(ProductCategoryModel.toJson(decoded), {
      'slug': 'beauty',
      'name': 'Beauty',
      'imageUrl': 'https://cdn.test/beauty.webp',
    });
  });

  test('defaults a missing preview image to an empty value', () {
    final categories = ProductCategoryModel.listFromJson([
      {'slug': 'beauty', 'name': 'Beauty'},
    ]);

    expect(categories.single.imageUrl, isEmpty);
  });
}
