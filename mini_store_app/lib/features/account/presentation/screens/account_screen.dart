import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../orders/presentation/cubit/order_history_cubit.dart';
import '../../../orders/presentation/cubit/order_history_state.dart';
import '../../../orders/presentation/order_history_lookup.dart';
import '../../../wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../../wishlist/presentation/cubit/wishlist_state.dart';
import '../../../wishlist/presentation/wishlist_lookup.dart';

/// Profile tab driven entirely by the persisted session.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will need to sign in again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('account-logout-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    await context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final session = state is AuthAuthenticated ? state.session : null;

        return AppScaffold(
          appBar: const AppAppBar(title: 'Account', subtitle: 'Your profile'),
          body: session == null
              ? const Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: AppEmptyView(
                      title: 'No account signed in',
                      message: 'Sign in to see your profile details.',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProfileCard(user: session.user),
                            const SizedBox(height: AppSpacing.lg),
                            _OrdersSection(
                              cubit: maybeOrderHistoryCubit(context),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _WishlistSection(
                              cubit: maybeWishlistCubit(context),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _DetailsCard(user: session.user),
                            const SizedBox(height: AppSpacing.lg),
                            const _AppearanceCard(),
                            const SizedBox(height: AppSpacing.lg),
                            OutlinedButton.icon(
                              key: const ValueKey('account-logout'),
                              onPressed: () => _confirmLogout(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                  color: AppColors.error.withValues(alpha: 0.4),
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text('Sign out'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            _ProfileAvatar(imageUrl: user.image),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: AppTypography.headlineSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '@${user.username}',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    return ClipOval(
      child: Container(
        width: 88,
        height: 88,
        color: context.palette.imageBackground,
        child: url.isEmpty
            ? const _AvatarPlaceholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const _AvatarPlaceholder();
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      size: 44,
      color: context.palette.textSecondary,
    );
  }
}

class _OrdersSection extends StatelessWidget {
  const _OrdersSection({this.cubit});

  final OrderHistoryCubit? cubit;

  static void _openAll(BuildContext context) {
    GoRouter.maybeOf(context)?.pushNamed(AppRoutes.ordersName);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = this.cubit;
    if (cubit == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
      bloc: cubit,
      builder: (context, state) {
        final recent = state.orders.take(3).toList(growable: false);
        final count = state.count;

        return Card(
          key: const ValueKey('account-orders'),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xxs,
                ),
                leading: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                title: Text(
                  'My orders',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  state.isLoading
                      ? 'Restoring your orders…'
                      : count == 0
                      ? 'Completed purchases will appear here.'
                      : '$count ${count == 1 ? 'order' : 'orders'} saved on this device',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                trailing: TextButton(
                  key: const ValueKey('account-orders-view-all'),
                  onPressed: () => _openAll(context),
                  child: const Text('View all'),
                ),
              ),
              if (recent.isNotEmpty) ...[
                const Divider(height: 1),
                ...recent.map(
                  (order) => ListTile(
                    key: ValueKey('account-order-${order.orderNumber}'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xxs,
                    ),
                    leading: Icon(
                      Icons.check_circle_rounded,
                      color: context.palette.success,
                      size: 20,
                    ),
                    title: Text(
                      order.orderNumber,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${formatOrderDate(order.placedAt)} · '
                      '${order.itemCount} '
                      '${order.itemCount == 1 ? 'item' : 'items'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      formatPrice(order.totalPaid),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => _openAll(context),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WishlistSection extends StatelessWidget {
  const _WishlistSection({this.cubit});

  final WishlistCubit? cubit;

  static void _openAll(BuildContext context) {
    GoRouter.maybeOf(context)?.pushNamed(AppRoutes.wishlistName);
  }

  static void _openProduct(BuildContext context, int productId) {
    GoRouter.maybeOf(context)?.pushNamed(
      AppRoutes.productDetailName,
      pathParameters: {'id': productId.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = this.cubit;
    if (cubit == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<WishlistCubit, WishlistState>(
      bloc: cubit,
      builder: (context, state) {
        final items = state.items.take(6).toList(growable: false);
        final count = state.count;

        return Card(
          key: const ValueKey('account-wishlist'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xxs,
                ),
                leading: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                title: Text(
                  'Wishlist',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  state.isLoading
                      ? 'Restoring your wishlist…'
                      : count == 0
                      ? 'Tap the heart on any product to save it here.'
                      : '$count ${count == 1 ? 'item' : 'items'} saved for later',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                trailing: TextButton(
                  key: const ValueKey('account-wishlist-view-all'),
                  onPressed: () => _openAll(context),
                  child: const Text('View all'),
                ),
              ),
              if (items.isNotEmpty) ...[
                const Divider(height: 1),
                SizedBox(
                  height: 164,
                  child: ListView.separated(
                    key: const ValueKey('account-wishlist-preview'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _WishlistPreview(
                        key: ValueKey(
                          'account-wishlist-item-${item.productId}',
                        ),
                        title: item.title,
                        price: item.price,
                        thumbnail: item.thumbnail,
                        onTap: () => _openProduct(context, item.productId),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WishlistPreview extends StatelessWidget {
  const _WishlistPreview({
    super.key,
    required this.title,
    required this.price,
    required this.thumbnail,
    required this.onTap,
  });

  final String title;
  final double price;
  final String thumbnail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.palette.imageBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxs),
                      child: AppNetworkImage(
                        imageUrl: thumbnail,
                        semanticLabel: title,
                        memCacheWidth: 180,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.productTitle,
                ),
                SizedBox(height: 5),
                Text(
                  formatPrice(price),
                  style: AppTypography.price.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.alternate_email_rounded,
            label: 'Username',
            value: user.username,
          ),
          const Divider(),
          _DetailRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: _valueOrFallback(user.email),
          ),
          const Divider(),
          _DetailRow(
            icon: Icons.wc_rounded,
            label: 'Gender',
            value: _capitalize(_valueOrFallback(user.gender)),
          ),
        ],
      ),
    );
  }

  static String _valueOrFallback(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'Not provided' : trimmed;
  }

  static String _capitalize(String value) {
    if (value.isEmpty || value == 'Not provided') {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxs,
      ),
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: context.palette.textSecondary,
        ),
      ),
      subtitle: Text(value, style: AppTypography.bodyMedium),
    );
  }
}

/// Appearance picker. The choice is persisted by [ThemeCubit] and restored on
/// the next launch.
class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, selectedMode) {
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xxs,
                ),
                leading: const Icon(
                  Icons.brightness_6_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                title: Text(
                  'Appearance',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Light, dark, or follow your device.',
                  style: AppTypography.bodySmall.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
              const Divider(),
              _AppearanceOption(
                mode: ThemeMode.light,
                label: 'Light',
                description: 'Always use the light theme',
                icon: Icons.light_mode_outlined,
                selectedMode: selectedMode,
              ),
              _AppearanceOption(
                mode: ThemeMode.dark,
                label: 'Dark',
                description: 'Always use the dark theme',
                icon: Icons.dark_mode_outlined,
                selectedMode: selectedMode,
              ),
              _AppearanceOption(
                mode: ThemeMode.system,
                label: 'System',
                description: 'Match your phone setting',
                icon: Icons.settings_suggest_outlined,
                selectedMode: selectedMode,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.mode,
    required this.label,
    required this.description,
    required this.icon,
    required this.selectedMode,
  });

  final ThemeMode mode;
  final String label;
  final String description;
  final IconData icon;
  final ThemeMode selectedMode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selected = mode == selectedMode;

    return ListTile(
      key: ValueKey('account-theme-${mode.name}'),
      onTap: () => context.read<ThemeCubit>().select(mode),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxs,
      ),
      leading: Icon(
        icon,
        size: 20,
        color: selected ? AppColors.primary : palette.textSecondary,
      ),
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        description,
        style: AppTypography.bodySmall.copyWith(color: palette.textSecondary),
      ),
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        size: 20,
        color: selected ? AppColors.primary : palette.border,
      ),
    );
  }
}
