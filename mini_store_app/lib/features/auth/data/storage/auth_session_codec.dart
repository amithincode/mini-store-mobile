import 'dart:convert';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';

/// JSON representation of the persisted session.
///
/// Required values are the token pair, user id, and username. Optional profile
/// fields stay nullable. Passwords are never written.
abstract final class AuthSessionCodec {
  static const String key = 'mini_store.auth.session.v1';
  static const int version = 1;

  static String encode(AuthSession session) {
    return jsonEncode(<String, dynamic>{
      'version': version,
      'accessToken': session.accessToken,
      'refreshToken': session.refreshToken,
      'user': <String, dynamic>{
        'id': session.user.id,
        'username': session.user.username,
        'email': session.user.email,
        'firstName': session.user.firstName,
        'lastName': session.user.lastName,
        'gender': session.user.gender,
        'image': session.user.image,
      },
    });
  }

  static AuthSession? decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['version'] != version) {
        return null;
      }

      final accessToken = _requiredString(decoded['accessToken']);
      final refreshToken = _requiredString(decoded['refreshToken']);
      final userJson = decoded['user'];

      if (accessToken == null ||
          refreshToken == null ||
          userJson is! Map<String, dynamic>) {
        return null;
      }

      final id = _requiredInt(userJson['id']);
      final username = _requiredString(userJson['username']);

      if (id == null || username == null) {
        return null;
      }

      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: User(
          id: id,
          username: username,
          email: _optionalString(userJson['email']),
          firstName: _optionalString(userJson['firstName']),
          lastName: _optionalString(userJson['lastName']),
          gender: _optionalString(userJson['gender']),
          image: _optionalString(userJson['image']),
        ),
      );
    } on FormatException {
      return null;
    }
  }

  static String? _requiredString(Object? value) {
    return switch (value) {
      String stringValue when stringValue.trim().isNotEmpty =>
        stringValue.trim(),
      _ => null,
    };
  }

  static String? _optionalString(Object? value) {
    return switch (value) {
      String stringValue when stringValue.trim().isNotEmpty =>
        stringValue.trim(),
      _ => null,
    };
  }

  static int? _requiredInt(Object? value) {
    final parsed = switch (value) {
      int intValue => intValue,
      num numValue => numValue.toInt(),
      String stringValue => int.tryParse(stringValue),
      _ => null,
    };

    return parsed != null && parsed > 0 ? parsed : null;
  }
}
