import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_log_interceptor.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/app_storage.dart';
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
import '../../features/products/presentation/cubit/store_cubit.dart';
import '../router/app_router.dart';

/// Central service locator. Only bootstrap code and tests should touch this;
/// widgets receive dependencies through constructors.
final GetIt getIt = GetIt.instance;

/// Registers config, storage, authentication, the protected API client, the
/// store cubit, and the router. Safe to call once during bootstrap.
Future<void> configureDependencies({required AppConfig config}) async {
  if (!getIt.isRegistered<AppConfig>()) {
    getIt.registerSingleton<AppConfig>(config);
  }

  if (!getIt.isRegistered<AppStorage>()) {
    getIt.registerSingleton<AppStorage>(await AppStorage.create());
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
      return DioAuthRemoteDataSource(authDio);
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

  if (!getIt.isRegistered<StoreCubit>()) {
    getIt.registerFactory<StoreCubit>(() => StoreCubit());
  }

  if (!getIt.isRegistered<GoRouter>()) {
    getIt.registerLazySingleton<GoRouter>(
      () => AppRouter.create(
        authCubit: getIt<AuthCubit>(),
        createStoreCubit: () => getIt<StoreCubit>(),
      ),
    );
  }
}
