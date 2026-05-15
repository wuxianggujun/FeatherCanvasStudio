import 'package:flutter/material.dart';

import '../../models/api_provider.dart';
import '../../models/image_advanced_settings.dart';
import '../layout_navigation_widgets.dart';
import '../local_settings_widgets.dart';

class LocalSettingsWorkspace extends StatelessWidget {
  const LocalSettingsWorkspace({
    required this.apiConfigCount,
    required this.imageLibraryCount,
    required this.generatedPreviewCount,
    required this.isCleaningStorage,
    required this.providerKind,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.imageCount,
    required this.advancedSettings,
    required this.userController,
    required this.onSizeChanged,
    required this.onImageCountChanged,
    required this.onAdvancedSettingsChanged,
    required this.onOpenApiSettings,
    required this.onCleanupStorage,
    required this.onResetToDefaults,
    super.key,
  });

  final int apiConfigCount;
  final int imageLibraryCount;
  final int generatedPreviewCount;
  final bool isCleaningStorage;
  final ApiProviderKind providerKind;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onImageCountChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onOpenApiSettings;
  final VoidCallback onCleanupStorage;
  final VoidCallback onResetToDefaults;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: '本地设置',
      description: '管理本机保存的默认生成参数、接口配置入口和恢复默认操作',
      children: [
        LocalSettingsPanel(
          apiConfigCount: apiConfigCount,
          imageLibraryCount: imageLibraryCount,
          generatedPreviewCount: generatedPreviewCount,
          isCleaningStorage: isCleaningStorage,
          providerKind: providerKind,
          promptController: promptController,
          negativePromptController: negativePromptController,
          size: size,
          imageCount: imageCount,
          advancedSettings: advancedSettings,
          userController: userController,
          onSizeChanged: onSizeChanged,
          onImageCountChanged: onImageCountChanged,
          onAdvancedSettingsChanged: onAdvancedSettingsChanged,
          onOpenApiSettings: onOpenApiSettings,
          onCleanupStorage: onCleanupStorage,
          onResetToDefaults: onResetToDefaults,
        ),
      ],
    );
  }
}
