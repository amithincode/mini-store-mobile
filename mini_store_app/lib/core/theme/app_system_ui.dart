import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// System chrome shared by every screen.
///
/// The stock [SystemUiOverlayStyle.light] and [SystemUiOverlayStyle.dark]
/// constants paint the Android navigation bar opaque black. Mini Store keeps
/// that bar on the app surface colour instead, so the system back/home keys
/// match the rest of the UI. Only the status-bar icon brightness follows the
/// app bar colour.
abstract final class AppSystemUi {
  /// Default light chrome: transparent status bar with dark icons and a
  /// surface-coloured navigation bar.
  static const SystemUiOverlayStyle light = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  );

  /// Dark chrome: transparent status bar with light icons and a dark,
  /// surface-coloured navigation bar.
  static const SystemUiOverlayStyle dark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: AppColors.darkSurface,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  );

  /// Chrome that matches [brightness], used at the root of the app.
  static SystemUiOverlayStyle forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  /// Picks status-bar icons that read on [barColor]. The navigation bar
  /// follows [brightness] so a coloured bar never leaves a light strip below
  /// the content in dark mode.
  static SystemUiOverlayStyle forBar(
    Color barColor, {
    Brightness brightness = Brightness.light,
  }) {
    final base = forBrightness(brightness);
    final lightIcons =
        ThemeData.estimateBrightnessForColor(barColor) == Brightness.dark;
    if (!lightIcons) {
      return base;
    }

    return base.copyWith(
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );
  }
}
