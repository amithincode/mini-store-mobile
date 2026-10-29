import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'app/app.dart';
import 'app/di/injector.dart';
import 'app/startup_error_app.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_system_ui.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppSystemUi.light);

  try {
    await dotenv.load();
    final config = AppConfig.fromEnvironment(dotenv.env);
    await configureDependencies(config: config);

    final router = getIt<GoRouter>();
    final authCubit = getIt<AuthCubit>();

    if (kDebugMode) {
      debugPrint(
        '[API] Network logging active. Each request, response, and error '
        'prints as a formatted JSON block.',
      );
    }

    runApp(MiniStoreApp(router: router, enableDevicePreview: false));
    // runApp(MiniStoreApp(router: router, enableDevicePreview: !kReleaseMode));
    unawaited(authCubit.restoreSession());
  } catch (error, stackTrace) {
    debugPrint('Mini Store failed to start: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(StartupErrorApp(message: error.toString()));
  }
}
