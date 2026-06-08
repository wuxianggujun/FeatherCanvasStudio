import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Tristate;

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:feather_canvas_studio/src/state/batch_generation_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

BatchGenerationNotifier _seededNotifier({
  List<BatchGenerationJob> jobs = const [],
  int targetCount = 1,
  int requestCount = 1,
  bool isRunning = false,
  bool pauseAfterCurrent = false,
}) {
  final notifier = BatchGenerationNotifier();
  notifier.jobs = jobs;
  notifier.targetCount = targetCount;
  notifier.requestCount = requestCount;
  notifier.isRunning = isRunning;
  notifier.pauseAfterCurrent = pauseAfterCurrent;
  return notifier;
}

void main() {
  test('summarizes batch queue jobs in one pass', () {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    final debugRecord = ImageRequestDebugRecord.fromRequest(
      const OpenAIImageRequest(
        baseUrl: 'https://example.com/v1',
        apiKey: 'key',
        prompt: 'running prompt',
        negativePrompt: '',
        model: 'gpt-image-2',
        size: '1536x1024',
        imageCount: 2,
      ),
    );
    final jobs = [
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'queued prompt',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 1,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ),
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'running prompt',
        negativePrompt: '',
        size: '1536x1024',
        imageCount: 2,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ).copyWith(
        status: BatchGenerationJobStatus.running,
        debugRecord: debugRecord,
      ),
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'done prompt',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 1,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ).copyWith(
        status: BatchGenerationJobStatus.succeeded,
        resultImages: [GeneratedImage.bytes(Uint8List(4))],
      ),
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'failed prompt',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 1,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ).copyWith(status: BatchGenerationJobStatus.failed),
    ];

    final summary = summarizeBatchGenerationJobs(
      jobs,
      fallbackSize: '1024x1024',
    );

    expect(summary.queuedCount, 1);
    expect(summary.runningCount, 1);
    expect(summary.finishedCount, 2);
    expect(summary.failedCount, 1);
    expect(summary.previewImages, hasLength(1));
    expect(summary.targetImageCount, 3);
    expect(summary.previewAspectRatio, imageAspectRatioFromSize('1536x1024'));
    expect(summary.latestDebugRecord, same(debugRecord));
  });

  test('caps batch preview images while preserving target count', () {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    final jobs = [
      for (var index = 0; index < 180; index++)
        BatchGenerationJob.create(
          apiConfig: config,
          prompt: 'done prompt $index',
          negativePrompt: '',
          size: '1024x1024',
          imageCount: 1,
          advancedSettings: const ImageAdvancedSettings(),
          user: '',
        ).copyWith(
          status: BatchGenerationJobStatus.succeeded,
          resultImages: [GeneratedImage.bytes(Uint8List(4))],
        ),
    ];

    final summary = summarizeBatchGenerationJobs(
      jobs,
      fallbackSize: '1024x1024',
    );

    expect(summary.finishedCount, 180);
    expect(summary.previewImages, hasLength(120));
    expect(summary.targetImageCount, 120);
  });

  testWidgets('batch workspace shows result accounting and preview sources', (
    tester,
  ) async {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    final imageBytes = base64Decode(_onePixelPngBase64);
    final jobs = [
      for (var index = 0; index < 121; index++)
        BatchGenerationJob.create(
          apiConfig: config,
          prompt: 'done prompt $index',
          negativePrompt: '',
          size: '1024x1024',
          imageCount: 1,
          advancedSettings: const ImageAdvancedSettings(),
          user: '',
        ).copyWith(
          status: BatchGenerationJobStatus.succeeded,
          resultImages: [GeneratedImage.bytes(Uint8List.fromList(imageBytes))],
        ),
    ];
    final promptController = TextEditingController();
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    final notifier = _seededNotifier(jobs: jobs);
    addTearDown(() {
      promptController.dispose();
      negativePromptController.dispose();
      userController.dispose();
      notifier.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 900,
            child: ChangeNotifierProvider<BatchGenerationNotifier>.value(
              value: notifier,
              child: BatchGenerationWorkspace(
                promptController: promptController,
                negativePromptController: negativePromptController,
                userController: userController,
                apiConfigs: const [config],
                selectedApiConfig: config,
                selectedApiConfigId: config.id,
                providerKind: config.providerKind,
                imageSizeCapabilityOverride: config.imageSizeCapabilityOverride,
                size: '1024x1024',
                advancedSettings: const ImageAdvancedSettings(),
                onApiConfigChanged: (_) {},
                onOpenApiSettings: () {},
                onSizeChanged: (_) {},
                onAdvancedSettingsChanged: (_) {},
                onTargetCountChanged: (_) {},
                onRequestCountChanged: (_) {},
                onAddPrompts: () {},
                onStart: () {},
                onPause: () {},
                onResume: () {},
                onCancelQueued: () {},
                onRetryFailed: () {},
                onRemoveJob: (_) {},
                onRetryJob: (_) {},
                onClearFinished: () {},
                onCopyImage: (_, _) {},
                onExportImage: (_, _) {},
                onMakeBackgroundTransparent: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('批量结果统计'), findsOneWidget);
    expect(find.text('总批次'), findsOneWidget);
    expect(find.text('请求图片'), findsOneWidget);
    expect(find.text('成功返回'), findsOneWidget);
    expect(find.text('当前预览'), findsOneWidget);
    expect(find.text('失败批次'), findsOneWidget);
    expect(find.text('121'), findsNWidgets(3));
    expect(find.text('120'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('请求 1 张，实际返回 1 张'), findsWidgets);
    expect(find.text('任务 1 · 第 1/1 张'), findsOneWidget);
    expect(find.text('已成功返回 121 张，当前仅预览 120 张，还有 1 张未在预览区显示。'), findsWidgets);
  });

  testWidgets('batch job row opens returned images for that batch', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1400, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    final imageBytes = base64Decode(_onePixelPngBase64);
    final jobs = [
      for (var batchIndex = 1; batchIndex <= 21; batchIndex++)
        BatchGenerationJob.create(
          apiConfig: config,
          prompt: 'batch prompt $batchIndex',
          negativePrompt: '',
          size: '1024x1024',
          imageCount: 4,
          advancedSettings: const ImageAdvancedSettings(),
          user: '',
          batchIndex: batchIndex,
          batchTotal: 21,
        ).copyWith(
          status: BatchGenerationJobStatus.succeeded,
          resultImages: [
            for (var imageIndex = 0; imageIndex < 4; imageIndex++)
              GeneratedImage.bytes(Uint8List.fromList(imageBytes)),
          ],
        ),
    ];
    final promptController = TextEditingController();
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    final notifier = _seededNotifier(jobs: jobs);
    int? copiedIndex;
    GeneratedImage? copiedImage;
    int? exportedIndex;
    GeneratedImage? exportedImage;
    addTearDown(() {
      promptController.dispose();
      negativePromptController.dispose();
      userController.dispose();
      notifier.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 900,
            child: ChangeNotifierProvider<BatchGenerationNotifier>.value(
              value: notifier,
              child: BatchGenerationWorkspace(
                promptController: promptController,
                negativePromptController: negativePromptController,
                userController: userController,
                apiConfigs: const [config],
                selectedApiConfig: config,
                selectedApiConfigId: config.id,
                providerKind: config.providerKind,
                imageSizeCapabilityOverride: config.imageSizeCapabilityOverride,
                size: '1024x1024',
                advancedSettings: const ImageAdvancedSettings(),
                onApiConfigChanged: (_) {},
                onOpenApiSettings: () {},
                onSizeChanged: (_) {},
                onAdvancedSettingsChanged: (_) {},
                onTargetCountChanged: (_) {},
                onRequestCountChanged: (_) {},
                onAddPrompts: () {},
                onStart: () {},
                onPause: () {},
                onResume: () {},
                onCancelQueued: () {},
                onRetryFailed: () {},
                onRemoveJob: (_) {},
                onRetryJob: (_) {},
                onClearFinished: () {},
                onCopyImage: (index, image) {
                  copiedIndex = index;
                  copiedImage = image;
                },
                onExportImage: (index, image) {
                  exportedIndex = index;
                  exportedImage = image;
                },
                onMakeBackgroundTransparent: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byTooltip('查看第 1/21 批返回的 4 张图片'), findsOneWidget);
    expect(find.byTooltip('查看任务 1 返回的 4 张图片'), findsNothing);

    final batchJobScrollable = find.descendant(
      of: find.byKey(const ValueKey('batch-job-list')),
      matching: find.byType(Scrollable),
    );
    expect(batchJobScrollable, findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('batch prompt 21'),
      600,
      scrollable: batchJobScrollable,
    );
    await tester.pump();

    await tester.tap(find.byTooltip('查看第 21/21 批返回的 4 张图片'));
    await tester.pumpAndSettle();

    expect(find.text('第 21/21 批 · 第 1/4 张'), findsWidgets);
    expect(find.text('第 21/21 批 · 第 2/4 张'), findsNothing);

    await tester.tap(find.byTooltip('下一张'));
    await tester.pumpAndSettle();

    expect(find.text('第 21/21 批 · 第 1/4 张'), findsNothing);
    expect(find.text('第 21/21 批 · 第 2/4 张'), findsWidgets);

    final dialog = find.byType(Dialog);
    await tester.tap(
      find.descendant(of: dialog, matching: find.byTooltip('复制图片')),
    );
    await tester.tap(
      find.descendant(of: dialog, matching: find.byTooltip('导出图片')),
    );
    await tester.pump();

    expect(copiedIndex, 81);
    expect(copiedImage, same(jobs.last.resultImages[1]));
    expect(exportedIndex, 81);
    expect(exportedImage, same(jobs.last.resultImages[1]));
  });

  testWidgets('batch job filters expose attention and returned jobs', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1400, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    final jobs = [
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'full success prompt',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 4,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ).copyWith(
        status: BatchGenerationJobStatus.succeeded,
        resultImages: [
          for (var index = 0; index < 4; index++)
            GeneratedImage.bytes(Uint8List(4)),
        ],
      ),
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'under returned prompt',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 4,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ).copyWith(
        status: BatchGenerationJobStatus.succeeded,
        resultImages: [
          for (var index = 0; index < 2; index++)
            GeneratedImage.bytes(Uint8List(4)),
        ],
      ),
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'failed prompt',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 4,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ).copyWith(status: BatchGenerationJobStatus.failed),
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'skipped prompt',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 4,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ).copyWith(status: BatchGenerationJobStatus.skipped),
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'queued prompt',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 4,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ),
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'running prompt',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 4,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ).copyWith(status: BatchGenerationJobStatus.running),
    ];
    final promptController = TextEditingController();
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    final notifier = _seededNotifier(jobs: jobs);
    addTearDown(() {
      promptController.dispose();
      negativePromptController.dispose();
      userController.dispose();
      notifier.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 900,
            child: ChangeNotifierProvider<BatchGenerationNotifier>.value(
              value: notifier,
              child: BatchGenerationWorkspace(
                promptController: promptController,
                negativePromptController: negativePromptController,
                userController: userController,
                apiConfigs: const [config],
                selectedApiConfig: config,
                selectedApiConfigId: config.id,
                providerKind: config.providerKind,
                imageSizeCapabilityOverride: config.imageSizeCapabilityOverride,
                size: '1024x1024',
                advancedSettings: const ImageAdvancedSettings(),
                onApiConfigChanged: (_) {},
                onOpenApiSettings: () {},
                onSizeChanged: (_) {},
                onAdvancedSettingsChanged: (_) {},
                onTargetCountChanged: (_) {},
                onRequestCountChanged: (_) {},
                onAddPrompts: () {},
                onStart: () {},
                onPause: () {},
                onResume: () {},
                onCancelQueued: () {},
                onRetryFailed: () {},
                onRemoveJob: (_) {},
                onRetryJob: (_) {},
                onClearFinished: () {},
                onCopyImage: (_, _) {},
                onExportImage: (_, _) {},
                onMakeBackgroundTransparent: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('全部 6'), findsOneWidget);
    expect(find.text('需关注 3'), findsOneWidget);
    expect(find.text('有返回 2'), findsOneWidget);
    expect(find.text('6 个任务'), findsOneWidget);
    expect(find.textContaining('少图完成'), findsOneWidget);
    expect(find.text('需关注：少返回 2 张'), findsOneWidget);

    await tester.tap(find.text('需关注 3'));
    await tester.pumpAndSettle();

    expect(find.text('显示 3/6 个任务'), findsOneWidget);
    expect(find.text('full success prompt'), findsNothing);
    expect(find.text('under returned prompt'), findsOneWidget);
    expect(find.text('failed prompt'), findsOneWidget);
    expect(find.text('queued prompt'), findsNothing);
    expect(find.text('running prompt'), findsNothing);
    expect(find.text('需关注：少返回 2 张'), findsOneWidget);
    expect(find.text('需关注：任务失败，可重试'), findsOneWidget);

    final batchJobScrollable = find.descendant(
      of: find.byKey(const ValueKey('batch-job-list')),
      matching: find.byType(Scrollable),
    );
    expect(batchJobScrollable, findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('skipped prompt'),
      240,
      scrollable: batchJobScrollable,
    );
    await tester.pump();

    expect(find.text('skipped prompt'), findsOneWidget);
    expect(find.text('需关注：任务已取消'), findsOneWidget);

    await tester.tap(find.text('有返回 2'));
    await tester.pumpAndSettle();

    expect(find.text('显示 2/6 个任务'), findsOneWidget);
    expect(find.text('full success prompt'), findsOneWidget);
    expect(find.text('under returned prompt'), findsOneWidget);
    expect(find.text('failed prompt'), findsNothing);
    expect(find.text('skipped prompt'), findsNothing);
    expect(find.text('queued prompt'), findsNothing);
    expect(find.text('running prompt'), findsNothing);
  });

  testWidgets('batch queue action buttons expose disabled reasons', (
    tester,
  ) async {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    final promptController = TextEditingController();
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    final notifier = _seededNotifier(isRunning: true);
    addTearDown(() {
      promptController.dispose();
      negativePromptController.dispose();
      userController.dispose();
      notifier.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 900,
            child: ChangeNotifierProvider<BatchGenerationNotifier>.value(
              value: notifier,
              child: BatchGenerationWorkspace(
                promptController: promptController,
                negativePromptController: negativePromptController,
                userController: userController,
                apiConfigs: const [config],
                selectedApiConfig: config,
                selectedApiConfigId: config.id,
                providerKind: config.providerKind,
                imageSizeCapabilityOverride: config.imageSizeCapabilityOverride,
                size: '1024x1024',
                advancedSettings: const ImageAdvancedSettings(),
                onApiConfigChanged: (_) {},
                onOpenApiSettings: () {},
                onSizeChanged: (_) {},
                onAdvancedSettingsChanged: (_) {},
                onTargetCountChanged: (_) {},
                onRequestCountChanged: (_) {},
                onAddPrompts: () {},
                onStart: () {},
                onPause: () {},
                onResume: () {},
                onCancelQueued: () {},
                onRetryFailed: () {},
                onRemoveJob: (_) {},
                onRetryJob: (_) {},
                onClearFinished: () {},
                onCopyImage: (_, _) {},
                onExportImage: (_, _) {},
                onMakeBackgroundTransparent: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final addPromptsSemantics = tester.getSemantics(
      _semanticsWithLabel('按行拆分入队').first,
    );
    expect(addPromptsSemantics.value, '队列运行中，当前不能执行此操作');
    expect(addPromptsSemantics.flagsCollection.isButton, isTrue);
    expect(addPromptsSemantics.flagsCollection.isEnabled, Tristate.isFalse);

    final retrySemantics = tester.getSemantics(
      _semanticsWithLabel('重试失败任务').first,
    );
    expect(retrySemantics.value, '队列运行中，当前不能执行此操作');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('batch queue exposes empty and error state semantics', (
    tester,
  ) async {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    final promptController = TextEditingController();
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    final emptyNotifier = _seededNotifier();
    addTearDown(() {
      promptController.dispose();
      negativePromptController.dispose();
      userController.dispose();
      emptyNotifier.dispose();
    });

    Widget workspace(BatchGenerationNotifier notifier) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 800,
            child: ChangeNotifierProvider<BatchGenerationNotifier>.value(
              value: notifier,
              child: BatchGenerationWorkspace(
                promptController: promptController,
                negativePromptController: negativePromptController,
                userController: userController,
                apiConfigs: const [config],
                selectedApiConfig: config,
                selectedApiConfigId: config.id,
                providerKind: config.providerKind,
                imageSizeCapabilityOverride: config.imageSizeCapabilityOverride,
                size: '1024x1024',
                advancedSettings: const ImageAdvancedSettings(),
                onApiConfigChanged: (_) {},
                onOpenApiSettings: () {},
                onSizeChanged: (_) {},
                onAdvancedSettingsChanged: (_) {},
                onTargetCountChanged: (_) {},
                onRequestCountChanged: (_) {},
                onAddPrompts: () {},
                onStart: () {},
                onPause: () {},
                onResume: () {},
                onCancelQueued: () {},
                onRetryFailed: () {},
                onRemoveJob: (_) {},
                onRetryJob: (_) {},
                onClearFinished: () {},
                onCopyImage: (_, _) {},
                onExportImage: (_, _) {},
                onMakeBackgroundTransparent: (_, _) {},
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(workspace(emptyNotifier));
    await tester.pump(const Duration(milliseconds: 200));

    expect(_semanticsWithLabel('还没有任务。把提示词加入队列后，会按目标数量拆分并串行生成。'), findsWidgets);

    final failedNotifier = _seededNotifier(
      jobs: [
        BatchGenerationJob.create(
          apiConfig: config,
          prompt: 'failed prompt',
          negativePrompt: '',
          size: '1024x1024',
          imageCount: 1,
          advancedSettings: const ImageAdvancedSettings(),
          user: '',
        ).copyWith(
          status: BatchGenerationJobStatus.failed,
          errorMessage: 'network error',
        ),
      ],
    );
    addTearDown(failedNotifier.dispose);

    await tester.pumpWidget(workspace(failedNotifier));
    await tester.pump(const Duration(milliseconds: 200));

    expect(_semanticsWithLabel('network error'), findsWidgets);
  });

  testWidgets(
    'batch queue expands within the preview pane without queued previews',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1800, 1000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const config = ApiConfig(
        id: 'config',
        name: 'Config',
        baseUrl: 'https://example.com/v1',
        apiKey: 'key',
        model: 'gpt-image-2',
      );
      final jobs = [
        for (var index = 0; index < 120; index++)
          BatchGenerationJob.create(
            apiConfig: config,
            prompt: 'batch prompt $index',
            negativePrompt: '',
            size: '1024x1024',
            imageCount: 4,
            advancedSettings: const ImageAdvancedSettings(),
            user: '',
          ),
      ];
      final promptController = TextEditingController();
      final negativePromptController = TextEditingController();
      final userController = TextEditingController();
      final notifier = _seededNotifier(
        jobs: jobs,
        targetCount: 100,
        requestCount: 4,
      );
      addTearDown(() {
        promptController.dispose();
        negativePromptController.dispose();
        userController.dispose();
        notifier.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1600,
              height: 800,
              child: ChangeNotifierProvider<BatchGenerationNotifier>.value(
                value: notifier,
                child: BatchGenerationWorkspace(
                  promptController: promptController,
                  negativePromptController: negativePromptController,
                  userController: userController,
                  apiConfigs: const [config],
                  selectedApiConfig: config,
                  selectedApiConfigId: config.id,
                  providerKind: config.providerKind,
                  imageSizeCapabilityOverride:
                      config.imageSizeCapabilityOverride,
                  size: '1024x1024',
                  advancedSettings: const ImageAdvancedSettings(),
                  onApiConfigChanged: (_) {},
                  onOpenApiSettings: () {},
                  onSizeChanged: (_) {},
                  onAdvancedSettingsChanged: (_) {},
                  onTargetCountChanged: (_) {},
                  onRequestCountChanged: (_) {},
                  onAddPrompts: () {},
                  onStart: () {},
                  onPause: () {},
                  onResume: () {},
                  onCancelQueued: () {},
                  onRetryFailed: () {},
                  onRemoveJob: (_) {},
                  onRetryJob: (_) {},
                  onClearFinished: () {},
                  onCopyImage: (_, _) {},
                  onExportImage: (_, _) {},
                  onMakeBackgroundTransparent: (_, _) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('120 个任务'), findsOneWidget);
      expect(find.text('当前表单拆分入队'), findsNothing);
      expect(find.text('等待 1'), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('batch prompt 0'), findsOneWidget);
      expect(find.text('batch prompt 119'), findsNothing);

      final listSize = tester.getSize(find.byType(ListView));
      expect(listSize.height, greaterThan(320));
    },
  );

  testWidgets('batch queue exposes retry actions for failed jobs', (
    tester,
  ) async {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    final jobs = [
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'failed prompt 1',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 1,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ).copyWith(
        status: BatchGenerationJobStatus.failed,
        errorMessage: 'network error',
      ),
      BatchGenerationJob.create(
        apiConfig: config,
        prompt: 'failed prompt 2',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 1,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      ).copyWith(
        status: BatchGenerationJobStatus.failed,
        errorMessage: 'rate limited',
      ),
    ];
    final promptController = TextEditingController();
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    final notifier = _seededNotifier(
      jobs: jobs,
      targetCount: 2,
      requestCount: 1,
    );
    var retriedAll = false;
    BatchGenerationJob? retriedJob;
    addTearDown(() {
      promptController.dispose();
      negativePromptController.dispose();
      userController.dispose();
      notifier.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 800,
            child: ChangeNotifierProvider<BatchGenerationNotifier>.value(
              value: notifier,
              child: BatchGenerationWorkspace(
                promptController: promptController,
                negativePromptController: negativePromptController,
                userController: userController,
                apiConfigs: const [config],
                selectedApiConfig: config,
                selectedApiConfigId: config.id,
                providerKind: config.providerKind,
                imageSizeCapabilityOverride: config.imageSizeCapabilityOverride,
                size: '1024x1024',
                advancedSettings: const ImageAdvancedSettings(),
                onApiConfigChanged: (_) {},
                onOpenApiSettings: () {},
                onSizeChanged: (_) {},
                onAdvancedSettingsChanged: (_) {},
                onTargetCountChanged: (_) {},
                onRequestCountChanged: (_) {},
                onAddPrompts: () {},
                onStart: () {},
                onPause: () {},
                onResume: () {},
                onCancelQueued: () {},
                onRetryFailed: () => retriedAll = true,
                onRemoveJob: (_) {},
                onRetryJob: (job) => retriedJob = job,
                onClearFinished: () {},
                onCopyImage: (_, _) {},
                onExportImage: (_, _) {},
                onMakeBackgroundTransparent: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('重试失败任务 (2)'), findsOneWidget);
    expect(find.byTooltip('重试任务'), findsNWidgets(2));

    await tester.ensureVisible(find.text('重试失败任务 (2)'));
    await tester.pump();
    await tester.tap(find.text('重试失败任务 (2)'));
    await tester.pump();

    expect(retriedAll, isTrue);

    await tester.tap(find.byTooltip('重试任务').first);
    await tester.pump();

    expect(retriedJob?.prompt, 'failed prompt 1');
  });

  testWidgets('running batch queue disables configuration inputs', (
    tester,
  ) async {
    const firstConfig = ApiConfig(
      id: 'config-1',
      name: 'Config 1',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    const secondConfig = ApiConfig(
      id: 'config-2',
      name: 'Config 2',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    final promptController = TextEditingController();
    final negativePromptController = TextEditingController();
    final userController = TextEditingController(text: 'locked-user');
    final notifier = _seededNotifier(
      jobs: const [],
      targetCount: 2,
      requestCount: 1,
      isRunning: true,
    );
    var apiConfigChanges = 0;
    var sizeChanges = 0;
    var advancedChanges = 0;
    addTearDown(() {
      promptController.dispose();
      negativePromptController.dispose();
      userController.dispose();
      notifier.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 900,
            child: ChangeNotifierProvider<BatchGenerationNotifier>.value(
              value: notifier,
              child: BatchGenerationWorkspace(
                promptController: promptController,
                negativePromptController: negativePromptController,
                userController: userController,
                apiConfigs: const [firstConfig, secondConfig],
                selectedApiConfig: firstConfig,
                selectedApiConfigId: firstConfig.id,
                providerKind: firstConfig.providerKind,
                imageSizeCapabilityOverride:
                    firstConfig.imageSizeCapabilityOverride,
                size: '1024x1024',
                advancedSettings: const ImageAdvancedSettings(),
                onApiConfigChanged: (_) => apiConfigChanges++,
                onOpenApiSettings: () {},
                onSizeChanged: (_) => sizeChanges++,
                onAdvancedSettingsChanged: (_) => advancedChanges++,
                onTargetCountChanged: (_) {},
                onRequestCountChanged: (_) {},
                onAddPrompts: () {},
                onStart: () {},
                onPause: () {},
                onResume: () {},
                onCancelQueued: () {},
                onRetryFailed: () {},
                onRemoveJob: (_) {},
                onRetryJob: (_) {},
                onClearFinished: () {},
                onCopyImage: (_, _) {},
                onExportImage: (_, _) {},
                onMakeBackgroundTransparent: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.ensureVisible(find.text('高级输出参数'));
    await tester.tap(find.text('高级输出参数'));
    await tester.pump(const Duration(milliseconds: 200));

    final disabledDropdowns = tester.widgetList<DropdownButtonFormField>(
      find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
    );
    expect(disabledDropdowns.length, greaterThanOrEqualTo(5));
    expect(
      disabledDropdowns.every((dropdown) => dropdown.onChanged == null),
      isTrue,
    );

    final userField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == '最终用户 ID',
      ),
    );
    expect(userField.enabled, isFalse);
    expect(apiConfigChanges, 0);
    expect(sizeChanges, 0);
    expect(advancedChanges, 0);
  });
}

Finder _semanticsWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
  );
}
