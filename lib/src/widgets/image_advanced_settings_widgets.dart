import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../models/image_advanced_settings.dart';
import '../theme/layout_constants.dart';
import '../utils/localized_display_labels.dart';
import 'common_form_widgets.dart';

class ImageAdvancedSettingsSection extends StatelessWidget {
  const ImageAdvancedSettingsSection({
    required this.settings,
    required this.userController,
    required this.hasTemplateImage,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final ImageAdvancedSettings settings;
  final TextEditingController userController;
  final bool hasTemplateImage;
  final ValueChanged<ImageAdvancedSettings> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final compressionEnabled = settings.supportsOutputCompression;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 4),
      title: Text(l10n.imageAdvancedSettingsTitle),
      subtitle: Text(
        '${localizedImageQualityLabel(l10n, settings.quality)}${l10n.imageAdvancedSettingsQualitySuffix} · '
        '${localizedImageOutputFormatLabel(settings.outputFormat)} · '
        '${localizedImageBackgroundLabel(l10n, settings.background)}${l10n.imageAdvancedSettingsBackgroundSuffix}',
      ),
      children: [
        ResponsivePair(
          first: _ImageOptionDropdown(
            label: l10n.imageAdvancedSettingsQuality,
            value: settings.quality,
            options: gptImageQualityOptions,
            labelBuilder: (value) => localizedImageQualityLabel(l10n, value),
            onChanged: enabled
                ? (value) => onChanged(settings.copyWith(quality: value))
                : null,
          ),
          second: _ImageOptionDropdown(
            label: l10n.imageAdvancedSettingsBackground,
            value: settings.background,
            options: gptImageBackgroundOptions,
            labelBuilder: (value) => localizedImageBackgroundLabel(l10n, value),
            onChanged: enabled
                ? (value) => onChanged(settings.copyWith(background: value))
                : null,
          ),
        ),
        const SizedBox(height: fieldGap),
        ResponsivePair(
          first: _ImageOptionDropdown(
            label: l10n.imageAdvancedSettingsOutputFormat,
            value: settings.outputFormat,
            options: gptImageOutputFormatOptions,
            labelBuilder: localizedImageOutputFormatLabel,
            onChanged: enabled
                ? (value) {
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
                  }
                : null,
          ),
          second: _ImageOptionDropdown(
            label: l10n.imageAdvancedSettingsModeration,
            value: settings.moderation,
            options: gptImageModerationOptions,
            labelBuilder: (value) => localizedImageModerationLabel(l10n, value),
            onChanged: !enabled || hasTemplateImage
                ? null
                : (value) => onChanged(settings.copyWith(moderation: value)),
          ),
        ),
        const SizedBox(height: fieldGap),
        _ImageCompressionSlider(
          value: settings.outputCompression,
          available: compressionEnabled,
          enabled: enabled && compressionEnabled,
          onChanged: (value) =>
              onChanged(settings.copyWith(outputCompression: value)),
        ),
        const SizedBox(height: fieldGap),
        TextField(
          controller: userController,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: l10n.imageAdvancedSettingsFinalUserId,
            hintText: l10n.imageAdvancedSettingsFinalUserHint,
          ),
        ),
        if (hasTemplateImage) ...[
          const SizedBox(height: fieldGap),
          _ImageOptionDropdown(
            label: l10n.imageAdvancedSettingsInputFidelity,
            value: settings.inputFidelity,
            options: const ['low', 'high'],
            labelBuilder: (value) => value == 'high'
                ? l10n.imageAdvancedSettingsHigh
                : l10n.imageAdvancedSettingsLow,
            onChanged: enabled
                ? (value) => onChanged(settings.copyWith(inputFidelity: value))
                : null,
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
    required this.available,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool available;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    final normalized = value.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          available
              ? l10n.imageAdvancedSettingsCompressionValue(normalized)
              : l10n.imageAdvancedSettingsCompressionUnavailable,
          style: theme.textTheme.bodySmall,
        ),
        Slider(
          value: normalized.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: '$normalized%',
          semanticFormatterCallback: (value) =>
              l10n.imageAdvancedSettingsCompressionValue(value.round()),
          onChanged: enabled ? (value) => onChanged(value.round()) : null,
        ),
      ],
    );
  }
}
