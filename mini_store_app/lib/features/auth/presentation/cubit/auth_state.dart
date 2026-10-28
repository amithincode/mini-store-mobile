import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_session.dart';
import 'login_form_state.dart';

/// Authentication states are mutually exclusive so loading, failure, and
/// success can never overlap.
sealed class AuthState extends Equatable {
  const AuthState({this.form = const LoginFormState()});

  final LoginFormState form;

  @override
  List<Object?> get props => [form];
}

/// Reading the persisted session while the splash screen is visible.
final class AuthChecking extends AuthState {
  const AuthChecking();
}

/// No session, ready for credentials.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({super.form});

  @override
  List<Object?> get props => [form];
}

/// A login request is in flight.
final class AuthSubmitting extends AuthState {
  const AuthSubmitting({required super.form});

  @override
  List<Object?> get props => [form];
}

/// The login request failed and [message] is safe to display.
final class AuthLoginFailure extends AuthState {
  const AuthLoginFailure({required super.form, required this.message});

  final String message;

  @override
  List<Object?> get props => [form, message];
}

/// A persisted session was restored or a login succeeded.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

/// The user signed out or the stored session could not be renewed.
final class AuthSignedOut extends AuthState {
  const AuthSignedOut({super.form, required this.message});

  final String message;

  @override
  List<Object?> get props => [form, message];
}
