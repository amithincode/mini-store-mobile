import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../products/presentation/utils/product_category_label.dart';

/// Horizontally scrollable category filter.
class CategoryChipList extends StatelessWidget {
  const CategoryChipList({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < categories.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xs),
            _buildChip(context, categories[index]),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String category) {
    final palette = context.palette;
    final isSelected = category == selectedCategory;

    return ChoiceChip(
      label: Text(productCategoryLabel(category)),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => onSelected(category),
      backgroundColor: palette.surface,
      selectedColor: palette.primaryContainer,
      side: BorderSide(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.35)
            : palette.border,
      ),
      labelStyle: AppTypography.labelLarge.copyWith(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? palette.onPrimaryContainer : palette.textSecondary,
      ),
    );
  }
}
