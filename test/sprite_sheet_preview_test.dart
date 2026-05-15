import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';

import 'package:feather_canvas_studio/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

void main() {
  test('stitches separate frame images into a sprite sheet preview', () async {
    final preview = await SpriteSheetPreviewComposer.build(
      images: [
        GeneratedImage.bytes(_pngOfColor(255, 0, 0)),
        GeneratedImage.bytes(_pngOfColor(0, 255, 0)),
        GeneratedImage.bytes(_pngOfColor(0, 0, 255)),
        GeneratedImage.bytes(_pngOfColor(255, 255, 0)),
      ],
      rows: 2,
      columns: 2,
    );

    final sheet = image_lib.decodeImage(preview.sheetBytes)!;
    final firstFrame = image_lib.decodeImage(preview.frameAt(0, 0))!;
    final secondFrame = image_lib.decodeImage(preview.frameAt(0, 1))!;

    expect(preview.rows, 2);
    expect(preview.columns, 2);
    expect(sheet.width, 4);
    expect(sheet.height, 4);
    expect(preview.sheetDisplaySizeForCell(12), const Size(24, 24));
    expect(
      preview.rowRectForDisplay(const Size(24, 24), 1),
      const Rect.fromLTWH(0, 12, 24, 12),
    );
    expect(
      preview.cellRectForDisplay(const Size(24, 24), 1, 1),
      const Rect.fromLTWH(12, 12, 12, 12),
    );
    expect(firstFrame.getPixel(0, 0).r.toInt(), 255);
    expect(firstFrame.getPixel(0, 0).g.toInt(), 0);
    expect(secondFrame.getPixel(0, 0).g.toInt(), 255);
  });

  test(
    'keeps a single generated frame as one frame in frame source mode',
    () async {
      final preview = await SpriteSheetPreviewComposer.build(
        images: [GeneratedImage.bytes(_pngOfColor(255, 0, 0))],
        rows: 2,
        columns: 2,
        sourceMode: SpriteSheetPreviewSourceMode.frames,
      );

      final firstFrame = image_lib.decodeImage(preview.frameAt(0, 0))!;
      final paddedFrame = image_lib.decodeImage(preview.frameAt(0, 1))!;

      expect(preview.frames, hasLength(4));
      expect(preview.frameWidth, 2);
      expect(preview.frameHeight, 2);
      expect(firstFrame.getPixel(0, 0).r.toInt(), 255);
      expect(paddedFrame.getPixel(0, 0).r.toInt(), 0);
    },
  );

  test('splits a single sprite sheet into frame previews', () async {
    final spriteSheet = image_lib.Image(width: 4, height: 4)
      ..clear(image_lib.ColorRgb8(0, 0, 0));

    image_lib.fillRect(
      spriteSheet,
      x1: 0,
      y1: 0,
      x2: 1,
      y2: 1,
      color: image_lib.ColorRgb8(255, 0, 0),
    );
    image_lib.fillRect(
      spriteSheet,
      x1: 2,
      y1: 0,
      x2: 3,
      y2: 1,
      color: image_lib.ColorRgb8(0, 255, 0),
    );
    image_lib.fillRect(
      spriteSheet,
      x1: 0,
      y1: 2,
      x2: 1,
      y2: 3,
      color: image_lib.ColorRgb8(0, 0, 255),
    );
    image_lib.fillRect(
      spriteSheet,
      x1: 2,
      y1: 2,
      x2: 3,
      y2: 3,
      color: image_lib.ColorRgb8(255, 255, 0),
    );

    final preview = await SpriteSheetPreviewComposer.build(
      images: [
        GeneratedImage.bytes(
          Uint8List.fromList(image_lib.encodePng(spriteSheet)),
        ),
      ],
      rows: 2,
      columns: 2,
    );

    final thirdFrame = image_lib.decodeImage(preview.frameAt(1, 0))!;
    final fourthFrame = image_lib.decodeImage(preview.frameAt(1, 1))!;
    final firstRowFrames = preview.framesForRow(0);

    expect(firstRowFrames, hasLength(2));
    expect(preview.frameWidth, 2);
    expect(preview.frameHeight, 2);
    expect(
      image_lib.decodeImage(firstRowFrames[0])!.getPixel(0, 0).r.toInt(),
      255,
    );
    expect(
      image_lib.decodeImage(firstRowFrames[1])!.getPixel(0, 0).g.toInt(),
      255,
    );
    expect(thirdFrame.getPixel(0, 0).b.toInt(), 255);
    expect(fourthFrame.getPixel(0, 0).r.toInt(), 255);
    expect(fourthFrame.getPixel(0, 0).g.toInt(), 255);
  });

  test('saves only the generated sprite sheet', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'sprite_sheet_output_cache_test_',
    );
    final store = AppLocalStore(baseDirectoryOverride: tempDir);
    final spriteSheet = image_lib.Image(width: 4, height: 4)
      ..clear(image_lib.ColorRgb8(0, 0, 0));

    image_lib.fillRect(
      spriteSheet,
      x1: 0,
      y1: 0,
      x2: 1,
      y2: 1,
      color: image_lib.ColorRgb8(255, 0, 0),
    );
    image_lib.fillRect(
      spriteSheet,
      x1: 2,
      y1: 0,
      x2: 3,
      y2: 1,
      color: image_lib.ColorRgb8(0, 255, 0),
    );
    image_lib.fillRect(
      spriteSheet,
      x1: 0,
      y1: 2,
      x2: 1,
      y2: 3,
      color: image_lib.ColorRgb8(0, 0, 255),
    );
    image_lib.fillRect(
      spriteSheet,
      x1: 2,
      y1: 2,
      x2: 3,
      y2: 3,
      color: image_lib.ColorRgb8(255, 255, 0),
    );

    final saveResult = await SpriteSheetOutputCache.saveSheetOnly(
      store: store,
      groupId: 'animation_test',
      sourceImage: GeneratedImage.bytes(
        Uint8List.fromList(image_lib.encodePng(spriteSheet)),
      ),
      rows: 2,
      columns: 2,
      resolveImageBytes: (image) async => image.bytes!,
    );

    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    expect(saveResult.sheet.filePath, isNotNull);
    expect(await File(saveResult.sheet.filePath!).exists(), isTrue);
    expect(saveResult.rows, 2);
    expect(saveResult.columns, 2);
    expect(saveResult.frameWidth, 2);
    expect(saveResult.frameHeight, 2);

    final savedSheet = image_lib.decodeImage(
      await File(saveResult.sheet.filePath!).readAsBytes(),
    )!;

    expect(savedSheet.width, 4);
    expect(savedSheet.height, 4);
    expect(savedSheet.getPixel(0, 0).r.toInt(), 255);
    expect(savedSheet.getPixel(2, 2).r.toInt(), 255);
    expect(savedSheet.getPixel(2, 2).g.toInt(), 255);
  });

  test('exports and saves edited sprite sheet files', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'sprite_sheet_file_service_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final store = AppLocalStore(baseDirectoryOverride: tempDir);
    final sheetPath = '${tempDir.path}${Platform.pathSeparator}sheet.png';
    final patchPath = '${tempDir.path}${Platform.pathSeparator}patch.png';
    await File(
      sheetPath,
    ).writeAsBytes(_pngOfColorWithSize(255, 0, 0, width: 4, height: 4));
    await File(patchPath).writeAsBytes(_pngOfColor(0, 255, 0));

    final exported = await SpriteSheetFileService.exportPng(
      store: store,
      pngBytes: _pngOfColor(0, 0, 255),
      rows: 2,
      columns: 2,
    );
    final edited = await SpriteSheetFileService.replaceFrameAndSave(
      store: store,
      readFileBytes: (path) => File(path).readAsBytes(),
      sheetPath: sheetPath,
      patchPath: patchPath,
      rows: 2,
      columns: 2,
      frameIndex: 1,
      fit: SpriteSheetFrameFit.stretch,
    );

    final editedImage = image_lib.decodeImage(
      await File(edited.path).readAsBytes(),
    )!;

    expect(exported.directoryPath, contains('generated-images'));
    expect(await File(exported.path).exists(), isTrue);
    expect(await File(edited.path).exists(), isTrue);
    expect(editedImage.getPixel(2, 0).g.toInt(), 255);
  });

  test('replaces one sprite sheet cell without changing other cells', () {
    final spriteSheet = image_lib.Image(width: 4, height: 4)
      ..clear(image_lib.ColorRgb8(0, 0, 0));
    image_lib.fillRect(
      spriteSheet,
      x1: 0,
      y1: 0,
      x2: 1,
      y2: 1,
      color: image_lib.ColorRgb8(255, 0, 0),
    );
    image_lib.fillRect(
      spriteSheet,
      x1: 2,
      y1: 0,
      x2: 3,
      y2: 1,
      color: image_lib.ColorRgb8(0, 255, 0),
    );
    image_lib.fillRect(
      spriteSheet,
      x1: 0,
      y1: 2,
      x2: 1,
      y2: 3,
      color: image_lib.ColorRgb8(0, 0, 255),
    );
    image_lib.fillRect(
      spriteSheet,
      x1: 2,
      y1: 2,
      x2: 3,
      y2: 3,
      color: image_lib.ColorRgb8(255, 255, 0),
    );

    final editedBytes = SpriteSheetEditorComposer.replaceFrame(
      sheetBytes: Uint8List.fromList(image_lib.encodePng(spriteSheet)),
      patchBytes: _pngOfColor(128, 64, 32),
      rows: 2,
      columns: 2,
      frameIndex: 2,
      fit: SpriteSheetFrameFit.stretch,
    );

    final edited = image_lib.decodeImage(editedBytes)!;

    expect(edited.width, 4);
    expect(edited.height, 4);
    expect(edited.getPixel(0, 0).r.toInt(), 255);
    expect(edited.getPixel(2, 0).g.toInt(), 255);
    expect(edited.getPixel(0, 2).r.toInt(), 128);
    expect(edited.getPixel(0, 2).g.toInt(), 64);
    expect(edited.getPixel(0, 2).b.toInt(), 32);
    expect(edited.getPixel(2, 2).r.toInt(), 255);
    expect(edited.getPixel(2, 2).g.toInt(), 255);
  });

  test('supports contain and cover replacement sizing', () {
    final sheetBytes = _pngOfColorWithSize(0, 0, 0, width: 6, height: 6);
    final widePatchBytes = _pngOfColorWithSize(
      200,
      100,
      50,
      width: 4,
      height: 2,
    );

    final contained = image_lib.decodeImage(
      SpriteSheetEditorComposer.replaceFrame(
        sheetBytes: sheetBytes,
        patchBytes: widePatchBytes,
        rows: 1,
        columns: 1,
        frameIndex: 0,
        fit: SpriteSheetFrameFit.contain,
      ),
    )!;
    final covered = image_lib.decodeImage(
      SpriteSheetEditorComposer.replaceFrame(
        sheetBytes: sheetBytes,
        patchBytes: widePatchBytes,
        rows: 1,
        columns: 1,
        frameIndex: 0,
        fit: SpriteSheetFrameFit.cover,
      ),
    )!;

    expect(contained.width, 6);
    expect(contained.height, 6);
    expect(covered.width, 6);
    expect(covered.height, 6);
    expect(contained.getPixel(3, 3).r.toInt(), 200);
    expect(covered.getPixel(0, 0).r.toInt(), 200);
  });
}

Uint8List _pngOfColor(int red, int green, int blue) {
  return _pngOfColorWithSize(red, green, blue, width: 2, height: 2);
}

Uint8List _pngOfColorWithSize(
  int red,
  int green,
  int blue, {
  required int width,
  required int height,
}) {
  final image = image_lib.Image(width: width, height: height)
    ..clear(image_lib.ColorRgb8(red, green, blue));
  return Uint8List.fromList(image_lib.encodePng(image));
}
