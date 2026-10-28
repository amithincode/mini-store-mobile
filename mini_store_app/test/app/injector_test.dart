import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_store_app/app/di/injector.dart';
import 'package:mini_store_app/core/config/app_config.dart';
import 'package:mini_store_app/core/storage/app_storage.dart';
import 'package:mini_store_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mini_store_app/features/auth/data/interceptors/auth_interceptor.dart';
import 'package:mini_store_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mini_store_app/features/auth/data/repositories/session_repository_impl.dart';
import 'package:mini_store_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mini_store_app/features/auth/domain/repositories/session_repository.dart';
import 'package:mini_store_app/features/auth/domain/session/session_expiration_notifier.dart';
import 'package:mini_store_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mini_store_app/features/auth/presentation/cubit/auth_state.dart';
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

  test(
    'registers config, storage, auth services, Dio, cubit, and router',
    () async {
      const config = AppConfig(apiBaseUrl: 'https://dummyjson.com');

      await configureDependencies(config: config);

      expect(getIt<AppConfig>(), same(config));
      expect(getIt<AppStorage>(), isA<AppStorage>());
      expect(getIt<SessionRepository>(), isA<SessionRepositoryImpl>());
      expect(getIt<AuthRemoteDataSource>(), isA<DioAuthRemoteDataSource>());
      expect(getIt<AuthRepository>(), isA<AuthRepositoryImpl>());
      expect(
        getIt<SessionExpirationNotifier>(),
        isA<SessionExpirationNotifier>(),
      );

      final dio = getIt<Dio>();
      expect(dio.options.baseUrl, config.apiBaseUrl);
      expect(dio.options.headers['Accept'], 'application/json');
      expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));

      final cubit = getIt<AuthCubit>();
      expect(cubit.state, isA<AuthChecking>());

      final firstCubit = getIt<StoreCubit>();
      final secondCubit = getIt<StoreCubit>();
      expect(firstCubit, isNot(same(secondCubit)));
      expect(firstCubit.state.products, isEmpty);
      await firstCubit.close();
      await secondCubit.close();

      final router = getIt<GoRouter>();
      expect(getIt<GoRouter>(), same(router));
      expect(router.routeInformationProvider, isNotNull);
      router.dispose();
    },
  );

  test('is safe to configure more than once', () async {
    const firstConfig = AppConfig(apiBaseUrl: 'https://dummyjson.com');

    await configureDependencies(config: firstConfig);
    await configureDependencies(
      config: const AppConfig(apiBaseUrl: 'https://example.com'),
    );

    expect(getIt<AppConfig>(), same(firstConfig));
    expect(getIt<AppStorage>(), isA<AppStorage>());
    expect(getIt<Dio>().options.baseUrl, firstConfig.apiBaseUrl);
    expect(
      getIt<Dio>().interceptors.whereType<AuthInterceptor>(),
      hasLength(1),
    );
  });
}
