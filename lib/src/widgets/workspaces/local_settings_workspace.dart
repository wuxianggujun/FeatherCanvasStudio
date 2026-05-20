import 'package:flutter/material.dart';

import '../../../main.dart' show appThemeMode, setAppThemeMode;
import '../../models/api_provider.dart';
import '../../models/app_config.dart';
import '../../models/image_advanced_settings.dart';
import '../../models/app_preset.dart';
import '../../shortcuts/app_shortcuts.dart';
import '../../l10n/app_l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/layout_constants.dart';
import '../common_form_widgets.dart';
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
    final l10n = appL10nOf(context);
    return WorkspacePage(
      title: l10n.localSettingsWorkspaceTitle,
      description: l10n.localSettingsWorkspaceDescription,
      trailing: historyControls,
      children: [
        const _ThemeModeSection(),
        const SizedBox(height: sectionGap),
        const _ShortcutsSection(),
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

class _ShortcutsSection extends StatelessWidget {
  const _ShortcutsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppPanel(
      title: l10n.shortcutsSectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shortcutsSectionDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final shortcut in appShortcutCheatSheet)
                _ShortcutChip(
                  label: _shortcutLabel(l10n, shortcut.id),
                  keys: shortcut.keys,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortcutLabel(AppLocalizations l10n, AppShortcutId id) {
    return switch (id) {
      AppShortcutId.undo => l10n.shortcutLabelUndo,
      AppShortcutId.redo => l10n.shortcutLabelRedo,
      AppShortcutId.redoAlt => l10n.shortcutLabelRedoAlt,
    };
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.label, required this.keys});

  final String label;
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            const SizedBox(width: 8),
            for (var index = 0; index < keys.length; index++) ...[
              if (index > 0)
                Text(
                  '+',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              if (index > 0) const SizedBox(width: 4),
              _Keycap(label: keys[index]),
              if (index < keys.length - 1) const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _Keycap extends StatelessWidget {
  const _Keycap({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection();

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(panelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appearanceSectionTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.appearanceSectionDescription,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: appThemeMode,
              builder: (context, mode, _) {
                return SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n.themeModeSystem),
                      icon: const Icon(Icons.brightness_auto_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n.themeModeLight),
                      icon: const Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n.themeModeDark),
                      icon: const Icon(Icons.dark_mode_outlined),
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
