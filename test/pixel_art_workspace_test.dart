import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'dart:ui' show Tristate;

void main() {
  testWidgets('pixel art workspace draws and saves png bytes', (tester) async {
    Uint8List? savedBytes;
    int? savedWidth;
    int? savedHeight;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PixelArtWorkspace(
            onSaveToLibrary: (bytes, width, height) async {
              savedBytes = bytes;
              savedWidth = width;
              savedHeight = height;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final canvas = find.byKey(const ValueKey('pixel-art-canvas'));
    expect(canvas, findsOneWidget);
    final canvasRect = tester.getRect(canvas);
    await tester.tapAt(canvasRect.topLeft + const Offset(12, 12));
    await tester.pump();

    await tester.ensureVisible(find.text('保存到作品库'));
    await tester.tap(find.text('保存到作品库'));
    await tester.pumpAndSettle();

    expect(savedWidth, 32);
    expect(savedHeight, 32);
    expect(savedBytes, isNotNull);

    final image = image_lib.decodePng(savedBytes!);
    expect(image, isNotNull);
    expect(image!.width, 32);
    expect(image.height, 32);
    expect(image.getPixel(0, 0).a, 255);
  });

  testWidgets('pixel art workspace applies custom canvas size', (tester) async {
    Uint8List? savedBytes;
    int? savedWidth;
    int? savedHeight;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PixelArtWorkspace(
            onSaveToLibrary: (bytes, width, height) async {
              savedBytes = bytes;
              savedWidth = width;
              savedHeight = height;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final widthField = find.descendant(
      of: find.byKey(const ValueKey('pixel-art-width-control')),
      matching: find.byType(TextField),
    );
    final heightField = find.descendant(
      of: find.byKey(const ValueKey('pixel-art-height-control')),
      matching: find.byType(TextField),
    );

    await tester.enterText(widthField, '48');
    await tester.enterText(heightField, '40');
    await tester.tap(find.text('应用画布尺寸'));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const ValueKey('pixel-art-canvas'));
    final canvasRect = tester.getRect(canvas);
    await tester.tapAt(canvasRect.topLeft + const Offset(12, 12));
    await tester.pump();

    await tester.ensureVisible(find.text('保存到作品库'));
    await tester.tap(find.text('保存到作品库'));
    await tester.pumpAndSettle();

    expect(savedWidth, 48);
    expect(savedHeight, 40);
    expect(savedBytes, isNotNull);

    final image = image_lib.decodePng(savedBytes!);
    expect(image, isNotNull);
    expect(image!.width, 48);
    expect(image.height, 40);
    expect(image.getPixel(0, 0).a, 255);
  });

  testWidgets('pixel art workspace exposes fullscreen toggle', (tester) async {
    bool? requestedFocusMode;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PixelArtWorkspace(
            isFocusMode: false,
            onFocusModeChanged: (value) => requestedFocusMode = value,
            onSaveToLibrary: (_, _, _) async {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('进入全屏编辑'));
    await tester.pump();
    expect(requestedFocusMode, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PixelArtWorkspace(
            isFocusMode: true,
            onFocusModeChanged: (value) => requestedFocusMode = value,
            onSaveToLibrary: (_, _, _) async {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('退出全屏编辑'));
    await tester.pump();
    expect(requestedFocusMode, isFalse);
  });

  testWidgets('pixel art undo and redo expose disabled reasons', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PixelArtWorkspace(onSaveToLibrary: (_, _, _) async {}),
        ),
      ),
    );
    await tester.pump();

    expect(_semanticsWithValue('暂无可撤销操作'), findsWidgets);
    expect(_semanticsWithValue('暂无可重做操作'), findsWidgets);
  });

  testWidgets('pixel art color swatches expose labels and selection state', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PixelArtWorkspace(onSaveToLibrary: (_, _, _) async {}),
        ),
      ),
    );
    await tester.pump();

    Finder colorSwatch(String label) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    );

    final blackSwatch = colorSwatch('选择颜色 #111827');
    final redSwatch = colorSwatch('选择颜色 #EF4444');
    expect(blackSwatch, findsWidgets);
    expect(redSwatch, findsWidgets);
    expect(
      tester.getSemantics(blackSwatch.first).flagsCollection.isSelected,
      Tristate.isTrue,
    );

    await tester.ensureVisible(redSwatch.first);
    await tester.tap(redSwatch.first);
    await tester.pump();

    expect(
      tester.getSemantics(redSwatch.first).flagsCollection.isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('pixel art canvas supports keyboard cursor painting', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1400, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Uint8List? savedBytes;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PixelArtWorkspace(
            onSaveToLibrary: (bytes, _, _) async {
              savedBytes = bytes;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel('像素画画布 · 32 x 32 · 当前键盘光标第 1 列第 1 行，方向键移动，空格或回车绘制'),
      findsOneWidget,
    );

    final canvas = find.byKey(const ValueKey('pixel-art-canvas'));
    final canvasRect = tester.getRect(canvas);
    await tester.tapAt(canvasRect.topLeft + const Offset(12, 12));
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'pixel_art_canvas');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(
      find.bySemanticsLabel('像素画画布 · 32 x 32 · 当前键盘光标第 2 列第 2 行，方向键移动，空格或回车绘制'),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.ensureVisible(find.text('保存到作品库'));
    await tester.tap(find.text('保存到作品库'));
    await tester.pumpAndSettle();

    final image = image_lib.decodePng(savedBytes!);
    expect(image, isNotNull);
    expect(image!.getPixel(0, 0).a, 255);
    expect(image.getPixel(1, 1).a, 255);
  });
}

Finder _semanticsWithValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.value == value,
  );
}
