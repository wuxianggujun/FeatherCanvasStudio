import 'package:flutter/material.dart';

import '../models/image_library_item.dart';
import '../models/ui_state.dart';
import '../theme/layout_constants.dart';
import '../utils/date_formatting.dart';
import '../utils/display_labels.dart';
import '../widgets/common_form_widgets.dart';
import 'image_library_common_widgets.dart';

part 'image_library_tile.dart';

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
    required this.availableProjects,
    required this.selectedProject,
    required this.onProjectChanged,
    required this.availableTags,
    required this.selectedTag,
    required this.onTagChanged,
    required this.sortOrder,
    required this.onSortOrderChanged,
    required this.selectedItemIds,
    required this.onSelectionChanged,
    required this.onSelectVisible,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.onExportSelected,
    required this.onUseInEditor,
    required this.onReuseGeneration,
    required this.onCopyGeneration,
    required this.onMakeBackgroundTransparent,
    required this.onEditMetadata,
    required this.onCopyImage,
    required this.onExportImage,
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
  final List<String> availableProjects;
  final String selectedProject;
  final ValueChanged<String> onProjectChanged;
  final List<String> availableTags;
  final String selectedTag;
  final ValueChanged<String> onTagChanged;
  final ImageLibrarySortOrder sortOrder;
  final ValueChanged<ImageLibrarySortOrder> onSortOrderChanged;
  final Set<String> selectedItemIds;
  final void Function(ImageLibraryItem item, bool selected) onSelectionChanged;
  final VoidCallback onSelectVisible;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final VoidCallback onExportSelected;
  final ValueChanged<ImageLibraryItem> onUseInEditor;
  final ValueChanged<ImageLibraryItem> onReuseGeneration;
  final ValueChanged<ImageLibraryItem> onCopyGeneration;
  final ValueChanged<ImageLibraryItem> onMakeBackgroundTransparent;
  final ValueChanged<ImageLibraryItem> onEditMetadata;
  final ValueChanged<ImageLibraryItem> onCopyImage;
  final ValueChanged<ImageLibraryItem> onExportImage;
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
          if (availableProjects.isNotEmpty || availableTags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (availableProjects.isNotEmpty)
                  SizedBox(
                    width: 180,
                    child: OptionDropdown<String>(
                      label: '项目',
                      value: selectedProject,
                      options: ['', ...availableProjects],
                      labelBuilder: (value) => value.isEmpty ? '全部项目' : value,
                      onChanged: onProjectChanged,
                      isDense: true,
                    ),
                  ),
                if (availableTags.isNotEmpty)
                  SizedBox(
                    width: 180,
                    child: OptionDropdown<String>(
                      label: '标签',
                      value: selectedTag,
                      options: ['', ...availableTags],
                      labelBuilder: (value) => value.isEmpty ? '全部标签' : value,
                      onChanged: onTagChanged,
                      isDense: true,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: fieldGap),
          ],
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
                OutlinedButton.icon(
                  onPressed: onExportSelected,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('导出已选'),
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
            _SelectableImageLibraryGrid(
              items: items,
              selectedItemIds: selectedItemIds,
              onSelectionChanged: onSelectionChanged,
              onUseInEditor: onUseInEditor,
              onReuseGeneration: onReuseGeneration,
              onCopyGeneration: onCopyGeneration,
              onMakeBackgroundTransparent: onMakeBackgroundTransparent,
              onEditMetadata: onEditMetadata,
              onCopyImage: onCopyImage,
              onExportImage: onExportImage,
              onCopyPath: onCopyPath,
              onOpenLocation: onOpenLocation,
              onDelete: onDelete,
              onOpenSliceExplorer: onOpenSliceExplorer,
              savedFrameCountFor: savedFrameCountFor,
            ),
        ],
      ),
    );
  }
}

