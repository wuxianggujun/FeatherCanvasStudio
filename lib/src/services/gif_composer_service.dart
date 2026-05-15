import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;

import 'app_local_store.dart';

enum GifPlaybackMode { normal, reverse, pingPong }

class GifSourceFrame {
  const GifSourceFrame({
    required this.id,
    required this.path,
    required this.delayMs,
    this.inlineBytes,
    this.label,
  });

  factory GifSourceFrame.fromPath(
    String path, {
    required int delayMs,
    required int seed,
    String? label,
  }) {
    return GifSourceFrame(
      id: '${DateTime.now().microsecondsSinceEpoch}_$seed',
      path: path,
      delayMs: delayMs,
      label: label,
    );
  }

  factory GifSourceFrame.fromBytes(
    Uint8List bytes, {
    required String sourcePath,
    required int delayMs,
    required int seed,
    String? label,
  }) {
    return GifSourceFrame(
      id: '${DateTime.now().microsecondsSinceEpoch}_$seed',
      path: sourcePath,
      delayMs: delayMs,
      inlineBytes: bytes,
      label: label,
    );
  }

  final String id;
  final String path;
  final int delayMs;
  final Uint8List? inlineBytes;
  final String? label;

  GifSourceFrame copyWith({
    String? id,
    String? path,
    int? delayMs,
    Uint8List? inlineBytes,
    String? label,
  }) {
    return GifSourceFrame(
      id: id ?? this.id,
      path: path ?? this.path,
      delayMs: delayMs ?? this.delayMs,
      inlineBytes: inlineBytes ?? this.inlineBytes,
      label: label ?? this.label,
    );
  }
}

List<T> expandGifFrameSequence<T>(List<T> items, GifPlaybackMode mode) {
  if (items.length <= 1) {
    return List<T>.from(items);
  }

  return switch (mode) {
    GifPlaybackMode.normal => List<T>.from(items),
    GifPlaybackMode.reverse => items.reversed.toList(),
    GifPlaybackMode.pingPong => [
      ...items,
      ...items.reversed.skip(1).take(items.length - 2),
    ],
  };
}

class GifComposerException implements Exception {
  const GifComposerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GifComposeOutput {
  const GifComposeOutput({required this.path, required this.directoryPath});

  final String path;
  final String directoryPath;
}

class GifComposer {
  const GifComposer._();

  static Future<String> compose({
    required List<GifSourceFrame> frames,
    required String outputPath,
    required int loopCount,
    required GifPlaybackMode playbackMode,
  }) async {
    if (frames.length < 2) {
      throw const GifComposerException('至少需要 2 张图片。');
    }

    final orderedFrames = expandGifFrameSequence(frames, playbackMode);
    final decodedFrames = <({image_lib.Image image, int delayMs})>[];
    for (final sourceFrame in orderedFrames) {
      final inline = sourceFrame.inlineBytes;
      final bytes = inline ?? await File(sourceFrame.path).readAsBytes();
      final frame = image_lib.decodeImage(bytes);
      if (frame == null) {
        final label = sourceFrame.label ?? _fileNameFromPath(sourceFrame.path);
        throw GifComposerException('无法解析图片：$label');
      }
      decodedFrames.add((image: frame, delayMs: sourceFrame.delayMs));
    }

    final baseWidth = decodedFrames.first.image.width;
    final baseHeight = decodedFrames.first.image.height;
    final encoder = image_lib.GifEncoder(
      delay: (decodedFrames.first.delayMs / 10).round().clamp(1, 65535),
      repeat: loopCount,
    );

    for (final frame in decodedFrames) {
      final normalizedFrame =
          frame.image.width == baseWidth && frame.image.height == baseHeight
          ? frame.image
          : image_lib.copyResize(
              frame.image,
              width: baseWidth,
              height: baseHeight,
              maintainAspect: true,
            );
      encoder.addFrame(
        normalizedFrame,
        duration: (frame.delayMs / 10).round().clamp(1, 65535),
      );
    }

    final bytes = encoder.finish();
    if (bytes == null || bytes.isEmpty) {
      throw const GifComposerException('GIF 编码没有输出内容。');
    }

    await File(outputPath).writeAsBytes(bytes, flush: true);
    return outputPath;
  }

  static Future<GifComposeOutput> composeToStore({
    required AppLocalStore store,
    required List<GifSourceFrame> frames,
    required int loopCount,
    required GifPlaybackMode playbackMode,
  }) async {
    final outputFile = await store.createGeneratedGifFile();
    final outputPath = await compose(
      frames: frames,
      outputPath: outputFile.path,
      loopCount: loopCount,
      playbackMode: playbackMode,
    );

    return GifComposeOutput(
      path: outputPath,
      directoryPath: outputFile.parent.path,
    );
  }
}

String _fileNameFromPath(String path) {
  final parts = path.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty);
  return parts.isEmpty ? path : parts.last;
}
