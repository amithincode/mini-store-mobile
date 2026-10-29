import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/products/presentation/cubit/product_list_cubit.dart';
import '../../features/products/presentation/screens/store_screen.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/cart/presentation/cubit/cart_state.dart';

/// Protected four-tab shell. Home keeps its existing screen and state.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.createProductListCubit});

  final ProductListCubit Function() createProductListCubit;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          StoreScreen(
            createCubit: widget.createProductListCubit,
            onCartTap: () => _selectTab(2),
          ),
          const CategoriesScreen(),
          const CartScreen(),
          const AccountScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: _CartNavIcon(selected: false),
            selectedIcon: _CartNavIcon(selected: true),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
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
