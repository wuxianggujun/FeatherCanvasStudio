import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Tristate;

import 'package:feather_canvas_studio/src/models/animation_project.dart';
import 'package:feather_canvas_studio/src/models/app_config.dart';
import 'package:feather_canvas_studio/src/models/generated_image.dart';
import 'package:feather_canvas_studio/src/models/image_advanced_settings.dart';
import 'package:feather_canvas_studio/src/models/sprite_sheet_grid_spec.dart';
import 'package:feather_canvas_studio/src/widgets/workspaces/animation_project_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('animation project workspace exposes track and frame workflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = (await tester.runAsync(
      () =>
          Directory.systemTemp.createTemp('animation_project_workspace_test_'),
    ))!;
    addTearDown(() async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      for (var attempt = 0; attempt < 5; attempt++) {
        if (!await tempDir.exists()) {
          return;
        }
        try {
          await tempDir.delete(recursive: true);
          return;
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    });

    final firstFramePath = (await tester.runAsync(
      () => _writePng(tempDir, 'first.png', image_lib.ColorRgb8(255, 0, 0)),
    ))!;
    final secondFramePath = (await tester.runAsync(
      () => _writePng(tempDir, 'second.png', image_lib.ColorRgb8(0, 255, 0)),
    ))!;
    final project = _projectWithTwoTracks(firstFramePath, secondFramePath);

    var imageSequenceImports = 0;
    var librarySequenceImports = 0;
    var addedTracks = 0;
    var exportedSheets = 0;
    var exportedGifs = 0;
    var exportedSequences = 0;
    var exportedProjectGifs = 0;
    var exportedProjectSequences = 0;
    String? duplicatedTrackId;
    String? deletedTrackId;
    String? visibilityTrackId;
    bool? requestedVisibility;
    String? lockedTrackId;
    bool? requestedLock;
    int? duplicatedFrameIndex;
    int? deletedFrameIndex;
    int? changedFrameDelay;
    int? changedProjectDelay;
    int? changedProjectLoopCount;
    bool? requestedProjectHiddenTracks;
    FrameTransform? changedTransform;
    int? replacedFrameIndex;
    int? clearedFrameIndex;
    int? pixelatedFrameIndex;
    int? pixelatedBlockSize;
    String? blankInsertedTrackId;
    int? blankInsertIndex;
    String? imageInsertedTrackId;
    int? imageInsertIndex;
    final promptController = TextEditingController(text: 'walk cycle');
    final negativePromptController = TextEditingController(text: 'blur');
    final userController = TextEditingController();
    addTearDown(promptController.dispose);
    addTearDown(negativePromptController.dispose);
    addTearDown(userController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimationProjectWorkspace(
            apiConfigs: [ApiConfig.defaults()],
            selectedApiConfig: ApiConfig.defaults(),
            promptController: promptController,
            negativePromptController: negativePromptController,
            size: '1024x1024',
            rows: 2,
            columns: 2,
            gridSpec: const SpriteSheetGridSpec(rows: 2, columns: 2),
            templateImagePath: null,
            advancedSettings: const ImageAdvancedSettings(),
            userController: userController,
            isGenerating: false,
            errorMessage: null,
            debugRecord: null,
            generatedImages: const [],
            project: project,
            selectedTrackId: 'track-main',
            isProjectBusy: false,
            projectErrorMessage: null,
            enablePreviewPlayback: false,
            onApiConfigChanged: (_) {},
            onOpenApiSettings: () {},
            onSizeChanged: (_) {},
            onRowsChanged: (_) {},
            onColumnsChanged: (_) {},
            onGridSpecChanged: (_) {},
            onAdvancedSettingsChanged: (_) {},
            onPickTemplateImage: () {},
            onClearTemplateImage: () {},
            onGenerate: () {},
            onImportGeneratedSheet: () {},
            onImportImageSequence: () => imageSequenceImports++,
            onImportLibraryImageSequence: () => librarySequenceImports++,
            onClearProject: () {},
            onTrackSelected: (_) {},
            onTrackAdded: () => addedTracks++,
            onTrackDuplicated: (trackId) => duplicatedTrackId = trackId,
            onTrackDeleted: (trackId) => deletedTrackId = trackId,
            onTrackMoved: (_, _) {},
            onTrackRenamed: (_, _) {},
            onProjectDefaultDelayChanged: (delayMs) =>
                changedProjectDelay = delayMs,
            onProjectPlaybackModeChanged: (_) {},
            onProjectLoopCountChanged: (loopCount) =>
                changedProjectLoopCount = loopCount,
            onProjectIncludeHiddenTracksChanged: (includeHiddenTracks) =>
                requestedProjectHiddenTracks = includeHiddenTracks,
            onTrackDelayChanged: (_, _) {},
            onTrackPlaybackModeChanged: (_, _) {},
            onTrackVisibilityChanged: (trackId, visible) {
              visibilityTrackId = trackId;
              requestedVisibility = visible;
            },
            onTrackLockChanged: (trackId, locked) {
              lockedTrackId = trackId;
              requestedLock = locked;
            },
            onFrameMoved: (_, _, _) {},
            onFrameDuplicated: (_, frameIndex) =>
                duplicatedFrameIndex = frameIndex,
            onBlankFrameInserted: (trackId, insertIndex) {
              blankInsertedTrackId = trackId;
              blankInsertIndex = insertIndex;
            },
            onImageFrameInserted: (trackId, insertIndex) {
              imageInsertedTrackId = trackId;
              imageInsertIndex = insertIndex;
            },
            onFrameDeleted: (_, frameIndex) => deletedFrameIndex = frameIndex,
            onFrameDelayChanged: (_, _, delayMs) => changedFrameDelay = delayMs,
            onFrameTransformChanged: (_, _, transform) =>
                changedTransform = transform,
            onFrameReplaced: (_, frameIndex) => replacedFrameIndex = frameIndex,
            onFrameCleared: (_, frameIndex) => clearedFrameIndex = frameIndex,
            onFramePixelated: (_, frameIndex, blockSize) {
              pixelatedFrameIndex = frameIndex;
              pixelatedBlockSize = blockSize;
            },
            onFrameAssetRebound: (_) {},
            onProjectAutoRepaired: () {},
            onExportProjectSpriteSheet: () => exportedSheets++,
            onExportProjectGif: () => exportedProjectGifs++,
            onExportProjectPngSequence: () => exportedProjectSequences++,
            onExportTrackGif: () => exportedGifs++,
            onExportTrackPngSequence: () => exportedSequences++,
            onExportSourceSpriteSheet: (_) {},
          ),
        ),
      ),
    );
    await _pumpBounded(tester);

    expect(find.text('动画工程'), findsWidgets);
    expect(find.text('工程控制'), findsOneWidget);
    expect(find.text('工程设置'), findsOneWidget);
    expect(find.text('轨道时间轴'), findsOneWidget);
    expect(find.text('序列帧时间轴'), findsOneWidget);
    expect(find.text('单帧变换'), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);
    expect(find.bySemanticsLabel('Main'), findsOneWidget);
    expect(find.bySemanticsLabel('当前帧 1 · 100ms'), findsOneWidget);
    await _pumpAsyncRender(tester);
    expect(
      find.bySemanticsLabel('动画工程预览 · 合成帧 1 / 2 · 100 ms'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, '导入本地图片序列'));
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, '从作品库导入序列'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '新建轨道'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '导出合成 Sprite Sheet'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '导出工程 GIF'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '导出工程 PNG 序列'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '导出当前轨道 GIF'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '导出 PNG 序列'));
    await tester.pump();

    expect(imageSequenceImports, 1);
    expect(librarySequenceImports, 1);
    expect(addedTracks, 1);
    expect(exportedSheets, 1);
    expect(exportedProjectGifs, 1);
    expect(exportedProjectSequences, 1);
    expect(exportedGifs, 1);
    expect(exportedSequences, 1);

    await tester.enterText(_textFieldWithLabel('工程默认帧时长'), '180');
    await tester.pump();
    await tester.enterText(_textFieldWithLabel('GIF 循环次数'), '2');
    await tester.pump();
    final includeHiddenTracksSwitch = find.byWidgetPredicate(
      (widget) =>
          widget is SwitchListTile &&
          widget.title is Text &&
          (widget.title as Text).data == '导出包含隐藏轨道',
    );
    await tester.ensureVisible(includeHiddenTracksSwitch);
    await tester.pump();
    await tester.tap(includeHiddenTracksSwitch);
    await tester.pump();

    expect(changedProjectDelay, 180);
    expect(changedProjectLoopCount, 2);
    expect(requestedProjectHiddenTracks, isTrue);

    await tester.tap(find.byTooltip('复制轨道').first);
    await tester.pump();
    await tester.tap(find.byTooltip('隐藏轨道').first);
    await tester.pump();
    await tester.tap(find.byTooltip('锁定轨道').first);
    await tester.pump();
    await tester.tap(find.byTooltip('删除轨道').first);
    await tester.pump();

    expect(duplicatedTrackId, 'track-main');
    expect(visibilityTrackId, 'track-main');
    expect(requestedVisibility, isFalse);
    expect(lockedTrackId, 'track-main');
    expect(requestedLock, isTrue);
    expect(deletedTrackId, 'track-main');

    await tester.enterText(_textFieldWithLabel('单帧时长'), '160');
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, '复制帧'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '复制帧'));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, '删除帧'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '删除帧'));
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('水平翻转'));
    await tester.pump();
    await tester.tap(find.byTooltip('水平翻转'));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, '替换帧'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '替换帧'));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, '插入空白帧'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '插入空白帧'));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, '插入图片帧'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '插入图片帧'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '清空帧'));
    await tester.pump();
    final pixelateMenu = tester.widget<PopupMenuButton<int>>(
      find.byWidgetPredicate(
        (widget) =>
            widget is PopupMenuButton<int> && widget.tooltip == '像素化当前帧',
      ),
    );
    final pixelateSemantics = tester.getSemantics(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '像素化当前帧',
      ),
    );
    expect(pixelateSemantics.flagsCollection.isButton, isTrue);
    expect(pixelateSemantics.flagsCollection.isEnabled, Tristate.isTrue);

    pixelateMenu.onSelected?.call(8);
    await tester.pump();

    expect(changedFrameDelay, 160);
    expect(duplicatedFrameIndex, 0);
    expect(deletedFrameIndex, 0);
    expect(changedTransform?.flipX, isTrue);
    expect(replacedFrameIndex, 0);
    expect(blankInsertedTrackId, 'track-main');
    expect(blankInsertIndex, 1);
    expect(imageInsertedTrackId, 'track-main');
    expect(imageInsertIndex, 1);
    expect(clearedFrameIndex, 0);
    expect(pixelatedFrameIndex, 0);
    expect(pixelatedBlockSize, 8);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('creation view exports generated sprite sheet before import', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final promptController = TextEditingController(text: 'walk cycle');
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    Uint8List? exportedBytes;
    addTearDown(promptController.dispose);
    addTearDown(negativePromptController.dispose);
    addTearDown(userController.dispose);

    await tester.pumpWidget(
      _workspaceApp(
        project: null,
        selectedTrackId: null,
        promptController: promptController,
        negativePromptController: negativePromptController,
        userController: userController,
        generatedImages: [GeneratedImage.bytes(_spriteSheetPng())],
        onExportSourceSpriteSheet: (bytes) => exportedBytes = bytes,
      ),
    );
    await _pumpBounded(tester);

    expect(find.text('创建动画工程'), findsOneWidget);
    expect(find.text('Sprite Sheet 来源预览'), findsNothing);
    await tester.tap(find.widgetWithText(OutlinedButton, '导出来源 Sprite Sheet'));
    await _pumpAsyncRender(tester);

    expect(exportedBytes, isNotNull);
    expect(exportedBytes, equals(_spriteSheetPng()));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('animation project preview reports render errors and can retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp(
        'animation_project_workspace_error_test_',
      ),
    ))!;
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final promptController = TextEditingController(text: 'walk cycle');
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    addTearDown(promptController.dispose);
    addTearDown(negativePromptController.dispose);
    addTearDown(userController.dispose);

    final missingFirst =
        '${tempDir.path}${Platform.pathSeparator}missing_first.png';
    final missingSecond =
        '${tempDir.path}${Platform.pathSeparator}missing_second.png';
    final unusedPath = (await tester.runAsync(
      () => _writePng(tempDir, 'unused.png', image_lib.ColorRgb8(0, 0, 255)),
    ))!;
    final missingProject = _projectWithTwoTracks(missingFirst, missingSecond)
        .copyWith(
          assets: [
            ..._projectWithTwoTracks(missingFirst, missingSecond).assets,
            FrameAsset(
              id: 'asset-unused',
              path: unusedPath,
              width: 4,
              height: 4,
              source: FrameAssetSource.importedFile,
            ),
          ],
        );
    String? reboundAssetId;
    var autoRepairs = 0;
    await tester.pumpWidget(
      _workspaceApp(
        project: missingProject,
        selectedTrackId: 'track-main',
        promptController: promptController,
        negativePromptController: negativePromptController,
        userController: userController,
        onFrameAssetRebound: (assetId) => reboundAssetId = assetId,
        onProjectAutoRepaired: () => autoRepairs++,
      ),
    );
    await _pumpAsyncRender(tester);
    await _pumpUntilFound(tester, find.text('缺失资源'));

    expect(find.text('缺失资源'), findsOneWidget);
    expect(find.textContaining('预览和导出会失败'), findsOneWidget);
    expect(find.text('可自动修复 1 项'), findsOneWidget);
    final repairButton = find.widgetWithText(OutlinedButton, '自动修复可处理项');
    await tester.ensureVisible(repairButton);
    await tester.pump();
    await tester.tap(repairButton);
    await tester.pump();
    expect(autoRepairs, 1);

    final rebindButton = find.widgetWithText(OutlinedButton, '重新绑定').first;
    await tester.ensureVisible(rebindButton);
    await tester.pump();
    await tester.tap(rebindButton);
    await tester.pump();

    expect(reboundAssetId, 'asset-first');
    expect(find.text('渲染失败'), findsOneWidget);
    expect(find.textContaining('动画帧文件不存在'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '重新渲染'), findsOneWidget);

    final retryButton = find.widgetWithText(FilledButton, '重新渲染');
    await tester.ensureVisible(retryButton);
    await tester.pump();
    await tester.tap(retryButton);
    await _pumpAsyncRender(tester);

    expect(find.text('渲染失败'), findsOneWidget);
    expect(find.textContaining('动画帧文件不存在'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('busy animation project actions expose disabled reasons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp(
        'animation_project_workspace_busy_test_',
      ),
    ))!;
    addTearDown(() async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final firstFramePath = (await tester.runAsync(
      () => _writePng(tempDir, 'first.png', image_lib.ColorRgb8(255, 0, 0)),
    ))!;
    final secondFramePath = (await tester.runAsync(
      () => _writePng(tempDir, 'second.png', image_lib.ColorRgb8(0, 255, 0)),
    ))!;
    final project = _projectWithTwoTracks(firstFramePath, secondFramePath);
    final promptController = TextEditingController(text: 'walk cycle');
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    addTearDown(promptController.dispose);
    addTearDown(negativePromptController.dispose);
    addTearDown(userController.dispose);

    await tester.pumpWidget(
      _workspaceApp(
        project: project,
        selectedTrackId: 'track-main',
        promptController: promptController,
        negativePromptController: negativePromptController,
        userController: userController,
        isProjectBusy: true,
      ),
    );
    await _pumpBounded(tester);

    final exportSemantics = tester.getSemantics(
      find
          .byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.label == '导出工程 GIF',
          )
          .first,
    );
    expect(exportSemantics.value, '当前工程正在处理任务，完成后可继续操作');
    expect(exportSemantics.flagsCollection.isButton, isTrue);
    expect(exportSemantics.flagsCollection.isEnabled, Tristate.isFalse);

    final importSemantics = tester.getSemantics(
      find
          .byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.label == '从作品库导入序列',
          )
          .first,
    );
    expect(importSemantics.value, '当前工程正在处理任务，完成后可继续操作');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

