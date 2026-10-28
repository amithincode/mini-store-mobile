import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/theme/app_theme.dart';
import 'package:mini_store_app/features/products/domain/entities/product.dart';
import 'package:mini_store_app/features/products/domain/entities/product_page.dart';
import 'package:mini_store_app/features/products/domain/failures/product_failure.dart';
import 'package:mini_store_app/features/products/presentation/screens/store_screen.dart';

import '../../support/product_test_doubles.dart';

/// Products deliberately have no remote image so widget tests never depend on
/// the network image cache.
List<Product> _products(int count, {int start = 1}) {
  return List<Product>.generate(count, (index) {
    final id = start + index;
    return Product(
      id: id,
      title: 'Product $id',
      description: 'Description $id',
      category: 'groceries',
      price: id + 0.99,
      rating: 4,
      stock: 10,
      brand: 'Brand $id',
      discountPercentage: 5,
      availabilityStatus: 'In Stock',
      imageUrl: '',
    );
  }, growable: false);
}

ProductPage _page(List<Product> products, {int total = 0, int skip = 0}) {
  return ProductPage(
    products: products,
    total: total == 0 ? products.length : total,
    skip: skip,
    limit: 10,
  );
}

Future<void> _pumpStore(
  WidgetTester tester, {
  required FakeProductRepository repository,
  Size size = const Size(390, 844),
  double textScale = 1,
  Duration searchDebounce = Duration.zero,
  VoidCallback? onCartTap,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final cubit = createTestProductListCubit(
    repository: repository,
    searchDebounce: searchDebounce,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: StoreScreen(createCubit: () => cubit, onCartTap: onCartTap),
    ),
  );

  await tester.pump();
  await tester.pump();
  await tester.pump();
}

FakeProductRepository _loadedRepository({
  int count = 10,
  int total = 10,
  int start = 1,
}) {
  return FakeProductRepository(
    onFetch: ({required query, required skip, required limit}) async => _page(
      _products(count, start: start),
      total: total,
      skip: skip,
    ),
  );
}

