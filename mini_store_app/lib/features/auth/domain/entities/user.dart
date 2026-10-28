import 'package:equatable/equatable.dart';

/// A signed-in customer profile returned by the authentication API.
///
/// Only the identifier and username are guaranteed; every other field is
/// optional so partial API payloads and older persisted sessions stay usable.
class User extends Equatable {
  const User({
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

  String get fullName {
    final parts = <String>[
      if (_hasText(firstName)) firstName!.trim(),
      if (_hasText(lastName)) lastName!.trim(),
    ];

    return parts.isEmpty ? username : parts.join(' ');
  }

  /// Keeps the current profile while applying any fields present in [other].
  User mergedWith(User other) {
    return User(
      id: other.id,
      username: other.username,
      email: other.email ?? email,
      firstName: other.firstName ?? firstName,
      lastName: other.lastName ?? lastName,
      gender: other.gender ?? gender,
      image: other.image ?? image,
    );
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    firstName,
    lastName,
    gender,
    image,
  ];
}
