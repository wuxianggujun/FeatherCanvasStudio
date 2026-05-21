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
    required this.gridSpec,
  });

  final Uint8List sheetBytes;
  final List<Uint8List> frames;
  final int rows;
  final int columns;
  final int sheetWidth;
  final int sheetHeight;
  final int frameWidth;
  final int frameHeight;
  final SpriteSheetGridSpec gridSpec;

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
    final scaleX = displaySize.width / sheetWidth;
    final scaleY = displaySize.height / sheetHeight;
    final firstCell = gridSpec.cellRectForSheet(
      sheetWidth: sheetWidth,
      sheetHeight: sheetHeight,
      row: row,
      column: 0,
    );
    final rowHeight = gridSpec.frameHeightForSheet(sheetHeight);
    return Rect.fromLTWH(
      firstCell.left * scaleX,
      firstCell.top * scaleY,
      (frameWidth * columns + gridSpec.columnGap * (columns - 1)) * scaleX,
      rowHeight * scaleY,
    );
  }

  Rect cellRectForDisplay(Size displaySize, int row, int column) {
    final scaleX = displaySize.width / sheetWidth;
    final scaleY = displaySize.height / sheetHeight;
    final cellRect = gridSpec.cellRectForSheet(
      sheetWidth: sheetWidth,
      sheetHeight: sheetHeight,
      row: row,
      column: column,
    );
    return Rect.fromLTWH(
      cellRect.left * scaleX,
      cellRect.top * scaleY,
      cellRect.width * scaleX,
      cellRect.height * scaleY,
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
    SpriteSheetGridSpec? gridSpec,
    SpriteSheetPreviewSourceMode sourceMode = SpriteSheetPreviewSourceMode.auto,
  }) async {
    final spec = _resolveGridSpec(
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
    )..validateForSheet(context: '切片预览');
    if (images.isEmpty) {
      throw const ImageGenerationException('没有可用于切片预览的图片。');
    }

    if (sourceMode == SpriteSheetPreviewSourceMode.sheet ||
        (sourceMode == SpriteSheetPreviewSourceMode.auto &&
            images.length == 1)) {
      final sheetBytes = await _resolveGeneratedImageBytesForPreview(
        images.single,
      );
      return buildFromSheetBytesInBackground(
        sheetBytes,
        rows: spec.rows,
        columns: spec.columns,
        gridSpec: spec,
      );
    }

    return _buildFromFrames(images, gridSpec: spec);
  }

  static SpriteSheetPreviewData buildFromSheetBytes(
    Uint8List sheetBytes, {
    required int rows,
    required int columns,
    SpriteSheetGridSpec? gridSpec,
  }) {
    final spec = _resolveGridSpec(
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
    )..validateForSheet(context: '切片预览');

    return _buildFromSheetBytes(sheetBytes, gridSpec: spec);
  }

  static Future<SpriteSheetPreviewData> buildFromSheetBytesInBackground(
    Uint8List sheetBytes, {
    required int rows,
    required int columns,
    SpriteSheetGridSpec? gridSpec,
  }) {
    return compute(
      _buildSpriteSheetPreviewFromSheetInIsolate,
      _SpriteSheetPreviewSheetTask(
        sheetBytes: sheetBytes,
        rows: rows,
        columns: columns,
        gridSpec: gridSpec,
      ),
      debugLabel: 'sprite-sheet-preview-from-sheet',
    );
  }

  static Future<SpriteSheetPreviewData> _buildFromFrames(
    List<GeneratedImage> images, {
    required SpriteSheetGridSpec gridSpec,
  }) async {
    final totalFrames = gridSpec.totalFrameCount;
    final frameBytes = <Uint8List>[];

    for (final image in images.take(totalFrames)) {
      frameBytes.add(await _resolveGeneratedImageBytesForPreview(image));
    }

    return compute(
      _buildSpriteSheetPreviewFromFramesInIsolate,
      _SpriteSheetPreviewFramesTask(frameBytes: frameBytes, gridSpec: gridSpec),
      debugLabel: 'sprite-sheet-preview-from-frames',
    );
  }

  static SpriteSheetPreviewData _buildFromFrameBytes(
    List<Uint8List> frameBytes, {
    required SpriteSheetGridSpec gridSpec,
  }) {
    final totalFrames = gridSpec.totalFrameCount;
    final decodedFrames = <image_lib.Image>[];

    for (final bytes in frameBytes.take(totalFrames)) {
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
      width:
          gridSpec.marginLeft +
          gridSpec.marginRight +
          frameWidth * gridSpec.columns +
          gridSpec.columnGap * (gridSpec.columns - 1),
      height:
          gridSpec.marginTop +
          gridSpec.marginBottom +
          frameHeight * gridSpec.rows +
          gridSpec.rowGap * (gridSpec.rows - 1),
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
      final row = index ~/ gridSpec.columns;
      final column = index % gridSpec.columns;
      final cellRect = gridSpec.cellRectForSheet(
        sheetWidth: sheet.width,
        sheetHeight: sheet.height,
        row: row,
        column: column,
      );
      image_lib.compositeImage(
        sheet,
        normalizedFrame,
        dstX: cellRect.left.toInt(),
        dstY: cellRect.top.toInt(),
      );
    }

    return SpriteSheetPreviewData(
      sheetBytes: Uint8List.fromList(image_lib.encodePng(sheet)),
      frames: frames,
      rows: gridSpec.rows,
      columns: gridSpec.columns,
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      gridSpec: gridSpec,
    );
  }

  static SpriteSheetPreviewData _buildFromSheetBytes(
    Uint8List sheetBytes, {
    required SpriteSheetGridSpec gridSpec,
  }) {
    final sheet = image_lib.decodeImage(sheetBytes);
    if (sheet == null) {
      throw const ImageGenerationException('整张图片无法解码，无法切片。');
    }

    gridSpec.validateForSheet(
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      context: '整张图片',
    );
    final frameWidth = gridSpec.frameWidthForSheet(sheet.width);
    final frameHeight = gridSpec.frameHeightForSheet(sheet.height);

    final frames = <Uint8List>[];
    for (var row = 0; row < gridSpec.rows; row++) {
      for (var column = 0; column < gridSpec.columns; column++) {
        final cellRect = gridSpec.cellRectForSheet(
          sheetWidth: sheet.width,
          sheetHeight: sheet.height,
          row: row,
          column: column,
        );
        final frame = image_lib.copyCrop(
          sheet,
          x: cellRect.left.toInt(),
          y: cellRect.top.toInt(),
          width: frameWidth,
          height: frameHeight,
        );
        frames.add(Uint8List.fromList(image_lib.encodePng(frame)));
      }
    }

    return SpriteSheetPreviewData(
      sheetBytes: sheetBytes,
      frames: frames,
      rows: gridSpec.rows,
      columns: gridSpec.columns,
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      gridSpec: gridSpec,
    );
  }
}

