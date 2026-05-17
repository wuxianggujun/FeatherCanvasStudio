import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'batch queue uses a bounded scroll list without queued previews',
    (tester) async {
      const config = ApiConfig(
        id: 'config',
        name: 'Config',
        baseUrl: 'https://example.com/v1',
        apiKey: 'key',
        model: 'gpt-image-2',
      );
      final jobs = [
        for (var index = 0; index < 24; index++)
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
      addTearDown(() {
        promptController.dispose();
        negativePromptController.dispose();
        userController.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
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
                jobs: jobs,
                targetCount: 100,
                requestCount: 4,
                isRunning: false,
                isPausing: false,
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

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('24 个任务'), findsOneWidget);
      expect(find.text('当前表单拆分入队'), findsNothing);
      expect(find.text('等待 1'), findsNothing);
      expect(find.byType(ListView), findsOneWidget);

      final listSize = tester.getSize(find.byType(ListView));
      expect(listSize.height, lessThanOrEqualTo(320));
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
    var retriedAll = false;
    BatchGenerationJob? retriedJob;
    addTearDown(() {
      promptController.dispose();
      negativePromptController.dispose();
      userController.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 800,
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
              jobs: jobs,
              targetCount: 2,
              requestCount: 1,
              isRunning: false,
              isPausing: false,
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
}
