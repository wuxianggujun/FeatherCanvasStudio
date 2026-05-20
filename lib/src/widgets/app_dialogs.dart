import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/image_library_item.dart';
import '../models/ui_state.dart';
import '../services/sprite_sheet_service.dart';
import '../l10n/app_l10n.dart';
import '../theme/layout_constants.dart';
import '../widgets/image_library_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';

typedef ImageLibraryMetadataEdit = ({
  String title,
  String note,
  String project,
  List<String> tags,
});

enum FirstRunSetupAction { openApiSettings, later }

Future<FirstRunSetupAction?> showFirstRunSetupDialog(BuildContext context) {
  return showDialog<FirstRunSetupAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final l10n = appL10nOf(context);
      return FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: AlertDialog(
          title: Text(l10n.firstRunSetupTitle),
          content: SizedBox(width: 520, child: Text(l10n.firstRunSetupMessage)),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(FirstRunSetupAction.later),
              child: Text(l10n.firstRunSetupLater),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pop(FirstRunSetupAction.openApiSettings),
              icon: const Icon(Icons.tune_outlined),
              label: Text(l10n.firstRunSetupOpenApiSettings),
            ),
          ],
        ),
      );
    },
  );
}

Future<ImagePickSource?> showImagePickSourceDialog(
  BuildContext context, {
  required String title,
  required bool allowLibrary,
  String? libraryEmptyMessage,
}) {
  return showDialog<ImagePickSource>(
    context: context,
    builder: (context) {
      final l10n = appL10nOf(context);
      return FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopPickSourceTile(
                  icon: Icons.folder_open_outlined,
                  title: l10n.pickSourceLocalFileTitle,
                  subtitle: l10n.pickSourceLocalFileSubtitle,
                  onTap: () =>
                      Navigator.of(context).pop(ImagePickSource.localFile),
                ),
                const SizedBox(height: 8),
                DesktopPickSourceTile(
                  icon: Icons.collections_bookmark_outlined,
                  title: l10n.pickSourceImageLibraryTitle,
                  subtitle: allowLibrary
                      ? l10n.pickSourceImageLibrarySubtitle
                      : libraryEmptyMessage ?? l10n.pickSourceImageLibraryEmpty,
                  onTap: () =>
                      Navigator.of(context).pop(ImagePickSource.imageLibrary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelAction),
            ),
          ],
        ),
      );
    },
  );
}

Future<T?> showImageLibraryPickerDialog<T extends Object>(
  BuildContext context, {
  required String title,
  required List<ImageLibraryItem> items,
  bool allowMultiple = false,
}) async {
  final result = await showDialog<Object>(
    context: context,
    builder: (context) {
      return ImageLibraryPickerDialog(
        title: title,
        items: items,
        allowMultiple: allowMultiple,
      );
    },
  );

  return result is T ? result : null;
}

Future<List<MapEntry<int, Uint8List>>?> showSpriteSheetSlicePicker(
  BuildContext context, {
  required ImageLibraryItem sheet,
  required bool allowMultiple,
  String? title,
}) {
  return showDialog<List<MapEntry<int, Uint8List>>>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return SpriteSheetSlicePickerDialog(
        sheet: sheet,
        allowMultiple: allowMultiple,
        title: title,
      );
    },
  );
}

Future<void> showSpriteSheetSliceExplorer(
  BuildContext context, {
  required ImageLibraryItem sheet,
  required Set<int> savedFrameIndexes,
  required Future<bool> Function(int frameIndex, Uint8List bytes) onSaveSlice,
  required Future<int> Function(List<MapEntry<int, Uint8List>> framesToSave)
  onSaveAllSlices,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return SpriteSheetSliceExplorerDialog(
        sheet: sheet,
        savedFrameIndexes: savedFrameIndexes,
        onSaveSlice: onSaveSlice,
        onSaveAllSlices: onSaveAllSlices,
      );
    },
  );
}

Future<ImageLibraryMetadataEdit?> showImageLibraryMetadataDialog(
  BuildContext context,
  ImageLibraryItem item,
) async {
  final titleController = TextEditingController(text: item.displayTitle);
  final noteController = TextEditingController(text: item.note);
  final projectController = TextEditingController(text: item.project);
  final tagsController = TextEditingController(text: item.tags.join(', '));
  try {
    return await showDialog<ImageLibraryMetadataEdit>(
      context: context,
      builder: (context) {
        final l10n = appL10nOf(context);
        return FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: AlertDialog(
            title: Text(l10n.imageLibraryEditMetadataTitle),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.imageLibraryMetadataTitleLabel,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: fieldGap),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: l10n.imageLibraryMetadataNoteLabel,
                      hintText: l10n.imageLibraryMetadataNoteHint,
                    ),
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: fieldGap),
                  TextField(
                    controller: projectController,
                    decoration: InputDecoration(
                      labelText: l10n.imageLibraryProjectLabel,
                      hintText: l10n.imageLibraryMetadataProjectHint,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: fieldGap),
                  TextField(
                    controller: tagsController,
                    decoration: InputDecoration(
                      labelText: l10n.imageLibraryTagLabel,
                      hintText: l10n.imageLibraryMetadataTagsHint,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancelAction),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop((
                  title: titleController.text,
                  note: noteController.text,
                  project: projectController.text,
                  tags: tagsController.text
                      .split(RegExp(r'[,，]'))
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList(),
                )),
                child: Text(l10n.saveAction),
              ),
            ],
          ),
        );
      },
    );
  } finally {
    titleController.dispose();
    noteController.dispose();
    projectController.dispose();
    tagsController.dispose();
  }
}

