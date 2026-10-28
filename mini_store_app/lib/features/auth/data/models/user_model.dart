import '../../domain/entities/user.dart';

/// Transport model for the user fields returned by DummyJSON.
class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.gender,
    this.image,
  });

  final int id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? image;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = _readInt(json['id']);
    final username = _readString(json['username']);

    if (id == null || id <= 0 || username == null || username.isEmpty) {
      throw const FormatException('The user payload is incomplete.');
    }

    return UserModel(
      id: id,
      username: username,
      email: _readString(json['email']),
      firstName: _readString(json['firstName']),
      lastName: _readString(json['lastName']),
      gender: _readString(json['gender']),
      image: _readString(json['image']),
    );
  }

  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      image: image,
    );
  }

  static int? _readInt(Object? value) {
    return switch (value) {
      int intValue => intValue,
      num numValue => numValue.toInt(),
      String stringValue => int.tryParse(stringValue),
      _ => null,
    };
  }

  static String? _readString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
