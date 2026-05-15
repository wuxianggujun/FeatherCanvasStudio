import 'package:flutter/material.dart';

import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../models/image_advanced_settings.dart';
import '../theme/layout_constants.dart';
import '../utils/display_labels.dart';
import '../widgets/api_settings_widgets.dart';
import '../widgets/common_form_widgets.dart';
import '../widgets/image_size_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.providerKind,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.imageCount,
    required this.advancedSettings,
    required this.userController,
    required this.isGenerating,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onImageCountChanged,
    required this.onAdvancedSettingsChanged,
    required this.onGenerate,
    super.key,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ApiProviderKind providerKind;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final bool isGenerating;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onImageCountChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: '生成配置',
      child: Column(
        children: [
          ApiConfigSelector(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfigId,
            onChanged: onApiConfigChanged,
            onOpenSettings: onOpenApiSettings,
          ),
          const SizedBox(height: fieldGap),
          TextField(
            controller: promptController,
            minLines: 5,
            maxLines: 9,
            decoration: const InputDecoration(
              labelText: '正向提示词',
              hintText: '描述你想生成的图片',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: fieldGap),
          TextField(
            controller: negativePromptController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '负向提示词',
              hintText: '会合并到 prompt 中，不额外发送非 OpenAI 字段',
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
          _ImageAdvancedSettingsSection(
            settings: advancedSettings,
            userController: userController,
            hasTemplateImage: false,
            onChanged: onAdvancedSettingsChanged,
          ),
          const SizedBox(height: fieldGap),
          OptionDropdown<int>(
            label: '数量',
            value: imageCount,
            options: const [1, 2, 3, 4],
            labelBuilder: (value) => '$value 张',
            onChanged: onImageCountChanged,
          ),
          const SizedBox(height: sectionGap),
          PrimaryActionButton(
            onPressed: isGenerating ? null : onGenerate,
            icon: Icons.auto_awesome,
            label: '生成图片',
            busyLabel: '生成中',
            isBusy: isGenerating,
          ),
        ],
      ),
    );
  }
}

class FrameAnimationPanel extends StatelessWidget {
  const FrameAnimationPanel({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.providerKind,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.rows,
    required this.columns,
    required this.templateImagePath,
    required this.advancedSettings,
    required this.userController,
    required this.isGenerating,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onAdvancedSettingsChanged,
    required this.onPickTemplateImage,
    required this.onClearTemplateImage,
    required this.onGenerate,
    super.key,
  });

  static const List<int> _gridSizes = <int>[1, 2, 3, 4, 5, 6, 7, 8];

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ApiProviderKind providerKind;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int rows;
  final int columns;
  final String? templateImagePath;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final bool isGenerating;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onPickTemplateImage;
  final VoidCallback onClearTemplateImage;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final frameTotal = rows * columns;

    return AppPanel(
      title: '帧动画配置',
      child: Column(
        children: [
          ApiConfigSelector(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfigId,
            onChanged: onApiConfigChanged,
            onOpenSettings: onOpenApiSettings,
          ),
          const SizedBox(height: fieldGap),
          TemplateImagePicker(
            imagePath: templateImagePath,
            onPick: isGenerating ? null : onPickTemplateImage,
            onClear: templateImagePath == null || isGenerating
                ? null
                : onClearTemplateImage,
          ),
          const SizedBox(height: fieldGap),
          TextField(
            controller: promptController,
            minLines: 7,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: '提示词内容',
              hintText: '把主体、场景、风格、动作变化写在这里即可',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: fieldGap),
          TextField(
            controller: negativePromptController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '负向提示词',
              hintText: '会应用到每一帧',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: fieldGap),
          ImageSizeInput(
            size: size,
            providerKind: providerKind,
            onChanged: onSizeChanged,
            compact: true,
          ),
          const SizedBox(height: fieldGap),
          _ImageAdvancedSettingsSection(
            settings: advancedSettings,
            userController: userController,
            hasTemplateImage: templateImagePath != null,
            onChanged: onAdvancedSettingsChanged,
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: OptionDropdown<int>(
              label: '行数',
              value: rows,
              options: _gridSizes,
              labelBuilder: (value) => '$value 行',
              onChanged: onRowsChanged,
            ),
            second: OptionDropdown<int>(
              label: '列数',
              value: columns,
              options: _gridSizes,
              labelBuilder: (value) => '$value 列',
              helperText:
                  '生成 1 张 $rows x $columns 的 Sprite Sheet，共 $frameTotal 格',
              onChanged: onColumnsChanged,
            ),
          ),
          const SizedBox(height: sectionGap),
          PrimaryActionButton(
            onPressed: isGenerating ? null : onGenerate,
            icon: Icons.movie_filter_outlined,
            label: '生成 Sprite Sheet',
            busyLabel: '生成 Sprite Sheet 中',
            isBusy: isGenerating,
          ),
        ],
      ),
    );
  }
}

