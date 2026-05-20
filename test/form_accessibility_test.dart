import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('api settings panel exposes labels for form controls', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 1100)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final nameController = TextEditingController(text: '默认配置');
    final baseUrlController = TextEditingController(
      text: 'https://api.openai.com/v1',
    );
    final apiKeyController = TextEditingController(text: 'sk-test');
    final modelController = TextEditingController(text: 'gpt-image-2');
    final timeoutController = TextEditingController(text: '480');
    addTearDown(nameController.dispose);
    addTearDown(baseUrlController.dispose);
    addTearDown(apiKeyController.dispose);
    addTearDown(modelController.dispose);
    addTearDown(timeoutController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 760,
            child: ApiSettingsPanel(
              apiConfigs: const [
                ApiConfig(
                  id: 'default',
                  name: '默认配置',
                  baseUrl: 'https://api.openai.com/v1',
                  apiKey: '',
                  model: 'gpt-image-2',
                  providerKind: ApiProviderKind.official,
                ),
              ],
              selectedApiConfigId: 'default',
              saveStatus: ApiConfigSaveStatus.saved,
              saveErrorMessage: null,
              isTestingApiConfig: false,
              apiTestDebugRecord: null,
              nameController: nameController,
              baseUrlController: baseUrlController,
              apiKeyController: apiKeyController,
              modelController: modelController,
              timeoutController: timeoutController,
              providerKind: ApiProviderKind.official,
              imageSizeCapabilityOverride: ImageSizeCapabilityOverride.auto,
              showApiKey: false,
              availableModels: const [ApiModelInfo(id: 'gpt-image-2')],
              isFetchingModels: false,
              modelFetchErrorMessage: null,
              modelFetchedAt: DateTime(2026, 5, 19, 10, 30),
              onApiConfigChanged: (_) {},
              onAddApiConfig: () {},
              onDeleteApiConfig: () {},
              onSaveApiConfig: () {},
              onTestApiConfig: () {},
              onBasicTestApiConfig: () {},
              onFetchModels: () {},
              onModelSelected: (_) {},
              onProviderKindChanged: (_) {},
              onImageSizeCapabilityOverrideChanged: (_) {},
              onToggleApiKeyVisibility: () {},
            ),
          ),
        ),
      ),
    );

    _expectSemanticsLabel(tester, '供应商');
    _expectSemanticsLabel(tester, '生图尺寸能力');
    expect(find.byTooltip('显示密钥'), findsOneWidget);
    expect(find.byTooltip('从已获取列表选择模型，或刷新列表'), findsOneWidget);

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('generation control panel exposes advanced settings semantics', (
    tester,
  ) async {
    final promptController = TextEditingController(text: 'A small robot');
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    addTearDown(promptController.dispose);
    addTearDown(negativePromptController.dispose);
    addTearDown(userController.dispose);
    tester.view
      ..physicalSize = const Size(900, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: ControlPanel(
                apiConfigs: const [
                  ApiConfig(
                    id: 'default',
                    name: '默认配置',
                    baseUrl: 'https://api.openai.com/v1',
                    apiKey: '',
                    model: 'gpt-image-2',
                    providerKind: ApiProviderKind.official,
                  ),
                ],
                selectedApiConfigId: 'default',
                providerKind: ApiProviderKind.official,
                model: 'gpt-image-2',
                imageSizeCapabilityOverride: ImageSizeCapabilityOverride.auto,
                promptController: promptController,
                negativePromptController: negativePromptController,
                size: '1024x1024',
                imageCount: 2,
                advancedSettings: const ImageAdvancedSettings(
                  outputFormat: 'jpeg',
                  outputCompression: 80,
                ),
                userController: userController,
                isGenerating: false,
                onApiConfigChanged: (_) {},
                onOpenApiSettings: () {},
                onSizeChanged: (_) {},
                onImageCountChanged: (_) {},
                onAdvancedSettingsChanged: (_) {},
                onGenerate: () {},
              ),
            ),
          ),
        ),
      ),
    );

    _expectSemanticsLabel(tester, '接口配置');
    _expectSemanticsLabel(tester, '目标数量');

    await tester.ensureVisible(find.text('高级输出参数'));
    await tester.pump();
    await tester.tap(find.text('高级输出参数'));
    await tester.pumpAndSettle();

    _expectSemanticsLabel(tester, '质量');
    _expectSemanticsLabel(tester, '背景');
    _expectSemanticsLabel(tester, '输出格式');
    _expectSemanticsLabel(tester, '审核强度');
    expect(find.bySemanticsLabel('输出压缩率 80%'), findsWidgets);
  });

  testWidgets('sprite sheet panel exposes grid stepper semantics', (
    tester,
  ) async {
    final promptController = TextEditingController(text: 'walk cycle');
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    addTearDown(promptController.dispose);
    addTearDown(negativePromptController.dispose);
    addTearDown(userController.dispose);
    tester.view
      ..physicalSize = const Size(900, 1500)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: SpriteSheetGenerationPanel(
                apiConfigs: const [
                  ApiConfig(
                    id: 'default',
                    name: '默认配置',
                    baseUrl: 'https://api.openai.com/v1',
                    apiKey: '',
                    model: 'gpt-image-2',
                    providerKind: ApiProviderKind.official,
                  ),
                ],
                selectedApiConfigId: 'default',
                providerKind: ApiProviderKind.official,
                model: 'gpt-image-2',
                imageSizeCapabilityOverride: ImageSizeCapabilityOverride.auto,
                promptController: promptController,
                negativePromptController: negativePromptController,
                size: '1024x1024',
                rows: 2,
                columns: 3,
                gridSpec: const SpriteSheetGridSpec(
                  rows: 2,
                  columns: 3,
                  marginLeft: 4,
                ),
                templateImagePath: null,
                advancedSettings: const ImageAdvancedSettings(),
                userController: userController,
                isGenerating: false,
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
              ),
            ),
          ),
        ),
      ),
    );

    expect(_semanticsWithLabel('行数'), findsWidgets);
    expect(_semanticsWithLabel('列数'), findsWidgets);

    await tester.ensureVisible(find.text('切片校准'));
    await tester.pump();
    await tester.tap(find.text('切片校准'));
    await tester.pumpAndSettle();

    expect(_semanticsWithLabel('左边距'), findsWidgets);
    expect(_semanticsWithValue('4px'), findsWidgets);
    expect(find.byTooltip('左边距减少 1px'), findsOneWidget);
    expect(find.byTooltip('左边距增加 1px'), findsOneWidget);
  });
}

Finder _semanticsWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
  );
}

Finder _semanticsWithValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.value == value,
  );
}

void _expectSemanticsLabel(WidgetTester tester, String label) {
  expect(
    tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((widget) => widget.properties.label),
    contains(label),
  );
}
