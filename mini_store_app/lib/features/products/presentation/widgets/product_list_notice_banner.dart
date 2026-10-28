import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/product_list_state.dart';

/// Inline banner shown above the grid when cached data is being displayed.
class ProductListNoticeBanner extends StatelessWidget {
  const ProductListNoticeBanner({
    super.key,
    required this.notice,
    this.onRetry,
  });

  final ProductListNotice notice;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isSession = notice.type == ProductListNoticeType.sessionExpired;
    final background = isSession
        ? AppColors.error.withValues(alpha: 0.08)
        : AppColors.accentContainer;
    final foreground = isSession ? AppColors.error : AppColors.textPrimary;
    final icon = switch (notice.type) {
      ProductListNoticeType.offlineShowingSaved => Icons.cloud_off_rounded,
      ProductListNoticeType.refreshFailed => Icons.sync_problem_rounded,
      ProductListNoticeType.searchRefreshFailed => Icons.search_off_rounded,
      ProductListNoticeType.sessionExpired => Icons.lock_clock_rounded,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              notice.message,
              style: AppTypography.bodySmall.copyWith(color: foreground),
            ),
          ),
          if (onRetry != null && !isSession) ...[
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
