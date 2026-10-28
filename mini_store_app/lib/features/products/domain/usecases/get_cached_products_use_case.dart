import '../entities/product_page.dart';
import '../repositories/product_repository.dart';

/// Reads locally cached products for immediate display before a refresh.
class GetCachedProductsUseCase {
  const GetCachedProductsUseCase(this._repository);

  final ProductRepository _repository;

  Future<ProductPage?> call({required String query}) {
    return _repository.readCached(query: query);
  }
}
