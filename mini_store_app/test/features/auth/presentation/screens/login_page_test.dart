import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/theme/app_theme.dart';
import 'package:mini_store_app/features/auth/domain/entities/auth_session.dart';
import 'package:mini_store_app/features/auth/domain/failures/auth_failure.dart';
import 'package:mini_store_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mini_store_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:mini_store_app/features/auth/presentation/screens/login_page.dart';

import '../../../../support/auth_test_doubles.dart';

Future<TestAuthDependencies> _pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final dependencies = TestAuthDependencies();
  addTearDown(dependencies.dispose);
  await dependencies.cubit.restoreSession();

  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: dependencies.cubit,
      child: MaterialApp(theme: AppTheme.light, home: const LoginPage()),
    ),
  );
  await tester.pump();

  return dependencies;
}

Future<void> _enterCredentials(
  WidgetTester tester, {
  String username = 'emilys',
  String password = 'emilyspass',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('login-username')),
    username,
  );
  await tester.enterText(
    find.byKey(const ValueKey('login-password')),
    password,
  );
}

void main() {
  testWidgets('shows an error for each empty field and skips the API', (
    tester,
  ) async {
    final dependencies = await _pumpLogin(tester);

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(find.text('Enter your username.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(dependencies.authRepository.loginCalls, 0);
  });

  testWidgets('clears a field error as soon as the user types', (tester) async {
    await _pumpLogin(tester);

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();
    expect(find.text('Enter your username.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('login-username')),
      'emilys',
    );
    await tester.pump();

    expect(find.text('Enter your username.'), findsNothing);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('signs in with the entered credentials', (tester) async {
    final dependencies = await _pumpLogin(tester);

    await _enterCredentials(tester);
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(dependencies.cubit.state, isA<AuthAuthenticated>());
    expect(dependencies.authRepository.lastUsername, 'emilys');
    expect(dependencies.authRepository.lastPassword, 'emilyspass');
  });

  testWidgets('shows the API message when credentials are rejected', (
    tester,
  ) async {
    final dependencies = await _pumpLogin(tester);
    dependencies.authRepository.loginFailure = const InvalidCredentialsFailure(
      'Invalid credentials',
    );

    await _enterCredentials(tester, password: 'wrong');
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
    expect(dependencies.cubit.state, isA<AuthLoginFailure>());
  });

  testWidgets('disables the submit button while signing in', (tester) async {
    final dependencies = await _pumpLogin(tester);
    final completer = Completer<AuthSession>();
    dependencies.authRepository.loginCompleter = completer;

    await _enterCredentials(tester);
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(find.text('Signing in…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('login-submit')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('login-password')))
          .enabled,
      isFalse,
    );

    completer.complete(testSession());
    await tester.pumpAndSettle();

    expect(dependencies.cubit.state, isA<AuthAuthenticated>());
  });

  testWidgets('toggles password visibility', (tester) async {
    await _pumpLogin(tester);

    EditableText passwordField() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('login-password')),
        matching: find.byType(EditableText),
      ),
    );

    expect(passwordField().obscureText, isTrue);
    expect(find.byTooltip('Show password'), findsOneWidget);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(passwordField().obscureText, isFalse);
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });
}
