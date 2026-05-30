import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
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
    this.targetAspectRatio = 1,
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
  final double targetAspectRatio;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    return PreviewPanelShell(
      title: l10n.previewPanelTitle,
      debugRecord: debugRecord,
      showDebugButton: true,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = appL10nOf(context);
    final previewCount = generatedImages.length;
    final effectiveTargetCount = targetImageCount == null
        ? previewCount
        : targetImageCount!.clamp(0, 10000).toInt();
    final pendingCount = isGenerating
        ? (effectiveTargetCount - previewCount).clamp(0, 10000).toInt()
        : 0;

    if (isGenerating && previewCount == 0 && pendingCount == 0) {
      return PreviewStateSurface.loading(
        key: const ValueKey('loading'),
        message: l10n.previewGeneratingImage,
      );
    }

    if (errorMessage != null) {
      return PreviewStateSurface.error(
        key: const ValueKey('error'),
        title: l10n.previewGenerationFailed,
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    if (previewCount == 0 && pendingCount == 0) {
      return PreviewStateSurface.empty(
        key: const ValueKey('empty'),
        message: l10n.previewEmptyMessage,
      );
    }

    return LayoutBuilder(
      key: const ValueKey('images'),
      builder: (context, constraints) {
        final totalCount = previewCount + pendingCount;
        final tileAspectRatio = _normalizedPreviewAspectRatio(
          targetAspectRatio,
        );
        final isCompact = totalCount > 4 || pendingCount > 0;
        final minTileWidth = isCompact ? 112.0 : 260.0;
        final columns = totalCount <= 1 || constraints.maxWidth < minTileWidth
            ? 1
            : (constraints.maxWidth / minTileWidth).floor().clamp(1, 6);
        final tileWidth =
            (constraints.maxWidth - layoutGap * (columns - 1)) / columns;
        final imageHeight = tileWidth / tileAspectRatio;
        final hasCaption = generatedImages.any(
          (image) =>
              image.revisedPrompt != null && image.revisedPrompt!.isNotEmpty,
        );
        final captionHeight = hasCaption ? 96.0 : 0.0;
        final tileHeight = imageHeight + captionHeight;
        final rowCount = (totalCount / columns).ceil();
        final gridHeight = (rowCount * tileHeight + (rowCount - 1) * layoutGap)
            .clamp(180.0, 620.0)
            .toDouble();

        return SizedBox(
          height: gridHeight,
          child: GridView.builder(
            key: const ValueKey('preview-grid'),
            primary: false,
            itemCount: totalCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: layoutGap,
              mainAxisSpacing: layoutGap,
              childAspectRatio: tileWidth / tileHeight,
            ),
            itemBuilder: (context, index) {
              if (index >= previewCount) {
                return _PendingImageTile(
                  index: index,
                  aspectRatio: tileAspectRatio,
                );
              }

              final image = generatedImages[index];
              return _GeneratedImageTile(
                image: image,
                images: generatedImages,
                previewIndex: index,
                aspectRatio: tileAspectRatio,
                onCopyImage: onCopyImage,
                onExportImage: onExportImage,
                onMakeBackgroundTransparent: onMakeBackgroundTransparent,
              );
            },
          ),
        );
      },
    );
  }
}

class _GeneratedImageTile extends StatelessWidget {
  const _GeneratedImageTile({
    required this.image,
    required this.images,
    required this.previewIndex,
    required this.aspectRatio,
    required this.onCopyImage,
    required this.onExportImage,
    required this.onMakeBackgroundTransparent,
  });

  final GeneratedImage image;
  final List<GeneratedImage> images;
  final int previewIndex;
  final double aspectRatio;
  final void Function(int index, GeneratedImage image) onCopyImage;
  final void Function(int index, GeneratedImage image) onExportImage;
  final void Function(int index, GeneratedImage image)
  onMakeBackgroundTransparent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
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
                      images: images,
                      initialIndex: previewIndex,
                      title: l10n.previewResultTitle(previewIndex + 1),
                      titleBuilder: (index, _) =>
                          l10n.previewResultTitle(index + 1),
                      onCopyImageAt: onCopyImage,
                      onExportImageAt: onExportImage,
                    ),
                    child: _GeneratedImageContent(
                      image: image,
                      semanticLabel: l10n.previewResultTitle(previewIndex + 1),
                    ),
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
                        tooltip: l10n.copyImageTooltip,
                        onPressed: () => onCopyImage(previewIndex, image),
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
                        tooltip: l10n.exportImageTooltip,
                        onPressed: () => onExportImage(previewIndex, image),
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
                        tooltip: l10n.makeBackgroundTransparentTooltip,
                        onPressed: () =>
                            onMakeBackgroundTransparent(previewIndex, image),
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
  const _PendingImageTile({required this.index, required this.aspectRatio});

  final int index;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = appL10nOf(context);

    return AspectRatio(
      aspectRatio: aspectRatio,
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
                  l10n.previewPendingImage(index + 1),
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
  const _GeneratedImageContent({
    required this.image,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  final GeneratedImage image;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final cacheWidth = _scaledImageCacheDimension(
          constraints.maxWidth,
          devicePixelRatio,
        );
        final cacheHeight = _scaledImageCacheDimension(
          constraints.maxHeight,
          devicePixelRatio,
        );

        if (image.filePath != null) {
          return Image.file(
            File(image.filePath!),
            fit: fit,
            semanticLabel: semanticLabel,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          );
        }

        if (image.bytes != null) {
          return Image.memory(
            image.bytes!,
            fit: fit,
            semanticLabel: semanticLabel,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          );
        }

        return Image.network(
          image.url!,
          fit: fit,
          semanticLabel: semanticLabel,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            final l10n = appL10nOf(context);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.previewImageLoadFailed(error)),
              ),
            );
          },
        );
      },
    );
  }
}

