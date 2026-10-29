import 'dart:convert';

import '../../../../core/storage/app_storage.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/failures/wishlist_storage_exception.dart';

abstract interface class WishlistLocalDataSource {
  Future<List<WishlistItem>> load();
  Future<void> save(List<WishlistItem> items);
}

class SharedPreferencesWishlistLocalDataSource
    implements WishlistLocalDataSource {
  SharedPreferencesWishlistLocalDataSource(this._storage);

  static const String _key = 'mini_store.wishlist.v1';

  final AppStorage _storage;

  @override
  Future<List<WishlistItem>> load() async {
    final raw = _storage.read<String>(_key);
    if (raw == null) {
      return const <WishlistItem>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <WishlistItem>[];
      }

      final byId = <int, WishlistItem>{};
      for (final entry in decoded.whereType<Map>()) {
        final value = Map<String, dynamic>.from(entry);
        final productId = _readInt(value['id']);
        if (productId == null || productId <= 0) {
          continue;
        }

        byId.putIfAbsent(
          productId,
          () => WishlistItem(
            productId: productId,
            title: value['title'] as String? ?? '',
            price: _readDouble(value['price']) ?? 0,
            thumbnail: value['thumbnail'] as String? ?? '',
            rating: _readDouble(value['rating']) ?? 0,
            category: value['category'] as String? ?? '',
            addedAt:
                DateTime.tryParse(value['addedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
      }

      return List<WishlistItem>.unmodifiable(byId.values);
    } on FormatException {
      return const <WishlistItem>[];
    }
  }

  @override
  Future<void> save(List<WishlistItem> items) async {
    final encoded = jsonEncode(
      items
          .map(
            (item) => <String, dynamic>{
              'id': item.productId,
              'title': item.title,
              'price': item.price,
              'thumbnail': item.thumbnail,
              'rating': item.rating,
              'category': item.category,
              'addedAt': item.addedAt.toIso8601String(),
            },
          )
          .toList(growable: false),
    );

    final saved = await _storage.write<String>(_key, encoded);
    if (!saved) {
      throw const WishlistStorageException();
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
