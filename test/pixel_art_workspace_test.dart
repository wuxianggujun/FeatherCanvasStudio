import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

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
}
