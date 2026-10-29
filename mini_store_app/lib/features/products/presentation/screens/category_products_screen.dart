import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/product_list_cubit.dart';
import '../cubit/product_list_state.dart';
import '../widgets/pagination_footer.dart';
import '../widgets/product_list_notice_banner.dart';
import '../widgets/product_sliver_grid.dart';

/// Products belonging to one category.
///
/// Reuses the Home list cubit (in category mode) and the shared grid,
/// pagination, refresh, and retry widgets.
class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({
    super.key,
    required this.slug,
    required this.name,
    required this.createCubit,
  });

  final String slug;
  final String name;
  final ProductListCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductListCubit>(
      create: (_) => createCubit()..loadInitial(),
      child: _CategoryProductsView(name: name),
    );
  }
}

class _CategoryProductsView extends StatefulWidget {
  const _CategoryProductsView({required this.name});

  final String name;

  @override
  State<_CategoryProductsView> createState() => _CategoryProductsViewState();
}

class _CategoryProductsViewState extends State<_CategoryProductsView> {
  static const double _loadMoreThreshold = 420;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification.metrics.extentAfter < _loadMoreThreshold) {
      unawaited(context.read<ProductListCubit>().loadMore());
    }

    return false;
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.store);
    }
  }

  void _openProduct(int id) {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    context.pushNamed(
      AppRoutes.productDetailName,
      pathParameters: {'id': id.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductListCubit>();

    return AppScaffold(
      appBar: AppAppBar(
        title: widget.name,
        subtitle: 'Category',
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: BlocBuilder<ProductListCubit, ProductListState>(
        builder: (context, state) => NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              key: const ValueKey('category-products-scroll'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: _slivers(context, cubit, state),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _slivers(
    BuildContext context,
    ProductListCubit cubit,
    ProductListState state,
  ) {
    return switch (state) {
      ProductListInitial() || ProductListLoading() => const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppLoadingView(message: 'Loading products…'),
        ),
      ],
      ProductListOfflineEmpty() => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorView(
            title: "You're offline",
            message:
                'This category is not saved on your device yet. '
                'Check your connection and try again.',
            retryLabel: 'Retry',
            onRetry: cubit.retryInitial,
          ),
        ),
      ],
      ProductListFailure() => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorView(
            title: "Couldn't load this category",
            message: state.failure.message,
            onRetry: state.canRetry ? cubit.retryInitial : null,
            icon: state.failure.requiresReauthentication
                ? Icons.lock_clock_rounded
                : Icons.cloud_off_rounded,
          ),
        ),
      ],
      ProductListEmpty() => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyView(
            title: 'No products yet',
            message:
                'This category does not have any products right now. '
                'Pull down to refresh.',
            icon: Icons.inventory_2_outlined,
            actionLabel: 'Retry',
            onAction: cubit.refresh,
          ),
        ),
      ],
      ProductListLoaded() => <Widget>[
        SliverPadding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: _CategoryHeader(
              count: state.products.length,
              total: state.total,
            ),
          ),
        ),
        if (state.notice != null)
          SliverPadding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: ProductListNoticeBanner(
                notice: state.notice!,
                onRetry: cubit.refresh,
              ),
            ),
          ),
        if (state.isRefreshing)
          const SliverPadding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(999)),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          sliver: ProductSliverGrid(
            products: state.products,
            onProductTap: (product) => _openProduct(product.id),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          sliver: SliverToBoxAdapter(
            child: ProductPaginationFooter(
              isLoading: state.isLoadingMore,
              failureMessage: _paginationMessage(state),
              onRetry: state.paginationFailure == null
                  ? null
                  : cubit.retryPagination,
            ),
          ),
        ),
      ],
    };
  }

  String? _paginationMessage(ProductListLoaded state) {
    final failure = state.paginationFailure;
    if (failure == null) {
      return null;
    }

    return failure.requiresReauthentication
        ? failure.message
        : "Couldn't load more products. Try again.";
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Text(
      total > count ? 'Showing $count of $total products' : '$count products',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
