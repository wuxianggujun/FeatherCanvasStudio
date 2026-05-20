part of 'package:feather_canvas_studio/main.dart';

mixin _ApiConfigStateMixin on State<FeatherCanvasHomePage> {
  bool get _isBootstrapping;
  bool get _isRestoringState;
  set _isRestoringState(bool value);
  AppLocalStore get _store;
  OpenAICompatibleImageClient get _client;
  Future<void> _saveSettings();
  void _showMessage(String message);
  String get _size;
  set _size(String value);

  final TextEditingController _baseUrlController = TextEditingController(
    text: defaultAppSettings.baseUrl,
  );
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController(
    text: defaultAppSettings.model,
  );
  final TextEditingController _apiConfigNameController = TextEditingController(
    text: '默认配置',
  );
  final TextEditingController _generationTimeoutController =
      TextEditingController(
        text: ApiConfig.defaultGenerationTimeoutSeconds.toString(),
      );

  bool _isTestingApiConfig = false;
  bool _showApiKey = false;
  List<ApiConfig> _apiConfigs = const [];
  String? _selectedApiConfigId;
  ApiProviderKind _apiConfigProviderKind = ApiProviderKind.compatible;
  ApiConfigSaveStatus _apiConfigSaveStatus = ApiConfigSaveStatus.saved;
  String? _apiConfigSaveErrorMessage;
  ImageRequestDebugRecord? _apiTestDebugRecord;
  bool _isFetchingApiModels = false;
  ImageSizeCapabilityOverride _imageSizeCapabilityOverride =
      ImageSizeCapabilityOverride.auto;
  Map<String, List<ApiModelInfo>> _apiModelCache = const {};
  Map<String, String> _apiModelFetchErrorCache = const {};
  Map<String, DateTime> _apiModelFetchedAtCache = const {};
  int _apiConfigSaveVersion = 0;
  Timer? _apiConfigSaveDebounce;

  ApiConfig get _selectedApiConfig {
    return resolveApiConfig(_apiConfigs, _selectedApiConfigId);
  }

  ApiConfig get _currentApiConfigDraft {
    return buildApiConfigDraft(
      selectedId: _selectedApiConfigId,
      nameText: _apiConfigNameController.text,
      baseUrlText: _baseUrlController.text,
      apiKeyText: _apiKeyController.text,
      modelText: _modelController.text,
      providerKind: _apiConfigProviderKind,
      imageSizeCapabilityOverride: _imageSizeCapabilityOverride,
      timeoutText: _generationTimeoutController.text,
    );
  }

  List<ApiModelInfo> get _visibleApiModels {
    final requestKey = apiModelRequestKey(_currentApiConfigDraft);
    return _apiModelCache[requestKey] ?? const [];
  }

  String? get _visibleApiModelFetchErrorMessage {
    final requestKey = apiModelRequestKey(_currentApiConfigDraft);
    return _apiModelFetchErrorCache[requestKey];
  }

  DateTime? get _visibleApiModelFetchedAt {
    final requestKey = apiModelRequestKey(_currentApiConfigDraft);
    return _apiModelFetchedAtCache[requestKey];
  }

  void _initApiConfigState() {
    _apiConfigNameController.addListener(_markApiConfigDirty);
    _baseUrlController.addListener(_markApiConfigDirty);
    _apiKeyController.addListener(_markApiConfigDirty);
    _modelController.addListener(_markApiConfigDirty);
    _generationTimeoutController.addListener(_markApiConfigDirty);
  }

  void _disposeApiConfigState() {
    _apiConfigSaveDebounce?.cancel();
    _apiConfigNameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _generationTimeoutController.dispose();
  }

  Future<ApiConfig> _prepareSelectedApiConfigForRequest() async {
    _apiConfigSaveDebounce?.cancel();
    return _selectedApiConfig;
  }

  void _markApiConfigDirty() {
    if (_isBootstrapping || _isRestoringState) {
      return;
    }

    _apiConfigSaveDebounce?.cancel();
    ++_apiConfigSaveVersion;
    setState(() {
      _apiConfigSaveStatus = ApiConfigSaveStatus.pending;
      _apiConfigSaveErrorMessage = null;
    });
  }

  Future<void> _saveCurrentApiConfig({int? saveVersion}) async {
    final activeSaveVersion = saveVersion ?? _apiConfigSaveVersion;
    if (mounted) {
      setState(() {
        _apiConfigSaveStatus = ApiConfigSaveStatus.saving;
        _apiConfigSaveErrorMessage = null;
      });
    }

    final selectedId = _selectedApiConfigId ?? ApiConfig.newId();
    final nextConfig = buildApiConfigDraft(
      selectedId: selectedId,
      nameText: _apiConfigNameController.text,
      baseUrlText: _baseUrlController.text,
      apiKeyText: _apiKeyController.text,
      modelText: _modelController.text,
      providerKind: _apiConfigProviderKind,
      imageSizeCapabilityOverride: _imageSizeCapabilityOverride,
      timeoutText: _generationTimeoutController.text,
    );

    final nextConfigs = upsertApiConfig(_apiConfigs, nextConfig);
    final normalizedSize = safeImageSizeForModel(
      size: _size,
      providerKind: nextConfig.providerKind,
      model: nextConfig.model,
      capabilityOverride: nextConfig.imageSizeCapabilityOverride,
    );

    if (mounted) {
      setState(() {
        _apiConfigs = nextConfigs;
        _selectedApiConfigId = selectedId;
        _size = normalizedSize;
      });
    } else {
      _apiConfigs = nextConfigs;
      _selectedApiConfigId = selectedId;
      _size = normalizedSize;
    }

    try {
      await _store.saveApiConfigs(nextConfigs);
      await _store.saveSelectedApiConfigId(selectedId);
      await _saveSettings();
      if (mounted && activeSaveVersion == _apiConfigSaveVersion) {
        setState(() {
          _apiConfigSaveStatus = ApiConfigSaveStatus.saved;
          _apiConfigSaveErrorMessage = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _apiConfigSaveStatus = ApiConfigSaveStatus.failed;
          _apiConfigSaveErrorMessage = error.toString();
        });
      }
    }
  }

  void _saveSelectedApiConfig() {
    _apiConfigSaveDebounce?.cancel();
    final saveVersion = ++_apiConfigSaveVersion;
    unawaited(_saveCurrentApiConfig(saveVersion: saveVersion));
  }

  Future<void> _testCurrentApiConfig({bool basic = false}) async {
    final apiConfig = _currentApiConfigDraft;
    final l10n = appL10nOf(context);

    setState(() {
      _isTestingApiConfig = true;
      _apiTestDebugRecord = null;
    });

    final result = await testApiConfigConnection(
      client: _client,
      apiConfig: apiConfig,
      basic: basic,
      labels: localizedApiConfigServiceLabels(l10n),
      onDebugRecord: (record) {
        _apiTestDebugRecord = record;
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _apiTestDebugRecord = result.debugRecord ?? _apiTestDebugRecord;
      _isTestingApiConfig = false;
    });
    _showMessage(result.message);
  }

  Future<void> _fetchCurrentApiModels() async {
    final apiConfig = _currentApiConfigDraft;
    final requestKey = apiModelRequestKey(apiConfig);
    final l10n = appL10nOf(context);

    setState(() {
      _isFetchingApiModels = true;
      _apiModelFetchErrorCache = updateApiModelFetchErrorCache(
        cache: _apiModelFetchErrorCache,
        requestKey: requestKey,
        errorMessage: null,
      );
    });

    final result = await fetchApiModelsForConfig(
      client: _client,
      apiConfig: apiConfig,
      labels: localizedApiConfigServiceLabels(l10n),
    );

    if (!mounted) {
      return;
    }

    if (apiModelRequestKey(_currentApiConfigDraft) != requestKey) {
      setState(() => _isFetchingApiModels = false);
      return;
    }

    setState(() {
      if (result.success) {
        _apiModelCache = cacheApiModelsForRequest(
          cache: _apiModelCache,
          requestKey: result.requestKey,
          models: result.models,
        );
        _apiModelFetchedAtCache = Map.unmodifiable({
          ..._apiModelFetchedAtCache,
          result.requestKey: DateTime.now(),
        });
      }
      _apiModelFetchErrorCache = updateApiModelFetchErrorCache(
        cache: _apiModelFetchErrorCache,
        requestKey: result.requestKey,
        errorMessage: result.errorMessage,
      );
      _isFetchingApiModels = false;
    });

    final autoSelectedModel = result.autoSelectedModel;
    if (autoSelectedModel != null &&
        _modelController.text.trim() != autoSelectedModel.id) {
      _modelController.text = autoSelectedModel.id;
      if (mounted) {
        setState(() {
          _size = safeImageSizeForModel(
            size: _size,
            providerKind: _apiConfigProviderKind,
            model: autoSelectedModel.id,
            capabilityOverride: _imageSizeCapabilityOverride,
          );
        });
      }
    }

    _showMessage(result.message);
  }

  void _selectFetchedApiModel(String modelId) {
    _modelController.text = modelId;
    setState(() {
      _size = safeImageSizeForModel(
        size: _size,
        providerKind: _apiConfigProviderKind,
        model: modelId,
        capabilityOverride: _imageSizeCapabilityOverride,
      );
    });
  }

  Future<void> _selectApiConfig(String id) async {
    _apiConfigSaveDebounce?.cancel();
    final nextConfig = resolveApiConfig(_apiConfigs, id);
    _isRestoringState = true;
    _apiConfigNameController.text = nextConfig.name;
    _baseUrlController.text = nextConfig.baseUrl;
    _apiKeyController.text = nextConfig.apiKey;
    _modelController.text = nextConfig.model;
    _generationTimeoutController.text = nextConfig.generationTimeoutSeconds
        .toString();
    if (mounted) {
      setState(() {
        _selectedApiConfigId = nextConfig.id;
        _apiConfigProviderKind = nextConfig.providerKind;
        _imageSizeCapabilityOverride = nextConfig.imageSizeCapabilityOverride;
        _size = safeImageSizeForModel(
          size: _size,
          providerKind: nextConfig.providerKind,
          model: nextConfig.model,
          capabilityOverride: nextConfig.imageSizeCapabilityOverride,
        );
        _apiConfigSaveStatus = ApiConfigSaveStatus.saved;
        _apiConfigSaveErrorMessage = null;
      });
    } else {
      _selectedApiConfigId = nextConfig.id;
      _apiConfigProviderKind = nextConfig.providerKind;
      _imageSizeCapabilityOverride = nextConfig.imageSizeCapabilityOverride;
    }
    _isRestoringState = false;

    await _store.saveSelectedApiConfigId(nextConfig.id);
    await _saveSettings();
  }

  Future<void> _addApiConfig() async {
    _apiConfigSaveDebounce?.cancel();

    final nextConfig = createCompatibleApiConfig();
    final nextConfigs = [..._apiConfigs, nextConfig];
    setState(() => _apiConfigs = nextConfigs);
    await _store.saveApiConfigs(nextConfigs);
    await _selectApiConfig(nextConfig.id);
  }

  void _setApiConfigProviderKind(ApiProviderKind kind) {
    if (kind == _apiConfigProviderKind) {
      return;
    }
    final fields = apiProviderKindDefaultedFields(
      previousKind: _apiConfigProviderKind,
      nextKind: kind,
      currentBaseUrl: _baseUrlController.text,
      currentModel: _modelController.text,
    );

    _isRestoringState = true;
    _baseUrlController.text = fields.baseUrl;
    _modelController.text = fields.model;
    _isRestoringState = false;
    final normalizedSizeOverride =
        normalizeImageSizeCapabilityOverrideForProvider(
          providerKind: kind,
          imageSizeCapabilityOverride: _imageSizeCapabilityOverride,
        );
    setState(() {
      _apiConfigProviderKind = kind;
      _imageSizeCapabilityOverride = normalizedSizeOverride;
      _size = safeImageSizeForModel(
        size: _size,
        providerKind: kind,
        model: fields.model,
        capabilityOverride: normalizedSizeOverride,
      );
    });
    _markApiConfigDirty();
  }

  void _setImageSizeCapabilityOverride(
    ImageSizeCapabilityOverride capabilityOverride,
  ) {
    final normalizedSizeOverride =
        normalizeImageSizeCapabilityOverrideForProvider(
          providerKind: _apiConfigProviderKind,
          imageSizeCapabilityOverride: capabilityOverride,
        );
    if (normalizedSizeOverride == _imageSizeCapabilityOverride) {
      return;
    }

    setState(() {
      _imageSizeCapabilityOverride = normalizedSizeOverride;
      _size = safeImageSizeForModel(
        size: _size,
        providerKind: _apiConfigProviderKind,
        model: _modelController.text,
        capabilityOverride: normalizedSizeOverride,
      );
    });
    _markApiConfigDirty();
  }

  Future<void> _deleteSelectedApiConfig() async {
    if (_apiConfigs.length <= 1) {
      _showMessage(appL10nOf(context).apiConfigDeleteLastMessage);
      return;
    }

    final result = deleteApiConfigSelection(_apiConfigs, _selectedApiConfigId);
    if (result == null) {
      return;
    }

    setState(() => _apiConfigs = result.configs);
    await _store.saveApiConfigs(result.configs);
    await _selectApiConfig(result.selectedConfig.id);
  }

  Widget _buildApiSettingsWorkspace() {
    return ApiSettingsWorkspace(
      apiConfigs: _apiConfigs,
      selectedApiConfig: _selectedApiConfig,
      saveStatus: _apiConfigSaveStatus,
      saveErrorMessage: _apiConfigSaveErrorMessage,
      isTestingApiConfig: _isTestingApiConfig,
      apiTestDebugRecord: _apiTestDebugRecord,
      nameController: _apiConfigNameController,
      baseUrlController: _baseUrlController,
      apiKeyController: _apiKeyController,
      modelController: _modelController,
      timeoutController: _generationTimeoutController,
      providerKind: _apiConfigProviderKind,
      imageSizeCapabilityOverride: _imageSizeCapabilityOverride,
      showApiKey: _showApiKey,
      availableModels: _visibleApiModels,
      isFetchingModels: _isFetchingApiModels,
      modelFetchErrorMessage: _visibleApiModelFetchErrorMessage,
      modelFetchedAt: _visibleApiModelFetchedAt,
      onApiConfigChanged: _selectApiConfig,
      onAddApiConfig: _addApiConfig,
      onDeleteApiConfig: _deleteSelectedApiConfig,
      onSaveApiConfig: _saveSelectedApiConfig,
      onTestApiConfig: () => _testCurrentApiConfig(),
      onBasicTestApiConfig: () => _testCurrentApiConfig(basic: true),
      onFetchModels: _fetchCurrentApiModels,
      onModelSelected: _selectFetchedApiModel,
      onProviderKindChanged: _setApiConfigProviderKind,
      onImageSizeCapabilityOverrideChanged: _setImageSizeCapabilityOverride,
      onToggleApiKeyVisibility: () =>
          setState(() => _showApiKey = !_showApiKey),
    );
  }
}
