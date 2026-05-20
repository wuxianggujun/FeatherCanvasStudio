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
  set _generalEditorImagePath(String? value);
  set _generalEditorImageInfo(ImageInspectionResult? value);
  set _generalEditorErrorMessage(String? value);
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
  String? get _imageTemplateImagePath;
  set _imageTemplateImagePath(String? value);
  set _editorErrorMessage(String? value);
  String? get _errorMessage;
  set _errorMessage(String? value);
  AnimationProjectStore get _animationProjectStore;
  AnimationProject? get _animationProject;
  set _animationProject(AnimationProject? value);
  String? get _selectedAnimationTrackId;
  set _selectedAnimationTrackId(String? value);
  set _animationProjectErrorMessage(String? value);
  @override
  Future<void> _selectFeature(WorkspaceFeature feature);
  @override
  void _showMessage(String message);
  @override
  Widget _buildCompactHistoryControls();
  @override
  void _pushHistory(WorkspaceFeature feature, HistoryAction action);

  ImageLibraryNotifier get _imageLibraryNotifier;
  final TextEditingController _imageLibrarySearchController =
      TextEditingController();
  final ImageLibraryFileService _fileService = const ImageLibraryFileService();
  final ImageLibraryService _imageLibraryService = const ImageLibraryService();

  Set<String>? _existingImageLibraryPaths;
  Set<String> _imageLibraryExistenceRefreshPaths = const <String>{};
  int _imageLibraryExistenceRefreshToken = 0;

  @override
  List<ImageLibraryItem> get _imageLibrary => _imageLibraryNotifier.items;

  @override
  set _imageLibrary(List<ImageLibraryItem> value) {
    final previousPaths = _imageLibraryPathSet(_imageLibraryNotifier.items);
    final nextPaths = _imageLibraryPathSet(value);
    _imageLibraryNotifier.items = value;
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
        final currentPaths = _imageLibraryPathSet(_imageLibraryNotifier.items);
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
      _showMessage(appL10nOf(context).imageLibraryStateNoAvailableImages);
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
      _showMessage(appL10nOf(context).imageLibraryStateSpriteSheetMissingGrid);
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
      _showMessage(appL10nOf(context).imageLibraryStateSpriteSheetMissingGroup);
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
        labels: imageLibrarySpriteFrameLabels(
          appL10nOf(context),
          sheetTitle: sheet.displayTitle,
          frameIndex: frameIndex + 1,
        ),
      );
      if (!mounted) {
        return null;
      }
      _imageLibrary = [item, ..._imageLibrary];
      if (pushHistory) {
        _pushImageLibraryAppendHistory(
          feature: WorkspaceFeature.imageLibrary,
          label: appL10nOf(context).imageLibraryStateSaveSliceHistory(
            sheet.displayTitle,
            frameIndex + 1,
          ),
          appendedItems: [item],
        );
      }
      return item;
    } catch (error) {
      _showMessage(appL10nOf(context).imageLibraryStateSaveSliceFailed(error));
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
    final l10n = appL10nOf(context);
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
      label: l10n.imageLibraryStateSaveSlicesHistory(sheet.displayTitle, saved),
      appendedItems: savedItems,
    );
    if (mounted) {
      _showMessage(l10n.imageLibraryStateSavedSlicesMessage(saved));
    }
    return saved;
  }

  Future<void> _openSliceExplorer(ImageLibraryItem sheet) async {
    if (!sheet.isSpriteSheetWithMetadata) {
      _showMessage(appL10nOf(context).imageLibraryStateItemMissingGrid);
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
    _imageLibrary = nextLibrary;

    final unchanged =
        updated.title == before.title &&
        updated.note == before.note &&
        updated.project == before.project &&
        _stringListEquals(updated.tags, before.tags);
    if (!unchanged) {
      _pushHistory(
        WorkspaceFeature.imageLibrary,
        HistoryAction(
          label: appL10nOf(
            context,
          ).imageLibraryStateEditMetadataHistory(updated.displayTitle),
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
            _imageLibrary = redoLibrary;
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
            _imageLibrary = revertedLibrary;
          },
        ),
      );
    }
    _showMessage(appL10nOf(context).imageLibraryStateMetadataUpdated);
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
    _showMessage(appL10nOf(context).imageLibraryStatePathCopied);
  }

  Future<void> _copyImageLibraryItemImage(ImageLibraryItem item) async {
    final l10n = appL10nOf(context);
    if (!await _fileService.fileExists(item.path)) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.imageLibraryStateFileMissing);
      return;
    }

    try {
      final result = await _fileService.copyImageFileToClipboard(item.path);
      if (!mounted) {
        return;
      }
      switch (result.status) {
        case ImageClipboardCopyStatus.imageCopied:
          _showMessage(l10n.imageLibraryStateImageCopied);
        case ImageClipboardCopyStatus.pathCopied:
          _showMessage(l10n.imageLibraryStateImagePathCopied);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.copyImageFailed(error));
    }
  }

  Future<void> _exportImageLibraryItemImage(ImageLibraryItem item) async {
    final l10n = appL10nOf(context);
    if (!await _fileService.fileExists(item.path)) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.imageLibraryStateFileMissing);
      return;
    }

    final isAnimationProject = item.kind == ImageAssetKind.animationProject;
    final location = await getSaveLocation(
      acceptedTypeGroups: isAnimationProject
          ? animationProjectTypeGroups
          : imageTypeGroups,
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
      _showMessage(
        isAnimationProject
            ? l10n.imageLibraryStateAnimationProjectExported(
                fileNameFromPath(result.destinationPath),
              )
            : l10n.imageLibraryStateImageExported(
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

  Future<void> _exportSelectedImageLibraryItems() async {
    final l10n = appL10nOf(context);
    final selectedIds = _selectedImageLibraryItemIds;
    final selectedItems = [
      for (final item in _imageLibrary)
        if (selectedIds.contains(item.id)) item,
    ];
    if (selectedItems.isEmpty) {
      _showMessage(l10n.imageLibraryStateSelectItemsToExport);
      return;
    }

    if (selectedItems.length == 1) {
      await _exportImageLibraryItemImage(selectedItems.single);
      return;
    }

    final directoryPath = await getDirectoryPath(
      confirmButtonText: l10n.imageLibraryStateExportHere,
    );
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
      _showMessage(l10n.imageLibraryStateSelectedFilesMissing);
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
      final skipped = missingCount == 0
          ? ''
          : l10n.imageLibraryStateSkippedMissingFiles(missingCount);
      _showMessage(
        l10n.imageLibraryStateExportedSelected(results.length, skipped),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.imageLibraryStateExportSelectedFailed(error));
    }
  }

  Future<void> _openImageLibraryItemLocation(ImageLibraryItem item) async {
    final result = await _fileService.openFileLocation(item.path);
    if (!mounted) {
      return;
    }
    switch (result.status) {
      case OpenFileLocationStatus.opened:
        _showMessage(appL10nOf(context).imageLibraryStateLocationOpened);
      case OpenFileLocationStatus.directoryMissing:
        _showMessage(appL10nOf(context).imageLibraryStateDirectoryMissing);
      case OpenFileLocationStatus.copiedUnsupportedPlatform:
        _showMessage(appL10nOf(context).imageLibraryStateDirectoryPathCopied);
      case OpenFileLocationStatus.copiedAfterFailure:
        _showMessage(
          appL10nOf(context).imageLibraryStateDirectoryOpenFailedPathCopied,
        );
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

  Future<void> _openAnimationProjectFromLibrary(ImageLibraryItem item) async {
    final l10n = appL10nOf(context);
    if (item.kind != ImageAssetKind.animationProject) {
      _showMessage(l10n.imageLibraryStateNotAnimationProject);
      return;
    }
    if (!await _fileService.fileExists(item.path)) {
      if (mounted) {
        setState(() {
          _animationProjectErrorMessage = l10n
              .imageLibraryStateAnimationProjectFileMissingDetail(item.path);
        });
      }
      _showMessage(l10n.imageLibraryStateAnimationProjectFileMissing);
      return;
    }

    final beforeProject = _animationProject;
    final beforeTrackId = _selectedAnimationTrackId;
    try {
      final project = await _animationProjectStore.loadProject(item.path);
      if (!mounted) {
        return;
      }
      await _selectFeature(WorkspaceFeature.animationProject);
      if (!mounted) {
        return;
      }
      final nextTrackId = project.tracks.isEmpty
          ? null
          : project.tracks.first.id;
      setState(() {
        _animationProject = project;
        _selectedAnimationTrackId = nextTrackId;
        _animationProjectErrorMessage = null;
      });
      _pushHistory(
        WorkspaceFeature.animationProject,
        HistoryAction(
          label: l10n.imageLibraryStateOpenAnimationProjectHistory(
            project.title,
          ),
          apply: () async {
            if (!mounted) return;
            setState(() {
              _animationProject = project;
              _selectedAnimationTrackId = nextTrackId;
              _animationProjectErrorMessage = null;
            });
          },
          revert: () async {
            if (!mounted) return;
            setState(() {
              _animationProject = beforeProject;
              _selectedAnimationTrackId = beforeTrackId;
              _animationProjectErrorMessage = null;
            });
          },
        ),
      );
      _showMessage(l10n.imageLibraryStateAnimationProjectOpened(project.title));
    } on ImageGenerationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _animationProjectErrorMessage = error.message;
      });
      _showMessage(
        l10n.imageLibraryStateOpenAnimationProjectFailed(error.message),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _animationProjectErrorMessage = l10n
            .imageLibraryStateOpenAnimationProjectFailed(error);
      });
      _showMessage(l10n.imageLibraryStateOpenAnimationProjectFailed(error));
    }
  }

  Future<_TransparentBackgroundLibraryResult?> _saveTransparentBackgroundImage({
    required Uint8List sourceBytes,
    required int tolerance,
    ImageLibraryItem? sourceItem,
    String? fallbackTitle,
    String? source,
  }) async {
    final l10n = appL10nOf(context);
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

    final titleSource =
        sourceItem?.displayTitle ?? fallbackTitle ?? l10n.imageLabel;
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
      title: l10n.imageLibraryStateTransparentBackgroundTitle(titleSource),
      source: source ?? l10n.backgroundTransparencyTitle,
      prompt: l10n.imageLibraryStateTransparentBackgroundPrompt(
        tolerance,
        result.width,
        result.height,
      ),
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

    _imageLibrary = [item, ..._imageLibrary];
    return _TransparentBackgroundLibraryResult(
      item: item,
      transparentPixelCount: result.transparentPixelCount,
    );
  }

  Future<void> _makeImageLibraryItemBackgroundTransparent(
    ImageLibraryItem item,
  ) async {
    final l10n = appL10nOf(context);
    if (!item.canMakeBackgroundTransparent) {
      _showMessage(l10n.imageLibraryStateNotProcessableStaticImage);
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
        _showMessage(l10n.backgroundTransparencyNoEdgeDetected);
        return;
      }
      _pushImageLibraryAppendHistory(
        feature: WorkspaceFeature.imageLibrary,
        label: l10n.imageGenerationTransparentBackgroundHistory(
          item.displayTitle,
        ),
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
      _showMessage(l10n.backgroundTransparencyFailed(error));
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
    final beforeImageTemplateImagePath = _imageTemplateImagePath;
    final beforeAnimationTemplateImagePath = _animationTemplateImagePath;
    final beforeAnimationProject = _animationProject;
    final beforeSelectedAnimationTrackId = _selectedAnimationTrackId;

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
      imageTemplateImagePath: _imageTemplateImagePath,
      animationTemplateImagePath: _animationTemplateImagePath,
    );
    final removesOpenAnimationProject =
        _animationProject != null &&
        impact.removedItems.any(
          (item) =>
              item.kind == ImageAssetKind.animationProject &&
              item.groupId == _animationProject!.id,
        );
    setState(() {
      _imageLibrary = impact.remainingItems;
      _selectedImageLibraryItemIds = cleanup.selectedItemIds;
      _editorImagePath = cleanup.editorImagePath;
      _editorPatchImagePath = cleanup.editorPatchImagePath;
      _imageTemplateImagePath = cleanup.imageTemplateImagePath;
      _animationTemplateImagePath = cleanup.animationTemplateImagePath;
      if (removesOpenAnimationProject) {
        _animationProject = null;
        _selectedAnimationTrackId = null;
        _animationProjectErrorMessage = null;
      }
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
              ? appL10nOf(context).imageLibraryStateDeleteOneHistory(
                  removedItems.first.displayTitle,
                )
              : appL10nOf(
                  context,
                ).imageLibraryStateDeleteManyHistory(removedItems.length),
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
              imageTemplateImagePath: _imageTemplateImagePath,
              animationTemplateImagePath: _animationTemplateImagePath,
            );
            trashPaths = redoImpact.trashPaths;
            setState(() {
              _imageLibrary = redoImpact.remainingItems;
              _selectedImageLibraryItemIds = redoCleanup.selectedItemIds;
              _editorImagePath = redoCleanup.editorImagePath;
              _editorPatchImagePath = redoCleanup.editorPatchImagePath;
              _imageTemplateImagePath = redoCleanup.imageTemplateImagePath;
              _animationTemplateImagePath =
                  redoCleanup.animationTemplateImagePath;
              if (removesOpenAnimationProject) {
                _animationProject = null;
                _selectedAnimationTrackId = null;
                _animationProjectErrorMessage = null;
              }
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
              _imageTemplateImagePath = beforeImageTemplateImagePath;
              _animationTemplateImagePath = beforeAnimationTemplateImagePath;
              _animationProject = beforeAnimationProject;
              _selectedAnimationTrackId = beforeSelectedAnimationTrackId;
              _animationProjectErrorMessage = null;
            });
          },
        ),
      );
    }

    _showMessage(
      impact.removedItems.length == 1
          ? appL10nOf(context).imageLibraryStateDeletedOne
          : appL10nOf(
              context,
            ).imageLibraryStateDeletedMany(impact.removedItems.length),
    );
  }

  Future<void> _useImageLibraryItemInEditor(ImageLibraryItem item) async {
    final l10n = appL10nOf(context);
    if (!item.canUseAsSpriteSheet) {
      if (!item.isImageFile || item.kind == ImageAssetKind.gif) {
        _showMessage(l10n.imageLibraryStateUnsupportedEditorSource);
        return;
      }
      await _selectFeature(WorkspaceFeature.imageEditor);
      if (!mounted) {
        return;
      }
      try {
        final bytes = await _fileService.readFileBytes(item.path);
        final info = await GeneralImageEditingService.inspectInBackground(
          bytes,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _generalEditorImagePath = item.path;
          _generalEditorImageInfo = info;
          _generalEditorErrorMessage = null;
        });
        _showMessage(l10n.imageLibraryStateOpenedInEditor(item.displayTitle));
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _generalEditorImagePath = item.path;
          _generalEditorImageInfo = null;
          _generalEditorErrorMessage = l10n.editorGifImageReadFailedMessage(
            error,
          );
        });
      }
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
      label: l10n.imageLibraryStateOpenInEditorHistory(item.displayTitle),
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
    final l10n = appL10nOf(context);
    final generation = item.generation;
    if (generation == null) {
      _showMessage(l10n.imageLibraryStateNoReusableGeneration);
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
      label: l10n.imageLibraryStateReuseGenerationHistory(item.displayTitle),
      before: before,
    );
    _showMessage(
      matchingConfigId == null
          ? l10n.imageLibraryStateGenerationLoadedNeedsApiConfig
          : l10n.imageLibraryStateGenerationLoaded,
    );
  }

  Future<void> _copyImageLibraryGeneration(ImageLibraryItem item) async {
    final l10n = appL10nOf(context);
    final generation = item.generation;
    if (generation == null) {
      _showMessage(l10n.imageLibraryStateNoCopyableGeneration);
      return;
    }

    await _fileService.copyTextToClipboard(
      formatGenerationSnapshotSummary(generation),
    );
    if (!mounted) {
      return;
    }
    _showMessage(l10n.imageLibraryStateGenerationCopied);
  }

  Widget _buildImageLibraryWorkspace() {
    return ImageLibraryWorkspace(
      historyControls: _buildCompactHistoryControls(),
      itemExists: _isImageLibraryItemAvailable,
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
      onSelectVisible: _selectVisibleImageLibraryItems,
      onClearSelection: _clearImageLibrarySelection,
      onDeleteSelected: _confirmDeleteSelectedImageLibraryItems,
      onExportSelected: () => unawaited(_exportSelectedImageLibraryItems()),
      onOpenAnimationProject: (item) =>
          unawaited(_openAnimationProjectFromLibrary(item)),
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
