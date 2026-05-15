part of 'sprite_sheet_service.dart';

class SpriteSheetPreviewData {
  const SpriteSheetPreviewData({
    required this.sheetBytes,
    required this.frames,
    required this.rows,
    required this.columns,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.frameWidth,
    required this.frameHeight,
  });

  final Uint8List sheetBytes;
  final List<Uint8List> frames;
  final int rows;
  final int columns;
  final int sheetWidth;
  final int sheetHeight;
  final int frameWidth;
  final int frameHeight;

  double get sheetAspectRatio => sheetWidth / sheetHeight;
  double get frameAspectRatio => frameWidth / frameHeight;

  Uint8List frameAt(int row, int column) {
    return frames[row * columns + column];
  }

  List<Uint8List> framesForRow(int row) {
    final start = row * columns;
    return frames.sublist(start, start + columns);
  }

  Size frameDisplaySizeForCell(double cellWidth) {
    return Size(cellWidth, cellWidth * frameHeight / frameWidth);
  }

  Size sheetDisplaySizeForCell(double cellWidth) {
    final frameSize = frameDisplaySizeForCell(cellWidth);
    return Size(frameSize.width * columns, frameSize.height * rows);
  }

  Rect rowRectForDisplay(Size displaySize, int row) {
    final rowHeight = displaySize.height / rows;
    return Rect.fromLTWH(0, rowHeight * row, displaySize.width, rowHeight);
  }

  Rect cellRectForDisplay(Size displaySize, int row, int column) {
    final cellWidth = displaySize.width / columns;
    final cellHeight = displaySize.height / rows;
    return Rect.fromLTWH(
      cellWidth * column,
      cellHeight * row,
      cellWidth,
      cellHeight,
    );
  }
}

enum SpriteSheetPreviewSourceMode { auto, frames, sheet }

class SpriteSheetPreviewComposer {
  const SpriteSheetPreviewComposer._();

  static Future<SpriteSheetPreviewData> build({
    required List<GeneratedImage> images,
    required int rows,
    required int columns,
    SpriteSheetPreviewSourceMode sourceMode = SpriteSheetPreviewSourceMode.auto,
  }) async {
    if (rows <= 0 || columns <= 0) {
      throw const ImageGenerationException('切片预览需要有效的行列数。');
    }
    if (images.isEmpty) {
      throw const ImageGenerationException('没有可用于切片预览的图片。');
    }

    if (sourceMode == SpriteSheetPreviewSourceMode.sheet ||
        (sourceMode == SpriteSheetPreviewSourceMode.auto &&
            images.length == 1)) {
      final sheetBytes = await _resolveGeneratedImageBytesForPreview(
        images.single,
      );
      return buildFromSheetBytes(sheetBytes, rows: rows, columns: columns);
    }

    return _buildFromFrames(images, rows: rows, columns: columns);
  }

  static SpriteSheetPreviewData buildFromSheetBytes(
    Uint8List sheetBytes, {
    required int rows,
    required int columns,
  }) {
    if (rows <= 0 || columns <= 0) {
      throw const ImageGenerationException('切片预览需要有效的行列数。');
    }

    return _buildFromSheetBytes(sheetBytes, rows: rows, columns: columns);
  }

  static Future<SpriteSheetPreviewData> _buildFromFrames(
    List<GeneratedImage> images, {
    required int rows,
    required int columns,
  }) async {
    final totalFrames = rows * columns;
    final decodedFrames = <image_lib.Image>[];

    for (final image in images.take(totalFrames)) {
      final bytes = await _resolveGeneratedImageBytesForPreview(image);
      final decodedFrame = image_lib.decodeImage(bytes);
      if (decodedFrame == null) {
        throw const ImageGenerationException('有图片无法解码，无法生成切片预览。');
      }
      decodedFrames.add(decodedFrame);
    }

    if (decodedFrames.isEmpty) {
      throw const ImageGenerationException('没有可用的帧图片。');
    }

    final frameWidth = decodedFrames.first.width;
    final frameHeight = decodedFrames.first.height;
    final sheet = image_lib.Image(
      width: frameWidth * columns,
      height: frameHeight * rows,
    );
    final frames = <Uint8List>[];

    for (var index = 0; index < totalFrames; index++) {
      final rawFrame = index < decodedFrames.length
          ? decodedFrames[index]
          : image_lib.Image(width: frameWidth, height: frameHeight);
      final normalizedFrame =
          rawFrame.width == frameWidth && rawFrame.height == frameHeight
          ? rawFrame
          : image_lib.copyResize(
              rawFrame,
              width: frameWidth,
              height: frameHeight,
            );
      frames.add(Uint8List.fromList(image_lib.encodePng(normalizedFrame)));
      image_lib.compositeImage(
        sheet,
        normalizedFrame,
        dstX: (index % columns) * frameWidth,
        dstY: (index ~/ columns) * frameHeight,
      );
    }

    return SpriteSheetPreviewData(
      sheetBytes: Uint8List.fromList(image_lib.encodePng(sheet)),
      frames: frames,
      rows: rows,
      columns: columns,
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );
  }

  static SpriteSheetPreviewData _buildFromSheetBytes(
    Uint8List sheetBytes, {
    required int rows,
    required int columns,
  }) {
    final sheet = image_lib.decodeImage(sheetBytes);
    if (sheet == null) {
      throw const ImageGenerationException('整张图片无法解码，无法切片。');
    }

    final frameWidth = (sheet.width / columns).floor();
    final frameHeight = (sheet.height / rows).floor();
    if (frameWidth <= 0 || frameHeight <= 0) {
      throw const ImageGenerationException('整张图片尺寸不足，无法按当前行列切片。');
    }

    final frames = <Uint8List>[];
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final frame = image_lib.copyCrop(
          sheet,
          x: column * frameWidth,
          y: row * frameHeight,
          width: frameWidth,
          height: frameHeight,
        );
        frames.add(Uint8List.fromList(image_lib.encodePng(frame)));
      }
    }

    return SpriteSheetPreviewData(
      sheetBytes: sheetBytes,
      frames: frames,
      rows: rows,
      columns: columns,
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );
  }
}
