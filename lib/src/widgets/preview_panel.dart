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
    required this.onMakeBackgroundTransparent,
    super.key,
  });

  final String? errorMessage;
  final List<GeneratedImage> generatedImages;
  final bool isGenerating;
  final ImageRequestDebugRecord? debugRecord;
  final VoidCallback onRetry;
  final void Function(int index, GeneratedImage image)
  onMakeBackgroundTransparent;

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
    if (isGenerating) {
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

    if (generatedImages.isEmpty) {
      return const PreviewStateSurface.empty(
        key: ValueKey('empty'),
        message: '生成后的图片会显示在这里',
      );
    }

    return LayoutBuilder(
      key: const ValueKey('images'),
      builder: (context, constraints) {
        final width = generatedImages.length <= 1 || constraints.maxWidth < 540
            ? constraints.maxWidth
            : (constraints.maxWidth - layoutGap) / 2;

        return Wrap(
          spacing: layoutGap,
          runSpacing: layoutGap,
          children: [
            for (var index = 0; index < generatedImages.length; index++)
              SizedBox(
                width: width,
                child: _GeneratedImageTile(
                  image: generatedImages[index],
                  onMakeBackgroundTransparent: () =>
                      onMakeBackgroundTransparent(
                        index,
                        generatedImages[index],
                      ),
                ),
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
    required this.onMakeBackgroundTransparent,
  });

  final GeneratedImage image;
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: _buildImageContent(),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: theme.colorScheme.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8),
                  child: IconButton(
                    tooltip: '背景转透明',
                    onPressed: onMakeBackgroundTransparent,
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    visualDensity: VisualDensity.compact,
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

  Widget _buildImageContent() {
    if (image.filePath != null) {
      return Image.file(File(image.filePath!), fit: BoxFit.cover);
    }

    if (image.bytes != null) {
      return Image.memory(image.bytes!, fit: BoxFit.cover);
    }

    return Image.network(
      image.url!,
      fit: BoxFit.cover,
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
