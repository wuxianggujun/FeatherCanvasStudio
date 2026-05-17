import '../models/image_library_item.dart';
import '../models/ui_state.dart';
import 'display_labels.dart';

bool imageLibraryItemMatchesSearch(ImageLibraryItem item, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return true;
  }

  final searchableText = [
    item.displayTitle,
    item.source,
    item.note,
    item.project,
    ...item.tags,
    item.prompt ?? '',
    item.generation?.prompt ?? '',
    item.generation?.negativePrompt ?? '',
    item.generation?.model ?? '',
    item.generation?.size ?? '',
    item.generation == null
        ? ''
        : apiProviderKindLabel(item.generation!.providerKind),
    item.animationProject?.title ?? '',
    item.animationProject == null
        ? ''
        : '${item.animationProject!.trackCount} ${item.animationProject!.frameCount} '
              '${item.animationProject!.canvasWidth}x${item.animationProject!.canvasHeight}',
    imageAssetKindLabel(item.kind),
    fileNameFromPath(item.path),
  ].join(' ').toLowerCase();

  return normalizedQuery
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .every(searchableText.contains);
}

bool imageLibraryItemMatchesProject(
  ImageLibraryItem item,
  String selectedProject,
) {
  final normalizedProject = selectedProject.trim().toLowerCase();
  if (normalizedProject.isEmpty) {
    return true;
  }
  return item.project.trim().toLowerCase() == normalizedProject;
}

bool imageLibraryItemMatchesTag(ImageLibraryItem item, String selectedTag) {
  final normalizedTag = selectedTag.trim().toLowerCase();
  if (normalizedTag.isEmpty) {
    return true;
  }
  return item.tags.any((tag) => tag.trim().toLowerCase() == normalizedTag);
}

int compareImageLibraryItems(
  ImageLibraryItem a,
  ImageLibraryItem b,
  ImageLibrarySortOrder sortOrder,
) {
  return switch (sortOrder) {
    ImageLibrarySortOrder.newest => b.createdAt.compareTo(a.createdAt),
    ImageLibrarySortOrder.oldest => a.createdAt.compareTo(b.createdAt),
    ImageLibrarySortOrder.titleAscending =>
      a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()),
  };
}
