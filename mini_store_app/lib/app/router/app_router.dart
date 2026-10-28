import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_session.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/products/presentation/cubit/store_cubit.dart';
import '../../features/products/presentation/screens/store_screen.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String loginName = 'login';
  static const String store = '/';
  static const String storeName = 'store';
}

/// Application routing. Feature screens receive their cubit factory through
/// this constructor instead of reaching into dependency injection.
abstract final class AppRouter {
  static GoRouter create({
    required StoreCubit Function() createStoreCubit,
    required AuthSession authSession,
  }) {
    return GoRouter(
      initialLocation: AppRoutes.login,
      refreshListenable: authSession,
      redirect: (context, state) {
        final isLoggingIn = state.matchedLocation == AppRoutes.login;

        if (!authSession.isSignedIn) {
          return isLoggingIn ? null : AppRoutes.login;
        }

        return isLoggingIn ? AppRoutes.store : null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.loginName,
          builder: (context, state) {
            return LoginScreen(onSignIn: authSession.signIn);
          },
        ),
        GoRoute(
          path: AppRoutes.store,
          name: AppRoutes.storeName,
          builder: (context, state) {
            return StoreScreen(createCubit: createStoreCubit);
          },
        ),
      ],
    );
  }
}
