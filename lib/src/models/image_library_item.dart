import 'dart:io';

import 'app_config.dart';
import 'image_asset_kind.dart';

class ImageLibraryItem {
  const ImageLibraryItem({
    required this.id,
    required this.path,
    required this.createdAt,
    required this.kind,
    required this.title,
    required this.source,
    this.note = '',
    this.prompt,
    this.generation,
    this.groupId,
    this.rows,
    this.columns,
    this.frameWidth,
    this.frameHeight,
    this.frameIndex,
  });

  factory ImageLibraryItem.fromJson(Map<String, dynamic> json) {
    return ImageLibraryItem(
      id: json['id'] as String? ?? newId(),
      path: json['path'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      kind: switch (json['kind']) {
        'spriteSheet' => ImageAssetKind.spriteSheet,
        'spriteFrame' => ImageAssetKind.spriteFrame,
        'editedImage' => ImageAssetKind.editedImage,
        'gif' => ImageAssetKind.gif,
        _ => ImageAssetKind.generatedImage,
      },
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? '',
      note: json['note'] as String? ?? '',
      prompt: json['prompt'] as String?,
      generation: _generationFromJson(json['generation']),
      groupId: json['groupId'] as String?,
      rows: (json['rows'] as num?)?.toInt(),
      columns: (json['columns'] as num?)?.toInt(),
      frameWidth: (json['frameWidth'] as num?)?.toInt(),
      frameHeight: (json['frameHeight'] as num?)?.toInt(),
      frameIndex: (json['frameIndex'] as num?)?.toInt(),
    );
  }

  static String newId({int seed = 0}) {
    return '${DateTime.now().microsecondsSinceEpoch}_$seed';
  }

  static GenerationSnapshot? _generationFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }

    return GenerationSnapshot.fromJson(Map<String, dynamic>.from(value));
  }

  final String id;
  final String path;
  final DateTime createdAt;
  final ImageAssetKind kind;
  final String title;
  final String source;
  final String note;
  final String? prompt;
  final GenerationSnapshot? generation;
  final String? groupId;
  final int? rows;
  final int? columns;
  final int? frameWidth;
  final int? frameHeight;
  final int? frameIndex;

  bool get existsSync => File(path).existsSync();
  bool get canUseAsSpriteSheet =>
      kind == ImageAssetKind.spriteSheet || kind == ImageAssetKind.editedImage;
  bool get isSpriteSheetWithMetadata =>
      kind == ImageAssetKind.spriteSheet &&
      rows != null &&
      columns != null &&
      rows! > 0 &&
      columns! > 0;
  int get totalFrameCount => isSpriteSheetWithMetadata ? rows! * columns! : 0;
  bool get isImageFile {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.gif');
  }

  String get displayTitle => title.isEmpty ? _fileNameFromPath(path) : title;

  ImageLibraryItem copyWith({
    String? title,
    String? note,
    int? rows,
    int? columns,
    int? frameWidth,
    int? frameHeight,
    int? frameIndex,
    GenerationSnapshot? generation,
  }) {
    return ImageLibraryItem(
      id: id,
      path: path,
      createdAt: createdAt,
      kind: kind,
      title: title ?? this.title,
      source: source,
      note: note ?? this.note,
      prompt: prompt,
      generation: generation ?? this.generation,
      groupId: groupId,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      frameWidth: frameWidth ?? this.frameWidth,
      frameHeight: frameHeight ?? this.frameHeight,
      frameIndex: frameIndex ?? this.frameIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'createdAt': createdAt.toIso8601String(),
      'kind': kind.name,
      'title': title,
      'source': source,
      'note': note,
      'prompt': prompt,
      if (generation != null) 'generation': generation!.toJson(),
      'groupId': groupId,
      if (rows != null) 'rows': rows,
      if (columns != null) 'columns': columns,
      if (frameWidth != null) 'frameWidth': frameWidth,
      if (frameHeight != null) 'frameHeight': frameHeight,
      if (frameIndex != null) 'frameIndex': frameIndex,
    };
  }
}

String _fileNameFromPath(String path) {
  final parts = path.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty);
  return parts.isEmpty ? path : parts.last;
}
