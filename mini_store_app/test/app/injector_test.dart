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
import 'package:mini_store_app/features/products/data/datasources/product_local_data_source.dart';
import 'package:mini_store_app/features/products/data/datasources/product_remote_data_source.dart';
import 'package:mini_store_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:mini_store_app/features/products/domain/repositories/product_repository.dart';
import 'package:mini_store_app/features/products/domain/usecases/get_cached_products_use_case.dart';
import 'package:mini_store_app/features/products/domain/usecases/get_products_use_case.dart';
import 'package:mini_store_app/features/products/domain/usecases/search_products_use_case.dart';
import 'package:mini_store_app/features/products/presentation/cubit/product_list_cubit.dart';
import 'package:mini_store_app/features/products/presentation/cubit/product_list_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppConfig _config(String baseUrl) {
  return AppConfig(
    apiBaseUrl: baseUrl,
    authLoginPath: '/auth/login',
    authRefreshPath: '/auth/refresh',
    productsPath: '/products',
    productsSearchPath: '/products/search',
    productDetailPath: '/products/{id}',
    categoriesPath: '/products/categories',
    categoryProductsPath: '/products/category/{slug}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.instance.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('registers config, storage, auth and product services, Dio, cubit, and '
      'router', () async {
    final config = _config('https://dummyjson.com');

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

    final firstCubit = getIt<ProductListCubit>();
    final secondCubit = getIt<ProductListCubit>();
    expect(firstCubit, isNot(same(secondCubit)));
    expect(firstCubit.state, isA<ProductListInitial>());
    await firstCubit.close();
    await secondCubit.close();

    expect(
      getIt<ProductLocalDataSource>(),
      isA<SharedPreferencesProductLocalDataSource>(),
    );
    expect(getIt<ProductRemoteDataSource>(), isA<DioProductRemoteDataSource>());
    expect(getIt<ProductRepository>(), isA<ProductRepositoryImpl>());
    expect(getIt<GetProductsUseCase>(), isA<GetProductsUseCase>());
    expect(getIt<SearchProductsUseCase>(), isA<SearchProductsUseCase>());
    expect(getIt<GetCachedProductsUseCase>(), isA<GetCachedProductsUseCase>());

    final router = getIt<GoRouter>();
    expect(getIt<GoRouter>(), same(router));
    expect(router.routeInformationProvider, isNotNull);
    router.dispose();
  });

  test('is safe to configure more than once', () async {
    final firstConfig = _config('https://dummyjson.com');

    await configureDependencies(config: firstConfig);
    await configureDependencies(config: _config('https://example.com'));

    expect(getIt<AppConfig>(), same(firstConfig));
    expect(getIt<AppStorage>(), isA<AppStorage>());
    expect(getIt<Dio>().options.baseUrl, firstConfig.apiBaseUrl);
    expect(
      getIt<Dio>().interceptors.whereType<AuthInterceptor>(),
      hasLength(1),
    );
  });
}
