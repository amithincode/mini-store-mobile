import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_line_item.dart';
import '../cubit/order_history_cubit.dart';
import '../cubit/order_history_state.dart';
import '../order_history_lookup.dart';

/// Every purchase completed on this device, newest first.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = maybeOrderHistoryCubit(context);

    return AppScaffold(
      appBar: AppAppBar(
        title: 'My orders',
        subtitle: 'Saved on this device',
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: cubit == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppEmptyView(
                  title: 'Orders unavailable',
                  message: 'Your saved orders could not be loaded.',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            )
          : BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
              bloc: cubit,
              builder: (context, state) {
                if (state.isLoading) {
                  return const AppLoadingView(
                    message: 'Restoring your orders…',
                  );
                }

                if (state.orders.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AppEmptyView(
                        title: 'No orders yet',
                        message:
                            'When you complete a purchase it will be saved '
                            'here automatically.',
                        icon: Icons.receipt_long_outlined,
                        actionLabel: 'Start shopping',
                        onAction: () => _goBack(context),
                      ),
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView.separated(
                      key: const ValueKey('orders-list'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.lg,
                      ),
                      itemCount: state.orders.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _Header(state: state);
                        }
                        return _OrderCard(order: state.orders[index - 1]);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  static void _goBack(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.store);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final OrderHistoryState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${state.count} ${state.count == 1 ? 'order' : 'orders'} · '
          '${formatPrice(state.totalSpent)} spent',
          style: AppTypography.bodySmall.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            state.errorMessage!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xxs),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final itemLabel = order.itemCount == 1
        ? '1 item'
        : '${order.itemCount} items';

    return Card(
      key: ValueKey('order-${order.orderNumber}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          leading: CircleAvatar(
            backgroundColor: palette.successContainer,
            foregroundColor: palette.onSuccessContainer,
            child: const Icon(Icons.receipt_long_rounded, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                formatPrice(order.totalPaid),
                style: AppTypography.titleSmall.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${formatOrderDate(order.placedAt)} · $itemLabel',
              style: AppTypography.bodySmall.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          children: [
            Divider(color: palette.border),
            ...order.items.map((item) => _OrderLine(item: item)),
          ],
        ),
      ),
    );
  }
}

class _OrderLine extends StatelessWidget {
  const _OrderLine({required this.item});

  final OrderLineItem item;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 44,
              color: palette.imageBackground,
              padding: const EdgeInsets.all(AppSpacing.xxs),
              child: AppNetworkImage(
                imageUrl: item.thumbnail,
                semanticLabel: item.title,
                memCacheWidth: 120,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '×${item.quantity}',
            style: AppTypography.bodySmall.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatPrice(item.lineTotal),
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
