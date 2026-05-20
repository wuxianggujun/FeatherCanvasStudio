import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/image_library_item.dart';
import '../models/image_asset_kind.dart';
import '../models/ui_state.dart';
import '../l10n/app_l10n.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/layout_constants.dart';
import '../utils/date_formatting.dart';
import '../utils/localized_display_labels.dart';
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
    required this.onOpenAnimationProject,
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
  final ValueChanged<ImageLibraryItem> onOpenAnimationProject;
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
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final selectedCount = selectedItemIds.length;
    final visibleSelectedCount = items
        .where((item) => selectedItemIds.contains(item.id))
        .length;
    final canSelectVisible =
        items.isNotEmpty && visibleSelectedCount < items.length;
    final controls = _buildControls(
      l10n: l10n,
      selectedCount: selectedCount,
      visibleSelectedCount: visibleSelectedCount,
      canSelectVisible: canSelectVisible,
    );

    return AppPanel(
      title: l10n.imageLibraryPanelTitle,
      trailing: Text(
        items.length == totalCount
            ? l10n.imageLibraryTotalCount(totalCount)
            : l10n.imageLibraryFilteredCount(items.length, totalCount),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      expandChild: fillAvailableHeight,
      child: fillAvailableHeight
          ? _ImageLibrarySliverScrollView(
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
    required AppLocalizations l10n,
    required int selectedCount,
    required int visibleSelectedCount,
    required bool canSelectVisible,
  }) {
    return [
      TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: l10n.imageLibrarySearchLabel,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.imageLibraryClearSearchTooltip,
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
                  label: l10n.imageLibraryProjectLabel,
                  value: selectedProject,
                  options: ['', ...availableProjects],
                  labelBuilder: (value) =>
                      value.isEmpty ? l10n.imageLibraryAllProjects : value,
                  onChanged: onProjectChanged,
                  isDense: true,
                ),
              ),
            if (availableTags.isNotEmpty)
              SizedBox(
                width: 180,
                child: OptionDropdown<String>(
                  label: l10n.imageLibraryTagLabel,
                  value: selectedTag,
                  options: ['', ...availableTags],
                  labelBuilder: (value) =>
                      value.isEmpty ? l10n.imageLibraryAllTags : value,
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
              label: Text(localizedImageLibraryKindFilterLabel(l10n, filter)),
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
              label: l10n.imageLibrarySortLabel,
              value: sortOrder,
              options: ImageLibrarySortOrder.values,
              labelBuilder: (sortOrder) =>
                  localizedImageLibrarySortOrderLabel(l10n, sortOrder),
              onChanged: onSortOrderChanged,
              isDense: true,
            ),
          ),
          _DisabledActionSemantics(
            label: l10n.imageLibrarySelectVisible,
            disabledReason: canSelectVisible
                ? null
                : items.isEmpty
                ? l10n.imageLibrarySelectVisibleEmptyUnavailable
                : l10n.imageLibrarySelectVisibleAllSelectedUnavailable,
            child: OutlinedButton.icon(
              onPressed: canSelectVisible ? onSelectVisible : null,
              icon: const Icon(Icons.checklist_outlined),
              label: Text(l10n.imageLibrarySelectVisible),
            ),
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
              label: Text(l10n.imageLibraryExpandSlices(groupedFrameCount)),
              onSelected: onToggleStandaloneFrames,
            ),
          if (selectedCount > 0) ...[
            TextButton.icon(
              onPressed: onClearSelection,
              icon: const Icon(Icons.close),
              label: Text(l10n.imageLibrarySelectedCount(selectedCount)),
            ),
            OutlinedButton.icon(
              onPressed: onExportSelected,
              icon: const Icon(Icons.file_download_outlined),
              label: Text(l10n.imageLibraryExportSelected),
            ),
            FilledButton.icon(
              onPressed: onDeleteSelected,
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.imageLibraryDeleteSelected),
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
        totalCount == 0
            ? appL10nOf(context).imageLibraryEmptyAll
            : appL10nOf(context).imageLibraryEmptyFiltered,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildGrid({bool asSliver = false}) {
    return _PaginatedImageLibraryGrid(
      items: items,
      selectedItemIds: selectedItemIds,
      onSelectionChanged: onSelectionChanged,
      onOpenAnimationProject: onOpenAnimationProject,
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

class _DisabledActionSemantics extends StatelessWidget {
  const _DisabledActionSemantics({
    required this.label,
    required this.disabledReason,
    required this.child,
  });

  final String label;
  final String? disabledReason;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (disabledReason == null) {
      return child;
    }

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      value: disabledReason,
      button: true,
      enabled: false,
      child: child,
    );
  }
}

const List<int> _imageLibraryPageSizeOptions = [24, 48, 96];

class _PaginatedImageLibraryGrid extends StatefulWidget {
  const _PaginatedImageLibraryGrid({
    required this.items,
    required this.selectedItemIds,
    required this.onSelectionChanged,
    required this.onOpenAnimationProject,
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
  final ValueChanged<ImageLibraryItem> onOpenAnimationProject;
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
      onOpenAnimationProject: widget.onOpenAnimationProject,
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
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final isFirstPage = pageIndex <= 0;
    final isLastPage = pageIndex >= pageCount - 1;
    final rangeLabel = totalCount == 0
        ? l10n.imageLibraryPageEmptyRange
        : l10n.imageLibraryPageRange(startIndex + 1, endIndex, totalCount);
    final statusLabel = l10n.imageLibraryPageStatus(
      pageIndex + 1,
      pageCount,
      rangeLabel,
    );
    final semanticLabel = l10n.imageLibraryPaginationSemanticLabel(
      statusLabel,
      pageSize,
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
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
                statusLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PaginationIconButton(
                    tooltip: l10n.imageLibraryFirstPageTooltip,
                    icon: Icons.first_page,
                    onPressed: isFirstPage ? null : () => onPageChanged(0),
                  ),
                  _PaginationIconButton(
                    tooltip: l10n.imageLibraryPreviousPageTooltip,
                    icon: Icons.chevron_left,
                    onPressed: isFirstPage
                        ? null
                        : () => onPageChanged(pageIndex - 1),
                  ),
                  _PaginationIconButton(
                    tooltip: l10n.imageLibraryNextPageTooltip,
                    icon: Icons.chevron_right,
                    onPressed: isLastPage
                        ? null
                        : () => onPageChanged(pageIndex + 1),
                  ),
                  _PaginationIconButton(
                    tooltip: l10n.imageLibraryLastPageTooltip,
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
                    l10n.imageLibraryPageSizePrefix,
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
                    l10n.imageLibraryPageSizeSuffix,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    required this.onOpenAnimationProject,
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
  final ValueChanged<ImageLibraryItem> onOpenAnimationProject;
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
        onOpenAnimationProject: () => widget.onOpenAnimationProject(item),
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

class _ImageLibrarySliverScrollView extends StatefulWidget {
  const _ImageLibrarySliverScrollView({required this.slivers});

  final List<Widget> slivers;

  @override
  State<_ImageLibrarySliverScrollView> createState() =>
      _ImageLibrarySliverScrollViewState();
}

class _ImageLibrarySliverScrollViewState
    extends State<_ImageLibrarySliverScrollView> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      child: CustomScrollView(
        controller: _controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: widget.slivers,
      ),
    );
  }
}