AnimationProject _projectWithTwoTracks(
  String firstFramePath,
  String secondFramePath,
) {
  final createdAt = DateTime.parse('2026-05-17T08:00:00Z');
  const firstAsset = 'asset-first';
  const secondAsset = 'asset-second';
  return AnimationProject(
    id: 'project-workspace',
    title: 'Workspace Smoke',
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
              FrameRef(assetId: firstAsset, delayMs: 100),
              FrameRef(assetId: secondAsset, delayMs: 120),
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
        defaultDelayMs: 100,
        playbackMode: AnimationPlaybackMode.normal,
        clips: [
          TimelineClip(
            id: 'clip-alt',
            name: 'Alt Loop',
            startFrame: 0,
            frames: [FrameRef(assetId: secondAsset, delayMs: 100)],
            loop: true,
          ),
        ],
      ),
    ],
    assets: [
      FrameAsset(
        id: firstAsset,
        path: firstFramePath,
        width: 4,
        height: 4,
        source: FrameAssetSource.importedFile,
        sourceFrameIndex: 0,
      ),
      FrameAsset(
        id: secondAsset,
        path: secondFramePath,
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

Future<String> _writePng(
  Directory directory,
  String name,
  image_lib.Color color,
) async {
  final image = image_lib.Image(width: 4, height: 4);
  image_lib.fill(image, color: color);
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(Uint8List.fromList(image_lib.encodePng(image)));
  return file.path;
}

Uint8List _spriteSheetPng() {
  final image = image_lib.Image(width: 4, height: 4);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final isRight = x >= 2;
      final isBottom = y >= 2;
      image.setPixelRgb(
        x,
        y,
        isRight ? 0 : 255,
        isBottom ? 0 : 255,
        isRight && isBottom ? 255 : 0,
      );
    }
  }
  return Uint8List.fromList(image_lib.encodePng(image));
}

