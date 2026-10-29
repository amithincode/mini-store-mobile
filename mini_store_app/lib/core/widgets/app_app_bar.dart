import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
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
    this.bottom,
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

  /// Optional second row rendered below the toolbar, above the divider.
  ///
  /// The bar adds the row's [PreferredSizeWidget.preferredSize] height to its
  /// own so the body starts below it.
  final PreferredSizeWidget? bottom;
  final bool showDivider;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final BorderRadius? borderRadius;
  final double toolbarHeight;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @override
  Size get preferredSize => Size.fromHeight(
    toolbarHeight +
        (bottom?.preferredSize.height ?? 0) +
        (showDivider ? dividerHeight : 0),
  );

  /// The tone actually painted behind the status bar, used to keep its icons
  /// readable. Gradients resolve to their darkest stop.
  Color _barColor(Color fallback) {
    final gradient = this.gradient;
    if (gradient is LinearGradient && gradient.colors.isNotEmpty) {
      return gradient.colors.reduce(
        (a, b) => a.computeLuminance() <= b.computeLuminance() ? a : b,
      );
    }
    return backgroundColor ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final foreground = foregroundColor ?? scheme.onSurface;

    return AppBar(
      toolbarHeight: toolbarHeight,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: foreground,
      backgroundColor: gradient == null
          ? (backgroundColor ?? scheme.surface)
          : Colors.transparent,
      systemOverlayStyle:
          systemOverlayStyle ??
          AppSystemUi.forBar(_barColor(scheme.surface), brightness: brightness),
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
                                            color: scheme.onSurfaceVariant,
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
      bottom: _buildBottom(scheme),
    );
  }

  /// Stacks the optional second row and the divider into the single slot an
  /// [AppBar] accepts.
  PreferredSizeWidget? _buildBottom(ColorScheme scheme) {
    final bottom = this.bottom;
    if (bottom == null && !showDivider) {
      return null;
    }

    final bottomHeight = bottom?.preferredSize.height ?? 0;

    return PreferredSize(
      preferredSize: Size.fromHeight(
        bottomHeight + (showDivider ? dividerHeight : 0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bottom != null) SizedBox(height: bottomHeight, child: bottom),
          if (showDivider)
            Container(
              height: dividerHeight,
              color: foregroundColor == null
                  ? scheme.outlineVariant
                  : Colors.white.withValues(alpha: 0.18),
            ),
        ],
      ),
    );
  }
}
