import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/product_list_source.dart';
import '../../domain/entities/product_page.dart';
import '../../domain/entities/product_query.dart';
import '../../domain/failures/product_failure.dart';
import '../../domain/usecases/get_cached_products_use_case.dart';
import '../../domain/usecases/get_category_products_use_case.dart';
import '../../domain/usecases/get_products_use_case.dart';
import '../../domain/usecases/search_products_use_case.dart';
import 'product_list_state.dart';

/// Owns the Home product list: cached-first loading, background refresh,
/// debounced search, pagination, and retry behaviour.
class ProductListCubit extends Cubit<ProductListState> {
  ProductListCubit({
    required GetProductsUseCase getProducts,
    required SearchProductsUseCase searchProducts,
    required GetCachedProductsUseCase getCachedProducts,
    GetCategoryProductsUseCase? getCategoryProducts,
    this.pageSize = defaultPageSize,
    Duration searchDebounce = const Duration(milliseconds: 500),
    this.source = const ProductListSource.catalogue(),
  }) : _getProducts = getProducts,
       _searchProducts = searchProducts,
       _getCachedProducts = getCachedProducts,
       _getCategoryProducts = getCategoryProducts,
       _searchDebounce = searchDebounce,
       super(const ProductListInitial());

  static const int defaultPageSize = 10;

  final GetProductsUseCase _getProducts;
  final SearchProductsUseCase _searchProducts;
  final GetCachedProductsUseCase _getCachedProducts;
  final GetCategoryProductsUseCase? _getCategoryProducts;
  final int pageSize;
  final Duration _searchDebounce;
  final ProductListSource source;

  String _activeQuery = '';
  Timer? _debounce;
  int _generation = 0;
  bool _firstPageInFlight = false;

  /// Loads the first page, showing cache immediately when available.
  Future<void> loadInitial() {
    if (_firstPageInFlight) {
      return Future<void>.value();
    }
    return _activateQuery(_activeQuery);
  }

  /// Debounces typing and starts a new search once the user pauses.
  void search(String value) {
    if (source.isCategory) {
      return;
    }
    final normalized = normalizeProductQuery(value);
    _debounce?.cancel();
    _debounce = null;

    if (normalized == _activeQuery) {
      return;
    }

    if (normalized.isEmpty) {
      unawaited(_activateQuery(''));
      return;
    }

    _debounce = Timer(_searchDebounce, () {
      _debounce = null;
      unawaited(_activateQuery(normalized));
    });
  }

  /// Submits the current field value immediately, bypassing the debounce.
  void submitSearch(String value) {
    if (source.isCategory) {
      return;
    }
    _debounce?.cancel();
    _debounce = null;

    final normalized = normalizeProductQuery(value);
    if (normalized == _activeQuery &&
        (state is ProductListLoaded || state is ProductListEmpty)) {
      unawaited(refresh());
      return;
    }

    unawaited(_activateQuery(normalized, force: true));
  }

  /// Restores the normal catalogue immediately.
  void clearSearch() {
    if (source.isCategory) {
      return;
    }
    _debounce?.cancel();
    _debounce = null;

    if (_activeQuery.isEmpty &&
        (state is ProductListLoaded || state is ProductListEmpty)) {
      return;
    }

    unawaited(_activateQuery('', force: true));
  }

  /// Refreshes the current query from page zero without hiding products.
  Future<void> refresh() async {
    if (_firstPageInFlight) {
      return;
    }

    final current = state;
    final query = _activeQuery;
    final existingProducts = current is ProductListLoaded
        ? current.products
        : const <Product>[];
    final existingTotal = current is ProductListLoaded ? current.total : 0;
    final hadProducts = existingProducts.isNotEmpty;
    final generation = ++_generation;
    _firstPageInFlight = true;

    if (hadProducts) {
      emit(
        ProductListLoaded(
          query: query,
          products: existingProducts,
          total: existingTotal,
          hasMore: existingProducts.length < existingTotal,
          isRefreshing: true,
        ),
      );
    } else {
      emit(ProductListLoading(query: query));
    }

    try {
      final page = await _fetchPage(query: query, skip: 0);
      if (!_isCurrent(generation)) {
        return;
      }
      _emitFirstPage(query, page);
    } on ProductFailure catch (failure) {
      if (_isCurrent(generation)) {
        _emitFirstPageFailure(
          query: query,
          failure: failure,
          cachedProducts: existingProducts,
          cachedTotal: existingTotal,
        );
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        _emitFirstPageFailure(
          query: query,
          failure: const ProductUnexpectedFailure(),
          cachedProducts: existingProducts,
          cachedTotal: existingTotal,
        );
      }
    } finally {
      if (_isCurrent(generation)) {
        _firstPageInFlight = false;
      }
    }
  }

  /// Appends the next page. Existing products stay visible on failure.
  Future<void> loadMore() async {
    final current = state;
    if (current is! ProductListLoaded ||
        current.isLoadingMore ||
        current.isRefreshing ||
        !current.hasMore ||
        current.paginationFailure != null) {
      return;
    }

    final generation = _generation;
    final query = current.query;
    final skip = current.products.length;
    emit(current.copyWith(isLoadingMore: true));

    try {
      final page = await _fetchPage(query: query, skip: skip);
      if (!_isCurrent(generation)) {
        return;
      }

      final merged = _dedupe(<Product>[...current.products, ...page.products]);
      final total = page.total > 0 ? page.total : current.total;
      final madeProgress = merged.length > current.products.length;

      emit(
        ProductListLoaded(
          query: query,
          products: merged,
          total: total,
          hasMore: madeProgress && merged.length < total,
          notice: current.notice,
        ),
      );
    } on ProductFailure catch (failure) {
      if (_isCurrent(generation)) {
        emit(
          current.copyWith(isLoadingMore: false, paginationFailure: failure),
        );
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        emit(
          current.copyWith(
            isLoadingMore: false,
            paginationFailure: const ProductUnexpectedFailure(),
          ),
        );
      }
    }
  }