int? _scaledImageCacheDimension(double logicalPixels, double devicePixelRatio) {
  if (!logicalPixels.isFinite || logicalPixels <= 0) {
    return null;
  }
  return (logicalPixels * devicePixelRatio).ceil().clamp(1, 4096);
}

double _normalizedPreviewAspectRatio(double aspectRatio) {
  if (!aspectRatio.isFinite || aspectRatio <= 0) {
    return 1;
  }
  return aspectRatio.clamp(1 / 3, 3).toDouble();
}

Future<void> showGeneratedImagePreviewDialog(
  BuildContext context, {
  required GeneratedImage image,
  required String title,
  List<GeneratedImage>? images,
  int initialIndex = 0,
  String Function(int index, GeneratedImage image)? titleBuilder,
  void Function(int index, GeneratedImage image)? onCopyImageAt,
  void Function(int index, GeneratedImage image)? onExportImageAt,
  VoidCallback? onCopyImage,
  VoidCallback? onExportImage,
}) {
  final previewImages = images == null || images.isEmpty ? [image] : images;
  final clampedInitialIndex = previewImages.length <= 1
      ? 0
      : initialIndex.clamp(0, previewImages.length - 1).toInt();

  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: _GeneratedImagePreviewDialog(
          images: previewImages,
          initialIndex: clampedInitialIndex,
          titleBuilder: titleBuilder ?? (_, _) => title,
          onCopyImage: onCopyImageAt,
          onExportImage: onExportImageAt,
          fallbackCopyImage: onCopyImage,
          fallbackExportImage: onExportImage,
        ),
      );
    },
  );
}

class _GeneratedImagePreviewDialog extends StatefulWidget {
  const _GeneratedImagePreviewDialog({
    required this.images,
    required this.initialIndex,
    required this.titleBuilder,
    required this.onCopyImage,
    required this.onExportImage,
    required this.fallbackCopyImage,
    required this.fallbackExportImage,
  });

  final List<GeneratedImage> images;
  final int initialIndex;
  final String Function(int index, GeneratedImage image) titleBuilder;
  final void Function(int index, GeneratedImage image)? onCopyImage;
  final void Function(int index, GeneratedImage image)? onExportImage;
  final VoidCallback? fallbackCopyImage;
  final VoidCallback? fallbackExportImage;

  @override
  State<_GeneratedImagePreviewDialog> createState() =>
      _GeneratedImagePreviewDialogState();
}

class _GeneratedImagePreviewDialogState
    extends State<_GeneratedImagePreviewDialog> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  GeneratedImage get _currentImage => widget.images[_currentIndex];

  bool get _canGoPrevious => _currentIndex > 0;

  bool get _canGoNext => _currentIndex < widget.images.length - 1;

  bool get _hasMultipleImages => widget.images.length > 1;

  void _goPrevious() {
    if (!_canGoPrevious) {
      return;
    }
    setState(() {
      _currentIndex -= 1;
    });
  }

  void _goNext() {
    if (!_canGoNext) {
      return;
    }
    setState(() {
      _currentIndex += 1;
    });
  }

  void _copyCurrentImage() {
    final callback = widget.onCopyImage;
    if (callback != null) {
      callback(_currentIndex, _currentImage);
      return;
    }
    widget.fallbackCopyImage?.call();
  }

  void _exportCurrentImage() {
    final callback = widget.onExportImage;
    if (callback != null) {
      callback(_currentIndex, _currentImage);
      return;
    }
    widget.fallbackExportImage?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final title = widget.titleBuilder(_currentIndex, _currentImage);
    final hasCopyAction =
        widget.onCopyImage != null || widget.fallbackCopyImage != null;
    final hasExportAction =
        widget.onExportImage != null || widget.fallbackExportImage != null;

    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
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
                  if (hasCopyAction)
                    IconButton(
                      tooltip: l10n.copyImageTooltip,
                      onPressed: _copyCurrentImage,
                      icon: const Icon(Icons.content_copy_outlined),
                    ),
                  if (hasExportAction)
                    IconButton(
                      tooltip: l10n.exportImageTooltip,
                      onPressed: _exportCurrentImage,
                      icon: const Icon(Icons.file_download_outlined),
                    ),
                  IconButton(
                    tooltip: l10n.closeAction,
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
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: InteractiveViewer(
                            key: ValueKey(_currentIndex),
                            minScale: 0.5,
                            maxScale: 5,
                            child: Center(
                              child: _GeneratedImageContent(
                                image: _currentImage,
                                fit: BoxFit.contain,
                                semanticLabel: title,
                              ),
                            ),
                          ),
                        ),
                        if (_hasMultipleImages) ...[
                          Positioned(
                            left: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _PreviewNavigationButton(
                                tooltip: l10n.previewPreviousImageTooltip,
                                icon: Icons.chevron_left,
                                onPressed: _canGoPrevious ? _goPrevious : null,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _PreviewNavigationButton(
                                tooltip: l10n.previewNextImageTooltip,
                                icon: Icons.chevron_right,
                                onPressed: _canGoNext ? _goNext : null,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewNavigationButton extends StatelessWidget {
  const _PreviewNavigationButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
