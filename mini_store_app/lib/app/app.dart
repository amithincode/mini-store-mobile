import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_system_ui.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_cubit.dart';

/// Root widget.
///
/// [router] and [themeCubit] are injected by bootstrap; [enableDevicePreview]
/// is disabled by tests and release builds.
class MiniStoreApp extends StatelessWidget {
  const MiniStoreApp({
    super.key,
    required this.router,
    required this.themeCubit,
    this.enableDevicePreview = true,
  });

  final GoRouter router;
  final ThemeCubit themeCubit;
  final bool enableDevicePreview;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      bloc: themeCubit,
      builder: (context, themeMode) {
        if (!enableDevicePreview) {
          return _buildApp(themeMode: themeMode);
        }

        return DevicePreview(
          enabled: true,
          builder: (context) {
            return _buildApp(
              themeMode: themeMode,
              locale: DevicePreview.locale(context),
              builder: DevicePreview.appBuilder,
              useInheritedMediaQuery: true,
            );
          },
        );
      },
    );
  }

  Widget _buildApp({
    required ThemeMode themeMode,
    Locale? locale,
    TransitionBuilder? builder,
    bool useInheritedMediaQuery = false,
  }) {
    return BlocProvider<ThemeCubit>.value(
      value: themeCubit,
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
        locale: locale,
        builder: (context, child) {
          final content = AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppSystemUi.forBrightness(Theme.of(context).brightness),
            child: child ?? const SizedBox.shrink(),
          );
          return builder == null ? content : builder(context, content);
        },
        // DevicePreview 1.3.x asserts this flag. Flutter 3.41 keeps the
        // parameter for compatibility even though the value is ignored.
        // ignore: deprecated_member_use
        useInheritedMediaQuery: useInheritedMediaQuery,
      ),
    );
  }
}
