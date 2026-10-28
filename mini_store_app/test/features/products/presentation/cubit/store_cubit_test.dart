import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/products/presentation/cubit/store_cubit.dart';
import 'package:mini_store_app/features/products/presentation/cubit/store_state.dart';

import '../../product_fixtures.dart';

void main() {
  late StoreCubit cubit;

  setUp(() {
    cubit = StoreCubit();
  });

  tearDown(() => cubit.close());

  test('starts with an empty catalogue and an All category', () {
    expect(cubit.state.products, isEmpty);
    expect(cubit.state.categories, <String>[StoreState.allCategory]);
    expect(cubit.state.visibleProducts, isEmpty);
    expect(cubit.state.hasActiveFilters, isFalse);
  });

  test('filters an injected catalogue by title, brand, and category', () {
    final fixtureCubit = StoreCubit(products: testProducts);
    addTearDown(fixtureCubit.close);

    fixtureCubit.search('mascara');
    expect(fixtureCubit.state.visibleProducts, hasLength(1));
    expect(
      fixtureCubit.state.visibleProducts.single.title,
      contains('Mascara'),
    );

    fixtureCubit.search('apple');
    expect(fixtureCubit.state.visibleProducts, hasLength(2));

    fixtureCubit.search('beauty');
    expect(fixtureCubit.state.visibleProducts, hasLength(1));
  });

  test('filters by category', () {
    final fixtureCubit = StoreCubit(products: testProducts);
    addTearDown(fixtureCubit.close);

    fixtureCubit.selectCategory('groceries');

    expect(fixtureCubit.state.visibleProducts, hasLength(2));
    expect(
      fixtureCubit.state.visibleProducts.every(
        (product) => product.category == 'groceries',
      ),
      isTrue,
    );
    expect(fixtureCubit.state.hasActiveFilters, isTrue);
  });

  test('combines category and search filters', () {
    final fixtureCubit = StoreCubit(products: testProducts);
    addTearDown(fixtureCubit.close);

    fixtureCubit.selectCategory('beauty');
    fixtureCubit.search('mascara');

    expect(fixtureCubit.state.visibleProducts, hasLength(1));
    expect(
      fixtureCubit.state.visibleProducts.single.title,
      contains('Mascara'),
    );
  });

  test('reports an empty result set', () {
    final fixtureCubit = StoreCubit(products: testProducts);
    addTearDown(fixtureCubit.close);

    fixtureCubit.search('a product that does not exist');

    expect(fixtureCubit.state.visibleProducts, isEmpty);
    expect(fixtureCubit.state.hasActiveFilters, isTrue);
  });

  test('clears both search and category filters', () {
    final fixtureCubit = StoreCubit(products: testProducts);
    addTearDown(fixtureCubit.close);

    fixtureCubit.selectCategory('smartphones');
    fixtureCubit.search('iphone');
    fixtureCubit.clearFilters();

    expect(fixtureCubit.state.query, isEmpty);
    expect(fixtureCubit.state.selectedCategory, StoreState.allCategory);
    expect(
      fixtureCubit.state.visibleProducts.length,
      fixtureCubit.state.products.length,
    );
    expect(fixtureCubit.state.hasActiveFilters, isFalse);
  });
}
