import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/screens/login_page.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/products/presentation/cubit/store_cubit.dart';
import '../shell/main_shell.dart';
import 'go_router_refresh_stream.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String splashName = 'splash';
  static const String login = '/login';
  static const String loginName = 'login';
  static const String store = '/';
  static const String storeName = 'store';
}

/// Application routing. The auth cubit is the single source of truth; the
/// interceptor and widgets never navigate directly.
abstract final class AppRouter {
  static GoRouter create({
    required AuthCubit authCubit,
    required StoreCubit Function() createStoreCubit,
  }) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final isSplash = state.matchedLocation == AppRoutes.splash;
        final isLogin = state.matchedLocation == AppRoutes.login;

        return switch (authCubit.state) {
          AuthChecking() => isSplash ? null : AppRoutes.splash,
          AuthAuthenticated() => isSplash || isLogin ? AppRoutes.store : null,
          _ => isLogin ? null : AppRoutes.login,
        };
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: AppRoutes.splashName,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.loginName,
          builder: (context, state) {
            return BlocProvider<AuthCubit>.value(
              value: authCubit,
              child: const LoginPage(),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.store,
          name: AppRoutes.storeName,
          builder: (context, state) {
            return BlocProvider<AuthCubit>.value(
              value: authCubit,
              child: MainShell(createStoreCubit: createStoreCubit),
            );
          },
        ),
      ],
    );
  }
}
