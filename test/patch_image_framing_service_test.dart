import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

void main() {
  test('renders source image centered on a transparent target frame', () {
    final patch = image_lib.Image(width: 4, height: 2, numChannels: 4)
      ..clear(image_lib.ColorRgba8(220, 40, 40, 255));

    final outputBytes = PatchImageFramingService.render(
      imageBytes: Uint8List.fromList(image_lib.encodePng(patch)),
      targetWidth: 4,
      targetHeight: 4,
      framing: const PatchImageFraming(scale: 1),
    );
    final output = image_lib.decodeImage(outputBytes)!;

    expect(output.width, 4);
    expect(output.height, 4);
    expect(output.getPixel(0, 0).a.toInt(), 0);
    expect(output.getPixel(1, 1).r.toInt(), 220);
    expect(output.getPixel(1, 2).r.toInt(), 220);
    expect(output.getPixel(0, 3).a.toInt(), 0);
  });

  test('supports offset cropping for oversized images', () {
    final patch = image_lib.Image(width: 4, height: 2, numChannels: 4);
    image_lib.fillRect(
      patch,
      x1: 0,
      y1: 0,
      x2: 1,
      y2: 1,
      color: image_lib.ColorRgba8(240, 0, 0, 255),
    );
    image_lib.fillRect(
      patch,
      x1: 2,
      y1: 0,
      x2: 3,
      y2: 1,
      color: image_lib.ColorRgba8(0, 0, 240, 255),
    );

    final outputBytes = PatchImageFramingService.render(
      imageBytes: Uint8List.fromList(image_lib.encodePng(patch)),
      targetWidth: 2,
      targetHeight: 2,
      framing: const PatchImageFraming(scale: 1, offsetX: -1),
    );
    final output = image_lib.decodeImage(outputBytes)!;

    expect(output.getPixel(0, 0).b.toInt(), 240);
    expect(output.getPixel(1, 1).b.toInt(), 240);
  });

  test(
    'replace frame clears old pixels before compositing transparent patch',
    () {
      final sheet = image_lib.Image(width: 2, height: 2, numChannels: 4)
        ..clear(image_lib.ColorRgba8(40, 180, 40, 255));
      final patch = image_lib.Image(width: 2, height: 2, numChannels: 4)
        ..clear(image_lib.ColorRgba8(0, 0, 0, 0));
      patch.setPixelRgba(1, 1, 200, 20, 20, 255);

      final outputBytes = SpriteSheetEditorComposer.replaceFrame(
        sheetBytes: Uint8List.fromList(image_lib.encodePng(sheet)),
        patchBytes: Uint8List.fromList(image_lib.encodePng(patch)),
        rows: 1,
        columns: 1,
        frameIndex: 0,
        fit: SpriteSheetFrameFit.stretch,
      );
      final output = image_lib.decodeImage(outputBytes)!;

      expect(output.getPixel(0, 0).a.toInt(), 0);
      expect(output.getPixel(1, 1).r.toInt(), 200);
    },
  );
}
