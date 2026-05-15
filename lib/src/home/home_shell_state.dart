part of 'package:feather_canvas_studio/main.dart';

mixin _HomeShellStateMixin
    on
        State<FeatherCanvasHomePage>,
        _ApiConfigStateMixin,
        _LocalSettingsStateMixin,
        _ImageLibraryStateMixin,
        _EditorGifStateMixin,
        _ImageGenerationStateMixin {
  @override
  AppLocalStore get _store;
  @override
  bool get _isBootstrapping;
  set _isBootstrapping(bool value);
  @override
  bool get _isRestoringState;
  @override
  set _isRestoringState(bool value);
  @override
  WorkspaceFeature get _selectedFeature;
  set _selectedFeature(WorkspaceFeature value);
  @override
  set _errorMessage(String? value);
  @override
  set _animationTemplateImagePath(String? value);
  @override
  set _editorImagePath(String? value);
  @override
  set _editorPatchImagePath(String? value);
  @override
  set _editorErrorMessage(String? value);
  @override
  List<GifSourceFrame> get _gifSourceFrames;
  @override
  set _gifSourceFrames(List<GifSourceFrame> value);
  @override
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
  set _animationRows(int value);
  @override
  set _animationColumns(int value);
  @override
  set _editorRows(int value);
  @override
  set _editorColumns(int value);
  @override
  set _editorTargetFrameIndex(int value);
  @override
  set _editorFrameFit(SpriteSheetFrameFit value);
  @override
  set _gifOutputPath(String? value);
  @override
  set _gifErrorMessage(String? value);
  @override
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
  ImageAdvancedSettings get _advancedSettings;
  @override
  set _advancedSettings(ImageAdvancedSettings value);
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
  TextEditingController get _promptController;
  @override
  TextEditingController get _negativePromptController;
  @override
  TextEditingController get _animationPromptController;
  @override
  TextEditingController get _userController;
  @override
  Future<void> _saveSettings();

  Future<void> _bootstrap() async {
    final settings = await _store.loadSettings();
    final storedApiConfigs = await _store.loadApiConfigs();
    final storedSelectedApiConfigId = await _store.loadSelectedApiConfigId();
    final imageLibrary = await _store.loadImageLibrary();

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
    _promptController.text = settings.prompt;
    _negativePromptController.text = settings.negativePrompt;
    _userController.text = settings.advancedSettings.user;

    setState(() {
      _apiConfigs = apiConfigs;
      _selectedApiConfigId = selectedApiConfig.id;
      _apiConfigProviderKind = selectedApiConfig.providerKind;
      _size = imageDimensionsFromSize(settings.size).size;
      _imageCount = settings.imageCount;
      _advancedSettings = settings.advancedSettings;
      _imageLibrary = imageLibrary;
      _isBootstrapping = false;
    });
    _isRestoringState = false;
    await _store.saveApiConfigs(apiConfigs);
    await _store.saveSelectedApiConfigId(selectedApiConfig.id);
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
    _settingsSaveDebounce?.cancel();
    _apiConfigSaveDebounce?.cancel();
    _isRestoringState = true;

    final defaultApiConfig = ApiConfig.defaults();
    _apiConfigNameController.text = defaultApiConfig.name;
    _baseUrlController.text = defaultApiConfig.baseUrl;
    _apiKeyController.clear();
    _modelController.text = defaultApiConfig.model;
    _promptController.text = defaultAppSettings.prompt;
    _negativePromptController.clear();
    _animationPromptController.text = defaultAnimationPrompt;
    _userController.clear();

    setState(() {
      _apiConfigs = [defaultApiConfig];
      _selectedApiConfigId = defaultApiConfig.id;
      _apiConfigProviderKind = defaultApiConfig.providerKind;
      _size = defaultAppSettings.size;
      _imageCount = defaultAppSettings.imageCount;
      _advancedSettings = defaultAppSettings.advancedSettings;
      _animationRows = defaultAnimationRows;
      _animationColumns = defaultAnimationColumns;
      _editorRows = defaultEditorRows;
      _editorColumns = defaultEditorColumns;
      _editorTargetFrameIndex = defaultEditorTargetFrameIndex;
      _editorFrameFit = defaultEditorFrameFit;
      _errorMessage = null;
      _animationErrorMessage = null;
      _imageRequestDebugRecord = null;
      _animationRequestDebugRecord = null;
      _generatedImages = const [];
      _animationFrames = const [];
      _animationTemplateImagePath = null;
      _editorImagePath = null;
      _editorPatchImagePath = null;
      _editorErrorMessage = null;
      _gifSourceFrames = const [];
      _gifOutputPath = null;
      _gifErrorMessage = null;
      _gifDefaultFrameDelayMs = defaultGifFrameDelayMs;
      _gifLoopCount = defaultGifLoopCount;
      _gifPlaybackMode = defaultGifPlaybackMode;
      _apiTestDebugRecord = null;
      _isTestingApiConfig = false;
    });

    _isRestoringState = false;
    await _store.saveApiConfigs([defaultApiConfig]);
    await _store.saveSelectedApiConfigId(defaultApiConfig.id);
    await _saveSettings();
    if (mounted) {
      _showMessage('表单已重置');
    }
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final navigationExtended = MediaQuery.sizeOf(context).width >= 980;

    if (_isBootstrapping) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FeatureNavigationRail(
              selectedFeature: _selectedFeature,
              extended: navigationExtended,
              onFeatureSelected: (feature) =>
                  unawaited(_selectFeature(feature)),
              onOpenSettings: () =>
                  unawaited(_selectFeature(WorkspaceFeature.localSettings)),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _buildSelectedWorkspace()),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedWorkspace() {
    return switch (_selectedFeature) {
      WorkspaceFeature.imageGeneration => _buildImageGenerationWorkspace(),
      WorkspaceFeature.frameAnimation => _buildFrameAnimationWorkspace(),
      WorkspaceFeature.imageEditor => _buildImageEditorWorkspace(),
      WorkspaceFeature.gifComposer => _buildGifComposerWorkspace(),
      WorkspaceFeature.imageLibrary => _buildImageLibraryWorkspace(),
      WorkspaceFeature.apiSettings => _buildApiSettingsWorkspace(),
      WorkspaceFeature.localSettings => _buildLocalSettingsWorkspace(),
    };
  }
}
