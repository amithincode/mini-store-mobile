import 'package:equatable/equatable.dart'; import '../../../products/domain/entities/product.dart'; import '../../../products/domain/failures/product_failure.dart';
sealed class ProductDetailState extends Equatable { const ProductDetailState(); @override List<Object?> get props => []; }
class ProductDetailInitial extends ProductDetailState { const ProductDetailInitial(); }
class ProductDetailLoading extends ProductDetailState { const ProductDetailLoading(); }
class ProductDetailLoaded extends ProductDetailState { const ProductDetailLoaded(this.product, {this.isOffline = false}); final Product product; final bool isOffline; @override List<Object?> get props => [product, isOffline]; }
class ProductDetailOffline extends ProductDetailState { const ProductDetailOffline(); }
class ProductDetailFailure extends ProductDetailState { const ProductDetailFailure(this.failure, {required this.canRetry}); final ProductFailure failure; final bool canRetry; @override List<Object?> get props => [failure, canRetry]; }
