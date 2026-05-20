import 'package:flutter/material.dart';

import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../models/ui_state.dart';
import '../services/image_api_client.dart';
import '../l10n/app_l10n.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/layout_constants.dart';
import '../utils/api_config_logic.dart';
import '../utils/date_formatting.dart';
import '../utils/display_labels.dart';
import '../utils/image_dimensions.dart';
import '../utils/localized_display_labels.dart';
import '../widgets/common_form_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';

part 'api_settings_panel_widgets.dart';

String apiModelFetchHelperText({
  required List<ApiModelInfo> availableModels,
  required bool isFetchingModels,
  required String? modelFetchErrorMessage,
  required DateTime? modelFetchedAt,
  AppLocalizations? l10n,
}) {
  final strings = l10n ?? lookupAppLocalizations(const Locale('zh'));
  final hasFetchedModels = modelFetchedAt != null;
  if (isFetchingModels) {
    if (availableModels.isNotEmpty) {
      return strings.apiModelRefreshingCached(availableModels.length);
    }
    if (hasFetchedModels) {
      return strings.apiModelRefreshingEmptyCache;
    }
    return strings.apiModelFetching;
  }

  final hasModels = availableModels.isNotEmpty;
  final hasError =
      modelFetchErrorMessage != null &&
      modelFetchErrorMessage.trim().isNotEmpty;
  final fetchedAtLabel = modelFetchedAt == null
      ? null
      : strings.apiModelLastSuccess(formatTimestamp(modelFetchedAt));

  if (hasError && hasModels) {
    return fetchedAtLabel == null
        ? strings.apiModelRefreshFailedUsingCache(availableModels.length)
        : strings.apiModelRefreshFailedUsingCacheWithTime(
            availableModels.length,
            fetchedAtLabel,
          );
  }
  if (hasModels) {
    return fetchedAtLabel == null
        ? strings.apiModelFetchedCount(availableModels.length)
        : strings.apiModelCachedCountWithTime(
            availableModels.length,
            fetchedAtLabel,
          );
  }
  if (hasError) {
    if (hasFetchedModels) {
      return fetchedAtLabel == null
          ? strings.apiModelRefreshFailedEmptyCache
          : strings.apiModelRefreshFailedEmptyCacheWithTime(fetchedAtLabel);
    }
    return strings.apiModelFetchFailed;
  }
  if (hasFetchedModels) {
    return fetchedAtLabel == null
        ? strings.apiModelFetchedCount(0)
        : strings.apiModelCachedCountWithTime(0, fetchedAtLabel);
  }
  return strings.apiModelNotFetched;
}

class ApiConfigSelector extends StatelessWidget {
  const ApiConfigSelector({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.onChanged,
    this.enabled = true,
    this.onOpenSettings,
    super.key,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final selectedExists = apiConfigs.any(
      (config) => config.id == selectedApiConfigId,
    );
    final String? selectedValue;
    if (selectedExists) {
      selectedValue = selectedApiConfigId;
    } else if (apiConfigs.isEmpty) {
      selectedValue = null;
    } else {
      selectedValue = apiConfigs.first.id;
    }

    final selectedLabel = selectedValue == null
        ? null
        : apiConfigs
              .firstWhere(
                (config) => config.id == selectedValue,
                orElse: () => apiConfigs.first,
              )
              .name;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            container: true,
            label: l10n.apiConfigLabel,
            value: selectedLabel,
            enabled: enabled && apiConfigs.isNotEmpty,
            child: DropdownButtonFormField<String>(
              key: ValueKey('api-config-$selectedValue'),
              initialValue: selectedValue,
              decoration: InputDecoration(labelText: l10n.apiConfigLabel),
              items: [
                for (final config in apiConfigs)
                  DropdownMenuItem<String>(
                    value: config.id,
                    child: Text(config.name),
                  ),
              ],
              onChanged: !enabled || apiConfigs.isEmpty
                  ? null
                  : (value) {
                      if (value != null) {
                        onChanged(value);
                      }
                    },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: l10n.manageApiConfigTooltip,
          child: IconButton.filledTonal(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.tune_outlined),
          ),
        ),
      ],
    );
  }
}

