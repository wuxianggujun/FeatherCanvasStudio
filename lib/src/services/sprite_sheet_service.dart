import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image_lib;

import '../models/exceptions.dart';
import '../models/generated_image.dart';
import '../models/sprite_sheet_frame_fit.dart';
import 'app_local_store.dart';

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

class SpriteSheetOutputCache {
  const SpriteSheetOutputCache._();

  static Future<SpriteSheetSaveResult> saveSheetOnly({
    required AppLocalStore store,
    required String groupId,
    required GeneratedImage sourceImage,
    required int rows,
    required int columns,
    required Future<Uint8List> Function(GeneratedImage image) resolveImageBytes,
  }) async {
    final sourceBytes = await resolveImageBytes(sourceImage);
    final previewData = SpriteSheetPreviewComposer.buildFromSheetBytes(
      sourceBytes,
      rows: rows,
      columns: columns,
    );

    final sheetFile = await store.saveGeneratedImageBytes(
      groupId: groupId,
      index: 0,
      bytes: previewData.sheetBytes,
    );
    final cachedSheet = GeneratedImage.file(
      sheetFile.path,
      revisedPrompt: sourceImage.revisedPrompt,
    );

    return SpriteSheetSaveResult(
      sheet: cachedSheet,
      rows: previewData.rows,
      columns: previewData.columns,
      frameWidth: previewData.frameWidth,
      frameHeight: previewData.frameHeight,
    );
  }
}

class SpriteSheetSaveResult {
  const SpriteSheetSaveResult({
    required this.sheet,
    required this.rows,
    required this.columns,
    required this.frameWidth,
    required this.frameHeight,
  });

  final GeneratedImage sheet;
  final int rows;
  final int columns;
  final int frameWidth;
  final int frameHeight;
}

class SpriteSheetFileOutput {
  const SpriteSheetFileOutput({
    required this.path,
    required this.directoryPath,
  });

  final String path;
  final String directoryPath;
}

class SpriteSheetFileService {
  const SpriteSheetFileService._();

  static Future<SpriteSheetFileOutput> exportPng({
    required AppLocalStore store,
    required Uint8List pngBytes,
    required int rows,
    required int columns,
  }) async {
    final outputFile = await store.createGeneratedSpriteSheetFile(
      rows: rows,
      columns: columns,
    );
    await outputFile.writeAsBytes(pngBytes, flush: true);

    return SpriteSheetFileOutput(
      path: outputFile.path,
      directoryPath: outputFile.parent.path,
    );
  }

  static Future<SpriteSheetFileOutput> replaceFrameAndSave({
    required AppLocalStore store,
    required Future<Uint8List> Function(String path) readFileBytes,
    required String sheetPath,
    required String patchPath,
    required int rows,
    required int columns,
    required int frameIndex,
    required SpriteSheetFrameFit fit,
  }) async {
    final sheetBytes = await readFileBytes(sheetPath);
    final patchBytes = await readFileBytes(patchPath);
    final editedBytes = SpriteSheetEditorComposer.replaceFrame(
      sheetBytes: sheetBytes,
      patchBytes: patchBytes,
      rows: rows,
      columns: columns,
      frameIndex: frameIndex,
      fit: fit,
    );

    return exportPng(
      store: store,
      pngBytes: editedBytes,
      rows: rows,
      columns: columns,
    );
  }
}

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

Future<Uint8List> _resolveGeneratedImageBytesForPreview(
  GeneratedImage image,
) async {
  if (image.bytes != null) {
    return image.bytes!;
  }

  if (image.filePath != null) {
    return File(image.filePath!).readAsBytes();
  }

  if (image.url != null) {
    final response = await http
        .get(Uri.parse(image.url!))
        .timeout(const Duration(minutes: 2));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ImageGenerationException(
        '切片预览下载图片失败：HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}',
      );
    }
    return response.bodyBytes;
  }

  throw const ImageGenerationException('图片没有可供切片预览的内容。');
}
