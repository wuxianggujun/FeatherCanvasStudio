import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;

import '../models/exceptions.dart';

class PatchImageDimensions {
  const PatchImageDimensions({required this.width, required this.height});

  final int width;
  final int height;
}

class PatchImageFraming {
  const PatchImageFraming({
    required this.scale,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  final double scale;
  final double offsetX;
  final double offsetY;

  PatchImageFraming copyWith({
    double? scale,
    double? offsetX,
    double? offsetY,
  }) {
    return PatchImageFraming(
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }
}

class PatchImageFramingService {
  const PatchImageFramingService._();

  static PatchImageDimensions readDimensions(Uint8List imageBytes) {
    final image = image_lib.decodeImage(imageBytes);
    if (image == null) {
      throw const ImageGenerationException('单帧图片无法解码。');
    }
    return PatchImageDimensions(width: image.width, height: image.height);
  }

  static PatchImageFraming containFraming({
    required PatchImageDimensions source,
    required int targetWidth,
    required int targetHeight,
  }) {
    return PatchImageFraming(
      scale: _minDouble(
        targetWidth / source.width,
        targetHeight / source.height,
      ),
    );
  }

  static PatchImageFraming coverFraming({
    required PatchImageDimensions source,
    required int targetWidth,
    required int targetHeight,
  }) {
    return PatchImageFraming(
      scale: _maxDouble(
        targetWidth / source.width,
        targetHeight / source.height,
      ),
    );
  }

  static Uint8List render({
    required Uint8List imageBytes,
    required int targetWidth,
    required int targetHeight,
    required PatchImageFraming framing,
  }) {
    if (targetWidth <= 0 || targetHeight <= 0) {
      throw const ImageGenerationException('目标帧尺寸无效。');
    }

    final source = image_lib.decodeImage(imageBytes);
    if (source == null) {
      throw const ImageGenerationException('单帧图片无法解码。');
    }

    final resizedWidth = (source.width * framing.scale)
        .round()
        .clamp(1, 1 << 30)
        .toInt();
    final resizedHeight = (source.height * framing.scale)
        .round()
        .clamp(1, 1 << 30)
        .toInt();
    final resized = image_lib.copyResize(
      source.convert(numChannels: 4),
      width: resizedWidth,
      height: resizedHeight,
    );
    final canvas = image_lib.Image(
      width: targetWidth,
      height: targetHeight,
      numChannels: 4,
    )..clear(image_lib.ColorRgba8(0, 0, 0, 0));

    final dstX = ((targetWidth - resizedWidth) / 2 + framing.offsetX).round();
    final dstY = ((targetHeight - resizedHeight) / 2 + framing.offsetY).round();
    final visibleLeft = _maxInt(0, dstX);
    final visibleTop = _maxInt(0, dstY);
    final visibleRight = _minInt(targetWidth, dstX + resizedWidth);
    final visibleBottom = _minInt(targetHeight, dstY + resizedHeight);
    final visibleWidth = visibleRight - visibleLeft;
    final visibleHeight = visibleBottom - visibleTop;

    if (visibleWidth <= 0 || visibleHeight <= 0) {
      return Uint8List.fromList(image_lib.encodePng(canvas));
    }

    final crop = image_lib.copyCrop(
      resized,
      x: visibleLeft - dstX,
      y: visibleTop - dstY,
      width: visibleWidth,
      height: visibleHeight,
    );
    image_lib.compositeImage(canvas, crop, dstX: visibleLeft, dstY: visibleTop);

    return Uint8List.fromList(image_lib.encodePng(canvas));
  }
}

double _minDouble(double a, double b) => a < b ? a : b;

double _maxDouble(double a, double b) => a > b ? a : b;

int _minInt(int a, int b) => a < b ? a : b;

int _maxInt(int a, int b) => a > b ? a : b;
