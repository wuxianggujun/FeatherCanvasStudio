import 'dart:ui' show Tristate;

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('local settings preset actions expose stable semantics', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final promptController = TextEditingController();
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    var applied = false;
    var deleted = false;
    addTearDown(promptController.dispose);
    addTearDown(negativePromptController.dispose);
    addTearDown(userController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1000,
              child: LocalSettingsPanel(
                apiConfigCount: 1,
                imageLibraryCount: 1,
                generatedPreviewCount: 0,
                isCleaningStorage: false,
                isExportingLibrary: false,
                isImportingLibrary: false,
                providerKind: ApiProviderKind.official,
                model: 'gpt-image-2',
                imageSizeCapabilityOverride: ImageSizeCapabilityOverride.auto,
                promptController: promptController,
                negativePromptController: negativePromptController,
                size: '1024x1024',
                imageCount: 1,
                advancedSettings: const ImageAdvancedSettings(),
                presets: [
                  AppPreset(
                    id: 'preset-1',
                    name: '常用方图',
                    kind: AppPresetKind.localGeneration,
                    createdAt: DateTime(2026, 5, 20),
                    prompt: 'pixel icon',
                    negativePrompt: '',
                    size: '1024x1024',
                    imageCount: 1,
                    advancedSettings: const ImageAdvancedSettings(),
                  ),
                ],
                userController: userController,
                onSizeChanged: (_) {},
                onImageCountChanged: (_) {},
                onAdvancedSettingsChanged: (_) {},
                onSavePreset: (_) {},
                onApplyPreset: (_) => applied = true,
                onDeletePreset: (_) => deleted = true,
                onOpenApiSettings: () {},
                onExportLibrary: () {},
                onImportLibrary: () {},
                onCleanupStorage: () {},
                onResetToDefaults: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final applySemantics = tester.getSemantics(
      _semanticsWithLabel('应用预设：常用方图').first,
    );
    expect(applySemantics.flagsCollection.isButton, isTrue);
    expect(applySemantics.flagsCollection.isEnabled, Tristate.isTrue);

    final deleteSemantics = tester.getSemantics(
      _semanticsWithLabel('删除预设：常用方图').first,
    );
    expect(deleteSemantics.flagsCollection.isButton, isTrue);
    expect(deleteSemantics.flagsCollection.isEnabled, Tristate.isTrue);

    await tester.ensureVisible(_semanticsWithLabel('应用预设：常用方图').first);
    await tester.pump();
    await tester.tap(_semanticsWithLabel('应用预设：常用方图').first);
    await tester.pump();
    await tester.ensureVisible(_semanticsWithLabel('删除预设：常用方图').first);
    await tester.pump();
    await tester.tap(_semanticsWithLabel('删除预设：常用方图').first);
    await tester.pump();

    expect(applied, isTrue);
    expect(deleted, isTrue);
  });

  testWidgets('local settings cleanup exposes disabled reason while busy', (
    tester,
  ) async {
    final promptController = TextEditingController();
    final negativePromptController = TextEditingController();
    final userController = TextEditingController();
    addTearDown(promptController.dispose);
    addTearDown(negativePromptController.dispose);
    addTearDown(userController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1000,
              child: LocalSettingsPanel(
                apiConfigCount: 1,
                imageLibraryCount: 1,
                generatedPreviewCount: 0,
                isCleaningStorage: true,
                isExportingLibrary: false,
                isImportingLibrary: false,
                providerKind: ApiProviderKind.official,
                model: 'gpt-image-2',
                imageSizeCapabilityOverride: ImageSizeCapabilityOverride.auto,
                promptController: promptController,
                negativePromptController: negativePromptController,
                size: '1024x1024',
                imageCount: 1,
                advancedSettings: const ImageAdvancedSettings(),
                presets: const [],
                userController: userController,
                onSizeChanged: (_) {},
                onImageCountChanged: (_) {},
                onAdvancedSettingsChanged: (_) {},
                onSavePreset: (_) {},
                onApplyPreset: (_) {},
                onDeletePreset: (_) {},
                onOpenApiSettings: () {},
                onExportLibrary: () {},
                onImportLibrary: () {},
                onCleanupStorage: () {},
                onResetToDefaults: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final cleanupSemantics = tester.getSemantics(
      _semanticsWithLabel('清理中').first,
    );
    expect(cleanupSemantics.value, '正在清理存储，完成后可继续操作');
    expect(cleanupSemantics.flagsCollection.isButton, isTrue);
    expect(cleanupSemantics.flagsCollection.isEnabled, Tristate.isFalse);
  });
}

Finder _semanticsWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
  );
}
