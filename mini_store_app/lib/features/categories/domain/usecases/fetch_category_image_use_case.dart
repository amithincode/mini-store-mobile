import '../repositories/category_repository.dart';

class FetchCategoryImageUseCase {
  const FetchCategoryImageUseCase(this._repository);

  final CategoryRepository _repository;

  Future<String?> call(String slug) => _repository.fetchPreviewImage(slug);
}
