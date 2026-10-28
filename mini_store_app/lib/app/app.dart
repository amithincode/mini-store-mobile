import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

/// Root widget.
///
/// [router] is injected by bootstrap; [enableDevicePreview] is disabled by
/// tests and release builds.
class MiniStoreApp extends StatelessWidget {
  const MiniStoreApp({
    super.key,
    required this.router,
    this.enableDevicePreview = true,
  });

  final GoRouter router;
  final bool enableDevicePreview;

  @override
  Widget build(BuildContext context) {
    if (!enableDevicePreview) {
      return _buildApp();
    }

    return DevicePreview(
      enabled: true,
      builder: (context) {
        return _buildApp(
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          useInheritedMediaQuery: true,
        );
      },
    );
  }

  Widget _buildApp({
    Locale? locale,
    TransitionBuilder? builder,
    bool useInheritedMediaQuery = false,
  }) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: locale,
      builder: builder,
      // DevicePreview 1.3.x asserts this flag. Flutter 3.41 keeps the
      // parameter for compatibility even though the value is ignored.
      // ignore: deprecated_member_use
      useInheritedMediaQuery: useInheritedMediaQuery,
    );
  }
}
