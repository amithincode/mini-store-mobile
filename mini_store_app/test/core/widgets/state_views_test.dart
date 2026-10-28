import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/theme/app_theme.dart';
import 'package:mini_store_app/core/widgets/state_views.dart';

void main() {
  testWidgets('empty view renders and triggers its action', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppEmptyView(
            title: 'No products found',
            message: 'Try another search.',
            actionLabel: 'Clear filters',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No products found'), findsOneWidget);
    expect(find.text('Try another search.'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    expect(tapped, isTrue);
  });

  testWidgets('error view renders and retries', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppErrorView(
            message: 'Please try again.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Please try again.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('loading view renders a progress indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLoadingView(message: 'Loading products…')),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading products…'), findsOneWidget);
  });
}
