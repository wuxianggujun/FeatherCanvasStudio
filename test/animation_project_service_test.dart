import 'dart:io';
import 'dart:typed_data';

import 'package:feather_canvas_studio/src/models/animation_project.dart';
import 'package:feather_canvas_studio/src/models/exceptions.dart';
import 'package:feather_canvas_studio/src/models/sprite_sheet_grid_spec.dart';
import 'package:feather_canvas_studio/src/services/animation_project_service.dart';
import 'package:feather_canvas_studio/src/services/app_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

void main() {
  test('imports sprite sheet into tracks and renders project sheet', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'animation_project_service_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final store = AppLocalStore(baseDirectoryOverride: tempDir);
    final sheetBytes = _spriteSheetPng(rows: 2, columns: 2);

    final result = await const AnimationProjectImporter().importSpriteSheet(
      store: store,
      sheetBytes: sheetBytes,
      title: 'Walk',
      rows: 2,
      columns: 2,
      defaultDelayMs: 100,
      gridSpec: const SpriteSheetGridSpec(rows: 2, columns: 2),
      sourceImagePath: '/tmp/source.png',
    );

    expect(await result.projectFile.exists(), isTrue);
    expect(result.project.title, 'Walk');
    expect(result.project.tracks, hasLength(2));
    expect(result.project.assets, hasLength(4));
    expect(result.project.totalFrameRefs, 4);
    for (final asset in result.project.assets) {
      expect(await File(asset.path).exists(), isTrue);
    }

    final trackRender = await const AnimationProjectRenderer()
        .renderTrackSpriteSheet(
          project: result.project,
          trackId: result.project.tracks.first.id,
        );
    final projectRender = await const AnimationProjectRenderer()
        .renderProjectSpriteSheet(project: result.project);
    final decodedTrack = image_lib.decodePng(trackRender.bytes)!;
    final decodedProject = image_lib.decodePng(projectRender.bytes)!;

    expect(trackRender.rows, 1);
    expect(trackRender.columns, 2);
    expect(decodedTrack.width, result.project.canvasWidth * 2);
    expect(decodedTrack.height, result.project.canvasHeight);
    expect(projectRender.rows, 1);
    expect(projectRender.columns, 2);
    expect(decodedProject.width, result.project.canvasWidth * 2);
    expect(decodedProject.height, result.project.canvasHeight);
  });

  test('appends imported image sequence as a normalized track', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'animation_project_append_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final store = AppLocalStore(baseDirectoryOverride: tempDir);
    final sourceA = File('${tempDir.path}${Platform.pathSeparator}a.png');
    final sourceB = File('${tempDir.path}${Platform.pathSeparator}b.png');
    await sourceA.writeAsBytes(
      _singleFramePng(
        width: 2,
        height: 2,
        color: image_lib.ColorRgb8(255, 0, 0),
      ),
    );
    await sourceB.writeAsBytes(
      _singleFramePng(
        width: 8,
        height: 4,
        color: image_lib.ColorRgb8(0, 255, 0),
      ),
    );

    final baseProject = AnimationProject.empty(
      title: 'Base',
      canvasWidth: 4,
      canvasHeight: 4,
      defaultDelayMs: 120,
    );
    final result = await const AnimationProjectImporter().appendImagesAsTrack(
      store: store,
      project: baseProject,
      imagePaths: [sourceA.path, sourceB.path],
      trackName: 'Imported',
      defaultDelayMs: 80,
    );

    expect(result.tracks, hasLength(2));
    expect(result.assets, hasLength(2));
    expect(result.totalFrameRefs, 2);
    expect(result.tracks.last.name, 'Imported');
    expect(result.tracks.last.defaultDelayMs, 80);
    expect(result.tracks.last.orderedFrames, hasLength(2));

    for (final asset in result.assets) {
      final file = File(asset.path);
      expect(await file.exists(), isTrue);
      expect(asset.width, 4);
      expect(asset.height, 4);
      expect(asset.source, FrameAssetSource.importedFile);
      final decoded = image_lib.decodePng(await file.readAsBytes())!;
      expect(decoded.width, 4);
      expect(decoded.height, 4);
    }
  });

  test('reports missing and invalid animation project files', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'animation_project_load_error_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final store = const AnimationProjectStore();
    final missingPath =
        '${tempDir.path}${Platform.pathSeparator}missing_project.json';
    await expectLater(
      store.loadProject(missingPath),
      throwsA(
        isA<ImageGenerationException>().having(
          (error) => error.message,
          'message',
          contains('动画工程文件不存在'),
        ),
      ),
    );

    final invalidFile = File(
      '${tempDir.path}${Platform.pathSeparator}invalid_project.json',
    );
    await invalidFile.writeAsString('{ invalid json');
    await expectLater(
      store.loadProject(invalidFile.path),
      throwsA(
        isA<ImageGenerationException>().having(
          (error) => error.message,
          'message',
          contains('不是有效 JSON'),
        ),
      ),
    );
  });

  test('reports missing frame assets during animation rendering', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'animation_project_missing_frame_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final missingFramePath =
        '${tempDir.path}${Platform.pathSeparator}missing_frame.png';
    final createdAt = DateTime.parse('2026-05-17T08:00:00Z');
    final project = AnimationProject(
      id: 'project-missing-frame',
      title: 'Missing Frame',
      createdAt: createdAt,
      updatedAt: createdAt,
      canvasWidth: 2,
      canvasHeight: 1,
      tracks: [
        _track(
          id: 'track-missing',
          name: 'Missing',
          assetIds: const ['asset-missing'],
          delays: const [100],
        ),
      ],
      assets: [_asset('asset-missing', missingFramePath)],
      timeline: const TimelineSettings(defaultFrameDelayMs: 100),
      exportSettings: const ExportSettings(),
    );

    await expectLater(
      const AnimationProjectRenderer().renderTrackFrames(
        project: project,
        trackId: 'track-missing',
      ),
      throwsA(
        isA<ImageGenerationException>().having(
          (error) => error.message,
          'message',
          contains('动画帧文件不存在'),
        ),
      ),
    );
  });

  test('diagnoses and rebinds missing frame assets', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'animation_project_rebind_frame_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final store = AppLocalStore(baseDirectoryOverride: tempDir);
    final missingFramePath =
        '${tempDir.path}${Platform.pathSeparator}missing_frame.png';
    final replacement = File(
      '${tempDir.path}${Platform.pathSeparator}replacement.png',
    );
    final unused = File('${tempDir.path}${Platform.pathSeparator}unused.png');
    await replacement.writeAsBytes(
      _singleFramePng(
        width: 4,
        height: 4,
        color: image_lib.ColorRgb8(0, 0, 255),
      ),
    );
    await unused.writeAsBytes(
      _singleFramePng(
        width: 2,
        height: 1,
        color: image_lib.ColorRgb8(255, 0, 255),
      ),
    );

    final createdAt = DateTime.parse('2026-05-17T08:00:00Z');
    final project = AnimationProject(
      id: 'project-rebind',
      title: 'Rebind',
      createdAt: createdAt,
      updatedAt: createdAt,
      canvasWidth: 2,
      canvasHeight: 1,
      tracks: [
        _track(
          id: 'track-rebind',
          name: 'Rebind',
          assetIds: const ['asset-rebind', ''],
          delays: const [100, 80],
        ),
      ],
      assets: [
        _asset('asset-rebind', missingFramePath),
        _asset('asset-unused', unused.path),
      ],
      timeline: const TimelineSettings(defaultFrameDelayMs: 100),
      exportSettings: const ExportSettings(),
    );

    final inspector = const AnimationProjectAssetInspector();
    final beforeDiagnostics = await inspector.inspect(project);
    expect(beforeDiagnostics.missingAssets, hasLength(1));
    expect(beforeDiagnostics.missingAssets.single.referenceCount, 1);
    expect(beforeDiagnostics.unusedAssets, hasLength(1));
    expect(beforeDiagnostics.unusedAssets.single.id, 'asset-unused');
    expect(beforeDiagnostics.invalidFrameReferenceCount, 1);
    expect(beforeDiagnostics.autoRepairableIssueCount, 2);

    final cleaned = const AnimationProjectEditor()
        .repairConsistency(project: project)!
        .project;
    expect(cleaned.assetById('asset-unused'), isNull);
    expect(cleaned.tracks.single.orderedFrames, hasLength(1));
    expect(await unused.exists(), isTrue);

    final brokenReferenceProject = cleaned.copyWith(assets: const []);
    final brokenReferenceDiagnostics = await inspector.inspect(
      brokenReferenceProject,
    );
    expect(brokenReferenceDiagnostics.missingAssets, hasLength(1));
    expect(
      brokenReferenceDiagnostics.missingAssets.single.message,
      contains('资源记录不存在'),
    );

    final rebound = await const AnimationProjectImporter().rebindFrameAsset(
      store: store,
      project: cleaned,
      assetId: 'asset-rebind',
      imagePath: replacement.path,
    );
    final reboundAsset = rebound.assetById('asset-rebind')!;
    expect(reboundAsset.path, isNot(missingFramePath));
    expect(reboundAsset.source, FrameAssetSource.importedFile);
    expect(await File(reboundAsset.path).exists(), isTrue);

    final decoded = image_lib.decodePng(
      await File(reboundAsset.path).readAsBytes(),
    )!;
    expect(decoded.width, 2);
    expect(decoded.height, 1);

    final afterDiagnostics = await inspector.inspect(rebound);
    expect(afterDiagnostics.hasIssues, isFalse);
    final frames = await const AnimationProjectRenderer().renderTrackFrames(
      project: rebound,
      trackId: 'track-rebind',
    );
    expect(frames, hasLength(1));

    final restoredReference = await const AnimationProjectImporter()
        .rebindFrameAsset(
          store: store,
          project: brokenReferenceProject,
          assetId: 'asset-rebind',
          imagePath: replacement.path,
        );
    expect(restoredReference.assetById('asset-rebind'), isNotNull);
  });

  test('renders single-frame transform before export composition', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'animation_project_transform_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final source = File('${tempDir.path}${Platform.pathSeparator}frame.png');
    await source.writeAsBytes(_twoColorFramePng());
    final createdAt = DateTime.parse('2026-05-17T08:00:00Z');
    final project = AnimationProject(
      id: 'project-transform',
      title: 'Transform',
      createdAt: createdAt,
      updatedAt: createdAt,
      canvasWidth: 2,
      canvasHeight: 1,
      tracks: [
        AnimationTrack(
          id: 'track-transform',
          name: 'Transform',
          kind: AnimationTrackKind.action,
          visible: true,
          locked: false,
          defaultDelayMs: 100,
          playbackMode: AnimationPlaybackMode.normal,
          clips: [
            TimelineClip(
              id: 'clip-transform',
              name: 'Loop',
              startFrame: 0,
              frames: [
                FrameRef(
                  assetId: 'asset-transform',
                  delayMs: 100,
                  transform: const FrameTransform(flipX: true, opacity: 0.5),
                ),
              ],
              loop: true,
            ),
          ],
        ),
      ],
      assets: [
        FrameAsset(
          id: 'asset-transform',
          path: source.path,
          width: 2,
          height: 1,
          source: FrameAssetSource.importedFile,
          sourceFrameIndex: 0,
        ),
      ],
      timeline: const TimelineSettings(defaultFrameDelayMs: 100),
      exportSettings: const ExportSettings(),
    );

    final frames = await const AnimationProjectRenderer().renderTrackFrames(
      project: project,
      trackId: 'track-transform',
    );
    final decoded = image_lib.decodePng(frames.single.bytes)!;
    final left = decoded.getPixel(0, 0);
    final right = decoded.getPixel(1, 0);

    expect(frames, hasLength(1));
    expect(left.g, greaterThan(left.r));
    expect(right.r, greaterThan(right.g));
    expect(left.a, greaterThan(0));
    expect(left.a, lessThan(255));
  });

  test(
    'composes visible project tracks in order and loops shorter tracks',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'animation_project_composite_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final red = File('${tempDir.path}${Platform.pathSeparator}red.png');
      final green = File('${tempDir.path}${Platform.pathSeparator}green.png');
      final blue = File('${tempDir.path}${Platform.pathSeparator}blue.png');
      final yellow = File('${tempDir.path}${Platform.pathSeparator}yellow.png');
      await red.writeAsBytes(
        _singleFramePng(
          width: 2,
          height: 1,
          color: image_lib.ColorRgb8(255, 0, 0),
        ),
      );
      await green.writeAsBytes(
        _transparentThenColorFramePng(image_lib.ColorRgba8(0, 255, 0, 255)),
      );
      await blue.writeAsBytes(
        _transparentThenColorFramePng(image_lib.ColorRgba8(0, 0, 255, 255)),
      );
      await yellow.writeAsBytes(
        _singleFramePng(
          width: 2,
          height: 1,
          color: image_lib.ColorRgb8(255, 255, 0),
        ),
      );

      final createdAt = DateTime.parse('2026-05-17T08:00:00Z');
      final project = AnimationProject(
        id: 'project-composite',
        title: 'Composite',
        createdAt: createdAt,
        updatedAt: createdAt,
        canvasWidth: 2,
        canvasHeight: 1,
        tracks: [
          _track(
            id: 'track-base',
            name: 'Base',
            assetIds: const ['asset-red'],
            delays: const [100],
          ),
          _track(
            id: 'track-overlay',
            name: 'Overlay',
            assetIds: const ['asset-green', 'asset-blue'],
            delays: const [120, 140],
          ),
          _track(
            id: 'track-hidden',
            name: 'Hidden',
            assetIds: const ['asset-yellow'],
            delays: const [100],
            visible: false,
          ),
        ],
        assets: [
          _asset('asset-red', red.path),
          _asset('asset-green', green.path),
          _asset('asset-blue', blue.path),
          _asset('asset-yellow', yellow.path),
        ],
        timeline: const TimelineSettings(defaultFrameDelayMs: 80),
        exportSettings: const ExportSettings(),
      );

      final renderer = const AnimationProjectRenderer();
      final frames = await renderer.renderProjectFrames(project: project);
      final render = await renderer.renderProjectSpriteSheet(project: project);
      final decoded = image_lib.decodePng(render.bytes)!;

      expect(frames, hasLength(2));
      expect(frames.map((frame) => frame.delayMs), [120, 140]);
      expect(render.rows, 1);
      expect(render.columns, 2);
      expect(decoded.width, 4);
      expect(decoded.height, 1);

      final frameOneLeft = decoded.getPixel(0, 0);
      final frameOneRight = decoded.getPixel(1, 0);
      final frameTwoLeft = decoded.getPixel(2, 0);
      final frameTwoRight = decoded.getPixel(3, 0);
      expect(frameOneLeft.r, greaterThan(frameOneLeft.g));
      expect(frameOneRight.g, greaterThan(frameOneRight.r));
      expect(frameTwoLeft.r, greaterThan(frameTwoLeft.b));
      expect(frameTwoRight.b, greaterThan(frameTwoRight.r));

      final hiddenFrames = await renderer.renderProjectFrames(
        project: project.copyWith(
          exportSettings: const ExportSettings(includeHiddenTracks: true),
        ),
      );
      final hiddenFirst = image_lib.decodePng(hiddenFrames.first.bytes)!;
      final hiddenPixel = hiddenFirst.getPixel(0, 0);
      expect(hiddenPixel.r, greaterThan(200));
      expect(hiddenPixel.g, greaterThan(200));

      final reversedFrames = await renderer.renderProjectFrames(
        project: project.copyWith(
          timeline: const TimelineSettings(
            defaultFrameDelayMs: 80,
            playbackMode: AnimationPlaybackMode.reverse,
          ),
        ),
      );
      final reversedFirst = image_lib.decodePng(reversedFrames.first.bytes)!;
      final reversedPixel = reversedFirst.getPixel(1, 0);
      expect(reversedPixel.b, greaterThan(reversedPixel.r));
    },
  );
}

