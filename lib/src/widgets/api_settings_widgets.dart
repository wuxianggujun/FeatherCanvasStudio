import 'package:flutter/material.dart';

import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../models/ui_state.dart';
import '../services/image_api_client.dart';
import '../theme/layout_constants.dart';
import '../utils/api_config_logic.dart';
import '../utils/date_formatting.dart';
import '../utils/display_labels.dart';
import '../utils/image_dimensions.dart';
import '../widgets/common_form_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';

part 'api_settings_panel_widgets.dart';

String apiModelFetchHelperText({
  required List<ApiModelInfo> availableModels,
  required bool isFetchingModels,
  required String? modelFetchErrorMessage,
  required DateTime? modelFetchedAt,
}) {
  final hasFetchedModels = modelFetchedAt != null;
  if (isFetchingModels) {
    if (availableModels.isNotEmpty) {
      return '正在刷新模型列表，当前显示 ${availableModels.length} 个缓存模型';
    }
    if (hasFetchedModels) {
      return '正在刷新模型列表，当前缓存为空';
    }
    return '正在获取模型列表...';
  }

  final hasModels = availableModels.isNotEmpty;
  final hasError =
      modelFetchErrorMessage != null &&
      modelFetchErrorMessage.trim().isNotEmpty;
  final fetchedAtLabel = modelFetchedAt == null
      ? null
      : '上次成功：${formatTimestamp(modelFetchedAt)}';

  if (hasError && hasModels) {
    return fetchedAtLabel == null
        ? '刷新失败，继续显示 ${availableModels.length} 个缓存模型'
        : '刷新失败，继续显示 ${availableModels.length} 个缓存模型，$fetchedAtLabel';
  }
  if (hasModels) {
    return fetchedAtLabel == null
        ? '已获取 ${availableModels.length} 个模型'
        : '已缓存 ${availableModels.length} 个模型，$fetchedAtLabel';
  }
  if (hasError) {
    if (hasFetchedModels) {
      return fetchedAtLabel == null
          ? '模型列表刷新失败，当前缓存为空，可修正配置后重试'
          : '模型列表刷新失败，当前缓存为空，$fetchedAtLabel';
    }
    return '模型列表获取失败，可修正配置后重试';
  }
  if (hasFetchedModels) {
    return fetchedAtLabel == null ? '已获取 0 个模型' : '已缓存 0 个模型，$fetchedAtLabel';
  }
  return '尚未获取模型列表';
}

class ApiConfigSelector extends StatelessWidget {
  const ApiConfigSelector({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.onChanged,
    this.onOpenSettings,
    super.key,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ValueChanged<String> onChanged;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('api-config-$selectedValue'),
            initialValue: selectedValue,
            decoration: const InputDecoration(labelText: '接口配置'),
            items: [
              for (final config in apiConfigs)
                DropdownMenuItem<String>(
                  value: config.id,
                  child: Text(config.name),
                ),
            ],
            onChanged: apiConfigs.isEmpty
                ? null
                : (value) {
                    if (value != null) {
                      onChanged(value);
                    }
                  },
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: '管理接口配置',
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
    return AppPanel(
      title: '接口配置',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ApiConfigSaveIndicator(
            status: saveStatus,
            errorMessage: saveErrorMessage,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '新增配置',
            onPressed: onAddApiConfig,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: '删除当前配置',
            onPressed: apiConfigs.length <= 1 ? null : onDeleteApiConfig,
            icon: const Icon(Icons.delete_outline),
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