class _ImageAdvancedSettingsSection extends StatelessWidget {
  const _ImageAdvancedSettingsSection({
    required this.settings,
    required this.userController,
    required this.hasTemplateImage,
    required this.onChanged,
  });

  final ImageAdvancedSettings settings;
  final TextEditingController userController;
  final bool hasTemplateImage;
  final ValueChanged<ImageAdvancedSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final compressionEnabled = settings.supportsOutputCompression;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 4),
      title: const Text('高级输出参数'),
      subtitle: Text(
        '${imageQualityLabel(settings.quality)}质量 · '
        '${imageOutputFormatLabel(settings.outputFormat)} · '
        '${imageBackgroundLabel(settings.background)}背景',
      ),
      children: [
        ResponsivePair(
          first: _ImageOptionDropdown(
            label: '质量',
            value: settings.quality,
            options: gptImageQualityOptions,
            labelBuilder: imageQualityLabel,
            onChanged: (value) => onChanged(settings.copyWith(quality: value)),
          ),
          second: _ImageOptionDropdown(
            label: '背景',
            value: settings.background,
            options: gptImageBackgroundOptions,
            labelBuilder: imageBackgroundLabel,
            onChanged: (value) =>
                onChanged(settings.copyWith(background: value)),
          ),
        ),
        const SizedBox(height: fieldGap),
        ResponsivePair(
          first: _ImageOptionDropdown(
            label: '输出格式',
            value: settings.outputFormat,
            options: gptImageOutputFormatOptions,
            labelBuilder: imageOutputFormatLabel,
            onChanged: (value) {
              final nextBackground =
                  value == 'jpeg' && settings.background == 'transparent'
                  ? 'auto'
                  : settings.background;
              onChanged(
                settings.copyWith(
                  outputFormat: value,
                  background: nextBackground,
                ),
              );
            },
          ),
          second: _ImageOptionDropdown(
            label: '审核强度',
            value: settings.moderation,
            options: gptImageModerationOptions,
            labelBuilder: imageModerationLabel,
            onChanged: hasTemplateImage
                ? null
                : (value) => onChanged(settings.copyWith(moderation: value)),
          ),
        ),
        const SizedBox(height: fieldGap),
        _ImageCompressionSlider(
          value: settings.outputCompression,
          enabled: compressionEnabled,
          onChanged: (value) =>
              onChanged(settings.copyWith(outputCompression: value)),
        ),
        const SizedBox(height: fieldGap),
        TextField(
          controller: userController,
          decoration: const InputDecoration(
            labelText: '最终用户 ID',
            hintText: '可选，用于 OpenAI 滥用监控',
          ),
        ),
        if (hasTemplateImage) ...[
          const SizedBox(height: fieldGap),
          _ImageOptionDropdown(
            label: '参考图保真度',
            value: settings.inputFidelity,
            options: const ['low', 'high'],
            labelBuilder: (value) => value == 'high' ? '高' : '低',
            onChanged: (value) =>
                onChanged(settings.copyWith(inputFidelity: value)),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ImageOptionDropdown extends StatelessWidget {
  const _ImageOptionDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final String Function(String value) labelBuilder;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return OptionDropdown<String>(
      label: label,
      value: value,
      options: options,
      labelBuilder: labelBuilder,
      onChanged: onChanged,
    );
  }
}

class _ImageCompressionSlider extends StatelessWidget {
  const _ImageCompressionSlider({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = value.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          enabled ? '输出压缩率 $normalized%' : '输出压缩率仅用于 JPEG / WebP',
          style: theme.textTheme.bodySmall,
        ),
        Slider(
          value: normalized.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: '$normalized%',
          onChanged: enabled ? (value) => onChanged(value.round()) : null,
        ),
      ],
    );
  }
}
