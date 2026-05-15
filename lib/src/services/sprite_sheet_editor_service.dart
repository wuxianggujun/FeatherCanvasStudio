part of 'sprite_sheet_service.dart';

class SpriteSheetEditorComposer {
  const SpriteSheetEditorComposer._();

  static Uint8List replaceFrame({
    required Uint8List sheetBytes,
    required Uint8List patchBytes,
    required int rows,
    required int columns,
    required int frameIndex,
    required SpriteSheetFrameFit fit,
  }) {
    if (rows <= 0 || columns <= 0) {
      throw const ImageGenerationException('替换帧需要有效的行列数。');
    }

    final totalFrames = rows * columns;
    if (frameIndex < 0 || frameIndex >= totalFrames) {
      throw ImageGenerationException('目标帧超出范围：当前只有 $totalFrames 帧。');
    }

    final sheet = image_lib.decodeImage(sheetBytes);
    if (sheet == null) {
      throw const ImageGenerationException('Sprite Sheet 无法解码。');
    }

    final patch = image_lib.decodeImage(patchBytes);
    if (patch == null) {
      throw const ImageGenerationException('单帧图片无法解码。');
    }

    final frameWidth = (sheet.width / columns).floor();
    final frameHeight = (sheet.height / rows).floor();
    if (frameWidth <= 0 || frameHeight <= 0) {
      throw const ImageGenerationException('Sprite Sheet 尺寸不足，无法替换帧。');
    }

    final editedSheet = sheet.clone(noAnimation: true);
    final normalizedPatch = _normalizePatch(
      patch,
      width: frameWidth,
      height: frameHeight,
      fit: fit,
    );
    final row = frameIndex ~/ columns;
    final column = frameIndex % columns;

    image_lib.compositeImage(
      editedSheet,
      normalizedPatch,
      dstX: column * frameWidth,
      dstY: row * frameHeight,
    );

    return Uint8List.fromList(image_lib.encodePng(editedSheet));
  }

  static image_lib.Image _normalizePatch(
    image_lib.Image patch, {
    required int width,
    required int height,
    required SpriteSheetFrameFit fit,
  }) {
    return switch (fit) {
      SpriteSheetFrameFit.stretch => image_lib.copyResize(
        patch,
        width: width,
        height: height,
      ),
      SpriteSheetFrameFit.contain => _containPatch(
        patch,
        width: width,
        height: height,
      ),
      SpriteSheetFrameFit.cover => _coverPatch(
        patch,
        width: width,
        height: height,
      ),
    };
  }

  static image_lib.Image _containPatch(
    image_lib.Image patch, {
    required int width,
    required int height,
  }) {
    final scale = _minDouble(width / patch.width, height / patch.height);
    final resizedWidth = (patch.width * scale).round().clamp(1, width);
    final resizedHeight = (patch.height * scale).round().clamp(1, height);
    final resized = image_lib.copyResize(
      patch,
      width: resizedWidth,
      height: resizedHeight,
    );
    final canvas = image_lib.Image(width: width, height: height, numChannels: 4)
      ..clear(image_lib.ColorRgba8(0, 0, 0, 0));

    image_lib.compositeImage(
      canvas,
      resized,
      dstX: (width - resizedWidth) ~/ 2,
      dstY: (height - resizedHeight) ~/ 2,
    );
    return canvas;
  }

  static image_lib.Image _coverPatch(
    image_lib.Image patch, {
    required int width,
    required int height,
  }) {
    final scale = _maxDouble(width / patch.width, height / patch.height);
    final resizedWidth = (patch.width * scale).round().clamp(width, 1 << 30);
    final resizedHeight = (patch.height * scale).round().clamp(height, 1 << 30);
    final resized = image_lib.copyResize(
      patch,
      width: resizedWidth,
      height: resizedHeight,
    );

    return image_lib.copyCrop(
      resized,
      x: ((resizedWidth - width) / 2).floor(),
      y: ((resizedHeight - height) / 2).floor(),
      width: width,
      height: height,
    );
  }
}

double _minDouble(double a, double b) => a < b ? a : b;

double _maxDouble(double a, double b) => a > b ? a : b;
