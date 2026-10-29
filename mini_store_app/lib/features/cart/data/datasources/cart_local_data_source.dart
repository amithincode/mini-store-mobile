import 'dart:convert';
import '../../../../core/storage/app_storage.dart';
import '../../domain/entities/cart_item.dart';

abstract interface class CartLocalDataSource { Future<List<CartItem>> load(); Future<void> save(List<CartItem> items); }
class SharedPreferencesCartLocalDataSource implements CartLocalDataSource {
  SharedPreferencesCartLocalDataSource(this._storage);
  static const _key = 'mini_store.cart.v1';
  final AppStorage _storage;
  @override Future<List<CartItem>> load() async {
    final raw = _storage.read<String>(_key); if (raw == null) return const [];
    try { final decoded = jsonDecode(raw); if (decoded is! List) return const [];
      return decoded.whereType<Map>().map((map) { final value = Map<String, dynamic>.from(map); return CartItem(productId: (value['id'] as num?)?.toInt() ?? 0, title: value['title'] as String? ?? '', price: (value['price'] as num?)?.toDouble() ?? 0, thumbnail: value['thumbnail'] as String? ?? '', quantity: (value['quantity'] as num?)?.toInt() ?? 0); }).where((item) => item.productId > 0 && item.quantity > 0).toList(growable: false);
    } on FormatException { return const []; }
  }
  @override Future<void> save(List<CartItem> items) => _storage.write<String>(_key, jsonEncode(items.map((item) => {'id': item.productId, 'title': item.title, 'price': item.price, 'thumbnail': item.thumbnail, 'quantity': item.quantity}).toList()));
}
