import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

void main() {
  test('pixelates each block to a shared average color', () {
    final image = image_lib.Image(width: 4, height: 4, numChannels: 4)
      ..clear(image_lib.ColorRgba8(0, 0, 0, 255));
    image.setPixelRgba(0, 0, 255, 0, 0, 255);
    image.setPixelRgba(1, 0, 0, 255, 0, 255);
    image.setPixelRgba(0, 1, 0, 0, 255, 255);
    image.setPixelRgba(1, 1, 255, 255, 255, 255);

    final result = PixelationService.pixelate(
      Uint8List.fromList(image_lib.encodePng(image)),
      blockSize: 2,
    );
    final output = image_lib.decodeImage(result.pngBytes)!;

    expect(result.width, 4);
    expect(result.height, 4);
    expect(result.blockSize, 2);
    for (var y = 0; y < 2; y++) {
      for (var x = 0; x < 2; x++) {
        final pixel = output.getPixel(x, y);
        expect(pixel.r.toInt(), 128);
        expect(pixel.g.toInt(), 128);
        expect(pixel.b.toInt(), 128);
        expect(pixel.a.toInt(), 255);
      }
    }
    expect(output.getPixel(2, 2).r.toInt(), 0);
    expect(output.getPixel(2, 2).a.toInt(), 255);
  });

  test('preserves fully transparent blocks', () {
    final image = image_lib.Image(width: 4, height: 2, numChannels: 4)
      ..clear(image_lib.ColorRgba8(80, 120, 160, 255));
    for (var y = 0; y < 2; y++) {
      for (var x = 0; x < 2; x++) {
        image.setPixelRgba(x, y, 255, 255, 255, 0);
      }
    }

    final result = PixelationService.pixelate(
      Uint8List.fromList(image_lib.encodePng(image)),
      blockSize: 2,
    );
    final output = image_lib.decodeImage(result.pngBytes)!;

    expect(output.getPixel(0, 0).a.toInt(), 0);
    expect(output.getPixel(1, 1).a.toInt(), 0);
    expect(output.getPixel(2, 0).r.toInt(), 80);
    expect(output.getPixel(2, 0).g.toInt(), 120);
    expect(output.getPixel(2, 0).b.toInt(), 160);
    expect(output.getPixel(2, 0).a.toInt(), 255);
  });

  test('runs pixelation in background isolate', () async {
    final image = image_lib.Image(width: 2, height: 2, numChannels: 4)
      ..clear(image_lib.ColorRgba8(0, 0, 0, 255));
    image.setPixelRgba(0, 0, 200, 0, 0, 255);
    image.setPixelRgba(1, 0, 0, 200, 0, 255);
    image.setPixelRgba(0, 1, 0, 0, 200, 255);
    image.setPixelRgba(1, 1, 200, 200, 200, 255);

    final result = await PixelationService.pixelateInBackground(
      Uint8List.fromList(image_lib.encodePng(image)),
      blockSize: 2,
    );
    final output = image_lib.decodeImage(result.pngBytes)!;

    expect(result.blockSize, 2);
    expect(output.getPixel(0, 0).r.toInt(), 100);
    expect(output.getPixel(0, 0).g.toInt(), 100);
    expect(output.getPixel(0, 0).b.toInt(), 100);
  });

  test('pixelates only the selected sprite sheet frame', () {
    final sheet = image_lib.Image(width: 4, height: 2, numChannels: 4)
      ..clear(image_lib.ColorRgba8(0, 0, 0, 255));
    sheet.setPixelRgba(0, 0, 255, 0, 0, 255);
    sheet.setPixelRgba(1, 0, 0, 255, 0, 255);
    sheet.setPixelRgba(0, 1, 0, 0, 255, 255);
    sheet.setPixelRgba(1, 1, 255, 255, 255, 255);
    image_lib.fillRect(
      sheet,
      x1: 2,
      y1: 0,
      x2: 3,
      y2: 1,
      color: image_lib.ColorRgba8(24, 48, 96, 255),
    );

    final editedBytes = SpriteSheetEditorComposer.pixelateFrame(
      sheetBytes: Uint8List.fromList(image_lib.encodePng(sheet)),
      rows: 1,
      columns: 2,
      frameIndex: 0,
      blockSize: 2,
    );
    final output = image_lib.decodeImage(editedBytes)!;

    expect(output.getPixel(0, 0).r.toInt(), 128);
    expect(output.getPixel(1, 1).g.toInt(), 128);
    expect(output.getPixel(2, 0).r.toInt(), 24);
    expect(output.getPixel(2, 0).g.toInt(), 48);
    expect(output.getPixel(3, 1).b.toInt(), 96);
  });
}
