import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/app/shell/main_shell.dart';
import 'package:mini_store_app/app/shell/main_tab_controller.dart';
import 'package:mini_store_app/core/theme/app_theme.dart';
import 'package:mini_store_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mini_store_app/features/products/domain/entities/product.dart';
import 'package:mini_store_app/features/products/domain/entities/product_page.dart';

import '../../features/categories/support/category_test_doubles.dart';
import '../../features/products/support/product_test_doubles.dart';
import '../../support/auth_test_doubles.dart';

List<Product> _products(int count) {
  return List<Product>.generate(
    count,
    (index) => Product(
      id: index + 1,
      title: 'Product ${index + 1}',
      description: 'Description ${index + 1}',
      category: 'groceries',
      price: index + 1.99,
      rating: 4,
      stock: 10,
      brand: 'Brand',
      discountPercentage: 5,
      availabilityStatus: 'In Stock',
      imageUrl: '',
    ),
    growable: false,
  );
}

Future<TestAuthDependencies> _pumpShell(
  WidgetTester tester, {
  MainTabController? tabController,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final dependencies = TestAuthDependencies();
  addTearDown(dependencies.dispose);

  final productRepository = FakeProductRepository(
    onFetch: ({required query, required skip, required limit}) async =>
        ProductPage(
          products: _products(20),
          total: 20,
          skip: skip,
          limit: limit,
        ),
  );
  final categoryRepository = FakeCategoryRepository(remote: testCategories(20));

  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: dependencies.cubit,
      child: MaterialApp(
        theme: AppTheme.light,
        home: MainShell(
          tabController: tabController,
          createProductListCubit: () => createTestProductListCubit(
            repository: productRepository,
            searchDebounce: Duration.zero,
          ),
          createCategoriesCubit: () =>
              createTestCategoriesCubit(categoryRepository),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump();
  await tester.pump();
  return dependencies;
}

void main() {
  testWidgets('hides the bottom bar while Home scrolls and restores it', (
    tester,
  ) async {
    await _pumpShell(tester);

    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('store-scroll')),
      const Offset(0, -400),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('hides the bottom bar while Categories scrolls and restores it', (
    tester,
  ) async {
    await _pumpShell(tester);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('categories-scroll')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('categories-scroll')),
      const Offset(0, -400),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('selecting a tab always restores a hidden bottom bar', (
    tester,
  ) async {
    final tabController = MainTabController();
    addTearDown(tabController.dispose);
    await _pumpShell(tester, tabController: tabController);

    await tester.drag(
      find.byKey(const ValueKey('store-scroll')),
      const Offset(0, -400),
    );
    await tester.pump();
    expect(find.byType(NavigationBar), findsNothing);

    tabController.select(MainTabController.accountIndex);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('No account signed in'), findsOneWidget);
  });
}
