// ignore_for_file: annotate_overrides

part of 'package:feather_canvas_studio/main.dart';

class _AnimationConfigSnapshot {
  const _AnimationConfigSnapshot({required this.config});

  final SpriteSheetImportConfig config;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _AnimationConfigSnapshot && config == other.config;
  }

  @override
  int get hashCode => config.hashCode;
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
  AnimationProjectFrameEditor get _animationProjectFrameEditor;
  ScrollController get _scrollController;
  TextEditingController get _animationPromptController;
  SpriteSheetImportConfig get _spriteSheetImportConfig;
  set _spriteSheetImportConfig(SpriteSheetImportConfig value);
  int get _animationRows;
  int get _animationColumns;
  SpriteSheetGridSpec get _animationGridSpec;
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
  String? get _imageTemplateImagePath;
  set _imageTemplateImagePath(String? value);
  Set<String> get _ephemeralTemplatePaths;
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
    final l10n = appL10nOf(context);
    final before = _captureAnimationConfig();
    setState(() {
      _spriteSheetImportConfig = _spriteSheetImportConfig.withRows(value);
    });
    _pushAnimationConfigHistory(
      label: l10n.imageGenerationAdjustAnimationRowsHistory(value),
      before: before,
      mergeKey: _animationGridConfigHistoryKey,
    );
  }

  void _setAnimationColumns(int value) {
    final l10n = appL10nOf(context);
    final before = _captureAnimationConfig();
    setState(() {
      _spriteSheetImportConfig = _spriteSheetImportConfig.withColumns(value);
    });
    _pushAnimationConfigHistory(
      label: l10n.imageGenerationAdjustAnimationColumnsHistory(value),
      before: before,
      mergeKey: _animationGridConfigHistoryKey,
    );
  }

  void _setAnimationGridSpec(SpriteSheetGridSpec value) {
    final l10n = appL10nOf(context);
    final before = _captureAnimationConfig();
    setState(() {
      _spriteSheetImportConfig = _spriteSheetImportConfig.withGridSpec(value);
    });
    _pushAnimationConfigHistory(
      label: l10n.imageGenerationAdjustAnimationGridSpecHistory,
      before: before,
      mergeKey: _animationGridConfigHistoryKey,
    );
  }

  _AnimationConfigSnapshot _captureAnimationConfig() {
    return _AnimationConfigSnapshot(config: _spriteSheetImportConfig);
  }

  void _restoreAnimationConfig(_AnimationConfigSnapshot snapshot) {
    if (!mounted) {
      return;
    }

    setState(() {
      _spriteSheetImportConfig = snapshot.config;
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
    final l10n = appL10nOf(context);
    final apiConfig = await _prepareSelectedApiConfigForRequest();
    if (!mounted) {
      return;
    }

    final prompt = _promptController.text.trim();
    final templatePath = _imageTemplateImagePath;
    final beforeImages = List<GeneratedImage>.unmodifiable(_generatedImages);
    final beforeDebugRecord = _imageRequestDebugRecord;

    if (apiConfig.apiKey.trim().isEmpty) {
      _showMessage(l10n.imageGenerationMissingApiKeyMessage);
      return;
    }

    if (apiConfig.model.trim().isEmpty) {
      _showMessage(l10n.imageGenerationMissingModelMessage);
      return;
    }

    if (prompt.isEmpty) {
      _showMessage(l10n.imageGenerationMissingPositivePromptMessage);
      return;
    }

    if (templatePath != null && !await _fileService.fileExists(templatePath)) {
      _showMessage(l10n.imageGenerationTemplateImageMissingMessage);
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
          templateImagePath: templatePath,
          titlePrefix: templatePath == null
              ? l10n.imageGenerationTextImageSource
              : l10n.imageGenerationReferenceImageSource,
          source: templatePath == null
              ? l10n.imageGenerationTextImageSource
              : l10n.imageGenerationReferenceImageSource,
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
        label: l10n.imageGenerationGenerateImagesHistory(allImages.length),
        beforeImages: beforeImages,
        beforeDebugRecord: beforeDebugRecord,
        afterImages: List<GeneratedImage>.unmodifiable(allImages),
        afterDebugRecord: _imageRequestDebugRecord,
        appendedItems: List<ImageLibraryItem>.unmodifiable(allLibraryItems),
      );
      _showMessage(
        templatePath == null
            ? l10n.imageGenerationImagesGeneratedMessage(allImages.length)
            : l10n.imageGenerationReferenceImagesGeneratedMessage(
                allImages.length,
              ),
      );
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
      _errorMessage = l10n.imageGenerationRequestTimeoutMessage;
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() {
        _imageRequestDebugRecord = _recordUnexpectedGenerationError(
          _imageRequestDebugRecord,
          error,
          stackTrace,
          fallbackPrefix: l10n.imageGenerationFailedPrefix,
        );
        _errorMessage = _unexpectedGenerationErrorMessage(
          error,
          fallbackPrefix: l10n.imageGenerationFailedPrefix,
        );
      });
    } finally {
      if (mounted) {
        _isGenerating = false;
      }
    }
  }

  Future<void> _pickImageTemplateImage() async {
    final l10n = appL10nOf(context);
    final candidates = _availableImageLibraryItems(
      allowedKinds: templateLibraryKinds,
    );
    final source = await _selectImagePickSource(
      title: l10n.imageGenerationSelectReferenceImageTitle,
      allowLibrary: candidates.isNotEmpty,
      libraryEmptyMessage: l10n.imageGenerationReferenceLibraryEmpty,
    );
    if (source == null || !mounted) {
      return;
    }

    String? imagePath;
    String? sliceLabel;
    if (source == ImagePickSource.localFile) {
      final image = await openFile(acceptedTypeGroups: templateImageTypeGroups);
      imagePath = image?.path;
    } else {
      final item = await _showImageLibraryPicker<ImageLibraryItem>(
        title: l10n.imageGenerationSelectReferenceImageTitle,
        allowedKinds: templateLibraryKinds,
      );
      if (item == null || !mounted) {
        return;
      }
      if (item.isSpriteSheetWithMetadata) {
        final picked = await _showSlicePicker(item, allowMultiple: false);
        if (picked == null || picked.isEmpty || !mounted) {
          return;
        }
        final entry = picked.first;
        final file = await _store.saveEphemeralBytes(
          prefix: 'reference',
          bytes: entry.value,
        );
        _ephemeralTemplatePaths.add(file.path);
        imagePath = file.path;
        sliceLabel = l10n.editorGifTemplateSliceLabel(
          item.displayTitle,
          entry.key + 1,
        );
      } else {
        imagePath = item.path;
      }
    }

    if (imagePath == null || !mounted) {
      return;
    }

    final previous = _imageTemplateImagePath;
    setState(() {
      _imageTemplateImagePath = imagePath;
      _errorMessage = null;
    });
    if (previous != null &&
        previous != imagePath &&
        _ephemeralTemplatePaths.remove(previous)) {
      unawaited(_fileService.safeDeleteFile(previous));
    }
    _showMessage(
      sliceLabel != null
          ? l10n.imageGenerationSelectedReferenceSliceMessage(sliceLabel)
          : l10n.imageGenerationSelectedReferenceImageMessage(
              fileNameFromPath(imagePath),
            ),
    );
  }

  void _clearImageTemplateImage() {
    final previous = _imageTemplateImagePath;
    setState(() => _imageTemplateImagePath = null);
    if (previous != null && _ephemeralTemplatePaths.remove(previous)) {
      unawaited(_fileService.safeDeleteFile(previous));
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
    final l10n = appL10nOf(context);
    switch (result.status) {
      case ImageClipboardCopyStatus.imageCopied:
        _showMessage(l10n.imageGenerationImageCopiedMessage);
      case ImageClipboardCopyStatus.pathCopied:
        _showMessage(l10n.imageGenerationImagePathCopiedMessage);
    }
  }

  Future<void> _copyGeneratedPreviewImage(GeneratedImage image) async {
    final l10n = appL10nOf(context);
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
      _showMessage(l10n.imageGenerationCopyImageFailedMessage(error));
    }
  }

  Future<void> _exportGeneratedPreviewImage(
    int index,
    GeneratedImage image,
  ) async {
    final l10n = appL10nOf(context);
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
      _showMessage(
        l10n.imageGenerationImageExportedMessage(
          fileNameFromPath(result.destinationPath),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.imageGenerationExportImageFailedMessage(error));
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
    final l10n = appL10nOf(context);
    final beforeImages = List<GeneratedImage>.unmodifiable(_generatedImages);
    final beforeDebugRecord = _imageRequestDebugRecord;
    final sourceItem = _findImageLibraryItemByPath(image.filePath);
    final fallbackTitle = l10n.imageGenerationGeneratedResultTitle(index + 1);
    final tolerance = await showBackgroundTransparencyDialog(
      context,
      sourceTitle: sourceItem?.displayTitle ?? fallbackTitle,
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
        fallbackTitle: fallbackTitle,
        source: l10n.imageGenerationTextImageSource,
      );
      if (!mounted) {
        return;
      }
      if (saved == null) {
        _showMessage(l10n.editorGifNoTransparentEdgeMessage);
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
        label: l10n.imageGenerationTransparentBackgroundHistory(
          sourceItem?.displayTitle ?? fallbackTitle,
        ),
        beforeImages: beforeImages,
        beforeDebugRecord: beforeDebugRecord,
        afterImages: _generatedImages,
        afterDebugRecord: _imageRequestDebugRecord,
        appendedItems: [saved.item],
      );
      _showMessage(
        l10n.imageGenerationTransparentBackgroundSavedMessage(
          saved.item.displayTitle,
          saved.transparentPixelCount,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.editorGifTransparentBackgroundFailedMessage(error));
    }
  }

  Future<void> _generateAnimationFrames() async {
    final l10n = appL10nOf(context);
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
      setState(
        () => _animationErrorMessage = l10n.imageGenerationMissingApiKeyError,
      );
      return;
    }

    if (apiConfig.model.trim().isEmpty) {
      setState(
        () => _animationErrorMessage = l10n.imageGenerationMissingModelError,
      );
      return;
    }

    if (prompt.isEmpty) {
      setState(
        () => _animationErrorMessage =
            l10n.imageGenerationMissingAnimationPromptError,
      );
      return;
    }

    if (totalFrames <= 0) {
      setState(
        () => _animationErrorMessage =
            l10n.imageGenerationInvalidAnimationGridError,
      );
      return;
    }

    if (templatePath != null && !await _fileService.fileExists(templatePath)) {
      setState(
        () => _animationErrorMessage =
            l10n.imageGenerationTemplateImageMissingError,
      );
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
        source: l10n.imageGenerationSpriteSheetSource,
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
        label: l10n.imageGenerationGenerateSpriteSheetHistory,
        beforeFrames: beforeFrames,
        beforeDebugRecord: beforeDebugRecord,
        afterFrames: [result.cachedSheet],
        afterDebugRecord: _animationRequestDebugRecord,
        appendedItem: result.libraryItem,
      );
      _showMessage(l10n.imageGenerationSpriteSheetGeneratedImportingMessage);
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
      setState(
        () =>
            _animationErrorMessage = l10n.imageGenerationRequestTimeoutMessage,
      );
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() {
        _animationRequestDebugRecord = _recordUnexpectedGenerationError(
          _animationRequestDebugRecord,
          error,
          stackTrace,
          fallbackPrefix: l10n.imageGenerationSpriteSheetFailedPrefix,
        );
        _animationErrorMessage = _unexpectedGenerationErrorMessage(
          error,
          fallbackPrefix: l10n.imageGenerationSpriteSheetFailedPrefix,
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
      return appL10nOf(
        context,
      ).imageGenerationStackOverflowMessage(fallbackPrefix);
    }
    return appL10nOf(
      context,
    ).imageGenerationUnexpectedErrorMessage(fallbackPrefix, error);
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

  Future<void> _importCurrentAnimationSheetToProject() async {
    final l10n = appL10nOf(context);
    if (_animationFrames.isEmpty) {
      _showMessage(l10n.imageGenerationImportSpriteSheetFirstMessage);
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
        title: l10n.navAnimationProject,
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
        labels: imageLibraryAnimationProjectLabels(l10n, result.project),
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
        label: l10n.imageGenerationImportSpriteSheetProjectHistory,
        beforeProject: beforeProject,
        beforeTrackId: beforeTrackId,
        afterProject: result.project,
        afterTrackId: _selectedAnimationTrackId,
        appendedItems: [item],
      );
      _showMessage(
        l10n.imageGenerationImportedAnimationProjectMessage(
          result.project.tracks.length,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _animationProjectErrorMessage = l10n
              .imageGenerationImportAnimationProjectFailedMessage(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnimationProjectBusy = false);
      }
    }
  }

  void _clearAnimationProject() {
    final l10n = appL10nOf(context);
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
      label: l10n.imageGenerationCloseAnimationProjectHistory,
      beforeProject: beforeProject,
      beforeTrackId: beforeTrackId,
      afterProject: null,
      afterTrackId: null,
    );
  }

  void _selectAnimationTrack(String trackId) {
    final l10n = appL10nOf(context);
    if (_selectedAnimationTrackId == trackId) {
      return;
    }
    final beforeTrackId = _selectedAnimationTrackId;
    setState(() => _selectedAnimationTrackId = trackId);
    _pushAnimationProjectHistory(
      label: l10n.imageGenerationSelectAnimationTrackHistory,
      beforeProject: _animationProject,
      beforeTrackId: beforeTrackId,
      afterProject: _animationProject,
      afterTrackId: trackId,
    );
  }

  Future<void> _renameAnimationTrack(String trackId, String name) async {
    final l10n = appL10nOf(context);
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
      label: l10n.imageGenerationRenameAnimationTrackHistory,
      beforeProject: before,
      afterProject: next,
    );
  }

  Future<void> _setAnimationTrackDelay(String trackId, int delayMs) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationAdjustTrackFrameDelayHistory,
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
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationAdjustTrackPlaybackHistory,
      beforeProject: project,
      result: const AnimationProjectEditor().setTrackPlaybackMode(
        project: project,
        trackId: trackId,
        mode: mode,
      ),
    );
  }

  Future<void> _setAnimationProjectDefaultDelay(int delayMs) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationAdjustProjectDefaultDelayHistory,
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
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationAdjustProjectPlaybackHistory,
      beforeProject: project,
      result: const AnimationProjectEditor().setProjectPlaybackMode(
        project: project,
        mode: mode,
      ),
    );
  }

  Future<void> _setAnimationProjectLoopCount(int loopCount) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationAdjustProjectGifLoopHistory,
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
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: includeHiddenTracks
          ? l10n.imageGenerationExportIncludeHiddenTracksHistory
          : l10n.imageGenerationExportExcludeHiddenTracksHistory,
      beforeProject: project,
      result: const AnimationProjectEditor().setProjectIncludeHiddenTracks(
        project: project,
        includeHiddenTracks: includeHiddenTracks,
      ),
    );
  }

  Future<void> _importLocalImagesToAnimationProject() async {
    final l10n = appL10nOf(context);
    final files = await openFiles(acceptedTypeGroups: templateImageTypeGroups);
    if (files.isEmpty) {
      return;
    }
    final paths = [for (final file in files) file.path];
    await _importImagePathsToAnimationProject(
      paths,
      sourceLabel: l10n.imageGenerationLocalSourceLabel,
    );
  }

  Future<void> _importLibraryImagesToAnimationProject() async {
    final l10n = appL10nOf(context);
    final items = await _showImageLibraryPicker<List<ImageLibraryItem>>(
      title: l10n.imageGenerationSelectLibrarySequenceTitle,
      allowMultiple: true,
      allowedKinds: const [
        ImageAssetKind.generatedImage,
        ImageAssetKind.spriteSheet,
        ImageAssetKind.spriteFrame,
        ImageAssetKind.editedImage,
      ],
    );
    if (items == null || items.isEmpty) {
      return;
    }
    final paths = [
      for (final item in items)
        if (item.isImageFile && !item.path.toLowerCase().endsWith('.gif'))
          item.path,
    ];
    if (paths.isEmpty) {
      _showMessage(l10n.imageGenerationLibraryNoImportableImagesMessage);
      return;
    }
    await _importImagePathsToAnimationProject(
      paths,
      sourceLabel: l10n.imageGenerationLibrarySourceLabel,
    );
  }

  Future<void> _importImagePathsToAnimationProject(
    List<String> paths, {
    required String sourceLabel,
  }) async {
    final l10n = appL10nOf(context);
    if (paths.isEmpty) {
      return;
    }
    setState(() {
      _isAnimationProjectBusy = true;
      _animationProjectErrorMessage = null;
    });

    try {
      final currentProject = _animationProject;
      if (currentProject == null) {
        final result = await _animationProjectImporter.importImagesAsTrack(
          store: _store,
          imagePaths: paths,
          title: l10n.navAnimationProject,
          defaultDelayMs: _gifDefaultFrameDelayMs,
        );
        final item = await _imageLibraryService.addAnimationProject(
          store: _store,
          path: result.projectFile.path,
          project: result.project,
          labels: imageLibraryAnimationProjectLabels(l10n, result.project),
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
          label: l10n.imageGenerationImportImageSequenceProjectHistory,
          beforeProject: beforeProject,
          beforeTrackId: beforeTrackId,
          afterProject: result.project,
          afterTrackId: _selectedAnimationTrackId,
          appendedItems: [item],
        );
        _showMessage(
          l10n.imageGenerationImportedImagesAsProjectMessage(
            paths.length,
            sourceLabel,
          ),
        );
        return;
      }

      final before = currentProject;
      final next = await _animationProjectImporter.appendImagesAsTrack(
        store: _store,
        project: currentProject,
        imagePaths: paths,
        trackName: l10n.imageGenerationImportedSequenceTrackName(
          currentProject.tracks.length + 1,
        ),
        defaultDelayMs: _gifDefaultFrameDelayMs,
      );
      final selectedTrackId = next.tracks.last.id;
      await _applyAnimationProjectChange(
        label: l10n.imageGenerationImportImageSequenceTrackHistory,
        beforeProject: before,
        afterProject: next,
        updateSelectedTrack: true,
        selectedTrackId: selectedTrackId,
      );
      _showMessage(
        l10n.imageGenerationImportedImagesAsTrackMessage(
          paths.length,
          sourceLabel,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _animationProjectErrorMessage = l10n
              .imageGenerationImportImageSequenceFailedMessage(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnimationProjectBusy = false);
      }
    }
  }

  Future<void> _addAnimationTrack() async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationAddAnimationTrackHistory,
      beforeProject: project,
      result: const AnimationProjectEditor().addTrack(
        project: project,
        defaultDelayMs: _gifDefaultFrameDelayMs,
      ),
    );
  }

  Future<void> _duplicateAnimationTrack(String trackId) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationDuplicateAnimationTrackHistory,
      beforeProject: project,
      result: const AnimationProjectEditor().duplicateTrack(
        project: project,
        trackId: trackId,
      ),
    );
  }

  Future<void> _deleteAnimationTrack(String trackId) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationDeleteAnimationTrackHistory,
      beforeProject: project,
      result: const AnimationProjectEditor().deleteTrack(
        project: project,
        trackId: trackId,
      ),
    );
  }

  Future<void> _moveAnimationTrack(String trackId, int delta) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationMoveAnimationTrackHistory,
      beforeProject: project,
      result: const AnimationProjectEditor().moveTrack(
        project: project,
        trackId: trackId,
        delta: delta,
      ),
    );
  }

  Future<void> _setAnimationTrackVisible(String trackId, bool visible) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: visible
          ? l10n.imageGenerationShowAnimationTrackHistory
          : l10n.imageGenerationHideAnimationTrackHistory,
      beforeProject: project,
      result: const AnimationProjectEditor().setTrackVisible(
        project: project,
        trackId: trackId,
        visible: visible,
      ),
    );
  }

  Future<void> _setAnimationTrackLocked(String trackId, bool locked) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: locked
          ? l10n.imageGenerationLockAnimationTrackHistory
          : l10n.imageGenerationUnlockAnimationTrackHistory,
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
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationMoveAnimationFrameHistory,
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
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationDuplicateAnimationFrameHistory,
      beforeProject: project,
      result: const AnimationProjectEditor().duplicateFrame(
        project: project,
        trackId: trackId,
        frameIndex: frameIndex,
      ),
    );
  }

  Future<void> _deleteAnimationFrame(String trackId, int frameIndex) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationDeleteAnimationFrameHistory,
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
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationAdjustFrameDelayHistory,
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
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationAdjustFrameTransformHistory,
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
    final l10n = appL10nOf(context);
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
        label: l10n.imageGenerationRebindFrameAssetHistory,
        beforeProject: project,
        afterProject: next,
      );
      _showMessage(
        l10n.imageGenerationReboundFrameAssetMessage(
          fileNameFromPath(file.path),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _animationProjectErrorMessage = l10n
              .imageGenerationRebindFrameAssetFailedMessage(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnimationProjectBusy = false);
      }
    }
  }

  Future<void> _replaceAnimationFrameAsset(
    String trackId,
    int frameIndex,
  ) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    final file = await openFile(acceptedTypeGroups: templateImageTypeGroups);
    if (file == null) {
      return;
    }

    await _editAnimationFrameAsset(
      label: l10n.imageGenerationReplaceAnimationFrameHistory,
      beforeProject: project,
      edit: () => _animationProjectFrameEditor.replaceFrameWithImage(
        store: _store,
        project: project,
        trackId: trackId,
        frameIndex: frameIndex,
        imagePath: file.path,
      ),
      successMessage: l10n.imageGenerationReplacedAnimationFrameMessage(
        frameIndex + 1,
        fileNameFromPath(file.path),
      ),
      errorPrefix: l10n.imageGenerationReplaceAnimationFrameFailedPrefix,
    );
  }

  Future<void> _insertBlankAnimationFrame(
    String trackId,
    int insertIndex,
  ) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _editAnimationFrameAsset(
      label: l10n.imageGenerationInsertBlankFrameHistory,
      beforeProject: project,
      edit: () => _animationProjectFrameEditor.insertBlankFrame(
        store: _store,
        project: project,
        trackId: trackId,
        insertIndex: insertIndex,
      ),
      successMessage: l10n.imageGenerationInsertedBlankFrameMessage(
        insertIndex + 1,
      ),
      errorPrefix: l10n.imageGenerationInsertBlankFrameFailedPrefix,
    );
  }

  Future<void> _insertAnimationFrameFromImage(
    String trackId,
    int insertIndex,
  ) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    final file = await openFile(acceptedTypeGroups: templateImageTypeGroups);
    if (file == null) {
      return;
    }

    await _editAnimationFrameAsset(
      label: l10n.imageGenerationInsertImageFrameHistory,
      beforeProject: project,
      edit: () => _animationProjectFrameEditor.insertFrameWithImage(
        store: _store,
        project: project,
        trackId: trackId,
        insertIndex: insertIndex,
        imagePath: file.path,
      ),
      successMessage: l10n.imageGenerationInsertedImageFrameMessage(
        insertIndex + 1,
        fileNameFromPath(file.path),
      ),
      errorPrefix: l10n.imageGenerationInsertImageFrameFailedPrefix,
    );
  }

  Future<void> _clearAnimationFrameAsset(String trackId, int frameIndex) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _editAnimationFrameAsset(
      label: l10n.imageGenerationClearAnimationFrameHistory,
      beforeProject: project,
      edit: () => _animationProjectFrameEditor.clearFrame(
        store: _store,
        project: project,
        trackId: trackId,
        frameIndex: frameIndex,
      ),
      successMessage: l10n.editorGifClearFrameMessage(frameIndex + 1),
      errorPrefix: l10n.imageGenerationClearAnimationFrameFailedPrefix,
    );
  }

  Future<void> _pixelateAnimationFrameAsset(
    String trackId,
    int frameIndex,
    int blockSize,
  ) async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    await _editAnimationFrameAsset(
      label: l10n.imageGenerationPixelateAnimationFrameHistory,
      beforeProject: project,
      edit: () => _animationProjectFrameEditor.pixelateFrame(
        store: _store,
        project: project,
        trackId: trackId,
        frameIndex: frameIndex,
        blockSize: blockSize,
      ),
      successMessage: l10n.imageGenerationPixelatedAnimationFrameMessage(
        frameIndex + 1,
        blockSize,
      ),
      errorPrefix: l10n.imageGenerationPixelateAnimationFrameFailedPrefix,
    );
  }

  Future<void> _editAnimationFrameAsset({
    required String label,
    required AnimationProject beforeProject,
    required Future<AnimationProjectEditResult?> Function() edit,
    required String successMessage,
    required String errorPrefix,
  }) async {
    final l10n = appL10nOf(context);
    setState(() {
      _isAnimationProjectBusy = true;
      _animationProjectErrorMessage = null;
    });
    try {
      final result = await edit();
      if (!mounted) {
        return;
      }
      if (result == null) {
        _showMessage(l10n.imageGenerationCurrentFrameNotEditableMessage);
        return;
      }
      await _applyAnimationProjectEdit(
        label: label,
        beforeProject: beforeProject,
        result: result,
      );
      _showMessage(successMessage);
    } catch (error) {
      if (mounted) {
        setState(
          () => _animationProjectErrorMessage = l10n
              .imageGenerationPrefixedErrorMessage(errorPrefix, error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnimationProjectBusy = false);
      }
    }
  }

  Future<void> _repairAnimationProjectConsistency() async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      return;
    }
    final result = const AnimationProjectEditor().repairConsistency(
      project: project,
    );
    if (result == null) {
      _showMessage(l10n.imageGenerationNoRepairableProjectIssuesMessage);
      return;
    }
    await _applyAnimationProjectEdit(
      label: l10n.imageGenerationRepairProjectConsistencyHistory,
      beforeProject: project,
      result: result,
    );
    _showMessage(l10n.imageGenerationRepairedProjectConsistencyMessage);
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
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      _showMessage(l10n.imageGenerationPleaseImportAnimationProjectMessage);
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
        labels: imageLibrarySpriteSheetLabels(
          l10n,
          title: l10n.imageLibraryAnimationProjectSpriteSheetTitle,
          source: l10n.imageLibraryAnimationProjectSpriteSheetSource,
          rows: output.rows ?? 1,
          columns:
              output.columns ?? _animationProjectCompositeFrameCount(project),
        ),
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
        label: l10n.imageGenerationExportAnimationProjectSpriteSheetHistory,
        appendedItems: [item],
      );
      _showMessage(
        l10n.imageGenerationExportedProjectSpriteSheetMessage(
          fileNameFromPath(output.path),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _animationProjectErrorMessage = l10n
              .imageGenerationExportFailedMessage(error),
        );
      }
    }
  }

  Future<void> _exportAnimationProjectGif() async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      _showMessage(l10n.imageGenerationPleaseImportAnimationProjectMessage);
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
        labels: imageLibraryGifLabels(
          l10n,
          title: l10n.imageLibraryAnimationProjectGifTitle,
          source: l10n.navAnimationProject,
          frameCount: frameCount,
        ),
      );
      if (!mounted) {
        return;
      }
      _imageLibrary = [item, ..._imageLibrary];
      _pushImageLibraryAppendHistory(
        feature: WorkspaceFeature.animationProject,
        label: l10n.imageGenerationExportAnimationProjectGifHistory,
        appendedItems: [item],
      );
      _showMessage(
        l10n.imageGenerationExportedProjectGifMessage(
          fileNameFromPath(output.path),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _animationProjectErrorMessage = l10n
              .imageGenerationExportProjectGifFailedMessage(error),
        );
      }
    }
  }

  Future<void> _exportAnimationTrackGif() async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    final trackId = _selectedAnimationTrackId;
    if (project == null || trackId == null) {
      _showMessage(l10n.imageGenerationPleaseSelectAnimationTrackMessage);
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
        labels: imageLibraryGifLabels(
          l10n,
          title: l10n.imageLibraryAnimationTrackGifTitle,
          source: l10n.navAnimationProject,
          frameCount: frameCount,
        ),
      );
      if (!mounted) {
        return;
      }
      _imageLibrary = [item, ..._imageLibrary];
      _pushImageLibraryAppendHistory(
        feature: WorkspaceFeature.animationProject,
        label: l10n.imageGenerationExportAnimationTrackGifHistory,
        appendedItems: [item],
      );
      _showMessage(
        l10n.imageGenerationExportedTrackGifMessage(
          fileNameFromPath(output.path),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _animationProjectErrorMessage = l10n
              .editorGifExportGifFailedMessage(error),
        );
      }
    }
  }

  Future<void> _exportAnimationProjectPngSequence() async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    if (project == null) {
      _showMessage(l10n.imageGenerationPleaseImportAnimationProjectMessage);
      return;
    }
    try {
      final files = await _animationProjectExportService
          .exportProjectPngSequence(store: _store, project: project);
      if (!mounted) {
        return;
      }
      _showMessage(
        l10n.imageGenerationExportedProjectPngSequenceMessage(files.length),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _animationProjectErrorMessage = l10n
              .imageGenerationExportProjectPngSequenceFailedMessage(error),
        );
      }
    }
  }

  Future<void> _exportAnimationTrackPngSequence() async {
    final l10n = appL10nOf(context);
    final project = _animationProject;
    final trackId = _selectedAnimationTrackId;
    if (project == null || trackId == null) {
      _showMessage(l10n.imageGenerationPleaseSelectAnimationTrackMessage);
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
      _showMessage(
        l10n.imageGenerationExportedTrackPngSequenceMessage(files.length),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _animationProjectErrorMessage = l10n
              .imageGenerationExportPngSequenceFailedMessage(error),
        );
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
      templateImagePath: _imageTemplateImagePath,
      advancedSettings: _advancedSettings,
      userController: _userController,
      onApiConfigChanged: _selectApiConfig,
      onOpenApiSettings: () =>
          unawaited(_selectFeature(WorkspaceFeature.apiSettings)),
      onSizeChanged: _setSize,
      onImageCountChanged: _setImageCount,
      onAdvancedSettingsChanged: _setAdvancedSettings,
      onPickTemplateImage: _pickImageTemplateImage,
      onClearTemplateImage: _clearImageTemplateImage,
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
      onImportLibraryImageSequence: () =>
          unawaited(_importLibraryImagesToAnimationProject()),
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
      onBlankFrameInserted: (trackId, insertIndex) =>
          unawaited(_insertBlankAnimationFrame(trackId, insertIndex)),
      onImageFrameInserted: (trackId, insertIndex) =>
          unawaited(_insertAnimationFrameFromImage(trackId, insertIndex)),
      onFrameDeleted: (trackId, frameIndex) =>
          unawaited(_deleteAnimationFrame(trackId, frameIndex)),
      onFrameDelayChanged: (trackId, frameIndex, delayMs) =>
          unawaited(_setAnimationFrameDelay(trackId, frameIndex, delayMs)),
      onFrameTransformChanged: (trackId, frameIndex, transform) => unawaited(
        _setAnimationFrameTransform(trackId, frameIndex, transform),
      ),
      onFrameReplaced: (trackId, frameIndex) =>
          unawaited(_replaceAnimationFrameAsset(trackId, frameIndex)),
      onFrameCleared: (trackId, frameIndex) =>
          unawaited(_clearAnimationFrameAsset(trackId, frameIndex)),
      onFramePixelated: (trackId, frameIndex, blockSize) => unawaited(
        _pixelateAnimationFrameAsset(trackId, frameIndex, blockSize),
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
    );
  }
}
