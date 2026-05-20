import 'package:flutter/material.dart';

import '../../models/api_provider.dart';
import '../../models/app_config.dart';
import '../../models/ui_state.dart';
import '../../services/image_api_client.dart';
import '../../l10n/app_l10n.dart';
import '../api_settings_widgets.dart';
import '../layout_navigation_widgets.dart';

class ApiSettingsWorkspace extends StatelessWidget {
  const ApiSettingsWorkspace({
    required this.apiConfigs,
    required this.selectedApiConfig,
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
  final ApiConfig selectedApiConfig;
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
    return WorkspacePage(
      title: l10n.apiSettingsWorkspaceTitle,
      description: l10n.apiSettingsWorkspaceDescription,
      children: [
        ApiSettingsPanel(
          apiConfigs: apiConfigs,
          selectedApiConfigId: selectedApiConfig.id,
          saveStatus: saveStatus,
          saveErrorMessage: saveErrorMessage,
          isTestingApiConfig: isTestingApiConfig,
          apiTestDebugRecord: apiTestDebugRecord,
          nameController: nameController,
          baseUrlController: baseUrlController,
          apiKeyController: apiKeyController,
          modelController: modelController,
          timeoutController: timeoutController,
          providerKind: providerKind,
          imageSizeCapabilityOverride: imageSizeCapabilityOverride,
          showApiKey: showApiKey,
          availableModels: availableModels,
          isFetchingModels: isFetchingModels,
          modelFetchErrorMessage: modelFetchErrorMessage,
          modelFetchedAt: modelFetchedAt,
          onApiConfigChanged: onApiConfigChanged,
          onAddApiConfig: onAddApiConfig,
          onDeleteApiConfig: onDeleteApiConfig,
          onSaveApiConfig: onSaveApiConfig,
          onTestApiConfig: onTestApiConfig,
          onBasicTestApiConfig: onBasicTestApiConfig,
          onFetchModels: onFetchModels,
          onModelSelected: onModelSelected,
          onProviderKindChanged: onProviderKindChanged,
          onImageSizeCapabilityOverrideChanged:
              onImageSizeCapabilityOverrideChanged,
          onToggleApiKeyVisibility: onToggleApiKeyVisibility,
        ),
      ],
    );
  }
}
