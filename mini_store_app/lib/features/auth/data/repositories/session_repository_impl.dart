import '../../../../core/storage/app_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/session_repository.dart';
import '../storage/auth_session_codec.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._storage);

  final AppStorage _storage;

  @override
  Future<AuthSession?> read() async {
    try {
      final raw = _storage.read<String>(AuthSessionCodec.key);
      if (raw == null) {
        return null;
      }

      final session = AuthSessionCodec.decode(raw);
      if (session == null) {
        await _storage.remove(AuthSessionCodec.key);
      }

      return session;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(AuthSession session) async {
    try {
      final saved = await _storage.write(
        AuthSessionCodec.key,
        AuthSessionCodec.encode(session),
      );
      if (!saved) {
        throw const StorageFailure();
      }
    } catch (error) {
      if (error is AuthFailure) {
        rethrow;
      }
      throw const StorageFailure();
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.remove(AuthSessionCodec.key);
    } catch (_) {
      throw const StorageFailure(
        'Your session could not be cleared. Please try again.',
      );
    }
  }
}
