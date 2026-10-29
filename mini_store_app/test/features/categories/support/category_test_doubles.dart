import 'package:mini_store_app/features/categories/domain/entities/product_category.dart';
import 'package:mini_store_app/features/categories/domain/repositories/category_repository.dart';
import 'package:mini_store_app/features/categories/domain/usecases/fetch_category_image_use_case.dart';
import 'package:mini_store_app/features/categories/domain/usecases/get_cached_categories_use_case.dart';
import 'package:mini_store_app/features/categories/domain/usecases/get_cached_category_images_use_case.dart';
import 'package:mini_store_app/features/categories/domain/usecases/get_categories_use_case.dart';
import 'package:mini_store_app/features/categories/domain/usecases/save_category_images_use_case.dart';
import 'package:mini_store_app/features/categories/presentation/cubit/categories_cubit.dart';

/// In-memory [CategoryRepository] for cubit and screen tests.
class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository({
    this.cached = const <ProductCategory>[],
    this.remote = const <ProductCategory>[],
  });

  List<ProductCategory> cached;
  List<ProductCategory> remote;
  Future<List<ProductCategory>> Function()? onFetch;
  Map<String, String> cachedPreviews = <String, String>{};
  int fetchCalls = 0;
  int previewCalls = 0;

  @override
  Future<List<ProductCategory>> fetchCategories() async {
    fetchCalls++;
    return onFetch?.call() ?? remote;
  }

  @override
  Future<List<ProductCategory>> readCached() async => cached;

  @override
  Future<Map<String, String>> readCachedPreviewImages() async => cachedPreviews;

  @override
  Future<String?> fetchPreviewImage(String slug) async {
    previewCalls++;
    return cachedPreviews[slug];
  }

  @override
  Future<void> savePreviewImages(Map<String, String> images) async {
    cachedPreviews = Map<String, String>.of(images);
  }
}

/// Builds a cubit wired to [repository] without touching the service locator.
CategoriesCubit createTestCategoriesCubit(FakeCategoryRepository repository) {
  return CategoriesCubit(
    getCategories: GetCategoriesUseCase(repository),
    getCachedCategories: GetCachedCategoriesUseCase(repository),
    getCachedImages: GetCachedCategoryImagesUseCase(repository),
    fetchImage: FetchCategoryImageUseCase(repository),
    saveImages: SaveCategoryImagesUseCase(repository),
  );
}

/// Categories whose preview images are empty, so widget tests never wait on a
/// network image.
List<ProductCategory> testCategories(int count) {
  return List<ProductCategory>.generate(
    count,
    (index) => ProductCategory(
      slug: 'category-${index + 1}',
      name: 'Category ${index + 1}',
    ),
    growable: false,
  );
}