class _SelectableImageLibraryGrid extends StatefulWidget {
  const _SelectableImageLibraryGrid({
    required this.items,
    required this.selectedItemIds,
    required this.onSelectionChanged,
    required this.onUseInEditor,
    required this.onReuseGeneration,
    required this.onCopyGeneration,
    required this.onMakeBackgroundTransparent,
    required this.onEditMetadata,
    required this.onCopyImage,
    required this.onExportImage,
    required this.onCopyPath,
    required this.onOpenLocation,
    required this.onDelete,
    required this.onOpenSliceExplorer,
    required this.savedFrameCountFor,
  });

  final List<ImageLibraryItem> items;
  final Set<String> selectedItemIds;
  final void Function(ImageLibraryItem item, bool selected) onSelectionChanged;
  final ValueChanged<ImageLibraryItem> onUseInEditor;
  final ValueChanged<ImageLibraryItem> onReuseGeneration;
  final ValueChanged<ImageLibraryItem> onCopyGeneration;
  final ValueChanged<ImageLibraryItem> onMakeBackgroundTransparent;
  final ValueChanged<ImageLibraryItem> onEditMetadata;
  final ValueChanged<ImageLibraryItem> onCopyImage;
  final ValueChanged<ImageLibraryItem> onExportImage;
  final ValueChanged<ImageLibraryItem> onCopyPath;
  final ValueChanged<ImageLibraryItem> onOpenLocation;
  final ValueChanged<String> onDelete;
  final ValueChanged<ImageLibraryItem> onOpenSliceExplorer;
  final int Function(ImageLibraryItem item) savedFrameCountFor;

  @override
  State<_SelectableImageLibraryGrid> createState() =>
      _SelectableImageLibraryGridState();
}

class _SelectableImageLibraryGridState
    extends State<_SelectableImageLibraryGrid> {
  bool? _dragSelectionValue;
  final Set<String> _dragTouchedIds = <String>{};

  bool get _isDraggingSelection => _dragSelectionValue != null;
  bool get _isSelectionMode => widget.selectedItemIds.isNotEmpty;

  void _startDragSelection(ImageLibraryItem item) {
    if (!_isSelectionMode) {
      return;
    }
    final nextSelected = !widget.selectedItemIds.contains(item.id);
    setState(() {
      _dragSelectionValue = nextSelected;
      _dragTouchedIds
        ..clear()
        ..add(item.id);
    });
    widget.onSelectionChanged(item, nextSelected);
  }

  void _applyDragSelection(ImageLibraryItem item) {
    final nextSelected = _dragSelectionValue;
    if (nextSelected == null || !_dragTouchedIds.add(item.id)) {
      return;
    }
    widget.onSelectionChanged(item, nextSelected);
  }

  void _endDragSelection() {
    if (!_isDraggingSelection) {
      return;
    }
    setState(() {
      _dragSelectionValue = null;
      _dragTouchedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: (_) => _endDragSelection(),
      onPointerCancel: (_) => _endDragSelection(),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.items.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.69,
        ),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return _ImageLibraryTile(
            item: item,
            selected: widget.selectedItemIds.contains(item.id),
            selectionMode: _isSelectionMode,
            onSelectionChanged: (selected) =>
                widget.onSelectionChanged(item, selected),
            onSelectionDragStart: () => _startDragSelection(item),
            onSelectionDragEnter: () => _applyDragSelection(item),
            onUseInEditor: () => widget.onUseInEditor(item),
            onReuseGeneration: () => widget.onReuseGeneration(item),
            onCopyGeneration: () => widget.onCopyGeneration(item),
            onMakeBackgroundTransparent: () =>
                widget.onMakeBackgroundTransparent(item),
            onEditMetadata: () => widget.onEditMetadata(item),
            onCopyImage: () => widget.onCopyImage(item),
            onExportImage: () => widget.onExportImage(item),
            onCopyPath: () => widget.onCopyPath(item),
            onOpenLocation: () => widget.onOpenLocation(item),
            onDelete: () => widget.onDelete(item.id),
            onOpenSliceExplorer: () => widget.onOpenSliceExplorer(item),
            savedFrameCount: widget.savedFrameCountFor(item),
          );
        },
      ),
    );
  }
}