  /// Retries the initial request or a failed search.
  Future<void> retryInitial() {
    final current = state;
    if (current is ProductListFailure || current is ProductListOfflineEmpty) {
      return _activateQuery(current.query, force: true);
    }
    return Future<void>.value();
  }

  /// Retries the failed next-page request.
  Future<void> retryPagination() async {
    final current = state;
    if (current is! ProductListLoaded || current.paginationFailure == null) {
      return;
    }

    emit(current.copyWith(paginationFailure: null, isLoadingMore: false));
    await loadMore();
  }

  Future<void> _activateQuery(String normalized, {bool force = false}) async {
    _debounce?.cancel();
    _debounce = null;

    if (!force &&
        normalized == _activeQuery &&
        (state is ProductListLoaded || state is ProductListEmpty)) {
      return;
    }

    if (_firstPageInFlight && normalized == _activeQuery) {
      return;
    }

    _activeQuery = normalized;
    final generation = ++_generation;
    _firstPageInFlight = true;

    final cached = await _readCache(_cacheQuery(normalized));
    if (!_isCurrent(generation)) {
      return;
    }

    if (cached != null && cached.products.isNotEmpty) {
      emit(
        ProductListLoaded(
          query: normalized,
          products: cached.products,
          total: cached.total,
          hasMore: cached.products.length < cached.total,
          isRefreshing: true,
        ),
      );
    } else {
      emit(ProductListLoading(query: normalized));
    }

    try {
      final page = await _fetchPage(query: normalized, skip: 0);
      if (!_isCurrent(generation)) {
        return;
      }
      _emitFirstPage(normalized, page);
    } on ProductFailure catch (failure) {
      if (_isCurrent(generation)) {
        _emitFirstPageFailure(
          query: normalized,
          failure: failure,
          cachedProducts: cached?.products ?? const <Product>[],
          cachedTotal: cached?.total ?? 0,
        );
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        _emitFirstPageFailure(
          query: normalized,
          failure: const ProductUnexpectedFailure(),
          cachedProducts: cached?.products ?? const <Product>[],
          cachedTotal: cached?.total ?? 0,
        );
      }
    } finally {
      if (_isCurrent(generation)) {
        _firstPageInFlight = false;
      }
    }
  }

  void _emitFirstPage(String query, ProductPage page) {
    final products = _dedupe(page.products);
    if (products.isEmpty) {
      emit(ProductListEmpty(query: query));
      return;
    }

    emit(
      ProductListLoaded(
        query: query,
        products: products,
        total: page.total,
        hasMore: products.length < page.total,
      ),
    );
  }

  void _emitFirstPageFailure({
    required String query,
    required ProductFailure failure,
    required List<Product> cachedProducts,
    required int cachedTotal,
  }) {
    if (cachedProducts.isNotEmpty) {
      emit(
        ProductListLoaded(
          query: query,
          products: cachedProducts,
          total: cachedTotal < cachedProducts.length
              ? cachedProducts.length
              : cachedTotal,
          hasMore: cachedProducts.length < cachedTotal,
          notice: _noticeFor(failure, query),
        ),
      );
      return;
    }

    if (failure.isOffline) {
      emit(ProductListOfflineEmpty(query: query, failure: failure));
      return;
    }

    emit(
      ProductListFailure(
        query: query,
        failure: failure,
        canRetry: !failure.requiresReauthentication,
      ),
    );
  }

  ProductListNotice _noticeFor(ProductFailure failure, String query) {
    final isSearch = query.isNotEmpty;

    if (failure.isOffline) {
      return ProductListNotice(
        type: ProductListNoticeType.offlineShowingSaved,
        message: isSearch
            ? "You're offline. Showing saved search results."
            : "You're offline. Showing saved products.",
      );
    }

    if (failure.requiresReauthentication) {
      return ProductListNotice(
        type: ProductListNoticeType.sessionExpired,
        message: failure.message,
      );
    }

    return ProductListNotice(
      type: isSearch
          ? ProductListNoticeType.searchRefreshFailed
          : ProductListNoticeType.refreshFailed,
      message: isSearch
          ? "Couldn't update search results. Showing saved results."
          : "Couldn't refresh products. Showing saved data.",
    );
  }

  Future<ProductPage> _fetchPage({
    required String query,
    required int skip,
  }) async {
    final slug = source.categorySlug;
    if (slug != null) {
      final useCase = _getCategoryProducts;
      if (useCase == null) {
        throw const ProductUnexpectedFailure();
      }
      return useCase(slug: slug, skip: skip, limit: pageSize);
    }

    return query.isEmpty
        ? _getProducts(skip: skip, limit: pageSize)
        : _searchProducts(query: query, skip: skip, limit: pageSize);
  }

  String _cacheQuery(String query) {
    return source.isCategory ? source.cacheKey : normalizeProductQuery(query);
  }

  Future<ProductPage?> _readCache(String query) async {
    try {
      return await _getCachedProducts(query: query);
    } catch (_) {
      return null;
    }
  }

  bool _isCurrent(int generation) => generation == _generation && !isClosed;

  List<Product> _dedupe(Iterable<Product> products) {
    final seen = <int>{};
    final result = <Product>[];

    for (final product in products) {
      if (seen.add(product.id)) {
        result.add(product);
      }
    }

    return List<Product>.unmodifiable(result);
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    _debounce = null;
    return super.close();
  }
}
