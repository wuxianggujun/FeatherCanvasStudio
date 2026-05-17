import 'dart:io';

import 'animation_project.dart';
import 'app_config.dart';
import 'image_asset_kind.dart';
import 'sprite_sheet_grid_spec.dart';

class ImageLibraryItem {
  const ImageLibraryItem({
    required this.id,
    required this.path,
    required this.createdAt,
    required this.kind,
    required this.title,
    required this.source,
    this.note = '',
    this.tags = const <String>[],
    this.project = '',
    this.prompt,
    this.generation,
    this.groupId,
    this.rows,
    this.columns,
    this.gridSpec,
    this.frameWidth,
    this.frameHeight,
    this.frameIndex,
    this.animationProject,
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
        'animationProject' => ImageAssetKind.animationProject,
        'gif' => ImageAssetKind.gif,
        _ => ImageAssetKind.generatedImage,
      },
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? '',
      note: json['note'] as String? ?? '',
      tags: _tagsFromJson(json['tags']),
      project: (json['project'] as String? ?? '').trim(),
      prompt: json['prompt'] as String?,
      generation: _generationFromJson(json['generation']),
      groupId: json['groupId'] as String?,
      rows: (json['rows'] as num?)?.toInt(),
      columns: (json['columns'] as num?)?.toInt(),
      gridSpec: _gridSpecFromJson(json['gridSpec']),
      frameWidth: (json['frameWidth'] as num?)?.toInt(),
      frameHeight: (json['frameHeight'] as num?)?.toInt(),
      frameIndex: (json['frameIndex'] as num?)?.toInt(),
      animationProject: _animationProjectSummaryFromJson(
        json['animationProject'],
      ),
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

  static List<String> _tagsFromJson(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    final tags = <String>[];
    final seen = <String>{};
    for (final tag in value) {
      if (tag is! String) {
        continue;
      }
      final normalized = tag.trim();
      final key = normalized.toLowerCase();
      if (normalized.isNotEmpty && seen.add(key)) {
        tags.add(normalized);
      }
    }
    return List.unmodifiable(tags);
  }

  final String id;
  final String path;
  final DateTime createdAt;
  final ImageAssetKind kind;
  final String title;
  final String source;
  final String note;
  final List<String> tags;
  final String project;
  final String? prompt;
  final GenerationSnapshot? generation;
  final String? groupId;
  final int? rows;
  final int? columns;
  final SpriteSheetGridSpec? gridSpec;
  final int? frameWidth;
  final int? frameHeight;
  final int? frameIndex;
  final AnimationProjectSummary? animationProject;

  bool get existsSync => File(path).existsSync();
  bool get canUseAsSpriteSheet =>
      kind == ImageAssetKind.spriteSheet || kind == ImageAssetKind.editedImage;
  bool get canMakeBackgroundTransparent {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  bool get isSpriteSheetWithMetadata =>
      kind == ImageAssetKind.spriteSheet &&
      effectiveGridSpec.rows > 0 &&
      effectiveGridSpec.columns > 0;
  int get totalFrameCount =>
      isSpriteSheetWithMetadata ? effectiveGridSpec.totalFrameCount : 0;
  SpriteSheetGridSpec get effectiveGridSpec {
    final savedGridSpec = gridSpec;
    if (savedGridSpec != null) {
      return savedGridSpec;
    }
    return SpriteSheetGridSpec(rows: rows ?? 0, columns: columns ?? 0);
  }

  bool get isImageFile {
    if (kind == ImageAssetKind.animationProject) {
      return false;
    }
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
    List<String>? tags,
    String? project,
    int? rows,
    int? columns,
    SpriteSheetGridSpec? gridSpec,
    int? frameWidth,
    int? frameHeight,
    int? frameIndex,
    GenerationSnapshot? generation,
    AnimationProjectSummary? animationProject,
  }) {
    return ImageLibraryItem(
      id: id,
      path: path,
      createdAt: createdAt,
      kind: kind,
      title: title ?? this.title,
      source: source,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      project: project ?? this.project,
      prompt: prompt,
      generation: generation ?? this.generation,
      groupId: groupId,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      gridSpec: gridSpec ?? this.gridSpec,
      frameWidth: frameWidth ?? this.frameWidth,
      frameHeight: frameHeight ?? this.frameHeight,
      frameIndex: frameIndex ?? this.frameIndex,
      animationProject: animationProject ?? this.animationProject,
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
      'tags': tags,
      'project': project,
      'prompt': prompt,
      if (generation != null) 'generation': generation!.toJson(),
      'groupId': groupId,
      if (rows != null) 'rows': rows,
      if (columns != null) 'columns': columns,
      if (gridSpec != null) 'gridSpec': gridSpec!.toJson(),
      if (frameWidth != null) 'frameWidth': frameWidth,
      if (frameHeight != null) 'frameHeight': frameHeight,
      if (frameIndex != null) 'frameIndex': frameIndex,
      if (animationProject != null)
        'animationProject': animationProject!.toJson(),
    };
  }
}

SpriteSheetGridSpec? _gridSpecFromJson(Object? value) {
  if (value is! Map) {
    return null;
  }

  try {
    return SpriteSheetGridSpec.fromJson(Map<String, dynamic>.from(value));
  } catch (_) {
    return null;
  }
}

AnimationProjectSummary? _animationProjectSummaryFromJson(Object? value) {
  if (value is! Map) {
    return null;
  }

  try {
    return AnimationProjectSummary.fromJson(Map<String, dynamic>.from(value));
  } catch (_) {
    return null;
  }
}

String _fileNameFromPath(String path) {
  final parts = path.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty);
  return parts.isEmpty ? path : parts.last;
}
