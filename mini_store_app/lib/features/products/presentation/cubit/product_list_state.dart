import 'package:equatable/equatable.dart';

import '../../domain/entities/product.dart';
import '../../domain/failures/product_failure.dart';

const Object _unset = Object();

/// Why a notice banner is shown above the product grid.
enum ProductListNoticeType {
  offlineShowingSaved,
  refreshFailed,
  searchRefreshFailed,
  sessionExpired,
}

/// Non-blocking information about the data currently on screen.
class ProductListNotice extends Equatable {
  const ProductListNotice({required this.type, required this.message});

  final ProductListNoticeType type;
  final String message;

  @override
  List<Object?> get props => [type, message];
}

/// Presentation state for the Home product list.
///
/// Each state represents one primary condition; refresh and pagination
/// progress live only on [ProductListLoaded] so they cannot conflict with the
/// initial loading, empty, and failure states.
sealed class ProductListState extends Equatable {
  const ProductListState({required this.query});

  /// Normalized query. Empty means the normal catalogue.
  final String query;

  List<Product> get products => const <Product>[];

  bool get hasProducts => products.isNotEmpty;

  @override
  List<Object?> get props => [query];
}

final class ProductListInitial extends ProductListState {
  const ProductListInitial() : super(query: '');
}

final class ProductListLoading extends ProductListState {
  const ProductListLoading({required super.query});
}

final class ProductListLoaded extends ProductListState {
  const ProductListLoaded({
    required super.query,
    required this.products,
    required this.total,
    required this.hasMore,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.notice,
    this.paginationFailure,
  });

  @override
  final List<Product> products;
  final int total;
  final bool hasMore;

  /// A background refresh is in flight while products stay visible.
  final bool isRefreshing;

  /// The next page is being appended.
  final bool isLoadingMore;

  final ProductListNotice? notice;

  /// Set only when appending a page failed; existing products are retained.
  final ProductFailure? paginationFailure;

  int get loadedCount => products.length;

  ProductListLoaded copyWith({
    List<Product>? products,
    int? total,
    bool? hasMore,
    bool? isRefreshing,
    bool? isLoadingMore,
    Object? notice = _unset,
    Object? paginationFailure = _unset,
  }) {
    return ProductListLoaded(
      query: query,
      products: products ?? this.products,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      notice: identical(notice, _unset)
          ? this.notice
          : notice as ProductListNotice?,
      paginationFailure: identical(paginationFailure, _unset)
          ? this.paginationFailure
          : paginationFailure as ProductFailure?,
    );
  }

  @override
  List<Object?> get props => [
    query,
    products,
    total,
    hasMore,
    isRefreshing,
    isLoadingMore,
    notice,
    paginationFailure,
  ];
}

final class ProductListEmpty extends ProductListState {
  const ProductListEmpty({required super.query});

  bool get isSearch => query.isNotEmpty;
}

final class ProductListOfflineEmpty extends ProductListState {
  const ProductListOfflineEmpty({required super.query, required this.failure});

  final ProductFailure failure;

  bool get isSearch => query.isNotEmpty;

  @override
  List<Object?> get props => [query, failure];
}

final class ProductListFailure extends ProductListState {
  const ProductListFailure({
    required super.query,
    required this.failure,
    required this.canRetry,
  });

  final ProductFailure failure;
  final bool canRetry;

  bool get isSearch => query.isNotEmpty;

  @override
  List<Object?> get props => [query, failure, canRetry];
}
