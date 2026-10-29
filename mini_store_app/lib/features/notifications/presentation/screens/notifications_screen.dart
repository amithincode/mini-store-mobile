import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_scaffold.dart';

/// Empty notifications inbox.
///
/// Notifications are intentionally out of scope for the dummy store; this
/// screen gives the Home bell a complete, explained destination.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _close(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      context.pop();
      return;
    }
    if (router != null) {
      context.go(AppRoutes.store);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        title: 'Notifications',
        subtitle: 'Order updates and offers',
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => _close(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _EmptyBell(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No notifications yet',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "You currently don't have any notifications. "
                  'Order updates and offers will appear here.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  key: const ValueKey('notifications-continue'),
                  onPressed: () => _close(context),
                  icon: const Icon(Icons.storefront_rounded),
                  label: const Text('Continue shopping'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBell extends StatelessWidget {
  const _EmptyBell();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'No notifications',
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: context.palette.primaryContainer.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.palette.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            Positioned(
              top: 24,
              right: 26,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.palette.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
