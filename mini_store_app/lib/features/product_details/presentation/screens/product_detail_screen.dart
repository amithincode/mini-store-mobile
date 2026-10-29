import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_system_ui.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_review.dart';
import '../../../products/domain/failures/product_failure.dart';
import '../../../products/presentation/utils/product_image_hero.dart';
import '../cubit/product_detail_cubit.dart';
import '../cubit/product_detail_state.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.createCubit,
    this.onGoToCart,
  });

  final int productId;
  final ProductDetailCubit Function() createCubit;
  final VoidCallback? onGoToCart;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createCubit()..load(productId),
      child: _ProductDetailView(onGoToCart: onGoToCart),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView({this.onGoToCart});

  final VoidCallback? onGoToCart;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) => switch (state) {
        ProductDetailInitial() || ProductDetailLoading() => const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: AppLoadingView(message: 'Loading product…')),
        ),
        ProductDetailOffline() => Scaffold(
          backgroundColor: AppColors.background,
          appBar: _detailAppBar(context),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppErrorView(
                title: "You're offline",
                message:
                    'This product is not saved on your device yet. '
                    'Check your connection and try again.',
                retryLabel: 'Retry',
                onRetry: context.read<ProductDetailCubit>().retry,
              ),
            ),
          ),
        ),
        ProductDetailFailure() => Scaffold(
          backgroundColor: AppColors.background,
          appBar: _detailAppBar(context),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppErrorView(
                message: state.failure.message,
                onRetry: state.canRetry
                    ? context.read<ProductDetailCubit>().retry
                    : null,
                icon: state.failure.requiresReauthentication
                    ? Icons.lock_clock_rounded
                    : Icons.cloud_off_rounded,
              ),
            ),
          ),
        ),
        ProductDetailLoaded() => _LoadedProduct(
          state: state,
          onGoToCart: onGoToCart,
        ),
      },
    );
  }
}

PreferredSizeWidget _detailAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    systemOverlayStyle: AppSystemUi.light,
    elevation: 0,
    leading: IconButton(
      tooltip: 'Back',
      onPressed: () {
        final router = GoRouter.maybeOf(context);
        if (router != null && router.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.store);
        }
      },
      icon: const Icon(Icons.arrow_back_rounded),
    ),
  );
}

class _LoadedProduct extends StatelessWidget {
  const _LoadedProduct({required this.state, this.onGoToCart});

  final ProductDetailLoaded state;
  final VoidCallback? onGoToCart;

  @override
  Widget build(BuildContext context) {
    final product = state.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _CartBar(product: product, onGoToCart: onGoToCart),
      body: CustomScrollView(
        key: const ValueKey('product-detail-scroll'),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 330,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            systemOverlayStyle: AppSystemUi.light,
            leading: IconButton(
              tooltip: 'Back',
              onPressed: () {
                final router = GoRouter.maybeOf(context);
                if (router != null && router.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.store);
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _ImageCarousel(product: product),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xxxl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (state.isRefreshing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  ),
                if (state.refreshFailure != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _RefreshNotice(
                      failure: state.refreshFailure!,
                      onRetry: context.read<ProductDetailCubit>().retry,
                    ),
                  ),
                _Info(product: product),
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.lg),
                Text('Description', style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  product.description.isEmpty
                      ? 'No description is available for this product.'
                      : product.description,
                  style: AppTypography.bodyLarge,
                ),
                if (product.warrantyInformation.isNotEmpty ||
                    product.shippingInformation.isNotEmpty ||
                    product.returnPolicy.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _Details(product: product),
                ],
                const SizedBox(height: AppSpacing.xl),
                _Reviews(reviews: product.reviews),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.product});

  final Product product;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = <String>{
      widget.product.imageUrl,
      ...widget.product.images,
    }.where((image) => image.trim().isNotEmpty).toList(growable: false);

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.imageBackground),
        if (images.isEmpty)
          const Center(
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
          )
        else
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              final image = AppNetworkImage(
                imageUrl: images[index],
                semanticLabel: widget.product.title,
                fit: BoxFit.contain,
              );

              if (index != 0) {
                return image;
              }

