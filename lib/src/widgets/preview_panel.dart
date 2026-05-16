import 'dart:io';

import 'package:flutter/material.dart';

import '../models/generated_image.dart';
import '../services/image_api_client.dart';
import '../theme/layout_constants.dart';
import 'preview_common_widgets.dart';

class PreviewPanel extends StatelessWidget {
  const PreviewPanel({
    required this.errorMessage,
    required this.generatedImages,
    required this.isGenerating,
    required this.debugRecord,
    required this.onRetry,
    required this.onCopyImage,
    required this.onExportImage,
    required this.onMakeBackgroundTransparent,
    this.targetImageCount,
    super.key,
  });

  final String? errorMessage;
  final List<GeneratedImage> generatedImages;
  final bool isGenerating;
  final ImageRequestDebugRecord? debugRecord;
  final VoidCallback onRetry;
  final void Function(int index, GeneratedImage image) onCopyImage;
  final void Function(int index, GeneratedImage image) onExportImage;
  final void Function(int index, GeneratedImage image)
  onMakeBackgroundTransparent;
  final int? targetImageCount;

  @override
  Widget build(BuildContext context) {
    return PreviewPanelShell(
      title: '结果预览',
      debugRecord: debugRecord,
      showDebugButton: true,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final effectiveTargetCount = targetImageCount == null
        ? generatedImages.length
        : targetImageCount!.clamp(0, 10000).toInt();
    final pendingCount = isGenerating
        ? (effectiveTargetCount - generatedImages.length)
              .clamp(0, 10000)
              .toInt()
        : 0;

    if (isGenerating && generatedImages.isEmpty && pendingCount == 0) {
      return const PreviewStateSurface.loading(
        key: ValueKey('loading'),
        message: '正在生成图片',
      );
    }

    if (errorMessage != null) {
      return PreviewStateSurface.error(
        key: const ValueKey('error'),
        title: '生成失败',
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    if (generatedImages.isEmpty && pendingCount == 0) {
      return const PreviewStateSurface.empty(
        key: ValueKey('empty'),
        message: '生成后的图片会显示在这里',
      );
    }

    return LayoutBuilder(
      key: const ValueKey('images'),
      builder: (context, constraints) {
        final totalCount = generatedImages.length + pendingCount;
        final isCompact = totalCount > 4 || pendingCount > 0;
        final minTileWidth = isCompact ? 112.0 : 260.0;
        final columns = totalCount <= 1 || constraints.maxWidth < minTileWidth
            ? 1
            : (constraints.maxWidth / minTileWidth).floor().clamp(1, 6);
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - layoutGap * (columns - 1)) / columns;

        return Wrap(
          spacing: layoutGap,
          runSpacing: layoutGap,
          children: [
            for (var index = 0; index < generatedImages.length; index++)
              SizedBox(
                width: width,
                child: _GeneratedImageTile(
                  image: generatedImages[index],
                  previewIndex: index,
                  onCopyImage: () => onCopyImage(index, generatedImages[index]),
                  onExportImage: () =>
                      onExportImage(index, generatedImages[index]),
                  onMakeBackgroundTransparent: () =>
                      onMakeBackgroundTransparent(
                        index,
                        generatedImages[index],
                      ),
                ),
              ),
            for (var index = 0; index < pendingCount; index++)
              SizedBox(
                width: width,
                child: _PendingImageTile(index: generatedImages.length + index),
              ),
          ],
        );
      },
    );
  }
}

class _GeneratedImageTile extends StatelessWidget {
  const _GeneratedImageTile({
    required this.image,
    required this.previewIndex,
    required this.onCopyImage,
    required this.onExportImage,
    required this.onMakeBackgroundTransparent,
  });

  final GeneratedImage image;
  final int previewIndex;
  final VoidCallback onCopyImage;
  final VoidCallback onExportImage;
  final VoidCallback onMakeBackgroundTransparent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              Positioned.fill(
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => showGeneratedImagePreviewDialog(
                      context,
                      image: image,
                      title: '结果 ${previewIndex + 1}',
                      onCopyImage: onCopyImage,
                      onExportImage: onExportImage,
                    ),
                    child: _GeneratedImageContent(image: image),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: theme.colorScheme.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '复制图片',
                        onPressed: onCopyImage,
                        icon: const Icon(Icons.content_copy_outlined),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: '导出图片',
                        onPressed: onExportImage,
                        icon: const Icon(Icons.file_download_outlined),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: '背景转透明',
                        onPressed: onMakeBackgroundTransparent,
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (image.revisedPrompt != null && image.revisedPrompt!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            image.revisedPrompt!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _PendingImageTile extends StatelessWidget {
  const _PendingImageTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.72, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              );
            },
            onEnd: () {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
                const SizedBox(height: 8),
                Text(
                  '等待 ${index + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratedImageContent extends StatelessWidget {
  const _GeneratedImageContent({required this.image, this.fit = BoxFit.cover});

  final GeneratedImage image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (image.filePath != null) {
      return Image.file(File(image.filePath!), fit: fit);
    }

    if (image.bytes != null) {
      return Image.memory(image.bytes!, fit: fit);
    }

    return Image.network(
      image.url!,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('图片加载失败：$error'),
          ),
        );
      },
    );
  }
}

Future<void> showGeneratedImagePreviewDialog(
  BuildContext context, {
  required GeneratedImage image,
  required String title,
  VoidCallback? onCopyImage,
  VoidCallback? onExportImage,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980, maxHeight: 820),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (onCopyImage != null)
                      IconButton(
                        tooltip: '复制图片',
                        onPressed: onCopyImage,
                        icon: const Icon(Icons.content_copy_outlined),
                      ),
                    if (onExportImage != null)
                      IconButton(
                        tooltip: '导出图片',
                        onPressed: onExportImage,
                        icon: const Icon(Icons.file_download_outlined),
                      ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5,
                        child: Center(
                          child: _GeneratedImageContent(
                            image: image,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
