part of 'package:feather_canvas_studio/main.dart';

class _GenerationReuseSnapshot {
  const _GenerationReuseSnapshot({
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
    required this.user,
    required this.size,
    required this.imageCount,
    required this.advancedSettings,
    required this.errorMessage,
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
  final String user;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final String? errorMessage;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _GenerationReuseSnapshot &&
            _apiConfigListEquals(apiConfigs, other.apiConfigs) &&
            selectedApiConfigId == other.selectedApiConfigId &&
            apiConfigProviderKind == other.apiConfigProviderKind &&
            imageSizeCapabilityOverride == other.imageSizeCapabilityOverride &&
            apiConfigName == other.apiConfigName &&
            baseUrl == other.baseUrl &&
            apiKey == other.apiKey &&
            model == other.model &&
            generationTimeout == other.generationTimeout &&
            prompt == other.prompt &&
            negativePrompt == other.negativePrompt &&
            user == other.user &&
            size == other.size &&
            imageCount == other.imageCount &&
            advancedSettings == other.advancedSettings &&
            errorMessage == other.errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(apiConfigs.map(_apiConfigHash)),
    selectedApiConfigId,
    apiConfigProviderKind,
    imageSizeCapabilityOverride,
    apiConfigName,
    baseUrl,
    apiKey,
    model,
    generationTimeout,
    prompt,
    negativePrompt,
    user,
    size,
    imageCount,
    advancedSettings,
    errorMessage,
  );
}

bool _apiConfigListEquals(List<ApiConfig> a, List<ApiConfig> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (!_apiConfigEquals(a[index], b[index])) {
      return false;
    }
  }
  return true;
}

bool _apiConfigEquals(ApiConfig a, ApiConfig b) {
  return a.id == b.id &&
      a.name == b.name &&
      a.baseUrl == b.baseUrl &&
      a.apiKey == b.apiKey &&
      a.model == b.model &&
      a.providerKind == b.providerKind &&
      a.imageSizeCapabilityOverride == b.imageSizeCapabilityOverride &&
      a.generationTimeoutSeconds == b.generationTimeoutSeconds;
}

int _apiConfigHash(ApiConfig config) {
  return Object.hash(
    config.id,
    config.name,
    config.baseUrl,
    config.apiKey,
    config.model,
    config.providerKind,
    config.imageSizeCapabilityOverride,
    config.generationTimeoutSeconds,
  );
}

