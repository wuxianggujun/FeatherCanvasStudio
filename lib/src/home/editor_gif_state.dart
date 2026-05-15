part of 'package:feather_canvas_studio/main.dart';

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
  int get _editorRows;
  set _editorRows(int value);
  int get _editorColumns;
  set _editorColumns(int value);
  int get _editorTargetFrameIndex;
  set _editorTargetFrameIndex(int value);
  SpriteSheetFrameFit get _editorFrameFit;
  set _editorFrameFit(SpriteSheetFrameFit value);
  int get _editorFrameCount;
  String? get _editorErrorMessage;
  bool get _isReplacingEditorFrame;
  set _isReplacingEditorFrame(bool value);
  int get _gifDefaultFrameDelayMs;
  set _gifDefaultFrameDelayMs(int value);
  int get _gifLoopCount;
  set _gifLoopCount(int value);
  GifPlaybackMode get _gifPlaybackMode;
  set _gifPlaybackMode(GifPlaybackMode value);
  bool get _isComposingGif;
  set _isComposingGif(bool value);
  String? get _gifOutputPath;
  set _gifOutputPath(String? value);
  String? get _gifErrorMessage;
  set _gifErrorMessage(String? value);
  @override
  void _showMessage(String message);

  void _setEditorRows(int value) {
    setState(() {
      _editorRows = value;
      _normalizeEditorTargetFrameIndex();
    });
  }

  void _setEditorColumns(int value) {
    setState(() {
      _editorColumns = value;
      _normalizeEditorTargetFrameIndex();
    });
  }

  void _setEditorTargetFrameIndex(int value) {
    setState(() {
      _editorTargetFrameIndex = value.clamp(0, _editorFrameCount - 1);
    });
  }

  void _setEditorFrameFit(SpriteSheetFrameFit value) {
    setState(() => _editorFrameFit = value);
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

    setState(() {
      _editorImagePath = imagePath;
      _editorErrorMessage = null;
    });
    _showMessage('已载入图片：${fileNameFromPath(imagePath)}');
  }

  void _clearEditorImage() {
    setState(() {
      _editorImagePath = null;
      _editorErrorMessage = null;
    });
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

    setState(() {
      _editorPatchImagePath = imagePath;
      _editorErrorMessage = null;
    });
    _showMessage('已选择单帧图片：${fileNameFromPath(imagePath)}');
  }

  void _clearEditorPatchImage() {
    setState(() {
      _editorPatchImagePath = null;
      _editorErrorMessage = null;
    });
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

    setState(() {
      _gifSourceFrames = newFrames;
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  void _clearGifSourceImages() {
    setState(() {
      _gifSourceFrames = const [];
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  void _setGifDefaultFrameDelay(int value) {
    setState(() => _gifDefaultFrameDelayMs = value);
  }

  void _applyGifFrameDelayToAll() {
    if (_gifSourceFrames.isEmpty) {
      return;
    }

    setState(() {
      _gifSourceFrames = [
        for (final frame in _gifSourceFrames)
          frame.copyWith(delayMs: _gifDefaultFrameDelayMs),
      ];
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  void _setGifSourceFrameDelay(int index, int delayMs) {
    if (index < 0 || index >= _gifSourceFrames.length) {
      return;
    }

    final nextFrames = [..._gifSourceFrames];
    nextFrames[index] = nextFrames[index].copyWith(delayMs: delayMs);
    setState(() {
      _gifSourceFrames = nextFrames;
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  void _setGifLoopCount(int value) {
    setState(() => _gifLoopCount = value);
  }

  void _setGifPlaybackMode(GifPlaybackMode value) {
    setState(() => _gifPlaybackMode = value);
  }

  void _reorderGifSourceImages(int oldIndex, int newIndex) {
    setState(() {
      _gifSourceFrames = reorderListItems(_gifSourceFrames, oldIndex, newIndex);
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  void _removeGifSourceImageAt(int index) {
    if (index < 0 || index >= _gifSourceFrames.length) {
      return;
    }

    final nextFrames = [..._gifSourceFrames]..removeAt(index);
    setState(() {
      _gifSourceFrames = nextFrames;
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  Future<void> _composeGif() async {
    if (_gifSourceFrames.length < 2) {
      _showMessage('请至少选择 2 张图片');
      return;
    }

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
      _showMessage(
        'GIF 已生成：${fileNameFromPath(output.path)} · 目录：${output.directoryPath}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _gifErrorMessage = 'GIF 生成失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isComposingGif = false);
      }
    }
  }

  Future<void> _exportSpriteSheet({
    required Uint8List pngBytes,
    required int rows,
    required int columns,
  }) async {
    final output = await SpriteSheetFileService.exportPng(
      store: _store,
      pngBytes: pngBytes,
      rows: rows,
      columns: columns,
    );
    if (!mounted) {
      return;
    }
    final item = await _imageLibraryService.addExportedSpriteSheet(
      store: _store,
      path: output.path,
      rows: rows,
      columns: columns,
    );
    if (!mounted) {
      return;
    }
    setState(() => _imageLibrary = [item, ..._imageLibrary]);
    _showMessage(
      '已导出 Sprite Sheet：${fileNameFromPath(output.path)} · 目录：${output.directoryPath}',
    );
  }

  Future<void> _replaceEditorFrame() async {
    final sheetPath = _editorImagePath;
    final patchPath = _editorPatchImagePath;
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
      final output = await SpriteSheetFileService.replaceFrameAndSave(
        store: _store,
        readFileBytes: _fileService.readFileBytes,
        sheetPath: sheetPath,
        patchPath: patchPath,
        rows: _editorRows,
        columns: _editorColumns,
        frameIndex: _editorTargetFrameIndex,
        fit: _editorFrameFit,
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
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _editorImagePath = output.path;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _showMessage(
        '已替换第 ${_editorTargetFrameIndex + 1} 帧：${fileNameFromPath(output.path)} · 目录：${output.directoryPath}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _editorErrorMessage = '单帧替换失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isReplacingEditorFrame = false);
      }
    }
  }

  Widget _buildImageEditorWorkspace() {
    return ImageEditorWorkspace(
      imagePath: _editorImagePath,
      patchImagePath: _editorPatchImagePath,
      rows: _editorRows,
      columns: _editorColumns,
      targetFrameIndex: _editorTargetFrameIndex.clamp(0, _editorFrameCount - 1),
      frameFit: _editorFrameFit,
      isReplacingFrame: _isReplacingEditorFrame,
      errorMessage: _editorErrorMessage,
      onPickImage: _pickEditorImage,
      onClearImage: _clearEditorImage,
      onPickPatchImage: _pickEditorPatchImage,
      onClearPatchImage: _clearEditorPatchImage,
      onRowsChanged: _setEditorRows,
      onColumnsChanged: _setEditorColumns,
      onTargetFrameChanged: _setEditorTargetFrameIndex,
      onFrameFitChanged: _setEditorFrameFit,
      onReplaceFrame: _replaceEditorFrame,
      onExportSpriteSheet: (bytes) => unawaited(
        _exportSpriteSheet(
          pngBytes: bytes,
          rows: _editorRows,
          columns: _editorColumns,
        ),
      ),
    );
  }

  Widget _buildGifComposerWorkspace() {
    return GifComposerWorkspace(
      frames: _gifSourceFrames,
      defaultFrameDelayMs: _gifDefaultFrameDelayMs,
      loopCount: _gifLoopCount,
      playbackMode: _gifPlaybackMode,
      isComposing: _isComposingGif,
      outputPath: _gifOutputPath,
      errorMessage: _gifErrorMessage,
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
