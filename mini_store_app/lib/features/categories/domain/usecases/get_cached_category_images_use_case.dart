import '../repositories/category_repository.dart';

class GetCachedCategoryImagesUseCase {
  const GetCachedCategoryImagesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Map<String, String>> call() => _repository.readCachedPreviewImages();
}
