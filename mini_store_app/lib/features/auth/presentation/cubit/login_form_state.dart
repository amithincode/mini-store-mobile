import 'package:equatable/equatable.dart';

/// Form-only state owned by the auth cubit so the login page can stay stateless.
class LoginFormState extends Equatable {
  const LoginFormState({
    this.username = '',
    this.password = '',
    this.usernameError,
    this.passwordError,
    this.obscurePassword = true,
  });

  static const Object _unset = Object();

  final String username;
  final String password;
  final String? usernameError;
  final String? passwordError;
  final bool obscurePassword;

  LoginFormState copyWith({
    String? username,
    String? password,
    Object? usernameError = _unset,
    Object? passwordError = _unset,
    bool? obscurePassword,
  }) {
    return LoginFormState(
      username: username ?? this.username,
      password: password ?? this.password,
      usernameError: identical(usernameError, _unset)
          ? this.usernameError
          : usernameError as String?,
      passwordError: identical(passwordError, _unset)
          ? this.passwordError
          : passwordError as String?,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }

  @override
  List<Object?> get props => [
    username,
    password,
    usernameError,
    passwordError,
    obscurePassword,
  ];
}
