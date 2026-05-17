import 'package:feather_canvas_studio/src/models/animation_project.dart';
import 'package:feather_canvas_studio/src/models/sprite_sheet_grid_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips animation project json with tracks and assets', () {
    final createdAt = DateTime.parse('2026-05-17T08:00:00Z');
    final updatedAt = DateTime.parse('2026-05-17T09:00:00Z');
    final project = AnimationProject(
      id: 'project-1',
      title: 'Run Cycle',
      createdAt: createdAt,
      updatedAt: updatedAt,
      canvasWidth: 64,
      canvasHeight: 48,
      tracks: const [
        AnimationTrack(
          id: 'track-1',
          name: 'Front',
          kind: AnimationTrackKind.action,
          visible: true,
          locked: false,
          defaultDelayMs: 90,
          playbackMode: AnimationPlaybackMode.pingPong,
          clips: [
            TimelineClip(
              id: 'clip-1',
              name: 'Loop',
              startFrame: 0,
              frames: [
                FrameRef(assetId: 'asset-1', delayMs: 90),
                FrameRef(assetId: 'asset-2', delayMs: 120),
              ],
              loop: true,
            ),
          ],
        ),
      ],
      assets: const [
        FrameAsset(
          id: 'asset-1',
          path: '/tmp/a.png',
          width: 64,
          height: 48,
          source: FrameAssetSource.spriteSheetSlice,
          sourceFrameIndex: 0,
        ),
        FrameAsset(
          id: 'asset-2',
          path: '/tmp/b.png',
          width: 64,
          height: 48,
          source: FrameAssetSource.spriteSheetSlice,
          sourceFrameIndex: 1,
        ),
      ],
      timeline: TimelineSettings(defaultFrameDelayMs: 90),
      exportSettings: ExportSettings(loopCount: 0),
      sourceImagePath: '/tmp/source.png',
      sourceGridSpec: SpriteSheetGridSpec(rows: 1, columns: 2),
    );

    final restored = AnimationProject.fromJson(project.toJson());
    final summary = AnimationProjectSummary.fromProject(restored);

    expect(restored.id, project.id);
    expect(restored.title, 'Run Cycle');
    expect(restored.canvasWidth, 64);
    expect(restored.canvasHeight, 48);
    expect(restored.sourceGridSpec?.columns, 2);
    expect(restored.tracks.single.playbackMode, AnimationPlaybackMode.pingPong);
    expect(restored.tracks.single.totalFrameRefs, 2);
    expect(restored.assetById('asset-2')?.sourceFrameIndex, 1);
    expect(summary.trackCount, 1);
    expect(summary.frameCount, 2);
    expect(summary.canvasWidth, 64);
  });
}
