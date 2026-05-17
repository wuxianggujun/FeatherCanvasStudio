import 'sprite_sheet_grid_spec.dart';

enum AnimationTrackKind { action, direction, layer }

enum AnimationPlaybackMode { normal, reverse, pingPong }

enum FrameAssetSource {
  generatedImage,
  spriteSheetSlice,
  pixelArt,
  editedFrame,
  importedFile,
}

class AnimationProject {
  const AnimationProject({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.tracks,
    required this.assets,
    required this.timeline,
    required this.exportSettings,
    this.sourceImagePath,
    this.sourceGridSpec,
  });

  factory AnimationProject.empty({
    required String title,
    int canvasWidth = 512,
    int canvasHeight = 512,
    int defaultDelayMs = 120,
  }) {
    final now = DateTime.now();
    final id = newId();
    return AnimationProject(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      tracks: [
        AnimationTrack(
          id: AnimationTrack.newId(),
          name: '轨道 1',
          kind: AnimationTrackKind.action,
          visible: true,
          locked: false,
          defaultDelayMs: defaultDelayMs,
          playbackMode: AnimationPlaybackMode.normal,
          clips: [
            TimelineClip(
              id: TimelineClip.newId(),
              name: '片段 1',
              startFrame: 0,
              frames: const [],
              loop: true,
            ),
          ],
        ),
      ],
      assets: const [],
      timeline: TimelineSettings(defaultFrameDelayMs: defaultDelayMs),
      exportSettings: const ExportSettings(),
    );
  }

  factory AnimationProject.fromJson(Map<String, dynamic> json) {
    return AnimationProject(
      id: json['id'] as String? ?? newId(),
      title: json['title'] as String? ?? '动画工程',
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
      canvasWidth: _readInt(json, 'canvasWidth', defaultValue: 512),
      canvasHeight: _readInt(json, 'canvasHeight', defaultValue: 512),
      tracks: _readList(
        json['tracks'],
        (value) => AnimationTrack.fromJson(value),
      ),
      assets: _readList(json['assets'], (value) => FrameAsset.fromJson(value)),
      timeline: json['timeline'] is Map
          ? TimelineSettings.fromJson(
              Map<String, dynamic>.from(json['timeline'] as Map),
            )
          : const TimelineSettings(),
      exportSettings: json['exportSettings'] is Map
          ? ExportSettings.fromJson(
              Map<String, dynamic>.from(json['exportSettings'] as Map),
            )
          : const ExportSettings(),
      sourceImagePath: json['sourceImagePath'] as String?,
      sourceGridSpec: json['sourceGridSpec'] is Map
          ? SpriteSheetGridSpec.fromJson(
              Map<String, dynamic>.from(json['sourceGridSpec'] as Map),
            )
          : null,
    );
  }

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int canvasWidth;
  final int canvasHeight;
  final List<AnimationTrack> tracks;
  final List<FrameAsset> assets;
  final TimelineSettings timeline;
  final ExportSettings exportSettings;
  final String? sourceImagePath;
  final SpriteSheetGridSpec? sourceGridSpec;

  static String newId() => 'animation_${DateTime.now().microsecondsSinceEpoch}';

  int get totalFrameRefs =>
      tracks.fold(0, (total, track) => total + track.totalFrameRefs);

  int get maxTrackFrameCount {
    var maxCount = 0;
    for (final track in tracks) {
      if (track.totalFrameRefs > maxCount) {
        maxCount = track.totalFrameRefs;
      }
    }
    return maxCount;
  }

  FrameAsset? assetById(String id) {
    for (final asset in assets) {
      if (asset.id == id) {
        return asset;
      }
    }
    return null;
  }

  AnimationTrack? trackById(String id) {
    for (final track in tracks) {
      if (track.id == id) {
        return track;
      }
    }
    return null;
  }

