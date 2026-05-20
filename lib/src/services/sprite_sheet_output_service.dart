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
    final previewData =
        await SpriteSheetPreviewComposer.buildFromSheetBytesInBackground(
          sourceBytes,
          rows: rows,
          columns: columns,
          gridSpec: SpriteSheetGridSpec(rows: rows, columns: columns),
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
    required this.metadataPath,
    required this.directoryPath,
    this.rows,
    this.columns,
    this.gridSpec,
  });

  final String path;
  final String metadataPath;
  final String directoryPath;
  final int? rows;
  final int? columns;
  final SpriteSheetGridSpec? gridSpec;
}

class SpriteSheetFileService {
  const SpriteSheetFileService._();

  static Future<SpriteSheetFileOutput> exportPng({
    required AppLocalStore store,
    required Uint8List pngBytes,
    required int rows,
    required int columns,
    SpriteSheetGridSpec? gridSpec,
  }) async {
    final outputFile = await store.createGeneratedSpriteSheetFile(
      rows: rows,
      columns: columns,
    );
    await outputFile.writeAsBytes(pngBytes, flush: true);
    final metadata = await compute(
      _inspectSpriteSheetExportInIsolate,
      _SpriteSheetExportMetadataTask(
        pngBytes: pngBytes,
        rows: rows,
        columns: columns,
        gridSpec: gridSpec,
      ),
      debugLabel: 'sprite-sheet-export-metadata',
    );
    final metadataFile = File('${outputFile.path}.metadata.json');
    await metadataFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': 1,
        'imageFile': outputFile.uri.pathSegments.last,
        'rows': metadata.rows,
        'columns': metadata.columns,
        'totalFrames': metadata.rows * metadata.columns,
        'gridSpec': metadata.gridSpec.toJson(),
        'sheetWidth': metadata.sheetWidth,
        'sheetHeight': metadata.sheetHeight,
        'frameWidth': metadata.frameWidth,
        'frameHeight': metadata.frameHeight,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );

    return SpriteSheetFileOutput(
      path: outputFile.path,
      metadataPath: metadataFile.path,
      directoryPath: outputFile.parent.path,
      rows: metadata.rows,
      columns: metadata.columns,
      gridSpec: metadata.gridSpec,
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
    SpriteSheetGridSpec? gridSpec,
  }) async {
    final sheetBytes = await readFileBytes(sheetPath);
    final patchBytes = await readFileBytes(patchPath);
    final editedBytes =
        await SpriteSheetEditorComposer.replaceFrameInBackground(
          sheetBytes: sheetBytes,
          patchBytes: patchBytes,
          rows: rows,
          columns: columns,
          frameIndex: frameIndex,
          fit: fit,
          gridSpec: gridSpec,
        );

    return exportPng(
      store: store,
      pngBytes: editedBytes,
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
    );
  }

  static Future<SpriteSheetFileOutput> copyFrameAndSave({
    required AppLocalStore store,
    required Future<Uint8List> Function(String path) readFileBytes,
    required String sheetPath,
    required int rows,
    required int columns,
    required int sourceFrameIndex,
    required int targetFrameIndex,
    SpriteSheetGridSpec? gridSpec,
  }) async {
    final sheetBytes = await readFileBytes(sheetPath);
    final editedBytes = await SpriteSheetEditorComposer.copyFrameInBackground(
      sheetBytes: sheetBytes,
      rows: rows,
      columns: columns,
      sourceFrameIndex: sourceFrameIndex,
      targetFrameIndex: targetFrameIndex,
      gridSpec: gridSpec,
    );

    return exportPng(
      store: store,
      pngBytes: editedBytes,
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
    );
  }

  static Future<SpriteSheetFileOutput> clearFrameAndSave({
    required AppLocalStore store,
    required Future<Uint8List> Function(String path) readFileBytes,
    required String sheetPath,
    required int rows,
    required int columns,
    required int frameIndex,
    SpriteSheetGridSpec? gridSpec,
  }) async {
    final sheetBytes = await readFileBytes(sheetPath);
    final editedBytes = await SpriteSheetEditorComposer.clearFrameInBackground(
      sheetBytes: sheetBytes,
      rows: rows,
      columns: columns,
      frameIndex: frameIndex,
      gridSpec: gridSpec,
    );

    return exportPng(
      store: store,
      pngBytes: editedBytes,
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
    );
  }

  static Future<SpriteSheetFileOutput> pixelateSheetAndSave({
    required AppLocalStore store,
    required Future<Uint8List> Function(String path) readFileBytes,
    required String sheetPath,
    required int rows,
    required int columns,
    required int blockSize,
    SpriteSheetGridSpec? gridSpec,
  }) async {
    final sheetBytes = await readFileBytes(sheetPath);
    final editedBytes = (await PixelationService.pixelateInBackground(
      sheetBytes,
      blockSize: blockSize,
    )).pngBytes;

    return exportPng(
      store: store,
      pngBytes: editedBytes,
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
    );
  }

  static Future<SpriteSheetFileOutput> pixelateFrameAndSave({
    required AppLocalStore store,
    required Future<Uint8List> Function(String path) readFileBytes,
    required String sheetPath,
    required int rows,
    required int columns,
    required int frameIndex,
    required int blockSize,
    SpriteSheetGridSpec? gridSpec,
  }) async {
    final sheetBytes = await readFileBytes(sheetPath);
    final editedBytes = await compute(
      _pixelateSpriteSheetFrameInIsolate,
      _PixelateSpriteSheetFrameTask(
        sheetBytes: sheetBytes,
        rows: rows,
        columns: columns,
        frameIndex: frameIndex,
        blockSize: blockSize,
        gridSpec: gridSpec,
      ),
      debugLabel: 'sprite-sheet-frame-pixelation',
    );

    return exportPng(
      store: store,
      pngBytes: editedBytes,
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
    );
  }
}

