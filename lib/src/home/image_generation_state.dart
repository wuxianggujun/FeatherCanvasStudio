// ignore_for_file: annotate_overrides

part of 'package:feather_canvas_studio/main.dart';

class _AnimationConfigSnapshot {
  const _AnimationConfigSnapshot({
    required this.rows,
    required this.columns,
    required this.gridSpec,
  });

  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _AnimationConfigSnapshot &&
            rows == other.rows &&
            columns == other.columns &&
            gridSpec == other.gridSpec;
  }

  @override
  int get hashCode => Object.hash(rows, columns, gridSpec);
}

const Duration _animationConfigHistoryMergeWindow = Duration(milliseconds: 800);
const String _animationGridConfigHistoryKey = 'animation-grid-config';

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
  SpriteSheetGridSpec get _animationGridSpec;
  set _animationGridSpec(SpriteSheetGridSpec value);
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
    required SpriteSheetGridSpec gridSpec,
  });
  @override
  void _showMessage(String message);
  void _pushHistory(WorkspaceFeature feature, HistoryAction action);
  bool _replaceTopHistory(
    WorkspaceFeature feature, {
    required HistoryAction current,
    required HistoryAction replacement,
  });

  HistoryAction? _lastAnimationConfigHistoryAction;
  String? _lastAnimationConfigHistoryKey;
  DateTime? _lastAnimationConfigHistoryAt;
  _AnimationConfigSnapshot? _lastAnimationConfigHistoryBefore;

  void _setAnimationRows(int value) {
    final before = _captureAnimationConfig();
    setState(() {
      _animationRows = value;
      _animationGridSpec = _animationGridSpec.copyWith(rows: value);
    });
    _pushAnimationConfigHistory(
      label: '调整帧动画行数为 $value 行',
      before: before,
      mergeKey: _animationGridConfigHistoryKey,
    );
  }

  void _setAnimationColumns(int value) {
    final before = _captureAnimationConfig();
    setState(() {
      _animationColumns = value;
      _animationGridSpec = _animationGridSpec.copyWith(columns: value);
    });
    _pushAnimationConfigHistory(
      label: '调整帧动画列数为 $value 列',
      before: before,
      mergeKey: _animationGridConfigHistoryKey,
    );
  }

  void _setAnimationGridSpec(SpriteSheetGridSpec value) {
    final before = _captureAnimationConfig();
    setState(() {
      _animationRows = value.rows;
      _animationColumns = value.columns;
      _animationGridSpec = value;
    });
    _pushAnimationConfigHistory(
      label: '调整帧动画切片校准',
      before: before,
      mergeKey: _animationGridConfigHistoryKey,
    );
  }

  _AnimationConfigSnapshot _captureAnimationConfig() {
    return _AnimationConfigSnapshot(
      rows: _animationRows,
      columns: _animationColumns,
      gridSpec: _animationGridSpec,
    );
  }

  void _restoreAnimationConfig(_AnimationConfigSnapshot snapshot) {
    if (!mounted) {
      return;
    }

    setState(() {
      _animationRows = snapshot.rows;
      _animationColumns = snapshot.columns;
      _animationGridSpec = snapshot.gridSpec;
    });
  }

  void _pushAnimationConfigHistory({
    required String label,
    required _AnimationConfigSnapshot before,
    required String mergeKey,
  }) {
    final after = _captureAnimationConfig();
    if (before == after) {
      return;
    }

    final now = DateTime.now();
    final previousAction = _lastAnimationConfigHistoryAction;
    final previousAt = _lastAnimationConfigHistoryAt;
    final shouldMerge =
        previousAction != null &&
        previousAt != null &&
        _lastAnimationConfigHistoryKey == mergeKey &&
        now.difference(previousAt) <= _animationConfigHistoryMergeWindow;

    if (shouldMerge) {
      final mergedBefore = _lastAnimationConfigHistoryBefore ?? before;
      final replacement = _animationConfigHistoryAction(
        label: label,
        before: mergedBefore,
        after: after,
      );
      final replaced = _replaceTopHistory(
        WorkspaceFeature.frameAnimation,
        current: previousAction,
        replacement: replacement,
      );
      if (replaced) {
        _rememberAnimationConfigHistory(
          action: replacement,
          mergeKey: mergeKey,
          before: mergedBefore,
          now: now,
        );
        return;
      }
    }

    final action = _animationConfigHistoryAction(
      label: label,
      before: before,
      after: after,
    );
    _pushHistory(WorkspaceFeature.frameAnimation, action);
    _rememberAnimationConfigHistory(
      action: action,
      mergeKey: mergeKey,
      before: before,
      now: now,
    );
  }

  HistoryAction _animationConfigHistoryAction({
    required String label,
    required _AnimationConfigSnapshot before,
    required _AnimationConfigSnapshot after,
  }) {
    return HistoryAction(
      label: label,
      apply: () => _restoreAnimationConfig(after),
      revert: () => _restoreAnimationConfig(before),
    );
  }

  void _rememberAnimationConfigHistory({
    required HistoryAction action,
    required String mergeKey,
    required _AnimationConfigSnapshot before,
    required DateTime now,
  }) {
    _lastAnimationConfigHistoryAction = action;
    _lastAnimationConfigHistoryKey = mergeKey;
    _lastAnimationConfigHistoryBefore = before;
    _lastAnimationConfigHistoryAt = now;
  }

  Future<void> _generateImage() async {
    final apiConfig = await _prepareSelectedApiConfigForRequest();
    if (!mounted) {
      return;
    }

    final prompt = _promptController.text.trim();
    final beforeImages = List<GeneratedImage>.unmodifiable(_generatedImages);
    final beforeDebugRecord = _imageRequestDebugRecord;

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
      _pushTextGenerationHistory(
        label: '生成 ${result.cachedImages.length} 张图片',
        beforeImages: beforeImages,
        beforeDebugRecord: beforeDebugRecord,
        afterImages: result.cachedImages,
        afterDebugRecord: _imageRequestDebugRecord,
        appendedItems: result.libraryItems,
      );
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
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() {
        _imageRequestDebugRecord = _recordUnexpectedGenerationError(
          _imageRequestDebugRecord,
          error,
          stackTrace,
          fallbackPrefix: '生成失败',
        );
        _errorMessage = _unexpectedGenerationErrorMessage(
          error,
          fallbackPrefix: '生成失败',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<Uint8List> _resolveGeneratedPreviewBytes(GeneratedImage image) {
    final bytes = image.bytes;
    if (bytes != null) {
      return Future.value(bytes);
    }

    final filePath = image.filePath;
    if (filePath != null) {
      return _fileService.readFileBytes(filePath);
    }

    return _client.resolveImageBytes(image);
  }

  Future<void> _makeGeneratedImageBackgroundTransparent(
    int index,
    GeneratedImage image,
  ) async {
    final beforeImages = List<GeneratedImage>.unmodifiable(_generatedImages);
    final beforeDebugRecord = _imageRequestDebugRecord;
    final sourceItem = _findImageLibraryItemByPath(image.filePath);
    final tolerance = await showBackgroundTransparencyDialog(
      context,
      sourceTitle: sourceItem?.displayTitle ?? '生成结果 ${index + 1}',
    );
    if (tolerance == null || !mounted) {
      return;
    }

    try {
      final sourceBytes = await _resolveGeneratedPreviewBytes(image);
      final saved = await _saveTransparentBackgroundImage(
        sourceBytes: sourceBytes,
        tolerance: tolerance,
        sourceItem: sourceItem,
        fallbackTitle: '生成结果 ${index + 1}',
        source: '文本生图',
      );
      if (!mounted) {
        return;
      }
      if (saved == null) {
        _showMessage('没有检测到可透明化的边缘背景，可尝试调高容差');
        return;
      }

      setState(() {
        final nextImages = List<GeneratedImage>.of(_generatedImages);
        if (index >= 0 && index < nextImages.length) {
          nextImages[index] = GeneratedImage.file(
            saved.item.path,
            revisedPrompt: image.revisedPrompt,
          );
          _generatedImages = List.unmodifiable(nextImages);
        }
      });
      _pushTextGenerationHistory(
        label: '背景转透明：${sourceItem?.displayTitle ?? '生成结果 ${index + 1}'}',
        beforeImages: beforeImages,
        beforeDebugRecord: beforeDebugRecord,
        afterImages: _generatedImages,
        afterDebugRecord: _imageRequestDebugRecord,
        appendedItems: [saved.item],
      );
      _showMessage(
        '已生成透明背景图片：${saved.item.displayTitle} · '
        '透明化 ${saved.transparentPixelCount} 个像素',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('背景转透明失败：$error');
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
    final beforeFrames = List<GeneratedImage>.unmodifiable(_animationFrames);
    final beforeDebugRecord = _animationRequestDebugRecord;

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
      _pushAnimationGenerationHistory(
        label: '生成 Sprite Sheet',
        beforeFrames: beforeFrames,
        beforeDebugRecord: beforeDebugRecord,
        afterFrames: [result.cachedSheet],
        afterDebugRecord: _animationRequestDebugRecord,
        appendedItem: result.libraryItem,
      );
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
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() {
        _animationRequestDebugRecord = _recordUnexpectedGenerationError(
          _animationRequestDebugRecord,
          error,
          stackTrace,
          fallbackPrefix: '帧动画生成失败',
        );
        _animationErrorMessage = _unexpectedGenerationErrorMessage(
          error,
          fallbackPrefix: '帧动画生成失败',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAnimation = false);
      }
    }
  }

  ImageRequestDebugRecord? _recordUnexpectedGenerationError(
    ImageRequestDebugRecord? record,
    Object error,
    StackTrace stackTrace, {
    required String fallbackPrefix,
  }) {
    if (record == null) {
      return null;
    }
    return record.copyWith(
      errorMessage: _unexpectedGenerationErrorMessage(
        error,
        fallbackPrefix: fallbackPrefix,
      ),
      stackTrace: stackTrace,
    );
  }

  String _unexpectedGenerationErrorMessage(
    Object error, {
    required String fallbackPrefix,
  }) {
    if (error is StackOverflowError) {
      return '$fallbackPrefix：客户端发生 Stack Overflow，已写入调试详情。'
          '如果调试详情里没有 HTTP 状态码，说明请求没有拿到接口响应。';
    }
    return '$fallbackPrefix：$error';
  }

  void _pushTextGenerationHistory({
    required String label,
    required List<GeneratedImage> beforeImages,
    required ImageRequestDebugRecord? beforeDebugRecord,
    required List<GeneratedImage> afterImages,
    required ImageRequestDebugRecord? afterDebugRecord,
    required List<ImageLibraryItem> appendedItems,
  }) {
    _pushHistory(
      WorkspaceFeature.imageGeneration,
      HistoryAction(
        label: label,
        apply: () => _restoreTextGenerationResult(
          images: afterImages,
          debugRecord: afterDebugRecord,
          appendedItems: appendedItems,
        ),
        revert: () => _restoreTextGenerationResult(
          images: beforeImages,
          debugRecord: beforeDebugRecord,
          removedItemIds: {for (final item in appendedItems) item.id},
        ),
      ),
    );
  }

  Future<void> _restoreTextGenerationResult({
    required List<GeneratedImage> images,
    required ImageRequestDebugRecord? debugRecord,
    List<ImageLibraryItem> appendedItems = const [],
    Set<String> removedItemIds = const {},
  }) async {
    await _applyImageLibraryMerge(
      appendedItems: appendedItems,
      removedItemIds: removedItemIds,
      updateState: () {
        _generatedImages = List<GeneratedImage>.unmodifiable(images);
        _imageRequestDebugRecord = debugRecord;
        _errorMessage = null;
      },
    );
  }

  void _pushAnimationGenerationHistory({
    required String label,
    required List<GeneratedImage> beforeFrames,
    required ImageRequestDebugRecord? beforeDebugRecord,
    required List<GeneratedImage> afterFrames,
    required ImageRequestDebugRecord? afterDebugRecord,
    required ImageLibraryItem? appendedItem,
  }) {
    final appendedItems = [?appendedItem];
    _pushHistory(
      WorkspaceFeature.frameAnimation,
      HistoryAction(
        label: label,
        apply: () => _restoreAnimationGenerationResult(
          frames: afterFrames,
          debugRecord: afterDebugRecord,
          appendedItems: appendedItems,
        ),
        revert: () => _restoreAnimationGenerationResult(
          frames: beforeFrames,
          debugRecord: beforeDebugRecord,
          removedItemIds: {for (final item in appendedItems) item.id},
        ),
      ),
    );
  }

  Future<void> _restoreAnimationGenerationResult({
    required List<GeneratedImage> frames,
    required ImageRequestDebugRecord? debugRecord,
    List<ImageLibraryItem> appendedItems = const [],
    Set<String> removedItemIds = const {},
  }) async {
    await _applyImageLibraryMerge(
      appendedItems: appendedItems,
      removedItemIds: removedItemIds,
      updateState: () {
        _animationFrames = List<GeneratedImage>.unmodifiable(frames);
        _animationRequestDebugRecord = debugRecord;
        _animationErrorMessage = null;
      },
    );
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
      onMakeBackgroundTransparent: (index, image) =>
          unawaited(_makeGeneratedImageBackgroundTransparent(index, image)),
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
      gridSpec: _animationGridSpec,
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
      onGridSpecChanged: _setAnimationGridSpec,
      onAdvancedSettingsChanged: _setAdvancedSettings,
      onPickTemplateImage: _pickAnimationTemplateImage,
      onClearTemplateImage: _clearAnimationTemplateImage,
      onGenerate: _generateAnimationFrames,
      onExportSpriteSheet: (bytes) => unawaited(
        _exportSpriteSheet(
          pngBytes: bytes,
          rows: _animationRows,
          columns: _animationColumns,
          gridSpec: _animationGridSpec,
        ),
      ),
      onSendToGif: _sendPreviewDataToGif,
    );
  }
}
