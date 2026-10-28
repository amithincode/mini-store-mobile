import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/app_storage.dart';
import '../../features/auth/presentation/auth_session.dart';
import '../../features/products/presentation/cubit/store_cubit.dart';
import '../router/app_router.dart';

/// Central service locator. Only bootstrap code and tests should touch this;
/// widgets receive dependencies through constructors.
final GetIt getIt = GetIt.instance;

/// Registers config, storage, the future API client, the store cubit, and the
/// router. Safe to call once during bootstrap.
Future<void> configureDependencies({required AppConfig config}) async {
  if (!getIt.isRegistered<AppConfig>()) {
    getIt.registerSingleton<AppConfig>(config);
  }

  if (!getIt.isRegistered<AppStorage>()) {
    getIt.registerSingleton<AppStorage>(await AppStorage.create());
  }

  if (!getIt.isRegistered<Dio>()) {
    getIt.registerLazySingleton<Dio>(() => createDioClient(getIt<AppConfig>()));
  }

  if (!getIt.isRegistered<StoreCubit>()) {
    getIt.registerFactory<StoreCubit>(() => StoreCubit());
  }

  if (!getIt.isRegistered<AuthSession>()) {
    getIt.registerLazySingleton<AuthSession>(
      AuthSession.new,
      dispose: (session) => session.dispose(),
    );
  }

  if (!getIt.isRegistered<GoRouter>()) {
    getIt.registerLazySingleton<GoRouter>(
      () => AppRouter.create(
        createStoreCubit: () => getIt<StoreCubit>(),
        authSession: getIt<AuthSession>(),
      ),
    );
  }
}
