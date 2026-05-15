import 'package:flutter/material.dart';

import '../models/image_advanced_settings.dart';
import '../theme/layout_constants.dart';
import '../utils/display_labels.dart';
import 'common_form_widgets.dart';

class ImageAdvancedSettingsSection extends StatelessWidget {
  const ImageAdvancedSettingsSection({
    required this.settings,
    required this.userController,
    required this.hasTemplateImage,
    required this.onChanged,
    super.key,
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
