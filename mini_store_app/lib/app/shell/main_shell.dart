import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_app_bar.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/bottom_bar_auto_hide.dart';
import '../../core/widgets/state_views.dart';
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/cart/presentation/cubit/cart_state.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/products/presentation/cubit/product_list_cubit.dart';
import '../../features/products/presentation/screens/store_screen.dart';
import '../router/app_router.dart';
import 'main_tab_controller.dart';

/// Protected four-tab shell.
///
/// Tab selection lives in a shared [MainTabController] so screens pushed on top
/// of the shell (product details, order success) can return to a specific tab
/// without stacking duplicate shell routes.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.createProductListCubit,
    this.createCategoriesCubit,
    this.tabController,
  });

  final ProductListCubit Function() createProductListCubit;
  final CategoriesCubit Function()? createCategoriesCubit;
  final MainTabController? tabController;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  MainTabController? _ownedController;
  final BottomBarVisibilityController _bottomBar =
      BottomBarVisibilityController();

  MainTabController get _tabs {
    return widget.tabController ?? (_ownedController ??= MainTabController());
  }

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_handleTabChanged);
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabController != widget.tabController) {
      (oldWidget.tabController ?? _ownedController)?.removeListener(
        _handleTabChanged,
      );
      _ownedController?.dispose();
      _ownedController = null;
      _tabs.addListener(_handleTabChanged);
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_handleTabChanged);
    _bottomBar.dispose();
    _ownedController?.dispose();
    super.dispose();
  }

  /// Any tab change, including one triggered outside the shell (for example
  /// "go to cart" on the product page), brings the navigation bar back.
  void _handleTabChanged() => _bottomBar.show();

  void _selectTab(int index) {
    final previous = _tabs.index;
    _tabs.select(index);
    if (previous != index && index == MainTabController.homeIndex) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _openCategory(String slug, String name) {
    context.pushNamed(
      AppRoutes.categoryProductsName,
      pathParameters: {'slug': slug},
      queryParameters: {'name': name},
    );
  }

  void _goHome() => _tabs.selectHome();

  @override
  Widget build(BuildContext context) {
    final createCategoriesCubit = widget.createCategoriesCubit;

    return AnimatedBuilder(
      animation: _tabs,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _tabs.index,
            children: [
              StoreScreen(
                createCubit: widget.createProductListCubit,
                bottomBar: _bottomBar,
              ),
              if (createCategoriesCubit != null)
                CategoriesScreen(
                  createCubit: createCategoriesCubit,
                  bottomBar: _bottomBar,
                  onCategorySelected: (category) =>
                      _openCategory(category.slug, category.name),
                )
              else
                const _UnavailableTab(
                  title: 'Categories',
                  message: 'Categories are unavailable right now.',
                ),
              if (_findCartCubit(context) != null)
                CartScreen(onContinueShopping: _goHome)
              else
                const _UnavailableTab(
                  title: 'Cart',
                  message: 'Your cart is unavailable right now.',
                ),
              const AccountScreen(),
            ],
          ),
          bottomNavigationBar: ListenableBuilder(
            listenable: _bottomBar,
            builder: (context, child) {
              return AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _bottomBar.visible
                    ? NavigationBar(
                        selectedIndex: _tabs.index,
                        onDestinationSelected: _selectTab,
                        backgroundColor: AppColors.surface,
                        indicatorColor: AppColors.primaryContainer,
                        labelBehavior:
                            NavigationDestinationLabelBehavior.alwaysShow,
                        destinations: [
                          const NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home_rounded),
                            label: 'Home',
                          ),
                          const NavigationDestination(
                            icon: Icon(Icons.grid_view_outlined),
                            selectedIcon: Icon(Icons.grid_view_rounded),
                            label: 'Categories',
                          ),
                          NavigationDestination(
                            icon: _CartNavIcon(selected: false),
                            selectedIcon: _CartNavIcon(selected: true),
                            label: 'Cart',
                          ),
                          const NavigationDestination(
                            icon: Icon(Icons.person_outline_rounded),
                            selectedIcon: Icon(Icons.person_rounded),
                            label: 'Account',
                          ),
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              );
            },
          ),
        );
      },
    );
  }
}

class _UnavailableTab extends StatelessWidget {
  const _UnavailableTab({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(title: title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyView(
            title: title,
            message: message,
            icon: Icons.info_outline_rounded,
          ),
        ),
      ),
    );
  }
}

class _CartNavIcon extends StatelessWidget {
  const _CartNavIcon({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) {
    if (_findCartCubit(context) == null) {
      return Icon(
        selected ? Icons.shopping_cart_rounded : Icons.shopping_cart_outlined,
      );
    }
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) => Badge(
        isLabelVisible: state.itemCount > 0,
        label: Text(state.itemCount > 99 ? '99+' : '${state.itemCount}'),
        child: Icon(
          selected ? Icons.shopping_cart_rounded : Icons.shopping_cart_outlined,
        ),
      ),
    );
  }
}

CartCubit? _findCartCubit(BuildContext context) {
  try {
    return BlocProvider.of<CartCubit>(context, listen: false);
  } catch (_) {
    return null;
  }
}
