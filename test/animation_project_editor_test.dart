import 'package:feather_canvas_studio/src/models/animation_project.dart';
import 'package:feather_canvas_studio/src/services/animation_project_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const editor = AnimationProjectEditor();

  test('edits tracks and returns selected track for history restore', () {
    final project = _project();

    final projectDelay = editor.setProjectDefaultDelay(
      project: project,
      delayMs: 140,
    );
    expect(projectDelay.project.timeline.defaultFrameDelayMs, 140);

    final projectPlayback = editor.setProjectPlaybackMode(
      project: project,
      mode: AnimationPlaybackMode.reverse,
    );
    expect(
      projectPlayback.project.timeline.playbackMode,
      AnimationPlaybackMode.reverse,
    );

    final loopCount = editor.setProjectLoopCount(
      project: project,
      loopCount: 2,
    );
    expect(loopCount.project.exportSettings.loopCount, 2);

    final includeHiddenTracks = editor.setProjectIncludeHiddenTracks(
      project: project,
      includeHiddenTracks: true,
    );
    expect(
      includeHiddenTracks.project.exportSettings.includeHiddenTracks,
      true,
    );

    final added = editor.addTrack(project: project, defaultDelayMs: 90);
    expect(added.project.tracks, hasLength(3));
    expect(added.project.tracks.last.name, '轨道 3');
    expect(added.selectedTrackId, added.project.tracks.last.id);

    final addHistory = _HistorySnapshot(
      beforeProject: project,
      beforeTrackId: 'track-main',
      afterProject: added.project,
      afterTrackId: added.selectedTrackId,
    );
    expect(addHistory.undoProject.tracks, hasLength(2));
    expect(addHistory.undoTrackId, 'track-main');
    expect(addHistory.redoProject.tracks, hasLength(3));
    expect(addHistory.redoTrackId, added.selectedTrackId);

    final duplicated = editor.duplicateTrack(
      project: project,
      trackId: 'track-main',
    )!;
    expect(duplicated.project.tracks, hasLength(3));
    expect(duplicated.project.tracks[1].name, 'Main 副本');
    expect(duplicated.project.tracks[1].locked, isFalse);
    expect(duplicated.project.tracks[1].orderedFrames, hasLength(2));
    expect(duplicated.selectedTrackId, duplicated.project.tracks[1].id);

    final deleted = editor.deleteTrack(
      project: project,
      trackId: 'track-main',
    )!;
    expect(deleted.project.tracks.map((track) => track.id), ['track-alt']);
    expect(deleted.selectedTrackId, 'track-alt');
    expect(
      editor.deleteTrack(project: deleted.project, trackId: 'track-alt'),
      isNull,
    );

    final moved = editor.moveTrack(
      project: project,
      trackId: 'track-alt',
      delta: -1,
    )!;
    expect(moved.project.tracks.map((track) => track.id), [
      'track-alt',
      'track-main',
    ]);
    expect(moved.selectedTrackId, isNull);

    final hidden = editor.setTrackVisible(
      project: project,
      trackId: 'track-main',
      visible: false,
    )!;
    expect(hidden.project.trackById('track-main')!.visible, isFalse);

    final locked = editor.setTrackLocked(
      project: project,
      trackId: 'track-main',
      locked: true,
    )!;
    expect(locked.project.trackById('track-main')!.locked, isTrue);

    final delayed = editor.setTrackDelay(
      project: project,
      trackId: 'track-main',
      delayMs: 160,
    )!;
    final delayedTrack = delayed.project.trackById('track-main')!;
    expect(delayedTrack.defaultDelayMs, 160);
    expect(delayedTrack.orderedFrames.map((frame) => frame.delayMs), [
      160,
      160,
    ]);

    final playback = editor.setTrackPlaybackMode(
      project: project,
      trackId: 'track-main',
      mode: AnimationPlaybackMode.pingPong,
    )!;
    expect(
      playback.project.trackById('track-main')!.playbackMode,
      AnimationPlaybackMode.pingPong,
    );
  });

  test('edits ordered frames and skips locked tracks', () {
    final project = _project();

    final moved = editor.moveFrame(
      project: project,
      trackId: 'track-main',
      fromIndex: 0,
      toIndex: 1,
    )!;
    expect(moved.project.trackById('track-main')!.orderedFrames.map(_assetId), [
      'asset-second',
      'asset-first',
    ]);

    final duplicated = editor.duplicateFrame(
      project: project,
      trackId: 'track-main',
      frameIndex: 0,
    )!;
    expect(
      duplicated.project.trackById('track-main')!.orderedFrames.map(_assetId),
      ['asset-first', 'asset-first', 'asset-second'],
    );

    final deleted = editor.deleteFrame(
      project: project,
      trackId: 'track-main',
      frameIndex: 0,
    )!;
    expect(
      deleted.project.trackById('track-main')!.orderedFrames.map(_assetId),
      ['asset-second'],
    );
    expect(
      editor.deleteFrame(
        project: deleted.project,
        trackId: 'track-main',
        frameIndex: 0,
      ),
      isNull,
    );

    final delayed = editor.setFrameDelay(
      project: project,
      trackId: 'track-main',
      frameIndex: 1,
      delayMs: 180,
    )!;
    expect(
      delayed.project.trackById('track-main')!.orderedFrames[1].delayMs,
      180,
    );

    final transformed = editor.setFrameTransform(
      project: project,
      trackId: 'track-main',
      frameIndex: 1,
      transform: const FrameTransform(
        offsetX: 2,
        offsetY: -1,
        opacity: 0.5,
        flipX: true,
      ),
    )!;
    final transform = transformed.project
        .trackById('track-main')!
        .orderedFrames[1]
        .transform;
    expect(transform.offsetX, 2);
    expect(transform.offsetY, -1);
    expect(transform.opacity, 0.5);
    expect(transform.flipX, isTrue);

    const insertedAsset = FrameAsset(
      id: 'asset-inserted',
      path: '/tmp/inserted.png',
      width: 4,
      height: 4,
      source: FrameAssetSource.editedFrame,
      sourceFrameIndex: 1,
    );
    final inserted = editor.insertFrameAsset(
      project: project,
      trackId: 'track-main',
      insertIndex: 1,
      asset: insertedAsset,
      delayMs: 150,
    )!;
    final insertedFrames = inserted.project
        .trackById('track-main')!
        .orderedFrames;
    expect(insertedFrames.map(_assetId), [
      'asset-first',
      'asset-inserted',
      'asset-second',
    ]);
    expect(insertedFrames.map((frame) => frame.delayMs), [100, 150, 120]);
    expect(
      inserted.project.assetById('asset-inserted')?.source,
      FrameAssetSource.editedFrame,
    );
    expect(inserted.selectedTrackId, 'track-main');
    expect(
      editor.insertFrameAsset(
        project: project,
        trackId: 'track-main',
        insertIndex: 3,
        asset: insertedAsset,
      ),
      isNull,
    );

    final lockedProject = editor
        .setTrackLocked(project: project, trackId: 'track-main', locked: true)!
        .project;
    expect(
      editor.duplicateFrame(
        project: lockedProject,
        trackId: 'track-main',
        frameIndex: 0,
      ),
      isNull,
    );
    expect(
      editor.setFrameDelay(
        project: lockedProject,
        trackId: 'track-main',
        frameIndex: 0,
        delayMs: 200,
      ),
      isNull,
    );
    expect(
      editor.setFrameTransform(
        project: lockedProject,
        trackId: 'track-main',
        frameIndex: 0,
        transform: const FrameTransform(offsetX: 1),
      ),
      isNull,
    );
    expect(
      editor.insertFrameAsset(
        project: lockedProject,
        trackId: 'track-main',
        insertIndex: 1,
        asset: insertedAsset,
      ),
      isNull,
    );
  });
}

