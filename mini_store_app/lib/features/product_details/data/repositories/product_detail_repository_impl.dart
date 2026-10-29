import '../../../products/domain/entities/product.dart';
import '../../domain/repositories/product_detail_repository.dart';
import '../datasources/product_detail_local_data_source.dart';
import '../datasources/product_detail_remote_data_source.dart';

class ProductDetailRepositoryImpl implements ProductDetailRepository {
  const ProductDetailRepositoryImpl(this._remote, this._local);
  final ProductDetailRemoteDataSource _remote;
  final ProductDetailLocalDataSource _local;
  @override
  Future<Product> fetchDetail(int id) async {
    final product = await _remote.fetchDetail(id);
    try {
      await _local.save(product);
    } catch (_) {}
    return product;
  }

  @override
  Future<Product?> readCached(int id) async {
    try {
      return await _local.read(id);
    } catch (_) {
      return null;
    }
  }
}
