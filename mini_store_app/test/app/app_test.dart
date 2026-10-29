import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/app/app.dart';
import 'package:mini_store_app/app/router/app_router.dart';
import 'package:mini_store_app/core/theme/theme_cubit.dart';
import 'package:mini_store_app/features/auth/domain/entities/user.dart';
import 'package:mini_store_app/features/auth/presentation/cubit/auth_state.dart';

import '../features/products/support/product_test_doubles.dart';
import '../support/auth_test_doubles.dart';

const User _accountUser = User(
  id: 1,
  username: 'emilys',
  email: 'emily.johnson@x.dummyjson.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  gender: 'female',
);

void _sizeWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpApp(
  WidgetTester tester,
  TestAuthDependencies dependencies,
) async {
  final router = AppRouter.create(
    authCubit: dependencies.cubit,
    createProductListCubit: () => createTestProductListCubit(
      repository: FakeProductRepository(),
      searchDebounce: Duration.zero,
    ),
  );
  addTearDown(router.dispose);
  final themeCubit = ThemeCubit.inMemory();
  addTearDown(themeCubit.close);
  await tester.pumpWidget(
    MiniStoreApp(
      router: router,
      themeCubit: themeCubit,
      enableDevicePreview: false,
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows splash, gates the shell, and signs out to login', (
    tester,
  ) async {
    _sizeWindow(tester);
    final dependencies = TestAuthDependencies();
    addTearDown(dependencies.dispose);
    dependencies.authRepository.loginResult = testSession(user: _accountUser);

    await _pumpApp(tester, dependencies);
    expect(find.text('Checking your session…'), findsOneWidget);

    await dependencies.cubit.restoreSession();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-username')), findsOneWidget);
    expect(find.text('No products yet'), findsNothing);

    final router = tester
        .widget<MiniStoreApp>(find.byType(MiniStoreApp))
        .router;
    router.go(AppRoutes.store);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-username')), findsOneWidget);
    expect(find.text('No products yet'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('login-username')),
      'emilys',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'emilyspass',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(dependencies.cubit.state, isA<AuthAuthenticated>());
    expect(find.text('No products yet'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    expect(find.text('Emily Johnson'), findsOneWidget);
    expect(find.text('@emilys'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('account-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-logout-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-username')), findsOneWidget);
    expect(find.text('You have been signed out.'), findsOneWidget);
    expect(router.canPop(), isFalse);
    expect(dependencies.sessionRepository.session, isNull);
  });

  testWidgets('a saved session opens the shell without logging in again', (
    tester,
  ) async {
    _sizeWindow(tester);
    final dependencies = TestAuthDependencies(
      session: testSession(user: _accountUser),
    );
    addTearDown(dependencies.dispose);

    await _pumpApp(tester, dependencies);
    await dependencies.cubit.restoreSession();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-username')), findsNothing);
    expect(find.text('No products yet'), findsOneWidget);
    expect(dependencies.authRepository.loginCalls, 0);
  });

  testWidgets('expiration redirects to login and clears the stack', (
    tester,
  ) async {
    _sizeWindow(tester);
    final dependencies = TestAuthDependencies(
      session: testSession(user: _accountUser),
    );
    addTearDown(dependencies.dispose);

    await _pumpApp(tester, dependencies);
    await dependencies.cubit.restoreSession();
    await tester.pumpAndSettle();
    expect(find.text('No products yet'), findsOneWidget);

    dependencies.expirationNotifier.notifyExpired(
      'Your session expired. Please sign in again.',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-username')), findsOneWidget);
    expect(
      find.text('Your session expired. Please sign in again.'),
      findsOneWidget,
    );
    expect(dependencies.sessionRepository.session, isNull);

    final router = tester
        .widget<MiniStoreApp>(find.byType(MiniStoreApp))
        .router;
    expect(router.canPop(), isFalse);
  });
}