Future<bool> confirmDeleteImageLibraryItemsDialog(
  BuildContext context, {
  required List<ImageLibraryItem> items,
  required int cascadeCount,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = appL10nOf(context);
      final isBatch = items.length > 1;
      final cascadeText = cascadeCount > 0
          ? '\n${l10n.imageLibraryDeleteCascade(cascadeCount)}'
          : '';
      return FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: AlertDialog(
          title: Text(
            isBatch
                ? l10n.imageLibraryDeleteBatchTitle(items.length)
                : l10n.imageLibraryDeleteOneTitle,
          ),
          content: Text(
            isBatch
                ? l10n.imageLibraryDeleteBatchMessage(cascadeText)
                : l10n.imageLibraryDeleteOneMessage(
                    items.single.displayTitle,
                    cascadeText,
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.confirmDeleteAction),
            ),
          ],
        ),
      );
    },
  );

  return confirmed == true;
}

Future<bool> confirmResetToDefaultsDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = appL10nOf(context);
      return FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: AlertDialog(
          title: Text(l10n.resetDefaultsTitle),
          content: Text(l10n.resetDefaultsMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.resetDefaultsAction),
            ),
          ],
        ),
      );
    },
  );

  return confirmed == true;
}

Future<bool> confirmSpriteSheetFrameReplacementDialog(
  BuildContext context, {
  required SpriteSheetFrameReplacementPreview preview,
  required int columns,
  required String fitLabel,
}) async {
  final frameNumber = preview.frameIndex + 1;
  final safeColumns = columns.clamp(1, 9999).toInt();
  final row = preview.frameIndex ~/ safeColumns + 1;
  final column = preview.frameIndex % safeColumns + 1;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final theme = Theme.of(context);
      final l10n = appL10nOf(context);
      return FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: AlertDialog(
          title: Text(l10n.spriteSheetReplaceFrameTitle(frameNumber)),
          content: SizedBox(
            width: 860,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.spriteSheetReplaceFrameTarget(
                      row,
                      column,
                      preview.frameWidth,
                      preview.frameHeight,
                      fitLabel,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: fieldGap),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 700) {
                        return Column(
                          children: [
                            _ReplacementPreviewTile(
                              title: l10n.spriteSheetOriginalFrame,
                              imageBytes: preview.originalFrameBytes,
                            ),
                            const SizedBox(height: fieldGap),
                            _ReplacementPreviewTile(
                              title: l10n.spriteSheetPatchFrame,
                              imageBytes: preview.patchBytes,
                            ),
                            const SizedBox(height: fieldGap),
                            _ReplacementPreviewTile(
                              title: l10n.spriteSheetReplacementResult,
                              imageBytes: preview.resultFrameBytes,
                              emphasized: true,
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ReplacementPreviewTile(
                              title: l10n.spriteSheetOriginalFrame,
                              imageBytes: preview.originalFrameBytes,
                            ),
                          ),
                          const SizedBox(width: fieldGap),
                          Expanded(
                            child: _ReplacementPreviewTile(
                              title: l10n.spriteSheetPatchFrame,
                              imageBytes: preview.patchBytes,
                            ),
                          ),
                          const SizedBox(width: fieldGap),
                          Expanded(
                            child: _ReplacementPreviewTile(
                              title: l10n.spriteSheetReplacementResult,
                              imageBytes: preview.resultFrameBytes,
                              emphasized: true,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelAction),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.published_with_changes_outlined),
              label: Text(l10n.spriteSheetConfirmReplace),
            ),
          ],
        ),
      );
    },
  );

  return confirmed == true;
}

class _ReplacementPreviewTile extends StatelessWidget {
  const _ReplacementPreviewTile({
    required this.title,
    required this.imageBytes,
    this.emphasized = false,
  });

  final String title;
  final Uint8List imageBytes;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = emphasized
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return Semantics(
      container: true,
      image: true,
      label: title,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: emphasized ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Text(title, style: theme.textTheme.labelLarge),
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                child: ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                    semanticLabel: title,
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
