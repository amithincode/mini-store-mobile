import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/product.dart';
import '../../../products/domain/failures/product_failure.dart';

sealed class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

final class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

final class ProductDetailLoaded extends ProductDetailState {
  const ProductDetailLoaded(
    this.product, {
    this.isRefreshing = false,
    this.refreshFailure,
  });

  final Product product;

  /// A background refresh is in flight while cached details stay visible.
  final bool isRefreshing;

  /// Set only when a background refresh failed; the cached product is kept.
  final ProductFailure? refreshFailure;

  bool get isOffline => refreshFailure?.isOffline ?? false;

  @override
  List<Object?> get props => [product, isRefreshing, refreshFailure];
}

final class ProductDetailOffline extends ProductDetailState {
  const ProductDetailOffline();
}

final class ProductDetailFailure extends ProductDetailState {
  const ProductDetailFailure(this.failure, {required this.canRetry});

  final ProductFailure failure;
  final bool canRetry;

  @override
  List<Object?> get props => [failure, canRetry];
}
