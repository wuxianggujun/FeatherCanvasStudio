part of 'image_library_panel.dart';

class _ImageLibraryTile extends StatelessWidget {
  const _ImageLibraryTile({
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onSelectionChanged,
    required this.onSelectionDragStart,
    required this.onSelectionDragEnter,
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
    required this.savedFrameCount,
  });

  final ImageLibraryItem item;
  final bool selected;
  final bool selectionMode;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onSelectionDragStart;
  final VoidCallback onSelectionDragEnter;
  final VoidCallback onOpenAnimationProject;
  final VoidCallback onUseInEditor;
  final VoidCallback onReuseGeneration;
  final VoidCallback onCopyGeneration;
  final VoidCallback onMakeBackgroundTransparent;
  final VoidCallback onEditMetadata;
  final VoidCallback onCopyImage;
  final VoidCallback onExportImage;
  final VoidCallback onCopyPath;
  final VoidCallback onOpenLocation;
  final VoidCallback onDelete;
  final VoidCallback onOpenSliceExplorer;
  final int savedFrameCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSheetWithMeta = item.isSpriteSheetWithMetadata;
    final isAnimationProject = item.kind == ImageAssetKind.animationProject;
    final canOpenInEditor =
        item.canUseAsSpriteSheet ||
        (item.isImageFile && item.kind != ImageAssetKind.gif);
    final totalFrames = item.totalFrameCount;
    final generation = item.generation;
    final displayPrompt = item.prompt ?? generation?.prompt;
    final primaryActionStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    const compactActionConstraints = BoxConstraints.tightFor(
      width: 40,
      height: 40,
    );

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
          onTap: selectionMode
              ? () => onSelectionChanged(!selected)
              : isAnimationProject
              ? onOpenAnimationProject
              : isSheetWithMeta
              ? onOpenSliceExplorer
              : generation != null
              ? onReuseGeneration
              : canOpenInEditor
              ? onUseInEditor
              : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MouseRegion(
                    onEnter: (_) => onSelectionDragEnter(),
                    child: Listener(
                      onPointerDown: (_) => onSelectionDragStart(),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: double.infinity,
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: ImageLibraryPreview(item: item),
                              ),
                            ),
                          ),
                          if (selectionMode || selected)
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
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$savedFrameCount/$totalFrames 帧',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
                          style: primaryActionStyle,
                          icon: const Icon(Icons.dashboard_customize_outlined),
                          label: const Text('切片'),
                        ),
                      )
                    else if (isAnimationProject)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onOpenAnimationProject,
                          style: primaryActionStyle,
                          icon: const Icon(Icons.account_tree_outlined),
                          label: const Text('打开'),
                        ),
                      )
                    else if (generation != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReuseGeneration,
                          style: primaryActionStyle,
                          icon: const Icon(Icons.restore_outlined),
                          label: const Text('复用'),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canOpenInEditor ? onUseInEditor : null,
                          style: primaryActionStyle,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('编辑'),
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: '编辑作品信息',
                      onPressed: onEditMetadata,
                      constraints: compactActionConstraints,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.drive_file_rename_outline),
                    ),
                    SizedBox.square(
                      dimension: 40,
                      child: PopupMenuButton<ImageLibraryTileMenuAction>(
                        tooltip: '更多操作',
                        padding: EdgeInsets.zero,
                        iconSize: 22,
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (action) {
                          switch (action) {
                            case ImageLibraryTileMenuAction
                                .openAnimationProject:
                              onOpenAnimationProject();
                            case ImageLibraryTileMenuAction.useInEditor:
                              onUseInEditor();
                            case ImageLibraryTileMenuAction.reuseGeneration:
                              onReuseGeneration();
                            case ImageLibraryTileMenuAction.copyGeneration:
                              onCopyGeneration();
                            case ImageLibraryTileMenuAction
                                .makeBackgroundTransparent:
                              onMakeBackgroundTransparent();
                            case ImageLibraryTileMenuAction.copyImage:
                              onCopyImage();
                            case ImageLibraryTileMenuAction.exportImage:
                              onExportImage();
                            case ImageLibraryTileMenuAction.copyPath:
                              onCopyPath();
                            case ImageLibraryTileMenuAction.openLocation:
                              onOpenLocation();
                            case ImageLibraryTileMenuAction.delete:
                              onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          if (isAnimationProject)
                            const PopupMenuItem(
                              value: ImageLibraryTileMenuAction
                                  .openAnimationProject,
                              child: _ImageLibraryTileMenuEntry(
                                icon: Icons.account_tree_outlined,
                                label: '打开动画工程',
                              ),
                            ),
                          if (canOpenInEditor)
                            const PopupMenuItem(
                              value: ImageLibraryTileMenuAction.useInEditor,
                              child: _ImageLibraryTileMenuEntry(
                                icon: Icons.edit_outlined,
                                label: '在编辑器中打开',
                              ),
                            ),
                          if (generation != null) ...[
                            const PopupMenuItem(
                              value: ImageLibraryTileMenuAction.reuseGeneration,
                              child: _ImageLibraryTileMenuEntry(
                                icon: Icons.restore_outlined,
                                label: '复用生成参数',
                              ),
                            ),
                            const PopupMenuItem(
                              value: ImageLibraryTileMenuAction.copyGeneration,
                              child: _ImageLibraryTileMenuEntry(
                                icon: Icons.content_copy_outlined,
                                label: '复制生成参数',
                              ),
                            ),
                          ],
                          if (item.canMakeBackgroundTransparent)
                            const PopupMenuItem(
                              value: ImageLibraryTileMenuAction
                                  .makeBackgroundTransparent,
                              child: _ImageLibraryTileMenuEntry(
                                icon: Icons.auto_fix_high_outlined,
                                label: '背景转透明',
                              ),
                            ),
                          if (item.isImageFile)
                            const PopupMenuItem(
                              value: ImageLibraryTileMenuAction.copyImage,
                              child: _ImageLibraryTileMenuEntry(
                                icon: Icons.content_copy_outlined,
                                label: '复制图片',
                              ),
                            ),
                          PopupMenuItem(
                            value: ImageLibraryTileMenuAction.exportImage,
                            child: _ImageLibraryTileMenuEntry(
                              icon: Icons.file_download_outlined,
                              label: item.isImageFile ? '导出图片' : '导出文件',
                            ),
                          ),
                          const PopupMenuItem(
                            value: ImageLibraryTileMenuAction.copyPath,
                            child: _ImageLibraryTileMenuEntry(
                              icon: Icons.copy_outlined,
                              label: '复制路径',
                            ),
                          ),
                          const PopupMenuItem(
                            value: ImageLibraryTileMenuAction.openLocation,
                            child: _ImageLibraryTileMenuEntry(
                              icon: Icons.folder_open_outlined,
                              label: '打开位置',
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: ImageLibraryTileMenuAction.delete,
                            child: _ImageLibraryTileMenuEntry(
                              icon: Icons.delete_outline,
                              label: '删除作品',
                              destructive: true,
                            ),
                          ),
                        ],
                      ),
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

class _ImageLibraryTileMenuEntry extends StatelessWidget {
  const _ImageLibraryTileMenuEntry({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 168, maxWidth: 196),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
