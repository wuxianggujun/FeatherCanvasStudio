import '../services/gif_composer_service.dart';

enum AppPresetKind { localGeneration, gif, spriteSheet }

class AppPreset {
  const AppPreset({
    required this.id,
    required this.name,
    required this.kind,
    this.prompt = '',
    this.negativePrompt = '',
    this.size = '1024x1024',
    this.imageCount = 1,
    this.rows = 4,
    this.columns = 4,
    this.gifDelayMs = 120,
    this.gifLoopCount = 0,
    this.playbackMode = GifPlaybackMode.normal,
  });

  factory AppPreset.fromJson(Map<String, dynamic> json) {
    return AppPreset(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? '',
      kind: parseAppPresetKind(json['kind']),
      prompt: json['prompt'] as String? ?? '',
      negativePrompt: json['negativePrompt'] as String? ?? '',
      size: json['size'] as String? ?? '1024x1024',
      imageCount: _readPositiveInt(json['imageCount'], fallback: 1),
      rows: _readPositiveInt(json['rows'], fallback: 4),
      columns: _readPositiveInt(json['columns'], fallback: 4),
      gifDelayMs: _readPositiveInt(json['gifDelayMs'], fallback: 120),
      gifLoopCount: _readNonNegativeInt(json['gifLoopCount'], fallback: 0),
      playbackMode: parseGifPlaybackMode(json['playbackMode']),
    );
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String name;
  final AppPresetKind kind;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final int rows;
  final int columns;
  final int gifDelayMs;
  final int gifLoopCount;
  final GifPlaybackMode playbackMode;

  AppPreset copyWith({
    String? id,
    String? name,
    AppPresetKind? kind,
    String? prompt,
    String? negativePrompt,
    String? size,
    int? imageCount,
    int? rows,
    int? columns,
    int? gifDelayMs,
    int? gifLoopCount,
    GifPlaybackMode? playbackMode,
  }) {
    return AppPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      prompt: prompt ?? this.prompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      size: size ?? this.size,
      imageCount: imageCount ?? this.imageCount,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      gifDelayMs: gifDelayMs ?? this.gifDelayMs,
      gifLoopCount: gifLoopCount ?? this.gifLoopCount,
      playbackMode: playbackMode ?? this.playbackMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kind': serializeAppPresetKind(kind),
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'size': size,
      'imageCount': imageCount,
      'rows': rows,
      'columns': columns,
      'gifDelayMs': gifDelayMs,
      'gifLoopCount': gifLoopCount,
      'playbackMode': serializeGifPlaybackMode(playbackMode),
    };
  }

  static int _readPositiveInt(Object? value, {required int fallback}) {
    final parsed = value is num ? value.toInt() : null;
    if (parsed == null || parsed <= 0) {
      return fallback;
    }
    return parsed;
  }

  static int _readNonNegativeInt(Object? value, {required int fallback}) {
    final parsed = value is num ? value.toInt() : null;
    if (parsed == null || parsed < 0) {
      return fallback;
    }
    return parsed;
  }
}

AppPresetKind parseAppPresetKind(
  Object? value, {
  AppPresetKind fallback = AppPresetKind.localGeneration,
}) {
  final raw = value is String ? value : null;
  return switch (raw) {
    'localGeneration' => AppPresetKind.localGeneration,
    'gif' => AppPresetKind.gif,
    'spriteSheet' => AppPresetKind.spriteSheet,
    _ => fallback,
  };
}

String serializeAppPresetKind(AppPresetKind kind) {
  return switch (kind) {
    AppPresetKind.localGeneration => 'localGeneration',
    AppPresetKind.gif => 'gif',
    AppPresetKind.spriteSheet => 'spriteSheet',
  };
}

GifPlaybackMode parseGifPlaybackMode(
  Object? value, {
  GifPlaybackMode fallback = GifPlaybackMode.normal,
}) {
  final raw = value is String ? value : null;
  return switch (raw) {
    'normal' => GifPlaybackMode.normal,
    'reverse' => GifPlaybackMode.reverse,
    'pingPong' => GifPlaybackMode.pingPong,
    _ => fallback,
  };
}

String serializeGifPlaybackMode(GifPlaybackMode mode) {
  return switch (mode) {
    GifPlaybackMode.normal => 'normal',
    GifPlaybackMode.reverse => 'reverse',
    GifPlaybackMode.pingPong => 'pingPong',
  };
}
