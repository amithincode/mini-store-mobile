import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/auth/domain/entities/auth_session.dart';
import 'package:mini_store_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:mini_store_app/features/auth/domain/entities/refresh_result.dart';
import 'package:mini_store_app/features/auth/domain/entities/user.dart';
import 'package:mini_store_app/features/auth/domain/failures/auth_failure.dart';
import 'package:mini_store_app/features/auth/presentation/cubit/auth_state.dart';

import '../../../../support/auth_test_doubles.dart';

void main() {
  test('restoring without a session requires authentication', () async {
    final dependencies = TestAuthDependencies();
    addTearDown(dependencies.dispose);

    expect(dependencies.cubit.state, isA<AuthChecking>());

    await dependencies.cubit.restoreSession();

    expect(dependencies.cubit.state, isA<AuthUnauthenticated>());
    expect(dependencies.authRepository.loginCalls, 0);
  });

  test(
    'restoring a saved session authenticates without calling login',
    () async {
      final session = testSession();
      final dependencies = TestAuthDependencies(session: session);
      addTearDown(dependencies.dispose);

      await dependencies.cubit.restoreSession();

      final state = dependencies.cubit.state;
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).session, session);
      expect(dependencies.authRepository.loginCalls, 0);
    },
  );

  test('ignores a second restore request', () async {
    final dependencies = TestAuthDependencies();
    addTearDown(dependencies.dispose);

    await dependencies.cubit.restoreSession();
    await dependencies.cubit.restoreSession();

    expect(dependencies.sessionRepository.readCalls, 1);
  });

  test(
    'empty credentials produce per-field errors without an API call',
    () async {
      final dependencies = TestAuthDependencies();
      addTearDown(dependencies.dispose);
      await dependencies.cubit.restoreSession();

      await dependencies.cubit.submit();

      final state = dependencies.cubit.state;
      expect(state, isA<AuthUnauthenticated>());
      expect(state.form.usernameError, 'Enter your username.');
      expect(state.form.passwordError, 'Enter your password.');
      expect(dependencies.authRepository.loginCalls, 0);
    },
  );

  test('typing clears the matching field error', () async {
    final dependencies = TestAuthDependencies();
    addTearDown(dependencies.dispose);
    await dependencies.cubit.restoreSession();
    await dependencies.cubit.submit();

    dependencies.cubit.usernameChanged('emilys');
    expect(dependencies.cubit.state.form.usernameError, isNull);
    expect(dependencies.cubit.state.form.passwordError, isNotNull);

    dependencies.cubit.passwordChanged('emilyspass');
    expect(dependencies.cubit.state.form.passwordError, isNull);
  });

  test('a valid submit trims the username and authenticates', () async {
    final dependencies = TestAuthDependencies();
    addTearDown(dependencies.dispose);
    await dependencies.cubit.restoreSession();

    dependencies.cubit
      ..usernameChanged('  emilys  ')
      ..passwordChanged('emilyspass');

    await dependencies.cubit.submit();

    expect(dependencies.cubit.state, isA<AuthAuthenticated>());
    expect(dependencies.authRepository.lastUsername, 'emilys');
    expect(dependencies.authRepository.lastPassword, 'emilyspass');
    expect(dependencies.sessionRepository.saveCalls, 1);
    expect(dependencies.sessionRepository.session, isNotNull);
  });

  test('shows the API message when login fails and keeps the form', () async {
    final dependencies = TestAuthDependencies();
    addTearDown(dependencies.dispose);
    await dependencies.cubit.restoreSession();
    dependencies.authRepository.loginFailure = const InvalidCredentialsFailure(
      'Invalid credentials',
    );

    dependencies.cubit
      ..usernameChanged('emilys')
      ..passwordChanged('wrong');
    await dependencies.cubit.submit();

    final state = dependencies.cubit.state;
    expect(state, isA<AuthLoginFailure>());
    expect((state as AuthLoginFailure).message, 'Invalid credentials');
    expect(state.form.username, 'emilys');
    expect(dependencies.sessionRepository.saveCalls, 0);
  });

  test('ignores duplicate submits while a request is in flight', () async {
    final dependencies = TestAuthDependencies();
    addTearDown(dependencies.dispose);
    await dependencies.cubit.restoreSession();
    final completer = Completer<AuthSession>();
    dependencies.authRepository.loginCompleter = completer;

    dependencies.cubit
      ..usernameChanged('emilys')
      ..passwordChanged('emilyspass');

    final first = dependencies.cubit.submit();
    final second = dependencies.cubit.submit();

    expect(dependencies.cubit.state, isA<AuthSubmitting>());
    expect(dependencies.authRepository.loginCalls, 1);

    completer.complete(testSession());
    await Future.wait(<Future<void>>[first, second]);

    expect(dependencies.cubit.state, isA<AuthAuthenticated>());
  });

  test('toggles password visibility', () async {
    final dependencies = TestAuthDependencies();
    addTearDown(dependencies.dispose);
    await dependencies.cubit.restoreSession();

    expect(dependencies.cubit.state.form.obscurePassword, isTrue);

    dependencies.cubit.togglePasswordVisibility();

    expect(dependencies.cubit.state.form.obscurePassword, isFalse);
  });

  test('logout clears the session and signs out', () async {
    final dependencies = TestAuthDependencies(session: testSession());
    addTearDown(dependencies.dispose);
    await dependencies.cubit.restoreSession();

    await dependencies.cubit.logout();

    expect(dependencies.cubit.state, isA<AuthSignedOut>());
    expect(dependencies.sessionRepository.clearCalls, 1);
    expect(dependencies.sessionRepository.session, isNull);
  });

  test(
    'session expiration clears storage and signs out with the message',
    () async {
      final dependencies = TestAuthDependencies(session: testSession());
      addTearDown(dependencies.dispose);
      await dependencies.cubit.restoreSession();

      dependencies.expirationNotifier.notifyExpired('Your session expired.');
      await pumpEventQueue();

      final state = dependencies.cubit.state;
      expect(state, isA<AuthSignedOut>());
      expect((state as AuthSignedOut).message, 'Your session expired.');
      expect(dependencies.sessionRepository.session, isNull);
    },
  );

  test('logs login and logout without exposing the password', () async {
    final dependencies = TestAuthDependencies();
    addTearDown(dependencies.dispose);
    await dependencies.cubit.restoreSession();

    dependencies.cubit
      ..usernameChanged('emilys')
      ..passwordChanged('emilyspass');
    await dependencies.cubit.submit();
    await dependencies.cubit.logout();

    expect(dependencies.logs, contains('[AUTH] Restoring saved session.'));
    expect(
      dependencies.logs,
      contains('[AUTH] No saved session; showing login.'),
    );
    expect(dependencies.logs, contains('[AUTH] Login request for @emilys.'));
    expect(dependencies.logs, contains('[AUTH] Login succeeded for @emilys.'));
    expect(dependencies.logs, contains('[AUTH] Logout requested.'));
    expect(dependencies.logs, contains('[AUTH] Signed out.'));
    expect(
      dependencies.logs.any((line) => line.contains('emilyspass')),
      isFalse,
    );
  });

  test(
    'a refresh result merges the returned profile into the saved session',
    () async {
      final dependencies = TestAuthDependencies(session: testSession());
      addTearDown(dependencies.dispose);

      dependencies.authRepository.refreshResult = const RefreshResult(
        tokens: AuthTokens(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
        ),
        user: User(id: 1, username: 'emilys', email: 'updated@example.com'),
      );

      final refreshed = await dependencies.refreshSessionUseCase();

      expect(refreshed.accessToken, 'new-access');
      expect(refreshed.refreshToken, 'new-refresh');
      expect(refreshed.user.email, 'updated@example.com');
      expect(refreshed.user.firstName, testUser.firstName);
      expect(dependencies.sessionRepository.session, refreshed);
    },
  );
}
