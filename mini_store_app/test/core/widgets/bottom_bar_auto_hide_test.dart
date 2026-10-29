import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/widgets/bottom_bar_auto_hide.dart';

Widget _harness(
  BottomBarVisibilityController? controller, {
  int itemCount = 40,
}) {
  return MaterialApp(
    home: Scaffold(
      body: BottomBarAutoHide(
        controller: controller,
        child: ListView.builder(
          key: const ValueKey('list'),
          itemCount: itemCount,
          itemBuilder: (context, index) =>
              SizedBox(height: 96, child: Text('Item $index')),
        ),
      ),
    ),
  );
}

void main() {
  test('starts visible, hides, and stays visible without a controller', () {
    final controller = BottomBarVisibilityController();
    addTearDown(controller.dispose);

    expect(controller.visible, isTrue);
    controller.hide();
    expect(controller.visible, isFalse);
    controller.show();
    expect(controller.visible, isTrue);
  });

  testWidgets('hides on a downward scroll and restores after scrolling stops', (
    tester,
  ) async {
    final controller = BottomBarVisibilityController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(controller));

    await tester.drag(
      find.byKey(const ValueKey('list')),
      const Offset(0, -320),
    );
    await tester.pump();

    expect(controller.visible, isFalse);

    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.visible, isTrue);
  });

  testWidgets('shows immediately when the user scrolls back up', (
    tester,
  ) async {
    final controller = BottomBarVisibilityController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(controller));

    await tester.drag(
      find.byKey(const ValueKey('list')),
      const Offset(0, -320),
    );
    await tester.pump();
    expect(controller.visible, isFalse);

    await tester.drag(find.byKey(const ValueKey('list')), const Offset(0, 160));
    await tester.pump();

    expect(controller.visible, isTrue);
  });

  testWidgets('restores the bar when the list returns to the top', (
    tester,
  ) async {
    final controller = BottomBarVisibilityController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(controller));

    await tester.drag(
      find.byKey(const ValueKey('list')),
      const Offset(0, -320),
    );
    await tester.pump();
    expect(controller.visible, isFalse);

    await tester.drag(find.byKey(const ValueKey('list')), const Offset(0, 400));
    await tester.pump();

    expect(controller.visible, isTrue);
  });

  testWidgets('ignores scrolls when no controller is supplied', (tester) async {
    await tester.pumpWidget(_harness(null));

    await tester.drag(
      find.byKey(const ValueKey('list')),
      const Offset(0, -320),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('cancels the pending restore timer on dispose', (tester) async {
    final controller = BottomBarVisibilityController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(controller));
    await tester.drag(
      find.byKey(const ValueKey('list')),
      const Offset(0, -320),
    );
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(controller.visible, isFalse);
  });
}
