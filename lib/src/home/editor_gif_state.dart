// ignore_for_file: annotate_overrides

part of 'package:feather_canvas_studio/main.dart';

class _EditorConfigSnapshot {
  const _EditorConfigSnapshot({
    required this.rows,
    required this.columns,
    required this.gridSpec,
    required this.targetFrameIndex,
    required this.frameFit,
  });

  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;
  final int targetFrameIndex;
  final SpriteSheetFrameFit frameFit;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _EditorConfigSnapshot &&
            rows == other.rows &&
            columns == other.columns &&
            gridSpec == other.gridSpec &&
            targetFrameIndex == other.targetFrameIndex &&
            frameFit == other.frameFit;
  }

  @override
  int get hashCode =>
      Object.hash(rows, columns, gridSpec, targetFrameIndex, frameFit);
}

class _EditorSourceSnapshot {
  const _EditorSourceSnapshot({
    required this.sheetPath,
    required this.patchPath,
    required this.rows,
    required this.columns,
    required this.gridSpec,
    required this.targetFrameIndex,
    required this.frameFit,
    required this.errorMessage,
  });

  final String? sheetPath;
  final String? patchPath;
  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;
  final int targetFrameIndex;
  final SpriteSheetFrameFit frameFit;
  final String? errorMessage;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _EditorSourceSnapshot &&
            sheetPath == other.sheetPath &&
            patchPath == other.patchPath &&
            rows == other.rows &&
            columns == other.columns &&
            gridSpec == other.gridSpec &&
            targetFrameIndex == other.targetFrameIndex &&
            frameFit == other.frameFit &&
            errorMessage == other.errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    sheetPath,
    patchPath,
    rows,
    columns,
    gridSpec,
    targetFrameIndex,
    frameFit,
    errorMessage,
  );
}

const Duration _editorConfigHistoryMergeWindow = Duration(milliseconds: 800);
const String _editorGridConfigHistoryKey = 'editor-grid-config';
const String _editorFrameFitHistoryKey = 'editor-frame-fit';

