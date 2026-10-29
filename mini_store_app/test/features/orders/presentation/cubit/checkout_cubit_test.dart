import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/cart/domain/entities/cart_item.dart';
import 'package:mini_store_app/features/cart/domain/failures/cart_storage_exception.dart';
import 'package:mini_store_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:mini_store_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:mini_store_app/features/orders/domain/services/order_number_generator.dart';
import 'package:mini_store_app/features/orders/domain/usecases/place_order_use_case.dart';
import 'package:mini_store_app/features/orders/presentation/cubit/checkout_cubit.dart';
import 'package:mini_store_app/features/orders/presentation/cubit/checkout_state.dart';

import '../../../products/product_fixtures.dart';

class _FakeCartRepository implements CartRepository {
  List<CartItem> stored = const <CartItem>[];
  bool failSave = false;
  final List<List<CartItem>> saved = <List<CartItem>>[];

  @override
  Future<List<CartItem>> loadCart() async => stored;

  @override
  Future<void> saveCart(List<CartItem> items) async {
    if (failSave) {
      throw const CartStorageException();
    }
    stored = items;
    saved.add(items);
  }
}

class _SequenceGenerator implements OrderNumberGenerator {
  _SequenceGenerator(this._numbers);

  final List<String> _numbers;
  int _index = 0;

  @override
  String next() => _numbers[_index++];
}

Future<({CartCubit cart, CheckoutCubit checkout, _FakeCartRepository repo})>
_setUp({
  Duration delay = Duration.zero,
  List<String> numbers = const ['MS-20481'],
}) async {
  final repo = _FakeCartRepository();
  final cart = CartCubit(repo);
  await cart.loadCart();
  final checkout = CheckoutCubit(
    cart: cart,
    placeOrder: PlaceOrderUseCase(
      _SequenceGenerator(numbers),
      processingDelay: delay,
    ),
  );
  return (cart: cart, checkout: checkout, repo: repo);
}

void main() {
  test('blocks an empty cart', () async {
    final setup = await _setUp();

    final result = await setup.checkout.confirmOrder();

    expect(result, isFalse);
    expect(setup.checkout.state, isA<CheckoutFailure>());
    expect(setup.checkout.completedOrder, isNull);
    await setup.checkout.close();
    await setup.cart.close();
  });

  test(
    'snapshots items and total, clears the cart, and reports success',
    () async {
      final setup = await _setUp();
      await setup.cart.addItem(testProduct(1));
      await setup.cart.addItem(testProduct(1));
      await setup.cart.addItem(testProduct(2));

      final result = await setup.checkout.confirmOrder();

      expect(result, isTrue);
      final state = setup.checkout.state as CheckoutSuccess;
      expect(state.order.orderNumber, 'MS-20481');
      expect(state.order.itemCount, 3);
      expect(state.order.totalPaid, closeTo(1.99 * 2 + 2.99, 0.0001));
      expect(setup.checkout.completedOrder, state.order);
      expect(setup.cart.state.items, isEmpty);
      expect(setup.cart.state.itemCount, 0);
      expect(setup.repo.stored, isEmpty);
      await setup.checkout.close();
      await setup.cart.close();
    },
  );

  test('reports processing before success', () async {
    final setup = await _setUp(delay: const Duration(milliseconds: 30));
    await setup.cart.addItem(testProduct(1));
    final states = <CheckoutState>[];
    setup.checkout.stream.listen(states.add);

    await setup.checkout.confirmOrder();
    await Future<void>.delayed(Duration.zero);

    expect(states.first, isA<CheckoutProcessing>());
    expect((states.first as CheckoutProcessing).itemCount, 1);
    expect(states.last, isA<CheckoutSuccess>());
    await setup.checkout.close();
    await setup.cart.close();
  });

  test('blocks duplicate submissions', () async {
    final setup = await _setUp(
      delay: const Duration(milliseconds: 30),
      numbers: const ['MS-10001', 'MS-10002'],
    );
    await setup.cart.addItem(testProduct(1));

    final first = setup.checkout.confirmOrder();
    final second = await setup.checkout.confirmOrder();
    final firstResult = await first;

    expect(firstResult, isTrue);
    expect(second, isFalse);
    expect(
      (setup.checkout.state as CheckoutSuccess).order.orderNumber,
      'MS-10001',
    );
    await setup.checkout.close();
    await setup.cart.close();
  });

  test('cart persistence failure prevents a false success', () async {
    final setup = await _setUp();
    await setup.cart.addItem(testProduct(1));
    setup.repo.failSave = true;

    final result = await setup.checkout.confirmOrder();

    expect(result, isFalse);
    expect(setup.checkout.state, isA<CheckoutFailure>());
    expect(setup.checkout.completedOrder, isNull);
    expect(setup.cart.state.items, hasLength(1));
    await setup.checkout.close();
    await setup.cart.close();
  });

  test('reset clears the completed order', () async {
    final setup = await _setUp();
    await setup.cart.addItem(testProduct(1));
    await setup.checkout.confirmOrder();

    setup.checkout.reset();

    expect(setup.checkout.completedOrder, isNull);
    expect(setup.checkout.state, isA<CheckoutIdle>());
    await setup.checkout.close();
    await setup.cart.close();
  });

  test('order numbers stay in the readable MS- format and change', () {
    final generator = RandomOrderNumberGenerator(random: Random(7));

    final first = generator.next();
    final second = generator.next();

    expect(first, matches(RegExp(r'^MS-\d{5}$')));
    expect(second, matches(RegExp(r'^MS-\d{5}$')));
    expect(second, isNot(first));
  });
}
