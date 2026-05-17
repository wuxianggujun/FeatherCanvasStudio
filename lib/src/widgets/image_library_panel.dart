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
    this.fillAvailableHeight = false,
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
  final bool fillAvailableHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = selectedItemIds.length;
    final visibleSelectedCount = items
        .where((item) => selectedItemIds.contains(item.id))
        .length;
    final controls = _buildControls(
      selectedCount: selectedCount,
      visibleSelectedCount: visibleSelectedCount,
    );

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
      expandChild: fillAvailableHeight,
      child: fillAvailableHeight
          ? CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...controls,
                      const SizedBox(height: fieldGap),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  _buildGrid(asSliver: true),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...controls,
                const SizedBox(height: fieldGap),
                if (items.isEmpty) _buildEmptyState(context) else _buildGrid(),
              ],
            ),
    );
  }

  List<Widget> _buildControls({
    required int selectedCount,
    required int visibleSelectedCount,
  }) {
    return [
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
    ];
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
    );
  }

  Widget _buildGrid({bool asSliver = false}) {
    return _PaginatedImageLibraryGrid(
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
      shrinkWrap: !fillAvailableHeight,
      asSliver: asSliver,
    );
  }
}

const List<int> _imageLibraryPageSizeOptions = [24, 48, 96];

class _PaginatedImageLibraryGrid extends StatefulWidget {
  const _PaginatedImageLibraryGrid({
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
    required this.shrinkWrap,
    required this.asSliver,
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
  final bool shrinkWrap;
  final bool asSliver;

  @override
  State<_PaginatedImageLibraryGrid> createState() =>
      _PaginatedImageLibraryGridState();
}

class _PaginatedImageLibraryGridState
    extends State<_PaginatedImageLibraryGrid> {
  int _pageIndex = 0;
  int _pageSize = _imageLibraryPageSizeOptions.first;

  int get _pageCount {
    if (widget.items.isEmpty) {
      return 1;
    }
    return (widget.items.length + _pageSize - 1) ~/ _pageSize;
  }

  @override
  void didUpdateWidget(covariant _PaginatedImageLibraryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pageIndex = _normalizedPageIndex(_pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = _normalizedPageIndex(_pageIndex);
    if (pageIndex != _pageIndex) {
      _pageIndex = pageIndex;
    }

    final start = pageIndex * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.items.length);
    final pageItems = widget.items.sublist(start, end);
    final showPagination =
        widget.items.length > _imageLibraryPageSizeOptions.first;
    final grid = _buildGrid(pageItems);

    if (widget.asSliver) {
      if (!showPagination) {
        return grid;
      }
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: _ImageLibraryPaginationBar(
              pageIndex: pageIndex,
              pageCount: _pageCount,
              pageSize: _pageSize,
              totalCount: widget.items.length,
              startIndex: start,
              endIndex: end,
              onPageChanged: _setPageIndex,
              onPageSizeChanged: _setPageSize,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: fieldGap)),
          grid,
          const SliverToBoxAdapter(child: SizedBox(height: fieldGap)),
          SliverToBoxAdapter(
            child: _ImageLibraryPaginationBar(
              pageIndex: pageIndex,
              pageCount: _pageCount,
              pageSize: _pageSize,
              totalCount: widget.items.length,
              startIndex: start,
              endIndex: end,
              onPageChanged: _setPageIndex,
              onPageSizeChanged: _setPageSize,
            ),
          ),
        ],
      );
    }

