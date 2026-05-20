import 'package:feather_canvas_studio/src/widgets/layout_navigation_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('responsive workspace split persists and resets width', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget buildSubject() {
      return const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 500,
            child: ResponsiveWorkspaceSplit(
              storageKey: 'test-split',
              controlsWidth: 320,
              minControlsWidth: 240,
              maxControlsWidth: 520,
              controls: SizedBox(
                key: ValueKey('controls-panel'),
                height: 500,
                child: ColoredBox(color: Colors.red),
              ),
              preview: SizedBox(
                key: ValueKey('preview-panel'),
                height: 500,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    final controls = find.byKey(const ValueKey('controls-panel'));
    expect(tester.getSize(controls).width, 320);

    final handle = find.byType(WorkspaceResizeHandle);
    expect(handle, findsOneWidget);
    expect(find.bySemanticsLabel('拖动调整宽度，双击复位'), findsOneWidget);

    expect(tester.getSize(handle).width, 20);
    expect(tester.getSize(handle).height, 500);

    await tester.drag(handle, const Offset(80, 0));
    await tester.pumpAndSettle();
    final draggedWidth = tester.getSize(controls).width;
    expect(draggedWidth, greaterThan(320));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(tester.getSize(controls).width, draggedWidth);

    await tester.tap(handle);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(handle);
    await tester.pumpAndSettle();
    expect(tester.getSize(controls).width, 320);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('workspaceSplit.controlsWidth.test-split'), isNull);
  });
}
