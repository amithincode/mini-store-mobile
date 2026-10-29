import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_log_interceptor.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/app_storage.dart';
import '../../core/theme/theme_cubit.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/interceptors/auth_interceptor.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/repositories/session_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/session_repository.dart';
import '../../features/auth/domain/session/session_expiration_notifier.dart';
import '../../features/auth/domain/usecases/login_use_case.dart';
import '../../features/auth/domain/usecases/logout_use_case.dart';
import '../../features/auth/domain/usecases/refresh_session_use_case.dart';
import '../../features/auth/domain/usecases/restore_session_use_case.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/products/domain/entities/product_list_source.dart';
import '../../features/products/data/datasources/product_local_data_source.dart';
import '../../features/products/data/datasources/product_remote_data_source.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/get_cached_products_use_case.dart';
import '../../features/products/domain/usecases/get_category_products_use_case.dart';
import '../../features/products/domain/usecases/get_products_use_case.dart';
import '../../features/products/domain/usecases/search_products_use_case.dart';
import '../../features/products/presentation/cubit/product_list_cubit.dart';
import '../../features/categories/data/datasources/category_local_data_source.dart';
import '../../features/categories/data/datasources/category_remote_data_source.dart';
import '../../features/categories/data/repositories/category_repository_impl.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/categories/domain/usecases/fetch_category_image_use_case.dart';
import '../../features/categories/domain/usecases/get_cached_categories_use_case.dart';
import '../../features/categories/domain/usecases/get_cached_category_images_use_case.dart';
import '../../features/categories/domain/usecases/get_categories_use_case.dart';
import '../../features/categories/domain/usecases/save_category_images_use_case.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/cart/data/datasources/cart_local_data_source.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/product_details/data/datasources/product_detail_local_data_source.dart';
import '../../features/product_details/data/datasources/product_detail_remote_data_source.dart';
import '../../features/product_details/data/repositories/product_detail_repository_impl.dart';
import '../../features/product_details/domain/repositories/product_detail_repository.dart';
import '../../features/product_details/domain/usecases/get_product_detail_use_case.dart';
import '../../features/product_details/presentation/cubit/product_detail_cubit.dart';
import '../../features/orders/data/datasources/order_local_data_source.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/orders/domain/services/order_number_generator.dart';
import '../../features/orders/domain/usecases/place_order_use_case.dart';
import '../../features/orders/presentation/cubit/checkout_cubit.dart';
import '../../features/orders/presentation/cubit/order_history_cubit.dart';
import '../../features/wishlist/data/datasources/wishlist_local_data_source.dart';
import '../../features/wishlist/data/repositories/wishlist_repository_impl.dart';
import '../../features/wishlist/domain/repositories/wishlist_repository.dart';
import '../../features/wishlist/presentation/cubit/wishlist_cubit.dart';
import '../router/app_router.dart';
import '../shell/main_tab_controller.dart';

/// Central service locator. Only bootstrap code and tests should touch this;
/// widgets receive dependencies through constructors.
final GetIt getIt = GetIt.instance;