void main() {
  testWidgets('renders the responsive grid at each breakpoint', (tester) async {
    final repository = _loadedRepository();
    await _pumpStore(tester, repository: repository);

    final sizes = <Size, int>{
      const Size(390, 844): 2,
      const Size(700, 900): 3,
      const Size(1000, 900): 4,
      const Size(1300, 900): 5,
    };

    for (final entry in sizes.entries) {
      tester.view.physicalSize = entry.key;
      await tester.pump();

      final grid = tester.widget<SliverGrid>(
        find.byKey(const ValueKey('product-grid')),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(
        delegate.crossAxisCount,
        entry.value,
        reason: 'columns at ${entry.key.width}',
      );
    }
  });

  testWidgets('renders product cards and the result count', (tester) async {
    await _pumpStore(tester, repository: _loadedRepository());

    expect(find.byKey(const ValueKey('product-card-1')), findsOneWidget);
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('10 items'), findsOneWidget);
    expect(find.text('Popular products'), findsOneWidget);
  });

  testWidgets('supports search, debounced results, and clearing', (
    tester,
  ) async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async {
        if (query == 'phone') {
          return _page(_products(2, start: 50), total: 2, skip: skip);
        }
        return _page(_products(6), total: 6, skip: skip);
      },
    );
    await _pumpStore(tester, repository: repository);

    await tester.enterText(find.byType(TextField), 'phone');
    await tester.pump();
    await tester.pump();

    expect(find.text('Search results'), findsOneWidget);
    expect(find.text('Results for "phone"'), findsOneWidget);
    expect(find.text('Product 50'), findsOneWidget);
    expect(repository.calls.any((call) => call.query == 'phone'), isTrue);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Popular products'), findsOneWidget);
    expect(find.text('Product 1'), findsOneWidget);
    expect(repository.calls.last.query, isEmpty);
  });

  testWidgets('submitting the search skips the debounce', (tester) async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async {
        if (query == 'iphone') {
          return _page(_products(2, start: 70), total: 2, skip: skip);
        }
        return _page(_products(6), total: 6, skip: skip);
      },
    );
    await _pumpStore(
      tester,
      repository: repository,
      searchDebounce: const Duration(milliseconds: 500),
    );
    repository.calls.clear();

    await tester.enterText(find.byType(TextField), 'iphone');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump();

    expect(repository.calls.single.query, 'iphone');
    expect(find.text('Product 70'), findsOneWidget);
  });

  testWidgets('shows a distinct empty-search state', (tester) async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async {
        if (query == 'missing') {
          return _page(const <Product>[], total: 0);
        }
        return _page(_products(4), total: 4, skip: skip);
      },
    );
    await _pumpStore(tester, repository: repository);

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump();
    await tester.pump();

    expect(find.text('No products found'), findsOneWidget);
    expect(
      find.text('No products found for your search. Try a different term.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Clear search'), findsOneWidget);
  });

  testWidgets('shows cached products with an offline notice', (tester) async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async =>
          throw const ProductOfflineFailure(),
      cachedByQuery: <String, ProductPage>{'': _page(_products(3), total: 3)},
    );
    await _pumpStore(tester, repository: repository);

    expect(
      find.text("You're offline. Showing saved products."),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('product-card-1')), findsOneWidget);
    expect(find.text('3 items'), findsOneWidget);
    expect(find.text("You're offline"), findsNothing);
  });

  testWidgets('shows an offline retry when no cache exists', (tester) async {
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async =>
          throw const ProductOfflineFailure(),
    );
    await _pumpStore(tester, repository: repository);

    expect(
      find.text("You're offline and no saved products are available."),
      findsOneWidget,
    );

    repository.onFetch =
        ({required query, required skip, required limit}) async =>
            _page(_products(5), total: 5, skip: skip);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('product-card-1')), findsOneWidget);
  });

  testWidgets('shows a non-blocking error when a refresh fails', (
    tester,
  ) async {
    var fail = false;
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async {
        if (fail) {
          throw const ProductServerFailure();
        }
        return _page(_products(4), total: 4, skip: skip);
      },
    );
    await _pumpStore(
      tester,
      repository: repository,
      size: const Size(1000, 900),
    );

    fail = true;
    await tester.tap(find.byTooltip('Refresh products'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text("Couldn't refresh products. Showing saved data."),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('product-card-1')), findsOneWidget);
  });

  testWidgets('shows a pagination loader and appends the next page', (
    tester,
  ) async {
    final nextPage = Completer<ProductPage>();
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) {
        if (skip == 0) {
          return Future<ProductPage>.value(
            _page(_products(10), total: 20, skip: 0),
          );
        }
        return nextPage.future;
      },
    );
    await _pumpStore(tester, repository: repository);

    await tester.drag(
      find.byKey(const ValueKey('store-scroll')),
      const Offset(0, -4000),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('pagination-loader')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-grid')), findsOneWidget);

    nextPage.complete(_page(_products(10, start: 11), total: 20, skip: 10));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('pagination-loader')), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('store-scroll')),
      const Offset(0, 4000),
    );
    await tester.pump();

    expect(find.text('20 items'), findsOneWidget);
  });

  testWidgets('retries a failed pagination request', (tester) async {
    var failNextPage = true;
    final repository = FakeProductRepository(
      onFetch: ({required query, required skip, required limit}) async {
        if (skip > 0 && failNextPage) {
          throw const ProductOfflineFailure();
        }
        return _page(
          skip == 0 ? _products(10) : _products(10, start: 11),
          total: 20,
          skip: skip,
        );
      },
    );
    await _pumpStore(tester, repository: repository);

    await tester.drag(
      find.byKey(const ValueKey('store-scroll')),
      const Offset(0, -4000),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('pagination-error')), findsOneWidget);
    expect(
      find.text("Couldn't load more products. Try again."),
      findsOneWidget,
    );

    failNextPage = false;
    await tester.ensureVisible(find.text('Try again'));
    await tester.pump();
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await tester.drag(
      find.byKey(const ValueKey('store-scroll')),
      const Offset(0, 4000),
    );
    await tester.pump();

    expect(find.text('20 items'), findsOneWidget);
    expect(find.byKey(const ValueKey('pagination-error')), findsNothing);
  });

  testWidgets('shows the refresh action only on desktop widths', (
    tester,
  ) async {
    await _pumpStore(tester, repository: _loadedRepository());

    expect(find.byTooltip('Refresh products'), findsNothing);

    tester.view.physicalSize = const Size(1000, 900);
    await tester.pump();

    expect(find.byTooltip('Refresh products'), findsOneWidget);
  });

  testWidgets('keeps the cart and product placeholders', (tester) async {
    var cartTapped = false;
    await _pumpStore(
      tester,
      repository: _loadedRepository(),
      onCartTap: () => cartTapped = true,
    );

    await tester.tap(find.byTooltip('Cart'));
    expect(cartTapped, isTrue);

    await tester.tap(find.byKey(const ValueKey('product-card-1')));
    await tester.pump();

    expect(
      find.textContaining('Product details for Product 1'),
      findsOneWidget,
    );
  });

  testWidgets('handles 1.3 text scale on a narrow phone without overflow', (
    tester,
  ) async {
    await _pumpStore(
      tester,
      repository: _loadedRepository(count: 4, total: 4),
      size: const Size(360, 800),
      textScale: 1.3,
    );

    expect(find.byKey(const ValueKey('product-card-1')), findsOneWidget);
    expect(find.text('Popular products'), findsOneWidget);
  });

  testWidgets('caps the search field width on wide screens', (tester) async {
    await _pumpStore(
      tester,
      repository: _loadedRepository(),
      size: const Size(1300, 900),
    );

    final fieldSize = tester.getSize(find.byType(TextField));
    expect(fieldSize.width, lessThanOrEqualTo(560));
  });
}