Finder _textFieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
}

Future<void> _pumpBounded(WidgetTester tester, {int maxPumps = 12}) async {
  await tester.pump();
  for (var index = 0; index < maxPumps; index++) {
    if (!tester.binding.hasScheduledFrame) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpAsyncRender(WidgetTester tester) async {
  await _pumpBounded(tester);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await _pumpBounded(tester);
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
}) async {
  for (var index = 0; index < maxPumps; index++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _workspaceApp({
  required AnimationProject? project,
  required String? selectedTrackId,
  required TextEditingController promptController,
  required TextEditingController negativePromptController,
  required TextEditingController userController,
  ValueChanged<String>? onFrameAssetRebound,
  void Function(String trackId, int frameIndex)? onFrameReplaced,
  void Function(String trackId, int insertIndex)? onBlankFrameInserted,
  void Function(String trackId, int insertIndex)? onImageFrameInserted,
  void Function(String trackId, int frameIndex)? onFrameCleared,
  void Function(String trackId, int frameIndex, int blockSize)?
  onFramePixelated,
  VoidCallback? onProjectAutoRepaired,
  List<GeneratedImage> generatedImages = const [],
  ValueChanged<Uint8List>? onExportSourceSpriteSheet,
  bool isProjectBusy = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AnimationProjectWorkspace(
        apiConfigs: [ApiConfig.defaults()],
        selectedApiConfig: ApiConfig.defaults(),
        promptController: promptController,
        negativePromptController: negativePromptController,
        size: '1024x1024',
        rows: 2,
        columns: 2,
        gridSpec: const SpriteSheetGridSpec(rows: 2, columns: 2),
        templateImagePath: null,
        advancedSettings: const ImageAdvancedSettings(),
        userController: userController,
        isGenerating: false,
        errorMessage: null,
        debugRecord: null,
        generatedImages: generatedImages,
        project: project,
        selectedTrackId: selectedTrackId,
        isProjectBusy: isProjectBusy,
        projectErrorMessage: null,
        enablePreviewPlayback: false,
        onApiConfigChanged: (_) {},
        onOpenApiSettings: () {},
        onSizeChanged: (_) {},
        onRowsChanged: (_) {},
        onColumnsChanged: (_) {},
        onGridSpecChanged: (_) {},
        onAdvancedSettingsChanged: (_) {},
        onPickTemplateImage: () {},
        onClearTemplateImage: () {},
        onGenerate: () {},
        onImportGeneratedSheet: () {},
        onImportImageSequence: () {},
        onImportLibraryImageSequence: () {},
        onClearProject: () {},
        onTrackSelected: (_) {},
        onTrackAdded: () {},
        onTrackDuplicated: (_) {},
        onTrackDeleted: (_) {},
        onTrackMoved: (_, _) {},
        onTrackRenamed: (_, _) {},
        onProjectDefaultDelayChanged: (_) {},
        onProjectPlaybackModeChanged: (_) {},
        onProjectLoopCountChanged: (_) {},
        onProjectIncludeHiddenTracksChanged: (_) {},
        onTrackDelayChanged: (_, _) {},
        onTrackPlaybackModeChanged: (_, _) {},
        onTrackVisibilityChanged: (_, _) {},
        onTrackLockChanged: (_, _) {},
        onFrameMoved: (_, _, _) {},
        onFrameDuplicated: (_, _) {},
        onBlankFrameInserted: onBlankFrameInserted ?? (_, _) {},
        onImageFrameInserted: onImageFrameInserted ?? (_, _) {},
        onFrameDeleted: (_, _) {},
        onFrameDelayChanged: (_, _, _) {},
        onFrameTransformChanged: (_, _, _) {},
        onFrameReplaced: onFrameReplaced ?? (_, _) {},
        onFrameCleared: onFrameCleared ?? (_, _) {},
        onFramePixelated: onFramePixelated ?? (_, _, _) {},
        onFrameAssetRebound: onFrameAssetRebound ?? (_) {},
        onProjectAutoRepaired: onProjectAutoRepaired ?? () {},
        onExportProjectSpriteSheet: () {},
        onExportProjectGif: () {},
        onExportProjectPngSequence: () {},
        onExportTrackGif: () {},
        onExportTrackPngSequence: () {},
        onExportSourceSpriteSheet: onExportSourceSpriteSheet ?? (_) {},
      ),
    ),
  );
}
