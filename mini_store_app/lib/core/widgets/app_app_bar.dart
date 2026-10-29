import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_system_ui.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/responsive.dart';

/// Shared app bar with an optional subtitle and actions.
///
/// The bar's content follows the same max width and gutters as [AppScaffold]
/// so titles line up with page content on tablets and desktops.
///
/// The default look is the neutral surface bar. Screens such as Home can pass
/// [gradient] and [foregroundColor] to switch to the coloured variant without
/// duplicating the responsive layout.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.showDivider = true,
    this.systemOverlayStyle,
    this.borderRadius,
    this.toolbarHeight = defaultToolbarHeight,
    this.titleStyle,
    this.subtitleStyle,
  });

  static const double defaultToolbarHeight = 64;
  static const double dividerHeight = 1;

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// When set, the bar paints this gradient instead of [backgroundColor].
  final Gradient? gradient;
  final bool showDivider;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final BorderRadius? borderRadius;
  final double toolbarHeight;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (showDivider ? dividerHeight : 0));

  /// The tone actually painted behind the status bar, used to keep its icons
  /// readable. Gradients resolve to their darkest stop.
  Color get _barColor {
    final gradient = this.gradient;
    if (gradient is LinearGradient && gradient.colors.isNotEmpty) {
      return gradient.colors.reduce(
        (a, b) => a.computeLuminance() <= b.computeLuminance() ? a : b,
      );
    }
    return backgroundColor ?? AppColors.surface;
  }

  @override
  Widget build(BuildContext context) {
    final foreground = foregroundColor ?? AppColors.textPrimary;

    return AppBar(
      toolbarHeight: toolbarHeight,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: foreground,
      backgroundColor: gradient == null
          ? (backgroundColor ?? AppColors.surface)
          : Colors.transparent,
      systemOverlayStyle: systemOverlayStyle ?? AppSystemUi.forBar(_barColor),
      shape: borderRadius == null
          ? null
          : RoundedRectangleBorder(borderRadius: borderRadius!),
      clipBehavior: borderRadius == null ? Clip.none : Clip.antiAlias,
      flexibleSpace: gradient == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: borderRadius,
              ),
            ),
      title: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = ResponsiveMetrics.fromWidth(constraints.maxWidth);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxContentWidth,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding,
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (titleStyle ??
                                        AppTypography.titleLarge.copyWith(
                                          fontSize: 19,
                                        ))
                                    .copyWith(color: foreground),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  (subtitleStyle ??
                                          AppTypography.labelSmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ))
                                      .copyWith(
                                        color: foreground.withValues(
                                          alpha: 0.78,
                                        ),
                                      ),
                            ),
                        ],
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      ...actions,
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottom: showDivider
          ? PreferredSize(
              preferredSize: const Size.fromHeight(dividerHeight),
              child: Container(
                height: dividerHeight,
                color: foregroundColor == null
                    ? AppColors.border
                    : Colors.white.withValues(alpha: 0.18),
              ),
            )
          : null,
    );
  }
}
