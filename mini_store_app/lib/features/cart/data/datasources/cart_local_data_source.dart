import 'dart:convert';

import '../../../../core/storage/app_storage.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/failures/cart_storage_exception.dart';

abstract interface class CartLocalDataSource {
  Future<List<CartItem>> load();
  Future<void> save(List<CartItem> items);
}

class SharedPreferencesCartLocalDataSource implements CartLocalDataSource {
  SharedPreferencesCartLocalDataSource(this._storage);

  static const String _key = 'mini_store.cart.v1';

  final AppStorage _storage;

  @override
  Future<List<CartItem>> load() async {
    final raw = _storage.read<String>(_key);
    if (raw == null) {
      return const <CartItem>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <CartItem>[];
      }

      final byId = <int, CartItem>{};
      for (final entry in decoded.whereType<Map>()) {
        final value = Map<String, dynamic>.from(entry);
        final productId = _readInt(value['id']);
        final quantity = _readInt(value['quantity']);
        if (productId == null || quantity == null) {
          continue;
        }
        if (productId <= 0 || quantity <= 0) {
          continue;
        }

        final item = CartItem(
          productId: productId,
          title: value['title'] as String? ?? '',
          price: _readDouble(value['price']) ?? 0,
          thumbnail: value['thumbnail'] as String? ?? '',
          quantity: quantity,
        );

        // Older builds could contain duplicates; keep one line per product.
        final existing = byId[productId];
        byId[productId] = existing == null
            ? item
            : existing.copyWith(quantity: existing.quantity + quantity);
      }

      return List<CartItem>.unmodifiable(byId.values);
    } on FormatException {
      return const <CartItem>[];
    }
  }

  @override
  Future<void> save(List<CartItem> items) async {
    final encoded = jsonEncode(
      items
          .map(
            (item) => <String, dynamic>{
              'id': item.productId,
              'title': item.title,
              'price': item.price,
              'thumbnail': item.thumbnail,
              'quantity': item.quantity,
            },
          )
          .toList(growable: false),
    );

    final saved = await _storage.write<String>(_key, encoded);
    if (!saved) {
      throw const CartStorageException();
    }
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double && value.isFinite) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static double? _readDouble(Object? value) {
    if (value is num && value.isFinite) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }
}
