import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/theme/app_colors.dart';
import 'package:mini_store_app/core/theme/app_system_ui.dart';

void main() {
  test('default chrome keeps the system navigation bar light', () {
    expect(AppSystemUi.light.statusBarColor, Colors.transparent);
    expect(AppSystemUi.light.statusBarIconBrightness, Brightness.dark);
    expect(AppSystemUi.light.systemNavigationBarColor, AppColors.surface);
    expect(
      AppSystemUi.light.systemNavigationBarIconBrightness,
      Brightness.dark,
    );
    expect(
      AppSystemUi.light.systemNavigationBarDividerColor,
      Colors.transparent,
    );
    expect(AppSystemUi.light.systemStatusBarContrastEnforced, isFalse);
    expect(AppSystemUi.light.systemNavigationBarContrastEnforced, isFalse);
  });

  test('dark bars flip the status icons but keep the navigation bar light', () {
    final style = AppSystemUi.forBar(AppColors.successDark);

    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.statusBarBrightness, Brightness.dark);
    expect(style.systemNavigationBarColor, AppColors.surface);
    expect(style.systemNavigationBarIconBrightness, Brightness.dark);
  });

  test('light bars keep dark status icons', () {
    final style = AppSystemUi.forBar(AppColors.surface);

    expect(style.statusBarIconBrightness, Brightness.dark);
    expect(style.systemNavigationBarColor, AppColors.surface);
  });
}
