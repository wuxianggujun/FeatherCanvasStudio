import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/image_library_item.dart';
import '../models/ui_state.dart';
import '../theme/layout_constants.dart';
import '../widgets/image_library_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';

typedef ImageLibraryMetadataEdit = ({
  String title,
  String note,
  String project,
  List<String> tags,
});

Future<ImagePickSource?> showImagePickSourceDialog(
  BuildContext context, {
  required String title,
  required bool allowLibrary,
  String? libraryEmptyMessage,
}) {
  return showDialog<ImagePickSource>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesktopPickSourceTile(
                icon: Icons.folder_open_outlined,
                title: '从本地文件选择',
                subtitle: '打开电脑文件选择窗口',
                onTap: () =>
                    Navigator.of(context).pop(ImagePickSource.localFile),
              ),
              const SizedBox(height: 8),
              DesktopPickSourceTile(
                icon: Icons.collections_bookmark_outlined,
                title: '从作品库选择',
                subtitle: allowLibrary
                    ? '直接使用已保存到作品库的图片'
                    : libraryEmptyMessage ?? '作品库还没有可用图片',
                onTap: () =>
                    Navigator.of(context).pop(ImagePickSource.imageLibrary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
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
        return AlertDialog(
          title: const Text('编辑作品信息'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '标题'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: fieldGap),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    hintText: '记录用途、版本或修改说明',
                  ),
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: fieldGap),
                TextField(
                  controller: projectController,
                  decoration: const InputDecoration(
                    labelText: '项目',
                    hintText: '例如：角色 A、Demo 游戏、UI 图标集',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: fieldGap),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: '标签',
                    hintText: '用逗号分隔，例如：idle, run, pixel',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
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
              child: const Text('保存'),
            ),
          ],
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
      final isBatch = items.length > 1;
      final cascadeText = cascadeCount > 0
          ? '\n同时会移除 $cascadeCount 个关联的切片帧。'
          : '';
      return AlertDialog(
        title: Text(isBatch ? '删除 ${items.length} 个作品' : '删除作品'),
        content: Text(
          isBatch
              ? '将从作品库移除这些作品，并删除应用缓存中的对应文件。'
                    '$cascadeText\n此操作不可撤销。'
              : '将从作品库移除「${items.single.displayTitle}」，'
                    '并删除应用缓存中的对应文件。$cascadeText\n此操作不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认删除'),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

Future<bool> confirmResetToDefaultsDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('恢复默认表单'),
        content: const Text(
          '会清空当前接口配置、提示词、预览结果和本地临时选择，'
          '作品库中的已保存文件不会被删除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('恢复默认'),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}
