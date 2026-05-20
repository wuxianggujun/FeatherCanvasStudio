part of 'api_settings_widgets.dart';

class _GenerationTimeoutField extends StatelessWidget {
  const _GenerationTimeoutField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      decoration: InputDecoration(
        labelText: l10n.apiTimeoutLabel,
        hintText: '${ApiConfig.defaultGenerationTimeoutSeconds}',
        helperText: l10n.apiTimeoutHelper(
          ApiConfig.defaultGenerationTimeoutSeconds,
          ApiConfig.minGenerationTimeoutSeconds,
          ApiConfig.maxGenerationTimeoutSeconds,
        ),
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
    final l10n = appL10nOf(context);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: l10n.apiConfigNameLabel,
        hintText: l10n.apiConfigNameHint,
        suffixIcon: PopupMenuButton<String>(
          tooltip: l10n.apiConfigSwitchTooltip,
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
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: l10n.apiProviderLabel,
          value: localizedApiProviderKindLabel(l10n, value),
          child: DropdownButtonFormField<ApiProviderKind>(
            key: ValueKey('api-provider-$value'),
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.apiProviderLabel),
            items: [
              for (final kind in ApiProviderKind.values)
                DropdownMenuItem<ApiProviderKind>(
                  value: kind,
                  child: Row(
                    children: [
                      Icon(apiProviderKindIcon(kind), size: 18),
                      const SizedBox(width: 8),
                      Text(localizedApiProviderKindLabel(l10n, kind)),
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
        ),
        const SizedBox(height: 4),
        Text(
          localizedApiProviderKindDescription(l10n, value),
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
    final l10n = appL10nOf(context);
    final saveButton = FilledButton.icon(
      onPressed: saveStatus == ApiConfigSaveStatus.saving
          ? null
          : onSaveApiConfig,
      icon: ButtonProgressIcon(
        isBusy: saveStatus == ApiConfigSaveStatus.saving,
        icon: Icons.save_outlined,
      ),
      label: Text(
        saveStatus == ApiConfigSaveStatus.saving
            ? l10n.apiSaving
            : l10n.apiSaveConfig,
      ),
    );
    final testButton = OutlinedButton.icon(
      onPressed: isTestingApiConfig ? null : onTestApiConfig,
      icon: ButtonProgressIcon(
        isBusy: isTestingApiConfig,
        icon: Icons.cloud_sync_outlined,
      ),
      label: Text(isTestingApiConfig ? l10n.apiTesting : l10n.apiTestConfig),
    );
    final basicTestButton = Tooltip(
      message: l10n.apiBasicTestTooltip,
      child: TextButton.icon(
        onPressed: isTestingApiConfig ? null : onBasicTestApiConfig,
        icon: const Icon(Icons.bolt_outlined, size: 18),
        label: Text(l10n.apiBasicTest),
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
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (label, color, icon) = switch (status) {
      ApiConfigSaveStatus.saved => (
        l10n.apiSaveStatusSaved,
        colorScheme.primary,
        Icons.check_circle_outline,
      ),
      ApiConfigSaveStatus.pending => (
        l10n.apiSaveStatusPending,
        colorScheme.secondary,
        Icons.schedule,
      ),
      ApiConfigSaveStatus.saving => (
        l10n.apiSaveStatusSaving,
        colorScheme.secondary,
        Icons.sync,
      ),
      ApiConfigSaveStatus.failed => (
        l10n.apiSaveStatusFailed,
        colorScheme.error,
        Icons.error_outline,
      ),
    };
    final tooltip = status == ApiConfigSaveStatus.failed
        ? l10n.apiSaveFailedTooltip(errorMessage ?? l10n.unknownError)
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

class _ImageSizeCapabilityOverrideDropdown extends StatelessWidget {
  const _ImageSizeCapabilityOverrideDropdown({
    required this.providerKind,
    required this.model,
    required this.value,
    required this.onChanged,
  });

  final ApiProviderKind providerKind;
  final String model;
  final ImageSizeCapabilityOverride value;
  final ValueChanged<ImageSizeCapabilityOverride> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final availableOverrides = ImageSizeCapabilityOverride.values
        .where(
          (override) => providerKind == ApiProviderKind.gemini
              ? override != ImageSizeCapabilityOverride.customPixels
              : override != ImageSizeCapabilityOverride.aspectRatio,
        )
        .toList(growable: false);
    final normalizedValue = normalizeImageSizeCapabilityOverrideForProvider(
      providerKind: providerKind,
      imageSizeCapabilityOverride: value,
    );
    final selectedValue = availableOverrides.contains(normalizedValue)
        ? normalizedValue
        : ImageSizeCapabilityOverride.auto;
    final capabilities = imageModelCapabilitiesFor(
      providerKind: providerKind,
      model: model,
      capabilityOverride: selectedValue,
    );
    final autoCapabilities = imageModelCapabilitiesFor(
      providerKind: providerKind,
      model: model,
    );
    final imageSizeLabels = localizedImageSizeDisplayLabels(l10n);
    final helperText = selectedValue == ImageSizeCapabilityOverride.auto
        ? l10n.apiImageSizeCapabilityAuto(
            imageSizeCapabilityLabel(autoCapabilities, labels: imageSizeLabels),
          )
        : l10n.apiImageSizeCapabilityDescription(
            imageSizeCapabilityLabel(capabilities, labels: imageSizeLabels),
            imageSizeCapabilityDescription(
              capabilities,
              labels: imageSizeLabels,
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: l10n.apiImageSizeCapabilityLabel,
          value: imageSizeCapabilityOverrideLabel(
            selectedValue,
            labels: imageSizeLabels,
          ),
          child: DropdownButtonFormField<ImageSizeCapabilityOverride>(
            key: ValueKey(
              'image-size-capability-$providerKind-$model-$selectedValue',
            ),
            initialValue: selectedValue,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.apiImageSizeCapabilityLabel,
            ),
            items: [
              for (final override in availableOverrides)
                DropdownMenuItem<ImageSizeCapabilityOverride>(
                  value: override,
                  child: Text(
                    imageSizeCapabilityOverrideLabel(
                      override,
                      labels: imageSizeLabels,
                    ),
                  ),
                ),
            ],
            onChanged: (override) {
              if (override != null) {
                onChanged(override);
              }
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final hasFetchedModels = modelFetchedAt != null;
    final hasAnyModels = availableModels.isNotEmpty;
    final fetchActionLabel = hasFetchedModels
        ? l10n.apiRefreshModelList
        : l10n.apiFetchModelList;

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
              tooltip: showApiKey ? l10n.apiHideKey : l10n.apiShowKey,
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
            labelText: l10n.apiModelLabel,
            hintText: localizedApiModelHintForProviderKind(l10n, providerKind),
            helperText: apiModelFetchHelperText(
              availableModels: availableModels,
              isFetchingModels: isFetchingModels,
              modelFetchErrorMessage: modelFetchErrorMessage,
              modelFetchedAt: modelFetchedAt,
              l10n: l10n,
            ),
            helperMaxLines: 2,
            suffixIcon: _ModelPickerButton(
              isFetchingModels: isFetchingModels,
              hasAnyModels: hasAnyModels,
              fetchActionLabel: fetchActionLabel,
              availableModels: availableModels,
              currentModelId: modelController.text,
              onFetchModels: onFetchModels,
              onModelSelected: onModelSelected,
            ),
          ),
        ),
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

class _ModelPickerButton extends StatelessWidget {
  const _ModelPickerButton({
    required this.isFetchingModels,
    required this.hasAnyModels,
    required this.fetchActionLabel,
    required this.availableModels,
    required this.currentModelId,
    required this.onFetchModels,
    required this.onModelSelected,
  });

  static const String _fetchActionValue = '__fetch__';

  final bool isFetchingModels;
  final bool hasAnyModels;
  final String fetchActionLabel;
  final List<ApiModelInfo> availableModels;
  final String currentModelId;
  final VoidCallback onFetchModels;
  final ValueChanged<String> onModelSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final tooltip = hasAnyModels
        ? l10n.apiModelPickerTooltip
        : fetchActionLabel;
    final normalizedCurrent = normalizeModelIdForSelection(currentModelId);

    return PopupMenuButton<String>(
      enabled: !isFetchingModels,
      tooltip: tooltip,
      position: PopupMenuPosition.under,
      icon: ButtonProgressIcon(
        isBusy: isFetchingModels,
        icon: hasAnyModels
            ? Icons.list_alt_outlined
            : Icons.manage_search_outlined,
      ),
      onSelected: (value) {
        if (value == _fetchActionValue) {
          onFetchModels();
        } else {
          onModelSelected(value);
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            value: _fetchActionValue,
            child: Row(
              children: [
                const Icon(Icons.manage_search_outlined, size: 18),
                const SizedBox(width: 8),
                Text(fetchActionLabel),
              ],
            ),
          ),
          if (hasAnyModels) const PopupMenuDivider(),
          for (final model in availableModels)
            PopupMenuItem<String>(
              value: model.id,
              child: Row(
                children: [
                  Icon(
                    normalizeModelIdForSelection(model.id) == normalizedCurrent
                        ? Icons.check
                        : Icons.circle_outlined,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      model.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ];
      },
    );
  }
}
