import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/theme/app_theme.dart';
import 'package:mini_store_app/features/account/presentation/screens/account_screen.dart';
import 'package:mini_store_app/features/auth/domain/entities/auth_session.dart';
import 'package:mini_store_app/features/auth/domain/entities/user.dart';
import 'package:mini_store_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mini_store_app/features/auth/presentation/cubit/auth_state.dart';

import '../../../../support/auth_test_doubles.dart';

const User _profileUser = User(
  id: 1,
  username: 'emilys',
  email: 'emily.johnson@x.dummyjson.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  gender: 'female',
);

AuthSession _sessionFor(User user) {
  return testSession(user: user);
}

Future<TestAuthDependencies> _pumpAccount(
  WidgetTester tester, {
  User user = _profileUser,
}) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final dependencies = TestAuthDependencies(session: _sessionFor(user));
  addTearDown(dependencies.dispose);
  await dependencies.cubit.restoreSession();

  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: dependencies.cubit,
      child: MaterialApp(theme: AppTheme.light, home: const AccountScreen()),
    ),
  );
  await tester.pump();

  return dependencies;
}

void main() {
  testWidgets('shows the saved profile without a network request', (
    tester,
  ) async {
    await _pumpAccount(tester);

    expect(find.text('Emily Johnson'), findsOneWidget);
    expect(find.text('@emilys'), findsOneWidget);
    expect(find.text('emily.johnson@x.dummyjson.com'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('uses placeholders for missing optional fields', (tester) async {
    await _pumpAccount(tester, user: const User(id: 2, username: 'minimal'));

    expect(find.text('minimal'), findsNWidgets(2));
    expect(find.text('@minimal'), findsOneWidget);
    expect(find.text('Not provided'), findsNWidgets(2));
  });

  testWidgets('cancelling the logout dialog keeps the session', (tester) async {
    final dependencies = await _pumpAccount(tester);

    await tester.tap(find.byKey(const ValueKey('account-logout')));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(dependencies.sessionRepository.clearCalls, 0);
    expect(dependencies.sessionRepository.session, isNotNull);
    expect(dependencies.cubit.state, isA<AuthAuthenticated>());
    expect(find.text('Emily Johnson'), findsOneWidget);
  });

  testWidgets('confirming logout clears the session', (tester) async {
    final dependencies = await _pumpAccount(tester);

    await tester.tap(find.byKey(const ValueKey('account-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-logout-confirm')));
    await tester.pumpAndSettle();

    expect(dependencies.sessionRepository.clearCalls, 1);
    expect(dependencies.sessionRepository.session, isNull);
    expect(dependencies.cubit.state, isA<AuthSignedOut>());
    expect(find.text('No account signed in'), findsOneWidget);
  });
}
