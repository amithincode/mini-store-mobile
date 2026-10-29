import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/state_views.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/screens/login_page.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/orders/presentation/cubit/checkout_cubit.dart';
import '../../features/orders/presentation/screens/order_success_screen.dart';
import '../../features/product_details/presentation/cubit/product_detail_cubit.dart';
import '../../features/product_details/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/cubit/product_list_cubit.dart';
import '../../features/products/presentation/screens/category_products_screen.dart';
import '../shell/main_shell.dart';
import '../shell/main_tab_controller.dart';
import 'go_router_refresh_stream.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String splashName = 'splash';
  static const String login = '/login';
  static const String loginName = 'login';
  static const String store = '/';
  static const String storeName = 'store';
  static const String productDetail = '/products/:id';
  static const String productDetailName = 'productDetail';
  static const String categoryProducts = '/categories/:slug';
  static const String categoryProductsName = 'categoryProducts';
  static const String orderSuccess = '/order-success';
  static const String orderSuccessName = 'orderSuccess';
  static const String notifications = '/notifications';
  static const String notificationsName = 'notifications';
}

/// Application routing. The auth cubit is the single source of truth; the
/// interceptor and widgets never navigate directly.
abstract final class AppRouter {
  static GoRouter create({
    required AuthCubit authCubit,
    required ProductListCubit Function() createProductListCubit,
    CategoriesCubit Function()? createCategoriesCubit,
    ProductListCubit Function(String slug)? createCategoryProductListCubit,
    ProductDetailCubit Function()? createProductDetailCubit,
    CartCubit? cartCubit,
    CheckoutCubit? checkoutCubit,
    MainTabController? tabController,
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
            return MultiBlocProvider(
              providers: [
                BlocProvider<AuthCubit>.value(value: authCubit),
                if (cartCubit != null)
                  BlocProvider<CartCubit>.value(value: cartCubit),
                if (checkoutCubit != null)
                  BlocProvider<CheckoutCubit>.value(value: checkoutCubit),
              ],
              child: MainShell(
                createProductListCubit: createProductListCubit,
                createCategoriesCubit: createCategoriesCubit,
                tabController: tabController,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.notifications,
          name: AppRoutes.notificationsName,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.productDetail,
          name: AppRoutes.productDetailName,
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null || id <= 0) {
              return const Scaffold(
                body: Center(child: Text('Product not found')),
              );
            }
            if (cartCubit == null || createProductDetailCubit == null) {
              return const Scaffold(
                body: Center(child: Text('Product details are unavailable.')),
              );
            }

            return BlocProvider<CartCubit>.value(
              value: cartCubit,
              child: ProductDetailScreen(
                productId: id,
                createCubit: createProductDetailCubit,
                onGoToCart: () {
                  tabController?.selectCart();
                  context.go(AppRoutes.store);
                },
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.categoryProducts,
          name: AppRoutes.categoryProductsName,
          builder: (context, state) {
            final slug = (state.pathParameters['slug'] ?? '').trim();
            final name =
                state.uri.queryParameters['name']?.trim().isNotEmpty == true
                ? state.uri.queryParameters['name']!.trim()
                : slug.replaceAll('-', ' ');

            if (slug.isEmpty || createCategoryProductListCubit == null) {
              return const Scaffold(
                body: Center(child: Text('Category products are unavailable.')),
              );
            }

            return CategoryProductsScreen(
              slug: slug,
              name: name,
              createCubit: () => createCategoryProductListCubit(slug),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.orderSuccess,
          name: AppRoutes.orderSuccessName,
          builder: (context, state) {
            final order = checkoutCubit?.completedOrder;
            if (order == null) {
              return AppScaffold(
                body: Center(
                  child: AppErrorView(
                    title: 'Order not available',
                    message:
                        'We could not find the completed order. '
                        'Return to the store to continue shopping.',
                    retryLabel: 'Continue shopping',
                    onRetry: () {
                      tabController?.selectHome();
                      context.go(AppRoutes.store);
                    },
                  ),
                ),
              );
            }

            return OrderSuccessScreen(
              order: order,
              onContinueShopping: () {
                checkoutCubit?.reset();
                tabController?.selectHome();
                context.go(AppRoutes.store);
              },
            );
          },
        ),
      ],
    );
  }
}
