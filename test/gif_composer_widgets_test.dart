import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

void main() {
  testWidgets('renders inline gif source frames without loading errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GifSourcePreviewPanel(
            frames: [
              GifSourceFrame.fromBytes(
                _pngOfColor(255, 0, 0),
                sourcePath: 'Sprite Sheet 预览',
                delayMs: 120,
                seed: 1,
                label: '第 1 帧',
              ),
            ],
            outputPath: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('加载失败'), findsNothing);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<MemoryImage>());
  });

  testWidgets('accepts custom gif frame durations', (tester) async {
    var defaultDelay = 120;
    var frameDelay = 120;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GifComposerPanel(
            frames: [
              GifSourceFrame.fromBytes(
                _pngOfColor(255, 0, 0),
                sourcePath: 'Sprite Sheet 预览',
                delayMs: frameDelay,
                seed: 1,
                label: '第 1 帧',
              ),
            ],
            defaultFrameDelayMs: defaultDelay,
            loopCount: 0,
            playbackMode: GifPlaybackMode.normal,
            isComposing: false,
            outputPath: null,
            errorMessage: null,
            onPickImages: () {},
            onClearImages: () {},
            onReorderImages: (_, _) {},
            onRemoveImageAt: (_) {},
            onFrameDelayChanged: (value) => defaultDelay = value,
            onApplyFrameDelayToAll: () {},
            onFrameDelayForImageChanged: (_, value) => frameDelay = value,
            onLoopCountChanged: (_) {},
            onPlaybackModeChanged: (_) {},
            onCompose: () {},
          ),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, '帧时长'), '375');
    await tester.enterText(find.widgetWithText(TextField, '默认帧时长'), '250');

    expect(frameDelay, 375);
    expect(defaultDelay, 250);
  });
}

Uint8List _pngOfColor(int red, int green, int blue) {
  final image = image_lib.Image(width: 2, height: 2)
    ..clear(image_lib.ColorRgb8(red, green, blue));
  return Uint8List.fromList(image_lib.encodePng(image));
}
