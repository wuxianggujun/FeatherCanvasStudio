import 'package:flutter/material.dart';

import '../models/api_provider.dart';
import '../models/app_preset.dart';
import '../models/app_config.dart';
import '../models/image_advanced_settings.dart';
import '../theme/layout_constants.dart';
import '../utils/generation_limits.dart';
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
                '这些值会保存在本机，并作为文本生图、动画工程等工作区的默认表单状态。',
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
                model: model,
                capabilityOverride: imageSizeCapabilityOverride,
                onChanged: onSizeChanged,
              ),
              const SizedBox(height: fieldGap),
              IntegerStepperField(
                label: '默认生成数量',
                value: imageCount,
                minValue: minImageGenerationCount,
                maxValue: maxImageGenerationTargetCount,
                suffixText: '张',
                helperText: '超过 $maxImageGenerationRequestCount 张会自动拆成多次请求',
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
          title: '常用预设',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        onSavePreset(AppPresetKind.localGeneration),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('保存文本预设'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onSavePreset(AppPresetKind.spriteSheet),
                    icon: const Icon(Icons.video_library_outlined),
                    label: const Text('保存动画工程预设'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onSavePreset(AppPresetKind.gif),
                    icon: const Icon(Icons.gif_box_outlined),
                    label: const Text('保存 GIF 预设'),
                  ),
                ],
              ),
              if (presets.isNotEmpty) ...[
                const SizedBox(height: fieldGap),
                for (final preset in presets)
                  _PresetRow(
                    preset: preset,
                    onApply: () => onApplyPreset(preset),
                    onDelete: () => onDeletePreset(preset),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: '作品库迁移',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '把作品库元数据和本地图片打包为 ZIP，或从 ZIP 导入到当前作品库。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: fieldGap),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: isExportingLibrary || imageLibraryCount == 0
                        ? null
                        : onExportLibrary,
                    icon: ButtonProgressIcon(
                      isBusy: isExportingLibrary,
                      icon: Icons.archive_outlined,
                    ),
                    label: Text(isExportingLibrary ? '导出中' : '导出作品库'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isImportingLibrary ? null : onImportLibrary,
                    icon: ButtonProgressIcon(
                      isBusy: isImportingLibrary,
                      icon: Icons.unarchive_outlined,
                    ),
                    label: Text(isImportingLibrary ? '导入中' : '导入作品库'),
                  ),
                ],
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

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.preset,
    required this.onApply,
    required this.onDelete,
  });

  final AppPreset preset;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(_presetIcon(preset.kind), color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _presetSummary(preset),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onApply, child: const Text('应用')),
            IconButton(
              tooltip: '删除预设',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _presetIcon(AppPresetKind kind) {
  return switch (kind) {
    AppPresetKind.localGeneration => Icons.image_outlined,
    AppPresetKind.spriteSheet => Icons.video_library_outlined,
    AppPresetKind.gif => Icons.gif_box_outlined,
  };
}

String _presetSummary(AppPreset preset) {
  return switch (preset.kind) {
    AppPresetKind.localGeneration => '${preset.size} · ${preset.imageCount} 张',
    AppPresetKind.spriteSheet =>
      '${preset.size} · ${preset.rows} x ${preset.columns}',
    AppPresetKind.gif => _gifPresetSummary(preset),
  };
}

String _gifPresetSummary(AppPreset preset) {
  final loopLabel = preset.gifLoopCount == 0
      ? '无限循环'
      : '播放 ${preset.gifLoopCount} 次';
  return '${preset.gifDelayMs} ms · $loopLabel';
}
