import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../models/image_asset_kind.dart';
import '../models/image_library_item.dart';
import '../utils/localized_display_labels.dart';

class ImageLibraryPreview extends StatelessWidget {
  const ImageLibraryPreview({required this.item, super.key});

  final ImageLibraryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticLabel =
        '${localizedImageAssetKindLabel(appL10nOf(context), item.kind)} · '
        '${item.displayTitle}';
    if (!item.isImageFile) {
      final icon = item.kind == ImageAssetKind.animationProject
          ? Icons.movie_creation_outlined
          : Icons.gif_box_outlined;
      return Semantics(
        container: true,
        label: semanticLabel,
        image: true,
        child: Center(
          child: Icon(icon, size: 42, color: theme.colorScheme.primary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final cacheWidth = _scaledCacheDimension(
          constraints.maxWidth,
          devicePixelRatio,
        );
        final cacheHeight = _scaledCacheDimension(
          constraints.maxHeight,
          devicePixelRatio,
        );

        return Semantics(
          container: true,
          label: semanticLabel,
          image: true,
          child: Image.file(
            File(item.path),
            fit: BoxFit.contain,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: theme.colorScheme.error,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

int? _scaledCacheDimension(double logicalPixels, double devicePixelRatio) {
  if (!logicalPixels.isFinite || logicalPixels <= 0) {
    return null;
  }
  return (logicalPixels * devicePixelRatio).ceil().clamp(1, 4096);
}

class ImageKindChip extends StatelessWidget {
  const ImageKindChip({required this.kind, super.key});

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
        localizedImageAssetKindLabel(appL10nOf(context), kind),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