/// Registers config, storage, authentication, the protected API client, the
/// product list dependencies, and the router. Safe to call once during
/// bootstrap.
Future<void> configureDependencies({required AppConfig config}) async {
  if (!getIt.isRegistered<AppConfig>()) {
    getIt.registerSingleton<AppConfig>(config);
  }

  if (!getIt.isRegistered<AppStorage>()) {
    getIt.registerSingleton<AppStorage>(await AppStorage.create());
  }

  if (!getIt.isRegistered<ThemeCubit>()) {
    getIt.registerLazySingleton<ThemeCubit>(
      () => ThemeCubit(getIt<AppStorage>()),
      dispose: (cubit) => cubit.close(),
    );
  }

  if (!getIt.isRegistered<SessionRepository>()) {
    getIt.registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(getIt<AppStorage>()),
    );
  }

  if (!getIt.isRegistered<ApiLogInterceptor>()) {
    getIt.registerLazySingleton<ApiLogInterceptor>(ApiLogInterceptor.new);
  }

  if (!getIt.isRegistered<AuthRemoteDataSource>()) {
    getIt.registerLazySingleton<AuthRemoteDataSource>(() {
      final authDio = createDioClient(
        getIt<AppConfig>(),
        logInterceptor: getIt<ApiLogInterceptor>(),
      );
      return DioAuthRemoteDataSource(authDio, getIt<AppConfig>());
    });
  }

  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<SessionExpirationNotifier>()) {
    getIt.registerLazySingleton<SessionExpirationNotifier>(
      SessionExpirationNotifier.new,
      dispose: (notifier) => notifier.dispose(),
    );
  }

  if (!getIt.isRegistered<RefreshSessionUseCase>()) {
    getIt.registerLazySingleton<RefreshSessionUseCase>(
      () => RefreshSessionUseCase(
        getIt<AuthRepository>(),
        getIt<SessionRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<LoginUseCase>()) {
    getIt.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(getIt<AuthRepository>(), getIt<SessionRepository>()),
    );
  }

  if (!getIt.isRegistered<RestoreSessionUseCase>()) {
    getIt.registerLazySingleton<RestoreSessionUseCase>(
      () => RestoreSessionUseCase(getIt<SessionRepository>()),
    );
  }

  if (!getIt.isRegistered<LogoutUseCase>()) {
    getIt.registerLazySingleton<LogoutUseCase>(
      () => LogoutUseCase(getIt<SessionRepository>()),
    );
  }

  if (!getIt.isRegistered<Dio>()) {
    getIt.registerLazySingleton<Dio>(() {
      final dio = createDioClient(
        getIt<AppConfig>(),
        logInterceptor: getIt<ApiLogInterceptor>(),
      );
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          sessionRepository: getIt<SessionRepository>(),
          refreshSession: getIt<RefreshSessionUseCase>(),
          expirationNotifier: getIt<SessionExpirationNotifier>(),
          config: getIt<AppConfig>(),
        ),
      );
      return dio;
    });
  }

  if (!getIt.isRegistered<AuthCubit>()) {
    getIt.registerLazySingleton<AuthCubit>(
      () => AuthCubit(
        loginUseCase: getIt<LoginUseCase>(),
        restoreSessionUseCase: getIt<RestoreSessionUseCase>(),
        logoutUseCase: getIt<LogoutUseCase>(),
        expirationNotifier: getIt<SessionExpirationNotifier>(),
        logger: (message) {
          if (kDebugMode) {
            debugPrint(message);
          }
        },
      ),
      dispose: (cubit) => cubit.close(),
    );
  }

  if (!getIt.isRegistered<ProductLocalDataSource>()) {
    getIt.registerLazySingleton<ProductLocalDataSource>(
      () => SharedPreferencesProductLocalDataSource(getIt<AppStorage>()),
    );
  }

  if (!getIt.isRegistered<ProductRemoteDataSource>()) {
    getIt.registerLazySingleton<ProductRemoteDataSource>(
      () => DioProductRemoteDataSource(getIt<Dio>(), getIt<AppConfig>()),
    );
  }

  if (!getIt.isRegistered<ProductRepository>()) {
    getIt.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(
        getIt<ProductRemoteDataSource>(),
        getIt<ProductLocalDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetProductsUseCase>()) {
    getIt.registerLazySingleton<GetProductsUseCase>(
      () => GetProductsUseCase(getIt<ProductRepository>()),
    );
  }

  if (!getIt.isRegistered<SearchProductsUseCase>()) {
    getIt.registerLazySingleton<SearchProductsUseCase>(
      () => SearchProductsUseCase(getIt<ProductRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCachedProductsUseCase>()) {
    getIt.registerLazySingleton<GetCachedProductsUseCase>(
      () => GetCachedProductsUseCase(getIt<ProductRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCategoryProductsUseCase>()) {
    getIt.registerLazySingleton<GetCategoryProductsUseCase>(
      () => GetCategoryProductsUseCase(getIt<ProductRepository>()),
    );
  }

  if (!getIt.isRegistered<CategoryLocalDataSource>()) {
    getIt.registerLazySingleton<CategoryLocalDataSource>(
      () => SharedPreferencesCategoryLocalDataSource(getIt<AppStorage>()),
    );
  }

  if (!getIt.isRegistered<CategoryRemoteDataSource>()) {
    getIt.registerLazySingleton<CategoryRemoteDataSource>(
      () => DioCategoryRemoteDataSource(getIt<Dio>(), getIt<AppConfig>()),
    );
  }

  if (!getIt.isRegistered<CategoryRepository>()) {
    getIt.registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImpl(
        getIt<CategoryRemoteDataSource>(),
        getIt<CategoryLocalDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetCategoriesUseCase>()) {
    getIt.registerLazySingleton<GetCategoriesUseCase>(
      () => GetCategoriesUseCase(getIt<CategoryRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCachedCategoriesUseCase>()) {
    getIt.registerLazySingleton<GetCachedCategoriesUseCase>(
      () => GetCachedCategoriesUseCase(getIt<CategoryRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCachedCategoryImagesUseCase>()) {
    getIt.registerLazySingleton<GetCachedCategoryImagesUseCase>(
      () => GetCachedCategoryImagesUseCase(getIt<CategoryRepository>()),
    );
  }

  if (!getIt.isRegistered<FetchCategoryImageUseCase>()) {
    getIt.registerLazySingleton<FetchCategoryImageUseCase>(
      () => FetchCategoryImageUseCase(getIt<CategoryRepository>()),
    );
  }

  if (!getIt.isRegistered<SaveCategoryImagesUseCase>()) {
    getIt.registerLazySingleton<SaveCategoryImagesUseCase>(
      () => SaveCategoryImagesUseCase(getIt<CategoryRepository>()),
    );
  }

  if (!getIt.isRegistered<CategoriesCubit>()) {
    getIt.registerFactory<CategoriesCubit>(
      () => CategoriesCubit(
        getCategories: getIt<GetCategoriesUseCase>(),
        getCachedCategories: getIt<GetCachedCategoriesUseCase>(),
        getCachedImages: getIt<GetCachedCategoryImagesUseCase>(),
        fetchImage: getIt<FetchCategoryImageUseCase>(),
        saveImages: getIt<SaveCategoryImagesUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<ProductListCubit>()) {
    getIt.registerFactory<ProductListCubit>(
      () => ProductListCubit(
        getProducts: getIt<GetProductsUseCase>(),
        searchProducts: getIt<SearchProductsUseCase>(),
        getCachedProducts: getIt<GetCachedProductsUseCase>(),
        getCategoryProducts: getIt<GetCategoryProductsUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<CartLocalDataSource>()) {
    getIt.registerLazySingleton<CartLocalDataSource>(
      () => SharedPreferencesCartLocalDataSource(getIt<AppStorage>()),
    );
  }
  if (!getIt.isRegistered<CartRepository>()) {
    getIt.registerLazySingleton<CartRepository>(
      () => CartRepositoryImpl(getIt<CartLocalDataSource>()),
    );
  }
  if (!getIt.isRegistered<CartCubit>()) {
    getIt.registerLazySingleton<CartCubit>(
      () => CartCubit(getIt<CartRepository>())..loadCart(),
      dispose: (cubit) => cubit.close(),
    );
  }
  if (!getIt.isRegistered<WishlistLocalDataSource>()) {
    getIt.registerLazySingleton<WishlistLocalDataSource>(
      () => SharedPreferencesWishlistLocalDataSource(getIt<AppStorage>()),
    );
  }
  if (!getIt.isRegistered<WishlistRepository>()) {
    getIt.registerLazySingleton<WishlistRepository>(
      () => WishlistRepositoryImpl(getIt<WishlistLocalDataSource>()),
    );
  }
  if (!getIt.isRegistered<WishlistCubit>()) {
    getIt.registerLazySingleton<WishlistCubit>(
      () => WishlistCubit(getIt<WishlistRepository>())..loadWishlist(),
      dispose: (cubit) => cubit.close(),
    );
  }
  if (!getIt.isRegistered<ProductDetailLocalDataSource>()) {
    getIt.registerLazySingleton<ProductDetailLocalDataSource>(
      () => SharedPreferencesProductDetailLocalDataSource(getIt<AppStorage>()),
    );
  }
  if (!getIt.isRegistered<ProductDetailRemoteDataSource>()) {
    getIt.registerLazySingleton<ProductDetailRemoteDataSource>(
      () => DioProductDetailRemoteDataSource(getIt<Dio>(), getIt<AppConfig>()),
    );
  }
  if (!getIt.isRegistered<ProductDetailRepository>()) {
    getIt.registerLazySingleton<ProductDetailRepository>(
      () => ProductDetailRepositoryImpl(
        getIt<ProductDetailRemoteDataSource>(),
        getIt<ProductDetailLocalDataSource>(),
      ),
    );
  }
  if (!getIt.isRegistered<GetProductDetailUseCase>()) {
    getIt.registerLazySingleton<GetProductDetailUseCase>(
      () => GetProductDetailUseCase(getIt<ProductDetailRepository>()),
    );
  }
  if (!getIt.isRegistered<ProductDetailCubit>()) {
    getIt.registerFactory<ProductDetailCubit>(
      () => ProductDetailCubit(
        getDetail: getIt<GetProductDetailUseCase>(),
        repository: getIt<ProductDetailRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<MainTabController>()) {
    getIt.registerLazySingleton<MainTabController>(
      MainTabController.new,
      dispose: (controller) => controller.dispose(),
    );
  }

  if (!getIt.isRegistered<OrderNumberGenerator>()) {
    getIt.registerLazySingleton<OrderNumberGenerator>(
      RandomOrderNumberGenerator.new,
    );
  }

  if (!getIt.isRegistered<PlaceOrderUseCase>()) {
    getIt.registerLazySingleton<PlaceOrderUseCase>(
      () => PlaceOrderUseCase(getIt<OrderNumberGenerator>()),
    );
  }

  if (!getIt.isRegistered<OrderLocalDataSource>()) {
    getIt.registerLazySingleton<OrderLocalDataSource>(
      () => SharedPreferencesOrderLocalDataSource(getIt<AppStorage>()),
    );
  }

  if (!getIt.isRegistered<OrderRepository>()) {
    getIt.registerLazySingleton<OrderRepository>(
      () => OrderRepositoryImpl(getIt<OrderLocalDataSource>()),
    );
  }

  if (!getIt.isRegistered<OrderHistoryCubit>()) {
    getIt.registerLazySingleton<OrderHistoryCubit>(
      () => OrderHistoryCubit(getIt<OrderRepository>())..loadOrders(),
      dispose: (cubit) => cubit.close(),
    );
  }

  if (!getIt.isRegistered<CheckoutCubit>()) {
    getIt.registerLazySingleton<CheckoutCubit>(
      () => CheckoutCubit(
        cart: getIt<CartCubit>(),
        placeOrder: getIt<PlaceOrderUseCase>(),
        history: getIt<OrderHistoryCubit>(),
      ),
      dispose: (cubit) => cubit.close(),
    );
  }

  if (!getIt.isRegistered<GoRouter>()) {
    getIt.registerLazySingleton<GoRouter>(
      () => AppRouter.create(
        authCubit: getIt<AuthCubit>(),
        createProductListCubit: () => getIt<ProductListCubit>(),
        createCategoriesCubit: () => getIt<CategoriesCubit>(),
        createCategoryProductListCubit: (slug) => ProductListCubit(
          getProducts: getIt<GetProductsUseCase>(),
          searchProducts: getIt<SearchProductsUseCase>(),
          getCachedProducts: getIt<GetCachedProductsUseCase>(),
          getCategoryProducts: getIt<GetCategoryProductsUseCase>(),
          source: ProductListSource.category(slug),
        ),
        createProductDetailCubit: () => getIt<ProductDetailCubit>(),
        cartCubit: getIt<CartCubit>(),
        checkoutCubit: getIt<CheckoutCubit>(),
        wishlistCubit: getIt<WishlistCubit>(),
        orderHistoryCubit: getIt<OrderHistoryCubit>(),
        tabController: getIt<MainTabController>(),
      ),
    );
  }
}
