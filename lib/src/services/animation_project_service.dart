import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;

import '../models/animation_project.dart';
import '../models/exceptions.dart';
import '../models/sprite_sheet_grid_spec.dart';
import 'app_local_store.dart';
import 'gif_composer_service.dart';
import 'sprite_sheet_service.dart';

class AnimationProjectStore {
  const AnimationProjectStore();

  Future<Directory> ensureProjectsDirectory(AppLocalStore store) async {
    final generatedDirectory = await store.ensureGeneratedImagesDirectory();
    final directory = Directory(
      '${generatedDirectory.path}${Platform.pathSeparator}animation-projects',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> projectFile(AppLocalStore store, String projectId) async {
    final directory = await ensureProjectsDirectory(store);
    return File('${directory.path}${Platform.pathSeparator}$projectId.json');
  }

  Future<File> saveProject(
    AppLocalStore store,
    AnimationProject project,
  ) async {
    final file = await projectFile(store, project.id);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
      flush: true,
    );
    return file;
  }

  Future<AnimationProject> loadProject(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ImageGenerationException('动画工程文件不存在：$path');
    }

    final String raw;
    try {
      raw = await file.readAsString();
    } on FileSystemException catch (error) {
      throw ImageGenerationException('无法读取动画工程：$path（${error.message}）');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw ImageGenerationException('动画工程文件不是有效 JSON：$path');
    }
    if (decoded is! Map) {
      throw ImageGenerationException('动画工程文件格式无效：$path');
    }

    try {
      return AnimationProject.fromJson(Map<String, dynamic>.from(decoded));
    } catch (error) {
      throw ImageGenerationException('动画工程内容无效：$path（$error）');
    }
  }
}

class AnimationProjectImportResult {
  const AnimationProjectImportResult({
    required this.project,
    required this.projectFile,
    required this.previewSheetBytes,
  });

  final AnimationProject project;
  final File projectFile;
  final Uint8List previewSheetBytes;
}

class AnimationProjectEditResult {
  const AnimationProjectEditResult({
    required this.project,
    this.selectedTrackId,
  });

  final AnimationProject project;
  final String? selectedTrackId;
}

class AnimationProjectAssetIssue {
  const AnimationProjectAssetIssue({
    required this.asset,
    required this.referenceCount,
    required this.message,
  });

  final FrameAsset asset;
  final int referenceCount;
  final String message;

  bool get affectsTimeline => referenceCount > 0;
}

class AnimationProjectAssetDiagnostics {
  const AnimationProjectAssetDiagnostics({
    required this.totalAssetCount,
    required this.referencedAssetCount,
    required this.missingAssets,
    required this.unusedAssets,
    required this.invalidFrameReferenceCount,
  });

  final int totalAssetCount;
  final int referencedAssetCount;
  final List<AnimationProjectAssetIssue> missingAssets;
  final List<FrameAsset> unusedAssets;
  final int invalidFrameReferenceCount;

  int get missingReferencedAssetCount =>
      missingAssets.where((issue) => issue.affectsTimeline).length;

  int get unusedAssetCount => unusedAssets.length;

  bool get hasMissingAssets => missingAssets.isNotEmpty;

  bool get hasUnusedAssets => unusedAssets.isNotEmpty;

  bool get hasInvalidFrameReferences => invalidFrameReferenceCount > 0;

  int get autoRepairableIssueCount =>
      unusedAssetCount + invalidFrameReferenceCount;

  bool get hasAutoRepairableIssues => autoRepairableIssueCount > 0;

  bool get hasIssues =>
      hasMissingAssets || hasUnusedAssets || hasInvalidFrameReferences;
}

class AnimationProjectAssetInspector {
  const AnimationProjectAssetInspector();

