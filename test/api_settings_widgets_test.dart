import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('describes why the last API config cannot be deleted', (
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
                  apiKey: 'sk-test',
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

    final deleteSemantics = tester.getSemantics(find.byTooltip('删除当前配置'));

    expect(deleteSemantics.value, '至少需要保留一个接口配置');
    expect(deleteSemantics.flagsCollection.isButton, isTrue);
    expect(deleteSemantics.flagsCollection.isEnabled, Tristate.isFalse);
  });

  test('describes default model list state before first fetch', () {
    expect(
      apiModelFetchHelperText(
        availableModels: const [],
        isFetchingModels: false,
        modelFetchErrorMessage: null,
        modelFetchedAt: null,
      ),
      '尚未获取模型列表',
    );
  });

  test('describes cached model list after a successful fetch', () {
    expect(
      apiModelFetchHelperText(
        availableModels: const [ApiModelInfo(id: 'gpt-image-2')],
        isFetchingModels: false,
        modelFetchErrorMessage: null,
        modelFetchedAt: DateTime(2026, 5, 15, 10, 30),
      ),
      '已缓存 1 个模型，上次成功：2026-05-15 10:30',
    );
  });

  test('distinguishes an empty but successfully fetched model list', () {
    expect(
      apiModelFetchHelperText(
        availableModels: const [],
        isFetchingModels: false,
        modelFetchErrorMessage: null,
        modelFetchedAt: DateTime(2026, 5, 15, 10, 30),
      ),
      '已缓存 0 个模型，上次成功：2026-05-15 10:30',
    );
  });

  test('describes fallback to cached models after a refresh failure', () {
    expect(
      apiModelFetchHelperText(
        availableModels: const [ApiModelInfo(id: 'gpt-image-2')],
        isFetchingModels: false,
        modelFetchErrorMessage: '502 Bad Gateway',
        modelFetchedAt: DateTime(2026, 5, 15, 10, 30),
      ),
      '刷新失败，继续显示 1 个缓存模型，上次成功：2026-05-15 10:30',
    );
  });

  test('describes refresh failure after an empty cached fetch', () {
    expect(
      apiModelFetchHelperText(
        availableModels: const [],
        isFetchingModels: false,
        modelFetchErrorMessage: '502 Bad Gateway',
        modelFetchedAt: DateTime(2026, 5, 15, 10, 30),
      ),
      '模型列表刷新失败，当前缓存为空，上次成功：2026-05-15 10:30',
    );
  });
}
