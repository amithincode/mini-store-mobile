import '../repositories/category_repository.dart';

class SaveCategoryImagesUseCase {
  const SaveCategoryImagesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<void> call(Map<String, String> images) =>
      _repository.savePreviewImages(images);
}
