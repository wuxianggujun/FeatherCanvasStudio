import 'dart:io';

import 'package:flutter/material.dart';

import '../models/image_asset_kind.dart';
import '../models/image_library_item.dart';
import '../utils/display_labels.dart';

class ImageLibraryPreview extends StatelessWidget {
  const ImageLibraryPreview({required this.item, super.key});

  final ImageLibraryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!item.isImageFile) {
      return Center(
        child: Icon(
          Icons.gif_box_outlined,
          size: 42,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return Image.file(
      File(item.path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.error,
          ),
        );
      },
    );
  }
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
        imageAssetKindLabel(kind),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
