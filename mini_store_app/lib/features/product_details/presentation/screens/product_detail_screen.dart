import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_review.dart';
import '../cubit/product_detail_cubit.dart';
import '../cubit/product_detail_state.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId, required this.createCubit});
  final int productId; final ProductDetailCubit Function() createCubit;
  @override Widget build(BuildContext context) => BlocProvider(create: (_) => createCubit()..load(productId), child: const _ProductDetailView());
}
class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: BlocBuilder<ProductDetailCubit, ProductDetailState>(builder: (context, state) => switch (state) {
      ProductDetailInitial() || ProductDetailLoading() => const Center(child: AppLoadingView(message: 'Loading product…')),
      ProductDetailOffline() => Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: AppErrorView(title: "You're offline", message: 'This product is not saved on your device yet.', onRetry: context.read<ProductDetailCubit>().retry))),
      ProductDetailFailure() => Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: AppErrorView(message: state.failure.message, onRetry: state.canRetry ? context.read<ProductDetailCubit>().retry : null))),
      ProductDetailLoaded() => _LoadedProduct(product: state.product, isOffline: state.isOffline),
    }),
  );
}
class _LoadedProduct extends StatelessWidget { const _LoadedProduct({required this.product, required this.isOffline}); final Product product; final bool isOffline;
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    bottomNavigationBar: _CartBar(product: product),
    body: CustomScrollView(slivers: [
      SliverAppBar(pinned: true, expandedHeight: 330, backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary, flexibleSpace: FlexibleSpaceBar(background: _ImageCarousel(product: product))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxxl), sliver: SliverList(delegate: SliverChildListDelegate([
        if (isOffline) const _OfflineBanner(), _Info(product: product), const SizedBox(height: AppSpacing.lg), const Divider(color: AppColors.border), const SizedBox(height: AppSpacing.lg),
        Text('Description', style: AppTypography.titleLarge), const SizedBox(height: AppSpacing.xs), Text(product.description.isEmpty ? 'No description is available for this product.' : product.description, style: AppTypography.bodyLarge),
        if (product.warrantyInformation.isNotEmpty || product.shippingInformation.isNotEmpty || product.returnPolicy.isNotEmpty) ...[const SizedBox(height: AppSpacing.lg), _Details(product: product)],
        const SizedBox(height: AppSpacing.xl), _Reviews(reviews: product.reviews),
      ])))
    ]),
  );
}
class _ImageCarousel extends StatefulWidget { const _ImageCarousel({required this.product}); final Product product; @override State<_ImageCarousel> createState() => _ImageCarouselState(); }
class _ImageCarouselState extends State<_ImageCarousel> { int _index = 0; @override Widget build(BuildContext context) { final images = {widget.product.imageUrl, ...widget.product.images}.where((image) => image.isNotEmpty).toList(); return Stack(fit: StackFit.expand, children: [Container(color: AppColors.imageBackground), PageView.builder(itemCount: images.isEmpty ? 1 : images.length, onPageChanged: (index) => setState(() => _index = index), itemBuilder: (_, index) => AppNetworkImage(imageUrl: images.isEmpty ? '' : images[index], semanticLabel: widget.product.title, fit: BoxFit.contain)), if (images.length > 1) Positioned(bottom: AppSpacing.md, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(images.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 180), margin: const EdgeInsets.all(3), height: 7, width: index == _index ? 18 : 7, decoration: BoxDecoration(color: index == _index ? AppColors.primary : AppColors.textSecondary.withValues(alpha: .35), borderRadius: BorderRadius.circular(9))))))]); } }
class _Info extends StatelessWidget { const _Info({required this.product}); final Product product; @override Widget build(BuildContext context) { final unavailable = !product.isInStock; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.category.toUpperCase(), style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)), const SizedBox(height: AppSpacing.xs), Text(product.title, style: AppTypography.headlineSmall), const SizedBox(height: AppSpacing.xs), Text(product.brand?.isNotEmpty == true ? product.brand! : 'No brand', style: AppTypography.bodyMedium), const SizedBox(height: AppSpacing.md), Row(children: [Text(formatPrice(product.price), style: AppTypography.headlineSmall.copyWith(color: AppColors.primaryDark)), if (product.hasDiscount) Padding(padding: const EdgeInsets.only(left: AppSpacing.sm), child: Chip(label: Text(formatDiscount(product.discountPercentage)), backgroundColor: AppColors.accentContainer, side: BorderSide.none)), const Spacer(), const Icon(Icons.star_rounded, color: AppColors.accent, size: 20), Text(' ${formatRating(product.rating)}', style: AppTypography.titleSmall)]), const SizedBox(height: AppSpacing.md), _StockBadge(stock: product.stock, unavailable: unavailable)]); } }
class _StockBadge extends StatelessWidget { const _StockBadge({required this.stock, required this.unavailable}); final int stock; final bool unavailable; @override Widget build(BuildContext context) { final low = stock > 0 && stock < 10; final color = unavailable ? AppColors.error : low ? AppColors.accent : AppColors.success; final label = unavailable ? 'Out of stock' : low ? 'Only $stock left' : 'In stock'; return Semantics(label: label, child: Chip(avatar: Icon(unavailable ? Icons.remove_circle_outline : Icons.check_circle_outline, size: 17, color: color), label: Text(label), backgroundColor: color.withValues(alpha: .1), side: BorderSide(color: color.withValues(alpha: .35)))); } }
class _Details extends StatelessWidget { const _Details({required this.product}); final Product product; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Product details', style: AppTypography.titleLarge), if (product.shippingInformation.isNotEmpty) _line(Icons.local_shipping_outlined, product.shippingInformation), if (product.warrantyInformation.isNotEmpty) _line(Icons.verified_user_outlined, product.warrantyInformation), if (product.returnPolicy.isNotEmpty) _line(Icons.assignment_return_outlined, product.returnPolicy)]); Widget _line(IconData icon, String text) => Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: AppColors.primary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(text, style: AppTypography.bodyMedium))])); }
class _Reviews extends StatelessWidget { const _Reviews({required this.reviews}); final List<ProductReview> reviews; @override Widget build(BuildContext context) { if (reviews.isEmpty) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Reviews', style: AppTypography.titleLarge), const SizedBox(height: AppSpacing.sm), Text('No reviews yet.', style: AppTypography.bodyMedium)]); return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Reviews (${reviews.length})', style: AppTypography.titleLarge), ...reviews.map((review) => Card(margin: const EdgeInsets.only(top: AppSpacing.sm), child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(review.reviewerName, style: AppTypography.titleSmall)), const Icon(Icons.star_rounded, color: AppColors.accent, size: 18), Text(' ${review.rating}')]), if (review.comment.isNotEmpty) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(review.comment, style: AppTypography.bodyMedium))]))))]); } }
class _CartBar extends StatelessWidget { const _CartBar({required this.product}); final Product product; @override Widget build(BuildContext context) => SafeArea(top: false, child: Material(color: AppColors.surface, elevation: 12, child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: BlocBuilder<CartCubit, CartState>(builder: (context, state) { final quantity = state.quantityFor(product.id); if (quantity == 0) return FilledButton.icon(onPressed: product.isInStock ? () => context.read<CartCubit>().addItem(product) : null, icon: const Icon(Icons.add_shopping_cart_rounded), label: const Text('Add to cart'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))); return Row(children: [Expanded(child: Text('$quantity in your cart', style: AppTypography.titleMedium)), IconButton.filledTonal(onPressed: () => context.read<CartCubit>().decrement(product.id), tooltip: 'Remove one item', icon: const Icon(Icons.remove)), const SizedBox(width: AppSpacing.xs), IconButton.filled(onPressed: () => context.read<CartCubit>().increment(product.id), tooltip: 'Add one item', icon: const Icon(Icons.add))]); }))), ); }
class _OfflineBanner extends StatelessWidget { const _OfflineBanner(); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: AppSpacing.md), padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: AppColors.accentContainer, borderRadius: BorderRadius.circular(10)), child: const Row(children: [Icon(Icons.cloud_off_outlined, size: 18), SizedBox(width: AppSpacing.xs), Expanded(child: Text("You're offline — showing saved product details."))])); }
