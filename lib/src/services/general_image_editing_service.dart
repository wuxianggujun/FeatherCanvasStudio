import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image_lib;

import '../models/exceptions.dart';
import 'background_transparency_service.dart';
import 'pixelation_service.dart';

enum ImageEditColorEffect { none, grayscale, sepia, invert }

enum ImageAnnotationKind { text, rectangle, ellipse, line, arrow }

enum GeneralImageOutputFormat { png, jpeg }

class ImageCropMargins {
  const ImageCropMargins({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;

  bool get isEmpty => left <= 0 && top <= 0 && right <= 0 && bottom <= 0;
}

class ImageResizeOptions {
  const ImageResizeOptions({this.width, this.height});

  final int? width;
  final int? height;

  bool get isEmpty => width == null && height == null;
}

class ImageColorAdjustments {
  const ImageColorAdjustments({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.warmth = 0,
  });

  final int brightness;
  final int contrast;
  final int saturation;
  final int warmth;

  bool get isEmpty =>
      brightness == 0 && contrast == 0 && saturation == 0 && warmth == 0;
}

class ImageEffectRegion {
  const ImageEffectRegion({
    this.enabled = false,
    this.leftRatio = 0.15,
    this.topRatio = 0.15,
    this.rightRatio = 0.85,
    this.bottomRatio = 0.85,
  });

  final bool enabled;
  final double leftRatio;
  final double topRatio;
  final double rightRatio;
  final double bottomRatio;
}

class ImageAnnotation {
  const ImageAnnotation({
    required this.kind,
    this.text = '',
    this.startXRatio = 0.12,
    this.startYRatio = 0.12,
    this.endXRatio = 0.88,
    this.endYRatio = 0.88,
    this.colorArgb = 0xFFFFD400,
    this.strokeWidth = 4,
    this.filled = false,
    this.fontSize = 24,
  });

  final ImageAnnotationKind kind;
  final String text;
  final double startXRatio;
  final double startYRatio;
  final double endXRatio;
  final double endYRatio;
  final int colorArgb;
  final int strokeWidth;
  final bool filled;
  final int fontSize;

  bool get hasVisibleContent =>
      kind != ImageAnnotationKind.text || text.trim().isNotEmpty;
}

class GeneralImageEditOptions {
  const GeneralImageEditOptions({
    this.crop = const ImageCropMargins(),
    this.quarterTurns = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.resize = const ImageResizeOptions(),
    this.adjustments = const ImageColorAdjustments(),
    this.effect = ImageEditColorEffect.none,
    this.effectRegion = const ImageEffectRegion(),
    this.blurRadius = 0,
    this.sharpenAmount = 0,
    this.pixelationBlockSize = 0,
    this.backgroundTransparencyTolerance,
    this.annotations = const [],
    this.outputFormat = GeneralImageOutputFormat.png,
    this.jpegQuality = 92,
  });

  final ImageCropMargins crop;
  final int quarterTurns;
  final bool flipHorizontal;
  final bool flipVertical;
  final ImageResizeOptions resize;
  final ImageColorAdjustments adjustments;
  final ImageEditColorEffect effect;
  final ImageEffectRegion effectRegion;
  final int blurRadius;
  final int sharpenAmount;
  final int pixelationBlockSize;
  final int? backgroundTransparencyTolerance;
  final List<ImageAnnotation> annotations;
  final GeneralImageOutputFormat outputFormat;
  final int jpegQuality;

  bool get isIdentity =>
      crop.isEmpty &&
      quarterTurns % 4 == 0 &&
      !flipHorizontal &&
      !flipVertical &&
      resize.isEmpty &&
      adjustments.isEmpty &&
      effect == ImageEditColorEffect.none &&
      blurRadius <= 0 &&
      sharpenAmount <= 0 &&
      pixelationBlockSize <= 0 &&
      backgroundTransparencyTolerance == null &&
      annotations.isEmpty &&
      outputFormat == GeneralImageOutputFormat.png;
}

class ImageInspectionResult {
  const ImageInspectionResult({
    required this.width,
    required this.height,
    required this.hasAlpha,
  });

  final int width;
  final int height;
  final bool hasAlpha;
}

class GeneralImageEditResult {
  const GeneralImageEditResult({
    required this.bytes,
    required this.width,
    required this.height,
    required this.summary,
    required this.outputFormat,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final String summary;
  final GeneralImageOutputFormat outputFormat;

  String get fileExtension {
    return switch (outputFormat) {
      GeneralImageOutputFormat.png => 'png',
      GeneralImageOutputFormat.jpeg => 'jpg',
    };
  }

  String get mimeType {
    return switch (outputFormat) {
      GeneralImageOutputFormat.png => 'image/png',
      GeneralImageOutputFormat.jpeg => 'image/jpeg',
    };
  }
}

class GeneralImageEditingService {
  const GeneralImageEditingService._();

  static ImageInspectionResult inspect(Uint8List imageBytes) {
    final decoded = image_lib.decodeImage(imageBytes);
    if (decoded == null) {
      throw const ImageGenerationException('图片无法解码，不能读取尺寸。');
    }
    if (decoded.width <= 0 || decoded.height <= 0) {
      throw const ImageGenerationException('图片尺寸无效。');
    }

    var hasAlpha = false;
    final image = decoded.convert(numChannels: 4);
    for (var y = 0; y < image.height && !hasAlpha; y++) {
      for (var x = 0; x < image.width; x++) {
        if (image.getPixel(x, y).a.toInt() < 255) {
          hasAlpha = true;
          break;
        }
      }
    }

    return ImageInspectionResult(
      width: decoded.width,
      height: decoded.height,
      hasAlpha: hasAlpha,
    );
  }

  static GeneralImageEditResult edit(
    Uint8List imageBytes, {
    required GeneralImageEditOptions options,
  }) {
    final decoded = image_lib.decodeImage(imageBytes);
    if (decoded == null) {
      throw const ImageGenerationException('图片无法解码，不能编辑。');
    }
    if (decoded.width <= 0 || decoded.height <= 0) {
      throw const ImageGenerationException('图片尺寸无效，不能编辑。');
    }

    var image = decoded.convert(numChannels: 4);
    final summary = <String>[];

    if (!options.crop.isEmpty) {
      image = _cropByMargins(image, options.crop);
      summary.add('裁剪');
    }

    final quarterTurns = _normalizeQuarterTurns(options.quarterTurns);
    if (quarterTurns != 0) {
      image = _rotateQuarterTurns(image, quarterTurns);
      summary.add('旋转 ${quarterTurns * 90}°');
    }

    if (options.flipHorizontal) {
      image = _flipHorizontal(image);
      summary.add('水平翻转');
    }
    if (options.flipVertical) {
      image = _flipVertical(image);
      summary.add('垂直翻转');
    }

    final resize = _resolveResize(image, options.resize);
    if (resize != null) {
      image = image_lib.copyResize(
        image,
        width: resize.width,
        height: resize.height,
        interpolation: image_lib.Interpolation.average,
      );
      summary.add('缩放 ${image.width} x ${image.height}');
    }

    image = _applyEffects(image, options, summary);

    final annotationCount = options.annotations
        .where((annotation) => annotation.hasVisibleContent)
        .length;
    if (annotationCount > 0) {
      _applyAnnotations(image, options.annotations);
      summary.add('标注 $annotationCount 个');
    }

    final encoded = _encodeOutput(image, options);
    if (options.outputFormat == GeneralImageOutputFormat.jpeg) {
      summary.add('JPEG ${options.jpegQuality.clamp(1, 100)}质量');
    }

    return GeneralImageEditResult(
      bytes: encoded,
      width: image.width,
      height: image.height,
      summary: summary.isEmpty ? '保存副本' : summary.join(' · '),
      outputFormat: options.outputFormat,
    );
  }

  static Future<GeneralImageEditResult> editInBackground(
    Uint8List imageBytes, {
    required GeneralImageEditOptions options,
  }) {
    return compute(
      _editInIsolate,
      _GeneralImageEditTask(imageBytes, options),
      debugLabel: 'general-image-edit',
    );
  }

  static Future<ImageInspectionResult> inspectInBackground(
    Uint8List imageBytes,
  ) {
    return compute(
      _inspectInIsolate,
      imageBytes,
      debugLabel: 'general-image-inspect',
    );
  }

  static image_lib.Image _cropByMargins(
    image_lib.Image source,
    ImageCropMargins margins,
  ) {
    final left = margins.left.clamp(0, source.width - 1).toInt();
    final top = margins.top.clamp(0, source.height - 1).toInt();
    final right = margins.right.clamp(0, source.width - left - 1).toInt();
    final bottom = margins.bottom.clamp(0, source.height - top - 1).toInt();
    final width = source.width - left - right;
    final height = source.height - top - bottom;
    final output = image_lib.Image(
      width: width,
      height: height,
      numChannels: 4,
    );

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        output.setPixel(x, y, source.getPixel(left + x, top + y));
      }
    }
    return output;
  }

  static image_lib.Image _rotateQuarterTurns(
    image_lib.Image source,
    int quarterTurns,
  ) {
    final turns = _normalizeQuarterTurns(quarterTurns);
    if (turns == 0) {
      return source;
    }

    final output = image_lib.Image(
      width: turns.isOdd ? source.height : source.width,
      height: turns.isOdd ? source.width : source.height,
      numChannels: 4,
    );

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final (targetX, targetY) = switch (turns) {
          1 => (source.height - 1 - y, x),
          2 => (source.width - 1 - x, source.height - 1 - y),
          _ => (y, source.width - 1 - x),
        };
        output.setPixel(targetX, targetY, pixel);
      }
    }
    return output;
  }

