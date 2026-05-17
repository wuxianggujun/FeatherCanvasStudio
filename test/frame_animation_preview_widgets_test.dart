import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

void main() {
  testWidgets('playback frame preview supports zoom controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1000,
              child: FrameAnimationPreviewPanel(
                title: 'Sprite Sheet 预览',
                emptyMessage: '暂无预览',
                errorMessage: null,
                debugRecord: null,
                generatedImages: [GeneratedImage.bytes(_pngOfColor(255, 0, 0))],
                isGenerating: false,
                rows: 1,
                columns: 1,
                gridSpec: const SpriteSheetGridSpec(rows: 1, columns: 1),
                onExportSpriteSheet: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('放大播放帧'));
    await tester.tap(find.byTooltip('放大播放帧'));
    await tester.pump();

    expect(find.text('125%'), findsOneWidget);
  });

  testWidgets('sprite sheet preview exposes pixelation editor shortcut', (
    tester,
  ) async {
    SpriteSheetPreviewData? openedPreviewData;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1000,
              child: FrameAnimationPreviewPanel(
                title: 'Sprite Sheet 预览',
                emptyMessage: '暂无预览',
                errorMessage: null,
                debugRecord: null,
                generatedImages: [GeneratedImage.bytes(_spriteSheetPng())],
                isGenerating: false,
                rows: 2,
                columns: 2,
                gridSpec: const SpriteSheetGridSpec(rows: 2, columns: 2),
                onExportSpriteSheet: (_) {},
                onOpenInEditor: (previewData) {
                  openedPreviewData = previewData;
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    final shortcut = find.text('像素化编辑');
    expect(shortcut, findsOneWidget);

    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();

    expect(openedPreviewData?.rows, 2);
    expect(openedPreviewData?.columns, 2);
  });

  testWidgets('mouse wheel zoom does not scroll the parent page', (
    tester,
  ) async {
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 420,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 260),
                  SizedBox(
                    width: 1000,
                    child: FrameAnimationPreviewPanel(
                      title: 'Sprite Sheet 预览',
                      emptyMessage: '暂无预览',
                      errorMessage: null,
                      debugRecord: null,
                      generatedImages: [
                        GeneratedImage.bytes(_pngOfColor(255, 0, 0)),
                      ],
                      isGenerating: false,
                      rows: 1,
                      columns: 1,
                      gridSpec: const SpriteSheetGridSpec(rows: 1, columns: 1),
                      onExportSpriteSheet: (_) {},
                    ),
                  ),
                  const SizedBox(height: 900),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.byType(InteractiveViewer));
    await tester.pump();

    final before = scrollController.offset;
    final pointer = TestPointer(1, ui.PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.byType(InteractiveViewer))),
    );
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -120)));
    await tester.pump();

    expect(scrollController.offset, before);
    expect(find.text('100%'), findsNothing);
  });

  testWidgets('preview sheet click selects replacement target frame', (
    tester,
  ) async {
    var selectedFrameIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: SizedBox(
                  width: 1000,
                  child: FrameAnimationPreviewPanel(
                    title: '切片查看',
                    emptyMessage: '暂无预览',
                    errorMessage: null,
                    debugRecord: null,
                    generatedImages: [GeneratedImage.bytes(_spriteSheetPng())],
                    isGenerating: false,
                    rows: 2,
                    columns: 2,
                    gridSpec: const SpriteSheetGridSpec(rows: 2, columns: 2),
                    selectedFrameIndex: selectedFrameIndex,
                    enablePlayback: false,
                    onFrameSelected: (index) =>
                        setState(() => selectedFrameIndex = index),
                    onExportSpriteSheet: (_) {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.textContaining('当前目标：第 1 帧'), findsOneWidget);

    final canvas = find.byKey(const ValueKey('sprite-sheet-preview-canvas'));
    await tester.ensureVisible(canvas);
    final canvasRect = tester.getRect(canvas);
    await tester.tapAt(
      canvasRect.topLeft +
          Offset(canvasRect.width * 0.75, canvasRect.height * 0.75),
    );
    await tester.pump();
    await tester.pump();

    expect(selectedFrameIndex, 3);
    expect(find.textContaining('当前目标：第 4 帧'), findsOneWidget);
  });
}

Uint8List _pngOfColor(int red, int green, int blue) {
  final image = image_lib.Image(width: 4, height: 4)
    ..clear(image_lib.ColorRgb8(red, green, blue));
  return Uint8List.fromList(image_lib.encodePng(image));
}

Uint8List _spriteSheetPng() {
  final image = image_lib.Image(width: 4, height: 4);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final isRight = x >= 2;
      final isBottom = y >= 2;
      image.setPixelRgb(
        x,
        y,
        isRight ? 0 : 255,
        isBottom ? 255 : 0,
        isRight && isBottom ? 255 : 0,
      );
    }
  }
  return Uint8List.fromList(image_lib.encodePng(image));
}
