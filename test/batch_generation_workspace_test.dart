import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:feather_canvas_studio/src/state/batch_generation_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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
