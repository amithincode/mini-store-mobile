import '../entities/product_category.dart';
import '../repositories/category_repository.dart';

class GetCachedCategoriesUseCase {
  const GetCachedCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<List<ProductCategory>> call() => _repository.readCached();
}