    if (!showPagination) {
      return grid;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ImageLibraryPaginationBar(
          pageIndex: pageIndex,
          pageCount: _pageCount,
          pageSize: _pageSize,
          totalCount: widget.items.length,
          startIndex: start,
          endIndex: end,
          onPageChanged: _setPageIndex,
          onPageSizeChanged: _setPageSize,
        ),
        const SizedBox(height: fieldGap),
        grid,
        const SizedBox(height: fieldGap),
        _ImageLibraryPaginationBar(
          pageIndex: pageIndex,
          pageCount: _pageCount,
          pageSize: _pageSize,
          totalCount: widget.items.length,
          startIndex: start,
          endIndex: end,
          onPageChanged: _setPageIndex,
          onPageSizeChanged: _setPageSize,
        ),
      ],
    );
  }

  Widget _buildGrid(List<ImageLibraryItem> pageItems) {
    return _SelectableImageLibraryGrid(
      items: pageItems,
      selectedItemIds: widget.selectedItemIds,
      onSelectionChanged: widget.onSelectionChanged,
      onUseInEditor: widget.onUseInEditor,
      onReuseGeneration: widget.onReuseGeneration,
      onCopyGeneration: widget.onCopyGeneration,
      onMakeBackgroundTransparent: widget.onMakeBackgroundTransparent,
      onEditMetadata: widget.onEditMetadata,
      onCopyImage: widget.onCopyImage,
      onExportImage: widget.onExportImage,
      onCopyPath: widget.onCopyPath,
      onOpenLocation: widget.onOpenLocation,
      onDelete: widget.onDelete,
      onOpenSliceExplorer: widget.onOpenSliceExplorer,
      savedFrameCountFor: widget.savedFrameCountFor,
      shrinkWrap: widget.shrinkWrap,
      asSliver: widget.asSliver,
    );
  }

  int _normalizedPageIndex(int pageIndex) {
    return pageIndex.clamp(0, _pageCount - 1);
  }

  void _setPageIndex(int pageIndex) {
    setState(() => _pageIndex = _normalizedPageIndex(pageIndex));
  }

  void _setPageSize(int pageSize) {
    if (_pageSize == pageSize) {
      return;
    }
    setState(() {
      _pageSize = pageSize;
      _pageIndex = 0;
    });
  }
}

class _ImageLibraryPaginationBar extends StatelessWidget {
  const _ImageLibraryPaginationBar({
    required this.pageIndex,
    required this.pageCount,
    required this.pageSize,
    required this.totalCount,
    required this.startIndex,
    required this.endIndex,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int pageIndex;
  final int pageCount;
  final int pageSize;
  final int totalCount;
  final int startIndex;
  final int endIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirstPage = pageIndex <= 0;
    final isLastPage = pageIndex >= pageCount - 1;
    final rangeLabel = totalCount == 0
        ? '0 / 0'
        : '${startIndex + 1}-$endIndex / $totalCount';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '第 ${pageIndex + 1} / $pageCount 页 · $rangeLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PaginationIconButton(
                  tooltip: '第一页',
                  icon: Icons.first_page,
                  onPressed: isFirstPage ? null : () => onPageChanged(0),
                ),
                _PaginationIconButton(
                  tooltip: '上一页',
                  icon: Icons.chevron_left,
                  onPressed: isFirstPage
                      ? null
                      : () => onPageChanged(pageIndex - 1),
                ),
                _PaginationIconButton(
                  tooltip: '下一页',
                  icon: Icons.chevron_right,
                  onPressed: isLastPage
                      ? null
                      : () => onPageChanged(pageIndex + 1),
                ),
                _PaginationIconButton(
                  tooltip: '最后一页',
                  icon: Icons.last_page,
                  onPressed: isLastPage
                      ? null
                      : () => onPageChanged(pageCount - 1),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '每页',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pageSize,
                    isDense: true,
                    items: [
                      for (final size in _imageLibraryPageSizeOptions)
                        DropdownMenuItem<int>(
                          value: size,
                          child: Text('$size'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onPageSizeChanged(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '个',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationIconButton extends StatelessWidget {
  const _PaginationIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
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
    required this.shrinkWrap,
    required this.asSliver,
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
  final bool shrinkWrap;
  final bool asSliver;

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
    if (widget.asSliver) {
      return SliverGrid(
        gridDelegate: _imageLibraryGridDelegate,
        delegate: SliverChildBuilderDelegate(
          _buildTile,
          childCount: widget.items.length,
        ),
      );
    }

    return Listener(
      onPointerUp: (_) => _endDragSelection(),
      onPointerCancel: (_) => _endDragSelection(),
      child: GridView.builder(
        shrinkWrap: widget.shrinkWrap,
        physics: widget.shrinkWrap
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        itemCount: widget.items.length,
        gridDelegate: _imageLibraryGridDelegate,
        itemBuilder: _buildTile,
      ),
    );
  }

  Widget _buildTile(BuildContext context, int index) {
    final item = widget.items[index];
    return Listener(
      onPointerUp: (_) => _endDragSelection(),
      onPointerCancel: (_) => _endDragSelection(),
      child: _ImageLibraryTile(
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
      ),
    );
  }
}

const SliverGridDelegateWithMaxCrossAxisExtent _imageLibraryGridDelegate =
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 380,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.88,
    );
