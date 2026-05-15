import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exceptions.dart';
import '../models/image_asset_kind.dart';
import '../models/image_library_item.dart';
import '../models/ui_state.dart';
import '../services/sprite_sheet_service.dart';
import '../theme/layout_constants.dart';
import '../utils/date_formatting.dart';
import '../utils/display_labels.dart';
import '../widgets/common_form_widgets.dart';

class ImageLibraryPanel extends StatelessWidget {
  const ImageLibraryPanel({
    required this.items,
    required this.totalCount,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.sortOrder,
    required this.onSortOrderChanged,
    required this.selectedItemIds,
    required this.onSelectionChanged,
    required this.onSelectVisible,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.onUseInEditor,
    required this.onReuseGeneration,
    required this.onCopyGeneration,
    required this.onEditMetadata,
    required this.onCopyPath,
    required this.onOpenLocation,
    required this.onDelete,
    required this.onOpenSliceExplorer,
    required this.savedFrameCountFor,
    required this.showStandaloneFrames,
    required this.groupedFrameCount,
    required this.onToggleStandaloneFrames,
    super.key,
  });

  final List<ImageLibraryItem> items;
  final int totalCount;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ImageLibraryKindFilter selectedFilter;
  final ValueChanged<ImageLibraryKindFilter> onFilterChanged;
  final ImageLibrarySortOrder sortOrder;
  final ValueChanged<ImageLibrarySortOrder> onSortOrderChanged;
  final Set<String> selectedItemIds;
  final void Function(ImageLibraryItem item, bool selected) onSelectionChanged;
  final VoidCallback onSelectVisible;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final ValueChanged<ImageLibraryItem> onUseInEditor;
  final ValueChanged<ImageLibraryItem> onReuseGeneration;
  final ValueChanged<ImageLibraryItem> onCopyGeneration;
  final ValueChanged<ImageLibraryItem> onEditMetadata;
  final ValueChanged<ImageLibraryItem> onCopyPath;
  final ValueChanged<ImageLibraryItem> onOpenLocation;
  final ValueChanged<String> onDelete;
  final ValueChanged<ImageLibraryItem> onOpenSliceExplorer;
  final int Function(ImageLibraryItem item) savedFrameCountFor;
  final bool showStandaloneFrames;
  final int groupedFrameCount;
  final ValueChanged<bool> onToggleStandaloneFrames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = selectedItemIds.length;
    final visibleSelectedCount = items
        .where((item) => selectedItemIds.contains(item.id))
        .length;

