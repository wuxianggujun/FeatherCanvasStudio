part of 'package:feather_canvas_studio/main.dart';

mixin _LocalSettingsStateMixin
    on State<FeatherCanvasHomePage>, _ApiConfigStateMixin {
  @override
  AppLocalStore get _store;
  @override
  bool get _isBootstrapping;
  @override
  bool get _isRestoringState;
  List<ImageLibraryItem> get _imageLibrary;
  List<GeneratedImage> get _generatedImages;
  List<GeneratedImage> get _animationFrames;
  Future<void> _selectFeature(WorkspaceFeature feature);
  Future<void> _confirmResetToDefaults();

  final TextEditingController _promptController = TextEditingController(
    text: defaultAppSettings.prompt,
  );
  final TextEditingController _negativePromptController =
      TextEditingController();
  final TextEditingController _userController = TextEditingController();

  String _size = defaultAppSettings.size;
  int _imageCount = defaultAppSettings.imageCount;
  ImageAdvancedSettings _advancedSettings = defaultAppSettings.advancedSettings;
  Timer? _settingsSaveDebounce;

  void _initLocalSettingsState() {
    _promptController.addListener(_scheduleSettingsSave);
    _negativePromptController.addListener(_scheduleSettingsSave);
    _userController.addListener(_syncUserAndScheduleSettingsSave);
  }

  void _disposeLocalSettingsState() {
    _settingsSaveDebounce?.cancel();
    _promptController.dispose();
    _negativePromptController.dispose();
    _userController.dispose();
  }

  void _scheduleSettingsSave() {
    if (_isBootstrapping || _isRestoringState) {
      return;
    }

    _settingsSaveDebounce?.cancel();
    _settingsSaveDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_saveSettings());
    });
  }

  void _syncUserAndScheduleSettingsSave() {
    _advancedSettings = _advancedSettings.copyWith(
      user: _userController.text.trim(),
    );
    _scheduleSettingsSave();
  }

  @override
  Future<void> _saveSettings() async {
    final apiConfig = _selectedApiConfig;
    final normalizedSize = imageDimensionsFromSize(_size).size;
    await _store.saveSettings(
      AppSettings(
        baseUrl: apiConfig.baseUrl,
        apiKey: apiConfig.apiKey,
        model: apiConfig.model,
        prompt: _promptController.text,
        negativePrompt: _negativePromptController.text,
        size: normalizedSize,
        imageCount: _imageCount,
        advancedSettings: _advancedSettings.copyWith(
          user: _userController.text.trim(),
        ),
      ),
    );
  }

  void _setSize(String value) {
    setState(() => _size = value.trim());
    _scheduleSettingsSave();
  }

  void _setImageCount(int value) {
    setState(() => _imageCount = value);
    _scheduleSettingsSave();
  }

  void _setAdvancedSettings(ImageAdvancedSettings value) {
    setState(() => _advancedSettings = value);
    if (_userController.text != value.user) {
      _userController.text = value.user;
    }
    _scheduleSettingsSave();
  }

  Widget _buildLocalSettingsWorkspace() {
    return LocalSettingsWorkspace(
      apiConfigCount: _apiConfigs.length,
      imageLibraryCount: _imageLibrary.length,
      generatedPreviewCount: _generatedImages.length + _animationFrames.length,
      providerKind: _apiConfigProviderKind,
      promptController: _promptController,
      negativePromptController: _negativePromptController,
      size: _size,
      imageCount: _imageCount,
      advancedSettings: _advancedSettings,
      userController: _userController,
      onSizeChanged: _setSize,
      onImageCountChanged: _setImageCount,
      onAdvancedSettingsChanged: _setAdvancedSettings,
      onOpenApiSettings: () =>
          unawaited(_selectFeature(WorkspaceFeature.apiSettings)),
      onResetToDefaults: () => unawaited(_confirmResetToDefaults()),
    );
  }
}