  static image_lib.Image _flipHorizontal(image_lib.Image source) {
    final output = image_lib.Image(
      width: source.width,
      height: source.height,
      numChannels: 4,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        output.setPixel(source.width - 1 - x, y, source.getPixel(x, y));
      }
    }
    return output;
  }

  static image_lib.Image _flipVertical(image_lib.Image source) {
    final output = image_lib.Image(
      width: source.width,
      height: source.height,
      numChannels: 4,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        output.setPixel(x, source.height - 1 - y, source.getPixel(x, y));
      }
    }
    return output;
  }

  static _ResolvedResize? _resolveResize(
    image_lib.Image image,
    ImageResizeOptions resize,
  ) {
    final rawWidth = resize.width;
    final rawHeight = resize.height;
    if (rawWidth == null && rawHeight == null) {
      return null;
    }

    final width = rawWidth == null
        ? math.max(1, (image.width * (rawHeight! / image.height)).round())
        : rawWidth.clamp(1, 8192).toInt();
    final height = rawHeight == null
        ? math.max(1, (image.height * (width / image.width)).round())
        : rawHeight.clamp(1, 8192).toInt();

    if (width == image.width && height == image.height) {
      return null;
    }
    return _ResolvedResize(width, height);
  }

  static image_lib.Image _applyEffects(
    image_lib.Image source,
    GeneralImageEditOptions options,
    List<String> summary,
  ) {
    final region = _resolveEffectRegion(source, options.effectRegion);
    if (region == null) {
      return _applyEffectsToImage(source, options, summary);
    }

    final regionImage = _copyRegion(source, region);
    final summaryLength = summary.length;
    final editedRegion = _applyEffectsToImage(regionImage, options, summary);
    _pasteRegion(source, editedRegion, region);
    if (summary.length > summaryLength) {
      summary.add('局部选区');
    }
    return source;
  }

  static image_lib.Image _applyEffectsToImage(
    image_lib.Image image,
    GeneralImageEditOptions options,
    List<String> summary,
  ) {
    final tolerance = options.backgroundTransparencyTolerance;
    if (tolerance != null) {
      final result = BackgroundTransparencyService.makeBackgroundTransparent(
        Uint8List.fromList(image_lib.encodePng(image)),
        tolerance: tolerance,
      );
      image = image_lib.decodeImage(result.pngBytes)!.convert(numChannels: 4);
      summary.add('边缘背景转透明');
    }

    if (!options.adjustments.isEmpty ||
        options.effect != ImageEditColorEffect.none) {
      image = _applyColor(
        image,
        adjustments: options.adjustments,
        effect: options.effect,
      );
      if (!options.adjustments.isEmpty) {
        summary.add('色彩调整');
      }
      if (options.effect != ImageEditColorEffect.none) {
        summary.add(_effectLabel(options.effect));
      }
    }

    final blurRadius = options.blurRadius.clamp(0, 20).toInt();
    if (blurRadius > 0) {
      image = image_lib.gaussianBlur(image, radius: blurRadius);
      summary.add('模糊 ${blurRadius}px');
    }

    final sharpenAmount = options.sharpenAmount.clamp(0, 100).toInt();
    if (sharpenAmount > 0) {
      image = _applyUnsharpMask(image, sharpenAmount);
      summary.add('锐化 $sharpenAmount%');
    }

    if (options.pixelationBlockSize > 0) {
      final blockSize = PixelationService.normalizeBlockSize(
        options.pixelationBlockSize,
      );
      image = PixelationService.pixelateDecodedImage(
        image,
        blockSize: blockSize,
      );
      summary.add('像素化 ${blockSize}px');
    }

    return image;
  }

  static _ImageEditPixelRegion? _resolveEffectRegion(
    image_lib.Image image,
    ImageEffectRegion region,
  ) {
    if (!region.enabled || image.width <= 1 || image.height <= 1) {
      return null;
    }

    final leftRatio = math.min(region.leftRatio, region.rightRatio).clamp(0, 1);
    final rightRatio = math
        .max(region.leftRatio, region.rightRatio)
        .clamp(0, 1);
    final topRatio = math.min(region.topRatio, region.bottomRatio).clamp(0, 1);
    final bottomRatio = math
        .max(region.topRatio, region.bottomRatio)
        .clamp(0, 1);

    final left = (leftRatio * image.width)
        .floor()
        .clamp(0, image.width - 1)
        .toInt();
    final top = (topRatio * image.height)
        .floor()
        .clamp(0, image.height - 1)
        .toInt();
    final right = (rightRatio * image.width)
        .ceil()
        .clamp(left + 1, image.width)
        .toInt();
    final bottom = (bottomRatio * image.height)
        .ceil()
        .clamp(top + 1, image.height)
        .toInt();

    if (left == 0 &&
        top == 0 &&
        right == image.width &&
        bottom == image.height) {
      return null;
    }
    return _ImageEditPixelRegion(left, top, right, bottom);
  }

  static image_lib.Image _copyRegion(
    image_lib.Image source,
    _ImageEditPixelRegion region,
  ) {
    final output = image_lib.Image(
      width: region.width,
      height: region.height,
      numChannels: 4,
    );
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        output.setPixel(x, y, source.getPixel(region.left + x, region.top + y));
      }
    }
    return output;
  }

  static void _pasteRegion(
    image_lib.Image target,
    image_lib.Image regionImage,
    _ImageEditPixelRegion region,
  ) {
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        target.setPixel(
          region.left + x,
          region.top + y,
          regionImage.getPixel(x, y),
        );
      }
    }
  }

  static image_lib.Image _applyColor(
    image_lib.Image source, {
    required ImageColorAdjustments adjustments,
    required ImageEditColorEffect effect,
  }) {
    final output = image_lib.Image(
      width: source.width,
      height: source.height,
      numChannels: 4,
    );
    final contrastInput = adjustments.contrast.clamp(-100, 100) * 2.55;
    final contrastFactor =
        (259 * (contrastInput + 255)) / (255 * (259 - contrastInput));
    final brightnessOffset = adjustments.brightness.clamp(-100, 100) * 2.55;
    final saturationFactor = 1 + adjustments.saturation.clamp(-100, 100) / 100;
    final warmth = adjustments.warmth.clamp(-100, 100);

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final alpha = pixel.a.toInt().clamp(0, 255);
        var red = pixel.r.toDouble();
        var green = pixel.g.toDouble();
        var blue = pixel.b.toDouble();

        red = contrastFactor * (red - 128) + 128 + brightnessOffset;
        green = contrastFactor * (green - 128) + 128 + brightnessOffset;
        blue = contrastFactor * (blue - 128) + 128 + brightnessOffset;

        final luminance = 0.299 * red + 0.587 * green + 0.114 * blue;
        red = luminance + (red - luminance) * saturationFactor;
        green = luminance + (green - luminance) * saturationFactor;
        blue = luminance + (blue - luminance) * saturationFactor;

        red += warmth * 0.7;
        blue -= warmth * 0.55;

        final (effectRed, effectGreen, effectBlue) = _applyEffect(
          red,
          green,
          blue,
          effect,
        );
        output.setPixelRgba(
          x,
          y,
          _channel(effectRed),
          _channel(effectGreen),
          _channel(effectBlue),
          alpha,
        );
      }
    }
    return output;
  }

  static (double, double, double) _applyEffect(
    double red,
    double green,
    double blue,
    ImageEditColorEffect effect,
  ) {
    return switch (effect) {
      ImageEditColorEffect.none => (red, green, blue),
      ImageEditColorEffect.grayscale => (
        0.299 * red + 0.587 * green + 0.114 * blue,
        0.299 * red + 0.587 * green + 0.114 * blue,
        0.299 * red + 0.587 * green + 0.114 * blue,
      ),
      ImageEditColorEffect.sepia => (
        red * 0.393 + green * 0.769 + blue * 0.189,
        red * 0.349 + green * 0.686 + blue * 0.168,
        red * 0.272 + green * 0.534 + blue * 0.131,
      ),
      ImageEditColorEffect.invert => (255 - red, 255 - green, 255 - blue),
    };
  }

  static image_lib.Image _applyUnsharpMask(image_lib.Image source, int amount) {
    final strength = amount.clamp(0, 100) / 100;
    if (strength <= 0) {
      return source;
    }

    final blurred = image_lib.gaussianBlur(
      image_lib.Image.from(source),
      radius: 1,
    );
    final output = image_lib.Image(
      width: source.width,
      height: source.height,
      numChannels: 4,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final original = source.getPixel(x, y);
        final smooth = blurred.getPixel(x, y);
        output.setPixelRgba(
          x,
          y,
          _channel(original.r + (original.r - smooth.r) * strength),
          _channel(original.g + (original.g - smooth.g) * strength),
          _channel(original.b + (original.b - smooth.b) * strength),
          original.a.toInt().clamp(0, 255),
        );
      }
    }
    return output;
  }

  static void _applyAnnotations(
    image_lib.Image image,
    List<ImageAnnotation> annotations,
  ) {
    for (final annotation in annotations) {
      if (!annotation.hasVisibleContent) {
        continue;
      }
      final start = _annotationPoint(
        image,
        annotation.startXRatio,
        annotation.startYRatio,
      );
      final end = _annotationPoint(
        image,
        annotation.endXRatio,
        annotation.endYRatio,
      );
      final color = _annotationColor(annotation.colorArgb);
      final strokeWidth = annotation.strokeWidth.clamp(1, 64).toInt();

      switch (annotation.kind) {
        case ImageAnnotationKind.text:
          image_lib.drawString(
            image,
            annotation.text.trim(),
            font: _annotationFont(annotation.fontSize),
            x: start.x,
            y: start.y,
            color: color,
          );
        case ImageAnnotationKind.rectangle:
          if (annotation.filled) {
            image_lib.fillRect(
              image,
              x1: start.x,
              y1: start.y,
              x2: end.x,
              y2: end.y,
              color: color,
            );
          } else {
            image_lib.drawRect(
              image,
              x1: start.x,
              y1: start.y,
              x2: end.x,
              y2: end.y,
              color: color,
              thickness: strokeWidth,
            );
          }
        case ImageAnnotationKind.ellipse:
          _drawEllipse(
            image,
            start: start,
            end: end,
            color: color,
            strokeWidth: strokeWidth,
            filled: annotation.filled,
          );
        case ImageAnnotationKind.line:
          _drawLine(
            image,
            start: start,
            end: end,
            color: color,
            strokeWidth: strokeWidth,
          );
        case ImageAnnotationKind.arrow:
          _drawArrow(
            image,
            start: start,
            end: end,
            color: color,
            strokeWidth: strokeWidth,
          );
      }
    }
  }

  static _AnnotationPoint _annotationPoint(
    image_lib.Image image,
    double xRatio,
    double yRatio,
  ) {
    final x = (xRatio.clamp(0, 1) * (image.width - 1)).round();
    final y = (yRatio.clamp(0, 1) * (image.height - 1)).round();
    return _AnnotationPoint(x, y);
  }

  static image_lib.ColorRgba8 _annotationColor(int argb) {
    return image_lib.ColorRgba8(
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
      (argb >> 24) & 0xFF,
    );
  }

  static image_lib.BitmapFont _annotationFont(int fontSize) {
    if (fontSize <= 14) {
      return image_lib.arial14;
    }
    if (fontSize <= 24) {
      return image_lib.arial24;
    }
    return image_lib.arial48;
  }

  static void _drawLine(
    image_lib.Image image, {
    required _AnnotationPoint start,
    required _AnnotationPoint end,
    required image_lib.Color color,
    required int strokeWidth,
  }) {
    image_lib.drawLine(
      image,
      x1: start.x,
      y1: start.y,
      x2: end.x,
      y2: end.y,
      color: color,
      thickness: strokeWidth,
      antialias: true,
    );
  }

  static void _drawArrow(
    image_lib.Image image, {
    required _AnnotationPoint start,
    required _AnnotationPoint end,
    required image_lib.Color color,
    required int strokeWidth,
  }) {
    _drawLine(
      image,
      start: start,
      end: end,
      color: color,
      strokeWidth: strokeWidth,
    );

    final dx = end.x - start.x;
    final dy = end.y - start.y;
    if (dx == 0 && dy == 0) {
      return;
    }

    final angle = math.atan2(dy, dx);
    final headLength = math.max(10.0, strokeWidth * 4.0);
    const headAngle = math.pi / 7;
    for (final direction in <double>[angle - headAngle, angle + headAngle]) {
      final head = _AnnotationPoint(
        (end.x - math.cos(direction) * headLength).round(),
        (end.y - math.sin(direction) * headLength).round(),
      );
      _drawLine(
        image,
        start: end,
        end: head,
        color: color,
        strokeWidth: strokeWidth,
      );
    }
  }

  static void _drawEllipse(
    image_lib.Image image, {
    required _AnnotationPoint start,
    required _AnnotationPoint end,
    required image_lib.Color color,
    required int strokeWidth,
    required bool filled,
  }) {
    final left = math.min(start.x, end.x);
    final right = math.max(start.x, end.x);
    final top = math.min(start.y, end.y);
    final bottom = math.max(start.y, end.y);
    final radiusX = math.max(1, (right - left) / 2);
    final radiusY = math.max(1, (bottom - top) / 2);
    final centerX = left + radiusX;
    final centerY = top + radiusY;

    if (filled) {
      for (var y = top; y <= bottom; y++) {
        final normalizedY = (y - centerY) / radiusY;
        final span =
            radiusX * math.sqrt(math.max(0, 1 - normalizedY * normalizedY));
        image_lib.drawLine(
          image,
          x1: (centerX - span).round(),
          y1: y,
          x2: (centerX + span).round(),
          y2: y,
          color: color,
        );
      }
      return;
    }

    const segments = 96;
    _AnnotationPoint? previous;
    for (var i = 0; i <= segments; i++) {
      final angle = (math.pi * 2 * i) / segments;
      final point = _AnnotationPoint(
        (centerX + math.cos(angle) * radiusX).round(),
        (centerY + math.sin(angle) * radiusY).round(),
      );
      final last = previous;
      if (last != null) {
        _drawLine(
          image,
          start: last,
          end: point,
          color: color,
          strokeWidth: strokeWidth,
        );
      }
      previous = point;
    }
  }

  static Uint8List _encodeOutput(
    image_lib.Image image,
    GeneralImageEditOptions options,
  ) {
    return switch (options.outputFormat) {
      GeneralImageOutputFormat.png => Uint8List.fromList(
        image_lib.encodePng(image),
      ),
      GeneralImageOutputFormat.jpeg => Uint8List.fromList(
        image_lib.encodeJpg(
          _flattenForJpeg(image),
          quality: options.jpegQuality.clamp(1, 100).toInt(),
        ),
      ),
    };
  }

  static image_lib.Image _flattenForJpeg(image_lib.Image source) {
    final output = image_lib.Image(
      width: source.width,
      height: source.height,
      numChannels: 3,
    );

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final alpha = pixel.a.toDouble().clamp(0, 255) / 255;
        final red = _channel(pixel.r * alpha + 255 * (1 - alpha));
        final green = _channel(pixel.g * alpha + 255 * (1 - alpha));
        final blue = _channel(pixel.b * alpha + 255 * (1 - alpha));
        output.setPixelRgb(x, y, red, green, blue);
      }
    }

    return output;
  }

  static int _normalizeQuarterTurns(int quarterTurns) {
    return ((quarterTurns % 4) + 4) % 4;
  }

  static int _channel(double value) {
    return value.round().clamp(0, 255).toInt();
  }

  static String _effectLabel(ImageEditColorEffect effect) {
    return switch (effect) {
      ImageEditColorEffect.none => '原色',
      ImageEditColorEffect.grayscale => '灰度',
      ImageEditColorEffect.sepia => '复古',
      ImageEditColorEffect.invert => '反相',
    };
  }
}

GeneralImageEditResult _editInIsolate(_GeneralImageEditTask task) {
  return GeneralImageEditingService.edit(
    task.imageBytes,
    options: task.options,
  );
}

ImageInspectionResult _inspectInIsolate(Uint8List imageBytes) {
  return GeneralImageEditingService.inspect(imageBytes);
}

class _GeneralImageEditTask {
  const _GeneralImageEditTask(this.imageBytes, this.options);

  final Uint8List imageBytes;
  final GeneralImageEditOptions options;
}

class _ResolvedResize {
  const _ResolvedResize(this.width, this.height);

  final int width;
  final int height;
}

class _ImageEditPixelRegion {
  const _ImageEditPixelRegion(this.left, this.top, this.right, this.bottom);

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => right - left;
  int get height => bottom - top;
}

class _AnnotationPoint {
  const _AnnotationPoint(this.x, this.y);

  final int x;
  final int y;
}
