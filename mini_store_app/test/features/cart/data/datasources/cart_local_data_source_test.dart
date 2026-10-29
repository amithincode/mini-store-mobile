import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/storage/app_storage.dart';
import 'package:mini_store_app/features/cart/data/datasources/cart_local_data_source.dart';
import 'package:mini_store_app/features/cart/domain/entities/cart_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStorage storage;
  late SharedPreferencesCartLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    storage = await AppStorage.create();
    local = SharedPreferencesCartLocalDataSource(storage);
  });

  const items = <CartItem>[
    CartItem(
      productId: 3,
      title: 'Cooking oil',
      price: 4.99,
      thumbnail: 'https://example.com/3.webp',
      quantity: 2,
    ),
    CartItem(
      productId: 9,
      title: 'Mascara',
      price: 9.99,
      thumbnail: 'https://example.com/9.webp',
      quantity: 1,
    ),
  ];

  test('persists and restores every cart field', () async {
    await local.save(items);

    final restored = await local.load();

    expect(restored, hasLength(2));
    expect(restored.first.productId, 3);
    expect(restored.first.title, 'Cooking oil');
    expect(restored.first.price, 4.99);
    expect(restored.first.thumbnail, 'https://example.com/3.webp');
    expect(restored.first.quantity, 2);
  });

  test('merges duplicate product ids from an older build', () async {
    await storage.write<String>(
      'mini_store.cart.v1',
      jsonEncode([
        {'id': 3, 'title': 'A', 'price': 1, 'thumbnail': '', 'quantity': 1},
        {'id': 3, 'title': 'A', 'price': 1, 'thumbnail': '', 'quantity': 2},
      ]),
    );

    final restored = await local.load();

    expect(restored, hasLength(1));
    expect(restored.single.quantity, 3);
  });

  test('skips malformed and non-positive entries', () async {
    await storage.write<String>(
      'mini_store.cart.v1',
      jsonEncode([
        {'id': 0, 'quantity': 1},
        {'id': 4, 'quantity': 0},
        {'id': 5, 'title': 'Good', 'price': 2, 'quantity': 2},
        'not-a-map',
      ]),
    );

    final restored = await local.load();

    expect(restored, hasLength(1));
    expect(restored.single.productId, 5);
    expect(restored.single.quantity, 2);
  });

  test('returns an empty cart for corrupted storage', () async {
    await storage.write<String>('mini_store.cart.v1', '{broken');

    expect(await local.load(), isEmpty);
  });
}
