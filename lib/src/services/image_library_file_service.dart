import 'dart:io';

import 'package:flutter/services.dart';

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
