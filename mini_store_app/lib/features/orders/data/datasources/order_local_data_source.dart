import 'dart:convert';

import '../../../../core/storage/app_storage.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_line_item.dart';
import '../../domain/failures/order_storage_exception.dart';

abstract interface class OrderLocalDataSource {
  Future<List<Order>> load();
  Future<void> save(List<Order> orders);
}

/// Persists completed orders as a JSON list, newest first.
class SharedPreferencesOrderLocalDataSource implements OrderLocalDataSource {
  SharedPreferencesOrderLocalDataSource(this._storage);

  static const String _key = 'mini_store.orders.v1';

  final AppStorage _storage;

  @override
  Future<List<Order>> load() async {
    final raw = _storage.read<String>(_key);
    if (raw == null) {
      return const <Order>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <Order>[];
      }

      final orders = <Order>[];
      for (final entry in decoded.whereType<Map>()) {
        final value = Map<String, dynamic>.from(entry);
        final orderNumber = (value['orderNumber'] as String? ?? '').trim();
        if (orderNumber.isEmpty) {
          continue;
        }

        final items = <OrderLineItem>[];
        final rawItems = value['items'];
        if (rawItems is List) {
          for (final rawItem in rawItems.whereType<Map>()) {
            final line = Map<String, dynamic>.from(rawItem);
            final productId = _readInt(line['id']);
            final quantity = _readInt(line['quantity']);
            if (productId == null || productId <= 0) {
              continue;
            }
            if (quantity == null || quantity <= 0) {
              continue;
            }
            items.add(
              OrderLineItem(
                productId: productId,
                title: line['title'] as String? ?? '',
                price: _readDouble(line['price']) ?? 0,
                thumbnail: line['thumbnail'] as String? ?? '',
                quantity: quantity,
              ),
            );
          }
        }

        // Receipts without line items cannot be shown usefully.
        if (items.isEmpty) {
          continue;
        }

        orders.add(
          Order(
            orderNumber: orderNumber,
            placedAt:
                DateTime.tryParse(value['placedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
            items: List<OrderLineItem>.unmodifiable(items),
          ),
        );
      }

      return List<Order>.unmodifiable(orders);
    } on FormatException {
      return const <Order>[];
    }
  }

  @override
  Future<void> save(List<Order> orders) async {
    final encoded = jsonEncode(
      orders
          .map(
            (order) => <String, dynamic>{
              'orderNumber': order.orderNumber,
              'placedAt': order.placedAt.toIso8601String(),
              'items': order.items
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
            },
          )
          .toList(growable: false),
    );

    final saved = await _storage.write<String>(_key, encoded);
    if (!saved) {
      throw const OrderStorageException();
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
