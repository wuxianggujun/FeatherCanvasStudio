import 'package:flutter/material.dart';

import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../models/ui_state.dart';
import '../services/image_api_client.dart';
import '../theme/layout_constants.dart';
import '../utils/api_config_logic.dart';
import '../utils/display_labels.dart';
import '../widgets/common_form_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';

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
    required this.providerKind,
    required this.showApiKey,
    required this.availableModels,
    required this.isFetchingModels,
    required this.modelFetchErrorMessage,
    required this.onApiConfigChanged,
    required this.onAddApiConfig,
    required this.onDeleteApiConfig,
    required this.onSaveApiConfig,
    required this.onTestApiConfig,
    required this.onBasicTestApiConfig,
    required this.onFetchModels,
    required this.onModelSelected,
    required this.onProviderKindChanged,
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
  final ApiProviderKind providerKind;
  final bool showApiKey;
  final List<ApiModelInfo> availableModels;
  final bool isFetchingModels;
  final String? modelFetchErrorMessage;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onAddApiConfig;
  final VoidCallback onDeleteApiConfig;
  final VoidCallback onSaveApiConfig;
  final VoidCallback onTestApiConfig;
  final VoidCallback onBasicTestApiConfig;
  final VoidCallback onFetchModels;
  final ValueChanged<String> onModelSelected;
  final ValueChanged<ApiProviderKind> onProviderKindChanged;
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
            onFetchModels: onFetchModels,
            onModelSelected: onModelSelected,
            onToggleApiKeyVisibility: onToggleApiKeyVisibility,
          ),
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

