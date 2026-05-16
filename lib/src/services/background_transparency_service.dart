import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;

import '../models/exceptions.dart';

class BackgroundTransparencyResult {
  const BackgroundTransparencyResult({
    required this.pngBytes,
    required this.transparentPixelCount,
    required this.width,
    required this.height,
    required this.sampledRed,
    required this.sampledGreen,
    required this.sampledBlue,
  });

  final Uint8List pngBytes;
  final int transparentPixelCount;
  final int width;
  final int height;
  final int sampledRed;
  final int sampledGreen;
  final int sampledBlue;
}

class BackgroundTransparencyService {
  const BackgroundTransparencyService._();

  static BackgroundTransparencyResult makeBackgroundTransparent(
    Uint8List imageBytes, {
    int tolerance = 28,
  }) {
    final decoded = image_lib.decodeImage(imageBytes);
    if (decoded == null) {
      throw const ImageGenerationException('图片无法解码，不能转换透明背景。');
    }
    if (decoded.width <= 0 || decoded.height <= 0) {
      throw const ImageGenerationException('图片尺寸无效，不能转换透明背景。');
    }

    final image = decoded.convert(numChannels: 4);
    final sample = _sampleBackgroundColor(image);
    final visited = Uint8List(image.width * image.height);
    final queue = Queue<_Point>();
    var transparentPixelCount = 0;

    void addCandidate(int x, int y) {
      if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
        return;
      }
      final offset = y * image.width + x;
      if (visited[offset] == 1) {
        return;
      }
      visited[offset] = 1;
      final pixel = image.getPixel(x, y);
      if (!_isBackgroundPixel(pixel, sample, tolerance)) {
        return;
      }
      queue.add(_Point(x, y));
    }

    for (var x = 0; x < image.width; x++) {
      addCandidate(x, 0);
      addCandidate(x, image.height - 1);
    }
    for (var y = 1; y < image.height - 1; y++) {
      addCandidate(0, y);
      addCandidate(image.width - 1, y);
    }

    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      final pixel = image.getPixel(point.x, point.y);
      if (pixel.a > 0) {
        image.setPixelRgba(point.x, point.y, pixel.r, pixel.g, pixel.b, 0);
        transparentPixelCount += 1;
      }

      addCandidate(point.x + 1, point.y);
      addCandidate(point.x - 1, point.y);
      addCandidate(point.x, point.y + 1);
      addCandidate(point.x, point.y - 1);
    }

    return BackgroundTransparencyResult(
      pngBytes: Uint8List.fromList(image_lib.encodePng(image)),
      transparentPixelCount: transparentPixelCount,
      width: image.width,
      height: image.height,
      sampledRed: sample.red,
      sampledGreen: sample.green,
      sampledBlue: sample.blue,
    );
  }

  static _SampledColor _sampleBackgroundColor(image_lib.Image image) {
    final corners = [
      image.getPixel(0, 0),
      image.getPixel(image.width - 1, 0),
      image.getPixel(0, image.height - 1),
      image.getPixel(image.width - 1, image.height - 1),
    ];
    final opaqueCorners = corners.where((pixel) => pixel.a > 0).toList();
    final samples = opaqueCorners.isEmpty ? corners : opaqueCorners;
    final red = _averageChannel(samples.map((pixel) => pixel.r.toInt()));
    final green = _averageChannel(samples.map((pixel) => pixel.g.toInt()));
    final blue = _averageChannel(samples.map((pixel) => pixel.b.toInt()));
    return _SampledColor(red, green, blue);
  }

  static int _averageChannel(Iterable<int> values) {
    var count = 0;
    var total = 0;
    for (final value in values) {
      count += 1;
      total += value;
    }
    return count == 0 ? 0 : (total / count).round();
  }

  static bool _isBackgroundPixel(
    image_lib.Pixel pixel,
    _SampledColor sample,
    int tolerance,
  ) {
    if (pixel.a <= 0) {
      return true;
    }
    final safeTolerance = tolerance.clamp(0, 255);
    final redDelta = (pixel.r.toInt() - sample.red).abs();
    final greenDelta = (pixel.g.toInt() - sample.green).abs();
    final blueDelta = (pixel.b.toInt() - sample.blue).abs();
    return math.max(redDelta, math.max(greenDelta, blueDelta)) <= safeTolerance;
  }
}

class _SampledColor {
  const _SampledColor(this.red, this.green, this.blue);

  final int red;
  final int green;
  final int blue;
}

class _Point {
  const _Point(this.x, this.y);

  final int x;
  final int y;
}
