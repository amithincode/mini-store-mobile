import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      appBar: AppAppBar(title: 'Categories', subtitle: 'Browse by department'),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: AppEmptyView(
            title: 'Categories are coming next',
            message:
                'Category browsing will be connected to the product API in '
                'the next phase.',
            icon: Icons.grid_view_rounded,
          ),
        ),
      ),
    );
  }
}