  AnimationProject copyWith({
    String? title,
    DateTime? updatedAt,
    int? canvasWidth,
    int? canvasHeight,
    List<AnimationTrack>? tracks,
    List<FrameAsset>? assets,
    TimelineSettings? timeline,
    ExportSettings? exportSettings,
    String? sourceImagePath,
    SpriteSheetGridSpec? sourceGridSpec,
  }) {
    return AnimationProject(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      tracks: tracks ?? this.tracks,
      assets: assets ?? this.assets,
      timeline: timeline ?? this.timeline,
      exportSettings: exportSettings ?? this.exportSettings,
      sourceImagePath: sourceImagePath ?? this.sourceImagePath,
      sourceGridSpec: sourceGridSpec ?? this.sourceGridSpec,
    );
  }

  AnimationProject touch() => copyWith(updatedAt: DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': 1,
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'tracks': tracks.map((track) => track.toJson()).toList(),
      'assets': assets.map((asset) => asset.toJson()).toList(),
      'timeline': timeline.toJson(),
      'exportSettings': exportSettings.toJson(),
      if (sourceImagePath != null) 'sourceImagePath': sourceImagePath,
      if (sourceGridSpec != null) 'sourceGridSpec': sourceGridSpec!.toJson(),
    };
  }
}

class AnimationTrack {
  const AnimationTrack({
    required this.id,
    required this.name,
    required this.kind,
    required this.visible,
    required this.locked,
    required this.defaultDelayMs,
    required this.playbackMode,
    required this.clips,
  });

  factory AnimationTrack.fromJson(Map<String, dynamic> json) {
    return AnimationTrack(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? '轨道',
      kind: _enumByName(
        AnimationTrackKind.values,
        json['kind'],
        AnimationTrackKind.action,
      ),
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      defaultDelayMs: _readInt(json, 'defaultDelayMs', defaultValue: 120),
      playbackMode: _enumByName(
        AnimationPlaybackMode.values,
        json['playbackMode'],
        AnimationPlaybackMode.normal,
      ),
      clips: _readList(json['clips'], (value) => TimelineClip.fromJson(value)),
    );
  }

  final String id;
  final String name;
  final AnimationTrackKind kind;
  final bool visible;
  final bool locked;
  final int defaultDelayMs;
  final AnimationPlaybackMode playbackMode;
  final List<TimelineClip> clips;

  static String newId() => 'track_${DateTime.now().microsecondsSinceEpoch}';

  int get totalFrameRefs =>
      clips.fold(0, (total, clip) => total + clip.frames.length);

  List<FrameRef> get orderedFrames => [
    for (final clip in clips) ...clip.frames,
  ];

  AnimationTrack copyWith({
    String? name,
    AnimationTrackKind? kind,
    bool? visible,
    bool? locked,
    int? defaultDelayMs,
    AnimationPlaybackMode? playbackMode,
    List<TimelineClip>? clips,
  }) {
    return AnimationTrack(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      defaultDelayMs: defaultDelayMs ?? this.defaultDelayMs,
      playbackMode: playbackMode ?? this.playbackMode,
      clips: clips ?? this.clips,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kind': kind.name,
      'visible': visible,
      'locked': locked,
      'defaultDelayMs': defaultDelayMs,
      'playbackMode': playbackMode.name,
      'clips': clips.map((clip) => clip.toJson()).toList(),
    };
  }
}

class TimelineClip {
  const TimelineClip({
    required this.id,
    required this.name,
    required this.startFrame,
    required this.frames,
    required this.loop,
    this.overrideDelayMs,
  });

  factory TimelineClip.fromJson(Map<String, dynamic> json) {
    return TimelineClip(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? '片段',
      startFrame: _readInt(json, 'startFrame', defaultValue: 0),
      frames: _readList(json['frames'], (value) => FrameRef.fromJson(value)),
      loop: json['loop'] as bool? ?? true,
      overrideDelayMs: (json['overrideDelayMs'] as num?)?.toInt(),
    );
  }

  final String id;
  final String name;
  final int startFrame;
  final List<FrameRef> frames;
  final bool loop;
  final int? overrideDelayMs;

  static String newId() => 'clip_${DateTime.now().microsecondsSinceEpoch}';

