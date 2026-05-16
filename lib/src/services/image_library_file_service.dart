import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/display_labels.dart';

enum OpenFileLocationStatus {
  opened,
  directoryMissing,
  copiedUnsupportedPlatform,
  copiedAfterFailure,
}

class OpenFileLocationResult {
  const OpenFileLocationResult({
    required this.status,
    required this.directoryPath,
  });

  final OpenFileLocationStatus status;
  final String directoryPath;
}

class ImageLibraryFileService {
  const ImageLibraryFileService();

  static String? _trashSessionId;

  Future<bool> fileExists(String path) {
    return File(path).exists();
  }

  Future<Uint8List> readFileBytes(String path) {
    return File(path).readAsBytes();
  }

  Future<void> copyTextToClipboard(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> safeDeleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 临时文件可能已被外部清理，删除失败不应中断主流程。
    }
  }

  Future<void> deleteExistingFiles(Iterable<String> paths) async {
    for (final path in paths) {
      await safeDeleteFile(path);
    }
  }

  /// 把文件移入当前会话的回收站,返回回收站路径;移动失败时返回 null
  /// (此时调用方应回退到 [safeDeleteFile])。
  Future<String?> moveToTrash(String originalPath) async {
    final source = File(originalPath);
    if (!await source.exists()) {
      return null;
    }
    try {
      final sessionDir = await _ensureTrashSessionDirectory();
      final fileName = fileNameFromPath(originalPath);
      final unique =
          '${DateTime.now().microsecondsSinceEpoch}_${_randomSuffix()}_$fileName';
      final trashPath =
          '${sessionDir.path}${Platform.pathSeparator}$unique';
      await _moveFile(source, trashPath);
      return trashPath;
    } catch (_) {
      return null;
    }
  }

  /// 把回收站文件恢复到原路径。返回 true 表示成功。
  Future<bool> restoreFromTrash({
    required String originalPath,
    required String trashPath,
  }) async {
    final source = File(trashPath);
    if (!await source.exists()) {
      return false;
    }
    try {
      final parent = File(originalPath).parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }
      await _moveFile(source, originalPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 清空当前会话的回收站目录,通常在 dispose 时调用。
  Future<void> purgeCurrentTrashSession() async {
    try {
      final base = await _trashRootDirectory();
      final sessionId = _trashSessionId;
      if (sessionId == null) return;
      final dir = Directory('${base.path}${Platform.pathSeparator}$sessionId');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // 清理失败不影响主流程。
    }
  }

  /// 清空之前会话遗留的回收站目录,启动时调用以防孤儿堆积。
  Future<void> purgeOrphanTrashSessions() async {
    try {
      final base = await _trashRootDirectory();
      if (!await base.exists()) return;
      final currentId = _trashSessionId;
      await for (final entity in base.list()) {
        if (entity is! Directory) continue;
        final name = fileNameFromPath(entity.path);
        if (currentId != null && name == currentId) continue;
        try {
          await entity.delete(recursive: true);
        } catch (_) {
          // 单个目录清理失败不影响整体。
        }
      }
    } catch (_) {
      // 清理失败不影响主流程。
    }
  }

  Future<Directory> _ensureTrashSessionDirectory() async {
    final base = await _trashRootDirectory();
    final id = _trashSessionId ??=
        '${DateTime.now().microsecondsSinceEpoch}_$pid';
    final dir = Directory('${base.path}${Platform.pathSeparator}$id');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _trashRootDirectory() async {
    Directory baseDirectory;
    try {
      baseDirectory = await getApplicationSupportDirectory();
    } catch (_) {
      baseDirectory = Directory.systemTemp;
    }
    final dir = Directory('${baseDirectory.path}${Platform.pathSeparator}trash');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _moveFile(File source, String destinationPath) async {
    try {
      await source.rename(destinationPath);
    } on FileSystemException {
      // 跨文件系统的 rename 会失败,退化为复制 + 删除。
      await source.copy(destinationPath);
      try {
        await source.delete();
      } catch (_) {
        // 复制成功但删除失败时,目标文件已建立,任务视为完成。
      }
    }
  }

  String _randomSuffix() {
    final value = DateTime.now().microsecondsSinceEpoch ^ pid;
    return value.toRadixString(36);
  }

  Future<OpenFileLocationResult> openFileLocation(String path) async {
    final file = File(path);
    final directory = file.parent;
    if (!await directory.exists()) {
      return OpenFileLocationResult(
        status: OpenFileLocationStatus.directoryMissing,
        directoryPath: directory.path,
      );
    }

    try {
      if (Platform.isWindows) {
        await Process.start('explorer.exe', ['/select,${file.path}']);
      } else if (Platform.isMacOS) {
        await Process.start('open', ['-R', file.path]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [directory.path]);
      } else {
        await copyTextToClipboard(directory.path);
        return OpenFileLocationResult(
          status: OpenFileLocationStatus.copiedUnsupportedPlatform,
          directoryPath: directory.path,
        );
      }

      return OpenFileLocationResult(
        status: OpenFileLocationStatus.opened,
        directoryPath: directory.path,
      );
    } catch (_) {
      await copyTextToClipboard(directory.path);
      return OpenFileLocationResult(
        status: OpenFileLocationStatus.copiedAfterFailure,
        directoryPath: directory.path,
      );
    }
  }
}