_SpriteSheetExportMetadata _inspectSpriteSheetExportInIsolate(
  _SpriteSheetExportMetadataTask task,
) {
  final previewData = SpriteSheetPreviewComposer.buildFromSheetBytes(
    task.pngBytes,
    rows: task.rows,
    columns: task.columns,
    gridSpec: task.gridSpec,
  );
  return _SpriteSheetExportMetadata(
    rows: previewData.rows,
    columns: previewData.columns,
    gridSpec: previewData.gridSpec,
    sheetWidth: previewData.sheetWidth,
    sheetHeight: previewData.sheetHeight,
    frameWidth: previewData.frameWidth,
    frameHeight: previewData.frameHeight,
  );
}

class _SpriteSheetExportMetadataTask {
  const _SpriteSheetExportMetadataTask({
    required this.pngBytes,
    required this.rows,
    required this.columns,
    required this.gridSpec,
  });

  final Uint8List pngBytes;
  final int rows;
  final int columns;
  final SpriteSheetGridSpec? gridSpec;
}

class _SpriteSheetExportMetadata {
  const _SpriteSheetExportMetadata({
    required this.rows,
    required this.columns,
    required this.gridSpec,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.frameWidth,
    required this.frameHeight,
  });

  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;
  final int sheetWidth;
  final int sheetHeight;
  final int frameWidth;
  final int frameHeight;
}

Uint8List _pixelateSpriteSheetFrameInIsolate(
  _PixelateSpriteSheetFrameTask task,
) {
  return SpriteSheetEditorComposer.pixelateFrame(
    sheetBytes: task.sheetBytes,
    rows: task.rows,
    columns: task.columns,
    frameIndex: task.frameIndex,
    blockSize: task.blockSize,
    gridSpec: task.gridSpec,
  );
}

class _PixelateSpriteSheetFrameTask {
  const _PixelateSpriteSheetFrameTask({
    required this.sheetBytes,
    required this.rows,
    required this.columns,
    required this.frameIndex,
    required this.blockSize,
    required this.gridSpec,
  });

  final Uint8List sheetBytes;
  final int rows;
  final int columns;
  final int frameIndex;
  final int blockSize;
  final SpriteSheetGridSpec? gridSpec;
}
