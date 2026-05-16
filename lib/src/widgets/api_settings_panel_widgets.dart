part of 'api_settings_widgets.dart';

class _GenerationTimeoutField extends StatelessWidget {
  const _GenerationTimeoutField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      decoration: InputDecoration(
        labelText: '请求超时（秒）',
        hintText: '${ApiConfig.defaultGenerationTimeoutSeconds}',
        helperText:
            '默认 ${ApiConfig.defaultGenerationTimeoutSeconds} 秒，范围 '
            '${ApiConfig.minGenerationTimeoutSeconds}–'
            '${ApiConfig.maxGenerationTimeoutSeconds}；image-2 等慢模型可调大',
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.timer_outlined),
      ),
      style: theme.textTheme.bodyMedium,
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
    required this.modelFetchedAt,
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
  final DateTime? modelFetchedAt;
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
    final hasFetchedModels = modelFetchedAt != null;

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
            hintText: apiModelHintForProviderKind(providerKind),
            helperText: apiModelFetchHelperText(
              availableModels: availableModels,
              isFetchingModels: isFetchingModels,
              modelFetchErrorMessage: modelFetchErrorMessage,
              modelFetchedAt: modelFetchedAt,
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
}
