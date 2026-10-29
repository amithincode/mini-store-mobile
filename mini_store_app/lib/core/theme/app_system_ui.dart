import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// System chrome shared by every screen.
///
/// The stock [SystemUiOverlayStyle.light] and [SystemUiOverlayStyle.dark]
/// constants paint the Android navigation bar opaque black. Mini Store keeps
/// that bar on the light app surface with dark buttons instead, so the system
/// back/home keys match the rest of the UI. Only the status-bar icon brightness
/// follows the app bar colour.
abstract final class AppSystemUi {
  /// Default chrome: transparent status bar with dark icons and a light,
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

  /// Picks status-bar icons that read on [barColor]. The navigation bar is
  /// always the app surface, so coloured bars never leave a dark strip below.
  static SystemUiOverlayStyle forBar(Color barColor) {
    final lightIcons =
        ThemeData.estimateBrightnessForColor(barColor) == Brightness.dark;
    if (!lightIcons) {
      return light;
    }

    return light.copyWith(
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );
  }
}
