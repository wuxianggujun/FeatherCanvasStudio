import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/image_library_item.dart';
import '../utils/display_labels.dart';
import 'app_local_store.dart';

class ImageLibraryArchiveException implements Exception {
  const ImageLibraryArchiveException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ImageLibraryArchiveExportResult {
  const ImageLibraryArchiveExportResult({
    required this.path,
    required this.exportedCount,
    required this.skippedMissingCount,
  });

  final String path;
  final int exportedCount;
  final int skippedMissingCount;
}

class ImageLibraryArchiveImportResult {
  const ImageLibraryArchiveImportResult({
    required this.importedItems,
    required this.skippedItems,
  });

  final List<ImageLibraryItem> importedItems;
  final int skippedItems;

  int get importedCount => importedItems.length;
}

class ImageLibraryArchiveService {
  const ImageLibraryArchiveService();

  static const int schemaVersion = 1;
  static const String manifestPath = 'feather_canvas_library.json';

  Future<ImageLibraryArchiveExportResult> exportArchive({
    required List<ImageLibraryItem> items,
    required String outputPath,
  }) async {
    final archive = Archive();
    final manifestItems = <Map<String, dynamic>>[];
    var skippedMissingCount = 0;

    for (final item in items) {
      final file = File(item.path);
      if (!await file.exists()) {
        skippedMissingCount += 1;
        continue;
      }

      final assetPath = _assetPathForItem(item);
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile.bytes(assetPath, bytes));
      manifestItems.add({'assetPath': assetPath, 'item': item.toJson()});
    }

    final manifest = {
      'schemaVersion': schemaVersion,
      'app': 'FeatherCanvas Studio',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'items': manifestItems,
    };
    archive.addFile(
      ArchiveFile.string(
        manifestPath,
        const JsonEncoder.withIndent('  ').convert(manifest),
      ),
    );

    final bytes = ZipEncoder().encode(archive);
    if (bytes.isEmpty) {
      throw const ImageLibraryArchiveException('作品库归档生成失败。');
    }

    final outputFile = File(outputPath);
    final parent = outputFile.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await outputFile.writeAsBytes(bytes, flush: true);

    return ImageLibraryArchiveExportResult(
      path: outputFile.path,
      exportedCount: manifestItems.length,
      skippedMissingCount: skippedMissingCount,
    );
  }

  Future<ImageLibraryArchiveImportResult> importArchive({
    required AppLocalStore store,
    required String archivePath,
  }) async {
    final archiveFile = File(archivePath);
    if (!await archiveFile.exists()) {
      throw const ImageLibraryArchiveException('导入文件不存在。');
    }

    final archive = ZipDecoder().decodeBytes(
      await archiveFile.readAsBytes(),
      verify: true,
    );
    final manifestFile = archive.findFile(manifestPath);
    if (manifestFile == null) {
      throw const ImageLibraryArchiveException('归档中缺少作品库元数据。');
    }

    final manifest = jsonDecode(utf8.decode(manifestFile.content));
    if (manifest is! Map || manifest['schemaVersion'] != schemaVersion) {
      throw const ImageLibraryArchiveException('作品库归档版本不受支持。');
    }

    final rawItems = manifest['items'];
    if (rawItems is! List) {
      throw const ImageLibraryArchiveException('作品库元数据格式不正确。');
    }

    final outputDirectory = await store.ensureGeneratedImagesDirectory();
    final importId = DateTime.now().microsecondsSinceEpoch.toString();
    final groupIdMap = <String, String>{};
    final importedItems = <ImageLibraryItem>[];
    var skippedItems = 0;

    for (var index = 0; index < rawItems.length; index++) {
      final raw = rawItems[index];
      if (raw is! Map) {
        skippedItems += 1;
        continue;
      }
      final assetPath = raw['assetPath'] as String?;
      final itemJson = raw['item'];
      if (assetPath == null ||
          itemJson is! Map ||
          !_isSafeAssetPath(assetPath)) {
        skippedItems += 1;
        continue;
      }

      final asset = archive.findFile(assetPath);
      if (asset == null || !asset.isFile) {
        skippedItems += 1;
        continue;
      }

      final sourceItem = ImageLibraryItem.fromJson(
        Map<String, dynamic>.from(itemJson),
      );
      final extension = _safeExtension(
        assetPath,
        fallbackPath: sourceItem.path,
      );
      final outputFile = File(
        '${outputDirectory.path}${Platform.pathSeparator}'
        'import_${importId}_${index.toString().padLeft(3, '0')}$extension',
      );
      await outputFile.writeAsBytes(
        Uint8List.fromList(asset.content),
        flush: true,
      );

      final sourceGroupId = sourceItem.groupId;
      final importedGroupId = sourceGroupId == null
          ? null
          : groupIdMap.putIfAbsent(
              sourceGroupId,
              () => 'import_${importId}_${groupIdMap.length + 1}',
            );
      importedItems.add(
        ImageLibraryItem(
          id: ImageLibraryItem.newId(seed: index),
          path: outputFile.path,
          createdAt: DateTime.now().add(Duration(microseconds: index)),
          kind: sourceItem.kind,
          title: sourceItem.displayTitle,
          source: sourceItem.source.isEmpty ? '作品库导入' : sourceItem.source,
          note: sourceItem.note,
          tags: sourceItem.tags,
          project: sourceItem.project,
          prompt: sourceItem.prompt,
          generation: sourceItem.generation,
          groupId: importedGroupId,
          rows: sourceItem.rows,
          columns: sourceItem.columns,
          gridSpec: sourceItem.gridSpec,
          frameWidth: sourceItem.frameWidth,
          frameHeight: sourceItem.frameHeight,
          frameIndex: sourceItem.frameIndex,
        ),
      );
    }

    return ImageLibraryArchiveImportResult(
      importedItems: importedItems,
      skippedItems: skippedItems,
    );
  }

  static String suggestedArchiveName({DateTime? now}) {
    final value = now ?? DateTime.now();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return 'feather-canvas-library-'
        '${value.year}${twoDigits(value.month)}${twoDigits(value.day)}-'
        '${twoDigits(value.hour)}${twoDigits(value.minute)}.zip';
  }

  static String _assetPathForItem(ImageLibraryItem item) {
    final extension = _safeExtension(item.path);
    return 'assets/${_safeArchiveName(item.id)}$extension';
  }

  static String _safeArchiveName(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9A-Za-z_.-]+'), '_');
    return normalized.isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : normalized;
  }

  static bool _isSafeAssetPath(String value) {
    final normalized = value.replaceAll('\\', '/');
    return normalized.startsWith('assets/') &&
        !normalized.contains('..') &&
        !normalized.startsWith('/') &&
        normalized == value;
  }

  static String _safeExtension(String path, {String? fallbackPath}) {
    String extensionFrom(String value) {
      final fileName = fileNameFromPath(value);
      final dot = fileName.lastIndexOf('.');
      if (dot <= 0 || dot == fileName.length - 1) {
        return '';
      }
      final extension = fileName.substring(dot).toLowerCase();
      return RegExp(r'^\.[0-9a-z]+$').hasMatch(extension) ? extension : '';
    }

    final extension = extensionFrom(path);
    if (extension.isNotEmpty) {
      return extension;
    }
    final fallback = fallbackPath == null ? '' : extensionFrom(fallbackPath);
    return fallback.isEmpty ? '.png' : fallback;
  }
}
