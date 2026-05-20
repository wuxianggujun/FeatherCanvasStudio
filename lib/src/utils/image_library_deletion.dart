import '../models/image_asset_kind.dart';
import '../models/image_library_item.dart';

class ImageLibraryDeletePlan {
  const ImageLibraryDeletePlan({
    required this.selectedItems,
    required this.cascadeChildFrames,
    required this.ids,
  });

  final List<ImageLibraryItem> selectedItems;
  final List<ImageLibraryItem> cascadeChildFrames;
  final Set<String> ids;
}

class ImageLibraryDeleteImpact {
  const ImageLibraryDeleteImpact({
    required this.removedItems,
    required this.removedPaths,
    required this.remainingItems,
    this.trashPaths = const <String, String>{},
  });

  final List<ImageLibraryItem> removedItems;
  final Set<String> removedPaths;
  final List<ImageLibraryItem> remainingItems;

  /// 原始路径 -> 回收站路径。当删除走回收站模式时填充,空表示走硬删除。
  final Map<String, String> trashPaths;

  ImageLibraryDeleteImpact withTrashPaths(Map<String, String> trashPaths) =>
      ImageLibraryDeleteImpact(
        removedItems: removedItems,
        removedPaths: removedPaths,
        remainingItems: remainingItems,
        trashPaths: trashPaths,
      );
}

class ImageLibraryReferenceCleanup {
  const ImageLibraryReferenceCleanup({
    required this.selectedItemIds,
    required this.editorImagePath,
    required this.editorPatchImagePath,
    required this.imageTemplateImagePath,
    required this.animationTemplateImagePath,
  });

  final Set<String> selectedItemIds;
  final String? editorImagePath;
  final String? editorPatchImagePath;
  final String? imageTemplateImagePath;
  final String? animationTemplateImagePath;
}

ImageLibraryDeletePlan buildImageLibraryDeletePlan({
  required List<ImageLibraryItem> library,
  required List<ImageLibraryItem> selectedItems,
}) {
  final selectedIds = selectedItems.map((item) => item.id).toSet();
  final selectedSpriteSheetGroupIds = {
    for (final item in selectedItems)
      if (item.kind == ImageAssetKind.spriteSheet && item.groupId != null)
        item.groupId!,
  };
  final cascadeChildFrames = [
    for (final item in library)
      if (item.kind == ImageAssetKind.spriteFrame &&
          item.groupId != null &&
          selectedSpriteSheetGroupIds.contains(item.groupId) &&
          !selectedIds.contains(item.id))
        item,
  ];

  return ImageLibraryDeletePlan(
    selectedItems: selectedItems,
    cascadeChildFrames: cascadeChildFrames,
    ids: {...selectedIds, for (final frame in cascadeChildFrames) frame.id},
  );
}

ImageLibraryDeleteImpact buildImageLibraryDeleteImpact(
  List<ImageLibraryItem> library,
  Set<String> ids,
) {
  final removedItems = [
    for (final item in library)
      if (ids.contains(item.id)) item,
  ];

  return ImageLibraryDeleteImpact(
    removedItems: removedItems,
    removedPaths: {
      for (final item in removedItems)
        if (item.path.isNotEmpty) item.path,
    },
    remainingItems: [
      for (final item in library)
        if (!ids.contains(item.id)) item,
    ],
  );
}

ImageLibraryReferenceCleanup cleanDeletedImageLibraryReferences({
  required Set<String> removedIds,
  required Set<String> removedPaths,
  required Set<String> selectedItemIds,
  required String? editorImagePath,
  required String? editorPatchImagePath,
  required String? imageTemplateImagePath,
  required String? animationTemplateImagePath,
}) {
  return ImageLibraryReferenceCleanup(
    selectedItemIds: {
      for (final id in selectedItemIds)
        if (!removedIds.contains(id)) id,
    },
    editorImagePath: _clearRemovedPath(editorImagePath, removedPaths),
    editorPatchImagePath: _clearRemovedPath(editorPatchImagePath, removedPaths),
    imageTemplateImagePath: _clearRemovedPath(
      imageTemplateImagePath,
      removedPaths,
    ),
    animationTemplateImagePath: _clearRemovedPath(
      animationTemplateImagePath,
      removedPaths,
    ),
  );
}

String? _clearRemovedPath(String? path, Set<String> removedPaths) {
  return path != null && removedPaths.contains(path) ? null : path;
}
