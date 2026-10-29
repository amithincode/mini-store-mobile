/// Which collection a [ProductListCubit] is showing.
sealed class ProductListSource {
  const ProductListSource();

  const factory ProductListSource.catalogue() = CatalogueProductListSource;
  const factory ProductListSource.category(String slug) =
      CategoryProductListSource;

  bool get isCategory => false;

  /// Cache namespace for this source. Category collections are isolated so
  /// browsing one category can never mix with another.
  String get cacheKey => '';

  String? get categorySlug => null;
}

final class CatalogueProductListSource extends ProductListSource {
  const CatalogueProductListSource();
}

final class CategoryProductListSource extends ProductListSource {
  const CategoryProductListSource(this.slug);

  final String slug;

  @override
  bool get isCategory => true;

  @override
  String get cacheKey => 'category:$slug';

  @override
  String? get categorySlug => slug;
}
