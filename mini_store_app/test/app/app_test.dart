import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/app/app.dart';
import 'package:mini_store_app/app/router/app_router.dart';
import 'package:mini_store_app/features/auth/presentation/auth_session.dart';
import 'package:mini_store_app/features/products/presentation/cubit/store_cubit.dart';

void main() {
  testWidgets('starts on login and gates the store until sign in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authSession = AuthSession();
    addTearDown(authSession.dispose);
    final router = AppRouter.create(
      createStoreCubit: StoreCubit.new,
      authSession: authSession,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MiniStoreApp(router: router, enableDevicePreview: false),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-email')), findsOneWidget);
    expect(find.text('Popular products'), findsNothing);

    router.go(AppRoutes.store);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-email')), findsOneWidget);
    expect(find.text('Popular products'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'amit@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'secret123',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(authSession.isSignedIn, isTrue);
    expect(find.text('No products yet'), findsOneWidget);
    expect(find.text('Popular products'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
