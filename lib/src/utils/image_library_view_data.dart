import '../models/image_asset_kind.dart';
import '../models/image_library_item.dart';
import '../models/ui_state.dart';
import 'display_labels.dart';
import 'image_library_filters.dart';

class ImageLibraryViewData {
  const ImageLibraryViewData({
    required this.availableItems,
    required this.visibleItems,
    required this.filteredItems,
    required this.availableProjects,
    required this.availableTags,
    required this.savedFrameCounts,
    required this.groupedFrameCount,
  });

  final List<ImageLibraryItem> availableItems;
  final List<ImageLibraryItem> visibleItems;
  final List<ImageLibraryItem> filteredItems;
  final List<String> availableProjects;
  final List<String> availableTags;
  final Map<String, int> savedFrameCounts;
  final int groupedFrameCount;

  int savedFrameCountFor(ImageLibraryItem item) {
    final groupId = item.groupId;
    return groupId == null ? 0 : savedFrameCounts[groupId] ?? 0;
  }
}

ImageLibraryViewData buildImageLibraryViewData({
  required List<ImageLibraryItem> library,
  required ImageLibraryKindFilter filter,
  required ImageLibrarySortOrder sortOrder,
  required String searchQuery,
  required bool showStandaloneFrames,
  String projectFilter = '',
  String tagFilter = '',
}) {
  final availableItems = [
    for (final item in library)
      if (item.existsSync) item,
  ];
  final sheetGroupIds = <String>{
    for (final item in availableItems)
      if (item.kind == ImageAssetKind.spriteSheet && item.groupId != null)
        item.groupId!,
  };
  final savedFrameCounts = <String, int>{};
  for (final item in availableItems) {
    if (item.kind == ImageAssetKind.spriteFrame &&
        item.groupId != null &&
        sheetGroupIds.contains(item.groupId)) {
      savedFrameCounts[item.groupId!] =
          (savedFrameCounts[item.groupId!] ?? 0) + 1;
    }
  }
  final visibleItems = [
    for (final item in availableItems)
      if (!(item.kind == ImageAssetKind.spriteFrame &&
          item.groupId != null &&
          sheetGroupIds.contains(item.groupId) &&
          !showStandaloneFrames))
        item,
  ];
  final availableProjects = _sortedDistinctStrings([
    for (final item in visibleItems) item.project,
  ]);
  final availableTags = _sortedDistinctStrings([
    for (final item in visibleItems) ...item.tags,
  ]);
  final filteredItems = [
    for (final item in visibleItems)
      if (imageLibraryKindFilterMatches(filter, item.kind) &&
          imageLibraryItemMatchesProject(item, projectFilter) &&
          imageLibraryItemMatchesTag(item, tagFilter) &&
          imageLibraryItemMatchesSearch(item, searchQuery))
        item,
  ]..sort((a, b) => compareImageLibraryItems(a, b, sortOrder));
  final groupedFrameCount = availableItems
      .where(
        (item) =>
            item.kind == ImageAssetKind.spriteFrame &&
            item.groupId != null &&
            sheetGroupIds.contains(item.groupId),
      )
      .length;

  return ImageLibraryViewData(
    availableItems: availableItems,
    visibleItems: visibleItems,
    filteredItems: filteredItems,
    availableProjects: availableProjects,
    availableTags: availableTags,
    savedFrameCounts: savedFrameCounts,
    groupedFrameCount: groupedFrameCount,
  );
}

List<String> _sortedDistinctStrings(Iterable<String> values) {
  final valuesByKey = <String, String>{};
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      continue;
    }
    valuesByKey.putIfAbsent(normalized.toLowerCase(), () => normalized);
  }

  return valuesByKey.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}