String _assetId(FrameRef frame) => frame.assetId;

class _HistorySnapshot {
  const _HistorySnapshot({
    required this.beforeProject,
    required this.beforeTrackId,
    required this.afterProject,
    required this.afterTrackId,
  });

  final AnimationProject beforeProject;
  final String? beforeTrackId;
  final AnimationProject afterProject;
  final String? afterTrackId;

  AnimationProject get undoProject => beforeProject;
  String? get undoTrackId => beforeTrackId;
  AnimationProject get redoProject => afterProject;
  String? get redoTrackId => afterTrackId;
}

AnimationProject _project() {
  final createdAt = DateTime.parse('2026-05-17T08:00:00Z');
  return AnimationProject(
    id: 'project-editor',
    title: 'Editor',
    createdAt: createdAt,
    updatedAt: createdAt,
    canvasWidth: 4,
    canvasHeight: 4,
    tracks: const [
      AnimationTrack(
        id: 'track-main',
        name: 'Main',
        kind: AnimationTrackKind.action,
        visible: true,
        locked: false,
        defaultDelayMs: 100,
        playbackMode: AnimationPlaybackMode.normal,
        clips: [
          TimelineClip(
            id: 'clip-main',
            name: 'Loop',
            startFrame: 0,
            frames: [
              FrameRef(assetId: 'asset-first', delayMs: 100),
              FrameRef(assetId: 'asset-second', delayMs: 120),
            ],
            loop: true,
          ),
        ],
      ),
      AnimationTrack(
        id: 'track-alt',
        name: 'Alt',
        kind: AnimationTrackKind.action,
        visible: true,
        locked: false,
        defaultDelayMs: 110,
        playbackMode: AnimationPlaybackMode.normal,
        clips: [
          TimelineClip(
            id: 'clip-alt',
            name: 'Alt Loop',
            startFrame: 0,
            frames: [FrameRef(assetId: 'asset-second', delayMs: 110)],
            loop: true,
          ),
        ],
      ),
    ],
    assets: const [
      FrameAsset(
        id: 'asset-first',
        path: '/tmp/first.png',
        width: 4,
        height: 4,
        source: FrameAssetSource.importedFile,
        sourceFrameIndex: 0,
      ),
      FrameAsset(
        id: 'asset-second',
        path: '/tmp/second.png',
        width: 4,
        height: 4,
        source: FrameAssetSource.importedFile,
        sourceFrameIndex: 1,
      ),
    ],
    timeline: const TimelineSettings(defaultFrameDelayMs: 100),
    exportSettings: const ExportSettings(),
  );
}
