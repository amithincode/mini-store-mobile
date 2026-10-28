import '../entities/product_page.dart';
import '../repositories/product_repository.dart';

/// Loads a page of the normal product catalogue.
class GetProductsUseCase {
  const GetProductsUseCase(this._repository);

  final ProductRepository _repository;

  Future<ProductPage> call({required int skip, required int limit}) {
    return _repository.fetchPage(query: '', skip: skip, limit: limit);
  }
}