Uint8List _spriteSheetPng({required int rows, required int columns}) {
  const frameWidth = 4;
  const frameHeight = 4;
  final sheet = image_lib.Image(
    width: frameWidth * columns,
    height: frameHeight * rows,
  );
  final colors = [
    image_lib.ColorRgb8(255, 0, 0),
    image_lib.ColorRgb8(0, 255, 0),
    image_lib.ColorRgb8(0, 0, 255),
    image_lib.ColorRgb8(255, 255, 0),
  ];
  for (var row = 0; row < rows; row++) {
    for (var column = 0; column < columns; column++) {
      image_lib.fillRect(
        sheet,
        x1: column * frameWidth,
        y1: row * frameHeight,
        x2: column * frameWidth + frameWidth - 1,
        y2: row * frameHeight + frameHeight - 1,
        color: colors[row * columns + column],
      );
    }
  }
  return Uint8List.fromList(image_lib.encodePng(sheet));
}

Uint8List _singleFramePng({
  required int width,
  required int height,
  required image_lib.Color color,
}) {
  final image = image_lib.Image(width: width, height: height);
  image_lib.fill(image, color: color);
  return Uint8List.fromList(image_lib.encodePng(image));
}

Uint8List _twoColorFramePng() {
  final image = image_lib.Image(width: 2, height: 1);
  image.setPixel(0, 0, image_lib.ColorRgb8(255, 0, 0));
  image.setPixel(1, 0, image_lib.ColorRgb8(0, 255, 0));
  return Uint8List.fromList(image_lib.encodePng(image));
}

