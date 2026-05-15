part of 'sprite_sheet_service.dart';

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
