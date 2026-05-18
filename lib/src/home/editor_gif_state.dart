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

class _GifConfigSnapshot {
  const _GifConfigSnapshot({
    required this.defaultFrameDelayMs,
    required this.loopCount,
    required this.playbackMode,
  });

  final int defaultFrameDelayMs;
  final int loopCount;
  final GifPlaybackMode playbackMode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _GifConfigSnapshot &&
            defaultFrameDelayMs == other.defaultFrameDelayMs &&
            loopCount == other.loopCount &&
            playbackMode == other.playbackMode;
  }

  @override
  int get hashCode => Object.hash(defaultFrameDelayMs, loopCount, playbackMode);
}

const Duration _editorConfigHistoryMergeWindow = Duration(milliseconds: 800);
const String _editorGridConfigHistoryKey = 'editor-grid-config';
const String _editorFrameFitHistoryKey = 'editor-frame-fit';
const Duration _gifHistoryMergeWindow = Duration(milliseconds: 800);
const String _gifDefaultDelayHistoryKey = 'gif-default-delay';
const String _gifLoopCountHistoryKey = 'gif-loop-count';
const String _gifPlaybackModeHistoryKey = 'gif-playback-mode';
const String _gifApplyDelayToAllHistoryKey = 'gif-apply-delay-to-all';
const String _gifClearFramesHistoryKey = 'gif-clear-frames';
const String _gifLoadSourceFramesHistoryKey = 'gif-load-source-frames';
const String _gifLoadPreviewFramesHistoryKey = 'gif-load-preview-frames';

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
  SpriteSheetGridSpec get _editorGridSpec => _imageEditorNotifier.editorGridSpec;
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
  String? get _editorPatchImagePath => _imageEditorNotifier.editorPatchImagePath;
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
  GifComposerNotifier get _gifComposerNotifier;
  // ignore: unused_element
  List<GifSourceFrame> get _gifSourceFrames => _gifComposerNotifier.frames;
  set _gifSourceFrames(List<GifSourceFrame> value) =>
      _gifComposerNotifier.frames = value;
  // ignore: unused_element
  int get _gifDefaultFrameDelayMs => _gifComposerNotifier.defaultFrameDelayMs;
  set _gifDefaultFrameDelayMs(int value) =>
      _gifComposerNotifier.defaultFrameDelayMs = value;
  // ignore: unused_element
  int get _gifLoopCount => _gifComposerNotifier.loopCount;
  set _gifLoopCount(int value) => _gifComposerNotifier.loopCount = value;
  // ignore: unused_element
  GifPlaybackMode get _gifPlaybackMode => _gifComposerNotifier.playbackMode;
  set _gifPlaybackMode(GifPlaybackMode value) =>
      _gifComposerNotifier.playbackMode = value;
  // ignore: unused_element
  bool get _isComposingGif => _gifComposerNotifier.isComposing;
  set _isComposingGif(bool value) => _gifComposerNotifier.isComposing = value;
  // ignore: unused_element
  String? get _gifOutputPath => _gifComposerNotifier.outputPath;
  set _gifOutputPath(String? value) => _gifComposerNotifier.outputPath = value;
  // ignore: unused_element
  String? get _gifErrorMessage => _gifComposerNotifier.errorMessage;
  set _gifErrorMessage(String? value) =>
      _gifComposerNotifier.errorMessage = value;
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
  HistoryAction? _lastGifConfigHistoryAction;
  String? _lastGifConfigHistoryKey;
  DateTime? _lastGifConfigHistoryAt;
  _GifConfigSnapshot? _lastGifConfigHistoryBefore;
  HistoryAction? _lastGifFramesHistoryAction;
  String? _lastGifFramesHistoryKey;
  DateTime? _lastGifFramesHistoryAt;
  List<GifSourceFrame>? _lastGifFramesHistoryBefore;

  void _setEditorRows(int value) {
    final before = _captureEditorConfig();
    setState(() {
      _editorRows = value;
      _editorGridSpec = _editorGridSpec.copyWith(rows: value);
      _normalizeEditorTargetFrameIndex();
    });
    _pushEditorConfigHistory(
      label: '调整行数为 $value 行',
      before: before,
      mergeKey: _editorGridConfigHistoryKey,
    );
  }

  void _setEditorColumns(int value) {
    final before = _captureEditorConfig();
    setState(() {
      _editorColumns = value;
      _editorGridSpec = _editorGridSpec.copyWith(columns: value);
      _normalizeEditorTargetFrameIndex();
    });
    _pushEditorConfigHistory(
      label: '调整列数为 $value 列',
      before: before,
      mergeKey: _editorGridConfigHistoryKey,
    );
  }

  void _setEditorGridSpec(SpriteSheetGridSpec value) {
    final before = _captureEditorConfig();
    setState(() {
      _editorRows = value.rows;
      _editorColumns = value.columns;
      _editorGridSpec = value;
      _normalizeEditorTargetFrameIndex();
    });
    _pushEditorConfigHistory(
      label: '调整切片校准',
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
    if (before.frameFit == value) {
      return;
    }
    _editorFrameFit = value;
    _pushEditorConfigHistory(
      label: '调整适配方式为 ${spriteSheetFrameFitLabel(value)}',
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
    final imagePath = await _pickSingleImagePathFromSource(
      title: '选择 Sprite Sheet 图片',
      libraryEmptyMessage: '生成或导出 Sprite Sheet 后可从这里复用',
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
    _pushEditorSourceHistory(label: '载入 Sprite Sheet', before: before);
    _showMessage('已载入图片：${fileNameFromPath(imagePath)}');
  }

  void _clearEditorImage() {
    final before = _captureEditorSource();
    if (before.sheetPath == null && before.errorMessage == null) {
      return;
    }

    setState(() {
      _editorImagePath = null;
      _editorErrorMessage = null;
    });
    _pushEditorSourceHistory(label: '清空 Sprite Sheet', before: before);
  }

  Future<void> _pickEditorPatchImage() async {
    final imagePath = await _pickSingleImagePathFromSource(
      title: '选择单帧图片',
      libraryEmptyMessage: '保存到作品库后的单帧图片会显示在这里',
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
    _pushEditorSourceHistory(label: '选择单帧图片', before: before);
    _showMessage('已选择单帧图片：${fileNameFromPath(imagePath)}');
  }

  void _clearEditorPatchImage() {
    final before = _captureEditorSource();
    if (before.patchPath == null && before.errorMessage == null) {
      return;
    }

    setState(() {
      _editorPatchImagePath = null;
      _editorErrorMessage = null;
    });
    _pushEditorSourceHistory(label: '清空单帧图片', before: before);
  }

  Future<void> _makeEditorPatchBackgroundTransparent(int tolerance) async {
    final patchPath = _editorPatchImagePath;
    if (patchPath == null) {
      _showMessage('请先选择一张单帧图片');
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
        _showMessage('没有检测到可透明化的边缘背景，可尝试调高容差');
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
        title: '透明背景单帧',
        source: '图片编辑',
        prompt:
            '背景转透明 · 容差 $tolerance · '
            '${result.width} x ${result.height}',
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _editorPatchImagePath = file.path;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _pushEditorPatchImageHistory(
        label: '背景转透明单帧',
        beforePatchPath: patchPath,
        afterPatchPath: file.path,
        appendedItem: item,
      );
      _showMessage(
        '已生成透明背景单帧：${fileNameFromPath(file.path)} · '
        '透明化 ${result.transparentPixelCount} 个像素',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = '背景转透明失败：$error';
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _adjustEditorPatchFraming() async {
    final sheetPath = _editorImagePath;
    final patchPath = _editorPatchImagePath;
    if (sheetPath == null) {
      _showMessage('请先选择一张 Sprite Sheet');
      return;
    }
    if (patchPath == null) {
      _showMessage('请先选择一张单帧图片');
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
        title: '取景单帧',
        source: '图片编辑',
        prompt:
            '单帧取景 · ${previewData.frameWidth} x '
            '${previewData.frameHeight}',
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
        label: '调整单帧取景',
        beforePatchPath: patchPath,
        afterPatchPath: file.path,
        appendedItem: item,
      );
      _showMessage(
        '已生成取景单帧：${fileNameFromPath(file.path)} · '
        '${previewData.frameWidth} x ${previewData.frameHeight}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = '调整取景失败：$error';
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _pickAnimationTemplateImage() async {
    final candidates = _availableImageLibraryItems(
      allowedKinds: templateLibraryKinds,
    );
    final source = await _selectImagePickSource(
      title: '选择模板图片',
      allowLibrary: candidates.isNotEmpty,
      libraryEmptyMessage: '保存到作品库后的图片会显示在这里',
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
        title: '选择模板图片',
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
        sliceLabel = '${item.displayTitle} · 帧 ${entry.key + 1}';
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
          ? '已选择模板切片：$sliceLabel'
          : '已选择模板图片：${fileNameFromPath(imagePath)}',
    );
  }

  void _clearAnimationTemplateImage() {
    final previous = _animationTemplateImagePath;
    setState(() => _animationTemplateImagePath = null);
    if (previous != null && _ephemeralTemplatePaths.remove(previous)) {
      unawaited(_fileService.safeDeleteFile(previous));
    }
  }

  Future<void> _pickGifSourceImages() async {
    final candidates = _availableImageLibraryItems(
      allowedKinds: gifSourceLibraryKinds,
    );
    final source = await _selectImagePickSource(
      title: '选择 GIF 图片序列',
      allowLibrary: candidates.isNotEmpty,
      libraryEmptyMessage: '保存到作品库后的图片会显示在这里',
    );
    if (source == null || !mounted) {
      return;
    }

    final newFrames = <GifSourceFrame>[];
    var seed = 0;

    if (source == ImagePickSource.localFile) {
      final images = await openFiles(acceptedTypeGroups: imageTypeGroups);
      final paths = [for (final image in images) image.path];
      newFrames.addAll(
        buildGifFramesFromPaths(
          paths,
          delayMs: _gifDefaultFrameDelayMs,
          seedStart: seed,
        ),
      );
      seed += paths.length;
    } else {
      final items = await _showImageLibraryPicker<List<ImageLibraryItem>>(
        title: '选择 GIF 图片序列',
        allowMultiple: true,
        allowedKinds: gifSourceLibraryKinds,
      );
      if (items == null || items.isEmpty || !mounted) {
        return;
      }
      for (final item in items) {
        if (item.isSpriteSheetWithMetadata) {
          final picked = await _showSlicePicker(item, allowMultiple: true);
          if (picked == null || !mounted) {
            continue;
          }
          newFrames.addAll(
            buildGifFramesFromSlices(
              sheet: item,
              slices: picked,
              delayMs: _gifDefaultFrameDelayMs,
              seedStart: seed,
            ),
          );
          seed += picked.length;
        } else {
          newFrames.add(
            buildGifFrameFromLibraryItem(
              item,
              delayMs: _gifDefaultFrameDelayMs,
              seed: seed++,
            ),
          );
        }
      }
    }

    if (newFrames.isEmpty || !mounted) {
      return;
    }

    final before = List<GifSourceFrame>.unmodifiable(_gifSourceFrames);
    setState(() {
      _gifSourceFrames = newFrames;
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
    _pushGifFramesHistory(
      label: '载入 GIF 图片序列',
      before: before,
      mergeKey: _gifLoadSourceFramesHistoryKey,
    );
  }

  void _clearGifSourceImages() {
    final before = List<GifSourceFrame>.unmodifiable(_gifSourceFrames);
    if (before.isEmpty) {
      return;
    }

    setState(() {
      _gifSourceFrames = const [];
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
    _pushGifFramesHistory(
      label: '清空 GIF 帧',
      before: before,
      mergeKey: _gifClearFramesHistoryKey,
    );
  }

  void _setGifDefaultFrameDelay(int value) {
    final before = _captureGifConfig();
    if (before.defaultFrameDelayMs == value) {
      return;
    }

    _gifDefaultFrameDelayMs = value;
    _pushGifConfigHistory(
      label: '调整默认帧时长为 $value ms',
      before: before,
      mergeKey: _gifDefaultDelayHistoryKey,
    );
  }

  void _applyGifFrameDelayToAll() {
    if (_gifSourceFrames.isEmpty) {
      return;
    }

    final before = List<GifSourceFrame>.unmodifiable(_gifSourceFrames);
    setState(() {
      _gifSourceFrames = [
        for (final frame in _gifSourceFrames)
          frame.copyWith(delayMs: _gifDefaultFrameDelayMs),
      ];
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
    _pushGifFramesHistory(
      label: '应用默认帧时长到全部',
      before: before,
      mergeKey: _gifApplyDelayToAllHistoryKey,
    );
  }

  void _setGifSourceFrameDelay(int index, int delayMs) {
    if (index < 0 || index >= _gifSourceFrames.length) {
      return;
    }

    final before = List<GifSourceFrame>.unmodifiable(_gifSourceFrames);
    if (_gifSourceFrames[index].delayMs == delayMs) {
      return;
    }

    final nextFrames = [..._gifSourceFrames];
    nextFrames[index] = nextFrames[index].copyWith(delayMs: delayMs);
    setState(() {
      _gifSourceFrames = nextFrames;
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
    final frame = before[index];
    _pushGifFramesHistory(
      label: '调整${frame.label ?? '第 ${index + 1} 帧'}时长为 $delayMs ms',
      before: before,
      mergeKey: 'gif-frame-delay-$index',
    );
  }

  void _setGifLoopCount(int value) {
    final before = _captureGifConfig();
    if (before.loopCount == value) {
      return;
    }

    _gifLoopCount = value;
    _pushGifConfigHistory(
      label: value == 0 ? '调整 GIF 为无限循环' : '调整 GIF 循环为 $value 次',
      before: before,
      mergeKey: _gifLoopCountHistoryKey,
    );
  }

  void _setGifPlaybackMode(GifPlaybackMode value) {
    final before = _captureGifConfig();
    if (before.playbackMode == value) {
      return;
    }

    _gifPlaybackMode = value;
    _pushGifConfigHistory(
      label: '调整播放模式为 ${gifPlaybackModeLabel(value)}',
      before: before,
      mergeKey: _gifPlaybackModeHistoryKey,
    );
  }

  _GifConfigSnapshot _captureGifConfig() {
    return _GifConfigSnapshot(
      defaultFrameDelayMs: _gifDefaultFrameDelayMs,
      loopCount: _gifLoopCount,
      playbackMode: _gifPlaybackMode,
    );
  }

  void _restoreGifConfig(_GifConfigSnapshot snapshot) {
    if (!mounted) {
      return;
    }

    setState(() {
      _gifDefaultFrameDelayMs = snapshot.defaultFrameDelayMs;
      _gifLoopCount = snapshot.loopCount;
      _gifPlaybackMode = snapshot.playbackMode;
    });
  }

  void _pushGifConfigHistory({
    required String label,
    required _GifConfigSnapshot before,
    required String mergeKey,
  }) {
    final after = _captureGifConfig();
    if (before == after) {
      return;
    }

    final now = DateTime.now();
    final previousAction = _lastGifConfigHistoryAction;
    final previousAt = _lastGifConfigHistoryAt;
    final shouldMerge =
        previousAction != null &&
        previousAt != null &&
        _lastGifConfigHistoryKey == mergeKey &&
        now.difference(previousAt) <= _gifHistoryMergeWindow;

    if (shouldMerge) {
      final mergedBefore = _lastGifConfigHistoryBefore ?? before;
      final replacement = _gifConfigHistoryAction(
        label: label,
        before: mergedBefore,
        after: after,
      );
      final replaced = _replaceTopHistory(
        WorkspaceFeature.gifComposer,
        current: previousAction,
        replacement: replacement,
      );
      if (replaced) {
        _rememberGifConfigHistory(
          action: replacement,
          mergeKey: mergeKey,
          before: mergedBefore,
          now: now,
        );
        return;
      }
    }

    final action = _gifConfigHistoryAction(
      label: label,
      before: before,
      after: after,
    );
    _pushHistory(WorkspaceFeature.gifComposer, action);
    _rememberGifConfigHistory(
      action: action,
      mergeKey: mergeKey,
      before: before,
      now: now,
    );
  }

  HistoryAction _gifConfigHistoryAction({
    required String label,
    required _GifConfigSnapshot before,
    required _GifConfigSnapshot after,
  }) {
    return HistoryAction(
      label: label,
      apply: () => _restoreGifConfig(after),
      revert: () => _restoreGifConfig(before),
    );
  }

  void _rememberGifConfigHistory({
    required HistoryAction action,
    required String mergeKey,
    required _GifConfigSnapshot before,
    required DateTime now,
  }) {
    _lastGifConfigHistoryAction = action;
    _lastGifConfigHistoryKey = mergeKey;
    _lastGifConfigHistoryBefore = before;
    _lastGifConfigHistoryAt = now;
  }

  void _restoreGifFrames(List<GifSourceFrame> frames) {
    if (!mounted) {
      return;
    }

    setState(() {
      _gifSourceFrames = List<GifSourceFrame>.unmodifiable(frames);
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  void _pushGifFramesHistory({
    required String label,
    required List<GifSourceFrame> before,
    required String mergeKey,
  }) {
    final after = List<GifSourceFrame>.unmodifiable(_gifSourceFrames);
    if (_gifSourceFrameStateEquals(before, after)) {
      return;
    }

    final now = DateTime.now();
    final previousAction = _lastGifFramesHistoryAction;
    final previousAt = _lastGifFramesHistoryAt;
    final shouldMerge =
        previousAction != null &&
        previousAt != null &&
        _lastGifFramesHistoryKey == mergeKey &&
        now.difference(previousAt) <= _gifHistoryMergeWindow;

    if (shouldMerge) {
      final mergedBefore = _lastGifFramesHistoryBefore ?? before;
      final replacement = _gifFramesHistoryAction(
        label: label,
        before: mergedBefore,
        after: after,
      );
      final replaced = _replaceTopHistory(
        WorkspaceFeature.gifComposer,
        current: previousAction,
        replacement: replacement,
      );
      if (replaced) {
        _rememberGifFramesHistory(
          action: replacement,
          mergeKey: mergeKey,
          before: mergedBefore,
          now: now,
        );
        return;
      }
    }

    final action = _gifFramesHistoryAction(
      label: label,
      before: before,
      after: after,
    );
    _pushHistory(WorkspaceFeature.gifComposer, action);
    _rememberGifFramesHistory(
      action: action,
      mergeKey: mergeKey,
      before: before,
      now: now,
    );
  }

  HistoryAction _gifFramesHistoryAction({
    required String label,
    required List<GifSourceFrame> before,
    required List<GifSourceFrame> after,
  }) {
    return HistoryAction(
      label: label,
      estimatedBytes:
          _gifFramesEstimatedBytes(before) + _gifFramesEstimatedBytes(after),
      apply: () => _restoreGifFrames(after),
      revert: () => _restoreGifFrames(before),
    );
  }

  void _rememberGifFramesHistory({
    required HistoryAction action,
    required String mergeKey,
    required List<GifSourceFrame> before,
    required DateTime now,
  }) {
    _lastGifFramesHistoryAction = action;
    _lastGifFramesHistoryKey = mergeKey;
    _lastGifFramesHistoryBefore = before;
    _lastGifFramesHistoryAt = now;
  }

  int _gifFramesEstimatedBytes(List<GifSourceFrame> frames) {
    return frames.fold<int>(
      0,
      (total, frame) => total + (frame.inlineBytes?.length ?? 0),
    );
  }

  bool _gifSourceFrameStateEquals(
    List<GifSourceFrame> a,
    List<GifSourceFrame> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].delayMs != b[i].delayMs) {
        return false;
      }
    }
    return true;
  }

  Future<void> _sendPreviewDataToGif(SpriteSheetPreviewData previewData) async {
    final frames = <GifSourceFrame>[
      for (var index = 0; index < previewData.frames.length; index++)
        GifSourceFrame.fromBytes(
          previewData.frames[index],
          sourcePath: 'Sprite Sheet 预览',
          delayMs: _gifDefaultFrameDelayMs,
          seed: index,
          label: '第 ${index + 1} 帧',
        ),
    ];

    if (frames.length < 2) {
      _showMessage('至少需要 2 帧才能合成 GIF');
      return;
    }

    final before = List<GifSourceFrame>.unmodifiable(_gifSourceFrames);
    setState(() {
      _gifSourceFrames = frames;
      _gifOutputPath = null;
      _gifErrorMessage = null;
      _selectedFeature = WorkspaceFeature.gifComposer;
    });
    _pushGifFramesHistory(
      label: '载入切片到 GIF',
      before: before,
      mergeKey: _gifLoadPreviewFramesHistoryKey,
    );
    _showMessage('已载入 ${frames.length} 帧到 GIF 合成');
  }

  void _reorderGifSourceImages(int oldIndex, int newIndex) {
    final before = List<GifSourceFrame>.unmodifiable(_gifSourceFrames);
    final after = List<GifSourceFrame>.unmodifiable(
      reorderListItems(_gifSourceFrames, oldIndex, newIndex),
    );
    if (_gifSourceFrameOrderEquals(before, after)) {
      return;
    }
    setState(() {
      _gifSourceFrames = after;
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
    _pushHistory(
      WorkspaceFeature.gifComposer,
      HistoryAction(
        label: '调整 GIF 帧顺序',
        apply: () {
          if (!mounted) return;
          setState(() {
            _gifSourceFrames = after;
            _gifOutputPath = null;
            _gifErrorMessage = null;
          });
        },
        revert: () {
          if (!mounted) return;
          setState(() {
            _gifSourceFrames = before;
            _gifOutputPath = null;
            _gifErrorMessage = null;
          });
        },
      ),
    );
  }

  void _removeGifSourceImageAt(int index) {
    if (index < 0 || index >= _gifSourceFrames.length) {
      return;
    }

    final before = List<GifSourceFrame>.unmodifiable(_gifSourceFrames);
    final removedFrame = _gifSourceFrames[index];
    final after = List<GifSourceFrame>.unmodifiable(
      [..._gifSourceFrames]..removeAt(index),
    );
    setState(() {
      _gifSourceFrames = after;
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
    _pushHistory(
      WorkspaceFeature.gifComposer,
      HistoryAction(
        label: removedFrame.label != null
            ? '移除「${removedFrame.label}」'
            : '移除第 ${index + 1} 帧',
        estimatedBytes: removedFrame.inlineBytes?.length ?? 0,
        apply: () {
          if (!mounted) return;
          setState(() {
            _gifSourceFrames = after;
            _gifOutputPath = null;
            _gifErrorMessage = null;
          });
        },
        revert: () {
          if (!mounted) return;
          setState(() {
            _gifSourceFrames = before;
            _gifOutputPath = null;
            _gifErrorMessage = null;
          });
        },
      ),
    );
  }

  bool _gifSourceFrameOrderEquals(
    List<GifSourceFrame> a,
    List<GifSourceFrame> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Future<void> _composeGif() async {
    if (_gifSourceFrames.length < 2) {
      _showMessage('请至少选择 2 张图片');
      return;
    }

    final beforeOutputPath = _gifOutputPath;
    setState(() {
      _isComposingGif = true;
      _gifErrorMessage = null;
      _gifOutputPath = null;
    });

    try {
      final output = await GifComposer.composeToStore(
        store: _store,
        frames: _gifSourceFrames,
        loopCount: _gifLoopCount,
        playbackMode: _gifPlaybackMode,
      );

      if (!mounted) {
        return;
      }

      final item = await _imageLibraryService.addGif(
        store: _store,
        path: output.path,
        frameCount: _gifSourceFrames.length,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _gifOutputPath = output.path;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _pushGifCompositionHistory(
        label: '生成 GIF',
        beforeOutputPath: beforeOutputPath,
        afterOutputPath: output.path,
        appendedItem: item,
      );
      _showMessage(
        'GIF 已生成：${fileNameFromPath(output.path)} · 目录：${output.directoryPath}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _gifErrorMessage = 'GIF 生成失败：$error';
    } finally {
      if (mounted) {
        _isComposingGif = false;
      }
    }
  }

  void _pushGifCompositionHistory({
    required String label,
    required String? beforeOutputPath,
    required String afterOutputPath,
    required ImageLibraryItem appendedItem,
  }) {
    _pushImageLibraryAppendHistory(
      feature: WorkspaceFeature.gifComposer,
      label: label,
      appendedItems: [appendedItem],
      applyState: () {
        _gifOutputPath = afterOutputPath;
        _gifErrorMessage = null;
      },
      revertState: () {
        _gifOutputPath = beforeOutputPath;
        _gifErrorMessage = null;
      },
    );
  }

  Future<void> _exportSpriteSheet({
    required Uint8List pngBytes,
    required int rows,
    required int columns,
    required SpriteSheetGridSpec gridSpec,
  }) async {
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
      gridSpec: gridSpec,
    );
    if (!mounted) {
      return;
    }
    _imageLibrary = [item, ..._imageLibrary];
    _pushImageLibraryAppendHistory(
      feature: _selectedFeature,
      label: '导出 Sprite Sheet',
      appendedItems: [item],
    );
    _showMessage(
      '已导出 Sprite Sheet：${fileNameFromPath(output.path)} · 目录：${output.directoryPath}',
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
      _showMessage('请先选择一张 Sprite Sheet');
      return;
    }
    if (patchPath == null) {
      _showMessage('请先选择要插入的单帧图片');
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
        fitLabel: spriteSheetFrameFitLabel(frameFit),
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
        label: '替换第 ${frameIndex + 1} 帧',
        beforeSheetPath: sheetPath,
        afterSheetPath: output.path,
        appendedItem: item,
      );
      _showMessage(
        '已替换第 ${frameIndex + 1} 帧：${fileNameFromPath(output.path)} · 目录：${output.directoryPath}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _editorErrorMessage = '单帧替换失败：$error';
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _copyPreviousEditorFrame() async {
    final sheetPath = _editorImagePath;
    if (sheetPath == null) {
      _showMessage('请先选择一张 Sprite Sheet');
      return;
    }
    if (_editorTargetFrameIndex <= 0) {
      _showMessage('第 1 帧没有上一帧可复制');
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
        label: '复制上一帧到第 ${_editorTargetFrameIndex + 1} 帧',
        beforeSheetPath: sheetPath,
        afterSheetPath: output.path,
        appendedItem: item,
      );
      _showMessage('已复制上一帧到第 ${_editorTargetFrameIndex + 1} 帧');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = '复制帧失败：$error';
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _clearEditorTargetFrame() async {
    final sheetPath = _editorImagePath;
    if (sheetPath == null) {
      _showMessage('请先选择一张 Sprite Sheet');
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
        label: '清空第 ${_editorTargetFrameIndex + 1} 帧',
        beforeSheetPath: sheetPath,
        afterSheetPath: output.path,
        appendedItem: item,
      );
      _showMessage('已清空第 ${_editorTargetFrameIndex + 1} 帧');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = '清空帧失败：$error';
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _pixelateEditorTargetFrame(int blockSize) async {
    final sheetPath = _editorImagePath;
    if (sheetPath == null) {
      _showMessage('请先选择一张 Sprite Sheet');
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
        title: '像素化 Sprite Sheet',
        source: '图片编辑',
        prompt:
            '像素化第 ${frameIndex + 1} 帧 · 像素块 ${safeBlockSize}px · '
            '$_editorRows x $_editorColumns',
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
        label: '像素化第 ${frameIndex + 1} 帧',
        beforeSheetPath: sheetPath,
        afterSheetPath: output.path,
        appendedItem: item,
      );
      _showMessage(
        '已像素化第 ${frameIndex + 1} 帧：${fileNameFromPath(output.path)} · '
        '像素块 ${safeBlockSize}px',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = '像素化当前帧失败：$error';
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _pixelateEditorSpriteSheet(int blockSize) async {
    final sheetPath = _editorImagePath;
    if (sheetPath == null) {
      _showMessage('请先选择一张 Sprite Sheet');
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
        title: '像素化 Sprite Sheet',
        source: '图片编辑',
        prompt:
            '像素化整张 · 像素块 ${safeBlockSize}px · '
            '$_editorRows x $_editorColumns',
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
        label: '像素化整张 Sprite Sheet',
        beforeSheetPath: sheetPath,
        afterSheetPath: output.path,
        appendedItem: item,
      );
      _showMessage(
        '已像素化整张 Sprite Sheet：${fileNameFromPath(output.path)} · '
        '像素块 ${safeBlockSize}px',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _editorErrorMessage = '像素化整张失败：$error';
    } finally {
      if (mounted) {
        _isReplacingEditorFrame = false;
      }
    }
  }

  Future<void> _pickGeneralEditorImage() async {
    final imagePath = await _pickSingleImagePathFromSource(
      title: '选择要编辑的图片',
      libraryEmptyMessage: '作品库里保存的图片会显示在这里',
      allowedLibraryKinds: templateLibraryKinds,
    );

    if (imagePath == null || !mounted) {
      return;
    }

    await _loadGeneralEditorImage(imagePath, label: '已载入图片');
  }

  Future<void> _loadGeneralEditorImage(
    String imagePath, {
    required String label,
  }) async {
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
      _showMessage('$label：${fileNameFromPath(imagePath)}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _generalEditorErrorMessage = '图片读取失败：$error';
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
    final imagePath = _generalEditorImagePath;
    final beforeInfo = _generalEditorImageInfo;
    if (imagePath == null) {
      _showMessage('请先选择一张图片');
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
        title: '编辑后的图片',
        source: '图片编辑',
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
        label: '编辑图片',
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
        '已保存编辑结果：${fileNameFromPath(file.path)} · ${result.summary}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _generalEditorErrorMessage = '图片编辑失败：$error';
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

  Widget _buildGifComposerWorkspace() {
    return GifComposerWorkspace(
      historyControls: _buildCompactHistoryControls(),
      onPickImages: _pickGifSourceImages,
      onClearImages: _clearGifSourceImages,
      onReorderImages: _reorderGifSourceImages,
      onRemoveImageAt: _removeGifSourceImageAt,
      onFrameDelayChanged: _setGifDefaultFrameDelay,
      onApplyFrameDelayToAll: _applyGifFrameDelayToAll,
      onFrameDelayForImageChanged: _setGifSourceFrameDelay,
      onLoopCountChanged: _setGifLoopCount,
      onPlaybackModeChanged: _setGifPlaybackMode,
      onCompose: _composeGif,
    );
  }
}
