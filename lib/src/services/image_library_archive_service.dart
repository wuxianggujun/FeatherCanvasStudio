import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import '../models/animation_project.dart';
import '../models/image_asset_kind.dart';
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
  }) {
    return _exportArchive(items: items, outputPath: outputPath);
  }

  Future<ImageLibraryArchiveExportResult> exportArchiveInBackground({
    required List<ImageLibraryItem> items,
    required String outputPath,
  }) {
    return compute(
      _exportArchiveInIsolate,
      _ImageLibraryArchiveExportTask(items: items, outputPath: outputPath),
      debugLabel: 'image-library-archive-export',
    );
  }

  Future<ImageLibraryArchiveExportResult> _exportArchive({
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
      final manifestItem = <String, dynamic>{
        'assetPath': assetPath,
        'item': item.toJson(),
      };
      if (item.kind == ImageAssetKind.animationProject) {
        final projectAssets = await _addAnimationProjectAssets(
          archive: archive,
          item: item,
        );
        skippedMissingCount += projectAssets.skippedMissingCount;
        if (projectAssets.entries.isNotEmpty) {
          manifestItem['projectAssets'] = projectAssets.entries;
        }
      }
      manifestItems.add(manifestItem);
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
    final outputDirectory = await store.ensureGeneratedImagesDirectory();
    return importArchiveInBackground(
      outputDirectoryPath: outputDirectory.path,
      archivePath: archivePath,
    );
  }

  Future<ImageLibraryArchiveImportResult> importArchiveInBackground({
    required String outputDirectoryPath,
    required String archivePath,
  }) {
    return compute(
      _importArchiveInIsolate,
      _ImageLibraryArchiveImportTask(
        archivePath: archivePath,
        outputDirectoryPath: outputDirectoryPath,
      ),
      debugLabel: 'image-library-archive-import',
    );
  }

  Future<ImageLibraryArchiveImportResult> _importArchiveToDirectory({
    required Directory outputDirectory,
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

    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }
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
      final sourceGroupId = sourceItem.groupId;
      var importedGroupId = sourceGroupId == null
          ? null
          : groupIdMap.putIfAbsent(
              sourceGroupId,
              () => 'import_${importId}_${groupIdMap.length + 1}',
            );
      var importedAnimationProject = sourceItem.animationProject;
      if (sourceItem.kind == ImageAssetKind.animationProject) {
        importedAnimationProject = await _writeImportedAnimationProject(
          archive: archive,
          rawManifestItem: raw,
          projectAsset: asset,
          outputFile: outputFile,
          outputDirectory: outputDirectory,
          importId: importId,
          itemIndex: index,
          importedProjectId: importedGroupId,
          fallbackSummary: sourceItem.animationProject,
        );
        importedGroupId ??= importedAnimationProject?.id;
      } else {
        await outputFile.writeAsBytes(
          Uint8List.fromList(asset.content),
          flush: true,
        );
      }
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
          animationProject: importedAnimationProject,
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

  static Future<_ProjectAssetArchiveEntries> _addAnimationProjectAssets({
    required Archive archive,
    required ImageLibraryItem item,
  }) async {
    try {
      final decoded = jsonDecode(await File(item.path).readAsString());
      if (decoded is! Map) {
        return const _ProjectAssetArchiveEntries();
      }
      final assets = decoded['assets'];
      if (assets is! List) {
        return const _ProjectAssetArchiveEntries();
      }

      final entries = <Map<String, dynamic>>[];
      var skippedMissingCount = 0;
      var assetIndex = 0;
      for (final asset in assets.whereType<Map>()) {
        final path = asset['path'];
        if (path is! String || path.isEmpty) {
          continue;
        }
        final file = File(path);
        if (!await file.exists()) {
          skippedMissingCount += 1;
          continue;
        }
        final assetPath =
            'assets/${_safeArchiveName(item.id)}_frame_$assetIndex'
            '${_safeExtension(path)}';
        archive.addFile(ArchiveFile.bytes(assetPath, await file.readAsBytes()));
        entries.add({
          'assetId': asset['id'] as String? ?? '',
          'assetPath': assetPath,
        });
        assetIndex += 1;
      }
      return _ProjectAssetArchiveEntries(
        entries: entries,
        skippedMissingCount: skippedMissingCount,
      );
    } catch (_) {
      return const _ProjectAssetArchiveEntries();
    }
  }

  static Future<AnimationProjectSummary?> _writeImportedAnimationProject({
    required Archive archive,
    required Map rawManifestItem,
    required ArchiveFile projectAsset,
    required File outputFile,
    required Directory outputDirectory,
    required String importId,
    required int itemIndex,
    required String? importedProjectId,
    required AnimationProjectSummary? fallbackSummary,
  }) async {
    Map<String, dynamic>? projectJson;
    try {
      projectJson = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(Uint8List.fromList(projectAsset.content)))
            as Map,
      );
    } catch (_) {
      await outputFile.writeAsBytes(
        Uint8List.fromList(projectAsset.content),
        flush: true,
      );
      return fallbackSummary;
    }

    final assetPathById = <String, String>{};
    final rawProjectAssets = rawManifestItem['projectAssets'];
    if (rawProjectAssets is List) {
      for (
        var assetIndex = 0;
        assetIndex < rawProjectAssets.length;
        assetIndex++
      ) {
        final rawProjectAsset = rawProjectAssets[assetIndex];
        if (rawProjectAsset is! Map) {
          continue;
        }
        final assetPath = rawProjectAsset['assetPath'] as String?;
        final assetId = rawProjectAsset['assetId'] as String? ?? '';
        if (assetPath == null || !_isSafeAssetPath(assetPath)) {
          continue;
        }
        final archivedAsset = archive.findFile(assetPath);
        if (archivedAsset == null || !archivedAsset.isFile) {
          continue;
        }
        final extension = _safeExtension(assetPath);
        final outputAssetFile = File(
          '${outputDirectory.path}${Platform.pathSeparator}'
          'import_${importId}_${itemIndex.toString().padLeft(3, '0')}'
          '_frame_${assetIndex.toString().padLeft(3, '0')}$extension',
        );
        await outputAssetFile.writeAsBytes(
          Uint8List.fromList(archivedAsset.content),
          flush: true,
        );
        if (assetId.isNotEmpty) {
          assetPathById[assetId] = outputAssetFile.path;
        }
      }
    }

    final assets = projectJson['assets'];
    if (assets is List) {
      for (final asset in assets.whereType<Map>()) {
        final id = asset['id'];
        if (id is String && assetPathById.containsKey(id)) {
          asset['path'] = assetPathById[id];
        }
      }
    }
    if (importedProjectId != null && importedProjectId.isNotEmpty) {
      projectJson['id'] = importedProjectId;
    }
    final summary = _summaryFromProjectJson(projectJson, fallbackSummary);
    if (summary != null) {
      projectJson['title'] = summary.title;
    }
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(projectJson),
      flush: true,
    );
    return summary;
  }

  static AnimationProjectSummary? _summaryFromProjectJson(
    Map<String, dynamic> json,
    AnimationProjectSummary? fallback,
  ) {
    final tracks = json['tracks'];
    var trackCount = 0;
    var frameCount = 0;
    if (tracks is List) {
      trackCount = tracks.whereType<Map>().length;
      for (final track in tracks.whereType<Map>()) {
        final clips = track['clips'];
        if (clips is! List) {
          continue;
        }
        for (final clip in clips.whereType<Map>()) {
          final frames = clip['frames'];
          if (frames is List) {
            frameCount += frames.length;
          }
        }
      }
    }
    final id = json['id'] as String? ?? fallback?.id ?? '';
    if (id.isEmpty) {
      return fallback;
    }
    return AnimationProjectSummary(
      id: id,
      title: json['title'] as String? ?? fallback?.title ?? '动画工程',
      trackCount: trackCount == 0 ? fallback?.trackCount ?? 0 : trackCount,
      frameCount: frameCount == 0 ? fallback?.frameCount ?? 0 : frameCount,
      canvasWidth:
          (json['canvasWidth'] as num?)?.toInt() ?? fallback?.canvasWidth ?? 0,
      canvasHeight:
          (json['canvasHeight'] as num?)?.toInt() ??
          fallback?.canvasHeight ??
          0,
    );
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

class _ProjectAssetArchiveEntries {
  const _ProjectAssetArchiveEntries({
    this.entries = const <Map<String, dynamic>>[],
    this.skippedMissingCount = 0,
  });

  final List<Map<String, dynamic>> entries;
  final int skippedMissingCount;
}

Future<ImageLibraryArchiveExportResult> _exportArchiveInIsolate(
  _ImageLibraryArchiveExportTask task,
) {
  return const ImageLibraryArchiveService()._exportArchive(
    items: task.items,
    outputPath: task.outputPath,
  );
}

Future<ImageLibraryArchiveImportResult> _importArchiveInIsolate(
  _ImageLibraryArchiveImportTask task,
) {
  return const ImageLibraryArchiveService()._importArchiveToDirectory(
    outputDirectory: Directory(task.outputDirectoryPath),
    archivePath: task.archivePath,
  );
}

class _ImageLibraryArchiveExportTask {
  const _ImageLibraryArchiveExportTask({
    required this.items,
    required this.outputPath,
  });

  final List<ImageLibraryItem> items;
  final String outputPath;
}

class _ImageLibraryArchiveImportTask {
  const _ImageLibraryArchiveImportTask({
    required this.archivePath,
    required this.outputDirectoryPath,
  });

  final String archivePath;
  final String outputDirectoryPath;
}
