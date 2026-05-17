import 'dart:typed_data';

import 'package:feather_canvas_studio/src/services/general_image_editing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

void main() {
  test('crops, rotates and flips an image', () {
    final source = image_lib.Image(width: 3, height: 2, numChannels: 4);
    _setPixel(source, 0, 0, 255, 0, 0);
    _setPixel(source, 1, 0, 0, 255, 0);
    _setPixel(source, 2, 0, 0, 0, 255);
    _setPixel(source, 0, 1, 255, 255, 0);
    _setPixel(source, 1, 1, 0, 255, 255);
    _setPixel(source, 2, 1, 255, 0, 255);

    final result = GeneralImageEditingService.edit(
      Uint8List.fromList(image_lib.encodePng(source)),
      options: const GeneralImageEditOptions(
        crop: ImageCropMargins(left: 1),
        quarterTurns: 1,
        flipHorizontal: true,
      ),
    );
    final output = image_lib.decodeImage(result.bytes)!;

    expect(output.width, 2);
    expect(output.height, 2);
    expect(output.getPixel(0, 0).g.toInt(), 255);
    expect(output.getPixel(0, 1).b.toInt(), 255);
    expect(result.summary, contains('裁剪'));
    expect(result.summary, contains('旋转 90°'));
    expect(result.summary, contains('水平翻转'));
  });

  test('resizes and applies grayscale effect', () {
    final source = image_lib.Image(width: 2, height: 2, numChannels: 4)
      ..clear(image_lib.ColorRgba8(120, 40, 200, 255));

    final result = GeneralImageEditingService.edit(
      Uint8List.fromList(image_lib.encodePng(source)),
      options: const GeneralImageEditOptions(
        resize: ImageResizeOptions(width: 4, height: 4),
        effect: ImageEditColorEffect.grayscale,
      ),
    );
    final output = image_lib.decodeImage(result.bytes)!;
    final pixel = output.getPixel(0, 0);

    expect(output.width, 4);
    expect(output.height, 4);
    expect(pixel.r.toInt(), pixel.g.toInt());
    expect(pixel.g.toInt(), pixel.b.toInt());
  });

  test('can limit effects to a selected region', () {
    final source = image_lib.Image(width: 4, height: 2, numChannels: 4)
      ..clear(image_lib.ColorRgba8(10, 20, 30, 255));
    image_lib.fillRect(
      source,
      x1: 2,
      y1: 0,
      x2: 3,
      y2: 1,
      color: image_lib.ColorRgba8(80, 90, 100, 255),
    );

    final result = GeneralImageEditingService.edit(
      Uint8List.fromList(image_lib.encodePng(source)),
      options: const GeneralImageEditOptions(
        effect: ImageEditColorEffect.invert,
        effectRegion: ImageEffectRegion(
          enabled: true,
          leftRatio: 0,
          topRatio: 0,
          rightRatio: 0.5,
          bottomRatio: 1,
        ),
      ),
    );
    final output = image_lib.decodeImage(result.bytes)!;

    expect(output.getPixel(0, 0).r.toInt(), 245);
    expect(output.getPixel(0, 0).g.toInt(), 235);
    expect(output.getPixel(2, 0).r.toInt(), 80);
    expect(output.getPixel(2, 0).g.toInt(), 90);
    expect(result.summary, contains('局部选区'));
  });

  test('can blur and sharpen image details', () {
    final source = image_lib.Image(width: 5, height: 5, numChannels: 4)
      ..clear(image_lib.ColorRgba8(120, 120, 120, 255));
    source.setPixelRgba(2, 2, 180, 180, 180, 255);

    final blurResult = GeneralImageEditingService.edit(
      Uint8List.fromList(image_lib.encodePng(source)),
      options: const GeneralImageEditOptions(blurRadius: 1),
    );
    final blurred = image_lib.decodeImage(blurResult.bytes)!;

    expect(blurred.getPixel(2, 2).r.toInt(), lessThan(180));
    expect(blurred.getPixel(2, 1).r.toInt(), greaterThan(120));
    expect(blurResult.summary, contains('模糊 1px'));

    final sharpenResult = GeneralImageEditingService.edit(
      Uint8List.fromList(image_lib.encodePng(source)),
      options: const GeneralImageEditOptions(sharpenAmount: 100),
    );
    final sharpened = image_lib.decodeImage(sharpenResult.bytes)!;

    expect(sharpened.getPixel(2, 2).r.toInt(), greaterThan(180));
    expect(sharpenResult.summary, contains('锐化 100%'));
  });

  test('can remove edge background and pixelate result', () {
    final source = image_lib.Image(width: 4, height: 4, numChannels: 4)
      ..clear(image_lib.ColorRgba8(255, 255, 255, 255));
    image_lib.fillRect(
      source,
      x1: 1,
      y1: 1,
      x2: 2,
      y2: 2,
      color: image_lib.ColorRgba8(20, 40, 80, 255),
    );

    final result = GeneralImageEditingService.edit(
      Uint8List.fromList(image_lib.encodePng(source)),
      options: const GeneralImageEditOptions(
        backgroundTransparencyTolerance: 4,
        pixelationBlockSize: 2,
      ),
    );
    final output = image_lib.decodeImage(result.bytes)!;

    expect(output.getPixel(0, 0).a.toInt(), lessThan(255));
    expect(output.getPixel(1, 1).a.toInt(), greaterThan(0));
    expect(result.summary, contains('边缘背景转透明'));
    expect(result.summary, contains('像素化'));
  });

  test('renders annotations as the final edit layer', () {
    final source = image_lib.Image(width: 20, height: 20, numChannels: 4)
      ..clear(image_lib.ColorRgba8(255, 255, 255, 255));

    final result = GeneralImageEditingService.edit(
      Uint8List.fromList(image_lib.encodePng(source)),
      options: const GeneralImageEditOptions(
        pixelationBlockSize: 2,
        annotations: [
          ImageAnnotation(
            kind: ImageAnnotationKind.rectangle,
            startXRatio: 0.2,
            startYRatio: 0.2,
            endXRatio: 0.4,
            endYRatio: 0.4,
            colorArgb: 0xFFFF0000,
            filled: true,
          ),
          ImageAnnotation(
            kind: ImageAnnotationKind.arrow,
            startXRatio: 0.7,
            startYRatio: 0,
            endXRatio: 1,
            endYRatio: 0,
            colorArgb: 0xFF0000FF,
            strokeWidth: 2,
          ),
        ],
      ),
    );
    final output = image_lib.decodeImage(result.bytes)!;
    final annotatedPixel = output.getPixel(6, 6);

    expect(annotatedPixel.r.toInt(), 255);
    expect(annotatedPixel.g.toInt(), 0);
    expect(annotatedPixel.b.toInt(), 0);
    expect(result.summary, contains('标注 2 个'));
  });

  test('can export jpeg with a flattened background', () {
    final source = image_lib.Image(width: 2, height: 2, numChannels: 4)
      ..clear(image_lib.ColorRgba8(255, 0, 0, 128));

    final result = GeneralImageEditingService.edit(
      Uint8List.fromList(image_lib.encodePng(source)),
      options: const GeneralImageEditOptions(
        outputFormat: GeneralImageOutputFormat.jpeg,
        jpegQuality: 80,
      ),
    );
    final output = image_lib.decodeImage(result.bytes)!;

    expect(result.fileExtension, 'jpg');
    expect(result.mimeType, 'image/jpeg');
    expect(result.bytes.take(2), [0xFF, 0xD8]);
    expect(output.width, 2);
    expect(output.height, 2);
    expect(output.getPixel(0, 0).a.toInt(), 255);
    expect(result.summary, contains('JPEG 80质量'));
  });
}

void _setPixel(
  image_lib.Image image,
  int x,
  int y,
  int red,
  int green,
  int blue,
) {
  image.setPixelRgba(x, y, red, green, blue, 255);
}
