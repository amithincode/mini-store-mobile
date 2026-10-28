import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/products/presentation/cubit/product_list_cubit.dart';
import '../../features/products/presentation/screens/store_screen.dart';

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
        destinations: const [
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
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart_rounded),
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
