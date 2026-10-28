import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/theme/app_theme.dart';
import 'package:mini_store_app/features/products/domain/entities/product.dart';
import 'package:mini_store_app/features/products/presentation/cubit/store_cubit.dart';
import 'package:mini_store_app/features/products/presentation/screens/store_screen.dart';

import '../../product_fixtures.dart';

Future<void> _pumpStore(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  List<Product> products = testProducts,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: StoreScreen(createCubit: () => StoreCubit(products: products)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

int _gridColumns(WidgetTester tester) {
  final grid = tester.widget<GridView>(
    find.byKey(const ValueKey('product-grid')),
  );
  final delegate =
      grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
  return delegate.crossAxisCount;
}

void main() {
  testWidgets('renders the storefront sections with a catalogue', (
    tester,
  ) async {
    await _pumpStore(tester);

    expect(find.text('Mini Store'), findsOneWidget);
    expect(find.text('Everyday essentials'), findsOneWidget);
    expect(find.text('Search products, brands…'), findsOneWidget);
    expect(find.text('WEEKEND DROP'), findsOneWidget);
    expect(find.text('Popular products'), findsOneWidget);
    expect(find.text('4 items'), findsOneWidget);
    expect(find.byKey(const ValueKey('product-grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an empty catalogue state without filters', (tester) async {
    await _pumpStore(tester, products: const <Product>[]);

    expect(find.text('No products yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('product-grid')), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('0 items'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses 2, 3, 4, and 5 columns across widths', (tester) async {
    await _pumpStore(tester, size: const Size(390, 1000));
    expect(_gridColumns(tester), 2);
    expect(tester.takeException(), isNull);

    await _pumpStore(tester, size: const Size(700, 1000));
    expect(_gridColumns(tester), 3);
    expect(tester.takeException(), isNull);

    await _pumpStore(tester, size: const Size(1000, 1000));
    expect(_gridColumns(tester), 4);
    expect(tester.takeException(), isNull);

    await _pumpStore(tester, size: const Size(1300, 1000));
    expect(_gridColumns(tester), 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters products from the search field', (tester) async {
    await _pumpStore(tester);

    await tester.enterText(find.byType(TextField), 'iphone');
    await tester.pump();

    expect(find.text('1 item'), findsOneWidget);
    expect(find.textContaining('iPhone'), findsWidgets);
    expect(find.text('Essence Mascara Lash Princess'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(find.text('4 items'), findsOneWidget);
  });

  testWidgets('filters products by category and resets', (tester) async {
    await _pumpStore(tester);

    await tester.tap(find.text('Beauty'));
    await tester.pump();

    expect(find.text('1 item'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'mascara');
    await tester.pump();

    expect(find.text('1 item'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pump();

    expect(find.text('1 item'), findsOneWidget);
  });

  testWidgets('shows a no-results state and clears all filters', (
    tester,
  ) async {
    await _pumpStore(tester);

    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pump();

    expect(find.text('No products found'), findsOneWidget);
    expect(find.text('0 items'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pump();

    expect(find.text('No products found'), findsNothing);
    expect(find.text('4 items'), findsOneWidget);
  });

  testWidgets('cart action is presentational only', (tester) async {
    await _pumpStore(tester);

    await tester.tap(find.byTooltip('Cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Cart features'), findsOneWidget);
  });

  testWidgets('product taps show a placeholder message', (tester) async {
    await _pumpStore(tester);

    await tester.tap(find.byKey(const ValueKey('product-card-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Product details for Essence Mascara'),
      findsOneWidget,
    );
  });

  testWidgets('adapts at a 320 px width with larger text', (tester) async {
    await _pumpStore(tester, size: const Size(320, 700), textScale: 1.3);

    expect(find.text('Mini Store'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    expect(find.byKey(const ValueKey('product-grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