SpriteSheetPreviewData _buildSpriteSheetPreviewFromSheetInIsolate(
  _SpriteSheetPreviewSheetTask task,
) {
  return SpriteSheetPreviewComposer.buildFromSheetBytes(
    task.sheetBytes,
    rows: task.rows,
    columns: task.columns,
    gridSpec: task.gridSpec,
  );
}

SpriteSheetPreviewData _buildSpriteSheetPreviewFromFramesInIsolate(
  _SpriteSheetPreviewFramesTask task,
) {
  return SpriteSheetPreviewComposer._buildFromFrameBytes(
    task.frameBytes,
    gridSpec: task.gridSpec,
  );
}

class _SpriteSheetPreviewSheetTask {
  const _SpriteSheetPreviewSheetTask({
    required this.sheetBytes,
    required this.rows,
    required this.columns,
    required this.gridSpec,
  });

  final Uint8List sheetBytes;
  final int rows;
  final int columns;
  final SpriteSheetGridSpec? gridSpec;
}

class _SpriteSheetPreviewFramesTask {
  const _SpriteSheetPreviewFramesTask({
    required this.frameBytes,
    required this.gridSpec,
  });

  final List<Uint8List> frameBytes;
  final SpriteSheetGridSpec gridSpec;
}

SpriteSheetGridSpec _resolveGridSpec({
  required int rows,
  required int columns,
  SpriteSheetGridSpec? gridSpec,
}) {
  if (gridSpec == null) {
    return SpriteSheetGridSpec(rows: rows, columns: columns);
  }
  if (gridSpec.rows != rows || gridSpec.columns != columns) {
    throw const ImageGenerationException('网格配置的行列数必须与传入行列数一致。');
  }
  return gridSpec;
}
