part of 'package:feather_canvas_studio/main.dart';

mixin _ImageLibraryStateMixin
    on
        State<FeatherCanvasHomePage>,
        _ApiConfigStateMixin,
        _LocalSettingsStateMixin {
  @override
  AppLocalStore get _store;
  WorkspaceFeature get _selectedFeature;
  @override
  bool get _isRestoringState;
  @override
  set _isRestoringState(bool value);
  String? get _editorImagePath;
  set _editorImagePath(String? value);
  String? get _editorPatchImagePath;
  set _editorPatchImagePath(String? value);
  String? get _animationTemplateImagePath;
  set _animationTemplateImagePath(String? value);
  set _editorErrorMessage(String? value);
  set _errorMessage(String? value);
  List<GifSourceFrame> get _gifSourceFrames;
  set _gifSourceFrames(List<GifSourceFrame> value);
  @override
  Future<void> _selectFeature(WorkspaceFeature feature);
  @override
  void _showMessage(String message);

  final TextEditingController _imageLibrarySearchController =
      TextEditingController();
  final ImageLibraryFileService _fileService = const ImageLibraryFileService();
  final ImageLibraryService _imageLibraryService = const ImageLibraryService();

  @override
  List<ImageLibraryItem> _imageLibrary = const [];
  ImageLibraryKindFilter _imageLibraryKindFilter = ImageLibraryKindFilter.all;
  ImageLibrarySortOrder _imageLibrarySortOrder = ImageLibrarySortOrder.newest;
  String _imageLibrarySearchQuery = '';
  Set<String> _selectedImageLibraryItemIds = <String>{};
  bool _showStandaloneSpriteFrames = false;

  void _disposeImageLibraryState() {
    _imageLibrarySearchController.dispose();
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

  Future<bool> _saveSingleSlice(
    ImageLibraryItem sheet,
    int frameIndex,
    Uint8List bytes,
  ) async {
    final groupId = sheet.groupId;
    if (groupId == null) {
      _showMessage('该 Sprite Sheet 缺少 groupId，无法保存切片');
      return false;
    }
    if (savedSpriteFrameIndexesForSheet(
      _imageLibrary,
      sheet,
    ).contains(frameIndex)) {
      return false;
    }
    try {
      final item = await _imageLibraryService.saveSpriteFrame(
        store: _store,
        sheet: sheet,
        frameIndex: frameIndex,
        bytes: bytes,
      );
      if (!mounted) {
        return false;
      }
      setState(() => _imageLibrary = [item, ..._imageLibrary]);
      return true;
    } catch (error) {
      _showMessage('保存切片失败：$error');
      return false;
    }
  }

  Future<int> _saveAllSlices(
    ImageLibraryItem sheet,
    List<MapEntry<int, Uint8List>> framesToSave,
  ) async {
    var saved = 0;
    for (final entry in framesToSave) {
      final ok = await _saveSingleSlice(sheet, entry.key, entry.value);
      if (!ok) {
        break;
      }
      saved++;
    }
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
  }) async {
    final nextLibrary = await _imageLibraryService.updateItemMetadata(
      store: _store,
      library: _imageLibrary,
      itemId: item.id,
      title: title,
      note: note,
    );
    if (!mounted) {
      return;
    }

    setState(() => _imageLibrary = nextLibrary);
    _showMessage('作品信息已更新');
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
    );
  }

  Future<void> _copyImageLibraryItemPath(ImageLibraryItem item) async {
    await _fileService.copyTextToClipboard(item.path);
    if (!mounted) {
      return;
    }
    _showMessage('作品路径已复制');
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
    await _selectFeature(WorkspaceFeature.imageEditor);
    if (!mounted) {
      return;
    }
    setState(() {
      _editorImagePath = item.path;
      _editorErrorMessage = null;
    });
  }

  Future<void> _reuseImageLibraryGeneration(ImageLibraryItem item) async {
    final generation = item.generation;
    if (generation == null) {
      _showMessage('这个作品没有可复用的生成参数');
      return;
    }

    if (_selectedFeature != WorkspaceFeature.imageGeneration) {
      await _selectFeature(WorkspaceFeature.imageGeneration);
      if (!mounted) {
        return;
      }
    }

    _isRestoringState = true;
    _promptController.text = generation.prompt;
    _negativePromptController.text = generation.negativePrompt;
    _userController.text = generation.advancedSettings.user;
    final draft = buildImageLibraryGenerationReuseDraft(
      generation: generation,
      apiConfigs: _apiConfigs,
    );
    final matchingConfigId = draft.matchingConfigId;

    setState(() {
      if (matchingConfigId != null) {
        _selectedApiConfigId = matchingConfigId;
      }
      _size = draft.size;
      _imageCount = draft.imageCount;
      _advancedSettings = draft.advancedSettings;
      _errorMessage = null;
    });

    _isRestoringState = false;
    if (matchingConfigId != null) {
      await _selectApiConfig(matchingConfigId);
    }
    await _saveSettings();
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
    );

    return ImageLibraryWorkspace(
      viewData: viewData,
      searchController: _imageLibrarySearchController,
      searchQuery: _imageLibrarySearchQuery,
      selectedFilter: _imageLibraryKindFilter,
      onSearchChanged: _setImageLibrarySearchQuery,
      onClearSearch: _clearImageLibrarySearchQuery,
      onFilterChanged: _setImageLibraryKindFilter,
      sortOrder: _imageLibrarySortOrder,
      onSortOrderChanged: _setImageLibrarySortOrder,
      selectedItemIds: _selectedImageLibraryItemIds,
      onSelectionChanged: _setImageLibraryItemSelected,
      onSelectVisible: () =>
          _selectVisibleImageLibraryItems(viewData.filteredItems),
      onClearSelection: _clearImageLibrarySelection,
      onDeleteSelected: _confirmDeleteSelectedImageLibraryItems,
      onUseInEditor: _useImageLibraryItemInEditor,
      onReuseGeneration: _reuseImageLibraryGeneration,
      onCopyGeneration: _copyImageLibraryGeneration,
      onEditMetadata: _showEditImageLibraryItemDialog,
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
