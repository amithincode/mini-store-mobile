import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/categories/domain/entities/product_category.dart';
import 'package:mini_store_app/features/categories/domain/repositories/category_repository.dart';
import 'package:mini_store_app/features/categories/domain/usecases/fetch_category_image_use_case.dart';
import 'package:mini_store_app/features/categories/domain/usecases/get_cached_categories_use_case.dart';
import 'package:mini_store_app/features/categories/domain/usecases/get_cached_category_images_use_case.dart';
import 'package:mini_store_app/features/categories/domain/usecases/get_categories_use_case.dart';
import 'package:mini_store_app/features/categories/domain/usecases/save_category_images_use_case.dart';
import 'package:mini_store_app/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:mini_store_app/features/categories/presentation/cubit/categories_state.dart';
import 'package:mini_store_app/features/products/domain/failures/product_failure.dart';

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository({this.cached = const <ProductCategory>[]});

  List<ProductCategory> cached;
  Future<List<ProductCategory>> Function()? onFetch;
  Future<String?> Function(String slug)? onPreview;
  Map<String, String> cachedPreviews = <String, String>{};
  Map<String, String>? savedPreviews;
  int fetchCalls = 0;
  int previewCalls = 0;
  int saveCalls = 0;

  @override
  Future<List<ProductCategory>> fetchCategories() async {
    fetchCalls++;
    return onFetch?.call() ?? const <ProductCategory>[];
  }

  @override
  Future<List<ProductCategory>> readCached() async => cached;

  @override
  Future<Map<String, String>> readCachedPreviewImages() async => cachedPreviews;

  @override
  Future<String?> fetchPreviewImage(String slug) async {
    previewCalls++;
    return onPreview?.call(slug);
  }

  @override
  Future<void> savePreviewImages(Map<String, String> images) async {
    saveCalls++;
    savedPreviews = images;
  }
}

const ProductCategory _beauty = ProductCategory(slug: 'beauty', name: 'Beauty');
const ProductCategory _home = ProductCategory(
  slug: 'home-decoration',
  name: 'Home Decoration',
);

CategoriesCubit _cubit(_FakeCategoryRepository repository) {
  return CategoriesCubit(
    getCategories: GetCategoriesUseCase(repository),
    getCachedCategories: GetCachedCategoriesUseCase(repository),
    getCachedImages: GetCachedCategoryImagesUseCase(repository),
    fetchImage: FetchCategoryImageUseCase(repository),
    saveImages: SaveCategoryImagesUseCase(repository),
  );
}

void main() {
  test('shows cached categories before refreshing', () async {
    final repository = _FakeCategoryRepository(cached: const [_beauty]);
    repository.onFetch = () async => const [_beauty, _home];
    final cubit = _cubit(repository);
    final states = <CategoriesState>[];
    cubit.stream.listen(states.add);

    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(states.first, isA<CategoriesLoaded>());
    expect((states.first as CategoriesLoaded).isRefreshing, isTrue);
    expect((states.first as CategoriesLoaded).categories, const [_beauty]);
    expect(states.last, isA<CategoriesLoaded>());
    expect((states.last as CategoriesLoaded).isRefreshing, isFalse);
    expect((states.last as CategoriesLoaded).categories, const [
      _beauty,
      _home,
    ]);
    await cubit.close();
  });

  test('keeps cached categories when the refresh is offline', () async {
    final repository = _FakeCategoryRepository(cached: const [_beauty]);
    repository.onFetch = () async => throw const ProductOfflineFailure();
    final cubit = _cubit(repository);

    await cubit.load();

    final state = cubit.state as CategoriesLoaded;
    expect(state.categories, const [_beauty]);
    expect(state.refreshFailure, isA<ProductOfflineFailure>());
    expect(state.isRefreshing, isFalse);
    await cubit.close();
  });

  test('reports offline when no cache exists', () async {
    final repository = _FakeCategoryRepository();
    repository.onFetch = () async => throw const ProductOfflineFailure();
    final cubit = _cubit(repository);

    await cubit.load();

    expect(cubit.state, isA<CategoriesOffline>());
    await cubit.close();
  });

  test(
    'reports a retryable failure for a server error without cache',
    () async {
      final repository = _FakeCategoryRepository();
      repository.onFetch = () async => throw const ProductServerFailure();
      final cubit = _cubit(repository);

      await cubit.load();

      final state = cubit.state as CategoriesFailure;
      expect(state.failure, isA<ProductServerFailure>());
      expect(state.canRetry, isTrue);
      await cubit.close();
    },
  );

  test('does not start overlapping loads', () async {
    final repository = _FakeCategoryRepository();
    repository.onFetch = () async => const [_beauty];
    final cubit = _cubit(repository);

    await Future.wait([cubit.load(), cubit.load()]);

    expect(repository.fetchCalls, 1);
    expect(cubit.state, isA<CategoriesLoaded>());
    await cubit.close();
  });

  test('attaches cached and freshly fetched preview images', () async {
    const cachedBeauty = ProductCategory(
      slug: 'beauty',
      name: 'Beauty',
      imageUrl: 'https://cdn.test/beauty.webp',
    );
    final repository = _FakeCategoryRepository(cached: const [cachedBeauty]);
    repository.onFetch = () async => const [_beauty, _home];
    repository.cachedPreviews = <String, String>{
      'beauty': 'https://cdn.test/beauty.webp',
    };
    repository.onPreview = (slug) async =>
        slug == 'home-decoration' ? 'https://cdn.test/home.webp' : null;
    final cubit = _cubit(repository);

    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = cubit.state as CategoriesLoaded;
    expect(state.categories[0].imageUrl, 'https://cdn.test/beauty.webp');
    expect(state.categories[1].imageUrl, 'https://cdn.test/home.webp');
    expect(repository.saveCalls, 1);
    expect(repository.savedPreviews, <String, String>{
      'beauty': 'https://cdn.test/beauty.webp',
      'home-decoration': 'https://cdn.test/home.webp',
    });
    await cubit.close();
  });

  test('keeps the list usable when a preview lookup fails', () async {
    final repository = _FakeCategoryRepository();
    repository.onFetch = () async => const [_beauty];
    repository.onPreview = (slug) async => throw const ProductOfflineFailure();
    final cubit = _cubit(repository);

    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = cubit.state as CategoriesLoaded;
    expect(state.categories.single.imageUrl, isEmpty);
    expect(repository.previewCalls, 1);
    await cubit.close();
  });

  test(
    'never resolves previews for categories that already have one',
    () async {
      const withImage = ProductCategory(
        slug: 'beauty',
        name: 'Beauty',
        imageUrl: 'https://cdn.test/beauty.webp',
      );
      final repository = _FakeCategoryRepository();
      repository.onFetch = () async => const [withImage];
      final cubit = _cubit(repository);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(repository.previewCalls, 0);
      expect(repository.saveCalls, 0);
      await cubit.close();
    },
  );
}
