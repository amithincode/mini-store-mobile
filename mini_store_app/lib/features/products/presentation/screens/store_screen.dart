import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../../../categories/presentation/widgets/category_chip_list.dart';
import '../cubit/store_cubit.dart';
import '../cubit/store_state.dart';
import '../widgets/product_grid.dart';
import '../widgets/product_section_header.dart';
import '../widgets/store_promo_banner.dart';
import '../widgets/store_search_field.dart';

/// The reference responsive feature screen.
///
/// [createCubit] is injected by the router (and by tests) so the screen never
/// reaches into the service locator.
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key, required this.createCubit, this.onCartTap});

  final StoreCubit Function() createCubit;
  final VoidCallback? onCartTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StoreCubit>(
      create: (context) => createCubit(),
      child: _StoreView(onCartTap: onCartTap),
    );
  }
}

class _StoreView extends StatefulWidget {
  const _StoreView({this.onCartTap});

  final VoidCallback? onCartTap;

  @override
  State<_StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<_StoreView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPlaceholder(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<StoreCubit>().search('');
  }

  void _clearAllFilters() {
    _searchController.clear();
    context.read<StoreCubit>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.fromWidth(
      MediaQuery.sizeOf(context).width,
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final bannerHeight =
        metrics.bannerHeight + (textScale - 1).clamp(0.0, 2.0) * 110;

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Mini Store',
        subtitle: 'Everyday essentials',
        actions: [
          CartIconButton(
            onPressed:
                widget.onCartTap ??
                () => _showPlaceholder(
                  'Cart features are coming in a later phase.',
                ),
          ),
        ],
      ),
      body: BlocBuilder<StoreCubit, StoreState>(
        builder: (context, state) {
          if (state.products.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: const AppEmptyView(
                    title: 'No products yet',
                    message:
                        'The product catalogue is being prepared. '
                        'Check back soon.',
                    icon: Icons.storefront_outlined,
                  ),
                ),
              ),
            );
          }

          final products = state.visibleProducts;

          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              top: metrics.isMobile ? AppSpacing.lg : AppSpacing.xl,
              bottom: AppSpacing.xxl,
            ),
            children: [
              StoreSearchField(
                controller: _searchController,
                maxWidth: metrics.searchMaxWidth,
                onChanged: context.read<StoreCubit>().search,
                onClear: _clearSearch,
              ),
              const SizedBox(height: AppSpacing.lg),
              CategoryChipList(
                categories: state.categories,
                selectedCategory: state.selectedCategory,
                onSelected: context.read<StoreCubit>().selectCategory,
              ),
              const SizedBox(height: AppSpacing.lg),
              StorePromoBanner(
                height: bannerHeight,
                onShopNow: () =>
                    _showPlaceholder('Promotions are coming in a later phase.'),
              ),
              const SizedBox(height: AppSpacing.xl),
              ProductSectionHeader(count: products.length),
              const SizedBox(height: AppSpacing.md),
              if (products.isEmpty)
                AppEmptyView(
                  title: 'No products found',
                  message:
                      'Try a different search term or choose another category.',
                  icon: Icons.search_off_rounded,
                  actionLabel: 'Clear filters',
                  onAction: _clearAllFilters,
                )
              else
                ProductGrid(
                  products: products,
                  onProductTap: (product) => _showPlaceholder(
                    'Product details for ${product.title} are coming in a '
                    'later phase.',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
