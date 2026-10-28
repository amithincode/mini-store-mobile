import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      appBar: AppAppBar(title: 'Cart', subtitle: 'Your selected items'),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: AppEmptyView(
            title: 'Your cart is empty',
            message:
                'Cart items and checkout arrive after product browsing is '
                'connected.',
            icon: Icons.shopping_cart_outlined,
          ),
        ),
      ),
    );
  }
}
