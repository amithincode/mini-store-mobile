import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/storage/app_storage.dart';
import 'package:mini_store_app/features/categories/data/datasources/category_local_data_source.dart';
import 'package:mini_store_app/features/categories/domain/entities/product_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStorage storage;
  late SharedPreferencesCategoryLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    storage = await AppStorage.create();
    local = SharedPreferencesCategoryLocalDataSource(storage);
  });

  const categories = <ProductCategory>[
    ProductCategory(slug: 'beauty', name: 'Beauty'),
    ProductCategory(slug: 'home-decoration', name: 'Home Decoration'),
  ];

  test('round-trips the category list', () async {
    await local.save(categories);

    final restored = await local.read();

    expect(restored, categories);
  });

  test('returns an empty list when nothing is cached', () async {
    expect(await local.read(), isEmpty);
  });

  test('ignores a corrupted cache value', () async {
    await storage.write<String>('mini_store.categories.v1', '{not json');

    expect(await local.read(), isEmpty);
  });

  test('ignores a cache value that is not a list', () async {
    await storage.write<String>(
      'mini_store.categories.v1',
      '{"slug":"beauty"}',
    );

    expect(await local.read(), isEmpty);
  });

  test('round-trips the preview image map', () async {
    await local.savePreviewImages(<String, String>{
      'beauty': 'https://cdn.test/beauty.webp',
      'home-decoration': 'https://cdn.test/home.webp',
    });

    expect(await local.readPreviewImages(), <String, String>{
      'beauty': 'https://cdn.test/beauty.webp',
      'home-decoration': 'https://cdn.test/home.webp',
    });
  });

  test('returns an empty preview map when nothing is cached', () async {
    expect(await local.readPreviewImages(), isEmpty);
  });

  test('ignores corrupted preview cache values', () async {
    await storage.write<String>('mini_store.category_images.v1', '{not json');
    expect(await local.readPreviewImages(), isEmpty);

    await storage.write<String>('mini_store.category_images.v1', '[1,2,3]');
    expect(await local.readPreviewImages(), isEmpty);
  });

  test('drops non-string or empty preview entries', () async {
    await storage.write<String>(
      'mini_store.category_images.v1',
      '{"beauty":"https://cdn.test/beauty.webp","empty":"  ","number":42}',
    );

    expect(await local.readPreviewImages(), <String, String>{
      'beauty': 'https://cdn.test/beauty.webp',
    });
  });
}
