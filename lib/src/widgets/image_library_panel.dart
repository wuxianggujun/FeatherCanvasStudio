import 'package:flutter/material.dart';

import '../models/image_library_item.dart';
import '../models/ui_state.dart';
import '../theme/layout_constants.dart';
import '../utils/date_formatting.dart';
import '../utils/display_labels.dart';
import '../widgets/common_form_widgets.dart';
import 'image_library_common_widgets.dart';

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
                            child: ImageLibraryPreview(item: item),
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
                    ImageKindChip(kind: item.kind),
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
