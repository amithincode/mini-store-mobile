import 'dart:async';

import 'package:mini_store_app/features/auth/domain/entities/auth_session.dart';
import 'package:mini_store_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:mini_store_app/features/auth/domain/entities/refresh_result.dart';
import 'package:mini_store_app/features/auth/domain/entities/user.dart';
import 'package:mini_store_app/features/auth/domain/failures/auth_failure.dart';
import 'package:mini_store_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mini_store_app/features/auth/domain/repositories/session_repository.dart';
import 'package:mini_store_app/features/auth/domain/session/session_expiration_notifier.dart';
import 'package:mini_store_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:mini_store_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:mini_store_app/features/auth/domain/usecases/refresh_session_use_case.dart';
import 'package:mini_store_app/features/auth/domain/usecases/restore_session_use_case.dart';
import 'package:mini_store_app/features/auth/presentation/cubit/auth_cubit.dart';

const User testUser = User(
  id: 1,
  username: 'emilys',
  email: 'emily.johnson@x.dummyjson.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  gender: 'female',
  image: 'https://dummyjson.com/icon/emilys/128',
);

AuthSession testSession({
  String accessToken = 'access-token',
  String refreshToken = 'refresh-token',
  User user = testUser,
}) {
  return AuthSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    user: user,
  );
}

class FakeAuthRepository implements AuthRepository {
  AuthSession? loginResult;
  AuthFailure? loginFailure;
  RefreshResult? refreshResult;
  AuthFailure? refreshFailure;
  Completer<AuthSession>? loginCompleter;
  Completer<RefreshResult>? refreshCompleter;

  int loginCalls = 0;
  int refreshCalls = 0;
  String? lastUsername;
  String? lastPassword;
  String? lastRefreshToken;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    lastUsername = username;
    lastPassword = password;

    final completer = loginCompleter;
    if (completer != null) {
      return completer.future;
    }
    if (loginFailure != null) {
      throw loginFailure!;
    }

    return loginResult ?? testSession();
  }

  @override
  Future<RefreshResult> refresh({required String refreshToken}) async {
    refreshCalls++;
    lastRefreshToken = refreshToken;

    final completer = refreshCompleter;
    if (completer != null) {
      return completer.future;
    }
    if (refreshFailure != null) {
      throw refreshFailure!;
    }

    return refreshResult ??
        const RefreshResult(
          tokens: AuthTokens(
            accessToken: 'refreshed-access-token',
            refreshToken: 'refreshed-refresh-token',
          ),
        );
  }
}

class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository({this.session});

  AuthSession? session;
  int readCalls = 0;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<AuthSession?> read() async {
    readCalls++;
    return session;
  }

  @override
  Future<void> save(AuthSession session) async {
    saveCalls++;
    this.session = session;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    session = null;
  }
}

class TestAuthDependencies {
  TestAuthDependencies({
    AuthSession? session,
    FakeAuthRepository? authRepository,
    List<String>? logs,
  }) : sessionRepository = FakeSessionRepository(session: session),
       authRepository = authRepository ?? FakeAuthRepository(),
       logs = logs ?? <String>[];

  final FakeAuthRepository authRepository;
  final FakeSessionRepository sessionRepository;
  final List<String> logs;
  final SessionExpirationNotifier expirationNotifier =
      SessionExpirationNotifier();

  late final LoginUseCase loginUseCase = LoginUseCase(
    authRepository,
    sessionRepository,
  );

  late final RestoreSessionUseCase restoreSessionUseCase =
      RestoreSessionUseCase(sessionRepository);

  late final LogoutUseCase logoutUseCase = LogoutUseCase(sessionRepository);

  late final RefreshSessionUseCase refreshSessionUseCase =
      RefreshSessionUseCase(authRepository, sessionRepository);

  late final AuthCubit cubit = AuthCubit(
    loginUseCase: loginUseCase,
    restoreSessionUseCase: restoreSessionUseCase,
    logoutUseCase: logoutUseCase,
    expirationNotifier: expirationNotifier,
    logger: logs.add,
  );

  Future<void> dispose() async {
    await cubit.close();
    await expirationNotifier.dispose();
  }
}