    return AppPanel(
      title: '应用内作品',
      trailing: Text(
        items.length == totalCount
            ? '$totalCount 个作品'
            : '${items.length} / $totalCount',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: '搜索作品',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清空搜索',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: fieldGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in ImageLibraryKindFilter.values)
                FilterChip(
                  selected: selectedFilter == filter,
                  label: Text(imageLibraryKindFilterLabel(filter)),
                  onSelected: (_) => onFilterChanged(filter),
                ),
            ],
          ),
          const SizedBox(height: fieldGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: OptionDropdown<ImageLibrarySortOrder>(
                  label: '排序',
                  value: sortOrder,
                  options: ImageLibrarySortOrder.values,
                  labelBuilder: imageLibrarySortOrderLabel,
                  onChanged: onSortOrderChanged,
                  isDense: true,
                ),
              ),
              OutlinedButton.icon(
                onPressed: items.isEmpty || visibleSelectedCount == items.length
                    ? null
                    : onSelectVisible,
                icon: const Icon(Icons.checklist_outlined),
                label: const Text('选择当前结果'),
              ),
              if (groupedFrameCount > 0)
                FilterChip(
                  selected: showStandaloneFrames,
                  avatar: Icon(
                    showStandaloneFrames
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  label: Text('展开切片 ($groupedFrameCount)'),
                  onSelected: onToggleStandaloneFrames,
                ),
              if (selectedCount > 0) ...[
                TextButton.icon(
                  onPressed: onClearSelection,
                  icon: const Icon(Icons.close),
                  label: Text('已选 $selectedCount'),
                ),
                FilledButton.icon(
                  onPressed: onDeleteSelected,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除已选'),
                ),
              ],
            ],
          ),
          const SizedBox(height: fieldGap),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 220),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                totalCount == 0 ? '暂无作品。生成、导出、编辑或合成后的图片会保存到这里。' : '当前条件下没有作品。',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.69,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _ImageLibraryTile(
                  item: item,
                  selected: selectedItemIds.contains(item.id),
                  onSelectionChanged: (selected) =>
                      onSelectionChanged(item, selected),
                  onUseInEditor: () => onUseInEditor(item),
                  onReuseGeneration: () => onReuseGeneration(item),
                  onCopyGeneration: () => onCopyGeneration(item),
                  onEditMetadata: () => onEditMetadata(item),
                  onCopyPath: () => onCopyPath(item),
                  onOpenLocation: () => onOpenLocation(item),
                  onDelete: () => onDelete(item.id),
                  onOpenSliceExplorer: () => onOpenSliceExplorer(item),
                  savedFrameCount: savedFrameCountFor(item),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ImageLibraryTile extends StatelessWidget {
  const _ImageLibraryTile({
    required this.item,
    required this.selected,
    required this.onSelectionChanged,
    required this.onUseInEditor,
    required this.onReuseGeneration,
    required this.onCopyGeneration,
    required this.onEditMetadata,
    required this.onCopyPath,
    required this.onOpenLocation,
    required this.onDelete,
    required this.onOpenSliceExplorer,
    required this.savedFrameCount,
  });

  final ImageLibraryItem item;
  final bool selected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onUseInEditor;
  final VoidCallback onReuseGeneration;
  final VoidCallback onCopyGeneration;
  final VoidCallback onEditMetadata;
  final VoidCallback onCopyPath;
  final VoidCallback onOpenLocation;
  final VoidCallback onDelete;
  final VoidCallback onOpenSliceExplorer;
  final int savedFrameCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSheetWithMeta = item.isSpriteSheetWithMetadata;
    final totalFrames = item.totalFrameCount;
    final generation = item.generation;
    final displayPrompt = item.prompt ?? generation?.prompt;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isSheetWithMeta
              ? onOpenSliceExplorer
              : item.canUseAsSpriteSheet
              ? onUseInEditor
              : generation != null
              ? onReuseGeneration
              : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: _ImageLibraryPreview(item: item),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.88,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Checkbox(
                            value: selected,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) =>
                                onSelectionChanged(value ?? false),
                          ),
                        ),
                      ),
                      if (isSheetWithMeta)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.dashboard_customize_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$savedFrameCount/$totalFrames 帧',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _ImageKindChip(kind: item.kind),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.source} · ${formatTimestamp(item.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                if (generation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${apiProviderKindLabel(generation.providerKind)} · '
                    '${generation.model} · ${generation.size}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (item.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (displayPrompt != null &&
                    displayPrompt.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    displayPrompt.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isSheetWithMeta)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onOpenSliceExplorer,
                          icon: const Icon(Icons.dashboard_customize_outlined),
                          label: const Text('切片'),
                        ),
                      )
                    else if (generation != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReuseGeneration,
                          icon: const Icon(Icons.restore_outlined),
                          label: const Text('复用'),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: item.canUseAsSpriteSheet
                              ? onUseInEditor
                              : null,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('编辑'),
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: '编辑作品信息',
                      onPressed: onEditMetadata,
                      icon: const Icon(Icons.drive_file_rename_outline),
                    ),
                    PopupMenuButton<ImageLibraryTileMenuAction>(
                      tooltip: '更多操作',
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (action) {
                        switch (action) {
                          case ImageLibraryTileMenuAction.useInEditor:
                            onUseInEditor();
                          case ImageLibraryTileMenuAction.reuseGeneration:
                            onReuseGeneration();
                          case ImageLibraryTileMenuAction.copyGeneration:
                            onCopyGeneration();
                          case ImageLibraryTileMenuAction.copyPath:
                            onCopyPath();
                          case ImageLibraryTileMenuAction.openLocation:
                            onOpenLocation();
                          case ImageLibraryTileMenuAction.delete:
                            onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        if (isSheetWithMeta && item.canUseAsSpriteSheet)
                          const PopupMenuItem(
                            value: ImageLibraryTileMenuAction.useInEditor,
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('在编辑器中打开'),
                            ),
                          ),
                        if (generation != null) ...[
                          const PopupMenuItem(
                            value: ImageLibraryTileMenuAction.reuseGeneration,
                            child: ListTile(
                              leading: Icon(Icons.restore_outlined),
                              title: Text('复用生成参数'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: ImageLibraryTileMenuAction.copyGeneration,
                            child: ListTile(
                              leading: Icon(Icons.content_copy_outlined),
                              title: Text('复制生成参数'),
                            ),
                          ),
                        ],
                        const PopupMenuItem(
                          value: ImageLibraryTileMenuAction.copyPath,
                          child: ListTile(
                            leading: Icon(Icons.copy_outlined),
                            title: Text('复制路径'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: ImageLibraryTileMenuAction.openLocation,
                          child: ListTile(
                            leading: Icon(Icons.folder_open_outlined),
                            title: Text('打开位置'),
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: ImageLibraryTileMenuAction.delete,
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('删除作品'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageLibraryPreview extends StatelessWidget {
  const _ImageLibraryPreview({required this.item});

  final ImageLibraryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!item.isImageFile) {
      return Center(
        child: Icon(
          Icons.gif_box_outlined,
          size: 42,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return Image.file(
      File(item.path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.error,
          ),
        );
      },
    );
  }
}

class SpriteSheetSliceExplorerDialog extends StatefulWidget {
  const SpriteSheetSliceExplorerDialog({
    required this.sheet,
    required this.savedFrameIndexes,
    required this.onSaveSlice,
    required this.onSaveAllSlices,
    super.key,
  });

  final ImageLibraryItem sheet;
  final Set<int> savedFrameIndexes;
  final Future<bool> Function(int frameIndex, Uint8List bytes) onSaveSlice;
  final Future<int> Function(List<MapEntry<int, Uint8List>> framesToSave)
  onSaveAllSlices;

  @override
  State<SpriteSheetSliceExplorerDialog> createState() =>
      SpriteSheetSliceExplorerDialogState();
}

class SpriteSheetSliceExplorerDialogState
    extends State<SpriteSheetSliceExplorerDialog> {
  SpriteSheetPreviewData? _previewData;
  String? _errorMessage;
  final Set<int> _savingIndexes = <int>{};
  final Set<int> _justSaved = <int>{};
  bool _isSavingAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.sheet.path).readAsBytes();
      final rows = widget.sheet.rows;
      final columns = widget.sheet.columns;
      if (rows == null || columns == null || rows <= 0 || columns <= 0) {
        throw const ImageGenerationException('该 Sprite Sheet 缺少行列元数据。');
      }
      final data = SpriteSheetPreviewComposer.buildFromSheetBytes(
        bytes,
        rows: rows,
        columns: columns,
      );
      if (!mounted) return;
      setState(() => _previewData = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = '加载切片失败：$error');
    }
  }

  bool _isSaved(int frameIndex) =>
      widget.savedFrameIndexes.contains(frameIndex) ||
      _justSaved.contains(frameIndex);

  Future<void> _saveOne(int frameIndex) async {
    final data = _previewData;
    if (data == null || _savingIndexes.contains(frameIndex)) return;
    setState(() => _savingIndexes.add(frameIndex));
    try {
      final saved = await widget.onSaveSlice(
        frameIndex,
        data.frames[frameIndex],
      );
      if (!mounted) return;
      if (saved) {
        setState(() => _justSaved.add(frameIndex));
      }
    } finally {
      if (mounted) {
        setState(() => _savingIndexes.remove(frameIndex));
      }
    }
  }

  Future<void> _saveAll() async {
    final data = _previewData;
    if (data == null || _isSavingAll) return;
    final pending = <MapEntry<int, Uint8List>>[];
    for (var i = 0; i < data.frames.length; i++) {
      if (!_isSaved(i)) {
        pending.add(MapEntry(i, data.frames[i]));
      }
    }
    if (pending.isEmpty) return;
    setState(() => _isSavingAll = true);
    try {
      final actuallySaved = await widget.onSaveAllSlices(pending);
      if (!mounted) return;
      setState(() {
        _justSaved.addAll(pending.take(actuallySaved).map((e) => e.key));
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingAll = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _previewData;
    final error = _errorMessage;
    final totalCount = (widget.sheet.rows ?? 0) * (widget.sheet.columns ?? 0);
    final savedCount = data == null
        ? widget.savedFrameIndexes.length
        : List.generate(
            data.frames.length,
            (i) => _isSaved(i),
          ).where((e) => e).length;
    final remaining = (data?.frames.length ?? totalCount) - savedCount;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('切片管理 · ${widget.sheet.displayTitle}')),
          if (data != null)
            Text(
              '已保存 $savedCount / ${data.frames.length}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 520,
        child: error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _previewData = null;
                        });
                        _load();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              )
            : data == null
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio:
                      data.frameWidth /
                      (data.frameHeight == 0 ? 1 : data.frameHeight),
                ),
                itemCount: data.frames.length,
                itemBuilder: (context, index) {
                  final bytes = data.frames[index];
                  final saved = _isSaved(index);
                  final saving = _savingIndexes.contains(index);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: saved
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.outlineVariant,
                        width: saved ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Image.memory(bytes, fit: BoxFit.contain),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.85,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${index + 1}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ),
                          if (saved)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '已保存',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          if (!saved)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Material(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.85,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                child: IconButton(
                                  tooltip: '保存这一帧',
                                  iconSize: 20,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: saving
                                      ? null
                                      : () => _saveOne(index),
                                  icon: saving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.bookmark_add_outlined),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: data == null || _isSavingAll || remaining <= 0
              ? null
              : _saveAll,
          icon: _isSavingAll
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.select_all),
          label: Text(remaining <= 0 ? '已全部保存' : '全部保存为切片 ($remaining)'),
        ),
      ],
    );
  }
}

class SpriteSheetSlicePickerDialog extends StatefulWidget {
  const SpriteSheetSlicePickerDialog({
    required this.sheet,
    required this.allowMultiple,
    this.title,
    super.key,
  });

  final ImageLibraryItem sheet;
  final bool allowMultiple;
  final String? title;

  @override
  State<SpriteSheetSlicePickerDialog> createState() =>
      SpriteSheetSlicePickerDialogState();
}

class SpriteSheetSlicePickerDialogState
    extends State<SpriteSheetSlicePickerDialog> {
  SpriteSheetPreviewData? _previewData;
  String? _errorMessage;
  final Set<int> _selected = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.sheet.path).readAsBytes();
      final rows = widget.sheet.rows;
      final columns = widget.sheet.columns;
      if (rows == null || columns == null || rows <= 0 || columns <= 0) {
        throw const ImageGenerationException('该 Sprite Sheet 缺少行列元数据。');
      }
      final data = SpriteSheetPreviewComposer.buildFromSheetBytes(
        bytes,
        rows: rows,
        columns: columns,
      );
      if (!mounted) return;
      setState(() => _previewData = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = '加载切片失败：$error');
    }
  }

  void _toggle(int index) {
    setState(() {
      if (widget.allowMultiple) {
        if (_selected.contains(index)) {
          _selected.remove(index);
        } else {
          _selected.add(index);
        }
      } else {
        _selected
          ..clear()
          ..add(index);
      }
    });
  }

  void _confirm() {
    final data = _previewData;
    if (data == null || _selected.isEmpty) return;
    final ordered = _selected.toList()..sort();
    Navigator.of(context).pop(<MapEntry<int, Uint8List>>[
      for (final idx in ordered) MapEntry(idx, data.frames[idx]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _previewData;
    final error = _errorMessage;
    final title = widget.title ?? (widget.allowMultiple ? '挑选切片帧' : '挑选一帧作为来源');

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('$title · ${widget.sheet.displayTitle}')),
          if (data != null)
            Text(
              widget.allowMultiple
                  ? '已选 ${_selected.length} / ${data.frames.length}'
                  : _selected.isEmpty
                  ? '尚未选择'
                  : '已选 #${_selected.first + 1}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 520,
        child: error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _previewData = null;
                        });
                        _load();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              )
            : data == null
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio:
                      data.frameWidth /
                      (data.frameHeight == 0 ? 1 : data.frameHeight),
                ),
                itemCount: data.frames.length,
                itemBuilder: (context, index) {
                  final bytes = data.frames[index];
                  final selected = _selected.contains(index);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _toggle(index),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: Image.memory(
                                    bytes,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface.withValues(
                                      alpha: 0.85,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                              ),
                              if (selected)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.check,
                                      size: 14,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: data == null || _selected.isEmpty ? null : _confirm,
          icon: const Icon(Icons.check),
          label: Text(
            widget.allowMultiple ? '确认选择 (${_selected.length})' : '确认选择',
          ),
        ),
      ],
    );
  }
}

