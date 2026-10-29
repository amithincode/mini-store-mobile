import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/categories/data/datasources/category_local_data_source.dart';
import 'package:mini_store_app/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:mini_store_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:mini_store_app/features/categories/domain/entities/product_category.dart';
import 'package:mini_store_app/features/products/domain/failures/product_failure.dart';

class _FakeCategoryRemote implements CategoryRemoteDataSource {
  _FakeCategoryRemote({this.result = const <ProductCategory>[]});

  List<ProductCategory> result;
  Object? failure;
  int calls = 0;

  String? previewImage;
  Object? previewFailure;
  int previewCalls = 0;
  final List<String> previewSlugs = <String>[];

  @override
  Future<List<ProductCategory>> fetchCategories() async {
    calls++;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return result;
  }

  @override
  Future<String?> fetchPreviewImage(String slug) async {
    previewCalls++;
    previewSlugs.add(slug);
    final error = previewFailure;
    if (error != null) {
      throw error;
    }
    return previewImage;
  }
}

class _FakeCategoryLocal implements CategoryLocalDataSource {
  _FakeCategoryLocal({this.stored = const <ProductCategory>[]});

  List<ProductCategory> stored;
  Map<String, String> storedPreviews = <String, String>{};
  bool failSave = false;
  bool failRead = false;
  bool failPreviewSave = false;
  bool failPreviewRead = false;
  int saves = 0;
  int previewSaves = 0;

  @override
  Future<List<ProductCategory>> read() async {
    if (failRead) {
      throw StateError('read failed');
    }
    return stored;
  }

  @override
  Future<void> save(List<ProductCategory> categories) async {
    saves++;
    if (failSave) {
      throw StateError('write failed');
    }
    stored = categories;
  }

  @override
  Future<Map<String, String>> readPreviewImages() async {
    if (failPreviewRead) {
      throw StateError('preview read failed');
    }
    return storedPreviews;
  }

  @override
  Future<void> savePreviewImages(Map<String, String> images) async {
    previewSaves++;
    if (failPreviewSave) {
      throw StateError('preview write failed');
    }
    storedPreviews = images;
  }
}

const categories = <ProductCategory>[
  ProductCategory(slug: 'beauty', name: 'Beauty'),
  ProductCategory(slug: 'fragrances', name: 'Fragrances'),
];

void main() {
  test('fetches categories and caches the successful response', () async {
    final remote = _FakeCategoryRemote(result: categories);
    final local = _FakeCategoryLocal();
    final repository = CategoryRepositoryImpl(remote, local);

    final result = await repository.fetchCategories();

    expect(result, categories);
    expect(local.saves, 1);
    expect(local.stored, categories);
  });

  test('keeps fresh categories visible when the cache write fails', () async {
    final remote = _FakeCategoryRemote(result: categories);
    final local = _FakeCategoryLocal()..failSave = true;
    final repository = CategoryRepositoryImpl(remote, local);

    expect(await repository.fetchCategories(), categories);
  });

  test('does not overwrite the cache with an empty response', () async {
    final remote = _FakeCategoryRemote();
    final local = _FakeCategoryLocal(stored: categories);
    final repository = CategoryRepositoryImpl(remote, local);

    expect(await repository.fetchCategories(), isEmpty);
    expect(local.saves, 0);
    expect(local.stored, categories);
  });

  test('returns saved categories before the network', () async {
    final local = _FakeCategoryLocal(stored: categories);
    final repository = CategoryRepositoryImpl(_FakeCategoryRemote(), local);

    expect(await repository.readCached(), categories);
  });

  test('treats a cache read failure as an empty cache', () async {
    final local = _FakeCategoryLocal(stored: categories)..failRead = true;
    final repository = CategoryRepositoryImpl(_FakeCategoryRemote(), local);

    expect(await repository.readCached(), isEmpty);
  });

  test('propagates network failures without touching the cache', () async {
    final remote = _FakeCategoryRemote()
      ..failure = const ProductOfflineFailure();
    final local = _FakeCategoryLocal(stored: categories);
    final repository = CategoryRepositoryImpl(remote, local);

    await expectLater(
      repository.fetchCategories(),
      throwsA(isA<ProductOfflineFailure>()),
    );
    expect(local.saves, 0);
    expect(local.stored, categories);
  });

  test('reads saved preview image URLs', () async {
    final local = _FakeCategoryLocal()
      ..storedPreviews = <String, String>{
        'beauty': 'https://cdn.test/beauty.webp',
      };
    final repository = CategoryRepositoryImpl(_FakeCategoryRemote(), local);

    expect(await repository.readCachedPreviewImages(), <String, String>{
      'beauty': 'https://cdn.test/beauty.webp',
    });
  });

  test('treats a preview cache read failure as empty', () async {
    final local = _FakeCategoryLocal()..failPreviewRead = true;
    final repository = CategoryRepositoryImpl(_FakeCategoryRemote(), local);

    expect(await repository.readCachedPreviewImages(), isEmpty);
  });

  test('resolves a remote preview image', () async {
    final remote = _FakeCategoryRemote()
      ..previewImage = 'https://cdn.test/beauty.webp';
    final repository = CategoryRepositoryImpl(remote, _FakeCategoryLocal());

    expect(
      await repository.fetchPreviewImage('beauty'),
      'https://cdn.test/beauty.webp',
    );
    expect(remote.previewSlugs, <String>['beauty']);
  });

  test('rejects empty, non-HTTP, and failed preview images', () async {
    final remote = _FakeCategoryRemote()..previewImage = '   ';
    final repository = CategoryRepositoryImpl(remote, _FakeCategoryLocal());

    expect(await repository.fetchPreviewImage('beauty'), isNull);

    remote.previewImage = 'not-a-url';
    expect(await repository.fetchPreviewImage('beauty'), isNull);

    remote
      ..previewImage = null
      ..previewFailure = const ProductOfflineFailure();
    expect(await repository.fetchPreviewImage('beauty'), isNull);

    expect(await repository.fetchPreviewImage('  '), isNull);
    expect(remote.previewCalls, 3);
  });

  test('persists preview URLs without surfacing cache failures', () async {
    final local = _FakeCategoryLocal();
    final repository = CategoryRepositoryImpl(_FakeCategoryRemote(), local);

    await repository.savePreviewImages(<String, String>{
      'beauty': 'https://cdn.test/beauty.webp',
    });
    expect(local.previewSaves, 1);
    expect(local.storedPreviews, isNotEmpty);

    local.failPreviewSave = true;
    await repository.savePreviewImages(<String, String>{'beauty': 'x'});
  });
}
