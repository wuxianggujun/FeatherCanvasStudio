import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image_lib;

import '../models/exceptions.dart';

class PixelationResult {
  const PixelationResult({
    required this.pngBytes,
    required this.width,
    required this.height,
    required this.blockSize,
  });

  final Uint8List pngBytes;
  final int width;
  final int height;
  final int blockSize;
}

class PixelationService {
  const PixelationService._();

  static const int minBlockSize = 2;
  static const int maxBlockSize = 128;

  static int normalizeBlockSize(int blockSize) {
    return blockSize.clamp(minBlockSize, maxBlockSize).toInt();
  }

  static PixelationResult pixelate(
    Uint8List imageBytes, {
    required int blockSize,
  }) {
    final decoded = image_lib.decodeImage(imageBytes);
    if (decoded == null) {
      throw const ImageGenerationException('图片无法解码，不能进行像素化处理。');
    }
    if (decoded.width <= 0 || decoded.height <= 0) {
      throw const ImageGenerationException('图片尺寸无效，不能进行像素化处理。');
    }

    final safeBlockSize = normalizeBlockSize(blockSize);
    final output = pixelateDecodedImage(decoded, blockSize: safeBlockSize);
    return PixelationResult(
      pngBytes: Uint8List.fromList(image_lib.encodePng(output)),
      width: output.width,
      height: output.height,
      blockSize: safeBlockSize,
    );
  }

  static Future<PixelationResult> pixelateInBackground(
    Uint8List imageBytes, {
    required int blockSize,
  }) {
    return compute(
      _pixelateInIsolate,
      _PixelationTask(imageBytes, blockSize),
      debugLabel: 'pixelation',
    );
  }

  static image_lib.Image pixelateDecodedImage(
    image_lib.Image source, {
    required int blockSize,
  }) {
    if (source.width <= 0 || source.height <= 0) {
      throw const ImageGenerationException('图片尺寸无效，不能进行像素化处理。');
    }

    final safeBlockSize = normalizeBlockSize(blockSize);
    final image = source.convert(numChannels: 4);
    for (var top = 0; top < image.height; top += safeBlockSize) {
      final bottom = math.min(top + safeBlockSize, image.height);
      for (var left = 0; left < image.width; left += safeBlockSize) {
        final right = math.min(left + safeBlockSize, image.width);
        final color = _averageBlockColor(
          image,
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        );
        _fillBlock(
          image,
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          color: color,
        );
      }
    }
    return image;
  }

  static _PixelColor _averageBlockColor(
    image_lib.Image image, {
    required int left,
    required int top,
    required int right,
    required int bottom,
  }) {
    var pixelCount = 0;
    var alphaTotal = 0;
    var redWeightedTotal = 0;
    var greenWeightedTotal = 0;
    var blueWeightedTotal = 0;

    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final pixel = image.getPixel(x, y);
        final alpha = pixel.a.toInt().clamp(0, 255);
        pixelCount += 1;
        alphaTotal += alpha;
        redWeightedTotal += pixel.r.toInt().clamp(0, 255) * alpha;
        greenWeightedTotal += pixel.g.toInt().clamp(0, 255) * alpha;
        blueWeightedTotal += pixel.b.toInt().clamp(0, 255) * alpha;
      }
    }

    if (pixelCount == 0 || alphaTotal == 0) {
      return const _PixelColor(0, 0, 0, 0);
    }

    return _PixelColor(
      (redWeightedTotal / alphaTotal).round().clamp(0, 255).toInt(),
      (greenWeightedTotal / alphaTotal).round().clamp(0, 255).toInt(),
      (blueWeightedTotal / alphaTotal).round().clamp(0, 255).toInt(),
      (alphaTotal / pixelCount).round().clamp(0, 255).toInt(),
    );
  }

  static void _fillBlock(
    image_lib.Image image, {
    required int left,
    required int top,
    required int right,
    required int bottom,
    required _PixelColor color,
  }) {
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        image.setPixelRgba(
          x,
          y,
          color.red,
          color.green,
          color.blue,
          color.alpha,
        );
      }
    }
  }
}

PixelationResult _pixelateInIsolate(_PixelationTask task) {
  return PixelationService.pixelate(task.imageBytes, blockSize: task.blockSize);
}

class _PixelationTask {
  const _PixelationTask(this.imageBytes, this.blockSize);

  final Uint8List imageBytes;
  final int blockSize;
}

class _PixelColor {
  const _PixelColor(this.red, this.green, this.blue, this.alpha);

  final int red;
  final int green;
  final int blue;
  final int alpha;
}
