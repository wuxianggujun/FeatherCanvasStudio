import 'package:flutter/material.dart';

import '../../../main.dart' show appThemeMode, setAppThemeMode;
import '../../models/api_provider.dart';
import '../../models/app_config.dart';
import '../../models/image_advanced_settings.dart';
import '../../models/app_preset.dart';
import '../../theme/layout_constants.dart';
import '../layout_navigation_widgets.dart';
import '../local_settings_widgets.dart';

class LocalSettingsWorkspace extends StatelessWidget {
  const LocalSettingsWorkspace({
    required this.apiConfigCount,
    required this.imageLibraryCount,
    required this.generatedPreviewCount,
    required this.isCleaningStorage,
    required this.isExportingLibrary,
    required this.isImportingLibrary,
    required this.providerKind,
    required this.model,
    required this.imageSizeCapabilityOverride,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.imageCount,
    required this.advancedSettings,
    required this.presets,
    required this.userController,
    required this.onSizeChanged,
    required this.onImageCountChanged,
    required this.onAdvancedSettingsChanged,
    required this.onSavePreset,
    required this.onApplyPreset,
    required this.onDeletePreset,
    required this.onOpenApiSettings,
    required this.onExportLibrary,
    required this.onImportLibrary,
    required this.onCleanupStorage,
    required this.onResetToDefaults,
    this.historyControls,
    super.key,
  });

  final int apiConfigCount;
  final int imageLibraryCount;
  final int generatedPreviewCount;
  final bool isCleaningStorage;
  final bool isExportingLibrary;
  final bool isImportingLibrary;
  final ApiProviderKind providerKind;
  final String model;
  final ImageSizeCapabilityOverride imageSizeCapabilityOverride;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final List<AppPreset> presets;
  final TextEditingController userController;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onImageCountChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final ValueChanged<AppPresetKind> onSavePreset;
  final ValueChanged<AppPreset> onApplyPreset;
  final ValueChanged<AppPreset> onDeletePreset;
  final VoidCallback onOpenApiSettings;
  final VoidCallback onExportLibrary;
  final VoidCallback onImportLibrary;
  final VoidCallback onCleanupStorage;
  final VoidCallback onResetToDefaults;
  final Widget? historyControls;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: '本地设置',
      description: '管理本机保存的默认生成参数、接口配置入口和恢复默认操作',
      trailing: historyControls,
      children: [
        const _ThemeModeSection(),
        const SizedBox(height: sectionGap),
        LocalSettingsPanel(
          apiConfigCount: apiConfigCount,
          imageLibraryCount: imageLibraryCount,
          generatedPreviewCount: generatedPreviewCount,
          isCleaningStorage: isCleaningStorage,
          isExportingLibrary: isExportingLibrary,
          isImportingLibrary: isImportingLibrary,
          providerKind: providerKind,
          model: model,
          imageSizeCapabilityOverride: imageSizeCapabilityOverride,
          promptController: promptController,
          negativePromptController: negativePromptController,
          size: size,
          imageCount: imageCount,
          advancedSettings: advancedSettings,
          presets: presets,
          userController: userController,
          onSizeChanged: onSizeChanged,
          onImageCountChanged: onImageCountChanged,
          onAdvancedSettingsChanged: onAdvancedSettingsChanged,
          onSavePreset: onSavePreset,
          onApplyPreset: onApplyPreset,
          onDeletePreset: onDeletePreset,
          onOpenApiSettings: onOpenApiSettings,
          onExportLibrary: onExportLibrary,
          onImportLibrary: onImportLibrary,
          onCleanupStorage: onCleanupStorage,
          onResetToDefaults: onResetToDefaults,
        ),
      ],
    );
  }
}

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(panelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('外观', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '选择应用主题。深色模式适合长时间编辑作业。',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: appThemeMode,
              builder: (context, mode, _) {
                return SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('跟随系统'),
                      icon: Icon(Icons.brightness_auto_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('浅色'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('深色'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) return;
                    setAppThemeMode(selection.first);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