class _ImageKindChip extends StatelessWidget {
  const _ImageKindChip({required this.kind});

  final ImageAssetKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        imageAssetKindLabel(kind),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class ImageLibraryPickerDialog extends StatefulWidget {
  const ImageLibraryPickerDialog({
    required this.title,
    required this.items,
    required this.allowMultiple,
    super.key,
  });

  final String title;
  final List<ImageLibraryItem> items;
  final bool allowMultiple;

  @override
  State<ImageLibraryPickerDialog> createState() =>
      ImageLibraryPickerDialogState();
}

class ImageLibraryPickerDialogState extends State<ImageLibraryPickerDialog> {
  final Set<String> _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 760,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: widget.items.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final selected = _selectedIds.contains(item.id);
              return Material(
                color: selected
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _toggleSelection(item),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: _ImageLibraryPreview(item: item),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: selected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          imageAssetKindLabel(item.kind),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selectedIds.isEmpty ? null : _confirm,
          child: Text(
            widget.allowMultiple ? '选择 ${_selectedIds.length} 张' : '选择',
          ),
        ),
      ],
    );
  }

  void _toggleSelection(ImageLibraryItem item) {
    setState(() {
      if (widget.allowMultiple) {
        if (!_selectedIds.add(item.id)) {
          _selectedIds.remove(item.id);
        }
      } else {
        _selectedIds
          ..clear()
          ..add(item.id);
      }
    });
  }

  void _confirm() {
    if (widget.allowMultiple) {
      Navigator.of(context).pop([
        for (final item in widget.items)
          if (_selectedIds.contains(item.id)) item,
      ]);
      return;
    }

    final selectedId = _selectedIds.first;
    for (final item in widget.items) {
      if (item.id == selectedId) {
        Navigator.of(context).pop(item);
        return;
      }
    }
  }
}
