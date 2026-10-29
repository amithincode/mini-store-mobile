import 'dart:convert';
import '../../../../core/storage/app_storage.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/domain/entities/product.dart';

abstract interface class ProductDetailLocalDataSource {
  Future<Product?> read(int id);
  Future<void> save(Product product);
}

class SharedPreferencesProductDetailLocalDataSource
    implements ProductDetailLocalDataSource {
  SharedPreferencesProductDetailLocalDataSource(this._storage);
  final AppStorage _storage;
  static const _prefix = 'mini_store.product_detail.v1.';
  static const _listPrefix = 'mini_store.products.v1.item.';
  @override
  Future<Product?> read(int id) async {
    for (final key in ['$_prefix$id', '$_listPrefix$id']) {
      final raw = _storage.read<String>(key);
      if (raw == null) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return ProductModel.fromJson(
            Map<String, dynamic>.from(decoded),
          ).toEntity();
        }
      } on FormatException {
        /* Ignore malformed cache entries. */
      }
    }
    return null;
  }

  @override
  Future<void> save(Product product) => _storage.write<String>(
    '$_prefix${product.id}',
    jsonEncode(ProductModel.fromEntity(product).toJson()),
  );
}