mixin _EditorGifStateMixin
    on
        State<FeatherCanvasHomePage>,
        _ApiConfigStateMixin,
        _LocalSettingsStateMixin,
        _ImageLibraryStateMixin {
  @override
  AppLocalStore get _store;
  @override
  ImageLibraryFileService get _fileService;
  @override
  ImageLibraryService get _imageLibraryService;
  Set<String> get _ephemeralTemplatePaths;
  set _animationErrorMessage(String? value);
  ImageEditorNotifier get _imageEditorNotifier;
  // ignore: unused_element
  int get _editorRows => _imageEditorNotifier.editorRows;
  set _editorRows(int value) => _imageEditorNotifier.editorRows = value;
  // ignore: unused_element
  int get _editorColumns => _imageEditorNotifier.editorColumns;
  set _editorColumns(int value) => _imageEditorNotifier.editorColumns = value;
  // ignore: unused_element
  SpriteSheetGridSpec get _editorGridSpec =>
      _imageEditorNotifier.editorGridSpec;
  set _editorGridSpec(SpriteSheetGridSpec value) =>
      _imageEditorNotifier.editorGridSpec = value;
  // ignore: unused_element
  int get _editorTargetFrameIndex =>
      _imageEditorNotifier.editorTargetFrameIndex;
  set _editorTargetFrameIndex(int value) =>
      _imageEditorNotifier.editorTargetFrameIndex = value;
  // ignore: unused_element
  SpriteSheetFrameFit get _editorFrameFit =>
      _imageEditorNotifier.editorFrameFit;
  set _editorFrameFit(SpriteSheetFrameFit value) =>
      _imageEditorNotifier.editorFrameFit = value;
  int get _editorFrameCount;
  // ignore: unused_element
  String? get _editorImagePath => _imageEditorNotifier.editorImagePath;
  set _editorImagePath(String? value) =>
      _imageEditorNotifier.editorImagePath = value;
  // ignore: unused_element
  String? get _editorPatchImagePath =>
      _imageEditorNotifier.editorPatchImagePath;
  set _editorPatchImagePath(String? value) =>
      _imageEditorNotifier.editorPatchImagePath = value;
  // ignore: unused_element
  String? get _editorErrorMessage => _imageEditorNotifier.editorErrorMessage;
  set _editorErrorMessage(String? value) =>
      _imageEditorNotifier.editorErrorMessage = value;
  // ignore: unused_element
  bool get _isReplacingEditorFrame =>
      _imageEditorNotifier.isReplacingEditorFrame;
  set _isReplacingEditorFrame(bool value) =>
      _imageEditorNotifier.isReplacingEditorFrame = value;
  // ignore: unused_element
  String? get _generalEditorImagePath =>
      _imageEditorNotifier.generalEditorImagePath;
  set _generalEditorImagePath(String? value) =>
      _imageEditorNotifier.generalEditorImagePath = value;
  // ignore: unused_element
  ImageInspectionResult? get _generalEditorImageInfo =>
      _imageEditorNotifier.generalEditorImageInfo;
  set _generalEditorImageInfo(ImageInspectionResult? value) =>
      _imageEditorNotifier.generalEditorImageInfo = value;
  // ignore: unused_element
  String? get _generalEditorErrorMessage =>
      _imageEditorNotifier.generalEditorErrorMessage;
  set _generalEditorErrorMessage(String? value) =>
      _imageEditorNotifier.generalEditorErrorMessage = value;
  // ignore: unused_element
  bool get _isProcessingGeneralImage =>
      _imageEditorNotifier.isProcessingGeneralImage;
  set _isProcessingGeneralImage(bool value) =>
      _imageEditorNotifier.isProcessingGeneralImage = value;
  bool get _isImageEditorFocusMode;
  set _isImageEditorFocusMode(bool value);
  int _gifDefaultFrameDelayMs = defaultGifFrameDelayMs;
  int _gifLoopCount = defaultGifLoopCount;
  GifPlaybackMode _gifPlaybackMode = defaultGifPlaybackMode;
  WorkspaceFeature get _selectedFeature;
  set _selectedFeature(WorkspaceFeature value);
  @override
  void _showMessage(String message);
  Widget _buildCompactHistoryControls();
  void _pushHistory(WorkspaceFeature feature, HistoryAction action);
  bool _replaceTopHistory(
    WorkspaceFeature feature, {
    required HistoryAction current,
    required HistoryAction replacement,
  });

  HistoryAction? _lastEditorConfigHistoryAction;
  String? _lastEditorConfigHistoryKey;
  DateTime? _lastEditorConfigHistoryAt;
  _EditorConfigSnapshot? _lastEditorConfigHistoryBefore;

  void _setEditorRows(int value) {
    final before = _captureEditorConfig();
    final l10n = appL10nOf(context);
    setState(() {
      _editorRows = value;
      _editorGridSpec = _editorGridSpec.copyWith(rows: value);
      _normalizeEditorTargetFrameIndex();
    });
    _pushEditorConfigHistory(
      label: l10n.editorGifAdjustRowsHistory(value),
      before: before,
      mergeKey: _editorGridConfigHistoryKey,
    );
  }

  void _setEditorColumns(int value) {
    final before = _captureEditorConfig();
    final l10n = appL10nOf(context);
    setState(() {
      _editorColumns = value;
      _editorGridSpec = _editorGridSpec.copyWith(columns: value);
      _normalizeEditorTargetFrameIndex();
    });
    _pushEditorConfigHistory(
      label: l10n.editorGifAdjustColumnsHistory(value),
      before: before,
      mergeKey: _editorGridConfigHistoryKey,
    );
  }

  void _setEditorGridSpec(SpriteSheetGridSpec value) {
    final before = _captureEditorConfig();
    final l10n = appL10nOf(context);
    setState(() {
      _editorRows = value.rows;
      _editorColumns = value.columns;
      _editorGridSpec = value;
      _normalizeEditorTargetFrameIndex();
    });
    _pushEditorConfigHistory(
      label: l10n.editorGifAdjustGridSpecHistory,
      before: before,
      mergeKey: _editorGridConfigHistoryKey,
    );
  }

  void _setEditorTargetFrameIndex(int value) {
    setState(() {
      _editorTargetFrameIndex = value.clamp(0, _editorFrameCount - 1);
    });
  }

  void _setEditorFrameFit(SpriteSheetFrameFit value) {
    final before = _captureEditorConfig();
    final l10n = appL10nOf(context);
    if (before.frameFit == value) {
      return;
    }
    _editorFrameFit = value;
    _pushEditorConfigHistory(
      label: l10n.editorGifAdjustFrameFitHistory(switch (value) {
        SpriteSheetFrameFit.contain => l10n.spriteSheetEditorFrameFitContain,
        SpriteSheetFrameFit.cover => l10n.spriteSheetEditorFrameFitCover,
        SpriteSheetFrameFit.stretch => l10n.spriteSheetEditorFrameFitStretch,
      }),
      before: before,
      mergeKey: _editorFrameFitHistoryKey,
    );
  }

  _EditorConfigSnapshot _captureEditorConfig() {
    return _EditorConfigSnapshot(
      rows: _editorRows,
      columns: _editorColumns,
      gridSpec: _editorGridSpec,
      targetFrameIndex: _editorTargetFrameIndex,
      frameFit: _editorFrameFit,
    );
  }

  void _restoreEditorConfig(_EditorConfigSnapshot snapshot) {
    if (!mounted) {
      return;
    }

    setState(() {
      _editorRows = snapshot.rows;
      _editorColumns = snapshot.columns;
      _editorGridSpec = snapshot.gridSpec;
      _editorTargetFrameIndex = snapshot.targetFrameIndex;
      _editorFrameFit = snapshot.frameFit;
      _normalizeEditorTargetFrameIndex();
    });
  }

  void _pushEditorConfigHistory({
    required String label,
    required _EditorConfigSnapshot before,
    required String mergeKey,
  }) {
    final after = _captureEditorConfig();
    if (before == after) {
      return;
    }

    final now = DateTime.now();
    final previousAction = _lastEditorConfigHistoryAction;
    final previousAt = _lastEditorConfigHistoryAt;
    final shouldMerge =
        previousAction != null &&
        previousAt != null &&
        _lastEditorConfigHistoryKey == mergeKey &&
        now.difference(previousAt) <= _editorConfigHistoryMergeWindow;

    if (shouldMerge) {
      final mergedBefore = _lastEditorConfigHistoryBefore ?? before;
      final replacement = _editorConfigHistoryAction(
        label: label,
        before: mergedBefore,
        after: after,
      );
      final replaced = _replaceTopHistory(
        WorkspaceFeature.imageEditor,
        current: previousAction,
        replacement: replacement,
      );
      if (replaced) {
        _rememberEditorConfigHistory(
          action: replacement,
          mergeKey: mergeKey,
          before: mergedBefore,
          now: now,
        );
        return;
      }
    }

    final action = _editorConfigHistoryAction(
      label: label,
      before: before,
      after: after,
    );
    _pushHistory(WorkspaceFeature.imageEditor, action);
    _rememberEditorConfigHistory(
      action: action,
      mergeKey: mergeKey,
      before: before,
      now: now,
    );
  }

  HistoryAction _editorConfigHistoryAction({
    required String label,
    required _EditorConfigSnapshot before,
    required _EditorConfigSnapshot after,
  }) {
    return HistoryAction(
      label: label,
      apply: () => _restoreEditorConfig(after),
      revert: () => _restoreEditorConfig(before),
    );
  }

  void _rememberEditorConfigHistory({
    required HistoryAction action,
    required String mergeKey,
    required _EditorConfigSnapshot before,
    required DateTime now,
  }) {
    _lastEditorConfigHistoryAction = action;
    _lastEditorConfigHistoryKey = mergeKey;
    _lastEditorConfigHistoryBefore = before;
    _lastEditorConfigHistoryAt = now;
  }

  _EditorSourceSnapshot _captureEditorSource() {
    return _EditorSourceSnapshot(
      sheetPath: _editorImagePath,
      patchPath: _editorPatchImagePath,
      rows: _editorRows,
      columns: _editorColumns,
      gridSpec: _editorGridSpec,
      targetFrameIndex: _editorTargetFrameIndex,
      frameFit: _editorFrameFit,
      errorMessage: _editorErrorMessage,
    );
  }

  void _restoreEditorSource(_EditorSourceSnapshot snapshot) {
    if (!mounted) {
      return;
    }

    setState(() {
      _editorImagePath = snapshot.sheetPath;
      _editorPatchImagePath = snapshot.patchPath;
      _editorRows = snapshot.rows;
      _editorColumns = snapshot.columns;
      _editorGridSpec = snapshot.gridSpec;
      _editorTargetFrameIndex = snapshot.targetFrameIndex;
      _editorFrameFit = snapshot.frameFit;
      _editorErrorMessage = snapshot.errorMessage;
      _normalizeEditorTargetFrameIndex();
    });
  }

  void _pushEditorSourceHistory({
    required String label,
    required _EditorSourceSnapshot before,
  }) {
    final after = _captureEditorSource();
    if (before == after) {
      return;
    }

    _pushHistory(
      WorkspaceFeature.imageEditor,
      HistoryAction(
        label: label,
        apply: () => _restoreEditorSource(after),
        revert: () => _restoreEditorSource(before),
      ),
    );
  }

  void _normalizeEditorTargetFrameIndex() {
    _editorTargetFrameIndex = _editorTargetFrameIndex.clamp(
      0,
      _editorFrameCount - 1,
    );
  }

  Future<String?> _pickSingleImagePathFromSource({
    required String title,
    List<XTypeGroup> acceptedTypeGroups = imageTypeGroups,
    String? libraryEmptyMessage,
    List<ImageAssetKind>? allowedLibraryKinds,
  }) async {
    final availableLibraryItems = _availableImageLibraryItems(
      allowedKinds: allowedLibraryKinds,
    );
    final source = await _selectImagePickSource(
      title: title,
      allowLibrary: availableLibraryItems.isNotEmpty,
      libraryEmptyMessage: libraryEmptyMessage,
    );
    if (source == null) {
      return null;
    }

    if (source == ImagePickSource.localFile) {
      final image = await openFile(acceptedTypeGroups: acceptedTypeGroups);
      return image?.path;
    }

    final item = await _showImageLibraryPicker<ImageLibraryItem>(
      title: title,
      allowedKinds: allowedLibraryKinds,
    );
    return item?.path;
  }

  Future<ImagePickSource?> _selectImagePickSource({
    required String title,
    required bool allowLibrary,
    String? libraryEmptyMessage,
  }) {
    if (!mounted) {
      return Future.value();
    }

    return showImagePickSourceDialog(
      context,
      title: title,
      allowLibrary: allowLibrary,
      libraryEmptyMessage: libraryEmptyMessage,
    );
  }

  Future<void> _pickEditorImage() async {
    final l10n = appL10nOf(context);
    final imagePath = await _pickSingleImagePathFromSource(
      title: l10n.editorGifSelectSpriteSheetTitle,
      libraryEmptyMessage: l10n.editorGifSpriteSheetLibraryEmpty,
      allowedLibraryKinds: spriteSheetLibraryKinds,
    );

    if (imagePath == null || !mounted) {
      return;
    }

    final before = _captureEditorSource();
    setState(() {
      _editorImagePath = imagePath;
      _editorErrorMessage = null;
    });
    _pushEditorSourceHistory(
      label: l10n.editorGifLoadSpriteSheetHistory,
      before: before,
    );
    _showMessage(l10n.editorGifLoadedImageMessage(fileNameFromPath(imagePath)));
  }

  void _clearEditorImage() {
    final l10n = appL10nOf(context);
    final before = _captureEditorSource();
    if (before.sheetPath == null && before.errorMessage == null) {
      return;
    }

    setState(() {
      _editorImagePath = null;
      _editorErrorMessage = null;
    });
    _pushEditorSourceHistory(
      label: l10n.editorGifClearSpriteSheetHistory,
      before: before,
    );
  }

  Future<void> _pickEditorPatchImage() async {
    final l10n = appL10nOf(context);
    final imagePath = await _pickSingleImagePathFromSource(
      title: l10n.editorGifSelectSingleFrameTitle,
      libraryEmptyMessage: l10n.editorGifSingleFrameLibraryEmpty,
      allowedLibraryKinds: singleFrameLibraryKinds,
    );

    if (imagePath == null || !mounted) {
      return;
    }

    final before = _captureEditorSource();
    setState(() {
      _editorPatchImagePath = imagePath;
      _editorErrorMessage = null;
    });
    _pushEditorSourceHistory(
      label: l10n.editorGifSelectSingleFrameHistory,
      before: before,
    );
    _showMessage(
      l10n.editorGifLoadedSingleFrameMessage(fileNameFromPath(imagePath)),
    );
  }

  void _clearEditorPatchImage() {
    final l10n = appL10nOf(context);
    final before = _captureEditorSource();
    if (before.patchPath == null && before.errorMessage == null) {
      return;
    }

    setState(() {
      _editorPatchImagePath = null;
      _editorErrorMessage = null;
    });
    _pushEditorSourceHistory(
      label: l10n.editorGifClearSingleFrameHistory,
      before: before,
    );
  }

  Future<void> _makeEditorPatchBackgroundTransparent(int tolerance) async {
    final l10n = appL10nOf(context);
    final patchPath = _editorPatchImagePath;
    if (patchPath == null) {
      _showMessage(l10n.editorGifPleaseSelectSingleFrame);
      return;
    }

    setState(() {
      _isReplacingEditorFrame = true;
      _editorErrorMessage = null;
    });

    try {
      final sourceBytes = await _fileService.readFileBytes(patchPath);
      final result = BackgroundTransparencyService.makeBackgroundTransparent(
        sourceBytes,
        tolerance: tolerance,
      );
      if (!mounted) {
        return;
      }
      if (result.transparentPixelCount == 0) {
        _showMessage(l10n.editorGifNoTransparentEdgeMessage);
        return;
      }

      final file = await _store.saveGeneratedImageBytes(
        groupId: 'transparent_${DateTime.now().microsecondsSinceEpoch}',
        index: 0,
        bytes: result.pngBytes,
      );
      if (!mounted) {
        return;
      }

      final item = await _imageLibraryService.addItem(
        store: _store,
        path: file.path,
        kind: ImageAssetKind.generatedImage,
        title: l10n.editorGifTransparentBackgroundTitle,
        source: l10n.editorGifImageEditorSource,
        prompt: l10n.editorGifTransparentBackgroundPrompt(
          tolerance,
          result.width,
          result.height,
        ),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _editorPatchImagePath = file.path;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _pushEditorPatchImageHistory(
        label: l10n.editorGifTransparentBackgroundHistory,
        beforePatchPath: patchPath,
        afterPatchPath: file.path,
        appendedItem: item,
      );
      _showMessage(
        l10n.editorGifTransparentBackgroundSavedMessage(
          fileNameFromPath(file.path),
          result.transparentPixelCount,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = l10n.editorGifTransparentBackgroundFailedMessage(
        error,
      );
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _adjustEditorPatchFraming() async {
    final l10n = appL10nOf(context);
    final sheetPath = _editorImagePath;
    final patchPath = _editorPatchImagePath;
    if (sheetPath == null) {
      _showMessage(l10n.editorGifPleaseSelectSpriteSheet);
      return;
    }
    if (patchPath == null) {
      _showMessage(l10n.editorGifPleaseSelectSingleFrame);
      return;
    }

    try {
      final sheetBytes = await _fileService.readFileBytes(sheetPath);
      final previewData = SpriteSheetPreviewComposer.buildFromSheetBytes(
        sheetBytes,
        rows: _editorRows,
        columns: _editorColumns,
        gridSpec: _editorGridSpec,
      );
      if (!mounted) {
        return;
      }

      final patchBytes = await _fileService.readFileBytes(patchPath);
      if (!mounted) {
        return;
      }

      final framing = await showPatchImageFramingDialog(
        context,
        imageBytes: patchBytes,
        targetWidth: previewData.frameWidth,
        targetHeight: previewData.frameHeight,
        sourceTitle: fileNameFromPath(patchPath),
      );
      if (framing == null || !mounted) {
        return;
      }

      setState(() {
        _isReplacingEditorFrame = true;
        _editorErrorMessage = null;
      });

      final framedBytes = PatchImageFramingService.render(
        imageBytes: patchBytes,
        targetWidth: previewData.frameWidth,
        targetHeight: previewData.frameHeight,
        framing: framing,
      );
      final file = await _store.saveGeneratedImageBytes(
        groupId: 'framed_patch_${DateTime.now().microsecondsSinceEpoch}',
        index: 0,
        bytes: framedBytes,
      );
      if (!mounted) {
        return;
      }

      final item = await _imageLibraryService.addItem(
        store: _store,
        path: file.path,
        kind: ImageAssetKind.generatedImage,
        title: l10n.editorGifFramedSingleFrameTitle,
        source: l10n.editorGifImageEditorSource,
        prompt: l10n.editorGifFramedSingleFramePrompt(
          previewData.frameWidth,
          previewData.frameHeight,
        ),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _editorPatchImagePath = file.path;
        _editorFrameFit = SpriteSheetFrameFit.stretch;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _pushEditorPatchImageHistory(
        label: l10n.editorGifAdjustFramingHistory,
        beforePatchPath: patchPath,
        afterPatchPath: file.path,
        appendedItem: item,
      );
      _showMessage(
        l10n.editorGifFramedSingleFrameSavedMessage(
          fileNameFromPath(file.path),
          previewData.frameWidth,
          previewData.frameHeight,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = l10n.editorGifAdjustFramingFailedMessage(error);
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _pickAnimationTemplateImage() async {
    final l10n = appL10nOf(context);
    final candidates = _availableImageLibraryItems(
      allowedKinds: templateLibraryKinds,
    );
    final source = await _selectImagePickSource(
      title: l10n.editorGifSelectTemplateTitle,
      allowLibrary: candidates.isNotEmpty,
      libraryEmptyMessage: l10n.editorGifTemplateLibraryEmpty,
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
        title: l10n.editorGifSelectTemplateTitle,
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
          prefix: 'template',
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

    final previous = _animationTemplateImagePath;
    setState(() {
      _animationTemplateImagePath = imagePath;
      _animationErrorMessage = null;
    });
    if (previous != null &&
        previous != imagePath &&
        _ephemeralTemplatePaths.remove(previous)) {
      unawaited(_fileService.safeDeleteFile(previous));
    }
    _showMessage(
      sliceLabel != null
          ? l10n.editorGifSelectedTemplateSliceMessage(sliceLabel)
          : l10n.editorGifSelectedTemplateImageMessage(
              fileNameFromPath(imagePath),
            ),
    );
  }

  void _clearAnimationTemplateImage() {
    final previous = _animationTemplateImagePath;
    setState(() => _animationTemplateImagePath = null);
    if (previous != null && _ephemeralTemplatePaths.remove(previous)) {
      unawaited(_fileService.safeDeleteFile(previous));
    }
  }

  Future<void> _sendPreviewDataToGif(SpriteSheetPreviewData previewData) async {
    final l10n = appL10nOf(context);
    if (previewData.frames.length < 2) {
      _showMessage(l10n.editorGifNeedAtLeastTwoFrames);
      return;
    }

    try {
      final importResult = await const AnimationProjectImporter()
          .importSpriteSheet(
            store: _store,
            sheetBytes: previewData.sheetBytes,
            title: l10n.editorGifQuickGifProjectTitle,
            rows: previewData.rows,
            columns: previewData.columns,
            defaultDelayMs: _gifDefaultFrameDelayMs,
            gridSpec: previewData.gridSpec,
          );
      final project = importResult.project.copyWith(
        exportSettings: importResult.project.exportSettings.copyWith(
          loopCount: _gifLoopCount,
        ),
        timeline: importResult.project.timeline.copyWith(
          playbackMode: _animationPlaybackMode(_gifPlaybackMode),
        ),
      );
      final output = await const AnimationProjectExportService()
          .exportProjectGif(store: _store, project: project);
      if (!mounted) {
        return;
      }
      final item = await _imageLibraryService.addGif(
        store: _store,
        path: output.path,
        labels: imageLibraryGifLabels(
          l10n,
          title: l10n.imageLibrarySpriteSheetGifTitle,
          source: l10n.editorGifImageEditorSource,
          frameCount: previewData.frames.length,
        ),
      );
      if (!mounted) {
        return;
      }
      _imageLibrary = [item, ..._imageLibrary];
      _pushImageLibraryAppendHistory(
        feature: _selectedFeature,
        label: l10n.editorGifExportSpriteSheetGifHistory,
        appendedItems: [item],
      );
      _showMessage(
        l10n.editorGifExportGifSavedMessage(
          fileNameFromPath(output.path),
          output.directoryPath,
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(l10n.editorGifExportGifFailedMessage(error));
      }
    }
  }

  Future<void> _exportSpriteSheet({
    required Uint8List pngBytes,
    required int rows,
    required int columns,
    required SpriteSheetGridSpec gridSpec,
  }) async {
    final l10n = appL10nOf(context);
    final output = await SpriteSheetFileService.exportPng(
      store: _store,
      pngBytes: pngBytes,
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
    );
    if (!mounted) {
      return;
    }
    final item = await _imageLibraryService.addExportedSpriteSheet(
      store: _store,
      path: output.path,
      rows: rows,
      columns: columns,
      labels: imageLibrarySpriteSheetLabels(
        l10n,
        title: l10n.imageLibraryExportedSpriteSheetTitle,
        source: l10n.imageLibraryExportedSpriteSheetSource,
        rows: rows,
        columns: columns,
      ),
      gridSpec: gridSpec,
    );
    if (!mounted) {
      return;
    }
    _imageLibrary = [item, ..._imageLibrary];
    _pushImageLibraryAppendHistory(
      feature: _selectedFeature,
      label: l10n.editorGifExportSpriteSheetHistory,
      appendedItems: [item],
    );
    _showMessage(
      l10n.editorGifExportSpriteSheetSavedMessage(
        fileNameFromPath(output.path),
        output.directoryPath,
      ),
    );
  }

  void _pushEditorFrameHistory({
    required String label,
    required String? beforeSheetPath,
    required String afterSheetPath,
    required ImageLibraryItem appendedItem,
  }) {
    _pushImageLibraryAppendHistory(
      feature: WorkspaceFeature.imageEditor,
      label: label,
      appendedItems: [appendedItem],
      applyState: () => _editorImagePath = afterSheetPath,
      revertState: () => _editorImagePath = beforeSheetPath,
    );
  }

  void _pushEditorPatchImageHistory({
    required String label,
    required String? beforePatchPath,
    required String afterPatchPath,
    required ImageLibraryItem appendedItem,
  }) {
    _pushImageLibraryAppendHistory(
      feature: WorkspaceFeature.imageEditor,
      label: label,
      appendedItems: [appendedItem],
      applyState: () => _editorPatchImagePath = afterPatchPath,
      revertState: () => _editorPatchImagePath = beforePatchPath,
    );
  }

  Future<void> _replaceEditorFrame() async {
    final l10n = appL10nOf(context);
    final sheetPath = _editorImagePath;
    final patchPath = _editorPatchImagePath;
    final rows = _editorRows;
    final columns = _editorColumns;
    final gridSpec = _editorGridSpec;
    final frameIndex = _editorTargetFrameIndex
        .clamp(0, _editorFrameCount - 1)
        .toInt();
    final frameFit = _editorFrameFit;
    if (sheetPath == null) {
      _showMessage(l10n.editorGifPleaseSelectSpriteSheet);
      return;
    }
    if (patchPath == null) {
      _showMessage(l10n.editorGifPleaseSelectPatchForInsert);
      return;
    }

    setState(() {
      _isReplacingEditorFrame = true;
      _editorErrorMessage = null;
    });

    try {
      final sheetBytes = await _fileService.readFileBytes(sheetPath);
      final patchBytes = await _fileService.readFileBytes(patchPath);
      final preview = SpriteSheetEditorComposer.buildReplacementPreview(
        sheetBytes: sheetBytes,
        patchBytes: patchBytes,
        rows: rows,
        columns: columns,
        frameIndex: frameIndex,
        fit: frameFit,
        gridSpec: gridSpec,
      );
      if (!mounted) {
        return;
      }
      _isReplacingEditorFrame = false;

      final confirmed = await confirmSpriteSheetFrameReplacementDialog(
        context,
        preview: preview,
        columns: columns,
        fitLabel: localizedSpriteSheetFrameFitLabel(l10n, frameFit),
      );
      if (!confirmed || !mounted) {
        return;
      }

      _isReplacingEditorFrame = true;
      final output = await SpriteSheetFileService.exportPng(
        store: _store,
        pngBytes: preview.editedSheetBytes,
        rows: rows,
        columns: columns,
        gridSpec: gridSpec,
      );

      final item = await _imageLibraryService.addEditedSpriteSheet(
        store: _store,
        path: output.path,
        frameIndex: frameIndex,
        rows: rows,
        columns: columns,
        labels: imageLibraryEditedSpriteSheetLabels(
          l10n,
          frameIndex: frameIndex + 1,
          rows: rows,
          columns: columns,
        ),
        gridSpec: gridSpec,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _editorImagePath = output.path;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _pushEditorFrameHistory(
        label: l10n.editorGifReplaceFrameHistory(frameIndex + 1),
        beforeSheetPath: sheetPath,
        afterSheetPath: output.path,
        appendedItem: item,
      );
      _showMessage(
        l10n.editorGifReplaceFrameSavedMessage(
          frameIndex + 1,
          fileNameFromPath(output.path),
          output.directoryPath,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _editorErrorMessage = l10n.editorGifReplaceFrameFailedMessage(error);
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _copyPreviousEditorFrame() async {
    final l10n = appL10nOf(context);
    final sheetPath = _editorImagePath;
    if (sheetPath == null) {
      _showMessage(l10n.editorGifPleaseSelectSpriteSheet);
      return;
    }
    if (_editorTargetFrameIndex <= 0) {
      _showMessage(l10n.editorGifFirstFrameNoPrevious);
      return;
    }

    setState(() {
      _isReplacingEditorFrame = true;
      _editorErrorMessage = null;
    });

    try {
      final output = await SpriteSheetFileService.copyFrameAndSave(
        store: _store,
        readFileBytes: _fileService.readFileBytes,
        sheetPath: sheetPath,
        rows: _editorRows,
        columns: _editorColumns,
        sourceFrameIndex: _editorTargetFrameIndex - 1,
        targetFrameIndex: _editorTargetFrameIndex,
        gridSpec: _editorGridSpec,
      );
      if (!mounted) {
        return;
      }

      final item = await _imageLibraryService.addEditedSpriteSheet(
        store: _store,
        path: output.path,
        frameIndex: _editorTargetFrameIndex,
        rows: _editorRows,
        columns: _editorColumns,
        labels: imageLibraryEditedSpriteSheetLabels(
          l10n,
          frameIndex: _editorTargetFrameIndex + 1,
          rows: _editorRows,
          columns: _editorColumns,
        ),
        gridSpec: _editorGridSpec,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _editorImagePath = output.path;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _pushEditorFrameHistory(
        label: l10n.editorGifCopyPreviousFrameHistory(
          _editorTargetFrameIndex + 1,
        ),
        beforeSheetPath: sheetPath,
        afterSheetPath: output.path,
        appendedItem: item,
      );
      _showMessage(
        l10n.editorGifCopyPreviousFrameMessage(_editorTargetFrameIndex + 1),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = l10n.editorGifCopyFrameFailedMessage(error);
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _clearEditorTargetFrame() async {
    final l10n = appL10nOf(context);
    final sheetPath = _editorImagePath;
    if (sheetPath == null) {
      _showMessage(l10n.editorGifPleaseSelectSpriteSheet);
      return;
    }

    setState(() {
      _isReplacingEditorFrame = true;
      _editorErrorMessage = null;
    });

    try {
      final output = await SpriteSheetFileService.clearFrameAndSave(
        store: _store,
        readFileBytes: _fileService.readFileBytes,
        sheetPath: sheetPath,
        rows: _editorRows,
        columns: _editorColumns,
        frameIndex: _editorTargetFrameIndex,
        gridSpec: _editorGridSpec,
      );
      if (!mounted) {
        return;
      }

      final item = await _imageLibraryService.addEditedSpriteSheet(
        store: _store,
        path: output.path,
        frameIndex: _editorTargetFrameIndex,
        rows: _editorRows,
        columns: _editorColumns,
        labels: imageLibraryEditedSpriteSheetLabels(
          l10n,
          frameIndex: _editorTargetFrameIndex + 1,
          rows: _editorRows,
          columns: _editorColumns,
        ),
        gridSpec: _editorGridSpec,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _editorImagePath = output.path;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _pushEditorFrameHistory(
        label: l10n.editorGifClearFrameHistory(_editorTargetFrameIndex + 1),
        beforeSheetPath: sheetPath,
        afterSheetPath: output.path,
        appendedItem: item,
      );
      _showMessage(
        l10n.editorGifClearFrameMessage(_editorTargetFrameIndex + 1),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = l10n.editorGifClearFrameFailedMessage(error);
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _pixelateEditorTargetFrame(int blockSize) async {
    final l10n = appL10nOf(context);
    final sheetPath = _editorImagePath;
    if (sheetPath == null) {
      _showMessage(l10n.editorGifPleaseSelectSpriteSheet);
      return;
    }

    final frameIndex = _editorTargetFrameIndex
        .clamp(0, _editorFrameCount - 1)
        .toInt();
    final safeBlockSize = PixelationService.normalizeBlockSize(blockSize);
    setState(() {
      _isReplacingEditorFrame = true;
      _editorErrorMessage = null;
    });

    try {
      final output = await SpriteSheetFileService.pixelateFrameAndSave(
        store: _store,
        readFileBytes: _fileService.readFileBytes,
        sheetPath: sheetPath,
        rows: _editorRows,
        columns: _editorColumns,
        frameIndex: frameIndex,
        blockSize: safeBlockSize,
        gridSpec: _editorGridSpec,
      );
      if (!mounted) {
        return;
      }

      final item = await _imageLibraryService.addItem(
        store: _store,
        path: output.path,
        kind: ImageAssetKind.editedImage,
        title: l10n.editorGifPixelatedSpriteSheetTitle,
        source: l10n.editorGifImageEditorSource,
        prompt: l10n.editorGifPixelatedFramePrompt(
          frameIndex + 1,
          safeBlockSize,
          _editorRows,
          _editorColumns,
        ),
        rows: _editorRows,
        columns: _editorColumns,
        gridSpec: _editorGridSpec,
        frameIndex: frameIndex,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _editorImagePath = output.path;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _pushEditorFrameHistory(
        label: l10n.editorGifPixelateFrameHistory(frameIndex + 1),
        beforeSheetPath: sheetPath,
        afterSheetPath: output.path,
        appendedItem: item,
      );
      _showMessage(
        l10n.editorGifPixelateFrameSavedMessage(
          frameIndex + 1,
          fileNameFromPath(output.path),
          safeBlockSize,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = l10n.editorGifPixelateCurrentFrameFailedMessage(
        error,
      );
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _pixelateEditorSpriteSheet(int blockSize) async {
    final l10n = appL10nOf(context);
    final sheetPath = _editorImagePath;
    if (sheetPath == null) {
      _showMessage(l10n.editorGifPleaseSelectSpriteSheet);
      return;
    }

    final safeBlockSize = PixelationService.normalizeBlockSize(blockSize);
    setState(() {
      _isReplacingEditorFrame = true;
      _editorErrorMessage = null;
    });

    try {
      final output = await SpriteSheetFileService.pixelateSheetAndSave(
        store: _store,
        readFileBytes: _fileService.readFileBytes,
        sheetPath: sheetPath,
        rows: _editorRows,
        columns: _editorColumns,
        blockSize: safeBlockSize,
        gridSpec: _editorGridSpec,
      );
      if (!mounted) {
        return;
      }

      final item = await _imageLibraryService.addItem(
        store: _store,
        path: output.path,
        kind: ImageAssetKind.editedImage,
        title: l10n.editorGifPixelatedSpriteSheetTitle,
        source: l10n.editorGifImageEditorSource,
        prompt: l10n.editorGifPixelatedWholeSheetPrompt(
          safeBlockSize,
          _editorRows,
          _editorColumns,
        ),
        rows: _editorRows,
        columns: _editorColumns,
        gridSpec: _editorGridSpec,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _editorImagePath = output.path;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _pushEditorFrameHistory(
        label: l10n.editorGifPixelateWholeSheetHistory,
        beforeSheetPath: sheetPath,
        afterSheetPath: output.path,
        appendedItem: item,
      );
      _showMessage(
        l10n.editorGifPixelateWholeSheetSavedMessage(
          fileNameFromPath(output.path),
          safeBlockSize,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = l10n.editorGifPixelateWholeSheetFailedMessage(
        error,
      );
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _pickGeneralEditorImage() async {
    final l10n = appL10nOf(context);
    final imagePath = await _pickSingleImagePathFromSource(
      title: l10n.editorGifSelectImageToEditTitle,
      libraryEmptyMessage: l10n.editorGifGeneralImageLibraryEmpty,
      allowedLibraryKinds: templateLibraryKinds,
    );

    if (imagePath == null || !mounted) {
      return;
    }

    await _loadGeneralEditorImage(imagePath);
  }

  Future<void> _loadGeneralEditorImage(String imagePath) async {
    final l10n = appL10nOf(context);
    setState(() {
      _isProcessingGeneralImage = true;
      _generalEditorErrorMessage = null;
    });

    try {
      final bytes = await _fileService.readFileBytes(imagePath);
      final info = await GeneralImageEditingService.inspectInBackground(bytes);
      if (!mounted) {
        return;
      }
      setState(() {
        _generalEditorImagePath = imagePath;
        _generalEditorImageInfo = info;
      });
      _showMessage(
        l10n.editorGifGeneralImageLoadedMessage(fileNameFromPath(imagePath)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _generalEditorErrorMessage = l10n.editorGifImageReadFailedMessage(error);
    } finally {
      if (mounted) {
        _isProcessingGeneralImage = false;
      }
    }
  }

  void _clearGeneralEditorImage() {
    if (_generalEditorImagePath == null &&
        _generalEditorImageInfo == null &&
        _generalEditorErrorMessage == null) {
      return;
    }

    setState(() {
      _generalEditorImagePath = null;
      _generalEditorImageInfo = null;
      _generalEditorErrorMessage = null;
    });
  }

  Future<void> _applyGeneralImageEdit(GeneralImageEditOptions options) async {
    final l10n = appL10nOf(context);
    final imagePath = _generalEditorImagePath;
    final beforeInfo = _generalEditorImageInfo;
    if (imagePath == null) {
      _showMessage(l10n.editorGifPleaseSelectImage);
      return;
    }

    setState(() {
      _isProcessingGeneralImage = true;
      _generalEditorErrorMessage = null;
    });

    try {
      final bytes = await _fileService.readFileBytes(imagePath);
      final result = await GeneralImageEditingService.editInBackground(
        bytes,
        options: options,
        labels: generalImageEditSummaryLabels(l10n),
      );
      final groupId = 'edited_${DateTime.now().microsecondsSinceEpoch}';
      final file = await _store.saveGeneratedImageBytes(
        groupId: groupId,
        index: 0,
        bytes: result.bytes,
        extension: result.fileExtension,
      );
      final outputInfo = await GeneralImageEditingService.inspectInBackground(
        result.bytes,
      );
      if (!mounted) {
        return;
      }

      final item = await _imageLibraryService.addItem(
        store: _store,
        path: file.path,
        kind: ImageAssetKind.editedImage,
        title: l10n.editorGifEditedImageTitle,
        source: l10n.editorGifImageEditorSource,
        prompt:
            '${result.summary} · ${result.width} x ${result.height} · ${result.mimeType}',
        groupId: groupId,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _generalEditorImagePath = file.path;
        _generalEditorImageInfo = outputInfo;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _pushImageLibraryAppendHistory(
        feature: WorkspaceFeature.imageEditor,
        label: l10n.editorGifEditImageHistory,
        appendedItems: [item],
        applyState: () {
          _generalEditorImagePath = file.path;
          _generalEditorImageInfo = outputInfo;
          _generalEditorErrorMessage = null;
        },
        revertState: () {
          _generalEditorImagePath = imagePath;
          _generalEditorImageInfo = beforeInfo;
          _generalEditorErrorMessage = null;
        },
      );
      _showMessage(
        l10n.editorGifEditImageSavedMessage(
          fileNameFromPath(file.path),
          result.summary,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _generalEditorErrorMessage = l10n.editorGifEditImageFailedMessage(error);
    } finally {
      if (mounted) {
        _isProcessingGeneralImage = false;
      }
    }
  }

  Widget _buildImageEditorWorkspace() {
    return ImageEditorWorkspace(
      onPickGeneralImage: () => unawaited(_pickGeneralEditorImage()),
      onClearGeneralImage: _clearGeneralEditorImage,
      onApplyGeneralImageEdit: _applyGeneralImageEdit,
      isFocusMode: _isImageEditorFocusMode,
      historyControls: _buildCompactHistoryControls(),
      onPickImage: _pickEditorImage,
      onClearImage: _clearEditorImage,
      onPickPatchImage: _pickEditorPatchImage,
      onClearPatchImage: _clearEditorPatchImage,
      onAdjustPatchFraming: () => unawaited(_adjustEditorPatchFraming()),
      onMakePatchBackgroundTransparent: (tolerance) =>
          unawaited(_makeEditorPatchBackgroundTransparent(tolerance)),
      onPixelateCurrentFrame: (blockSize) =>
          unawaited(_pixelateEditorTargetFrame(blockSize)),
      onPixelateWholeSheet: (blockSize) =>
          unawaited(_pixelateEditorSpriteSheet(blockSize)),
      onRowsChanged: _setEditorRows,
      onColumnsChanged: _setEditorColumns,
      onGridSpecChanged: _setEditorGridSpec,
      onTargetFrameChanged: _setEditorTargetFrameIndex,
      onFrameFitChanged: _setEditorFrameFit,
      onFocusModeChanged: (value) =>
          setState(() => _isImageEditorFocusMode = value),
      onReplaceFrame: _replaceEditorFrame,
      onCopyPreviousFrame: () => unawaited(_copyPreviousEditorFrame()),
      onClearTargetFrame: () => unawaited(_clearEditorTargetFrame()),
      onExportSpriteSheet: (bytes) => unawaited(
        _exportSpriteSheet(
          pngBytes: bytes,
          rows: _editorRows,
          columns: _editorColumns,
          gridSpec: _editorGridSpec,
        ),
      ),
      onSendToGif: _sendPreviewDataToGif,
    );
  }
}

AnimationPlaybackMode _animationPlaybackMode(GifPlaybackMode mode) {
  return switch (mode) {
    GifPlaybackMode.normal => AnimationPlaybackMode.normal,
    GifPlaybackMode.reverse => AnimationPlaybackMode.reverse,
    GifPlaybackMode.pingPong => AnimationPlaybackMode.pingPong,
  };
}
