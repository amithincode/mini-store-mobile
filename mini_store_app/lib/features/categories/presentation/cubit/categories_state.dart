import 'package:equatable/equatable.dart';

import '../../../products/domain/failures/product_failure.dart';
import '../../domain/entities/product_category.dart';

sealed class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class CategoriesInitial extends CategoriesState {
  const CategoriesInitial();
}

final class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

final class CategoriesLoaded extends CategoriesState {
  const CategoriesLoaded(
    this.categories, {
    this.isRefreshing = false,
    this.refreshFailure,
  });

  final List<ProductCategory> categories;
  final bool isRefreshing;

  /// Set when a background refresh failed but saved categories are visible.
  final ProductFailure? refreshFailure;

  @override
  List<Object?> get props => [categories, isRefreshing, refreshFailure];
}

final class CategoriesEmpty extends CategoriesState {
  const CategoriesEmpty();
}

final class CategoriesOffline extends CategoriesState {
  const CategoriesOffline(this.failure);

  final ProductFailure failure;

  @override
  List<Object?> get props => [failure];
}

final class CategoriesFailure extends CategoriesState {
  const CategoriesFailure(this.failure, {required this.canRetry});

  final ProductFailure failure;
  final bool canRetry;

  @override
  List<Object?> get props => [failure, canRetry];
}