              return Hero(
                tag: productImageHeroTag(widget.product.id),
                child: image,
              );
            },
          ),
        if (images.length > 1)
          Positioned(
            bottom: AppSpacing.md,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.all(3),
                  height: 7,
                  width: index == _index ? 18 : 7,
                  decoration: BoxDecoration(
                    color: index == _index
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final unavailable = !product.isInStock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.category.toUpperCase(),
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(product.title, style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          product.brand?.isNotEmpty == true ? product.brand! : 'No brand',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatPrice(product.price),
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
            if (product.hasDiscount)
              Chip(
                label: Text(formatDiscount(product.discountPercentage)),
                backgroundColor: AppColors.accentContainer,
                side: BorderSide.none,
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                Text(
                  ' ${formatRating(product.rating)}',
                  style: AppTypography.titleSmall,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _StockBadge(stock: product.stock, unavailable: unavailable),
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock, required this.unavailable});

  final int stock;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final low = stock > 0 && stock < 10;
    final color = unavailable
        ? AppColors.error
        : low
        ? AppColors.accent
        : AppColors.success;
    final label = unavailable
        ? 'Out of stock'
        : low
        ? 'Only $stock left'
        : 'In stock';

    return Semantics(
      label: label,
      child: Chip(
        avatar: Icon(
          unavailable
              ? Icons.remove_circle_outline
              : Icons.check_circle_outline,
          size: 17,
          color: color,
        ),
        label: Text(label),
        backgroundColor: color.withValues(alpha: .1),
        side: BorderSide(color: color.withValues(alpha: .35)),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product details', style: AppTypography.titleLarge),
        if (product.shippingInformation.isNotEmpty)
          _line(Icons.local_shipping_outlined, product.shippingInformation),
        if (product.warrantyInformation.isNotEmpty)
          _line(Icons.verified_user_outlined, product.warrantyInformation),
        if (product.returnPolicy.isNotEmpty)
          _line(Icons.assignment_return_outlined, product.returnPolicy),
      ],
    );
  }

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTypography.bodyMedium)),
      ],
    ),
  );
}

class _Reviews extends StatelessWidget {
  const _Reviews({required this.reviews});

