import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/failures/auth_failure.dart';
import '../../domain/session/session_expiration_notifier.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/restore_session_use_case.dart';
import 'auth_state.dart';
import 'login_form_state.dart';

/// Coordinates authentication presentation state and use cases.
///
/// It never touches Dio, storage, or routing directly.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginUseCase loginUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
    required LogoutUseCase logoutUseCase,
    required SessionExpirationNotifier expirationNotifier,
    void Function(String message)? logger,
  }) : _loginUseCase = loginUseCase,
       _restoreSessionUseCase = restoreSessionUseCase,
       _logoutUseCase = logoutUseCase,
       _logger = logger,
       super(const AuthChecking()) {
    _expirationSubscription = expirationNotifier.stream.listen(
      _handleExpiration,
    );
  }

  final LoginUseCase _loginUseCase;
  final RestoreSessionUseCase _restoreSessionUseCase;
  final LogoutUseCase _logoutUseCase;
  final void Function(String message)? _logger;

  late final StreamSubscription<SessionExpirationEvent> _expirationSubscription;

  Future<void> restoreSession() async {
    if (state is! AuthChecking) {
      return;
    }

    _log('Restoring saved session.');
    try {
      final session = await _restoreSessionUseCase();
      if (isClosed) {
        return;
      }

      _log(
        session == null
            ? 'No saved session; showing login.'
            : 'Session restored for @${session.user.username}.',
      );
      emit(
        session == null
            ? const AuthUnauthenticated()
            : AuthAuthenticated(session),
      );
    } catch (_) {
      _log('Session restore failed; showing login.');
      if (!isClosed) {
        emit(const AuthUnauthenticated());
      }
    }
  }

  void usernameChanged(String value) {
    _updateForm((form) => form.copyWith(username: value, usernameError: null));
  }

  void passwordChanged(String value) {
    _updateForm((form) => form.copyWith(password: value, passwordError: null));
  }

  void togglePasswordVisibility() {
    _updateForm(
      (form) => form.copyWith(obscurePassword: !form.obscurePassword),
    );
  }

  Future<void> submit() async {
    if (state is AuthSubmitting ||
        state is AuthAuthenticated ||
        state is AuthChecking) {
      return;
    }

    final form = state.form;
    final username = form.username.trim();
    final password = form.password;
    final usernameError = username.isEmpty ? 'Enter your username.' : null;
    final passwordError = password.isEmpty ? 'Enter your password.' : null;

    if (usernameError != null || passwordError != null) {
      _log('Login blocked: missing username or password.');
      emit(
        AuthUnauthenticated(
          form: form.copyWith(
            username: username,
            usernameError: usernameError,
            passwordError: passwordError,
          ),
        ),
      );
      return;
    }

    _log('Login request for @$username.');
    emit(AuthSubmitting(form: form));

    try {
      final session = await _loginUseCase(
        username: username,
        password: password,
      );
      if (!isClosed) {
        _log('Login succeeded for @${session.user.username}.');
        emit(AuthAuthenticated(session));
      }
    } on AuthFailure catch (failure) {
      _log('Login failed: ${failure.message}');
      if (!isClosed) {
        emit(AuthLoginFailure(form: form, message: failure.message));
      }
    } catch (_) {
      _log('Login failed: unexpected error.');
      if (!isClosed) {
        emit(
          AuthLoginFailure(
            form: form,
            message: 'Something went wrong. Please try again.',
          ),
        );
      }
    }
  }

  Future<void> logout() async {
    _log('Logout requested.');
    try {
      await _logoutUseCase();
    } catch (_) {
      // The visible state still needs to leave the protected area.
    } finally {
      if (!isClosed) {
        _log('Signed out.');
        emit(const AuthSignedOut(message: 'You have been signed out.'));
      }
    }
  }

  void _updateForm(LoginFormState Function(LoginFormState) update) {
    final current = state;
    if (current is AuthChecking ||
        current is AuthSubmitting ||
        current is AuthAuthenticated) {
      return;
    }

    emit(AuthUnauthenticated(form: update(current.form)));
  }

  Future<void> _handleExpiration(SessionExpirationEvent event) async {
    _log('Session expired: ${event.message}');
    try {
      await _logoutUseCase();
    } catch (_) {
      // Storage was already cleared by the interceptor in the normal path.
    } finally {
      if (!isClosed) {
        emit(AuthSignedOut(message: event.message));
      }
    }
  }

  void _log(String message) => _logger?.call('[AUTH] $message');

  @override
  Future<void> close() async {
    await _expirationSubscription.cancel();
    return super.close();
  }
}