  TimelineClip copyWith({
    String? name,
    int? startFrame,
    List<FrameRef>? frames,
    bool? loop,
    int? overrideDelayMs,
  }) {
    return TimelineClip(
      id: id,
      name: name ?? this.name,
      startFrame: startFrame ?? this.startFrame,
      frames: frames ?? this.frames,
      loop: loop ?? this.loop,
      overrideDelayMs: overrideDelayMs ?? this.overrideDelayMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startFrame': startFrame,
      'frames': frames.map((frame) => frame.toJson()).toList(),
      'loop': loop,
      if (overrideDelayMs != null) 'overrideDelayMs': overrideDelayMs,
    };
  }
}

class FrameAsset {
  const FrameAsset({
    required this.id,
    required this.path,
    required this.width,
    required this.height,
    required this.source,
    this.sourceLibraryItemId,
    this.sourceFrameIndex,
  });

  factory FrameAsset.fromJson(Map<String, dynamic> json) {
    return FrameAsset(
      id: json['id'] as String? ?? newId(),
      path: json['path'] as String? ?? '',
      width: _readInt(json, 'width', defaultValue: 0),
      height: _readInt(json, 'height', defaultValue: 0),
      source: _enumByName(
        FrameAssetSource.values,
        json['source'],
        FrameAssetSource.importedFile,
      ),
      sourceLibraryItemId: json['sourceLibraryItemId'] as String?,
      sourceFrameIndex: (json['sourceFrameIndex'] as num?)?.toInt(),
    );
  }

  final String id;
  final String path;
  final int width;
  final int height;
  final FrameAssetSource source;
  final String? sourceLibraryItemId;
  final int? sourceFrameIndex;

  static String newId() => 'asset_${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'width': width,
      'height': height,
      'source': source.name,
      if (sourceLibraryItemId != null)
        'sourceLibraryItemId': sourceLibraryItemId,
      if (sourceFrameIndex != null) 'sourceFrameIndex': sourceFrameIndex,
    };
  }
}

class FrameRef {
  const FrameRef({
    required this.assetId,
    required this.delayMs,
    this.transform = const FrameTransform(),
  });

  factory FrameRef.fromJson(Map<String, dynamic> json) {
    return FrameRef(
      assetId: json['assetId'] as String? ?? '',
      delayMs: _readInt(json, 'delayMs', defaultValue: 120),
      transform: json['transform'] is Map
          ? FrameTransform.fromJson(
              Map<String, dynamic>.from(json['transform'] as Map),
            )
          : const FrameTransform(),
    );
  }

  final String assetId;
  final int delayMs;
  final FrameTransform transform;

  FrameRef copyWith({
    String? assetId,
    int? delayMs,
    FrameTransform? transform,
  }) {
    return FrameRef(
      assetId: assetId ?? this.assetId,
      delayMs: delayMs ?? this.delayMs,
      transform: transform ?? this.transform,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'delayMs': delayMs,
      'transform': transform.toJson(),
    };
  }
}

class FrameTransform {
  const FrameTransform({
    this.offsetX = 0,
    this.offsetY = 0,
    this.opacity = 1,
    this.flipX = false,
    this.flipY = false,
  });

  factory FrameTransform.fromJson(Map<String, dynamic> json) {
    return FrameTransform(
      offsetX: _readDouble(json, 'offsetX', defaultValue: 0),
      offsetY: _readDouble(json, 'offsetY', defaultValue: 0),
      opacity: _readDouble(json, 'opacity', defaultValue: 1),
      flipX: json['flipX'] as bool? ?? false,
      flipY: json['flipY'] as bool? ?? false,
    );
  }

  final double offsetX;
  final double offsetY;
  final double opacity;
  final bool flipX;
  final bool flipY;

  bool get isIdentity =>
      offsetX == 0 && offsetY == 0 && opacity == 1 && !flipX && !flipY;

  FrameTransform copyWith({
    double? offsetX,
    double? offsetY,
    double? opacity,
    bool? flipX,
    bool? flipY,
  }) {
    return FrameTransform(
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      opacity: opacity ?? this.opacity,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offsetX': offsetX,
      'offsetY': offsetY,
      'opacity': opacity,
      'flipX': flipX,
      'flipY': flipY,
    };
  }
}

