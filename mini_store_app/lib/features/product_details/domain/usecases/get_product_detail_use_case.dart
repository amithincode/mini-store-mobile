import '../../../products/domain/entities/product.dart';
import '../repositories/product_detail_repository.dart';

class GetProductDetailUseCase {
  const GetProductDetailUseCase(this._repository);
  final ProductDetailRepository _repository;
  Future<Product> call(int id) => _repository.fetchDetail(id);
}
