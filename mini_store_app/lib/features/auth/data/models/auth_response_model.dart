import 'user_model.dart';

/// Transport model shared by login and refresh responses.
class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserModel? user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final accessToken = _requiredToken(json['accessToken']);
    final refreshToken = _requiredToken(json['refreshToken']);

    return AuthResponseModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: _readUser(json),
    );
  }

  static UserModel? _readUser(Map<String, dynamic> json) {
    final nested = json['user'];

    if (nested is Map<String, dynamic>) {
      return UserModel.fromJson(nested);
    }

    if (json['id'] == null && json['username'] == null) {
      return null;
    }

    try {
      return UserModel.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  static String _requiredToken(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('The token payload is incomplete.');
    }

    return value.trim();
  }
}