class TimelineSettings {
  const TimelineSettings({
    this.defaultFrameDelayMs = 120,
    this.playbackMode = AnimationPlaybackMode.normal,
  });

  factory TimelineSettings.fromJson(Map<String, dynamic> json) {
    return TimelineSettings(
      defaultFrameDelayMs: _readInt(
        json,
        'defaultFrameDelayMs',
        defaultValue: 120,
      ),
      playbackMode: _enumByName(
        AnimationPlaybackMode.values,
        json['playbackMode'],
        AnimationPlaybackMode.normal,
      ),
    );
  }

  final int defaultFrameDelayMs;
  final AnimationPlaybackMode playbackMode;

  TimelineSettings copyWith({
    int? defaultFrameDelayMs,
    AnimationPlaybackMode? playbackMode,
  }) {
    return TimelineSettings(
      defaultFrameDelayMs: defaultFrameDelayMs ?? this.defaultFrameDelayMs,
      playbackMode: playbackMode ?? this.playbackMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultFrameDelayMs': defaultFrameDelayMs,
      'playbackMode': playbackMode.name,
    };
  }
}

class ExportSettings {
  const ExportSettings({this.loopCount = 0, this.includeHiddenTracks = false});

  factory ExportSettings.fromJson(Map<String, dynamic> json) {
    return ExportSettings(
      loopCount: _readInt(json, 'loopCount', defaultValue: 0),
      includeHiddenTracks: json['includeHiddenTracks'] as bool? ?? false,
    );
  }

  final int loopCount;
  final bool includeHiddenTracks;

  ExportSettings copyWith({int? loopCount, bool? includeHiddenTracks}) {
    return ExportSettings(
      loopCount: loopCount ?? this.loopCount,
      includeHiddenTracks: includeHiddenTracks ?? this.includeHiddenTracks,
    );
  }

  Map<String, dynamic> toJson() {
    return {'loopCount': loopCount, 'includeHiddenTracks': includeHiddenTracks};
  }
}

class AnimationProjectSummary {
  const AnimationProjectSummary({
    required this.id,
    required this.title,
    required this.trackCount,
    required this.frameCount,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  factory AnimationProjectSummary.fromProject(AnimationProject project) {
    return AnimationProjectSummary(
      id: project.id,
      title: project.title,
      trackCount: project.tracks.length,
      frameCount: project.totalFrameRefs,
      canvasWidth: project.canvasWidth,
      canvasHeight: project.canvasHeight,
    );
  }

  factory AnimationProjectSummary.fromJson(Map<String, dynamic> json) {
    return AnimationProjectSummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '动画工程',
      trackCount: _readInt(json, 'trackCount', defaultValue: 0),
      frameCount: _readInt(json, 'frameCount', defaultValue: 0),
      canvasWidth: _readInt(json, 'canvasWidth', defaultValue: 0),
      canvasHeight: _readInt(json, 'canvasHeight', defaultValue: 0),
    );
  }

  final String id;
  final String title;
  final int trackCount;
  final int frameCount;
  final int canvasWidth;
  final int canvasHeight;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'trackCount': trackCount,
      'frameCount': frameCount,
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
    };
  }
}

List<T> _readList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) parse,
) {
  if (value is! List) {
    return const [];
  }
  return List<T>.unmodifiable(
    value.whereType<Map>().map(
      (entry) => parse(Map<String, dynamic>.from(entry)),
    ),
  );
}

T _enumByName<T extends Enum>(List<T> values, Object? value, T fallback) {
  if (value is String) {
    for (final item in values) {
      if (item.name == value) {
        return item;
      }
    }
  }
  return fallback;
}

DateTime _readDate(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

int _readInt(
  Map<String, dynamic> json,
  String key, {
  required int defaultValue,
}) {
  final value = json[key];
  if (value == null) {
    return defaultValue;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return defaultValue;
}

double _readDouble(
  Map<String, dynamic> json,
  String key, {
  required double defaultValue,
}) {
  final value = json[key];
  if (value is num) {
    return value.toDouble();
  }
  return defaultValue;
}
