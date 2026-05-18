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
  AnimationProjectImporter get _animationProjectImporter;
  AnimationProjectStore get _animationProjectStore;
  AnimationProjectExportService get _animationProjectExportService;
  ScrollController get _scrollController;
  TextEditingController get _animationPromptController;
  int get _animationRows;
  set _animationRows(int value);
  int get _animationColumns;
  set _animationColumns(int value);
  SpriteSheetGridSpec get _animationGridSpec;
  set _animationGridSpec(SpriteSheetGridSpec value);
  int get _animationFrameCount;
  // ignore: unused_element
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
  AnimationProject? get _animationProject;
  set _animationProject(AnimationProject? value);
  String? get _selectedAnimationTrackId;
  set _selectedAnimationTrackId(String? value);
  bool get _isAnimationProjectBusy;
  set _isAnimationProjectBusy(bool value);
  String? get _animationProjectErrorMessage;
  set _animationProjectErrorMessage(String? value);
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
      label: '调整序列帧行数为 $value 行',
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
      label: '调整序列帧列数为 $value 列',
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
      label: '调整序列帧切片校准',
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
        WorkspaceFeature.animationProject,
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
    _pushHistory(WorkspaceFeature.animationProject, action);
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
      final targetImageCount = normalizeImageGenerationTargetCount(_imageCount);
      final batches = splitImageGenerationBatches(
        targetCount: targetImageCount,
        requestCount: maxImageGenerationRequestCount,
      );
      final allImages = <GeneratedImage>[];
      final allLibraryItems = <ImageLibraryItem>[];

      for (final batchCount in batches) {
        final result = await _imageGenerationService.generateTextImages(
          client: _client,
          store: _store,
          imageLibraryService: _imageLibraryService,
          apiConfig: apiConfig,
          prompt: prompt,
          negativePrompt: negativePrompt,
          size: _size,
          imageCount: batchCount,
          advancedSettings: _advancedSettings,
          user: user,
          onDebugRecord: (record) => _imageRequestDebugRecord = record,
        );

        if (!mounted) {
          return;
        }

        allImages.addAll(result.cachedImages);
        allLibraryItems.addAll(result.libraryItems);
        setState(() {
          _generatedImages = List<GeneratedImage>.unmodifiable(allImages);
          _imageLibrary = [...result.libraryItems, ..._imageLibrary];
        });
      }
      _pushTextGenerationHistory(
        label: '生成 ${allImages.length} 张图片',
        beforeImages: beforeImages,
        beforeDebugRecord: beforeDebugRecord,
        afterImages: List<GeneratedImage>.unmodifiable(allImages),
        afterDebugRecord: _imageRequestDebugRecord,
        appendedItems: List<ImageLibraryItem>.unmodifiable(allLibraryItems),
      );
      _showMessage('图片生成完成，共 ${allImages.length} 张');
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
      _errorMessage = '请求超时，请检查接口地址或稍后重试';
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
        _isGenerating = false;
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

  Future<ImageClipboardCopyResult> _copyGeneratedImageToClipboard(
    GeneratedImage image,
  ) async {
    final filePath = image.filePath;
    if (filePath != null) {
      return _fileService.copyImageFileToClipboard(filePath);
    }

    final bytes = await _resolveGeneratedPreviewBytes(image);
    return _fileService.copyImageBytesToClipboard(bytes);
  }

  void _showImageClipboardCopyResult(ImageClipboardCopyResult result) {
    switch (result.status) {
      case ImageClipboardCopyStatus.imageCopied:
        _showMessage('图片已复制到剪贴板');
      case ImageClipboardCopyStatus.pathCopied:
        _showMessage('当前平台暂不支持直接复制图片，已复制图片路径');
    }
  }

  Future<void> _copyGeneratedPreviewImage(GeneratedImage image) async {
    try {
      final result = await _copyGeneratedImageToClipboard(image);
      if (!mounted) {
        return;
      }
      _showImageClipboardCopyResult(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('复制图片失败：$error');
    }
  }

  Future<void> _exportGeneratedPreviewImage(
    int index,
    GeneratedImage image,
  ) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: imageTypeGroups,
      suggestedName: _suggestedGeneratedExportFileName(index, image),
    );
    if (location == null || !mounted) {
      return;
    }

    try {
      final filePath = image.filePath;
      final result = filePath == null
          ? await _fileService.exportBytesToPath(
              bytes: await _resolveGeneratedPreviewBytes(image),
              destinationPath: location.path,
            )
          : await _fileService.exportFileToPath(
              sourcePath: filePath,
              destinationPath: location.path,
            );
      if (!mounted) {
        return;
      }
      _showMessage('图片已导出：${fileNameFromPath(result.destinationPath)}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('导出图片失败：$error');
    }
  }

  String _suggestedGeneratedExportFileName(int index, GeneratedImage image) {
    final filePath = image.filePath;
    if (filePath != null) {
      return fileNameFromPath(filePath);
    }
    return 'generated-image-${index + 1}.png';
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
      _showMessage('Sprite Sheet 已生成，正在导入动画工程');
      await _importCurrentAnimationSheetToProject();
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
          fallbackPrefix: 'Sprite Sheet 生成失败',
        );
        _animationErrorMessage = _unexpectedGenerationErrorMessage(
          error,
          fallbackPrefix: 'Sprite Sheet 生成失败',
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
      WorkspaceFeature.animationProject,
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

  Future<void> _openAnimationPreviewInEditor(
    SpriteSheetPreviewData previewData,
  ) async {
    final sourceFeature = _selectedFeature;
    final output = await SpriteSheetFileService.exportPng(
      store: _store,
      pngBytes: previewData.sheetBytes,
      rows: previewData.rows,
      columns: previewData.columns,
      gridSpec: previewData.gridSpec,
    );
    if (!mounted) {
      return;
    }

    final item = await _imageLibraryService.addExportedSpriteSheet(
      store: _store,
      path: output.path,
      rows: previewData.rows,
      columns: previewData.columns,
      gridSpec: previewData.gridSpec,
    );
    if (!mounted) {
      return;
    }

    _imageLibrary = [item, ..._imageLibrary];
    _pushImageLibraryAppendHistory(
      feature: sourceFeature,
      label: '打开 Sprite Sheet 到图片编辑器',
      appendedItems: [item],
    );
    await _useImageLibraryItemInEditor(item);
    if (!mounted) {
      return;
    }
    _showMessage('已打开到图片编辑器，可在编辑工具中使用像素化');
  }

  Future<void> _importCurrentAnimationSheetToProject() async {
    if (_animationFrames.isEmpty) {
      _showMessage('请先生成 Sprite Sheet，再导入动画工程');
      return;
    }

    final source = _animationFrames.first;
    setState(() {
      _isAnimationProjectBusy = true;
      _animationProjectErrorMessage = null;
    });

    try {
      final bytes = await _resolveGeneratedPreviewBytes(source);
      final result = await _animationProjectImporter.importSpriteSheet(
        store: _store,
        sheetBytes: bytes,
        title: '动画工程',
        rows: _animationRows,
        columns: _animationColumns,
        defaultDelayMs: _gifDefaultFrameDelayMs,
        gridSpec: _animationGridSpec,
        sourceImagePath: source.filePath,
      );
      final item = await _imageLibraryService.addAnimationProject(
        store: _store,
        path: result.projectFile.path,
        project: result.project,
      );
      if (!mounted) {
        return;
      }
      final beforeProject = _animationProject;
      final beforeTrackId = _selectedAnimationTrackId;
      setState(() {
        _animationProject = result.project;
        _selectedAnimationTrackId = result.project.tracks.isEmpty
            ? null
            : result.project.tracks.first.id;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _pushAnimationProjectHistory(
        label: '导入 Sprite Sheet 为动画工程',
        beforeProject: beforeProject,
        beforeTrackId: beforeTrackId,
        afterProject: result.project,
        afterTrackId: _selectedAnimationTrackId,
        appendedItems: [item],
      );
      _showMessage('已导入动画工程：${result.project.tracks.length} 条轨道');
    } catch (error) {
      if (mounted) {
        setState(() => _animationProjectErrorMessage = '导入动画工程失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _isAnimationProjectBusy = false);
      }
    }
  }

  void _clearAnimationProject() {
    final beforeProject = _animationProject;
    final beforeTrackId = _selectedAnimationTrackId;
    if (beforeProject == null) {
      return;
    }
    setState(() {
      _animationProject = null;
      _selectedAnimationTrackId = null;
      _animationProjectErrorMessage = null;
    });
    _pushAnimationProjectHistory(
      label: '关闭动画工程',
      beforeProject: beforeProject,
      beforeTrackId: beforeTrackId,
      afterProject: null,
      afterTrackId: null,
    );
  }

  void _selectAnimationTrack(String trackId) {
    if (_selectedAnimationTrackId == trackId) {
      return;
    }
    final beforeTrackId = _selectedAnimationTrackId;
    setState(() => _selectedAnimationTrackId = trackId);
    _pushAnimationProjectHistory(
      label: '选择动画轨道',
      beforeProject: _animationProject,
      beforeTrackId: beforeTrackId,
      afterProject: _animationProject,
      afterTrackId: trackId,
    );
  }

  Future<void> _renameAnimationTrack(String trackId, String name) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return;
    }
    final before = project;
    final next = project
        .copyWith(
          tracks: [
            for (final track in project.tracks)
              track.id == trackId ? track.copyWith(name: normalized) : track,
          ],
        )
        .touch();
    await _applyAnimationProjectChange(
      label: '重命名动画轨道',
      beforeProject: before,
      afterProject: next,
    );
  }

  Future<void> _setAnimationTrackDelay(String trackId, int delayMs) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '调整轨道帧时长',
      beforeProject: project,
      result: const AnimationProjectEditor().setTrackDelay(
        project: project,
        trackId: trackId,
        delayMs: delayMs,
      ),
    );
  }

  Future<void> _setAnimationTrackPlaybackMode(
    String trackId,
    AnimationPlaybackMode mode,
  ) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '调整轨道播放方式',
      beforeProject: project,
      result: const AnimationProjectEditor().setTrackPlaybackMode(
        project: project,
        trackId: trackId,
        mode: mode,
      ),
    );
  }

  Future<void> _setAnimationProjectDefaultDelay(int delayMs) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '调整工程默认帧时长',
      beforeProject: project,
      result: const AnimationProjectEditor().setProjectDefaultDelay(
        project: project,
        delayMs: delayMs,
      ),
    );
  }

  Future<void> _setAnimationProjectPlaybackMode(
    AnimationPlaybackMode mode,
  ) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '调整工程播放方式',
      beforeProject: project,
      result: const AnimationProjectEditor().setProjectPlaybackMode(
        project: project,
        mode: mode,
      ),
    );
  }

  Future<void> _setAnimationProjectLoopCount(int loopCount) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '调整工程 GIF 循环次数',
      beforeProject: project,
      result: const AnimationProjectEditor().setProjectLoopCount(
        project: project,
        loopCount: loopCount,
      ),
    );
  }

  Future<void> _setAnimationProjectIncludeHiddenTracks(
    bool includeHiddenTracks,
  ) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: includeHiddenTracks ? '导出包含隐藏轨道' : '导出排除隐藏轨道',
      beforeProject: project,
      result: const AnimationProjectEditor().setProjectIncludeHiddenTracks(
        project: project,
        includeHiddenTracks: includeHiddenTracks,
      ),
    );
  }

  Future<void> _importLocalImagesToAnimationProject() async {
    final files = await openFiles(acceptedTypeGroups: templateImageTypeGroups);
    if (files.isEmpty) {
      return;
    }
    setState(() {
      _isAnimationProjectBusy = true;
      _animationProjectErrorMessage = null;
    });

    try {
      final paths = [for (final file in files) file.path];
      final currentProject = _animationProject;
      if (currentProject == null) {
        final result = await _animationProjectImporter.importImagesAsTrack(
          store: _store,
          imagePaths: paths,
          title: '动画工程',
          defaultDelayMs: _gifDefaultFrameDelayMs,
        );
        final item = await _imageLibraryService.addAnimationProject(
          store: _store,
          path: result.projectFile.path,
          project: result.project,
        );
        if (!mounted) {
          return;
        }
        final beforeProject = _animationProject;
        final beforeTrackId = _selectedAnimationTrackId;
        setState(() {
          _animationProject = result.project;
          _selectedAnimationTrackId = result.project.tracks.first.id;
          _imageLibrary = [item, ..._imageLibrary];
        });
        _pushAnimationProjectHistory(
          label: '导入图片序列为动画工程',
          beforeProject: beforeProject,
          beforeTrackId: beforeTrackId,
          afterProject: result.project,
          afterTrackId: _selectedAnimationTrackId,
          appendedItems: [item],
        );
        _showMessage('已导入 ${paths.length} 张图片为动画工程');
        return;
      }

      final before = currentProject;
      final next = await _animationProjectImporter.appendImagesAsTrack(
        store: _store,
        project: currentProject,
        imagePaths: paths,
        trackName: '导入序列 ${currentProject.tracks.length + 1}',
        defaultDelayMs: _gifDefaultFrameDelayMs,
      );
      final selectedTrackId = next.tracks.last.id;
      await _applyAnimationProjectChange(
        label: '导入图片序列为轨道',
        beforeProject: before,
        afterProject: next,
        updateSelectedTrack: true,
        selectedTrackId: selectedTrackId,
      );
      _showMessage('已导入 ${paths.length} 张图片为新轨道');
    } catch (error) {
      if (mounted) {
        setState(() => _animationProjectErrorMessage = '导入图片序列失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _isAnimationProjectBusy = false);
      }
    }
  }

  Future<void> _addAnimationTrack() async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '新建动画轨道',
      beforeProject: project,
      result: const AnimationProjectEditor().addTrack(
        project: project,
        defaultDelayMs: _gifDefaultFrameDelayMs,
      ),
    );
  }

  Future<void> _duplicateAnimationTrack(String trackId) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '复制动画轨道',
      beforeProject: project,
      result: const AnimationProjectEditor().duplicateTrack(
        project: project,
        trackId: trackId,
      ),
    );
  }

  Future<void> _deleteAnimationTrack(String trackId) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '删除动画轨道',
      beforeProject: project,
      result: const AnimationProjectEditor().deleteTrack(
        project: project,
        trackId: trackId,
      ),
    );
  }

  Future<void> _moveAnimationTrack(String trackId, int delta) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '调整动画轨道顺序',
      beforeProject: project,
      result: const AnimationProjectEditor().moveTrack(
        project: project,
        trackId: trackId,
        delta: delta,
      ),
    );
  }

  Future<void> _setAnimationTrackVisible(String trackId, bool visible) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: visible ? '显示动画轨道' : '隐藏动画轨道',
      beforeProject: project,
      result: const AnimationProjectEditor().setTrackVisible(
        project: project,
        trackId: trackId,
        visible: visible,
      ),
    );
  }

  Future<void> _setAnimationTrackLocked(String trackId, bool locked) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: locked ? '锁定动画轨道' : '解锁动画轨道',
      beforeProject: project,
      result: const AnimationProjectEditor().setTrackLocked(
        project: project,
        trackId: trackId,
        locked: locked,
      ),
    );
  }

  Future<void> _moveAnimationFrame(
    String trackId,
    int fromIndex,
    int toIndex,
  ) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '调整序列帧顺序',
      beforeProject: project,
      result: const AnimationProjectEditor().moveFrame(
        project: project,
        trackId: trackId,
        fromIndex: fromIndex,
        toIndex: toIndex,
      ),
    );
  }

  Future<void> _duplicateAnimationFrame(String trackId, int frameIndex) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '复制序列帧',
      beforeProject: project,
      result: const AnimationProjectEditor().duplicateFrame(
        project: project,
        trackId: trackId,
        frameIndex: frameIndex,
      ),
    );
  }

  Future<void> _deleteAnimationFrame(String trackId, int frameIndex) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '删除序列帧',
      beforeProject: project,
      result: const AnimationProjectEditor().deleteFrame(
        project: project,
        trackId: trackId,
        frameIndex: frameIndex,
      ),
    );
  }

  Future<void> _setAnimationFrameDelay(
    String trackId,
    int frameIndex,
    int delayMs,
  ) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '调整单帧时长',
      beforeProject: project,
      result: const AnimationProjectEditor().setFrameDelay(
        project: project,
        trackId: trackId,
        frameIndex: frameIndex,
        delayMs: delayMs,
      ),
    );
  }

  Future<void> _setAnimationFrameTransform(
    String trackId,
    int frameIndex,
    FrameTransform transform,
  ) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: '调整单帧变换',
      beforeProject: project,
      result: const AnimationProjectEditor().setFrameTransform(
        project: project,
        trackId: trackId,
        frameIndex: frameIndex,
        transform: transform,
      ),
    );
  }

  Future<void> _rebindAnimationFrameAsset(String assetId) async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    final file = await openFile(acceptedTypeGroups: templateImageTypeGroups);
    if (file == null) {
      return;
    }

    setState(() {
      _isAnimationProjectBusy = true;
      _animationProjectErrorMessage = null;
    });
    try {
      final next = await _animationProjectImporter.rebindFrameAsset(
        store: _store,
        project: project,
        assetId: assetId,
        imagePath: file.path,
      );
      await _applyAnimationProjectChange(
        label: '重新绑定动画帧资源',
        beforeProject: project,
        afterProject: next,
      );
      _showMessage('已重新绑定帧资源：${fileNameFromPath(file.path)}');
    } catch (error) {
      if (mounted) {
        setState(() => _animationProjectErrorMessage = '重新绑定帧资源失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _isAnimationProjectBusy = false);
      }
    }
  }

  Future<void> _repairAnimationProjectConsistency() async {
    final project = _animationProject;
    if (project == null) {
      return;
    }
    final result = const AnimationProjectEditor().repairConsistency(
      project: project,
    );
    if (result == null) {
      _showMessage('没有可自动修复的工程问题');
      return;
    }
    await _applyAnimationProjectEdit(
      label: '自动修复动画工程一致性',
      beforeProject: project,
      result: result,
    );
    _showMessage('已自动修复工程一致性问题');
  }

  Future<void> _applyAnimationProjectEdit({
    required String label,
    required AnimationProject beforeProject,
    required AnimationProjectEditResult? result,
  }) async {
    if (result == null) {
      return;
    }
    await _applyAnimationProjectChange(
      label: label,
      beforeProject: beforeProject,
      afterProject: result.project,
      updateSelectedTrack: result.selectedTrackId != null,
      selectedTrackId: result.selectedTrackId,
    );
  }

  Future<void> _applyAnimationProjectChange({
    required String label,
    required AnimationProject beforeProject,
    required AnimationProject afterProject,
    bool updateSelectedTrack = false,
    String? selectedTrackId,
  }) async {
    final beforeTrackId = _selectedAnimationTrackId;
    setState(() {
      _animationProject = afterProject;
      if (updateSelectedTrack) {
        _selectedAnimationTrackId = selectedTrackId;
      } else if (_selectedAnimationTrackId != null &&
          afterProject.trackById(_selectedAnimationTrackId!) == null) {
        _selectedAnimationTrackId = afterProject.tracks.isEmpty
            ? null
            : afterProject.tracks.first.id;
      }
    });
    await _animationProjectStore.saveProject(_store, afterProject);
    await _syncAnimationProjectLibraryItem(afterProject);
    _pushAnimationProjectHistory(
      label: label,
      beforeProject: beforeProject,
      beforeTrackId: beforeTrackId,
      afterProject: afterProject,
      afterTrackId: _selectedAnimationTrackId,
    );
  }

  Future<void> _syncAnimationProjectLibraryItem(
    AnimationProject project,
  ) async {
    final summary = AnimationProjectSummary.fromProject(project);
    final nextLibrary = [
      for (final item in _imageLibrary)
        if (item.kind == ImageAssetKind.animationProject &&
            item.groupId == project.id)
          item.copyWith(title: project.title, animationProject: summary)
        else
          item,
    ];
    await _store.saveImageLibrary(nextLibrary);
    if (!mounted) {
      return;
    }
    _imageLibrary = nextLibrary;
  }

  void _pushAnimationProjectHistory({
    required String label,
    required AnimationProject? beforeProject,
    required String? beforeTrackId,
    required AnimationProject? afterProject,
    required String? afterTrackId,
    List<ImageLibraryItem> appendedItems = const [],
  }) {
    _pushHistory(
      WorkspaceFeature.animationProject,
      HistoryAction(
        label: label,
        apply: () => _restoreAnimationProjectState(
          project: afterProject,
          selectedTrackId: afterTrackId,
          appendedItems: appendedItems,
        ),
        revert: () => _restoreAnimationProjectState(
          project: beforeProject,
          selectedTrackId: beforeTrackId,
          removedItemIds: {for (final item in appendedItems) item.id},
        ),
      ),
    );
  }

  Future<void> _restoreAnimationProjectState({
    required AnimationProject? project,
    required String? selectedTrackId,
    List<ImageLibraryItem> appendedItems = const [],
    Set<String> removedItemIds = const {},
  }) async {
    await _applyImageLibraryMerge(
      appendedItems: appendedItems,
      removedItemIds: removedItemIds,
      updateState: () {
        _animationProject = project;
        _selectedAnimationTrackId = selectedTrackId;
        _animationProjectErrorMessage = null;
      },
    );
  }

  Future<void> _exportAnimationProjectSpriteSheet() async {
    final project = _animationProject;
    if (project == null) {
      _showMessage('请先导入动画工程');
      return;
    }
    try {
      final output = await _animationProjectExportService
          .exportProjectSpriteSheet(store: _store, project: project);
      final item = await _imageLibraryService.addExportedSpriteSheet(
        store: _store,
        path: output.path,
        rows: output.rows ?? 1,
        columns:
            output.columns ?? _animationProjectCompositeFrameCount(project),
        gridSpec:
            output.gridSpec ??
            SpriteSheetGridSpec(
              rows: 1,
              columns: _animationProjectCompositeFrameCount(project),
            ),
      );
      if (!mounted) {
        return;
      }
      _imageLibrary = [item, ..._imageLibrary];
      _pushImageLibraryAppendHistory(
        feature: WorkspaceFeature.animationProject,
        label: '导出动画工程 Sprite Sheet',
        appendedItems: [item],
      );
      _showMessage('动画工程 Sprite Sheet 已导出：${fileNameFromPath(output.path)}');
    } catch (error) {
      if (mounted) {
        setState(() => _animationProjectErrorMessage = '导出失败：$error');
      }
    }
  }

  Future<void> _exportAnimationProjectGif() async {
    final project = _animationProject;
    if (project == null) {
      _showMessage('请先导入动画工程');
      return;
    }
    try {
      final output = await _animationProjectExportService.exportProjectGif(
        store: _store,
        project: project,
      );
      final frameCount = _animationProjectCompositeFrameCount(project);
      final item = await _imageLibraryService.addGif(
        store: _store,
        path: output.path,
        frameCount: frameCount,
      );
      if (!mounted) {
        return;
      }
      _imageLibrary = [item, ..._imageLibrary];
      _pushImageLibraryAppendHistory(
        feature: WorkspaceFeature.animationProject,
        label: '导出动画工程 GIF',
        appendedItems: [item],
      );
      _showMessage('动画工程 GIF 已导出：${fileNameFromPath(output.path)}');
    } catch (error) {
      if (mounted) {
        setState(() => _animationProjectErrorMessage = '导出工程 GIF 失败：$error');
      }
    }
  }

  Future<void> _exportAnimationTrackGif() async {
    final project = _animationProject;
    final trackId = _selectedAnimationTrackId;
    if (project == null || trackId == null) {
      _showMessage('请先选择动画轨道');
      return;
    }
    try {
      final output = await _animationProjectExportService.exportTrackGif(
        store: _store,
        project: project,
        trackId: trackId,
      );
      final frameCount = project.trackById(trackId)?.totalFrameRefs ?? 0;
      final item = await _imageLibraryService.addGif(
        store: _store,
        path: output.path,
        frameCount: frameCount,
      );
      if (!mounted) {
        return;
      }
      _imageLibrary = [item, ..._imageLibrary];
      _pushImageLibraryAppendHistory(
        feature: WorkspaceFeature.animationProject,
        label: '导出动画轨道 GIF',
        appendedItems: [item],
      );
      _showMessage('当前轨道 GIF 已导出：${fileNameFromPath(output.path)}');
    } catch (error) {
      if (mounted) {
        setState(() => _animationProjectErrorMessage = '导出 GIF 失败：$error');
      }
    }
  }

  Future<void> _exportAnimationProjectPngSequence() async {
    final project = _animationProject;
    if (project == null) {
      _showMessage('请先导入动画工程');
      return;
    }
    try {
      final files = await _animationProjectExportService
          .exportProjectPngSequence(store: _store, project: project);
      if (!mounted) {
        return;
      }
      _showMessage('已导出 ${files.length} 张工程合成 PNG 序列帧');
    } catch (error) {
      if (mounted) {
        setState(() => _animationProjectErrorMessage = '导出工程 PNG 序列失败：$error');
      }
    }
  }

  Future<void> _exportAnimationTrackPngSequence() async {
    final project = _animationProject;
    final trackId = _selectedAnimationTrackId;
    if (project == null || trackId == null) {
      _showMessage('请先选择动画轨道');
      return;
    }
    try {
      final files = await _animationProjectExportService.exportTrackPngSequence(
        store: _store,
        project: project,
        trackId: trackId,
      );
      if (!mounted) {
        return;
      }
      _showMessage('已导出 ${files.length} 张 PNG 序列帧');
    } catch (error) {
      if (mounted) {
        setState(() => _animationProjectErrorMessage = '导出 PNG 序列失败：$error');
      }
    }
  }

  int _animationProjectCompositeFrameCount(AnimationProject project) {
    final renderHidden = project.exportSettings.includeHiddenTracks;
    var maxCount = 1;
    for (final track in project.tracks) {
      if (!renderHidden && !track.visible) {
        continue;
      }
      final frameCount = track.orderedFrames.length;
      if (frameCount <= 1) {
        if (frameCount > maxCount) {
          maxCount = frameCount;
        }
        continue;
      }
      final expandedCount = switch (track.playbackMode) {
        AnimationPlaybackMode.normal => frameCount,
        AnimationPlaybackMode.reverse => frameCount,
        AnimationPlaybackMode.pingPong => frameCount + frameCount - 2,
      };
      if (expandedCount > maxCount) {
        maxCount = expandedCount;
      }
    }
    return maxCount;
  }

  void _exportRenderedAnimationSpriteSheet(AnimationSpriteSheetRender render) {
    unawaited(
      _exportSpriteSheet(
        pngBytes: render.bytes,
        rows: render.rows,
        columns: render.columns,
        gridSpec: render.gridSpec,
      ),
    );
  }

  void _exportSourceAnimationSpriteSheet(Uint8List bytes) {
    unawaited(
      _exportSpriteSheet(
        pngBytes: bytes,
        rows: _animationRows,
        columns: _animationColumns,
        gridSpec: _animationGridSpec,
      ),
    );
  }

  void _sendRenderedAnimationToGif(AnimationSpriteSheetRender render) {
    final previewData = SpriteSheetPreviewComposer.buildFromSheetBytes(
      render.bytes,
      rows: render.rows,
      columns: render.columns,
      gridSpec: render.gridSpec,
    );
    unawaited(_sendPreviewDataToGif(previewData));
  }

  void _openRenderedAnimationInEditor(AnimationSpriteSheetRender render) {
    final previewData = SpriteSheetPreviewComposer.buildFromSheetBytes(
      render.bytes,
      rows: render.rows,
      columns: render.columns,
      gridSpec: render.gridSpec,
    );
    unawaited(_openAnimationPreviewInEditor(previewData));
  }

  Widget _buildImageGenerationWorkspace() {
    return ImageGenerationWorkspace(
      controller: _scrollController,
      historyControls: _buildCompactHistoryControls(),
      apiConfigs: _apiConfigs,
      selectedApiConfig: _selectedApiConfig,
      promptController: _promptController,
      negativePromptController: _negativePromptController,
      size: _size,
      imageCount: _imageCount,
      advancedSettings: _advancedSettings,
      userController: _userController,
      onApiConfigChanged: _selectApiConfig,
      onOpenApiSettings: () =>
          unawaited(_selectFeature(WorkspaceFeature.apiSettings)),
      onSizeChanged: _setSize,
      onImageCountChanged: _setImageCount,
      onAdvancedSettingsChanged: _setAdvancedSettings,
      onGenerate: _generateImage,
      onCopyImage: (index, image) =>
          unawaited(_copyGeneratedPreviewImage(image)),
      onExportImage: (index, image) =>
          unawaited(_exportGeneratedPreviewImage(index, image)),
      onMakeBackgroundTransparent: (index, image) =>
          unawaited(_makeGeneratedImageBackgroundTransparent(index, image)),
    );
  }

  Widget _buildAnimationProjectWorkspace() {
    return AnimationProjectWorkspace(
      historyControls: _buildCompactHistoryControls(),
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
      project: _animationProject,
      selectedTrackId: _selectedAnimationTrackId,
      isProjectBusy: _isAnimationProjectBusy,
      projectErrorMessage: _animationProjectErrorMessage,
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
      onImportGeneratedSheet: () =>
          unawaited(_importCurrentAnimationSheetToProject()),
      onImportImageSequence: () =>
          unawaited(_importLocalImagesToAnimationProject()),
      onClearProject: _clearAnimationProject,
      onTrackSelected: _selectAnimationTrack,
      onTrackAdded: () => unawaited(_addAnimationTrack()),
      onTrackDuplicated: (trackId) =>
          unawaited(_duplicateAnimationTrack(trackId)),
      onTrackDeleted: (trackId) => unawaited(_deleteAnimationTrack(trackId)),
      onTrackMoved: (trackId, delta) =>
          unawaited(_moveAnimationTrack(trackId, delta)),
      onTrackRenamed: (trackId, name) =>
          unawaited(_renameAnimationTrack(trackId, name)),
      onProjectDefaultDelayChanged: (delayMs) =>
          unawaited(_setAnimationProjectDefaultDelay(delayMs)),
      onProjectPlaybackModeChanged: (mode) =>
          unawaited(_setAnimationProjectPlaybackMode(mode)),
      onProjectLoopCountChanged: (loopCount) =>
          unawaited(_setAnimationProjectLoopCount(loopCount)),
      onProjectIncludeHiddenTracksChanged: (includeHiddenTracks) => unawaited(
        _setAnimationProjectIncludeHiddenTracks(includeHiddenTracks),
      ),
      onTrackDelayChanged: (trackId, delayMs) =>
          unawaited(_setAnimationTrackDelay(trackId, delayMs)),
      onTrackPlaybackModeChanged: (trackId, mode) =>
          unawaited(_setAnimationTrackPlaybackMode(trackId, mode)),
      onTrackVisibilityChanged: (trackId, visible) =>
          unawaited(_setAnimationTrackVisible(trackId, visible)),
      onTrackLockChanged: (trackId, locked) =>
          unawaited(_setAnimationTrackLocked(trackId, locked)),
      onFrameMoved: (trackId, fromIndex, toIndex) =>
          unawaited(_moveAnimationFrame(trackId, fromIndex, toIndex)),
      onFrameDuplicated: (trackId, frameIndex) =>
          unawaited(_duplicateAnimationFrame(trackId, frameIndex)),
      onFrameDeleted: (trackId, frameIndex) =>
          unawaited(_deleteAnimationFrame(trackId, frameIndex)),
      onFrameDelayChanged: (trackId, frameIndex, delayMs) =>
          unawaited(_setAnimationFrameDelay(trackId, frameIndex, delayMs)),
      onFrameTransformChanged: (trackId, frameIndex, transform) => unawaited(
        _setAnimationFrameTransform(trackId, frameIndex, transform),
      ),
      onFrameAssetRebound: (assetId) =>
          unawaited(_rebindAnimationFrameAsset(assetId)),
      onProjectAutoRepaired: () =>
          unawaited(_repairAnimationProjectConsistency()),
      onExportProjectSpriteSheet: () =>
          unawaited(_exportAnimationProjectSpriteSheet()),
      onExportProjectGif: () => unawaited(_exportAnimationProjectGif()),
      onExportProjectPngSequence: () =>
          unawaited(_exportAnimationProjectPngSequence()),
      onExportTrackGif: () => unawaited(_exportAnimationTrackGif()),
      onExportTrackPngSequence: () =>
          unawaited(_exportAnimationTrackPngSequence()),
      onExportSourceSpriteSheet: _exportSourceAnimationSpriteSheet,
      onExportRenderedSpriteSheet: _exportRenderedAnimationSpriteSheet,
      onSendRenderedToGif: _sendRenderedAnimationToGif,
      onOpenRenderedInEditor: _openRenderedAnimationInEditor,
    );
  }
}
