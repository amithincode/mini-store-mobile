import '../entities/product_page.dart';
import '../repositories/product_repository.dart';

class GetCategoryProductsUseCase {
  const GetCategoryProductsUseCase(this._repository);

  final ProductRepository _repository;

  Future<ProductPage> call({
    required String slug,
    required int skip,
    required int limit,
  }) {
    return _repository.fetchCategoryPage(slug: slug, skip: skip, limit: limit);
  }
}
