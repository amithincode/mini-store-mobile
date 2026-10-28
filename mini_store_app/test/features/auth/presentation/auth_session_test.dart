import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/features/auth/presentation/auth_session.dart';

void main() {
  test('starts signed out', () {
    final session = AuthSession();
    addTearDown(session.dispose);

    expect(session.isSignedIn, isFalse);
    expect(session.email, isNull);
  });

  test('signs in with a trimmed email and notifies listeners', () {
    final session = AuthSession();
    addTearDown(session.dispose);

    var notifications = 0;
    session.addListener(() => notifications++);

    session.signIn('  amit@example.com  ');

    expect(session.isSignedIn, isTrue);
    expect(session.email, 'amit@example.com');
    expect(notifications, 1);
  });

  test('ignores a repeated sign in for the same account', () {
    final session = AuthSession();
    addTearDown(session.dispose);

    var notifications = 0;
    session.addListener(() => notifications++);

    session.signIn('amit@example.com');
    session.signIn('amit@example.com');

    expect(notifications, 1);
  });

  test('signs out and notifies listeners', () {
    final session = AuthSession();
    addTearDown(session.dispose);

    session.signIn('amit@example.com');
    var notifications = 0;
    session.addListener(() => notifications++);

    session.signOut();

    expect(session.isSignedIn, isFalse);
    expect(session.email, isNull);
    expect(notifications, 1);
  });
}
