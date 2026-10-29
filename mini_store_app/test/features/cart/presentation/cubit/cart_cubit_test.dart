import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/cart/domain/entities/cart_item.dart';
import 'package:mini_store_app/features/cart/domain/failures/cart_storage_exception.dart';
import 'package:mini_store_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:mini_store_app/features/cart/presentation/cubit/cart_cubit.dart';

import '../../../products/product_fixtures.dart';

class _FakeCartRepository implements CartRepository {
  List<CartItem> stored = const <CartItem>[];
  bool failSave = false;
  bool failLoad = false;
  final List<List<CartItem>> saved = <List<CartItem>>[];

  @override
  Future<List<CartItem>> loadCart() async {
    if (failLoad) {
      throw const CartStorageException('Could not restore the cart.');
    }
    return stored;
  }

  @override
  Future<void> saveCart(List<CartItem> items) async {
    if (failSave) {
      throw const CartStorageException();
    }
    stored = items;
    saved.add(items);
  }
}

void main() {
  test('restores the saved cart after a restart', () async {
    final repository = _FakeCartRepository()
      ..stored = const [
        CartItem(
          productId: 2,
          title: 'Saved product',
          price: 12.5,
          thumbnail: 'https://example.com/2.webp',
          quantity: 3,
        ),
      ];
    final cubit = CartCubit(repository);

    expect(cubit.state.isLoading, isTrue);
    await cubit.loadCart();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.items.single.productId, 2);
    expect(cubit.state.itemCount, 3);
    await cubit.close();
  });

  test('adds a product and increments it without duplicates', () async {
    final repository = _FakeCartRepository();
    final cubit = CartCubit(repository);
    await cubit.loadCart();
    final product = testProduct(5);

    expect(await cubit.addItem(product), isTrue);
    expect(await cubit.addItem(product), isTrue);

    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.items.single.productId, 5);
    expect(cubit.state.items.single.quantity, 2);
    expect(cubit.state.items.single.title, product.title);
    expect(repository.saved, hasLength(2));
    await cubit.close();
  });

  test('increments, decrements, and removes at zero', () async {
    final repository = _FakeCartRepository();
    final cubit = CartCubit(repository);
    await cubit.loadCart();
    await cubit.addItem(testProduct(1));
    await cubit.addItem(testProduct(1));

    expect(await cubit.increment(1), isTrue);
    expect(cubit.state.itemCount, 3);

    expect(await cubit.decrement(1), isTrue);
    expect(cubit.state.itemCount, 2);

    await cubit.decrement(1);
    await cubit.decrement(1);

    expect(cubit.state.items, isEmpty);
    expect(cubit.state.itemCount, 0);
    expect(repository.stored, isEmpty);
    await cubit.close();
  });

  test('removes an entire line and updates totals', () async {
    final repository = _FakeCartRepository();
    final cubit = CartCubit(repository);
    await cubit.loadCart();
    await cubit.addItem(testProduct(1));
    await cubit.addItem(testProduct(1));
    await cubit.addItem(testProduct(2));

    expect(cubit.state.itemCount, 3);
    expect(cubit.state.totalPrice, closeTo(1.99 * 2 + 2.99, 0.0001));
    expect(cubit.state.quantityFor(1), 2);
    expect(cubit.state.itemFor(2)!.lineTotal, closeTo(2.99, 0.0001));

    expect(await cubit.remove(1), isTrue);

    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.quantityFor(1), 0);
    expect(cubit.state.totalPrice, closeTo(2.99, 0.0001));
    await cubit.close();
  });

  test(
    'a storage failure keeps the previous cart and reports failure',
    () async {
      final repository = _FakeCartRepository();
      final cubit = CartCubit(repository);
      await cubit.loadCart();
      await cubit.addItem(testProduct(1));
      final before = cubit.state.items;

      repository.failSave = true;
      final result = await cubit.addItem(testProduct(2));

      expect(result, isFalse);
      expect(cubit.state.items, before);
      expect(cubit.state.itemCount, 1);
      expect(cubit.state.isMutating, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
      await cubit.close();
    },
  );

  test('clearing persists an empty cart', () async {
    final repository = _FakeCartRepository();
    final cubit = CartCubit(repository);
    await cubit.loadCart();
    await cubit.addItem(testProduct(1));

    expect(await cubit.clear(), isTrue);

    expect(cubit.state.items, isEmpty);
    expect(repository.stored, isEmpty);
    await cubit.close();
  });

  test('a failed restore leaves an empty, usable cart', () async {
    final repository = _FakeCartRepository()..failLoad = true;
    final cubit = CartCubit(repository);

    await cubit.loadCart();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.errorMessage, isNotNull);
    await cubit.close();
  });

  test('overlapping adds are serialized into one line', () async {
    final repository = _FakeCartRepository();
    final cubit = CartCubit(repository);
    await cubit.loadCart();
    final product = testProduct(3);

    await Future.wait([
      cubit.addItem(product),
      cubit.addItem(product),
      cubit.addItem(product),
    ]);

    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.items.single.quantity, 3);
    await cubit.close();
  });
}
