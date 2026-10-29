import '../../../products/domain/entities/product.dart';

abstract interface class ProductDetailRepository {
  Future<Product> fetchDetail(int id);
  Future<Product?> readCached(int id);
}
