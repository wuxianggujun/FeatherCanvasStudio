import 'package:flutter/material.dart';

import '../models/api_provider.dart';
import '../models/image_advanced_settings.dart';
import '../theme/layout_constants.dart';
import '../widgets/image_advanced_settings_widgets.dart';
import '../widgets/image_size_widgets.dart';
import '../widgets/common_form_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';

class LocalSettingsPanel extends StatelessWidget {
  const LocalSettingsPanel({
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        AppPanel(
          title: '本地状态',
          child: Column(
            children: [
              _SettingsSummaryRow(
                icon: Icons.tune_outlined,
                label: '接口配置',
                value: '$apiConfigCount 个',
              ),
              const Divider(height: 20),
              _SettingsSummaryRow(
                icon: Icons.collections_outlined,
                label: '作品库记录',
                value: '$imageLibraryCount 条',
              ),
              const Divider(height: 20),
              _SettingsSummaryRow(
                icon: Icons.preview_outlined,
                label: '当前预览结果',
                value: '$generatedPreviewCount 张',
              ),
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: '默认生成设置',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '这些值会保存在本机，并作为文本生图、帧动画等工作区的默认表单状态。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: fieldGap),
              TextField(
                controller: promptController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: '默认正向提示词',
                  hintText: '新会话或恢复默认后使用的正向提示词',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: fieldGap),
              TextField(
                controller: negativePromptController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '默认负向提示词',
                  hintText: '可选，会合并到 prompt 中',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: fieldGap),
              ImageSizeInput(
                size: size,
                providerKind: providerKind,
                onChanged: onSizeChanged,
              ),
              const SizedBox(height: fieldGap),
              OptionDropdown<int>(
                label: '默认生成数量',
                value: imageCount,
                options: const [1, 2, 3, 4],
                labelBuilder: (value) => '$value 张',
                onChanged: onImageCountChanged,
              ),
              const SizedBox(height: fieldGap),
              ImageAdvancedSettingsSection(
                settings: advancedSettings,
                userController: userController,
                hasTemplateImage: false,
                onChanged: onAdvancedSettingsChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: '配置入口',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '接口地址、密钥和模型列表统一在接口配置页维护。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: fieldGap),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onOpenApiSettings,
                  icon: const Icon(Icons.tune_outlined),
                  label: const Text('打开接口配置'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: '存储清理',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '清理作品库不再引用的生成文件，以及临时参考图缓存。不会删除作品库仍在使用的文件。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: fieldGap),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: isCleaningStorage ? null : onCleanupStorage,
                  icon: ButtonProgressIcon(
                    isBusy: isCleaningStorage,
                    icon: Icons.cleaning_services_outlined,
                  ),
                  label: Text(isCleaningStorage ? '清理中' : '清理未引用文件'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: '恢复默认',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '仅在需要重新开始配置时使用。恢复前会再次确认。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: fieldGap),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: onResetToDefaults,
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('恢复默认表单'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSummaryRow extends StatelessWidget {
  const _SettingsSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
