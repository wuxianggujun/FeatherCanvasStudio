import 'dart:async';

import '../models/image_library_item.dart';

class ImageLibrarySelectedExportPlan {
  const ImageLibrarySelectedExportPlan({
    required this.selectedItems,
    required this.existingItems,
    required this.missingCount,
  });

  final List<ImageLibraryItem> selectedItems;
  final List<ImageLibraryItem> existingItems;
  final int missingCount;

  bool get hasExistingFiles => existingItems.isNotEmpty;
}

List<ImageLibraryItem> selectedImageLibraryItemsForExport({
  required List<ImageLibraryItem> library,
  required Set<String> selectedItemIds,
}) {
  return [
    for (final item in library)
      if (selectedItemIds.contains(item.id)) item,
  ];
}

Future<ImageLibrarySelectedExportPlan> buildImageLibrarySelectedExportPlan({
  required List<ImageLibraryItem> selectedItems,
  required FutureOr<bool> Function(ImageLibraryItem item) itemExists,
}) async {
  final existingItems = <ImageLibraryItem>[];
  var missingCount = 0;
  for (final item in selectedItems) {
    if (await itemExists(item)) {
      existingItems.add(item);
    } else {
      missingCount += 1;
    }
  }

  return ImageLibrarySelectedExportPlan(
    selectedItems: selectedItems,
    existingItems: existingItems,
    missingCount: missingCount,
  );
}
