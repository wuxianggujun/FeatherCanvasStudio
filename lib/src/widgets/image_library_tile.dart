part of 'image_library_panel.dart';

class _ImageLibraryTile extends StatelessWidget {
  const _ImageLibraryTile({
    required this.item,
    required this.selected,
    required this.onSelectionChanged,
    required this.onUseInEditor,
    required this.onReuseGeneration,
    required this.onCopyGeneration,
    required this.onMakeBackgroundTransparent,
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
  final VoidCallback onMakeBackgroundTransparent;
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
                          case ImageLibraryTileMenuAction
                              .makeBackgroundTransparent:
                            onMakeBackgroundTransparent();
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
                        if (item.canMakeBackgroundTransparent)
                          const PopupMenuItem(
                            value: ImageLibraryTileMenuAction
                                .makeBackgroundTransparent,
                            child: ListTile(
                              leading: Icon(Icons.auto_fix_high_outlined),
                              title: Text('背景转透明'),
                            ),
                          ),
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
