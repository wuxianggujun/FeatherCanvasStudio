import 'dart:io';

import 'package:flutter/foundation.dart';
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

  String get displayLabel => label ?? _fileNameFromPath(path);

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

    final request = <String, Object?>{
      'frames': [
        for (final frame in expandGifFrameSequence(frames, playbackMode))
          <String, Object?>{
            'path': frame.path,
            'delayMs': frame.delayMs,
            'inlineBytes': frame.inlineBytes,
            'label': frame.label,
          },
      ],
      'outputPath': outputPath,
      'loopCount': loopCount,
    };
    return compute(_composeGifInIsolate, request);
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

Future<String> _composeGifInIsolate(Map<String, Object?> request) async {
  final rawFrames = request['frames'] as List<dynamic>;
  final outputPath = request['outputPath'] as String;
  final loopCount = request['loopCount'] as int;
  final decodedFrames = <({image_lib.Image image, int delayMs})>[];

  for (final rawFrame in rawFrames) {
    final frameMap = Map<String, Object?>.from(rawFrame as Map);
    final inlineBytes = frameMap['inlineBytes'] as Uint8List?;
    final path = frameMap['path'] as String;
    final bytes = inlineBytes ?? await File(path).readAsBytes();
    final frame = image_lib.decodeImage(bytes);
    if (frame == null) {
      final label = frameMap['label'] as String? ?? _fileNameFromPath(path);
      throw GifComposerException('无法解析图片：$label');
    }
    decodedFrames.add((image: frame, delayMs: frameMap['delayMs'] as int));
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
