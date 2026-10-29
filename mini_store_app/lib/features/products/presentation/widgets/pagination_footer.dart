import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Bottom-of-list loader and retry row for pagination.
class ProductPaginationFooter extends StatelessWidget {
  const ProductPaginationFooter({
    super.key,
    this.isLoading = false,
    this.failureMessage,
    this.onRetry,
  });

  final bool isLoading;
  final String? failureMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (failureMessage != null) {
      final palette = context.palette;
      return Container(
        key: const ValueKey('pagination-error'),
        margin: const EdgeInsets.only(top: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                failureMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      );
    }

    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return const Padding(
      key: ValueKey('pagination-loader'),
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}
