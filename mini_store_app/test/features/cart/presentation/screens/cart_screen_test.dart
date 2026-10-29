import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_store_app/app/router/app_router.dart';
import 'package:mini_store_app/features/cart/domain/entities/cart_item.dart';
import 'package:mini_store_app/features/cart/domain/failures/cart_storage_exception.dart';
import 'package:mini_store_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:mini_store_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:mini_store_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:mini_store_app/features/orders/domain/entities/order.dart';
import 'package:mini_store_app/features/orders/domain/repositories/order_repository.dart';
import 'package:mini_store_app/features/orders/domain/services/order_number_generator.dart';
import 'package:mini_store_app/features/orders/domain/usecases/place_order_use_case.dart';
import 'package:mini_store_app/features/orders/presentation/cubit/checkout_cubit.dart';
import 'package:mini_store_app/features/orders/presentation/cubit/checkout_state.dart';
import 'package:mini_store_app/features/orders/presentation/cubit/order_history_cubit.dart';
import 'package:mini_store_app/features/orders/presentation/screens/order_success_screen.dart';

class _FakeCartRepository implements CartRepository {
  _FakeCartRepository(this.stored, {this.failLoad = false});

  List<CartItem> stored;
  final bool failLoad;

  @override
  Future<List<CartItem>> loadCart() async {
    if (failLoad) {
      throw const CartStorageException();
    }
    return stored;
  }

  @override
  Future<void> saveCart(List<CartItem> items) async {
    stored = items;
  }
}

class _FixedGenerator implements OrderNumberGenerator {
  @override
  String next() => 'MS-30001';
}

class _FakeOrderRepository implements OrderRepository {
  List<Order> stored = const <Order>[];

  @override
  Future<List<Order>> loadOrders() async => stored;

  @override
  Future<void> saveOrders(List<Order> orders) async {
    stored = orders;
  }
}

const CartItem _item = CartItem(
  productId: 3,
  title: 'Cooking oil',
  price: 4.99,
  thumbnail: '',
  quantity: 2,
);

Future<
  ({CartCubit cart, CheckoutCubit checkout, _FakeCartRepository repository})
>
_pumpCart(WidgetTester tester, {bool failLoad = false}) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = _FakeCartRepository([_item], failLoad: failLoad);
  final cart = CartCubit(repository);
  await cart.loadCart();
  final history = OrderHistoryCubit(_FakeOrderRepository());
  await history.loadOrders();
  final checkout = CheckoutCubit(
    cart: cart,
    placeOrder: PlaceOrderUseCase(
      _FixedGenerator(),
      processingDelay: Duration.zero,
    ),
    history: history,
  );

  Widget shell(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>.value(value: cart),
        BlocProvider<CheckoutCubit>.value(value: checkout),
      ],
      child: child,
    );
  }

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            shell(CartScreen(onContinueShopping: () => context.go('/'))),
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        name: AppRoutes.orderSuccessName,
        builder: (context, state) {
          final order = checkout.completedOrder;
          if (order == null) {
            return const Scaffold(body: Text('missing order'));
          }
          return OrderSuccessScreen(
            order: order,
            onContinueShopping: () {
              checkout.reset();
              context.go('/');
            },
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return (cart: cart, checkout: checkout, repository: repository);
}

void main() {
  testWidgets('shows cart lines, totals, and quantity controls', (
    tester,
  ) async {
    final setup = await _pumpCart(tester);

    expect(find.text('Cooking oil'), findsOneWidget);
    expect(find.byKey(const ValueKey('cart-quantity-3')), findsOneWidget);
    expect(find.text('\$9.98'), findsWidgets);
    expect(find.text('2 units'), findsOneWidget);
    expect(find.text('\$9.98'), findsWidgets);

    await setup.cart.close();
    await setup.checkout.close();
  });

  testWidgets('reports a failed cart restore without faking items', (
    tester,
  ) async {
    final setup = await _pumpCart(tester, failLoad: true);

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Your saved cart could not be restored.'), findsOneWidget);
    expect(setup.cart.state.items, isEmpty);

    await setup.cart.close();
    await setup.checkout.close();
  });

  testWidgets('cancelling the confirmation keeps the cart', (tester) async {
    final setup = await _pumpCart(tester);

    await tester.tap(find.byKey(const ValueKey('cart-place-order')));
    await tester.pumpAndSettle();
    expect(find.text('Confirm your order'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('checkout-cancel')));
    await tester.pumpAndSettle();

    expect(setup.checkout.state, isA<CheckoutIdle>());
    expect(setup.cart.state.items, hasLength(1));
    expect(find.text('Cooking oil'), findsOneWidget);

    await setup.cart.close();
    await setup.checkout.close();
  });

  testWidgets('confirming places the order and opens the success screen', (
    tester,
  ) async {
    final setup = await _pumpCart(tester);

    await tester.tap(find.byKey(const ValueKey('cart-place-order')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkout-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Order confirmed'), findsOneWidget);
    expect(find.byKey(const ValueKey('order-success-number')), findsOneWidget);
    expect(find.text('MS-30001'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);
    expect(setup.cart.state.items, isEmpty);
    expect(setup.repository.stored, isEmpty);

    await tester.tap(find.byKey(const ValueKey('order-success-continue')));
    await tester.pumpAndSettle();

    expect(setup.checkout.completedOrder, isNull);
    expect(find.text('Your cart is empty'), findsOneWidget);

    await setup.cart.close();
    await setup.checkout.close();
  });
}
