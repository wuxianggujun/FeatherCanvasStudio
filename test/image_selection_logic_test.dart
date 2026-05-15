import 'dart:io';
import 'dart:typed_data';

import 'package:feather_canvas_studio/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'filters available image library items by kind and existing image file',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'image_selection_logic_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final existingImage = File(
        '${tempDir.path}${Platform.pathSeparator}image.png',
      );
      final existingText = File(
        '${tempDir.path}${Platform.pathSeparator}note.txt',
      );
      await existingImage.writeAsBytes([1], flush: true);
      await existingText.writeAsString('text', flush: true);

      final imageItem = _item(
        id: 'image',
        path: existingImage.path,
        kind: ImageAssetKind.generatedImage,
      );
      final textItem = _item(
        id: 'text',
        path: existingText.path,
        kind: ImageAssetKind.generatedImage,
      );
      final missingItem = _item(
        id: 'missing',
        path: '${tempDir.path}${Platform.pathSeparator}missing.png',
        kind: ImageAssetKind.generatedImage,
      );

      expect(
        availableImageLibraryItems(
          [imageItem, textItem, missingItem],
          allowedKinds: const [ImageAssetKind.generatedImage],
        ),
        [imageItem],
      );
      expect(
        availableImageLibraryItems(
          [imageItem],
          allowedKinds: const [ImageAssetKind.gif],
        ),
        isEmpty,
      );
    },
  );

  test('builds gif frames from paths and slices with stable labels', () {
    final pathFrames = buildGifFramesFromPaths(
      ['/tmp/a.png', '/tmp/b.png'],
      delayMs: 120,
      seedStart: 3,
    );
    final sheet = _item(
      id: 'sheet',
      path: '/tmp/sheet.png',
      kind: ImageAssetKind.spriteSheet,
      title: 'Sheet',
    );
    final sliceFrames = buildGifFramesFromSlices(
      sheet: sheet,
      slices: [
        MapEntry(0, Uint8List.fromList([1])),
        MapEntry(2, Uint8List.fromList([3])),
      ],
      delayMs: 160,
      seedStart: 5,
    );
    final libraryFrame = buildGifFrameFromLibraryItem(
      sheet,
      delayMs: 180,
      seed: 7,
    );

    expect(pathFrames.map((frame) => frame.path), ['/tmp/a.png', '/tmp/b.png']);
    expect(pathFrames.map((frame) => frame.delayMs), [120, 120]);
    expect(sliceFrames.map((frame) => frame.label), [
      'Sheet · 帧 1',
      'Sheet · 帧 3',
    ]);
    expect(
      sliceFrames.map((frame) => frame.inlineBytes),
      everyElement(isNotNull),
    );
    expect(libraryFrame.path, '/tmp/sheet.png');
    expect(libraryFrame.delayMs, 180);
  });
}

ImageLibraryItem _item({
  required String id,
  required String path,
  required ImageAssetKind kind,
  String title = '',
}) {
  return ImageLibraryItem(
    id: id,
    path: path,
    createdAt: DateTime.parse('2026-05-15T12:00:00Z'),
    kind: kind,
    title: title,
    source: 'test',
  );
}
