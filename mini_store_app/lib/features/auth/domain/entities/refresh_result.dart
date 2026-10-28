import 'package:equatable/equatable.dart';

import 'auth_tokens.dart';
import 'user.dart';

/// A refresh response. [user] is only present when the API returns profile
/// fields alongside the renewed tokens.
class RefreshResult extends Equatable {
  const RefreshResult({required this.tokens, this.user});

  final AuthTokens tokens;
  final User? user;

  @override
  List<Object?> get props => [tokens, user];
}