class _ApiConfigNameField extends StatelessWidget {
  const _ApiConfigNameField({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.controller,
    required this.onConfigSelected,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final TextEditingController controller;
  final ValueChanged<String> onConfigSelected;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '接口名称',
        hintText: '例如 OpenAI 官方、内网代理、备用接口',
        suffixIcon: PopupMenuButton<String>(
          tooltip: '切换接口配置',
          enabled: apiConfigs.isNotEmpty,
          icon: const Icon(Icons.arrow_drop_down),
          onSelected: onConfigSelected,
          itemBuilder: (context) => [
            for (final config in apiConfigs)
              PopupMenuItem<String>(
                value: config.id,
                child: Row(
                  children: [
                    Icon(
                      config.id == selectedApiConfigId
                          ? Icons.check
                          : Icons.http_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(config.name)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApiProviderKindDropdown extends StatelessWidget {
  const _ApiProviderKindDropdown({
    required this.value,
    required this.onChanged,
  });

  final ApiProviderKind value;
  final ValueChanged<ApiProviderKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<ApiProviderKind>(
          key: ValueKey('api-provider-$value'),
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '供应商'),
          items: [
            for (final kind in ApiProviderKind.values)
              DropdownMenuItem<ApiProviderKind>(
                value: kind,
                child: Row(
                  children: [
                    Icon(apiProviderKindIcon(kind), size: 18),
                    const SizedBox(width: 8),
                    Text(apiProviderKindLabel(kind)),
                  ],
                ),
              ),
          ],
          onChanged: (kind) {
            if (kind != null) {
              onChanged(kind);
            }
          },
        ),
        const SizedBox(height: 4),
        Text(
          apiProviderKindDescription(value),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ApiConfigActions extends StatelessWidget {
  const _ApiConfigActions({
    required this.saveStatus,
    required this.isTestingApiConfig,
    required this.apiTestDebugRecord,
    required this.onSaveApiConfig,
    required this.onTestApiConfig,
    required this.onBasicTestApiConfig,
  });

  final ApiConfigSaveStatus saveStatus;
  final bool isTestingApiConfig;
  final ImageRequestDebugRecord? apiTestDebugRecord;
  final VoidCallback onSaveApiConfig;
  final VoidCallback onTestApiConfig;
  final VoidCallback onBasicTestApiConfig;

  @override
  Widget build(BuildContext context) {
    final saveButton = FilledButton.icon(
      onPressed: saveStatus == ApiConfigSaveStatus.saving
          ? null
          : onSaveApiConfig,
      icon: ButtonProgressIcon(
        isBusy: saveStatus == ApiConfigSaveStatus.saving,
        icon: Icons.save_outlined,
      ),
      label: Text(saveStatus == ApiConfigSaveStatus.saving ? '保存中' : '保存配置'),
    );
    final testButton = OutlinedButton.icon(
      onPressed: isTestingApiConfig ? null : onTestApiConfig,
      icon: ButtonProgressIcon(
        isBusy: isTestingApiConfig,
        icon: Icons.cloud_sync_outlined,
      ),
      label: Text(isTestingApiConfig ? '测试中' : '测试接口'),
    );
    final basicTestButton = Tooltip(
      message: '只发送 model/prompt/size/n，先确认接口本身可用',
      child: TextButton.icon(
        onPressed: isTestingApiConfig ? null : onBasicTestApiConfig,
        icon: const Icon(Icons.bolt_outlined, size: 18),
        label: const Text('基础测试'),
      ),
    );
    final debugButton = RequestDebugButton(record: apiTestDebugRecord);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              saveButton,
              const SizedBox(height: 8),
              testButton,
              const SizedBox(height: 8),
              Row(children: [basicTestButton, const Spacer(), debugButton]),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: saveButton),
            const SizedBox(width: 8),
            testButton,
            const SizedBox(width: 8),
            basicTestButton,
            const SizedBox(width: 8),
            debugButton,
          ],
        );
      },
    );
  }
}

class _ApiConfigSaveIndicator extends StatelessWidget {
  const _ApiConfigSaveIndicator({
    required this.status,
    required this.errorMessage,
  });

  final ApiConfigSaveStatus status;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (label, color, icon) = switch (status) {
      ApiConfigSaveStatus.saved => (
        '已保存',
        colorScheme.primary,
        Icons.check_circle_outline,
      ),
      ApiConfigSaveStatus.pending => (
        '未保存',
        colorScheme.secondary,
        Icons.schedule,
      ),
      ApiConfigSaveStatus.saving => ('保存中', colorScheme.secondary, Icons.sync),
      ApiConfigSaveStatus.failed => (
        '保存失败',
        colorScheme.error,
        Icons.error_outline,
      ),
    };
    final tooltip = status == ApiConfigSaveStatus.failed
        ? '保存失败：${errorMessage ?? '未知错误'}'
        : label;

    return Tooltip(
      message: tooltip,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: Container(
          key: ValueKey(status),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == ApiConfigSaveStatus.saving)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionSettingsFields extends StatelessWidget {
  const _ConnectionSettingsFields({
    required this.baseUrlController,
    required this.apiKeyController,
    required this.modelController,
    required this.providerKind,
    required this.showApiKey,
    required this.availableModels,
    required this.isFetchingModels,
    required this.modelFetchErrorMessage,
    required this.onFetchModels,
    required this.onModelSelected,
    required this.onToggleApiKeyVisibility,
  });

  final TextEditingController baseUrlController;
  final TextEditingController apiKeyController;
  final TextEditingController modelController;
  final ApiProviderKind providerKind;
  final bool showApiKey;
  final List<ApiModelInfo> availableModels;
  final bool isFetchingModels;
  final String? modelFetchErrorMessage;
  final VoidCallback onFetchModels;
  final ValueChanged<String> onModelSelected;
  final VoidCallback onToggleApiKeyVisibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedModel = matchingFetchedModel(
      availableModels,
      modelController.text,
    )?.id;
    final modelListKey = Object.hashAll(
      availableModels.map((model) => Object.hash(model.id, model.ownedBy)),
    );
    final hasFetchedModels = availableModels.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: baseUrlController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Base URL',
            hintText: defaultBaseUrlForProviderKind(providerKind),
          ),
        ),
        const SizedBox(height: fieldGap),
        TextField(
          controller: apiKeyController,
          obscureText: !showApiKey,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: apiKeyHintForProviderKind(providerKind),
            suffixIcon: IconButton(
              tooltip: showApiKey ? '隐藏密钥' : '显示密钥',
              onPressed: onToggleApiKeyVisibility,
              icon: Icon(
                showApiKey
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: fieldGap),
        TextField(
          controller: modelController,
          decoration: InputDecoration(
            labelText: '模型',
            hintText: defaultModelForProviderKind(providerKind),
            helperText: _modelFetchHelperText(
              availableModels: availableModels,
              isFetchingModels: isFetchingModels,
              modelFetchErrorMessage: modelFetchErrorMessage,
            ),
            helperMaxLines: 2,
            suffixIcon: Tooltip(
              message: hasFetchedModels ? '刷新模型列表' : '获取模型列表',
              child: IconButton(
                onPressed: isFetchingModels ? null : onFetchModels,
                icon: ButtonProgressIcon(
                  isBusy: isFetchingModels,
                  icon: Icons.manage_search_outlined,
                ),
              ),
            ),
          ),
        ),
        if (availableModels.isNotEmpty) ...[
          const SizedBox(height: fieldGap),
          DropdownButtonFormField<String>(
            key: ValueKey('api-model-$modelListKey-$selectedModel'),
            initialValue: selectedModel,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: '可用模型',
              helperText: '选择后会写入上方模型字段，保存配置后生效',
              prefixIcon: const Icon(Icons.list_alt_outlined),
            ),
            items: [
              for (final model in availableModels)
                DropdownMenuItem<String>(
                  value: model.id,
                  child: Text(
                    model.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                onModelSelected(value);
              }
            },
          ),
        ],
        if (modelFetchErrorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  modelFetchErrorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _modelFetchHelperText({
    required List<ApiModelInfo> availableModels,
    required bool isFetchingModels,
    required String? modelFetchErrorMessage,
  }) {
    if (isFetchingModels) {
      return '正在获取模型列表...';
    }
    if (availableModels.isNotEmpty) {
      return '已获取 ${availableModels.length} 个模型';
    }
    if (modelFetchErrorMessage != null) {
      return '模型列表获取失败，可修正配置后重试';
    }
    return '尚未获取模型列表';
  }
}