  Future<AnimationProjectAssetDiagnostics> inspect(
    AnimationProject project,
  ) async {
    final referenceCounts = <String, int>{};
    var invalidFrameReferenceCount = 0;
    for (final track in project.tracks) {
      for (final frame in track.orderedFrames) {
        if (frame.assetId.isEmpty) {
          invalidFrameReferenceCount += 1;
          continue;
        }
        referenceCounts.update(
          frame.assetId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final missingAssets = <AnimationProjectAssetIssue>[];
    final unusedAssets = <FrameAsset>[];
    final knownAssetIds = <String>{};
    for (final asset in project.assets) {
      knownAssetIds.add(asset.id);
      final referenceCount = referenceCounts[asset.id] ?? 0;
      if (referenceCount == 0) {
        unusedAssets.add(asset);
      }
      final path = asset.path.trim();
      if (path.isEmpty) {
        missingAssets.add(
          AnimationProjectAssetIssue(
            asset: asset,
            referenceCount: referenceCount,
            message: '资源没有记录文件路径',
          ),
        );
        continue;
      }
      if (!await File(path).exists()) {
        missingAssets.add(
          AnimationProjectAssetIssue(
            asset: asset,
            referenceCount: referenceCount,
            message: '资源文件不存在',
          ),
        );
      }
    }
    for (final entry in referenceCounts.entries) {
      if (knownAssetIds.contains(entry.key)) {
        continue;
      }
      missingAssets.add(
        AnimationProjectAssetIssue(
          asset: FrameAsset(
            id: entry.key,
            path: '',
            width: project.canvasWidth,
            height: project.canvasHeight,
            source: FrameAssetSource.importedFile,
          ),
          referenceCount: entry.value,
          message: '时间轴引用的资源记录不存在',
        ),
      );
    }

    return AnimationProjectAssetDiagnostics(
      totalAssetCount: project.assets.length,
      referencedAssetCount: referenceCounts.length,
      missingAssets: List<AnimationProjectAssetIssue>.unmodifiable(
        missingAssets,
      ),
      unusedAssets: List<FrameAsset>.unmodifiable(unusedAssets),
      invalidFrameReferenceCount: invalidFrameReferenceCount,
    );
  }
}

class AnimationProjectEditor {
  const AnimationProjectEditor();

  AnimationProjectEditResult addTrack({
    required AnimationProject project,
    required int defaultDelayMs,
  }) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final track = AnimationTrack(
      id: '${project.id}_track_$timestamp',
      name: '轨道 ${project.tracks.length + 1}',
      kind: AnimationTrackKind.action,
      visible: true,
      locked: false,
      defaultDelayMs: defaultDelayMs,
      playbackMode: AnimationPlaybackMode.normal,
      clips: [
        TimelineClip(
          id: '${project.id}_clip_$timestamp',
          name: '序列 ${project.tracks.length + 1}',
          startFrame: 0,
          frames: const [],
          loop: true,
        ),
      ],
    );
    return AnimationProjectEditResult(
      project: project.copyWith(tracks: [...project.tracks, track]).touch(),
      selectedTrackId: track.id,
    );
  }

  AnimationProjectEditResult setProjectDefaultDelay({
    required AnimationProject project,
    required int delayMs,
  }) {
    return AnimationProjectEditResult(
      project: project
          .copyWith(
            timeline: project.timeline.copyWith(defaultFrameDelayMs: delayMs),
          )
          .touch(),
    );
  }

  AnimationProjectEditResult setProjectPlaybackMode({
    required AnimationProject project,
    required AnimationPlaybackMode mode,
  }) {
    return AnimationProjectEditResult(
      project: project
          .copyWith(timeline: project.timeline.copyWith(playbackMode: mode))
          .touch(),
    );
  }

  AnimationProjectEditResult setProjectLoopCount({
    required AnimationProject project,
    required int loopCount,
  }) {
    return AnimationProjectEditResult(
      project: project
          .copyWith(
            exportSettings: project.exportSettings.copyWith(
              loopCount: loopCount,
            ),
          )
          .touch(),
    );
  }

  AnimationProjectEditResult setProjectIncludeHiddenTracks({
    required AnimationProject project,
    required bool includeHiddenTracks,
  }) {
    return AnimationProjectEditResult(
      project: project
          .copyWith(
            exportSettings: project.exportSettings.copyWith(
              includeHiddenTracks: includeHiddenTracks,
            ),
          )
          .touch(),
    );
  }

  AnimationProjectEditResult? duplicateTrack({
    required AnimationProject project,
    required String trackId,
  }) {
    final source = project.trackById(trackId);
    if (source == null) {
      return null;
    }
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final duplicate = AnimationTrack(
      id: '${project.id}_track_copy_$timestamp',
      name: '${source.name} 副本',
      kind: source.kind,
      visible: source.visible,
      locked: false,
      defaultDelayMs: source.defaultDelayMs,
      playbackMode: source.playbackMode,
      clips: [
        for (var index = 0; index < source.clips.length; index++)
          TimelineClip(
            id: '${project.id}_clip_copy_${timestamp}_$index',
            name: source.clips[index].name,
            startFrame: source.clips[index].startFrame,
            frames: List<FrameRef>.from(source.clips[index].frames),
            loop: source.clips[index].loop,
            overrideDelayMs: source.clips[index].overrideDelayMs,
          ),
      ],
    );
    final sourceIndex = project.tracks.indexWhere(
      (track) => track.id == trackId,
    );
    final tracks = [...project.tracks]..insert(sourceIndex + 1, duplicate);
    return AnimationProjectEditResult(
      project: project.copyWith(tracks: tracks).touch(),
      selectedTrackId: duplicate.id,
    );
  }

  AnimationProjectEditResult? deleteTrack({
    required AnimationProject project,
    required String trackId,
  }) {
    if (project.tracks.length <= 1) {
      return null;
    }
    final index = project.tracks.indexWhere((track) => track.id == trackId);
    if (index < 0) {
      return null;
    }
    final tracks = [
      for (final track in project.tracks)
        if (track.id != trackId) track,
    ];
    final nextSelectedIndex = index.clamp(0, tracks.length - 1).toInt();
    return AnimationProjectEditResult(
      project: project.copyWith(tracks: tracks).touch(),
      selectedTrackId: tracks[nextSelectedIndex].id,
    );
  }

  AnimationProjectEditResult? moveTrack({
    required AnimationProject project,
    required String trackId,
    required int delta,
  }) {
    if (delta == 0) {
      return null;
    }
    final index = project.tracks.indexWhere((track) => track.id == trackId);
    if (index < 0) {
      return null;
    }
    final targetIndex = (index + delta).clamp(0, project.tracks.length - 1);
    if (targetIndex == index) {
      return null;
    }
    final tracks = [...project.tracks];
    final track = tracks.removeAt(index);
    tracks.insert(targetIndex.toInt(), track);
    return AnimationProjectEditResult(
      project: project.copyWith(tracks: tracks).touch(),
    );
  }

  AnimationProjectEditResult? setTrackVisible({
    required AnimationProject project,
    required String trackId,
    required bool visible,
  }) {
    return _updateTrack(
      project: project,
      trackId: trackId,
      update: (track) => track.copyWith(visible: visible),
    );
  }

  AnimationProjectEditResult? setTrackLocked({
    required AnimationProject project,
    required String trackId,
    required bool locked,
  }) {
    return _updateTrack(
      project: project,
      trackId: trackId,
      update: (track) => track.copyWith(locked: locked),
    );
  }

  AnimationProjectEditResult? setTrackDelay({
    required AnimationProject project,
    required String trackId,
    required int delayMs,
  }) {
    return _updateTrack(
      project: project,
      trackId: trackId,
      update: (track) => track.copyWith(
        defaultDelayMs: delayMs,
        clips: [
          for (final clip in track.clips)
            clip.copyWith(
              frames: [
                for (final frame in clip.frames)
                  frame.copyWith(delayMs: delayMs),
              ],
            ),
        ],
      ),
    );
  }

  AnimationProjectEditResult? setTrackPlaybackMode({
    required AnimationProject project,
    required String trackId,
    required AnimationPlaybackMode mode,
  }) {
    return _updateTrack(
      project: project,
      trackId: trackId,
      update: (track) => track.copyWith(playbackMode: mode),
    );
  }

  AnimationProjectEditResult? moveFrame({
    required AnimationProject project,
    required String trackId,
    required int fromIndex,
    required int toIndex,
  }) {
    final track = project.trackById(trackId);
    if (track == null || track.locked) {
      return null;
    }
    final frames = [...track.orderedFrames];
    if (fromIndex < 0 ||
        fromIndex >= frames.length ||
        toIndex < 0 ||
        toIndex >= frames.length ||
        fromIndex == toIndex) {
      return null;
    }
    final frame = frames.removeAt(fromIndex);
    frames.insert(toIndex, frame);
    return _replaceTrackFrames(project: project, track: track, frames: frames);
  }

  AnimationProjectEditResult? duplicateFrame({
    required AnimationProject project,
    required String trackId,
    required int frameIndex,
  }) {
    final track = project.trackById(trackId);
    if (track == null || track.locked) {
      return null;
    }
    final frames = [...track.orderedFrames];
    if (frameIndex < 0 || frameIndex >= frames.length) {
      return null;
    }
    frames.insert(frameIndex + 1, frames[frameIndex]);
    return _replaceTrackFrames(project: project, track: track, frames: frames);
  }

  AnimationProjectEditResult? deleteFrame({
    required AnimationProject project,
    required String trackId,
    required int frameIndex,
  }) {
    final track = project.trackById(trackId);
    if (track == null || track.locked) {
      return null;
    }
    final frames = [...track.orderedFrames];
    if (frames.length <= 1 || frameIndex < 0 || frameIndex >= frames.length) {
      return null;
    }
    frames.removeAt(frameIndex);
    return _replaceTrackFrames(project: project, track: track, frames: frames);
  }

  AnimationProjectEditResult? setFrameDelay({
    required AnimationProject project,
    required String trackId,
    required int frameIndex,
    required int delayMs,
  }) {
    final track = project.trackById(trackId);
    if (track == null || track.locked) {
      return null;
    }
    final frames = [...track.orderedFrames];
    if (frameIndex < 0 || frameIndex >= frames.length) {
      return null;
    }
    frames[frameIndex] = frames[frameIndex].copyWith(delayMs: delayMs);
    return _replaceTrackFrames(project: project, track: track, frames: frames);
  }

  AnimationProjectEditResult? setFrameTransform({
    required AnimationProject project,
    required String trackId,
    required int frameIndex,
    required FrameTransform transform,
  }) {
    final track = project.trackById(trackId);
    if (track == null || track.locked) {
      return null;
    }
    final frames = [...track.orderedFrames];
    if (frameIndex < 0 || frameIndex >= frames.length) {
      return null;
    }
    frames[frameIndex] = frames[frameIndex].copyWith(transform: transform);
    return _replaceTrackFrames(project: project, track: track, frames: frames);
  }

  AnimationProjectEditResult? removeUnusedAssets({
    required AnimationProject project,
  }) {
    final referencedAssetIds = <String>{};
    for (final track in project.tracks) {
      for (final frame in track.orderedFrames) {
        if (frame.assetId.isNotEmpty) {
          referencedAssetIds.add(frame.assetId);
        }
      }
    }
    final assets = [
      for (final asset in project.assets)
        if (referencedAssetIds.contains(asset.id)) asset,
    ];
    if (assets.length == project.assets.length) {
      return null;
    }
    return AnimationProjectEditResult(
      project: project
          .copyWith(assets: List<FrameAsset>.unmodifiable(assets))
          .touch(),
    );
  }

  AnimationProjectEditResult? repairConsistency({
    required AnimationProject project,
  }) {
    var changed = false;
    final tracks = <AnimationTrack>[];
    final referencedAssetIds = <String>{};

    for (final track in project.tracks) {
      final clips = <TimelineClip>[];
      for (final clip in track.clips) {
        final frames = [
          for (final frame in clip.frames)
            if (frame.assetId.isNotEmpty) frame,
        ];
        if (frames.length != clip.frames.length) {
          changed = true;
        }
        for (final frame in frames) {
          referencedAssetIds.add(frame.assetId);
        }
        clips.add(clip.copyWith(frames: List<FrameRef>.unmodifiable(frames)));
      }
      tracks.add(track.copyWith(clips: List<TimelineClip>.unmodifiable(clips)));
    }

    final assets = [
      for (final asset in project.assets)
        if (referencedAssetIds.contains(asset.id)) asset,
    ];
    if (assets.length != project.assets.length) {
      changed = true;
    }
    if (!changed) {
      return null;
    }
    return AnimationProjectEditResult(
      project: project
          .copyWith(
            tracks: List<AnimationTrack>.unmodifiable(tracks),
            assets: List<FrameAsset>.unmodifiable(assets),
          )
          .touch(),
    );
  }

  AnimationProjectEditResult? _updateTrack({
    required AnimationProject project,
    required String trackId,
    required AnimationTrack Function(AnimationTrack track) update,
  }) {
    if (project.trackById(trackId) == null) {
      return null;
    }
    return AnimationProjectEditResult(
      project: project
          .copyWith(
            tracks: [
              for (final track in project.tracks)
                track.id == trackId ? update(track) : track,
            ],
          )
          .touch(),
    );
  }

  AnimationProjectEditResult _replaceTrackFrames({
    required AnimationProject project,
    required AnimationTrack track,
    required List<FrameRef> frames,
  }) {
    final replacement = _trackWithSingleClip(track, frames);
    return AnimationProjectEditResult(
      project: project
          .copyWith(
            tracks: [
              for (final current in project.tracks)
                current.id == track.id ? replacement : current,
            ],
          )
          .touch(),
    );
  }

  AnimationTrack _trackWithSingleClip(
    AnimationTrack track,
    List<FrameRef> frames,
  ) {
    final clips = track.clips;
    final baseClip = clips.isEmpty
        ? TimelineClip(
            id: TimelineClip.newId(),
            name: '序列',
            startFrame: 0,
            frames: const [],
            loop: true,
          )
        : clips.first;
    return track.copyWith(
      clips: [baseClip.copyWith(frames: List<FrameRef>.unmodifiable(frames))],
    );
  }
}

class AnimationProjectImporter {
  const AnimationProjectImporter();

  Future<AnimationProjectImportResult> importSpriteSheet({
    required AppLocalStore store,
    required Uint8List sheetBytes,
    required String title,
    required int rows,
    required int columns,
    required int defaultDelayMs,
    SpriteSheetGridSpec? gridSpec,
    String? sourceImagePath,
    String? sourceLibraryItemId,
  }) async {
    final spec = gridSpec ?? SpriteSheetGridSpec(rows: rows, columns: columns);
    final previewData = SpriteSheetPreviewComposer.buildFromSheetBytes(
      sheetBytes,
      rows: rows,
      columns: columns,
      gridSpec: spec,
    );
    final now = DateTime.now();
    final projectId = AnimationProject.newId();
    final assets = <FrameAsset>[];

    for (var index = 0; index < previewData.frames.length; index++) {
      final bytes = previewData.frames[index];
      final decoded = image_lib.decodeImage(bytes);
      if (decoded == null) {
        throw ImageGenerationException('第 ${index + 1} 帧无法解码。');
      }
      final file = await store.saveGeneratedImageBytes(
        groupId: projectId,
        index: index,
        bytes: bytes,
      );
      assets.add(
        FrameAsset(
          id: '${projectId}_asset_$index',
          path: file.path,
          width: decoded.width,
          height: decoded.height,
          source: FrameAssetSource.spriteSheetSlice,
          sourceLibraryItemId: sourceLibraryItemId,
          sourceFrameIndex: index,
        ),
      );
    }

    final tracks = <AnimationTrack>[];
    for (var row = 0; row < rows; row++) {
      final frameRefs = <FrameRef>[];
      for (var column = 0; column < columns; column++) {
        final index = row * columns + column;
        frameRefs.add(
          FrameRef(assetId: assets[index].id, delayMs: defaultDelayMs),
        );
      }
      tracks.add(
        AnimationTrack(
          id: '${projectId}_track_$row',
          name: '轨道 ${row + 1}',
          kind: AnimationTrackKind.action,
          visible: true,
          locked: false,
          defaultDelayMs: defaultDelayMs,
          playbackMode: AnimationPlaybackMode.normal,
          clips: [
            TimelineClip(
              id: '${projectId}_clip_$row',
              name: '序列 ${row + 1}',
              startFrame: 0,
              frames: List<FrameRef>.unmodifiable(frameRefs),
              loop: true,
            ),
          ],
        ),
      );
    }

    final project = AnimationProject(
      id: projectId,
      title: title.trim().isEmpty ? '动画工程' : title.trim(),
      createdAt: now,
      updatedAt: now,
      canvasWidth: previewData.frameWidth,
      canvasHeight: previewData.frameHeight,
      tracks: List<AnimationTrack>.unmodifiable(tracks),
      assets: List<FrameAsset>.unmodifiable(assets),
      timeline: TimelineSettings(defaultFrameDelayMs: defaultDelayMs),
      exportSettings: const ExportSettings(),
      sourceImagePath: sourceImagePath,
      sourceGridSpec: spec,
    );
    final projectFile = await const AnimationProjectStore().saveProject(
      store,
      project,
    );

    return AnimationProjectImportResult(
      project: project,
      projectFile: projectFile,
      previewSheetBytes: previewData.sheetBytes,
    );
  }

  Future<AnimationProjectImportResult> importImagesAsTrack({
    required AppLocalStore store,
    required List<String> imagePaths,
    required String title,
    required int defaultDelayMs,
  }) async {
    if (imagePaths.isEmpty) {
      throw const ImageGenerationException('至少需要一张图片才能创建动画工程。');
    }
    final now = DateTime.now();
    final projectId = AnimationProject.newId();
    final assets = <FrameAsset>[];
    var canvasWidth = 0;
    var canvasHeight = 0;

    for (var index = 0; index < imagePaths.length; index++) {
      final bytes = await File(imagePaths[index]).readAsBytes();
      final decoded = image_lib.decodeImage(bytes);
      if (decoded == null) {
        throw ImageGenerationException('无法解析图片：${imagePaths[index]}');
      }
      canvasWidth = canvasWidth == 0 ? decoded.width : canvasWidth;
      canvasHeight = canvasHeight == 0 ? decoded.height : canvasHeight;
      final normalized =
          decoded.width == canvasWidth && decoded.height == canvasHeight
          ? decoded
          : image_lib.copyResize(
              decoded,
              width: canvasWidth,
              height: canvasHeight,
            );
      final normalizedBytes = Uint8List.fromList(
        image_lib.encodePng(normalized),
      );
      final file = await store.saveGeneratedImageBytes(
        groupId: projectId,
        index: index,
        bytes: normalizedBytes,
      );
      assets.add(
        FrameAsset(
          id: '${projectId}_asset_$index',
          path: file.path,
          width: canvasWidth,
          height: canvasHeight,
          source: FrameAssetSource.importedFile,
          sourceFrameIndex: index,
        ),
      );
    }

    final project = AnimationProject(
      id: projectId,
      title: title.trim().isEmpty ? '动画工程' : title.trim(),
      createdAt: now,
      updatedAt: now,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      tracks: [
        AnimationTrack(
          id: '${projectId}_track_0',
          name: '轨道 1',
          kind: AnimationTrackKind.action,
          visible: true,
          locked: false,
          defaultDelayMs: defaultDelayMs,
          playbackMode: AnimationPlaybackMode.normal,
          clips: [
            TimelineClip(
              id: '${projectId}_clip_0',
              name: '序列 1',
              startFrame: 0,
              frames: [
                for (final asset in assets)
                  FrameRef(assetId: asset.id, delayMs: defaultDelayMs),
              ],
              loop: true,
            ),
          ],
        ),
      ],
      assets: List<FrameAsset>.unmodifiable(assets),
      timeline: TimelineSettings(defaultFrameDelayMs: defaultDelayMs),
      exportSettings: const ExportSettings(),
    );
    final projectFile = await const AnimationProjectStore().saveProject(
      store,
      project,
    );
    final sheet = await const AnimationProjectRenderer().renderTrackSpriteSheet(
      project: project,
      trackId: project.tracks.first.id,
    );
    return AnimationProjectImportResult(
      project: project,
      projectFile: projectFile,
      previewSheetBytes: sheet.bytes,
    );
  }

  Future<AnimationProject> appendImagesAsTrack({
    required AppLocalStore store,
    required AnimationProject project,
    required List<String> imagePaths,
    required String trackName,
    required int defaultDelayMs,
  }) async {
    if (imagePaths.isEmpty) {
      throw const ImageGenerationException('至少需要一张图片才能导入序列帧。');
    }

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final startIndex = project.assets.length;
    final assets = <FrameAsset>[];
    for (var index = 0; index < imagePaths.length; index++) {
      final path = imagePaths[index];
      final bytes = await File(path).readAsBytes();
      final decoded = image_lib.decodeImage(bytes);
      if (decoded == null) {
        throw ImageGenerationException('无法解析图片：$path');
      }
      final normalized =
          decoded.width == project.canvasWidth &&
              decoded.height == project.canvasHeight
          ? decoded
          : image_lib.copyResize(
              decoded,
              width: project.canvasWidth,
              height: project.canvasHeight,
            );
      final normalizedBytes = Uint8List.fromList(
        image_lib.encodePng(normalized),
      );
      final file = await store.saveGeneratedImageBytes(
        groupId: project.id,
        index: startIndex + index,
        bytes: normalizedBytes,
      );
      assets.add(
        FrameAsset(
          id: '${project.id}_asset_${timestamp}_$index',
          path: file.path,
          width: project.canvasWidth,
          height: project.canvasHeight,
          source: FrameAssetSource.importedFile,
          sourceFrameIndex: index,
        ),
      );
    }

    final normalizedTrackName = trackName.trim().isEmpty
        ? '轨道 ${project.tracks.length + 1}'
        : trackName.trim();
    final track = AnimationTrack(
      id: '${project.id}_track_$timestamp',
      name: normalizedTrackName,
      kind: AnimationTrackKind.action,
      visible: true,
      locked: false,
      defaultDelayMs: defaultDelayMs,
      playbackMode: AnimationPlaybackMode.normal,
      clips: [
        TimelineClip(
          id: '${project.id}_clip_$timestamp',
          name: normalizedTrackName,
          startFrame: 0,
          frames: [
            for (final asset in assets)
              FrameRef(assetId: asset.id, delayMs: defaultDelayMs),
          ],
          loop: true,
        ),
      ],
    );

    return project
        .copyWith(
          assets: List<FrameAsset>.unmodifiable([...project.assets, ...assets]),
          tracks: List<AnimationTrack>.unmodifiable([...project.tracks, track]),
        )
        .touch();
  }

  Future<AnimationProject> rebindFrameAsset({
    required AppLocalStore store,
    required AnimationProject project,
    required String assetId,
    required String imagePath,
  }) async {
    if (assetId.trim().isEmpty) {
      throw const ImageGenerationException('动画帧资源不存在。');
    }
    final assetIndex = project.assets.indexWhere(
      (asset) => asset.id == assetId,
    );
    final targetIndex = assetIndex < 0 ? project.assets.length : assetIndex;

    final sourceFile = File(imagePath);
    if (!await sourceFile.exists()) {
      throw ImageGenerationException('替换图片不存在：$imagePath');
    }

    final Uint8List bytes;
    try {
      bytes = await sourceFile.readAsBytes();
    } on FileSystemException catch (error) {
      throw ImageGenerationException('无法读取替换图片：$imagePath（${error.message}）');
    }

    final decoded = image_lib.decodeImage(bytes);
    if (decoded == null) {
      throw ImageGenerationException('无法解析替换图片：$imagePath');
    }

    final targetWidth = project.canvasWidth > 0
        ? project.canvasWidth
        : decoded.width;
    final targetHeight = project.canvasHeight > 0
        ? project.canvasHeight
        : decoded.height;
    final normalized =
        decoded.width == targetWidth && decoded.height == targetHeight
        ? decoded
        : image_lib.copyResize(
            decoded,
            width: targetWidth,
            height: targetHeight,
          );
    final output = await store.saveGeneratedImageBytes(
      groupId: project.id,
      index: targetIndex,
      bytes: Uint8List.fromList(image_lib.encodePng(normalized)),
    );
    final previous = assetIndex < 0
        ? FrameAsset(
            id: assetId,
            path: '',
            width: targetWidth,
            height: targetHeight,
            source: FrameAssetSource.importedFile,
            sourceFrameIndex: targetIndex,
          )
        : project.assets[assetIndex];
    final replacement = FrameAsset(
      id: previous.id,
      path: output.path,
      width: targetWidth,
      height: targetHeight,
      source: FrameAssetSource.importedFile,
      sourceFrameIndex: previous.sourceFrameIndex ?? assetIndex,
    );
    return project
        .copyWith(
          assets: assetIndex < 0
              ? [...project.assets, replacement]
              : [
                  for (final asset in project.assets)
                    asset.id == assetId ? replacement : asset,
                ],
        )
        .touch();
  }
}

class RenderedAnimationFrame {
  const RenderedAnimationFrame({
    required this.bytes,
    required this.delayMs,
    required this.label,
    required this.asset,
  });

  final Uint8List bytes;
  final int delayMs;
  final String label;
  final FrameAsset asset;
}

class AnimationSpriteSheetRender {
  const AnimationSpriteSheetRender({
    required this.bytes,
    required this.rows,
    required this.columns,
    required this.gridSpec,
    this.frameDelayMs = const [],
  });

  final Uint8List bytes;
  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;
  final List<int> frameDelayMs;
}

class AnimationProjectRenderer {
  const AnimationProjectRenderer();

  Future<List<RenderedAnimationFrame>> renderTrackFrames({
    required AnimationProject project,
    required String trackId,
  }) async {
    final track = project.trackById(trackId);
    if (track == null) {
      throw const ImageGenerationException('动画轨道不存在。');
    }
    final refs = _expandPlayback(track.orderedFrames, track.playbackMode);
    final frames = <RenderedAnimationFrame>[];
    for (var index = 0; index < refs.length; index++) {
      final ref = refs[index];
      final asset = project.assetById(ref.assetId);
      if (asset == null) {
        throw ImageGenerationException('动画帧资源不存在：${ref.assetId}');
      }
      if (asset.path.isEmpty) {
        throw ImageGenerationException('动画帧文件路径为空：${asset.id}');
      }
      final bytes = await _renderFrameBytes(project, asset, ref.transform);
      frames.add(
        RenderedAnimationFrame(
          bytes: bytes,
          delayMs: ref.delayMs,
          label: '${track.name} · 第 ${index + 1} 帧',
          asset: asset,
        ),
      );
    }
    return frames;
  }

  Future<AnimationSpriteSheetRender> renderTrackSpriteSheet({
    required AnimationProject project,
    required String trackId,
    int? columns,
  }) async {
    final frames = await renderTrackFrames(project: project, trackId: trackId);
    if (frames.isEmpty) {
      throw const ImageGenerationException('当前轨道没有可导出的帧。');
    }
    final resolvedColumns = (columns ?? frames.length)
        .clamp(1, frames.length)
        .toInt();
    final rows = (frames.length / resolvedColumns).ceil();
    return _composeSpriteSheet(
      project: project,
      frames: frames,
      rows: rows,
      columns: resolvedColumns,
    );
  }

  Future<AnimationSpriteSheetRender> renderProjectSpriteSheet({
    required AnimationProject project,
    int? columns,
  }) async {
    final frames = await renderProjectFrames(project: project);
    final resolvedColumns = (columns ?? frames.length)
        .clamp(1, frames.length)
        .toInt();
    final rows = (frames.length / resolvedColumns).ceil();
    return _composeSpriteSheet(
      project: project,
      frames: frames,
      rows: rows,
      columns: resolvedColumns,
    );
  }

  Future<List<RenderedAnimationFrame>> renderProjectFrames({
    required AnimationProject project,
    bool? includeHiddenTracks,
    bool applyProjectPlayback = true,
  }) async {
    final renderHidden =
        includeHiddenTracks ?? project.exportSettings.includeHiddenTracks;
    final tracks = project.tracks
        .where((track) => renderHidden || track.visible)
        .toList();
    if (tracks.isEmpty) {
      throw const ImageGenerationException('没有可导出的可见轨道。');
    }

    final renderedTracks = <_RenderedTrackFrames>[];
    for (final track in tracks) {
      final frames = await renderTrackFrames(
        project: project,
        trackId: track.id,
      );
      if (frames.isEmpty) {
        continue;
      }
      renderedTracks.add(
        _RenderedTrackFrames(
          frames: frames,
          loops: track.clips.any((clip) => clip.loop),
        ),
      );
    }
    if (renderedTracks.isEmpty) {
      throw const ImageGenerationException('没有可导出的动画帧。');
    }

    final frameCount = renderedTracks
        .map((track) => track.frames.length)
        .fold(0, math.max);
    final frames = <RenderedAnimationFrame>[];
    for (var index = 0; index < frameCount; index++) {
      final canvas = _transparentCanvas(
        project.canvasWidth,
        project.canvasHeight,
      );
      var delayMs = project.timeline.defaultFrameDelayMs;
      var hasFrame = false;
      for (final track in renderedTracks) {
        final frame = track.frameAt(index);
        if (frame == null) {
          continue;
        }
        hasFrame = true;
        delayMs = math.max(delayMs, frame.delayMs);
        final image = image_lib.decodeImage(frame.bytes);
        if (image == null) {
          continue;
        }
        image_lib.compositeImage(canvas, image);
      }
      if (!hasFrame) {
        continue;
      }
      frames.add(
        RenderedAnimationFrame(
          bytes: Uint8List.fromList(image_lib.encodePng(canvas)),
          delayMs: delayMs,
          label: '${project.title} · 合成帧 ${index + 1}',
          asset: FrameAsset(
            id: '${project.id}_composite_$index',
            path: '',
            width: project.canvasWidth,
            height: project.canvasHeight,
            source: FrameAssetSource.editedFrame,
          ),
        ),
      );
    }
    if (!applyProjectPlayback) {
      return frames;
    }
    return _expandPlayback(frames, project.timeline.playbackMode);
  }

  Future<Uint8List> _renderFrameBytes(
    AnimationProject project,
    FrameAsset asset,
    FrameTransform transform,
  ) async {
    final file = File(asset.path);
    if (!await file.exists()) {
      throw ImageGenerationException('动画帧文件不存在：${asset.path}');
    }

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on FileSystemException catch (error) {
      throw ImageGenerationException('无法读取动画帧：${asset.path}（${error.message}）');
    }
    final image = image_lib.decodeImage(bytes);
    if (image == null) {
      throw ImageGenerationException('无法解析动画帧：${asset.path}');
    }
    if (transform.isIdentity &&
        image.width == project.canvasWidth &&
        image.height == project.canvasHeight) {
      return bytes;
    }
    var frame =
        image.width == project.canvasWidth &&
            image.height == project.canvasHeight
        ? image
        : image_lib.copyResize(
            image,
            width: project.canvasWidth,
            height: project.canvasHeight,
          );
    frame = frame.convert(numChannels: 4);
    if (transform.flipX) {
      image_lib.flipHorizontal(frame);
    }
    if (transform.flipY) {
      image_lib.flipVertical(frame);
    }

    final opacity = transform.opacity.clamp(0, 1).toDouble();
    if (opacity <= 0) {
      return _transparentPng(project.canvasWidth, project.canvasHeight);
    }
    if (opacity < 1) {
      for (final pixel in frame) {
        pixel.a = pixel.a * opacity;
      }
    }

    if (transform.offsetX == 0 && transform.offsetY == 0) {
      return Uint8List.fromList(image_lib.encodePng(frame));
    }

    final canvas = _transparentCanvas(
      project.canvasWidth,
      project.canvasHeight,
    );
    image_lib.compositeImage(
      canvas,
      frame,
      dstX: transform.offsetX.round(),
      dstY: transform.offsetY.round(),
    );
    return Uint8List.fromList(image_lib.encodePng(canvas));
  }

  AnimationSpriteSheetRender _composeSpriteSheet({
    required AnimationProject project,
    required List<RenderedAnimationFrame> frames,
    required int rows,
    required int columns,
  }) {
    final sheet = _transparentCanvas(
      project.canvasWidth * columns,
      project.canvasHeight * rows,
    );
    for (var index = 0; index < frames.length; index++) {
      final image = image_lib.decodeImage(frames[index].bytes);
      if (image == null) {
        continue;
      }
      final row = index ~/ columns;
      final column = index % columns;
      image_lib.compositeImage(
        sheet,
        image,
        dstX: column * project.canvasWidth,
        dstY: row * project.canvasHeight,
      );
    }
    final spec = SpriteSheetGridSpec(rows: rows, columns: columns);
    return AnimationSpriteSheetRender(
      bytes: Uint8List.fromList(image_lib.encodePng(sheet)),
      rows: rows,
      columns: columns,
      gridSpec: spec,
      frameDelayMs: [for (final frame in frames) frame.delayMs],
    );
  }

  List<T> _expandPlayback<T>(
    List<T> frames,
    AnimationPlaybackMode playbackMode,
  ) {
    if (frames.length <= 1) {
      return List<T>.from(frames);
    }
    return switch (playbackMode) {
      AnimationPlaybackMode.normal => List<T>.from(frames),
      AnimationPlaybackMode.reverse => frames.reversed.toList(),
      AnimationPlaybackMode.pingPong => <T>[
        ...frames,
        ...frames.reversed.skip(1).take(frames.length - 2),
      ],
    };
  }

  Uint8List _transparentPng(int width, int height) {
    return Uint8List.fromList(
      image_lib.encodePng(_transparentCanvas(width, height)),
    );
  }

  image_lib.Image _transparentCanvas(int width, int height) {
    final canvas = image_lib.Image(
      width: width,
      height: height,
      numChannels: 4,
    );
    for (final pixel in canvas) {
      pixel.a = 0;
    }
    return canvas;
  }
}

class _RenderedTrackFrames {
  const _RenderedTrackFrames({required this.frames, required this.loops});

  final List<RenderedAnimationFrame> frames;
  final bool loops;

  RenderedAnimationFrame? frameAt(int index) {
    if (frames.isEmpty) {
      return null;
    }
    if (index < frames.length) {
      return frames[index];
    }
    if (!loops) {
      return null;
    }
    return frames[index % frames.length];
  }
}

class AnimationProjectExportService {
  const AnimationProjectExportService();

  Future<SpriteSheetFileOutput> exportProjectSpriteSheet({
    required AppLocalStore store,
    required AnimationProject project,
  }) async {
    final render = await const AnimationProjectRenderer()
        .renderProjectSpriteSheet(project: project);
    return SpriteSheetFileService.exportPng(
      store: store,
      pngBytes: render.bytes,
      rows: render.rows,
      columns: render.columns,
      gridSpec: render.gridSpec,
    );
  }

  Future<SpriteSheetFileOutput> exportTrackSpriteSheet({
    required AppLocalStore store,
    required AnimationProject project,
    required String trackId,
  }) async {
    final render = await const AnimationProjectRenderer()
        .renderTrackSpriteSheet(project: project, trackId: trackId);
    return SpriteSheetFileService.exportPng(
      store: store,
      pngBytes: render.bytes,
      rows: render.rows,
      columns: render.columns,
      gridSpec: render.gridSpec,
    );
  }

  Future<GifComposeOutput> exportTrackGif({
    required AppLocalStore store,
    required AnimationProject project,
    required String trackId,
  }) async {
    final frames = await const AnimationProjectRenderer().renderTrackFrames(
      project: project,
      trackId: trackId,
    );
    if (frames.length < 2) {
      throw const ImageGenerationException('至少需要 2 帧才能导出 GIF。');
    }
    return GifComposer.composeToStore(
      store: store,
      frames: [
        for (var index = 0; index < frames.length; index++)
          GifSourceFrame.fromBytes(
            frames[index].bytes,
            sourcePath: project.title,
            delayMs: frames[index].delayMs,
            seed: index,
            label: frames[index].label,
          ),
      ],
      loopCount: project.exportSettings.loopCount,
      playbackMode: _gifPlaybackMode(project.timeline.playbackMode),
    );
  }

  Future<GifComposeOutput> exportProjectGif({
    required AppLocalStore store,
    required AnimationProject project,
  }) async {
    final frames = await const AnimationProjectRenderer().renderProjectFrames(
      project: project,
    );
    if (frames.length < 2) {
      throw const ImageGenerationException('至少需要 2 帧才能导出 GIF。');
    }
    return GifComposer.composeToStore(
      store: store,
      frames: [
        for (var index = 0; index < frames.length; index++)
          GifSourceFrame.fromBytes(
            frames[index].bytes,
            sourcePath: project.title,
            delayMs: frames[index].delayMs,
            seed: index,
            label: frames[index].label,
          ),
      ],
      loopCount: project.exportSettings.loopCount,
      playbackMode: GifPlaybackMode.normal,
    );
  }

  Future<List<File>> exportTrackPngSequence({
    required AppLocalStore store,
    required AnimationProject project,
    required String trackId,
  }) async {
    final frames = await const AnimationProjectRenderer().renderTrackFrames(
      project: project,
      trackId: trackId,
    );
    final files = <File>[];
    final groupId = '${project.id}_png_sequence';
    for (var index = 0; index < frames.length; index++) {
      files.add(
        await store.saveGeneratedImageBytes(
          groupId: groupId,
          index: index,
          bytes: frames[index].bytes,
        ),
      );
    }
    return files;
  }

  Future<List<File>> exportProjectPngSequence({
    required AppLocalStore store,
    required AnimationProject project,
  }) async {
    final frames = await const AnimationProjectRenderer().renderProjectFrames(
      project: project,
    );
    final files = <File>[];
    final groupId = '${project.id}_project_png_sequence';
    for (var index = 0; index < frames.length; index++) {
      files.add(
        await store.saveGeneratedImageBytes(
          groupId: groupId,
          index: index,
          bytes: frames[index].bytes,
        ),
      );
    }
    return files;
  }
}

GifPlaybackMode _gifPlaybackMode(AnimationPlaybackMode mode) {
  return switch (mode) {
    AnimationPlaybackMode.normal => GifPlaybackMode.normal,
    AnimationPlaybackMode.reverse => GifPlaybackMode.reverse,
    AnimationPlaybackMode.pingPong => GifPlaybackMode.pingPong,
  };
}
