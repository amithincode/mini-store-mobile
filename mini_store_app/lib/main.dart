import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'app/app.dart';
import 'app/di/injector.dart';
import 'app/startup_error_app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
    final config = AppConfig.fromEnvironment(dotenv.env);
    await configureDependencies(config: config);

    runApp(
      MiniStoreApp(
        router: getIt<GoRouter>(),
        enableDevicePreview: !kReleaseMode,
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Mini Store failed to start: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(StartupErrorApp(message: error.toString()));
  }
}
