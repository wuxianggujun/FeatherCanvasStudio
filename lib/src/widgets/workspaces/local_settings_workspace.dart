import 'package:flutter/material.dart';

import '../layout_navigation_widgets.dart';
import '../local_settings_widgets.dart';

class LocalSettingsWorkspace extends StatelessWidget {
  const LocalSettingsWorkspace({
    required this.apiConfigCount,
    required this.imageLibraryCount,
    required this.generatedPreviewCount,
    required this.onOpenApiSettings,
    required this.onResetToDefaults,
    super.key,
  });

  final int apiConfigCount;
  final int imageLibraryCount;
  final int generatedPreviewCount;
  final VoidCallback onOpenApiSettings;
  final VoidCallback onResetToDefaults;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: '本地设置',
      description: '管理本机保存的表单状态、接口配置入口和恢复默认操作',
      children: [
        LocalSettingsPanel(
          apiConfigCount: apiConfigCount,
          imageLibraryCount: imageLibraryCount,
          generatedPreviewCount: generatedPreviewCount,
          onOpenApiSettings: onOpenApiSettings,
          onResetToDefaults: onResetToDefaults,
        ),
      ],
    );
  }
}
