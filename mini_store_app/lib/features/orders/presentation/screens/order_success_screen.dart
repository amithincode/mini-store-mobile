import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_system_ui.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/order.dart';

/// Confirmation screen for the locally completed dummy order.
///
/// The whole page sits on the success green so the moment reads as a single,
/// celebratory state. The summary card follows the active theme so the numbers
/// stay readable in dark mode.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.order,
    required this.onContinueShopping,
  });

  final Order order;
  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.forBar(
        AppColors.successDark,
        brightness: Theme.of(context).brightness,
      ),
      child: Scaffold(
        backgroundColor: AppColors.success,
        body: Stack(
          children: [
            const Positioned.fill(child: _SuccessBackdrop()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _SuccessTick(),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Order confirmed',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.onSuccess,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Thank you! Your order has been placed successfully.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.onSuccess.withValues(alpha: 0.82),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.successDeep.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _SummaryRow(
                                label: 'Order number',
                                value: order.orderNumber,
                                valueKey: const ValueKey(
                                  'order-success-number',
                                ),
                                emphasize: true,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _SummaryRow(
                                label: 'Items',
                                value:
                                    '${order.itemCount} '
                                    '${order.itemCount == 1 ? 'item' : 'items'}',
                                valueKey: const ValueKey('order-success-items'),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                child: Divider(),
                              ),
                              _SummaryRow(
                                label: 'Total paid',
                                value: formatPrice(order.totalPaid),
                                valueKey: const ValueKey('order-success-total'),
                                emphasize: true,
                                accent: palette.success,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton.icon(
                          key: const ValueKey('order-success-continue'),
                          onPressed: onContinueShopping,
                          icon: const Icon(Icons.storefront_rounded),
                          label: const Text('Continue shopping'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.successDeep,
                            minimumSize: const Size.fromHeight(54),
                            textStyle: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'This order is saved in My orders on this device.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSuccess.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBackdrop extends StatelessWidget {
  const _SuccessBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.success, AppColors.successDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _Glow(size: 240, opacity: 0.1),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _Glow(size: 280, opacity: 0.08),
          ),
          Positioned(
            top: 120,
            left: -30,
            child: _Glow(size: 90, opacity: 0.07),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

/// Animated success tick: a soft ring expands, then the check draws itself.
class _SuccessTick extends StatefulWidget {
  const _SuccessTick();

  @override
  State<_SuccessTick> createState() => _SuccessTickState();
}

class _SuccessTickState extends State<_SuccessTick>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Order placed successfully',
      child: SizedBox(
        width: 132,
        height: 132,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final ring = Curves.easeOut.transform(
              _controller.value.clamp(0.0, 0.55) / 0.55,
            );
            final tick = Curves.easeOutCubic.transform(
              ((_controller.value - 0.2) / 0.8).clamp(0.0, 1.0),
            );

            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 0.85 + ring * 0.35,
                  child: Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: 0.18 * (1 - ring) + 0.06,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.successDeep.withValues(alpha: 0.25),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(54, 54),
                      painter: _TickPainter(
                        progress: tick,
                        color: AppColors.successDark,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.115
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.54)
      ..lineTo(size.width * 0.42, size.height * 0.78)
      ..lineTo(size.width * 0.86, size.height * 0.26);

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueKey,
    this.emphasize = false,
    this.accent,
  });

  final String label;
  final String value;
  final Key valueKey;
  final bool emphasize;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            key: valueKey,
            textAlign: TextAlign.end,
            style: emphasize
                ? AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent ?? palette.textPrimary,
                  )
                : AppTypography.bodyMedium.copyWith(color: palette.textPrimary),
          ),
        ),
      ],
    );
  }
}
