part of 'package:feather_canvas_studio/main.dart';

mixin _ImageGenerationStateMixin
    on
        State<FeatherCanvasHomePage>,
        _ApiConfigStateMixin,
        _LocalSettingsStateMixin,
        _ImageLibraryStateMixin,
        _EditorGifStateMixin {
  @override
  OpenAICompatibleImageClient get _client;
  @override
  AppLocalStore get _store;
  @override
  ImageLibraryFileService get _fileService;
  @override
  ImageLibraryService get _imageLibraryService;
  ImageGenerationService get _imageGenerationService;
  ScrollController get _scrollController;
  TextEditingController get _animationPromptController;
  int get _animationRows;
  set _animationRows(int value);
  int get _animationColumns;
  set _animationColumns(int value);
  int get _animationFrameCount;
  bool get _isGenerating;
  set _isGenerating(bool value);
  bool get _isGeneratingAnimation;
  set _isGeneratingAnimation(bool value);
  String? get _errorMessage;
  @override
  set _errorMessage(String? value);
  String? get _animationErrorMessage;
  @override
  set _animationErrorMessage(String? value);
  ImageRequestDebugRecord? get _imageRequestDebugRecord;
  set _imageRequestDebugRecord(ImageRequestDebugRecord? value);
  ImageRequestDebugRecord? get _animationRequestDebugRecord;
  set _animationRequestDebugRecord(ImageRequestDebugRecord? value);
  @override
  List<GeneratedImage> get _generatedImages;
  set _generatedImages(List<GeneratedImage> value);
  @override
  List<GeneratedImage> get _animationFrames;
  set _animationFrames(List<GeneratedImage> value);
  @override
  String? get _animationTemplateImagePath;
  @override
  List<ImageLibraryItem> get _imageLibrary;
  @override
  set _imageLibrary(List<ImageLibraryItem> value);
  @override
  Future<void> _selectApiConfig(String id);
  @override
  Future<void> _selectFeature(WorkspaceFeature feature);
  @override
  void _setSize(String value);
  @override
  void _setImageCount(int value);
  @override
  void _setAdvancedSettings(ImageAdvancedSettings value);
  @override
  Future<void> _exportSpriteSheet({
    required Uint8List pngBytes,
    required int rows,
    required int columns,
  });
  @override
  void _showMessage(String message);

  void _setAnimationRows(int value) {
    setState(() => _animationRows = value);
  }

  void _setAnimationColumns(int value) {
    setState(() => _animationColumns = value);
  }

  Future<void> _generateImage() async {
    final apiConfig = await _prepareSelectedApiConfigForRequest();
    if (!mounted) {
      return;
    }

    final prompt = _promptController.text.trim();

    if (apiConfig.apiKey.trim().isEmpty) {
      _showMessage('请先在接口配置页填写 API Key');
      return;
    }

    if (apiConfig.model.trim().isEmpty) {
      _showMessage('请先在接口配置页获取模型列表并选择模型');
      return;
    }

    if (prompt.isEmpty) {
      _showMessage('请先填写正向提示词');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _imageRequestDebugRecord = null;
      _generatedImages = const [];
    });

    try {
      final negativePrompt = _negativePromptController.text.trim();
      final user = _userController.text.trim();
      final result = await _imageGenerationService.generateTextImages(
        client: _client,
        store: _store,
        imageLibraryService: _imageLibraryService,
        apiConfig: apiConfig,
        prompt: prompt,
        negativePrompt: negativePrompt,
        size: _size,
        imageCount: _imageCount,
        advancedSettings: _advancedSettings,
        user: user,
        onDebugRecord: (record) => _imageRequestDebugRecord = record,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _generatedImages = result.cachedImages;
        _imageLibrary = [...result.libraryItems, ..._imageLibrary];
      });
      _showMessage('图片生成完成');
    } on ImageGenerationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = '请求超时，请检查接口地址或稍后重试');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = '生成失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateAnimationFrames() async {
    final apiConfig = await _prepareSelectedApiConfigForRequest();
    if (!mounted) {
      return;
    }

    final prompt = _animationPromptController.text.trim();
    final totalFrames = _animationFrameCount;
    final templatePath = _animationTemplateImagePath;

    if (apiConfig.apiKey.trim().isEmpty) {
      setState(() => _animationErrorMessage = '请先在接口配置页填写 API Key。');
      return;
    }

    if (apiConfig.model.trim().isEmpty) {
      setState(() => _animationErrorMessage = '请先在接口配置页获取模型列表并选择模型。');
      return;
    }

    if (prompt.isEmpty) {
      setState(() => _animationErrorMessage = '请先填写动画描述。');
      return;
    }

    if (totalFrames <= 0) {
      setState(() => _animationErrorMessage = '请先设置有效的行列数量。');
      return;
    }

    if (templatePath != null && !await _fileService.fileExists(templatePath)) {
      setState(() => _animationErrorMessage = '模板图片不存在，请重新选择。');
      return;
    }

    setState(() {
      _isGeneratingAnimation = true;
      _animationErrorMessage = null;
      _animationRequestDebugRecord = null;
      _animationFrames = const [];
    });

    try {
      final negativePrompt = _negativePromptController.text.trim();
      final user = _userController.text.trim();
      final result = await _imageGenerationService.generateSpriteSheet(
        client: _client,
        store: _store,
        imageLibraryService: _imageLibraryService,
        apiConfig: apiConfig,
        prompt: prompt,
        negativePrompt: negativePrompt,
        size: _size,
        rows: _animationRows,
        columns: _animationColumns,
        advancedSettings: _advancedSettings,
        user: user,
        templateImagePath: templatePath,
        onDebugRecord: (record) => _animationRequestDebugRecord = record,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _animationFrames = [result.cachedSheet];
        final libraryItem = result.libraryItem;
        if (libraryItem != null) {
          _imageLibrary = [libraryItem, ..._imageLibrary];
        }
      });
      _showMessage('Sprite Sheet 已生成，可在作品集中按需切片或直接导出');
    } on ImageGenerationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _animationErrorMessage = error.message);
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() => _animationErrorMessage = '请求超时，请检查接口地址或稍后重试');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _animationErrorMessage = '帧动画生成失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAnimation = false);
      }
    }
  }

  Widget _buildImageGenerationWorkspace() {
    return ImageGenerationWorkspace(
      controller: _scrollController,
      apiConfigs: _apiConfigs,
      selectedApiConfig: _selectedApiConfig,
      promptController: _promptController,
      negativePromptController: _negativePromptController,
      size: _size,
      imageCount: _imageCount,
      advancedSettings: _advancedSettings,
      userController: _userController,
      isGenerating: _isGenerating,
      errorMessage: _errorMessage,
      generatedImages: _generatedImages,
      debugRecord: _imageRequestDebugRecord,
      onApiConfigChanged: _selectApiConfig,
      onOpenApiSettings: () =>
          unawaited(_selectFeature(WorkspaceFeature.apiSettings)),
      onSizeChanged: _setSize,
      onImageCountChanged: _setImageCount,
      onAdvancedSettingsChanged: _setAdvancedSettings,
      onGenerate: _generateImage,
    );
  }

  Widget _buildFrameAnimationWorkspace() {
    return FrameAnimationWorkspace(
      apiConfigs: _apiConfigs,
      selectedApiConfig: _selectedApiConfig,
      promptController: _animationPromptController,
      negativePromptController: _negativePromptController,
      size: _size,
      rows: _animationRows,
      columns: _animationColumns,
      templateImagePath: _animationTemplateImagePath,
      advancedSettings: _advancedSettings,
      userController: _userController,
      isGenerating: _isGeneratingAnimation,
      errorMessage: _animationErrorMessage,
      debugRecord: _animationRequestDebugRecord,
      generatedImages: _animationFrames,
      onApiConfigChanged: _selectApiConfig,
      onOpenApiSettings: () =>
          unawaited(_selectFeature(WorkspaceFeature.apiSettings)),
      onSizeChanged: _setSize,
      onRowsChanged: _setAnimationRows,
      onColumnsChanged: _setAnimationColumns,
      onAdvancedSettingsChanged: _setAdvancedSettings,
      onPickTemplateImage: _pickAnimationTemplateImage,
      onClearTemplateImage: _clearAnimationTemplateImage,
      onGenerate: _generateAnimationFrames,
      onExportSpriteSheet: (bytes) => unawaited(
        _exportSpriteSheet(
          pngBytes: bytes,
          rows: _animationRows,
          columns: _animationColumns,
        ),
      ),
    );
  }
}
