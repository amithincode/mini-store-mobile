import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/theme/app_theme.dart';
import 'package:mini_store_app/core/widgets/bottom_bar_auto_hide.dart';
import 'package:mini_store_app/features/categories/domain/entities/product_category.dart';
import 'package:mini_store_app/features/categories/presentation/screens/categories_screen.dart';

import '../../support/category_test_doubles.dart';

Future<void> _pumpCategories(
  WidgetTester tester, {
  required FakeCategoryRepository repository,
  BottomBarVisibilityController? bottomBar,
  ValueChanged<ProductCategory>? onCategorySelected,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CategoriesScreen(
        createCubit: () => createTestCategoriesCubit(repository),
        bottomBar: bottomBar,
        onCategorySelected: onCategorySelected ?? (_) {},
      ),
    ),
  );

  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('renders the category cards and reports selections', (
    tester,
  ) async {
    final repository = FakeCategoryRepository(remote: testCategories(4));
    ProductCategory? selected;

    await _pumpCategories(
      tester,
      repository: repository,
      onCategorySelected: (category) => selected = category,
    );

    expect(
      find.byKey(const ValueKey('category-card-category-1')),
      findsOneWidget,
    );
    expect(find.text('Category 1'), findsOneWidget);
    expect(find.text('Shop by category'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('category-card-category-2')));
    await tester.pump();

    expect(selected?.slug, 'category-2');
  });

  testWidgets('hides the bottom bar on scroll and restores it on stop', (
    tester,
  ) async {
    final bottomBar = BottomBarVisibilityController();
    addTearDown(bottomBar.dispose);
    final repository = FakeCategoryRepository(remote: testCategories(20));

    await _pumpCategories(tester, repository: repository, bottomBar: bottomBar);

    await tester.drag(
      find.byKey(const ValueKey('categories-scroll')),
      const Offset(0, -320),
    );
    await tester.pump();

    expect(bottomBar.visible, isFalse);

    await tester.pump(const Duration(milliseconds: 600));
    expect(bottomBar.visible, isTrue);
  });

  testWidgets('restores the bottom bar as soon as the user scrolls back up', (
    tester,
  ) async {
    final bottomBar = BottomBarVisibilityController();
    addTearDown(bottomBar.dispose);
    final repository = FakeCategoryRepository(remote: testCategories(20));

    await _pumpCategories(tester, repository: repository, bottomBar: bottomBar);

    await tester.drag(
      find.byKey(const ValueKey('categories-scroll')),
      const Offset(0, -320),
    );
    await tester.pump();
    expect(bottomBar.visible, isFalse);

    await tester.drag(
      find.byKey(const ValueKey('categories-scroll')),
      const Offset(0, 160),
    );
    await tester.pump();

    expect(bottomBar.visible, isTrue);
  });

  testWidgets('shows the empty state when no categories are available', (
    tester,
  ) async {
    await _pumpCategories(tester, repository: FakeCategoryRepository());

    expect(find.text('No categories yet'), findsOneWidget);
  });
}
