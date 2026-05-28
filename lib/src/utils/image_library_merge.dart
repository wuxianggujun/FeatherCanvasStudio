import '../models/image_library_item.dart';

class ImageLibraryMergePatch {
  const ImageLibraryMergePatch({
    this.appendedItems = const <ImageLibraryItem>[],
    this.removedItemIds = const <String>{},
  });

  const ImageLibraryMergePatch.append(List<ImageLibraryItem> items)
    : appendedItems = items,
      removedItemIds = const <String>{};

  const ImageLibraryMergePatch.removeIds(Set<String> ids)
    : appendedItems = const <ImageLibraryItem>[],
      removedItemIds = ids;

  final List<ImageLibraryItem> appendedItems;
  final Set<String> removedItemIds;

  List<ImageLibraryItem> applyTo(List<ImageLibraryItem> currentLibrary) {
    final appendedIds = {for (final item in appendedItems) item.id};
    return [
      ...appendedItems,
      for (final item in currentLibrary)
        if (!removedItemIds.contains(item.id) && !appendedIds.contains(item.id))
          item,
    ];
  }
}

List<ImageLibraryItem> mergeImageLibraryItems({
  required List<ImageLibraryItem> currentLibrary,
  List<ImageLibraryItem> appendedItems = const <ImageLibraryItem>[],
  Set<String> removedItemIds = const <String>{},
}) {
  return ImageLibraryMergePatch(
    appendedItems: appendedItems,
    removedItemIds: removedItemIds,
  ).applyTo(currentLibrary);
}