mixin _ImageLibraryStateMixin
    on
        State<FeatherCanvasHomePage>,
        _ApiConfigStateMixin,
        _LocalSettingsStateMixin {
  @override
  AppLocalStore get _store;
  @override
  WorkspaceFeature get _selectedFeature;
  @override
  bool get _isRestoringState;
  @override
  set _isRestoringState(bool value);
  String? get _editorImagePath;
  set _editorImagePath(String? value);
  String? get _editorPatchImagePath;
  set _editorPatchImagePath(String? value);
  set _editorRows(int value);
  set _editorColumns(int value);
  set _editorGridSpec(SpriteSheetGridSpec value);
  _EditorSourceSnapshot _captureEditorSource();
  void _pushEditorSourceHistory({
    required String label,
    required _EditorSourceSnapshot before,
  });
  String? get _animationTemplateImagePath;
  set _animationTemplateImagePath(String? value);
  set _editorErrorMessage(String? value);
  String? get _errorMessage;
  set _errorMessage(String? value);
  List<GifSourceFrame> get _gifSourceFrames;
  set _gifSourceFrames(List<GifSourceFrame> value);
  @override
  Future<void> _selectFeature(WorkspaceFeature feature);
  @override
  void _showMessage(String message);
  @override
  void _pushHistory(WorkspaceFeature feature, HistoryAction action);

  final TextEditingController _imageLibrarySearchController =
      TextEditingController();
  final ImageLibraryFileService _fileService = const ImageLibraryFileService();
  final ImageLibraryService _imageLibraryService = const ImageLibraryService();

  List<ImageLibraryItem> _imageLibraryValue = const [];
  Set<String>? _existingImageLibraryPaths;
  Set<String> _imageLibraryExistenceRefreshPaths = const <String>{};
  int _imageLibraryExistenceRefreshToken = 0;

  @override
  List<ImageLibraryItem> get _imageLibrary => _imageLibraryValue;

  @override
  set _imageLibrary(List<ImageLibraryItem> value) {
    final previousPaths = _imageLibraryPathSet(_imageLibraryValue);
    final nextPaths = _imageLibraryPathSet(value);
    _imageLibraryValue = value;
    _updateImageLibraryExistenceCacheAfterAssignment(
      previousPaths: previousPaths,
      nextPaths: nextPaths,
    );
  }

  ImageLibraryKindFilter _imageLibraryKindFilter = ImageLibraryKindFilter.all;
  ImageLibrarySortOrder _imageLibrarySortOrder = ImageLibrarySortOrder.newest;
  String _imageLibrarySearchQuery = '';
  String _imageLibraryProjectFilter = '';
  String _imageLibraryTagFilter = '';
  Set<String> _selectedImageLibraryItemIds = <String>{};
  bool _showStandaloneSpriteFrames = false;

  void _disposeImageLibraryState() {
    _imageLibraryExistenceRefreshToken += 1;
    _imageLibrarySearchController.dispose();
  }

  Set<String> _imageLibraryPathSet(List<ImageLibraryItem> library) {
    return {
      for (final item in library)
        if (item.path.trim().isNotEmpty) item.path,
    };
  }

  void _updateImageLibraryExistenceCacheAfterAssignment({
    required Set<String> previousPaths,
    required Set<String> nextPaths,
  }) {
    final cachedExistingPaths = _existingImageLibraryPaths;
    if (cachedExistingPaths != null) {
      _existingImageLibraryPaths = {
        for (final path in cachedExistingPaths)
          if (nextPaths.contains(path)) path,
        for (final path in nextPaths)
          if (!previousPaths.contains(path)) path,
      };
    } else if (nextPaths.isEmpty) {
      _existingImageLibraryPaths = const <String>{};
    }

    if (_stringSetEquals(nextPaths, _imageLibraryExistenceRefreshPaths)) {
      return;
    }

    _imageLibraryExistenceRefreshPaths = Set<String>.unmodifiable(nextPaths);
    final refreshToken = ++_imageLibraryExistenceRefreshToken;
    final pathsToCheck = cachedExistingPaths == null
        ? nextPaths
        : {
            for (final path in nextPaths)
              if (!previousPaths.contains(path)) path,
          };
    if (pathsToCheck.isEmpty) {
      return;
    }

    unawaited(
      _collectExistingImageLibraryPaths(pathsToCheck).then((existingPaths) {
        if (!mounted || refreshToken != _imageLibraryExistenceRefreshToken) {
          return;
        }
        final currentPaths = _imageLibraryPathSet(_imageLibraryValue);
        final currentCachedPaths = _existingImageLibraryPaths;
        final nextExistingPaths = {
          if (cachedExistingPaths != null && currentCachedPaths != null)
            for (final path in currentCachedPaths)
              if (currentPaths.contains(path)) path,
          for (final path in existingPaths)
            if (currentPaths.contains(path)) path,
        };
        final cachedPaths = _existingImageLibraryPaths;
        if (cachedPaths != null &&
            _stringSetEquals(cachedPaths, nextExistingPaths)) {
          return;
        }
        setState(() {
          _existingImageLibraryPaths = Set<String>.unmodifiable(
            nextExistingPaths,
          );
        });
      }),
    );
  }

  Future<Set<String>> _collectExistingImageLibraryPaths(
    Set<String> paths,
  ) async {
    final existingPaths = <String>{};
    for (final path in paths) {
      if (await _fileService.fileExists(path)) {
        existingPaths.add(path);
      }
    }
    return existingPaths;
  }

  bool _isImageLibraryItemAvailable(ImageLibraryItem item) {
    if (item.path.trim().isEmpty) {
      return false;
    }
    final existingPaths = _existingImageLibraryPaths;
    return existingPaths == null || existingPaths.contains(item.path);
  }

  Future<T?> _showImageLibraryPicker<T extends Object>({
    required String title,
    bool allowMultiple = false,
    List<ImageAssetKind>? allowedKinds,
  }) async {
    if (!mounted) {
      return null;
    }

    final candidates = _availableImageLibraryItems(allowedKinds: allowedKinds);
    if (candidates.isEmpty) {
      _showMessage('作品库还没有可用图片');
      return null;
    }

    return showImageLibraryPickerDialog<T>(
      context,
      title: title,
      items: candidates,
      allowMultiple: allowMultiple,
    );
  }

  List<ImageLibraryItem> _availableImageLibraryItems({
    List<ImageAssetKind>? allowedKinds,
  }) {
    return availableImageLibraryItems(
      _imageLibrary,
      allowedKinds: allowedKinds,
      itemExists: _isImageLibraryItemAvailable,
    );
  }

  Future<List<MapEntry<int, Uint8List>>?> _showSlicePicker(
    ImageLibraryItem sheet, {
    required bool allowMultiple,
    String? title,
  }) async {
    if (!sheet.isSpriteSheetWithMetadata) {
      _showMessage('该 Sprite Sheet 缺少行列元数据，无法切片');
      return null;
    }
    return showSpriteSheetSlicePicker(
      context,
      sheet: sheet,
      allowMultiple: allowMultiple,
      title: title,
    );
  }

  Future<ImageLibraryItem?> _saveSingleSliceItem(
    ImageLibraryItem sheet,
    int frameIndex,
    Uint8List bytes, {
    bool pushHistory = true,
  }) async {
    final groupId = sheet.groupId;
    if (groupId == null) {
      _showMessage('该 Sprite Sheet 缺少 groupId，无法保存切片');
      return null;
    }
    if (savedSpriteFrameIndexesForSheet(
      _imageLibrary,
      sheet,
    ).contains(frameIndex)) {
      return null;
    }
    try {
      final item = await _imageLibraryService.saveSpriteFrame(
        store: _store,
        sheet: sheet,
        frameIndex: frameIndex,
        bytes: bytes,
      );
      if (!mounted) {
        return null;
      }
      setState(() => _imageLibrary = [item, ..._imageLibrary]);
      if (pushHistory) {
        _pushImageLibraryAppendHistory(
          feature: WorkspaceFeature.imageLibrary,
          label: '保存「${sheet.displayTitle}」第 ${frameIndex + 1} 帧',
          appendedItems: [item],
        );
      }
      return item;
    } catch (error) {
      _showMessage('保存切片失败：$error');
      return null;
    }
  }

  Future<bool> _saveSingleSlice(
    ImageLibraryItem sheet,
    int frameIndex,
    Uint8List bytes,
  ) async {
    final item = await _saveSingleSliceItem(sheet, frameIndex, bytes);
    return item != null;
  }

  Future<int> _saveAllSlices(
    ImageLibraryItem sheet,
    List<MapEntry<int, Uint8List>> framesToSave,
  ) async {
    final savedItems = <ImageLibraryItem>[];
    for (final entry in framesToSave) {
      final item = await _saveSingleSliceItem(
        sheet,
        entry.key,
        entry.value,
        pushHistory: false,
      );
      if (item == null) {
        break;
      }
      savedItems.add(item);
    }
    final saved = savedItems.length;
    _pushImageLibraryAppendHistory(
      feature: WorkspaceFeature.imageLibrary,
      label: '保存「${sheet.displayTitle}」$saved 个切片帧',
      appendedItems: savedItems,
    );
    if (mounted) {
      _showMessage('已保存 $saved 个切片帧到作品集');
    }
    return saved;
  }

  Future<void> _openSliceExplorer(ImageLibraryItem sheet) async {
    if (!sheet.isSpriteSheetWithMetadata) {
      _showMessage('该作品缺少行列元数据，无法切片');
      return;
    }
    await showSpriteSheetSliceExplorer(
      context,
      sheet: sheet,
      savedFrameIndexes: savedSpriteFrameIndexesForSheet(_imageLibrary, sheet),
      onSaveSlice: (frameIndex, bytes) =>
          _saveSingleSlice(sheet, frameIndex, bytes),
      onSaveAllSlices: (frames) => _saveAllSlices(sheet, frames),
    );
  }

  Future<void> _updateImageLibraryItemMetadata(
    ImageLibraryItem item, {
    required String title,
    required String note,
    required String project,
    required List<String> tags,
  }) async {
    final before = item;
    final nextLibrary = await _imageLibraryService.updateItemMetadata(
      store: _store,
      library: _imageLibrary,
      itemId: item.id,
      title: title,
      note: note,
      project: project,
      tags: tags,
    );
    if (!mounted) {
      return;
    }

    final updated = nextLibrary.firstWhere(
      (entry) => entry.id == item.id,
      orElse: () => item,
    );
    setState(() => _imageLibrary = nextLibrary);

    final unchanged =
        updated.title == before.title &&
        updated.note == before.note &&
        updated.project == before.project &&
        _stringListEquals(updated.tags, before.tags);
    if (!unchanged) {
      _pushHistory(
        WorkspaceFeature.imageLibrary,
        HistoryAction(
          label: '编辑「${updated.displayTitle}」',
          apply: () async {
            if (!mounted) return;
            final redoLibrary = await _imageLibraryService.updateItemMetadata(
              store: _store,
              library: _imageLibrary,
              itemId: updated.id,
              title: updated.title,
              note: updated.note,
              project: updated.project,
              tags: updated.tags,
            );
            if (!mounted) return;
            setState(() => _imageLibrary = redoLibrary);
          },
          revert: () async {
            if (!mounted) return;
            final revertedLibrary = await _imageLibraryService
                .updateItemMetadata(
                  store: _store,
                  library: _imageLibrary,
                  itemId: before.id,
                  title: before.title,
                  note: before.note,
                  project: before.project,
                  tags: before.tags,
                );
            if (!mounted) return;
            setState(() => _imageLibrary = revertedLibrary);
          },
        ),
      );
    }
    _showMessage('作品信息已更新');
  }

  bool _stringListEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _stringSetEquals(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) {
        return false;
      }
    }
    return true;
  }

  List<ImageLibraryItem> _mergeImageLibraryState({
    required List<ImageLibraryItem> currentLibrary,
    List<ImageLibraryItem> appendedItems = const [],
    Set<String> removedItemIds = const {},
  }) {
    final appendedIds = {for (final item in appendedItems) item.id};
    return [
      ...appendedItems,
      for (final item in currentLibrary)
        if (!removedItemIds.contains(item.id) && !appendedIds.contains(item.id))
          item,
    ];
  }

  Future<void> _applyImageLibraryMerge({
    List<ImageLibraryItem> appendedItems = const [],
    Set<String> removedItemIds = const {},
    VoidCallback? updateState,
  }) async {
    final nextLibrary = _mergeImageLibraryState(
      currentLibrary: _imageLibrary,
      appendedItems: appendedItems,
      removedItemIds: removedItemIds,
    );
    await _store.saveImageLibrary(nextLibrary);
    if (!mounted) {
      return;
    }
    setState(() {
      _imageLibrary = nextLibrary;
      updateState?.call();
    });
  }

  void _pushImageLibraryAppendHistory({
    required WorkspaceFeature feature,
    required String label,
    required List<ImageLibraryItem> appendedItems,
    VoidCallback? applyState,
    VoidCallback? revertState,
  }) {
    if (appendedItems.isEmpty) {
      return;
    }

    _pushHistory(
      feature,
      HistoryAction(
        label: label,
        apply: () async {
          await _applyImageLibraryMerge(
            appendedItems: appendedItems,
            updateState: applyState,
          );
        },
        revert: () async {
          await _applyImageLibraryMerge(
            removedItemIds: {for (final item in appendedItems) item.id},
            updateState: revertState,
          );
        },
      ),
    );
  }

  Future<void> _showEditImageLibraryItemDialog(ImageLibraryItem item) async {
    final result = await showImageLibraryMetadataDialog(context, item);
    if (result == null || !mounted) {
      return;
    }

    await _updateImageLibraryItemMetadata(
      item,
      title: result.title,
      note: result.note,
      project: result.project,
      tags: result.tags,
    );
  }

  Future<void> _copyImageLibraryItemPath(ImageLibraryItem item) async {
    await _fileService.copyTextToClipboard(item.path);
    if (!mounted) {
      return;
    }
    _showMessage('作品路径已复制');
  }

  Future<void> _copyImageLibraryItemImage(ImageLibraryItem item) async {
    if (!await _fileService.fileExists(item.path)) {
      if (!mounted) {
        return;
      }
      _showMessage('作品文件不存在');
      return;
    }

    try {
      final result = await _fileService.copyImageFileToClipboard(item.path);
      if (!mounted) {
        return;
      }
      switch (result.status) {
        case ImageClipboardCopyStatus.imageCopied:
          _showMessage('图片已复制到剪贴板');
        case ImageClipboardCopyStatus.pathCopied:
          _showMessage('当前平台暂不支持直接复制图片，已复制图片路径');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('复制图片失败：$error');
    }
  }

  Future<void> _exportImageLibraryItemImage(ImageLibraryItem item) async {
    if (!await _fileService.fileExists(item.path)) {
      if (!mounted) {
        return;
      }
      _showMessage('作品文件不存在');
      return;
    }

    final location = await getSaveLocation(
      acceptedTypeGroups: imageTypeGroups,
      suggestedName: fileNameFromPath(item.path),
    );
    if (location == null || !mounted) {
      return;
    }

    try {
      final result = await _fileService.exportFileToPath(
        sourcePath: item.path,
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

  Future<void> _exportSelectedImageLibraryItems() async {
    final selectedIds = _selectedImageLibraryItemIds;
    final selectedItems = [
      for (final item in _imageLibrary)
        if (selectedIds.contains(item.id)) item,
    ];
    if (selectedItems.isEmpty) {
      _showMessage('请先选择要导出的作品');
      return;
    }

    if (selectedItems.length == 1) {
      await _exportImageLibraryItemImage(selectedItems.single);
      return;
    }

    final directoryPath = await getDirectoryPath(confirmButtonText: '导出到这里');
    if (directoryPath == null || !mounted) {
      return;
    }

    final existingItems = <ImageLibraryItem>[];
    var missingCount = 0;
    for (final item in selectedItems) {
      if (await _fileService.fileExists(item.path)) {
        existingItems.add(item);
      } else {
        missingCount += 1;
      }
    }
    if (existingItems.isEmpty) {
      _showMessage('选中的作品文件都不存在');
      return;
    }

    try {
      final results = await _fileService.exportFilesToDirectory(
        sourcePaths: existingItems.map((item) => item.path),
        directoryPath: directoryPath,
      );
      if (!mounted) {
        return;
      }
      final skipped = missingCount == 0 ? '' : '，跳过 $missingCount 个缺失文件';
      _showMessage('已导出 ${results.length} 个作品$skipped');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('导出已选作品失败：$error');
    }
  }

  Future<void> _openImageLibraryItemLocation(ImageLibraryItem item) async {
    final result = await _fileService.openFileLocation(item.path);
    if (!mounted) {
      return;
    }
    switch (result.status) {
      case OpenFileLocationStatus.opened:
        _showMessage('已打开作品所在位置');
      case OpenFileLocationStatus.directoryMissing:
        _showMessage('作品所在目录不存在');
      case OpenFileLocationStatus.copiedUnsupportedPlatform:
        _showMessage('已复制作品目录路径');
      case OpenFileLocationStatus.copiedAfterFailure:
        _showMessage('无法打开目录，已复制作品目录路径');
    }
  }

  ImageLibraryItem? _findImageLibraryItemByPath(String? path) {
    if (path == null) {
      return null;
    }
    for (final item in _imageLibrary) {
      if (item.path == path) {
        return item;
      }
    }
    return null;
  }

  Future<_TransparentBackgroundLibraryResult?> _saveTransparentBackgroundImage({
    required Uint8List sourceBytes,
    required int tolerance,
    ImageLibraryItem? sourceItem,
    String? fallbackTitle,
    String source = '背景转透明',
  }) async {
    final result =
        await BackgroundTransparencyService.makeBackgroundTransparentInBackground(
          sourceBytes,
          tolerance: tolerance,
        );
    if (result.transparentPixelCount == 0) {
      return null;
    }

    final groupId = 'transparent_${DateTime.now().microsecondsSinceEpoch}';
    final file = await _store.saveGeneratedImageBytes(
      groupId: groupId,
      index: 0,
      bytes: result.pngBytes,
    );
    if (!mounted) {
      return null;
    }

    final titleSource = sourceItem?.displayTitle ?? fallbackTitle ?? '图片';
    final item = await _imageLibraryService.addItem(
      store: _store,
      path: file.path,
      kind: sourceItem?.kind == ImageAssetKind.spriteSheet
          ? ImageAssetKind.spriteSheet
          : sourceItem?.kind == ImageAssetKind.editedImage
          ? ImageAssetKind.editedImage
          : sourceItem?.kind == ImageAssetKind.spriteFrame
          ? ImageAssetKind.spriteFrame
          : ImageAssetKind.generatedImage,
      title: '透明背景：$titleSource',
      source: source,
      prompt:
          '背景转透明 · 容差 $tolerance · '
          '${result.width} x ${result.height}',
      generation: sourceItem?.generation,
      groupId: sourceItem?.kind == ImageAssetKind.spriteSheet ? groupId : null,
      rows: sourceItem?.rows,
      columns: sourceItem?.columns,
      gridSpec: sourceItem?.gridSpec,
      frameWidth: sourceItem?.frameWidth,
      frameHeight: sourceItem?.frameHeight,
      frameIndex: sourceItem?.frameIndex,
    );
    if (!mounted) {
      return null;
    }

    setState(() => _imageLibrary = [item, ..._imageLibrary]);
    return _TransparentBackgroundLibraryResult(
      item: item,
      transparentPixelCount: result.transparentPixelCount,
    );
  }

  Future<void> _makeImageLibraryItemBackgroundTransparent(
    ImageLibraryItem item,
  ) async {
    if (!item.canMakeBackgroundTransparent) {
      _showMessage('该作品不是可处理的静态图片');
      return;
    }

    final tolerance = await showBackgroundTransparencyDialog(
      context,
      sourceTitle: item.displayTitle,
    );
    if (tolerance == null || !mounted) {
      return;
    }

    try {
      final sourceBytes = await _fileService.readFileBytes(item.path);
      final saved = await _saveTransparentBackgroundImage(
        sourceBytes: sourceBytes,
        tolerance: tolerance,
        sourceItem: item,
      );
      if (!mounted) {
        return;
      }
      if (saved == null) {
        _showMessage('没有检测到可透明化的边缘背景，可尝试调高容差');
        return;
      }
      _pushImageLibraryAppendHistory(
        feature: WorkspaceFeature.imageLibrary,
        label: '背景转透明：${item.displayTitle}',
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

  void _setImageLibraryKindFilter(ImageLibraryKindFilter filter) {
    setState(() {
      _imageLibraryKindFilter = filter;
      _selectedImageLibraryItemIds = <String>{};
    });
  }

  void _setImageLibrarySortOrder(ImageLibrarySortOrder sortOrder) {
    setState(() => _imageLibrarySortOrder = sortOrder);
  }

  void _setImageLibrarySearchQuery(String value) {
    setState(() {
      _imageLibrarySearchQuery = value;
      _selectedImageLibraryItemIds = <String>{};
    });
  }

  void _setImageLibraryProjectFilter(String value) {
    setState(() {
      _imageLibraryProjectFilter = value;
      _selectedImageLibraryItemIds = <String>{};
    });
  }

  void _setImageLibraryTagFilter(String value) {
    setState(() {
      _imageLibraryTagFilter = value;
      _selectedImageLibraryItemIds = <String>{};
    });
  }

  void _clearImageLibrarySearchQuery() {
    _imageLibrarySearchController.clear();
    _setImageLibrarySearchQuery('');
  }

  void _setImageLibraryItemSelected(ImageLibraryItem item, bool selected) {
    setState(() {
      final nextSelection = Set<String>.from(_selectedImageLibraryItemIds);
      if (selected) {
        nextSelection.add(item.id);
      } else {
        nextSelection.remove(item.id);
      }
      _selectedImageLibraryItemIds = nextSelection;
    });
  }

  void _selectVisibleImageLibraryItems(List<ImageLibraryItem> items) {
    if (items.isEmpty) {
      return;
    }

    setState(() {
      _selectedImageLibraryItemIds = {
        ..._selectedImageLibraryItemIds,
        for (final item in items) item.id,
      };
    });
  }

  void _clearImageLibrarySelection() {
    setState(() => _selectedImageLibraryItemIds = <String>{});
  }

  Future<void> _confirmDeleteImageLibraryItem(String id) async {
    final items = [
      for (final item in _imageLibrary)
        if (item.id == id) item,
    ];
    await _confirmDeleteImageLibraryItems(items);
  }

  Future<void> _confirmDeleteSelectedImageLibraryItems() async {
    final selectedIds = _selectedImageLibraryItemIds;
    final items = [
      for (final item in _imageLibrary)
        if (selectedIds.contains(item.id)) item,
    ];
    await _confirmDeleteImageLibraryItems(items);
  }

  Future<void> _confirmDeleteImageLibraryItems(
    List<ImageLibraryItem> items,
  ) async {
    if (items.isEmpty) {
      return;
    }

    final plan = buildImageLibraryDeletePlan(
      library: _imageLibrary,
      selectedItems: items,
    );

    final confirmed = await confirmDeleteImageLibraryItemsDialog(
      context,
      items: items,
      cascadeCount: plan.cascadeChildFrames.length,
    );
    if (!confirmed || !mounted) {
      return;
    }

    await _deleteImageLibraryItems(plan.ids);
  }

  Future<void> _deleteImageLibraryItems(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final beforeSelectedIds = _selectedImageLibraryItemIds;
    final beforeEditorImagePath = _editorImagePath;
    final beforeEditorPatchImagePath = _editorPatchImagePath;
    final beforeAnimationTemplateImagePath = _animationTemplateImagePath;
    final beforeGifSourceFrames = _gifSourceFrames;

    final impact = await _imageLibraryService.deleteItems(
      store: _store,
      fileService: _fileService,
      library: _imageLibrary,
      ids: ids,
    );

    if (!mounted) {
      return;
    }
    final cleanup = cleanDeletedImageLibraryReferences(
      removedIds: ids,
      removedPaths: impact.removedPaths,
      selectedItemIds: _selectedImageLibraryItemIds,
      editorImagePath: _editorImagePath,
      editorPatchImagePath: _editorPatchImagePath,
      animationTemplateImagePath: _animationTemplateImagePath,
      gifSourceFrames: _gifSourceFrames,
    );
    setState(() {
      _imageLibrary = impact.remainingItems;
      _selectedImageLibraryItemIds = cleanup.selectedItemIds;
      _editorImagePath = cleanup.editorImagePath;
      _editorPatchImagePath = cleanup.editorPatchImagePath;
      _animationTemplateImagePath = cleanup.animationTemplateImagePath;
      _gifSourceFrames = cleanup.gifSourceFrames;
    });

    final removedItems = List<ImageLibraryItem>.unmodifiable(
      impact.removedItems,
    );
    if (removedItems.isNotEmpty) {
      var trashPaths = impact.trashPaths;
      _pushHistory(
        WorkspaceFeature.imageLibrary,
        HistoryAction(
          label: removedItems.length == 1
              ? '删除「${removedItems.first.displayTitle}」'
              : '删除 ${removedItems.length} 个作品',
          apply: () async {
            if (!mounted) return;
            final redoImpact = await _imageLibraryService.deleteItems(
              store: _store,
              fileService: _fileService,
              library: _imageLibrary,
              ids: removedItems.map((item) => item.id).toSet(),
            );
            if (!mounted) return;
            final redoCleanup = cleanDeletedImageLibraryReferences(
              removedIds: redoImpact.removedItems
                  .map((item) => item.id)
                  .toSet(),
              removedPaths: redoImpact.removedPaths,
              selectedItemIds: _selectedImageLibraryItemIds,
              editorImagePath: _editorImagePath,
              editorPatchImagePath: _editorPatchImagePath,
              animationTemplateImagePath: _animationTemplateImagePath,
              gifSourceFrames: _gifSourceFrames,
            );
            trashPaths = redoImpact.trashPaths;
            setState(() {
              _imageLibrary = redoImpact.remainingItems;
              _selectedImageLibraryItemIds = redoCleanup.selectedItemIds;
              _editorImagePath = redoCleanup.editorImagePath;
              _editorPatchImagePath = redoCleanup.editorPatchImagePath;
              _animationTemplateImagePath =
                  redoCleanup.animationTemplateImagePath;
              _gifSourceFrames = redoCleanup.gifSourceFrames;
            });
          },
          revert: () async {
            if (!mounted) return;
            final restoredLibrary = await _imageLibraryService.restoreItems(
              store: _store,
              fileService: _fileService,
              currentLibrary: _imageLibrary,
              removedItems: removedItems,
              trashPaths: trashPaths,
            );
            if (!mounted) return;
            setState(() {
              _imageLibrary = restoredLibrary;
              _selectedImageLibraryItemIds = beforeSelectedIds;
              _editorImagePath = beforeEditorImagePath;
              _editorPatchImagePath = beforeEditorPatchImagePath;
              _animationTemplateImagePath = beforeAnimationTemplateImagePath;
              _gifSourceFrames = beforeGifSourceFrames;
            });
          },
        ),
      );
    }

    _showMessage(
      impact.removedItems.length == 1
          ? '作品已删除'
          : '已删除 ${impact.removedItems.length} 个作品',
    );
  }

  Future<void> _useImageLibraryItemInEditor(ImageLibraryItem item) async {
    if (!item.canUseAsSpriteSheet) {
      _showMessage('这类作品不能直接作为 Sprite Sheet 编辑');
      return;
    }
    final before = _captureEditorSource();
    await _selectFeature(WorkspaceFeature.imageEditor);
    if (!mounted) {
      return;
    }
    setState(() {
      _editorImagePath = item.path;
      if (item.isSpriteSheetWithMetadata) {
        final gridSpec = item.effectiveGridSpec;
        _editorRows = gridSpec.rows;
        _editorColumns = gridSpec.columns;
        _editorGridSpec = gridSpec;
      }
      _editorErrorMessage = null;
    });
    _pushEditorSourceHistory(
      label: '在编辑器中打开「${item.displayTitle}」',
      before: before,
    );
  }

  _GenerationReuseSnapshot _captureGenerationReuseSnapshot() {
    final draft = _currentApiConfigDraft;
    return _GenerationReuseSnapshot(
      apiConfigs: List<ApiConfig>.unmodifiable(
        upsertApiConfig(_apiConfigs, draft),
      ),
      selectedApiConfigId: draft.id,
      apiConfigProviderKind: _apiConfigProviderKind,
      imageSizeCapabilityOverride: _imageSizeCapabilityOverride,
      apiConfigName: _apiConfigNameController.text,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
      generationTimeout: _generationTimeoutController.text,
      prompt: _promptController.text,
      negativePrompt: _negativePromptController.text,
      user: _userController.text,
      size: _size,
      imageCount: _imageCount,
      advancedSettings: _advancedSettings,
      errorMessage: _errorMessage,
    );
  }

  Future<void> _restoreGenerationReuseSnapshot(
    _GenerationReuseSnapshot snapshot,
  ) async {
    if (!mounted) {
      return;
    }

    _settingsSaveDebounce?.cancel();
    _apiConfigSaveDebounce?.cancel();
    _isRestoringState = true;
    try {
      _apiConfigNameController.text = snapshot.apiConfigName;
      _baseUrlController.text = snapshot.baseUrl;
      _apiKeyController.text = snapshot.apiKey;
      _modelController.text = snapshot.model;
      _generationTimeoutController.text = snapshot.generationTimeout;
      _setControllerText(
        controller: _promptController,
        value: snapshot.prompt,
        remember: (value) => _lastPromptText = value,
      );
      _setControllerText(
        controller: _negativePromptController,
        value: snapshot.negativePrompt,
        remember: (value) => _lastNegativePromptText = value,
      );
      _userController.text = snapshot.user;

      setState(() {
        _apiConfigs = snapshot.apiConfigs;
        _selectedApiConfigId = snapshot.selectedApiConfigId;
        _apiConfigProviderKind = snapshot.apiConfigProviderKind;
        _imageSizeCapabilityOverride = snapshot.imageSizeCapabilityOverride;
        _apiConfigSaveStatus = ApiConfigSaveStatus.saved;
        _apiConfigSaveErrorMessage = null;
        _size = snapshot.size;
        _imageCount = normalizeImageGenerationTargetCount(snapshot.imageCount);
        _advancedSettings = snapshot.advancedSettings;
        _errorMessage = snapshot.errorMessage;
      });
    } finally {
      _isRestoringState = false;
    }

    await _store.saveApiConfigs(snapshot.apiConfigs);
    await _store.saveSelectedApiConfigId(snapshot.selectedApiConfigId);
    await _saveSettings();
  }

  void _pushGenerationReuseHistory({
    required String label,
    required _GenerationReuseSnapshot before,
  }) {
    final after = _captureGenerationReuseSnapshot();
    if (before == after) {
      return;
    }

    _pushHistory(
      WorkspaceFeature.imageGeneration,
      HistoryAction(
        label: label,
        apply: () => _restoreGenerationReuseSnapshot(after),
        revert: () => _restoreGenerationReuseSnapshot(before),
      ),
    );
  }

  Future<void> _reuseImageLibraryGeneration(ImageLibraryItem item) async {
    final generation = item.generation;
    if (generation == null) {
      _showMessage('这个作品没有可复用的生成参数');
      return;
    }

    _flushPendingGenerationTextHistory();
    final before = _captureGenerationReuseSnapshot();
    if (_selectedFeature != WorkspaceFeature.imageGeneration) {
      await _selectFeature(WorkspaceFeature.imageGeneration);
      if (!mounted) {
        return;
      }
    }

    _isRestoringState = true;
    final draft = buildImageLibraryGenerationReuseDraft(
      generation: generation,
      apiConfigs: _apiConfigs,
    );
    final matchingConfigId = draft.matchingConfigId;

    try {
      _setControllerText(
        controller: _promptController,
        value: generation.prompt,
        remember: (value) => _lastPromptText = value,
      );
      _setControllerText(
        controller: _negativePromptController,
        value: generation.negativePrompt,
        remember: (value) => _lastNegativePromptText = value,
      );
      _userController.text = generation.advancedSettings.user;

      setState(() {
        if (matchingConfigId != null) {
          _selectedApiConfigId = matchingConfigId;
        }
        _size = safeImageSizeForModel(
          size: draft.size,
          providerKind: matchingConfigId != null
              ? resolveApiConfig(_apiConfigs, matchingConfigId).providerKind
              : _apiConfigProviderKind,
          model: matchingConfigId != null
              ? resolveApiConfig(_apiConfigs, matchingConfigId).model
              : _modelController.text,
          capabilityOverride: matchingConfigId != null
              ? resolveApiConfig(
                  _apiConfigs,
                  matchingConfigId,
                ).imageSizeCapabilityOverride
              : _imageSizeCapabilityOverride,
        );
        _imageCount = normalizeImageGenerationTargetCount(draft.imageCount);
        _advancedSettings = draft.advancedSettings;
        _errorMessage = null;
      });
    } finally {
      _isRestoringState = false;
    }
    if (matchingConfigId != null) {
      await _selectApiConfig(matchingConfigId);
    }
    await _saveSettings();
    _pushGenerationReuseHistory(
      label: '复用「${item.displayTitle}」生成参数',
      before: before,
    );
    _showMessage(matchingConfigId == null ? '已载入作品参数，接口配置需要手动选择' : '已载入作品参数');
  }

  Future<void> _copyImageLibraryGeneration(ImageLibraryItem item) async {
    final generation = item.generation;
    if (generation == null) {
      _showMessage('这个作品没有可复制的生成参数');
      return;
    }

    await _fileService.copyTextToClipboard(
      formatGenerationSnapshotSummary(generation),
    );
    if (!mounted) {
      return;
    }
    _showMessage('作品参数已复制');
  }

  Widget _buildImageLibraryWorkspace() {
    final viewData = buildImageLibraryViewData(
      library: _imageLibrary,
      filter: _imageLibraryKindFilter,
      sortOrder: _imageLibrarySortOrder,
      searchQuery: _imageLibrarySearchQuery,
      showStandaloneFrames: _showStandaloneSpriteFrames,
      projectFilter: _imageLibraryProjectFilter,
      tagFilter: _imageLibraryTagFilter,
      itemExists: _isImageLibraryItemAvailable,
    );

    return ImageLibraryWorkspace(
      viewData: viewData,
      searchController: _imageLibrarySearchController,
      searchQuery: _imageLibrarySearchQuery,
      selectedFilter: _imageLibraryKindFilter,
      onSearchChanged: _setImageLibrarySearchQuery,
      onClearSearch: _clearImageLibrarySearchQuery,
      onFilterChanged: _setImageLibraryKindFilter,
      selectedProject: _imageLibraryProjectFilter,
      onProjectChanged: _setImageLibraryProjectFilter,
      selectedTag: _imageLibraryTagFilter,
      onTagChanged: _setImageLibraryTagFilter,
      sortOrder: _imageLibrarySortOrder,
      onSortOrderChanged: _setImageLibrarySortOrder,
      selectedItemIds: _selectedImageLibraryItemIds,
      onSelectionChanged: _setImageLibraryItemSelected,
      onSelectVisible: () =>
          _selectVisibleImageLibraryItems(viewData.filteredItems),
      onClearSelection: _clearImageLibrarySelection,
      onDeleteSelected: _confirmDeleteSelectedImageLibraryItems,
      onExportSelected: () => unawaited(_exportSelectedImageLibraryItems()),
      onUseInEditor: _useImageLibraryItemInEditor,
      onReuseGeneration: _reuseImageLibraryGeneration,
      onCopyGeneration: _copyImageLibraryGeneration,
      onMakeBackgroundTransparent: (item) =>
          unawaited(_makeImageLibraryItemBackgroundTransparent(item)),
      onEditMetadata: _showEditImageLibraryItemDialog,
      onCopyImage: (item) => unawaited(_copyImageLibraryItemImage(item)),
      onExportImage: (item) => unawaited(_exportImageLibraryItemImage(item)),
      onCopyPath: _copyImageLibraryItemPath,
      onOpenLocation: _openImageLibraryItemLocation,
      onDelete: _confirmDeleteImageLibraryItem,
      onOpenSliceExplorer: _openSliceExplorer,
      showStandaloneFrames: _showStandaloneSpriteFrames,
      onToggleStandaloneFrames: (value) =>
          setState(() => _showStandaloneSpriteFrames = value),
    );
  }
}

class _TransparentBackgroundLibraryResult {
  const _TransparentBackgroundLibraryResult({
    required this.item,
    required this.transparentPixelCount,
  });

  final ImageLibraryItem item;
  final int transparentPixelCount;
}
