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
}

Uint8List _pngOfColor(int red, int green, int blue) {
  final image = image_lib.Image(width: 4, height: 4)
    ..clear(image_lib.ColorRgb8(red, green, blue));
  return Uint8List.fromList(image_lib.encodePng(image));
}
