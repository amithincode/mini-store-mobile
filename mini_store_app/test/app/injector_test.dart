import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_store_app/app/di/injector.dart';
import 'package:mini_store_app/core/config/app_config.dart';
import 'package:mini_store_app/core/storage/app_storage.dart';
import 'package:mini_store_app/features/auth/presentation/auth_session.dart';
import 'package:mini_store_app/features/products/presentation/cubit/store_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.instance.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('registers config, storage, Dio, cubit, auth, and router', () async {
    const config = AppConfig(apiBaseUrl: 'https://dummyjson.com');

    await configureDependencies(config: config);

    expect(getIt<AppConfig>(), same(config));
    expect(getIt<AppStorage>(), isA<AppStorage>());

    final dio = getIt<Dio>();
    expect(dio.options.baseUrl, config.apiBaseUrl);
    expect(dio.options.headers['Accept'], 'application/json');

    final firstCubit = getIt<StoreCubit>();
    final secondCubit = getIt<StoreCubit>();
    expect(firstCubit, isNot(same(secondCubit)));
    expect(firstCubit.state.products, isEmpty);
    await firstCubit.close();
    await secondCubit.close();

    final authSession = getIt<AuthSession>();
    expect(authSession.isSignedIn, isFalse);

    final router = getIt<GoRouter>();
    expect(getIt<GoRouter>(), same(router));
    expect(router.routeInformationProvider, isNotNull);
    router.dispose();
  });

  test('is safe to configure more than once', () async {
    const firstConfig = AppConfig(apiBaseUrl: 'https://dummyjson.com');

    await configureDependencies(config: firstConfig);
    await configureDependencies(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
    );

    expect(getIt<AppConfig>(), same(firstConfig));
    expect(getIt<AppStorage>(), isA<AppStorage>());
    expect(getIt<Dio>().options.baseUrl, firstConfig.apiBaseUrl);
  });
}
