part of 'sprite_sheet_service.dart';

class SpriteSheetEditorComposer {
  const SpriteSheetEditorComposer._();

  static Uint8List copyFrame({
    required Uint8List sheetBytes,
    required int rows,
    required int columns,
    required int sourceFrameIndex,
    required int targetFrameIndex,
    SpriteSheetGridSpec? gridSpec,
  }) {
    final spec = _resolveGridSpec(
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
    )..validateForSheet(context: '复制帧');
    _validateFrameIndex(sourceFrameIndex, spec.totalFrameCount);
    _validateFrameIndex(targetFrameIndex, spec.totalFrameCount);

    final sheet = image_lib.decodeImage(sheetBytes);
    if (sheet == null) {
      throw const ImageGenerationException('Sprite Sheet 无法解码。');
    }
    spec.validateForSheet(
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      context: 'Sprite Sheet',
    );

    final sourceRect = _cellRect(spec, sheet, sourceFrameIndex);
    final targetRect = _cellRect(spec, sheet, targetFrameIndex);
    final sourceFrame = image_lib.copyCrop(
      sheet,
      x: sourceRect.left.toInt(),
      y: sourceRect.top.toInt(),
      width: sourceRect.width.toInt(),
      height: sourceRect.height.toInt(),
    );
    final editedSheet = sheet.convert(numChannels: 4);
    image_lib.compositeImage(
      editedSheet,
      sourceFrame,
      dstX: targetRect.left.toInt(),
      dstY: targetRect.top.toInt(),
    );

    return Uint8List.fromList(image_lib.encodePng(editedSheet));
  }

  static Uint8List clearFrame({
    required Uint8List sheetBytes,
    required int rows,
    required int columns,
    required int frameIndex,
    SpriteSheetGridSpec? gridSpec,
  }) {
    final spec = _resolveGridSpec(
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
    )..validateForSheet(context: '清空帧');
    _validateFrameIndex(frameIndex, spec.totalFrameCount);

    final sheet = image_lib.decodeImage(sheetBytes);
    if (sheet == null) {
      throw const ImageGenerationException('Sprite Sheet 无法解码。');
    }
    spec.validateForSheet(
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      context: 'Sprite Sheet',
    );

    final rect = _cellRect(spec, sheet, frameIndex);
    final editedSheet = sheet.convert(numChannels: 4);
    _clearRectTransparent(editedSheet, rect);

    return Uint8List.fromList(image_lib.encodePng(editedSheet));
  }

  static Uint8List replaceFrame({
    required Uint8List sheetBytes,
    required Uint8List patchBytes,
    required int rows,
    required int columns,
    required int frameIndex,
    required SpriteSheetFrameFit fit,
    SpriteSheetGridSpec? gridSpec,
  }) {
    final spec = _resolveGridSpec(
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
    )..validateForSheet(context: '替换帧');

    final totalFrames = spec.totalFrameCount;
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

    spec.validateForSheet(
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      context: 'Sprite Sheet',
    );
    final frameWidth = spec.frameWidthForSheet(sheet.width);
    final frameHeight = spec.frameHeightForSheet(sheet.height);

    final editedSheet = sheet.convert(numChannels: 4);
    final normalizedPatch = _normalizePatch(
      patch,
      width: frameWidth,
      height: frameHeight,
      fit: fit,
    );
    final row = frameIndex ~/ spec.columns;
    final column = frameIndex % spec.columns;
    final cellRect = spec.cellRectForSheet(
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      row: row,
      column: column,
    );

    _clearRectTransparent(editedSheet, cellRect);
    image_lib.compositeImage(
      editedSheet,
      normalizedPatch,
      dstX: cellRect.left.toInt(),
      dstY: cellRect.top.toInt(),
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

  static Rect _cellRect(
    SpriteSheetGridSpec spec,
    image_lib.Image sheet,
    int frameIndex,
  ) {
    final row = frameIndex ~/ spec.columns;
    final column = frameIndex % spec.columns;
    return spec.cellRectForSheet(
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      row: row,
      column: column,
    );
  }

  static void _validateFrameIndex(int frameIndex, int totalFrames) {
    if (frameIndex < 0 || frameIndex >= totalFrames) {
      throw ImageGenerationException('目标帧超出范围：当前只有 $totalFrames 帧。');
    }
  }

  static void _clearRectTransparent(image_lib.Image image, Rect rect) {
    final left = rect.left.toInt().clamp(0, image.width);
    final top = rect.top.toInt().clamp(0, image.height);
    final right = rect.right.toInt().clamp(0, image.width);
    final bottom = rect.bottom.toInt().clamp(0, image.height);
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
}

double _minDouble(double a, double b) => a < b ? a : b;

double _maxDouble(double a, double b) => a > b ? a : b;
