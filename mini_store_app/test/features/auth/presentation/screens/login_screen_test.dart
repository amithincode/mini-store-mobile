import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/theme/app_theme.dart';
import 'package:mini_store_app/features/auth/presentation/screens/login_screen.dart';

Future<void> _pumpLogin(
  WidgetTester tester,
  ValueChanged<String> onSignIn,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: LoginScreen(onSignIn: onSignIn),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows validation errors for empty fields', (tester) async {
    String? signedInEmail;
    await _pumpLogin(tester, (email) => signedInEmail = email);

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );
    expect(signedInEmail, isNull);
  });

  testWidgets('rejects an invalid email and a short password', (tester) async {
    String? signedInEmail;
    await _pumpLogin(tester, (email) => signedInEmail = email);

    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'not-an-email',
    );
    await tester.enterText(find.byKey(const ValueKey('login-password')), '123');
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );
    expect(signedInEmail, isNull);
  });

  testWidgets('submits a trimmed valid email', (tester) async {
    String? signedInEmail;
    await _pumpLogin(tester, (email) => signedInEmail = email);

    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      '  amit@example.com  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'secret123',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(signedInEmail, 'amit@example.com');
    expect(find.text('Enter a valid email address.'), findsNothing);
  });

  testWidgets('toggles password visibility', (tester) async {
    await _pumpLogin(tester, (_) {});

    EditableText passwordField() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('login-password')),
        matching: find.byType(EditableText),
      ),
    );

    expect(passwordField().obscureText, isTrue);
    expect(find.byTooltip('Show password'), findsOneWidget);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(passwordField().obscureText, isFalse);
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });
}