class ApiSettingsPanel extends StatelessWidget {
  const ApiSettingsPanel({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.saveStatus,
    required this.saveErrorMessage,
    required this.isTestingApiConfig,
    required this.apiTestDebugRecord,
    required this.nameController,
    required this.baseUrlController,
    required this.apiKeyController,
    required this.modelController,
    required this.timeoutController,
    required this.providerKind,
    required this.imageSizeCapabilityOverride,
    required this.showApiKey,
    required this.availableModels,
    required this.isFetchingModels,
    required this.modelFetchErrorMessage,
    required this.modelFetchedAt,
    required this.onApiConfigChanged,
    required this.onAddApiConfig,
    required this.onDeleteApiConfig,
    required this.onSaveApiConfig,
    required this.onTestApiConfig,
    required this.onBasicTestApiConfig,
    required this.onFetchModels,
    required this.onModelSelected,
    required this.onProviderKindChanged,
    required this.onImageSizeCapabilityOverrideChanged,
    required this.onToggleApiKeyVisibility,
    super.key,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ApiConfigSaveStatus saveStatus;
  final String? saveErrorMessage;
  final bool isTestingApiConfig;
  final ImageRequestDebugRecord? apiTestDebugRecord;
  final TextEditingController nameController;
  final TextEditingController baseUrlController;
  final TextEditingController apiKeyController;
  final TextEditingController modelController;
  final TextEditingController timeoutController;
  final ApiProviderKind providerKind;
  final ImageSizeCapabilityOverride imageSizeCapabilityOverride;
  final bool showApiKey;
  final List<ApiModelInfo> availableModels;
  final bool isFetchingModels;
  final String? modelFetchErrorMessage;
  final DateTime? modelFetchedAt;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onAddApiConfig;
  final VoidCallback onDeleteApiConfig;
  final VoidCallback onSaveApiConfig;
  final VoidCallback onTestApiConfig;
  final VoidCallback onBasicTestApiConfig;
  final VoidCallback onFetchModels;
  final ValueChanged<String> onModelSelected;
  final ValueChanged<ApiProviderKind> onProviderKindChanged;
  final ValueChanged<ImageSizeCapabilityOverride>
  onImageSizeCapabilityOverrideChanged;
  final VoidCallback onToggleApiKeyVisibility;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final canDeleteApiConfig = apiConfigs.length > 1;
    return AppPanel(
      title: l10n.apiSettingsPanelTitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ApiConfigSaveIndicator(
            status: saveStatus,
            errorMessage: saveErrorMessage,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.apiSettingsAddConfigTooltip,
            onPressed: onAddApiConfig,
            icon: const Icon(Icons.add),
          ),
          Semantics(
            container: true,
            excludeSemantics: !canDeleteApiConfig,
            label: canDeleteApiConfig
                ? null
                : l10n.apiSettingsDeleteConfigTooltip,
            value: canDeleteApiConfig
                ? null
                : l10n.apiSettingsDeleteConfigUnavailable,
            button: !canDeleteApiConfig,
            enabled: canDeleteApiConfig,
            child: IconButton(
              tooltip: l10n.apiSettingsDeleteConfigTooltip,
              onPressed: canDeleteApiConfig ? onDeleteApiConfig : null,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          _ApiConfigNameField(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfigId,
            controller: nameController,
            onConfigSelected: onApiConfigChanged,
          ),
          const SizedBox(height: fieldGap),
          _ApiProviderKindDropdown(
            value: providerKind,
            onChanged: onProviderKindChanged,
          ),
          const SizedBox(height: fieldGap),
          _ConnectionSettingsFields(
            baseUrlController: baseUrlController,
            apiKeyController: apiKeyController,
            modelController: modelController,
            providerKind: providerKind,
            showApiKey: showApiKey,
            availableModels: availableModels,
            isFetchingModels: isFetchingModels,
            modelFetchErrorMessage: modelFetchErrorMessage,
            modelFetchedAt: modelFetchedAt,
            onFetchModels: onFetchModels,
            onModelSelected: onModelSelected,
            onToggleApiKeyVisibility: onToggleApiKeyVisibility,
          ),
          const SizedBox(height: fieldGap),
          _ImageSizeCapabilityOverrideDropdown(
            providerKind: providerKind,
            model: modelController.text,
            value: imageSizeCapabilityOverride,
            onChanged: onImageSizeCapabilityOverrideChanged,
          ),
          const SizedBox(height: fieldGap),
          _GenerationTimeoutField(controller: timeoutController),
          const SizedBox(height: fieldGap),
          _ApiConfigActions(
            saveStatus: saveStatus,
            isTestingApiConfig: isTestingApiConfig,
            apiTestDebugRecord: apiTestDebugRecord,
            onSaveApiConfig: onSaveApiConfig,
            onTestApiConfig: onTestApiConfig,
            onBasicTestApiConfig: onBasicTestApiConfig,
          ),
        ],
      ),
    );
  }
}