  final List<ProductReview> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reviews', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text('No reviews yet.', style: AppTypography.bodyMedium),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews (${reviews.length})', style: AppTypography.titleLarge),
        ...reviews.map(
          (review) => Card(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.reviewerName,
                          style: AppTypography.titleSmall,
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.accent,
                        size: 18,
                      ),
                      Text(' ${review.rating}'),
                    ],
                  ),
                  if (review.comment.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        review.comment,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.product, this.onGoToCart});

  final Product product;
  final VoidCallback? onGoToCart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF4FF),
              Color(0xFFDCEBFF),
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(26),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                final quantity = state.quantityFor(product.id);
                final busy = state.isMutating;

                if (quantity == 0) {
                  return FilledButton.icon(
                    key: const ValueKey('detail-add-to-cart'),
                    onPressed: product.isInStock && !busy
                        ? () => _addToCart(context)
                        : null,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(busy ? 'Adding…' : 'Add to cart'),
                    style: _lightActionStyle,
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4E5FC),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.xs,
                              ),
                              child: Text(
                                quantity == 1
                                    ? '1 item in your cart'
                                    : '$quantity items in your cart',
                                style: AppTypography.titleSmall.copyWith(
                                  color: const Color(0xFF355781),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('detail-decrement'),
                            onPressed: busy
                                ? null
                                : () => _change(
                                    context,
                                    () => context.read<CartCubit>().decrement(
                                      product.id,
                                    ),
                                  ),
                            tooltip: 'Remove one item',
                            icon: const Icon(Icons.remove_rounded),
                            style: _stepperStyle,
                          ),
                          SizedBox(
                            width: 38,
                            child: Text(
                              '$quantity',
                              key: const ValueKey('detail-quantity'),
                              textAlign: TextAlign.center,
                              style: AppTypography.titleMedium.copyWith(
                                color: const Color(0xFF18345B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('detail-increment'),
                            onPressed: busy
                                ? null
                                : () => _change(
                                    context,
                                    () => context.read<CartCubit>().increment(
                                      product.id,
                                    ),
                                  ),
                            tooltip: 'Add one item',
                            icon: const Icon(Icons.add_rounded),
                            style: _stepperStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      key: const ValueKey('detail-go-to-cart'),
                      onPressed: busy ? null : onGoToCart,
                      icon: const Icon(Icons.shopping_cart_rounded),
                      label: const Text('Go to cart'),
                      style: _lightActionStyle,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static final ButtonStyle _lightActionStyle = FilledButton.styleFrom(
    backgroundColor: const Color(0xFF347FE5),
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFFAAC9F3),
    disabledForegroundColor: Colors.white70,
    minimumSize: const Size.fromHeight(52),
    textStyle: AppTypography.labelLarge.copyWith(
      fontWeight: FontWeight.w700,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    elevation: 0,
  );

  static final ButtonStyle _stepperStyle = IconButton.styleFrom(
    backgroundColor: const Color(0xFFEAF3FF),
    foregroundColor: const Color(0xFF2878E5),
    disabledBackgroundColor: const Color(0xFFF2F6FC),
    disabledForegroundColor: const Color(0xFFB0C4DF),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  Future<void> _addToCart(BuildContext context) async {
    final succeeded = await context.read<CartCubit>().addItem(product);
    if (!context.mounted) {
      return;
    }

    if (!succeeded) {
      _showFailure(context);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Added to cart.')));
  }

  Future<void> _change(
    BuildContext context,
    Future<bool> Function() change,
  ) async {
    final succeeded = await change();
    if (!succeeded && context.mounted) {
      _showFailure(context);
    }
  }

  void _showFailure(BuildContext context) {
    final message =
        context.read<CartCubit>().state.errorMessage ??
        'Could not update your cart. Please try again.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// class _CartBar extends StatelessWidget {
//   const _CartBar({required this.product, this.onGoToCart});

//   final Product product;
//   final VoidCallback? onGoToCart;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: AppColors.primary,
//       elevation: 14,
//       child: DecoratedBox(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color.fromARGB(255, 54, 110, 231),
//               Color.fromARGB(255, 42, 66, 132),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           top: false,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(
//               AppSpacing.md,
//               AppSpacing.md,
//               AppSpacing.md,
//               AppSpacing.sm,
//             ),
//             child: BlocBuilder<CartCubit, CartState>(
//               builder: (context, state) {
//                 final quantity = state.quantityFor(product.id);
//                 final busy = state.isMutating;

//                 if (quantity == 0) {
//                   return FilledButton.icon(
//                     key: const ValueKey('detail-add-to-cart'),
//                     onPressed: product.isInStock && !busy
//                         ? () => _addToCart(context)
//                         : null,
//                     icon: busy
//                         ? const SizedBox(
//                             width: 18,
//                             height: 18,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2.2,
//                               color: AppColors.primary,
//                             ),
//                           )
//                         : const Icon(Icons.add_shopping_cart_rounded),
//                     label: Text(busy ? 'Adding…' : 'Add to cart'),
//                     style: _lightActionStyle,
//                   );
//                 }

//                 return Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: AppSpacing.xs,
//                         vertical: AppSpacing.xxs,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withValues(alpha: 0.18),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Padding(
//                               padding: const EdgeInsets.only(
//                                 left: AppSpacing.xs,
//                               ),
//                               child: Text(
//                                 quantity == 1
//                                     ? '1 item in your cart'
//                                     : '$quantity items in your cart',
//                                 style: AppTypography.titleSmall.copyWith(
//                                   color: Colors.white.withValues(alpha: 0.82),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           IconButton(
//                             key: const ValueKey('detail-decrement'),
//                             onPressed: busy
//                                 ? null
//                                 : () => _change(
//                                     context,
//                                     () => context.read<CartCubit>().decrement(
//                                       product.id,
//                                     ),
//                                   ),
//                             tooltip: 'Remove one item',
//                             icon: const Icon(Icons.remove_rounded),
//                             style: _stepperStyle,
//                           ),
//                           SizedBox(
//                             width: 38,
//                             child: Text(
//                               '$quantity',
//                               key: const ValueKey('detail-quantity'),
//                               textAlign: TextAlign.center,
//                               style: AppTypography.titleMedium.copyWith(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ),
//                           IconButton(
//                             key: const ValueKey('detail-increment'),
//                             onPressed: busy
//                                 ? null
//                                 : () => _change(
//                                     context,
//                                     () => context.read<CartCubit>().increment(
//                                       product.id,
//                                     ),
//                                   ),
//                             tooltip: 'Add one item',
//                             icon: const Icon(Icons.add_rounded),
//                             style: _stepperStyle,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: AppSpacing.sm),
//                     FilledButton.icon(
//                       key: const ValueKey('detail-go-to-cart'),
//                       onPressed: busy ? null : onGoToCart,
//                       icon: const Icon(Icons.shopping_cart_rounded),
//                       label: const Text('Go to cart'),
//                       style: _lightActionStyle,
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   static final ButtonStyle _lightActionStyle = FilledButton.styleFrom(
//     backgroundColor: AppColors.surface,
//     foregroundColor: AppColors.primaryDeep,
//     disabledBackgroundColor: AppColors.surface.withValues(alpha: 0.55),
//     disabledForegroundColor: AppColors.primaryDeep.withValues(alpha: 0.55),
//     minimumSize: const Size.fromHeight(52),
//     textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
//   );

//   static final ButtonStyle _stepperStyle = IconButton.styleFrom(
//     backgroundColor: Colors.white.withValues(alpha: 0.18),
//     foregroundColor: Colors.white,
//     disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
//     disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
//   );

//   Future<void> _addToCart(BuildContext context) async {
//     final succeeded = await context.read<CartCubit>().addItem(product);
//     if (!context.mounted) {
//       return;
//     }

//     if (!succeeded) {
//       _showFailure(context);
//       return;
//     }

//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(const SnackBar(content: Text('Added to cart.')));
//   }

//   Future<void> _change(
//     BuildContext context,
//     Future<bool> Function() change,
//   ) async {
//     final succeeded = await change();
//     if (!succeeded && context.mounted) {
//       _showFailure(context);
//     }
//   }

//   void _showFailure(BuildContext context) {
//     final message =
//         context.read<CartCubit>().state.errorMessage ??
//         'Could not update your cart. Please try again.';
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(SnackBar(content: Text(message)));
//   }
// }

class _RefreshNotice extends StatelessWidget {
  const _RefreshNotice({required this.failure, required this.onRetry});

  final ProductFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isSession = failure.requiresReauthentication;
    final background = isSession
        ? AppColors.error.withValues(alpha: 0.08)
        : AppColors.accentContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            failure.isOffline
                ? Icons.cloud_off_rounded
                : Icons.sync_problem_rounded,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              failure.isOffline
                  ? "You're offline. Showing saved product details."
                  : isSession
                  ? failure.message
                  : "Couldn't refresh details. Showing saved data.",
              style: AppTypography.bodySmall,
            ),
          ),
          if (!isSession)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
