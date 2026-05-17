import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

void main() {
  test('removes only edge-connected matching background', () {
    final image = image_lib.Image(width: 5, height: 5, numChannels: 4)
      ..clear(image_lib.ColorRgba8(255, 255, 255, 255));

    image_lib.fillRect(
      image,
      x1: 1,
      y1: 1,
      x2: 3,
      y2: 3,
      color: image_lib.ColorRgba8(220, 40, 40, 255),
    );
    image.setPixelRgba(2, 2, 255, 255, 255, 255);

    final result = BackgroundTransparencyService.makeBackgroundTransparent(
      Uint8List.fromList(image_lib.encodePng(image)),
      tolerance: 4,
    );
    final output = image_lib.decodeImage(result.pngBytes)!;

    expect(result.transparentPixelCount, 16);
    expect(output.getPixel(0, 0).a.toInt(), 0);
    expect(output.getPixel(4, 4).a.toInt(), 0);
    expect(output.getPixel(1, 1).a.toInt(), 255);
    expect(output.getPixel(2, 2).a.toInt(), 255);
  });

  test('uses tolerance for slightly uneven background colors', () {
    final image = image_lib.Image(width: 3, height: 3, numChannels: 4)
      ..clear(image_lib.ColorRgba8(250, 250, 250, 255));
    image.setPixelRgba(1, 0, 244, 244, 244, 255);
    image.setPixelRgba(1, 1, 40, 80, 160, 255);

    final result = BackgroundTransparencyService.makeBackgroundTransparent(
      Uint8List.fromList(image_lib.encodePng(image)),
      tolerance: 8,
    );
    final output = image_lib.decodeImage(result.pngBytes)!;

    expect(output.getPixel(1, 0).a.toInt(), 0);
    expect(output.getPixel(1, 1).a.toInt(), 255);
  });

  test('runs transparent background conversion in background isolate', () async {
    final image = image_lib.Image(width: 3, height: 3, numChannels: 4)
      ..clear(image_lib.ColorRgba8(255, 255, 255, 255));
    image.setPixelRgba(1, 1, 10, 20, 30, 255);

    final result =
        await BackgroundTransparencyService.makeBackgroundTransparentInBackground(
          Uint8List.fromList(image_lib.encodePng(image)),
          tolerance: 4,
        );
    final output = image_lib.decodeImage(result.pngBytes)!;

    expect(result.transparentPixelCount, 8);
    expect(output.getPixel(0, 0).a.toInt(), 0);
    expect(output.getPixel(1, 1).a.toInt(), 255);
  });
}
