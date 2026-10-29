import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/bottom_bar_auto_hide.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../app/router/app_router.dart';
import '../cubit/product_list_cubit.dart';
import '../cubit/product_list_state.dart';
import '../widgets/pagination_footer.dart';
import '../widgets/product_list_notice_banner.dart';
import '../widgets/product_sliver_grid.dart';
import '../widgets/product_section_header.dart';
import '../widgets/store_promo_banner.dart';
import '../widgets/store_search_field.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key, required this.createCubit, this.bottomBar});

  final ProductListCubit Function() createCubit;

  /// Drives the shell's bottom navigation while this tab scrolls.
  final BottomBarVisibilityController? bottomBar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductListCubit>(
      create: (context) => createCubit()..loadInitial(),
      child: _StoreView(bottomBar: bottomBar),
    );
  }
}

class _StoreView extends StatefulWidget {
  const _StoreView({this.bottomBar});

  final BottomBarVisibilityController? bottomBar;

  @override
  State<_StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<_StoreView>
    with SingleTickerProviderStateMixin {
  static const double _loadMoreThreshold = 420;
  static const double _collapseOffsetThreshold = 40;
  static const double _scrollDeltaThreshold = 6;
  static const double _expandedToolbarHeight = 68;
  static const double _collapsedToolbarHeight = AppAppBar.defaultToolbarHeight;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  /// 0 keeps the search row open, 1 tucks it into an app bar action.
  late final AnimationController _searchBarController;

  double _lastScrollOffset = 0;

  bool _searchPinnedOpen = false;

  @override
  void initState() {
    super.initState();
    _searchBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addStatusListener(_onSearchBarStatusChanged);
  }

  @override
  void dispose() {
    _searchBarController
      ..removeStatusListener(_onSearchBarStatusChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchBarStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _scheduleViewportCheck();
    }
  }

  void _setSearchCollapsed(bool collapsed) {
    if (collapsed) {
      if (_searchBarController.isCompleted ||
          _searchBarController.status == AnimationStatus.forward) {
        return;
      }
      _searchFocusNode.unfocus();
      _searchBarController.forward();
      return;
    }

    if (_searchBarController.isDismissed ||
        _searchBarController.status == AnimationStatus.reverse) {
      return;
    }
    _searchBarController.reverse();
  }

  void _openSearch() {
    _searchPinnedOpen = true;
    _setSearchCollapsed(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _showPlaceholder(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ProductListCubit>().clearSearch();
  }

  void _refreshProducts() {
    _searchPinnedOpen = false;
    _setSearchCollapsed(false);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    context.read<ProductListCubit>().refresh();
  }

  void _openNotifications() {
    if (GoRouter.maybeOf(context) == null) {
      _showPlaceholder(
        'Notifications are available in the full app experience.',
      );
      return;
    }
    context.pushNamed(AppRoutes.notificationsName);
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _lastScrollOffset = notification.metrics.pixels;
      _searchPinnedOpen = false;
    } else if (notification is ScrollUpdateNotification) {
      final offset = notification.metrics.pixels;
      final delta = offset - _lastScrollOffset;
      _lastScrollOffset = offset;

      if (offset <= 0 || delta < -_scrollDeltaThreshold) {
        _setSearchCollapsed(false);
      } else if (delta > _scrollDeltaThreshold &&
          offset > _collapseOffsetThreshold &&
          !_searchPinnedOpen) {
        _setSearchCollapsed(true);
      }
    } else if (notification is ScrollEndNotification &&
        notification.metrics.pixels <= 0) {
      _setSearchCollapsed(false);
    }

    if (notification.metrics.extentAfter < _loadMoreThreshold) {
      unawaited(context.read<ProductListCubit>().loadMore());
    }

    return false;
  }

  /// Wide web layouts can fit all ten products without scrolling, so check the
  /// viewport after layout and keep appending until the screen is covered.
  void _scheduleViewportCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final position = _scrollController.position;
      if (position.maxScrollExtent > 0 &&
          position.extentAfter >= _loadMoreThreshold) {
        return;
      }

      final cubit = context.read<ProductListCubit>();
      final state = cubit.state;
      if (state is ProductListLoaded &&
          state.hasMore &&
          !state.isRefreshing &&
          !state.isLoadingMore &&
          state.paginationFailure == null) {
        unawaited(cubit.loadMore());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.fromWidth(
      MediaQuery.sizeOf(context).width,
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final bannerHeight =
        metrics.bannerHeight + (textScale - 1).clamp(0.0, 2.0) * 110;
    final searchRowHeight = 72 + (textScale - 1).clamp(0.0, 2.0) * 24;

    // Built once and handed to the animation builder as its child so scrolling
    // the app bar open or closed never rebuilds the product list.
    final body = BlocListener<ProductListCubit, ProductListState>(
      listenWhen: (previous, current) => previous.query != current.query,
      listener: (context, state) {
        widget.bottomBar?.show();
        _setSearchCollapsed(false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      },
      child: BlocBuilder<ProductListCubit, ProductListState>(
        builder: (context, state) {
          _scheduleViewportCheck();

          return BottomBarAutoHide(
            controller: widget.bottomBar,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: RefreshIndicator(
                onRefresh: context.read<ProductListCubit>().refresh,
                child: CustomScrollView(
                  key: const ValueKey('store-scroll'),
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.only(
                        top: metrics.isMobile ? AppSpacing.lg : AppSpacing.xl,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _StoreHeader(
                          bannerHeight: bannerHeight,
                          state: state,
                          onRefresh: context.read<ProductListCubit>().refresh,
                          onShopNow: () => _showPlaceholder(
                            'Promotions are coming in a later phase.',
                          ),
                        ),
                      ),
                    ),
                    ..._contentSlivers(context, state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    return AnimatedBuilder(
      animation: _searchBarController,
      child: body,
      builder: (context, child) {
        final collapse = Curves.easeOutCubic.transform(
          _searchBarController.value,
        );
        final toolbarHeight =
            _expandedToolbarHeight +
            (_collapsedToolbarHeight - _expandedToolbarHeight) * collapse;
        final searchHeight = searchRowHeight * (1 - collapse);
        final showSearchRow = collapse < 0.999;
        final showSearchAction = collapse > 0.2;

        return AppScaffold(
          appBar: AppAppBar(
            title: 'Mini Store',
            subtitle: 'Everyday essentials',
            backgroundColor: AppColors.primaryGradient.colors.first,
            foregroundColor: Colors.white,
            toolbarHeight: toolbarHeight,
            showDivider: false,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            bottom: showSearchRow
                ? _HomeSearchBar(
                    height: searchHeight,
                    expandedHeight: searchRowHeight,
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    maxWidth: metrics.searchMaxWidth,
                    onChanged: context.read<ProductListCubit>().search,
                    onSubmitted: context.read<ProductListCubit>().submitSearch,
                    onClear: _clearSearch,
                  )
                : null,
            actions: [
              if (kIsWeb || metrics.isDesktop)
                _HomeAppBarAction(
                  tooltip: 'Refresh products',
                  onPressed: _refreshProducts,
                  icon: Icons.refresh_rounded,
                ),
              if (showSearchAction)
                _HomeAppBarAction(
                  tooltip: 'Search products',
                  onPressed: _openSearch,
                  icon: Icons.search_rounded,
                ),
              _HomeAppBarAction(
                tooltip: 'Notifications',
                onPressed: _openNotifications,
                icon: Icons.notifications_none_rounded,
              ),
            ],
          ),
          body: child!,
        );
      },
    );
  }

  List<Widget> _contentSlivers(BuildContext context, ProductListState state) {
    final cubit = context.read<ProductListCubit>();

    return switch (state) {
      ProductListInitial() || ProductListLoading() => <Widget>[
        _StateSliver(
          child: AppLoadingView(
            message: state.query.isEmpty
                ? 'Loading products…'
                : 'Searching products…',
          ),
        ),
      ],
      ProductListOfflineEmpty() => <Widget>[
        _StateSliver(
          child: AppErrorView(
            title: "You're offline",
            message: state.isSearch
                ? "You're offline and no saved search results are available."
                : "You're offline and no saved products are available.",
            retryLabel: 'Retry',
            onRetry: cubit.retryInitial,
          ),
        ),
      ],
      ProductListFailure() => <Widget>[
        _StateSliver(
          child: AppErrorView(
            title: state.isSearch
                ? "Couldn't search products"
                : "Couldn't load products",
            message: state.failure.message,
            onRetry: state.canRetry ? cubit.retryInitial : null,
            icon: state.failure.requiresReauthentication
                ? Icons.lock_clock_rounded
                : Icons.cloud_off_rounded,
          ),
        ),
      ],
      ProductListEmpty() => <Widget>[
        _StateSliver(
          child: AppEmptyView(
            title: state.isSearch ? 'No products found' : 'No products yet',
            message: state.isSearch
                ? 'No products found for your search. Try a different term.'
                : 'The product catalogue is empty right now. '
                      'Pull to refresh and try again.',
            icon: state.isSearch
                ? Icons.search_off_rounded
                : Icons.storefront_outlined,
            actionLabel: state.isSearch ? 'Clear search' : null,
            onAction: state.isSearch ? _clearSearch : null,
          ),
        ),
      ],
      ProductListLoaded() => <Widget>[
        SliverPadding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          sliver: ProductSliverGrid(
            products: state.products,
            onProductTap: (product) {
              // The production shell supplies GoRouter. The graceful fallback
              // keeps this reusable screen usable in isolated previews/tests.
              if (GoRouter.maybeOf(context) == null) {
                _showPlaceholder(
                  'Product details for ${product.title} are coming in a later phase.',
                );
                return;
              }
              context.pushNamed(
                AppRoutes.productDetailName,
                pathParameters: {'id': product.id.toString()},
              );
            },
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

    if (failure.requiresReauthentication) {
      return failure.message;
    }

    return "Couldn't load more products. Try again.";
  }
}

class _HomeAppBarAction extends StatelessWidget {
  const _HomeAppBarAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xxs),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 21),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.16),
          foregroundColor: Colors.white,
          minimumSize: const Size(40, 40),
        ),
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeSearchBar({
    required this.height,
    required this.expandedHeight,
    required this.controller,
    required this.focusNode,
    required this.maxWidth,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final double height;
  final double expandedHeight;
  final TextEditingController controller;
  final FocusNode focusNode;
  final double maxWidth;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: expandedHeight,
          maxHeight: expandedHeight,
          child: SizedBox(
            height: expandedHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final metrics = ResponsiveMetrics.fromWidth(
                  constraints.maxWidth,
                );

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.maxContentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.horizontalPadding,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: StoreSearchField(
                          controller: controller,
                          focusNode: focusNode,
                          maxWidth: maxWidth,
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                          onClear: onClear,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({
    required this.bannerHeight,
    required this.state,
    required this.onRefresh,
    required this.onShopNow,
  });

  final double bannerHeight;
  final ProductListState state;
  final Future<void> Function() onRefresh;
  final VoidCallback onShopNow;

  @override
  Widget build(BuildContext context) {
    final ProductListLoaded? loaded = state is ProductListLoaded
        ? state as ProductListLoaded
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.query.isEmpty) ...[
          StorePromoBanner(height: bannerHeight - 15, onShopNow: onShopNow),
          const SizedBox(height: AppSpacing.md),
        ],
        if (loaded?.notice != null) ...[
          ProductListNoticeBanner(notice: loaded!.notice!, onRetry: onRefresh),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state is ProductListLoaded || state is ProductListEmpty) ...[
          ProductSectionHeader(
            count: state.products.length,
            title: state.query.isEmpty ? 'Popular products' : 'Search results',
            subtitle: state.query.isEmpty
                ? 'Handpicked favourites for everyday living'
                : 'Results for "${state.query}"',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (loaded?.isRefreshing ?? false) ...[
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            child: LinearProgressIndicator(minHeight: 3),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _StateSliver extends StatelessWidget {
  const _StateSliver({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: child,
          ),
        ),
      ),
    );
  }
}
