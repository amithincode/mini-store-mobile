import '../entities/product_page.dart';
import '../repositories/product_repository.dart';

/// Loads a page of search results for a query.
class SearchProductsUseCase {
  const SearchProductsUseCase(this._repository);

  final ProductRepository _repository;

  Future<ProductPage> call({
    required String query,
    required int skip,
    required int limit,
  }) {
    return _repository.fetchPage(query: query, skip: skip, limit: limit);
  }
}
