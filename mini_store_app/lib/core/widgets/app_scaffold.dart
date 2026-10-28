import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

/// Shared page shell: owns the scaffold, safe areas, content width, and
/// responsive gutters so feature screens only provide their body.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.resizeToAvoidBottomInset = true,
    this.bodyAlignment = Alignment.topCenter,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final bool resizeToAvoidBottomInset;
  final Alignment bodyAlignment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        // Scaffold already places the body below an app bar, which consumes
        // the status bar inset.
        top: appBar == null && safeAreaTop,
        bottom: safeAreaBottom,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = ResponsiveMetrics.fromWidth(constraints.maxWidth);

            return Align(
              alignment: bodyAlignment,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.maxContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.horizontalPadding,
                  ),
                  child: body,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
