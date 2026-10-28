import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/theme/app_theme.dart';
import 'package:mini_store_app/core/widgets/app_app_bar.dart';
import 'package:mini_store_app/core/widgets/app_scaffold.dart';

const Key _bodyKey = ValueKey('scaffold-body');

Future<void> _pumpScaffold(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: AppScaffold(
        appBar: AppAppBar(
          title: 'Mini Store',
          subtitle: 'Everyday essentials',
          actions: [
            IconButton(
              onPressed: () {},
              tooltip: 'Cart',
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
          ],
        ),
        body: const SizedBox(
          width: double.infinity,
          height: 200,
          child: ColoredBox(key: _bodyKey, color: Colors.white),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('uses a 64 px toolbar plus a 1 px divider', (tester) async {
    await _pumpScaffold(tester, 400);

    expect(find.text('Mini Store'), findsOneWidget);
    expect(find.text('Everyday essentials'), findsOneWidget);
    expect(find.byTooltip('Cart'), findsOneWidget);

    final appBar = tester.widget<AppAppBar>(find.byType(AppAppBar));
    expect(appBar.preferredSize, const Size.fromHeight(65));
  });

  testWidgets('applies mobile, tablet, and desktop gutters', (tester) async {
    await _pumpScaffold(tester, 400);
    expect(tester.getSize(find.byKey(_bodyKey)).width, 368);

    await _pumpScaffold(tester, 800);
    expect(tester.getSize(find.byKey(_bodyKey)).width, 752);

    await _pumpScaffold(tester, 1300);
    expect(tester.getSize(find.byKey(_bodyKey)).width, 1136);
  });

  testWidgets('caps content width on very large screens', (tester) async {
    await _pumpScaffold(tester, 1800);

    expect(tester.getSize(find.byKey(_bodyKey)).width, 1136);
  });
}
