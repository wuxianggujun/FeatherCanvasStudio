// ignore_for_file: annotate_overrides

part of 'package:feather_canvas_studio/main.dart';

const int _historyMenuMaxItems = 8;

enum _MessageLevel { info, success, warning, error }

class _ResetDefaultsSnapshot {
  const _ResetDefaultsSnapshot({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.apiConfigProviderKind,
    required this.imageSizeCapabilityOverride,
    required this.apiConfigName,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.generationTimeout,
    required this.prompt,
    required this.negativePrompt,
    required this.animationPrompt,
    required this.user,
    required this.size,
    required this.imageCount,
    required this.advancedSettings,
    required this.spriteSheetImportConfig,
    required this.editorRows,
    required this.editorColumns,
    required this.editorGridSpec,
    required this.editorTargetFrameIndex,
    required this.editorFrameFit,
    required this.errorMessage,
    required this.animationErrorMessage,
    required this.imageRequestDebugRecord,
    required this.animationRequestDebugRecord,
    required this.generatedImages,
    required this.animationFrames,
    required this.imageTemplateImagePath,
    required this.animationTemplateImagePath,
    required this.editorImagePath,
    required this.editorPatchImagePath,
    required this.generalEditorImagePath,
    required this.generalEditorImageInfo,
    required this.generalEditorErrorMessage,
    required this.editorErrorMessage,
    required this.gifDefaultFrameDelayMs,
    required this.gifLoopCount,
    required this.gifPlaybackMode,
    required this.apiTestDebugRecord,
    required this.isTestingApiConfig,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ApiProviderKind apiConfigProviderKind;
  final ImageSizeCapabilityOverride imageSizeCapabilityOverride;
  final String apiConfigName;
  final String baseUrl;
  final String apiKey;
  final String model;
  final String generationTimeout;
  final String prompt;
  final String negativePrompt;
  final String animationPrompt;
  final String user;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final SpriteSheetImportConfig spriteSheetImportConfig;
  final int editorRows;
  final int editorColumns;
  final SpriteSheetGridSpec editorGridSpec;
  final int editorTargetFrameIndex;
  final SpriteSheetFrameFit editorFrameFit;
  final String? errorMessage;
  final String? animationErrorMessage;
  final ImageRequestDebugRecord? imageRequestDebugRecord;
  final ImageRequestDebugRecord? animationRequestDebugRecord;
  final List<GeneratedImage> generatedImages;
  final List<GeneratedImage> animationFrames;
  final String? imageTemplateImagePath;
  final String? animationTemplateImagePath;
  final String? editorImagePath;
  final String? editorPatchImagePath;
  final String? generalEditorImagePath;
  final ImageInspectionResult? generalEditorImageInfo;
  final String? generalEditorErrorMessage;
  final String? editorErrorMessage;
  final int gifDefaultFrameDelayMs;
  final int gifLoopCount;
  final GifPlaybackMode gifPlaybackMode;
  final ImageRequestDebugRecord? apiTestDebugRecord;
  final bool isTestingApiConfig;
}

mixin _HomeShellStateMixin
    on
        State<FeatherCanvasHomePage>,
        _ApiConfigStateMixin,
        _LocalSettingsStateMixin,
        _ImageLibraryStateMixin,
        _EditorGifStateMixin,
        _ImageGenerationStateMixin,
        _BatchGenerationStateMixin,
        _HistoryStateMixin {
  @override
  AppLocalStore get _store;
  ImageGenerationNotifier get _imageGenerationNotifier;
  BatchGenerationNotifier get _batchGenerationNotifier;
  ImageEditorNotifier get _imageEditorNotifier;
  ImageLibraryNotifier get _imageLibraryNotifier;
  @override
  bool get _isBootstrapping;
  set _isBootstrapping(bool value);
  @override
  bool get _isRestoringState;
  @override
  set _isRestoringState(bool value);
  @override
  WorkspaceFeature get _selectedFeature;
  @override
  set _selectedFeature(WorkspaceFeature value);
  @override
  set _errorMessage(String? value);
  set _imageTemplateImagePath(String? value);
  @override
  set _animationTemplateImagePath(String? value);
  @override
  set _editorImagePath(String? value);
  @override
  set _editorPatchImagePath(String? value);
  @override
  set _generalEditorImagePath(String? value);
  @override
  set _generalEditorImageInfo(ImageInspectionResult? value);
  @override
  set _generalEditorErrorMessage(String? value);
  @override
  set _editorErrorMessage(String? value);
  @override
  bool get _isImageEditorFocusMode;
  @override
  set _isImageEditorFocusMode(bool value);
  bool get _isPixelArtFocusMode;
  set _isPixelArtFocusMode(bool value);
  set _animationErrorMessage(String? value);
  @override
  set _imageRequestDebugRecord(ImageRequestDebugRecord? value);
  @override
  set _animationRequestDebugRecord(ImageRequestDebugRecord? value);
  @override
  set _generatedImages(List<GeneratedImage> value);
  @override
  set _animationFrames(List<GeneratedImage> value);
  @override
  SpriteSheetImportConfig get _spriteSheetImportConfig;
  @override
  set _spriteSheetImportConfig(SpriteSheetImportConfig value);
  @override
  set _editorRows(int value);
  @override
  set _editorColumns(int value);
  @override
  set _editorGridSpec(SpriteSheetGridSpec value);
  @override
  set _editorTargetFrameIndex(int value);
  @override
  set _editorFrameFit(SpriteSheetFrameFit value);
  set _gifDefaultFrameDelayMs(int value);
  @override
  set _gifLoopCount(int value);
  @override
  set _gifPlaybackMode(GifPlaybackMode value);
  @override
  Timer? get _settingsSaveDebounce;
  @override
  set _settingsSaveDebounce(Timer? value);
  @override
  Timer? get _apiConfigSaveDebounce;
  @override
  set _apiConfigSaveDebounce(Timer? value);
  @override
  List<ApiConfig> get _apiConfigs;
  @override
  set _apiConfigs(List<ApiConfig> value);
  @override
  String? get _selectedApiConfigId;
  @override
  set _selectedApiConfigId(String? value);
  @override
  ApiProviderKind get _apiConfigProviderKind;
  @override
  set _apiConfigProviderKind(ApiProviderKind value);
  @override
  ImageSizeCapabilityOverride get _imageSizeCapabilityOverride;
  @override
  set _imageSizeCapabilityOverride(ImageSizeCapabilityOverride value);
  @override
  ImageAdvancedSettings get _advancedSettings;
  @override
  set _advancedSettings(ImageAdvancedSettings value);
  @override
  set _appPresets(List<AppPreset> value);
  @override
  String get _size;
  @override
  set _size(String value);
  @override
  int get _imageCount;
  @override
  set _imageCount(int value);
  @override
  List<ImageLibraryItem> get _imageLibrary;
  @override
  set _imageLibrary(List<ImageLibraryItem> value);
  @override
  ImageRequestDebugRecord? get _apiTestDebugRecord;
  @override
  set _apiTestDebugRecord(ImageRequestDebugRecord? value);
  @override
  bool get _isTestingApiConfig;
  @override
  set _isTestingApiConfig(bool value);
  @override
  TextEditingController get _apiConfigNameController;
  @override
  TextEditingController get _baseUrlController;
  @override
  TextEditingController get _apiKeyController;
  @override
  TextEditingController get _modelController;
  @override
  TextEditingController get _generationTimeoutController;
  @override
  TextEditingController get _promptController;
  @override
  TextEditingController get _negativePromptController;
  @override
  TextEditingController get _animationPromptController;
  @override
  TextEditingController get _userController;
  @override
  Future<void> _saveSettings();

  bool _navigationRailCompact = true;

  Future<void> _bootstrap() async {
    final settings = await _store.loadSettings();
    final storedApiConfigs = await _store.loadApiConfigs();
    final storedSelectedApiConfigId = await _store.loadSelectedApiConfigId();
    final imageLibrary = await _store.loadImageLibrary();
    final appPresets = await _store.loadPresets();
    final onboardingCompleted = await _store.loadOnboardingCompleted();

    if (!mounted) {
      return;
    }

    final apiConfigs = storedApiConfigs.isEmpty
        ? [ApiConfig.defaults()]
        : storedApiConfigs;
    final selectedApiConfig = resolveApiConfig(
      apiConfigs,
      storedSelectedApiConfigId,
    );

    _isRestoringState = true;
    _apiConfigNameController.text = selectedApiConfig.name;
    _baseUrlController.text = selectedApiConfig.baseUrl;
    _apiKeyController.text = selectedApiConfig.apiKey;
    _modelController.text = selectedApiConfig.model;
    _generationTimeoutController.text = selectedApiConfig
        .generationTimeoutSeconds
        .toString();
    _promptController.text = settings.prompt;
    _negativePromptController.text = settings.negativePrompt;
    _userController.text = settings.advancedSettings.user;

    setState(() {
      _apiConfigs = apiConfigs;
      _selectedApiConfigId = selectedApiConfig.id;
      _apiConfigProviderKind = selectedApiConfig.providerKind;
      _imageSizeCapabilityOverride =
          selectedApiConfig.imageSizeCapabilityOverride;
      _size = safeImageSizeForModel(
        size: settings.size,
        providerKind: selectedApiConfig.providerKind,
        model: selectedApiConfig.model,
        capabilityOverride: selectedApiConfig.imageSizeCapabilityOverride,
      );
      _imageCount = normalizeImageGenerationTargetCount(settings.imageCount);
      _advancedSettings = settings.advancedSettings;
      _imageLibrary = imageLibrary;
      _appPresets = appPresets;
      _isBootstrapping = false;
    });
    _isRestoringState = false;
    await _store.saveApiConfigs(apiConfigs);
    await _store.saveSelectedApiConfigId(selectedApiConfig.id);
    if (!onboardingCompleted && _shouldShowFirstRunSetup(selectedApiConfig)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_showFirstRunSetup());
      });
    }
  }

  bool _shouldShowFirstRunSetup(ApiConfig config) {
    return config.apiKey.trim().isEmpty || config.model.trim().isEmpty;
  }

  Future<void> _showFirstRunSetup() async {
    if (!mounted) {
      return;
    }
    final action = await showFirstRunSetupDialog(context);
    await _store.saveOnboardingCompleted(true);
    if (!mounted) {
      return;
    }
    if (action == FirstRunSetupAction.openApiSettings) {
      await _selectFeature(WorkspaceFeature.apiSettings);
    }
  }

  @override
  Future<void> _selectFeature(WorkspaceFeature feature) async {
    if (_selectedFeature == feature) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _selectedFeature = feature);
  }

  Future<void> _resetToDefaults() async {
    _flushPendingGenerationTextHistory();

    final l10n = appL10nOf(context);
    final before = _captureResetDefaultsSnapshot(includeCurrentApiDraft: true);
    final after = _defaultResetDefaultsSnapshot();
    await _restoreResetDefaultsSnapshot(after);

    _pushHistory(
      WorkspaceFeature.localSettings,
      HistoryAction(
        label: l10n.homeResetDefaultsAction,
        apply: () => _restoreResetDefaultsSnapshot(after),
        revert: () => _restoreResetDefaultsSnapshot(before),
      ),
    );
    if (mounted) {
      _showMessage(l10n.homeResetDefaultsMessage);
    }
  }

  _ResetDefaultsSnapshot _captureResetDefaultsSnapshot({
    required bool includeCurrentApiDraft,
  }) {
    final draft = _currentApiConfigDraft;
    final apiConfigs = includeCurrentApiDraft
        ? upsertApiConfig(_apiConfigs, draft)
        : _apiConfigs;

    return _ResetDefaultsSnapshot(
      apiConfigs: List<ApiConfig>.unmodifiable(apiConfigs),
      selectedApiConfigId: includeCurrentApiDraft
          ? draft.id
          : (_selectedApiConfigId ?? _selectedApiConfig.id),
      apiConfigProviderKind: _apiConfigProviderKind,
      imageSizeCapabilityOverride: _imageSizeCapabilityOverride,
      apiConfigName: _apiConfigNameController.text,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
      generationTimeout: _generationTimeoutController.text,
      prompt: _promptController.text,
      negativePrompt: _negativePromptController.text,
      animationPrompt: _animationPromptController.text,
      user: _userController.text,
      size: _size,
      imageCount: _imageCount,
      advancedSettings: _advancedSettings,
      spriteSheetImportConfig: _spriteSheetImportConfig,
      editorRows: _editorRows,
      editorColumns: _editorColumns,
      editorGridSpec: _editorGridSpec,
      editorTargetFrameIndex: _editorTargetFrameIndex,
      editorFrameFit: _editorFrameFit,
      errorMessage: _errorMessage,
      animationErrorMessage: _animationErrorMessage,
      imageRequestDebugRecord: _imageRequestDebugRecord,
      animationRequestDebugRecord: _animationRequestDebugRecord,
      generatedImages: List<GeneratedImage>.unmodifiable(_generatedImages),
      animationFrames: List<GeneratedImage>.unmodifiable(_animationFrames),
      imageTemplateImagePath: _imageTemplateImagePath,
      animationTemplateImagePath: _animationTemplateImagePath,
      editorImagePath: _editorImagePath,
      editorPatchImagePath: _editorPatchImagePath,
      generalEditorImagePath: _generalEditorImagePath,
      generalEditorImageInfo: _generalEditorImageInfo,
      generalEditorErrorMessage: _generalEditorErrorMessage,
      editorErrorMessage: _editorErrorMessage,
      gifDefaultFrameDelayMs: _gifDefaultFrameDelayMs,
      gifLoopCount: _gifLoopCount,
      gifPlaybackMode: _gifPlaybackMode,
      apiTestDebugRecord: _apiTestDebugRecord,
      isTestingApiConfig: _isTestingApiConfig,
    );
  }

  _ResetDefaultsSnapshot _defaultResetDefaultsSnapshot() {
    final defaultApiConfig = ApiConfig.defaults();
    return _ResetDefaultsSnapshot(
      apiConfigs: [defaultApiConfig],
      selectedApiConfigId: defaultApiConfig.id,
      apiConfigProviderKind: defaultApiConfig.providerKind,
      imageSizeCapabilityOverride: defaultApiConfig.imageSizeCapabilityOverride,
      apiConfigName: defaultApiConfig.name,
      baseUrl: defaultApiConfig.baseUrl,
      apiKey: defaultApiConfig.apiKey,
      model: defaultApiConfig.model,
      generationTimeout: defaultApiConfig.generationTimeoutSeconds.toString(),
      prompt: defaultAppSettings.prompt,
      negativePrompt: defaultAppSettings.negativePrompt,
      animationPrompt: defaultAnimationPrompt,
      user: '',
      size: defaultAppSettings.size,
      imageCount: defaultAppSettings.imageCount,
      advancedSettings: defaultAppSettings.advancedSettings,
      spriteSheetImportConfig: SpriteSheetImportConfig.defaults(),
      editorRows: defaultEditorRows,
      editorColumns: defaultEditorColumns,
      editorGridSpec: const SpriteSheetGridSpec(
        rows: defaultEditorRows,
        columns: defaultEditorColumns,
      ),
      editorTargetFrameIndex: defaultEditorTargetFrameIndex,
      editorFrameFit: defaultEditorFrameFit,
      errorMessage: null,
      animationErrorMessage: null,
      imageRequestDebugRecord: null,
      animationRequestDebugRecord: null,
      generatedImages: const [],
      animationFrames: const [],
      imageTemplateImagePath: null,
      animationTemplateImagePath: null,
      editorImagePath: null,
      editorPatchImagePath: null,
      generalEditorImagePath: null,
      generalEditorImageInfo: null,
      generalEditorErrorMessage: null,
      editorErrorMessage: null,
      gifDefaultFrameDelayMs: defaultGifFrameDelayMs,
      gifLoopCount: defaultGifLoopCount,
      gifPlaybackMode: defaultGifPlaybackMode,
      apiTestDebugRecord: null,
      isTestingApiConfig: false,
    );
  }

  Future<void> _restoreResetDefaultsSnapshot(
    _ResetDefaultsSnapshot snapshot,
  ) async {
    if (!mounted) {
      return;
    }

    _settingsSaveDebounce?.cancel();
    _apiConfigSaveDebounce?.cancel();
    _isRestoringState = true;
    _apiConfigNameController.text = snapshot.apiConfigName;
    _baseUrlController.text = snapshot.baseUrl;
    _apiKeyController.text = snapshot.apiKey;
    _modelController.text = snapshot.model;
    _generationTimeoutController.text = snapshot.generationTimeout;
    _promptController.text = snapshot.prompt;
    _negativePromptController.text = snapshot.negativePrompt;
    _animationPromptController.text = snapshot.animationPrompt;
    _userController.text = snapshot.user;

    setState(() {
      _apiConfigs = snapshot.apiConfigs;
      _selectedApiConfigId = snapshot.selectedApiConfigId;
      _apiConfigProviderKind = snapshot.apiConfigProviderKind;
      _imageSizeCapabilityOverride = snapshot.imageSizeCapabilityOverride;
      _size = safeImageSizeForModel(
        size: snapshot.size,
        providerKind: snapshot.apiConfigProviderKind,
        model: snapshot.model,
        capabilityOverride: snapshot.imageSizeCapabilityOverride,
      );
      _imageCount = normalizeImageGenerationTargetCount(snapshot.imageCount);
      _advancedSettings = snapshot.advancedSettings;
      _spriteSheetImportConfig = snapshot.spriteSheetImportConfig;
      _editorRows = snapshot.editorRows;
      _editorColumns = snapshot.editorColumns;
      _editorGridSpec = snapshot.editorGridSpec;
      _editorTargetFrameIndex = snapshot.editorTargetFrameIndex;
      _editorFrameFit = snapshot.editorFrameFit;
      _errorMessage = snapshot.errorMessage;
      _animationErrorMessage = snapshot.animationErrorMessage;
      _imageRequestDebugRecord = snapshot.imageRequestDebugRecord;
      _animationRequestDebugRecord = snapshot.animationRequestDebugRecord;
      _generatedImages = snapshot.generatedImages;
      _animationFrames = snapshot.animationFrames;
      _imageTemplateImagePath = snapshot.imageTemplateImagePath;
      _animationTemplateImagePath = snapshot.animationTemplateImagePath;
      _editorImagePath = snapshot.editorImagePath;
      _editorPatchImagePath = snapshot.editorPatchImagePath;
      _generalEditorImagePath = snapshot.generalEditorImagePath;
      _generalEditorImageInfo = snapshot.generalEditorImageInfo;
      _generalEditorErrorMessage = snapshot.generalEditorErrorMessage;
      _editorErrorMessage = snapshot.editorErrorMessage;
      _gifDefaultFrameDelayMs = snapshot.gifDefaultFrameDelayMs;
      _gifLoopCount = snapshot.gifLoopCount;
      _gifPlaybackMode = snapshot.gifPlaybackMode;
      _apiTestDebugRecord = snapshot.apiTestDebugRecord;
      _isTestingApiConfig = snapshot.isTestingApiConfig;
      _apiConfigSaveStatus = ApiConfigSaveStatus.saved;
      _apiConfigSaveErrorMessage = null;
    });

    _isRestoringState = false;
    await _store.saveApiConfigs(snapshot.apiConfigs);
    await _store.saveSelectedApiConfigId(snapshot.selectedApiConfigId);
    await _saveSettings();
  }

  @override
  Future<void> _confirmResetToDefaults() async {
    final shouldReset = await confirmResetToDefaultsDialog(context);
    if (shouldReset) {
      await _resetToDefaults();
    }
  }

  @override
  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    final level = _classifyMessage(message);
    final (icon, background, foreground) = switch (level) {
      _MessageLevel.error => (
        Icons.error_outline,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      _MessageLevel.warning => (
        Icons.warning_amber_outlined,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      _MessageLevel.success => (
        Icons.check_circle_outline,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      _MessageLevel.info => (
        Icons.info_outline,
        scheme.inverseSurface,
        scheme.onInverseSurface,
      ),
    };
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: background,
        duration: level == _MessageLevel.error
            ? const Duration(seconds: 6)
            : const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }

  _MessageLevel _classifyMessage(String message) {
    if (message.contains('失败') ||
        message.contains('错误') ||
        message.contains('无法') ||
        message.contains('未能')) {
      return _MessageLevel.error;
    }
    if (message.contains('请先') ||
        message.contains('请选择') ||
        message.contains('请填写') ||
        message.contains('至少') ||
        message.contains('没有')) {
      return _MessageLevel.warning;
    }
    if (message.startsWith('已') ||
        message.contains('成功') ||
        message.contains('完成')) {
      return _MessageLevel.success;
    }
    return _MessageLevel.info;
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final imageEditorFocusMode =
        _selectedFeature == WorkspaceFeature.imageEditor &&
        _isImageEditorFocusMode;
    final pixelArtFocusMode =
        _selectedFeature == WorkspaceFeature.pixelArtEditor &&
        _isPixelArtFocusMode;
    final workspaceFocusMode = imageEditorFocusMode || pixelArtFocusMode;
    final navigationCompact =
        _navigationRailCompact || viewportWidth < AppBreakpoints.compact;
    final navigationExtended =
        (viewportWidth >= AppBreakpoints.expanded ||
            (viewportWidth >= AppBreakpoints.railShortMinWidth &&
                viewportHeight < AppBreakpoints.railShortHeight)) &&
        !navigationCompact;

    if (_isBootstrapping) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ImageGenerationNotifier>.value(
          value: _imageGenerationNotifier,
        ),
        ChangeNotifierProvider<BatchGenerationNotifier>.value(
          value: _batchGenerationNotifier,
        ),
        ChangeNotifierProvider<ImageEditorNotifier>.value(
          value: _imageEditorNotifier,
        ),
        ChangeNotifierProvider<ImageLibraryNotifier>.value(
          value: _imageLibraryNotifier,
        ),
      ],
      child: Shortcuts(
        shortcuts: AppShortcuts.global,
        child: Actions(
          actions: <Type, Action<Intent>>{
            UndoIntent: CallbackAction<UndoIntent>(
              onInvoke: (_) {
                unawaited(_undoCurrentWorkspace());
                return null;
              },
            ),
            RedoIntent: CallbackAction<RedoIntent>(
              onInvoke: (_) {
                unawaited(_redoCurrentWorkspace());
                return null;
              },
            ),
          },
          child: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!workspaceFocusMode) ...[
                  FeatureNavigationRail(
                    selectedFeature: _selectedFeature,
                    extended: navigationExtended,
                    compact: navigationCompact,
                    onFeatureSelected: (feature) =>
                        unawaited(_selectFeature(feature)),
                    onOpenSettings: () => unawaited(
                      _selectFeature(WorkspaceFeature.localSettings),
                    ),
                    onToggleCompact: () => setState(
                      () => _navigationRailCompact = !_navigationRailCompact,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: Column(
                    children: [Expanded(child: _buildSelectedWorkspace())],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHistoryControls() {
    if (!_workspaceSupportsHistory(_selectedFeature)) {
      return const SizedBox.shrink();
    }
    final l10n = appL10nOf(context);
    final stack = _peekHistoryStack(_selectedFeature);
    if (stack == null) {
      return _buildHistoryButtonRow(
        l10n: l10n,
        isApplyingHistory: _isApplyingHistory,
        canUndo: false,
        canRedo: false,
        undoLabel: null,
        redoLabel: null,
        undoActions: const [],
        redoActions: const [],
        compact: true,
      );
    }
    return ListenableBuilder(
      listenable: stack,
      builder: (context, _) => _buildHistoryButtonRow(
        l10n: l10n,
        isApplyingHistory: _isApplyingHistory,
        canUndo: !_isApplyingHistory && stack.canUndo,
        canRedo: !_isApplyingHistory && stack.canRedo,
        undoLabel: stack.topUndo?.label,
        redoLabel: stack.topRedo?.label,
        undoActions: stack.recentUndoActions(limit: _historyMenuMaxItems),
        redoActions: stack.recentRedoActions(limit: _historyMenuMaxItems),
        compact: true,
      ),
    );
  }

  Widget _buildHistoryButtonRow({
    required AppLocalizations l10n,
    required bool isApplyingHistory,
    required bool canUndo,
    required bool canRedo,
    required String? undoLabel,
    required String? redoLabel,
    required List<HistoryAction> undoActions,
    required List<HistoryAction> redoActions,
    bool compact = false,
  }) {
    final hasHistory = undoActions.isNotEmpty || redoActions.isNotEmpty;
    final undoTooltipBase = '${l10n.historyUndo} (Ctrl+Z)';
    final redoTooltipBase = '${l10n.historyRedo} (Ctrl+Y)';
    final buttons = [
      _HistoryActionSemantics(
        label: l10n.historyUndo,
        disabledReason: canUndo
            ? null
            : isApplyingHistory
            ? l10n.historyApplying
            : l10n.historyUndoUnavailable,
        child: IconButton(
          icon: const Icon(Icons.undo, size: 20),
          tooltip: isApplyingHistory
              ? l10n.historyApplying
              : canUndo
              ? (undoLabel == null
                    ? undoTooltipBase
                    : '$undoTooltipBase：$undoLabel')
              : undoTooltipBase,
          onPressed: canUndo ? () => unawaited(_undoCurrentWorkspace()) : null,
          visualDensity: VisualDensity.compact,
        ),
      ),
      _HistoryActionSemantics(
        label: l10n.historyRedo,
        disabledReason: canRedo
            ? null
            : isApplyingHistory
            ? l10n.historyApplying
            : l10n.historyRedoUnavailable,
        child: IconButton(
          icon: const Icon(Icons.redo, size: 20),
          tooltip: isApplyingHistory
              ? l10n.historyApplying
              : canRedo
              ? (redoLabel == null
                    ? redoTooltipBase
                    : '$redoTooltipBase：$redoLabel')
              : redoTooltipBase,
          onPressed: canRedo ? () => unawaited(_redoCurrentWorkspace()) : null,
          visualDensity: VisualDensity.compact,
        ),
      ),
      _HistoryActionSemantics(
        label: l10n.historyMenuTitle,
        disabledReason: !isApplyingHistory && hasHistory
            ? null
            : isApplyingHistory
            ? l10n.historyApplying
            : l10n.historyMenuEmpty,
        child: PopupMenuButton<int>(
          tooltip: isApplyingHistory
              ? l10n.historyApplying
              : hasHistory
              ? l10n.historyMenuTitle
              : l10n.historyMenuEmpty,
          enabled: !isApplyingHistory && hasHistory,
          icon: const Icon(Icons.history, size: 20),
          iconSize: 20,
          padding: EdgeInsets.zero,
          onSelected: (steps) {
            if (_isApplyingHistory) {
              return;
            }
            if (steps > 0) {
              unawaited(_undoCurrentWorkspace(steps: steps));
            } else if (steps < 0) {
              unawaited(_redoCurrentWorkspace(steps: -steps));
            }
          },
          itemBuilder: (context) => _buildHistoryMenuItems(
            l10n: l10n,
            undoActions: undoActions,
            redoActions: redoActions,
          ),
        ),
      ),
    ];

    if (compact) {
      return Row(mainAxisSize: MainAxisSize.min, children: buttons);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: buttons),
    );
  }

  List<PopupMenuEntry<int>> _buildHistoryMenuItems({
    required AppLocalizations l10n,
    required List<HistoryAction> undoActions,
    required List<HistoryAction> redoActions,
  }) {
    final items = <PopupMenuEntry<int>>[];

    if (undoActions.isNotEmpty) {
      items.add(_historyMenuHeader(l10n.historyUndoTo));
      for (var index = 0; index < undoActions.length; index++) {
        items.add(
          _historyMenuAction(
            value: index + 1,
            icon: Icons.undo,
            label: undoActions[index].label,
            stepLabel: index == 0
                ? l10n.historyNextStep
                : l10n.historyStepCount(index + 1),
          ),
        );
      }
    }

    if (undoActions.isNotEmpty && redoActions.isNotEmpty) {
      items.add(const PopupMenuDivider());
    }

    if (redoActions.isNotEmpty) {
      items.add(_historyMenuHeader(l10n.historyRedoTo));
      for (var index = 0; index < redoActions.length; index++) {
        items.add(
          _historyMenuAction(
            value: -(index + 1),
            icon: Icons.redo,
            label: redoActions[index].label,
            stepLabel: index == 0
                ? l10n.historyNextStep
                : l10n.historyStepCount(index + 1),
          ),
        );
      }
    }

    return items;
  }

  PopupMenuEntry<int> _historyMenuHeader(String label) {
    return PopupMenuItem<int>(enabled: false, height: 32, child: Text(label));
  }

  PopupMenuEntry<int> _historyMenuAction({
    required int value,
    required IconData icon,
    required String label,
    required String stepLabel,
  }) {
    return PopupMenuItem<int>(
      value: value,
      height: 40,
      child: SizedBox(
        width: 260,
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 12),
            Text(stepLabel),
          ],
        ),
      ),
    );
  }

  bool _workspaceSupportsHistory(WorkspaceFeature feature) {
    return feature == WorkspaceFeature.imageGeneration ||
        feature == WorkspaceFeature.animationProject ||
        feature == WorkspaceFeature.imageEditor ||
        feature == WorkspaceFeature.pixelArtEditor ||
        feature == WorkspaceFeature.imageLibrary ||
        feature == WorkspaceFeature.localSettings;
  }

  Future<void> _savePixelArtToLibrary(
    Uint8List pngBytes,
    int width,
    int height,
  ) async {
    final l10n = appL10nOf(context);
    try {
      final groupId = 'pixel_art_${DateTime.now().microsecondsSinceEpoch}';
      final file = await _store.saveGeneratedImageBytes(
        groupId: groupId,
        index: 0,
        bytes: pngBytes,
      );
      final item = await _imageLibraryService.addItem(
        store: _store,
        path: file.path,
        kind: ImageAssetKind.editedImage,
        title: l10n.homePixelArtTitle,
        source: l10n.homePixelArtSource,
        prompt: l10n.homePixelArtPrompt(width, height),
        groupId: groupId,
      );
      if (!mounted) {
        return;
      }
      _imageLibrary = [item, ..._imageLibrary];
      _pushImageLibraryAppendHistory(
        feature: WorkspaceFeature.pixelArtEditor,
        label: l10n.homePixelArtSaveAction,
        appendedItems: [item],
      );
      _showMessage(l10n.homePixelArtSavedMessage(fileNameFromPath(file.path)));
    } catch (error) {
      if (mounted) {
        _showMessage(l10n.homePixelArtSaveFailedMessage('$error'));
      }
    }
  }

  Future<void> _exportPixelArtPng(
    Uint8List pngBytes,
    int width,
    int height,
  ) async {
    final l10n = appL10nOf(context);
    final location = await getSaveLocation(
      acceptedTypeGroups: imageTypeGroups,
      suggestedName: _suggestedPixelArtExportFileName(width, height),
    );
    if (location == null || !mounted) {
      return;
    }

    try {
      final result = await _fileService.exportBytesToPath(
        bytes: pngBytes,
        destinationPath: location.path,
      );
      if (!mounted) {
        return;
      }
      _showMessage(
        l10n.homePixelArtExportedMessage(
          fileNameFromPath(result.destinationPath),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(l10n.homePixelArtExportFailedMessage('$error'));
      }
    }
  }

  String _suggestedPixelArtExportFileName(int width, int height) {
    final timestamp = DateTime.now().toLocal().toIso8601String();
    final safeTimestamp = timestamp
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .replaceAll('T', '_');
    return 'pixel-art-${width}x$height-$safeTimestamp.png';
  }

  Widget _buildSelectedWorkspace() {
    return switch (_selectedFeature) {
      WorkspaceFeature.imageGeneration => _buildImageGenerationWorkspace(),
      WorkspaceFeature.batchGeneration => _buildBatchGenerationWorkspace(),
      WorkspaceFeature.animationProject => _buildAnimationProjectWorkspace(),
      WorkspaceFeature.imageEditor => _buildImageEditorWorkspace(),
      WorkspaceFeature.pixelArtEditor => PixelArtWorkspace(
        onSaveToLibrary: _savePixelArtToLibrary,
        onExportPng: _exportPixelArtPng,
        isFocusMode: _isPixelArtFocusMode,
        onFocusModeChanged: (value) =>
            setState(() => _isPixelArtFocusMode = value),
        historyControls: _buildCompactHistoryControls(),
      ),
      WorkspaceFeature.imageLibrary => _buildImageLibraryWorkspace(),
      WorkspaceFeature.apiSettings => _buildApiSettingsWorkspace(),
      WorkspaceFeature.localSettings => _buildLocalSettingsWorkspace(),
    };
  }
}

class _HistoryActionSemantics extends StatelessWidget {
  const _HistoryActionSemantics({
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
