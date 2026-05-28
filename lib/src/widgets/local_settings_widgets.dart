import 'package:flutter/material.dart';

import '../models/api_provider.dart';
import '../models/app_preset.dart';
import '../models/app_config.dart';
import '../models/image_advanced_settings.dart';
import '../l10n/app_l10n.dart';
import '../l10n/generated/app_localizations.dart';
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
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        AppPanel(
          title: l10n.localSettingsStatusSectionTitle,
          child: Column(
            children: [
              _SettingsSummaryRow(
                icon: Icons.tune_outlined,
                label: l10n.localSettingsStatusApiConfigs,
                value: l10n.countApiConfigs(apiConfigCount),
              ),
              const Divider(height: 20),
              _SettingsSummaryRow(
                icon: Icons.collections_outlined,
                label: l10n.localSettingsStatusLibraryItems,
                value: l10n.countLibraryItems(imageLibraryCount),
              ),
              const Divider(height: 20),
              _SettingsSummaryRow(
                icon: Icons.preview_outlined,
                label: l10n.localSettingsStatusPreviewImages,
                value: l10n.countImages(generatedPreviewCount),
              ),
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: l10n.localSettingsDefaultsSectionTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.localSettingsDefaultsSectionDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: fieldGap),
              TextField(
                controller: promptController,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: l10n.localSettingsDefaultPromptLabel,
                  hintText: l10n.localSettingsDefaultPromptHint,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: fieldGap),
              OptionalPromptExclusionSection(
                controller: negativePromptController,
                labelText: l10n.localSettingsDefaultNegativePromptLabel,
                hintText: l10n.localSettingsDefaultNegativePromptHint,
                minLines: 2,
                maxLines: 5,
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
                label: l10n.localSettingsDefaultImageCountLabel,
                value: imageCount,
                minValue: minImageGenerationCount,
                maxValue: maxImageGenerationTargetCount,
                suffixText: l10n.imageCountSuffix,
                helperText: l10n.localSettingsDefaultImageCountHelper(
                  maxImageGenerationRequestCount,
                ),
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
          title: l10n.localSettingsPresetSectionTitle,
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
                    label: Text(l10n.localSettingsSaveTextPreset),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onSavePreset(AppPresetKind.spriteSheet),
                    icon: const Icon(Icons.video_library_outlined),
                    label: Text(l10n.localSettingsSaveAnimationPreset),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onSavePreset(AppPresetKind.gif),
                    icon: const Icon(Icons.gif_box_outlined),
                    label: Text(l10n.localSettingsSaveGifPreset),
                  ),
                ],
              ),
              if (presets.isNotEmpty) ...[
                const SizedBox(height: fieldGap),
                for (final preset in presets)
                  _PresetRow(
                    preset: preset,
                    l10n: l10n,
                    onApply: () => onApplyPreset(preset),
                    onDelete: () => onDeletePreset(preset),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: l10n.localSettingsLibraryMigrationSectionTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.localSettingsLibraryMigrationSectionDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: fieldGap),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DisabledActionSemantics(
                    label: isExportingLibrary
                        ? l10n.localSettingsExportingLibrary
                        : l10n.localSettingsExportLibrary,
                    disabledReason: isExportingLibrary
                        ? l10n.localSettingsLibraryExportBusyUnavailable
                        : imageLibraryCount == 0
                        ? l10n.localSettingsLibraryExportEmptyUnavailable
                        : null,
                    child: OutlinedButton.icon(
                      onPressed: isExportingLibrary || imageLibraryCount == 0
                          ? null
                          : onExportLibrary,
                      icon: ButtonProgressIcon(
                        isBusy: isExportingLibrary,
                        icon: Icons.archive_outlined,
                      ),
                      label: Text(
                        isExportingLibrary
                            ? l10n.localSettingsExportingLibrary
                            : l10n.localSettingsExportLibrary,
                      ),
                    ),
                  ),
                  _DisabledActionSemantics(
                    label: isImportingLibrary
                        ? l10n.localSettingsImportingLibrary
                        : l10n.localSettingsImportLibrary,
                    disabledReason: isImportingLibrary
                        ? l10n.localSettingsLibraryImportBusyUnavailable
                        : null,
                    child: OutlinedButton.icon(
                      onPressed: isImportingLibrary ? null : onImportLibrary,
                      icon: ButtonProgressIcon(
                        isBusy: isImportingLibrary,
                        icon: Icons.unarchive_outlined,
                      ),
                      label: Text(
                        isImportingLibrary
                            ? l10n.localSettingsImportingLibrary
                            : l10n.localSettingsImportLibrary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: l10n.localSettingsConfigEntrySectionTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.localSettingsConfigEntrySectionDescription,
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
                  label: Text(l10n.localSettingsOpenApiSettings),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: l10n.localSettingsStorageCleanupSectionTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.localSettingsStorageCleanupSectionDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: fieldGap),
              Align(
                alignment: Alignment.centerLeft,
                child: _DisabledActionSemantics(
                  label: isCleaningStorage
                      ? l10n.localSettingsCleaningStorage
                      : l10n.localSettingsCleanUnusedFiles,
                  disabledReason: isCleaningStorage
                      ? l10n.localSettingsStorageCleanupBusyUnavailable
                      : null,
                  child: OutlinedButton.icon(
                    onPressed: isCleaningStorage ? null : onCleanupStorage,
                    icon: ButtonProgressIcon(
                      isBusy: isCleaningStorage,
                      icon: Icons.cleaning_services_outlined,
                    ),
                    label: Text(
                      isCleaningStorage
                          ? l10n.localSettingsCleaningStorage
                          : l10n.localSettingsCleanUnusedFiles,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: l10n.localSettingsResetSectionTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.localSettingsResetSectionDescription,
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
                  label: Text(l10n.localSettingsResetForm),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisabledActionSemantics extends StatelessWidget {
  const _DisabledActionSemantics({
    required this.label,
    required this.disabledReason,
    required this.child,
  });

  final String label;
  final String? disabledReason;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (disabledReason == null) {
      return child;
    }

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      value: disabledReason,
      button: true,
      enabled: false,
      child: child,
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
    required this.l10n,
    required this.onApply,
    required this.onDelete,
  });

  final AppPreset preset;
  final AppLocalizations l10n;
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
                    _presetSummary(l10n, preset),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Semantics(
              container: true,
              label: l10n.applyPresetAction(preset.name),
              button: true,
              enabled: true,
              child: TextButton(
                onPressed: onApply,
                child: Text(l10n.applyPreset),
              ),
            ),
            Semantics(
              container: true,
              label: l10n.deletePresetAction(preset.name),
              button: true,
              enabled: true,
              child: IconButton(
                tooltip: l10n.deletePresetTooltip,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
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

String _presetSummary(AppLocalizations l10n, AppPreset preset) {
  return switch (preset.kind) {
    AppPresetKind.localGeneration => l10n.localGenerationPresetSummary(
      preset.size,
      preset.imageCount,
    ),
    AppPresetKind.spriteSheet => l10n.spriteSheetPresetSummary(
      preset.size,
      preset.rows,
      preset.columns,
    ),
    AppPresetKind.gif => _gifPresetSummary(l10n, preset),
  };
}

String _gifPresetSummary(AppLocalizations l10n, AppPreset preset) {
  final loopLabel = preset.gifLoopCount == 0
      ? l10n.gifLoopInfinite
      : l10n.gifLoopCount(preset.gifLoopCount);
  return l10n.gifPresetSummary(preset.gifDelayMs, loopLabel);
}