Uint8List _transparentThenColorFramePng(image_lib.Color color) {
  final image = image_lib.Image(width: 2, height: 1, numChannels: 4);
  image.setPixel(0, 0, image_lib.ColorRgba8(0, 0, 0, 0));
  image.setPixel(1, 0, color);
  return Uint8List.fromList(image_lib.encodePng(image));
}

AnimationTrack _track({
  required String id,
  required String name,
  required List<String> assetIds,
  required List<int> delays,
  bool visible = true,
}) {
  return AnimationTrack(
    id: id,
    name: name,
    kind: AnimationTrackKind.layer,
    visible: visible,
    locked: false,
    defaultDelayMs: delays.first,
    playbackMode: AnimationPlaybackMode.normal,
    clips: [
      TimelineClip(
        id: '$id-clip',
        name: 'Loop',
        startFrame: 0,
        frames: [
          for (var index = 0; index < assetIds.length; index++)
            FrameRef(assetId: assetIds[index], delayMs: delays[index]),
        ],
        loop: true,
      ),
    ],
  );
}

FrameAsset _asset(String id, String path) {
  return FrameAsset(
    id: id,
    path: path,
    width: 2,
    height: 1,
    source: FrameAssetSource.importedFile,
    sourceFrameIndex: 0,
  );
}
