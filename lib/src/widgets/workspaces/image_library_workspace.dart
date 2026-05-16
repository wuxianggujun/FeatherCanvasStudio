import 'package:flutter/material.dart';

import '../../models/image_library_item.dart';
import '../../models/ui_state.dart';
import '../../utils/image_library_view_data.dart';
import '../image_library_widgets.dart';
import '../layout_navigation_widgets.dart';

class ImageLibraryWorkspace extends StatelessWidget {
  const ImageLibraryWorkspace({
    required this.viewData,
    required this.searchController,
    required this.searchQuery,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
    required this.selectedProject,
    required this.onProjectChanged,
    required this.selectedTag,
    required this.onTagChanged,
    required this.sortOrder,
    required this.onSortOrderChanged,
    required this.selectedItemIds,
    required this.onSelectionChanged,
    required this.onSelectVisible,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.onUseInEditor,
    required this.onReuseGeneration,
    required this.onCopyGeneration,
    required this.onMakeBackgroundTransparent,
    required this.onEditMetadata,
    required this.onCopyPath,
    required this.onOpenLocation,
    required this.onDelete,
    required this.onOpenSliceExplorer,
    required this.showStandaloneFrames,
    required this.onToggleStandaloneFrames,
    super.key,
  });

  final ImageLibraryViewData viewData;
  final TextEditingController searchController;
  final String searchQuery;
  final ImageLibraryKindFilter selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<ImageLibraryKindFilter> onFilterChanged;
  final String selectedProject;
  final ValueChanged<String> onProjectChanged;
  final String selectedTag;
  final ValueChanged<String> onTagChanged;
  final ImageLibrarySortOrder sortOrder;
  final ValueChanged<ImageLibrarySortOrder> onSortOrderChanged;
  final Set<String> selectedItemIds;
  final void Function(ImageLibraryItem item, bool selected) onSelectionChanged;
  final VoidCallback onSelectVisible;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final ValueChanged<ImageLibraryItem> onUseInEditor;
  final ValueChanged<ImageLibraryItem> onReuseGeneration;
  final ValueChanged<ImageLibraryItem> onCopyGeneration;
  final ValueChanged<ImageLibraryItem> onMakeBackgroundTransparent;
  final ValueChanged<ImageLibraryItem> onEditMetadata;
  final ValueChanged<ImageLibraryItem> onCopyPath;
  final ValueChanged<ImageLibraryItem> onOpenLocation;
  final ValueChanged<String> onDelete;
  final ValueChanged<ImageLibraryItem> onOpenSliceExplorer;
  final bool showStandaloneFrames;
  final ValueChanged<bool> onToggleStandaloneFrames;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: '作品',
      description: '集中保存生成、切片、编辑和合成后的图片，其他功能可以直接复用',
      children: [
        ImageLibraryPanel(
          items: viewData.filteredItems,
          totalCount: viewData.visibleItems.length,
          searchController: searchController,
          searchQuery: searchQuery,
          onSearchChanged: onSearchChanged,
          onClearSearch: onClearSearch,
          selectedFilter: selectedFilter,
          onFilterChanged: onFilterChanged,
          availableProjects: viewData.availableProjects,
          selectedProject: selectedProject,
          onProjectChanged: onProjectChanged,
          availableTags: viewData.availableTags,
          selectedTag: selectedTag,
          onTagChanged: onTagChanged,
          sortOrder: sortOrder,
          onSortOrderChanged: onSortOrderChanged,
          selectedItemIds: selectedItemIds,
          onSelectionChanged: onSelectionChanged,
          onSelectVisible: onSelectVisible,
          onClearSelection: onClearSelection,
          onDeleteSelected: onDeleteSelected,
          onUseInEditor: onUseInEditor,
          onReuseGeneration: onReuseGeneration,
          onCopyGeneration: onCopyGeneration,
          onMakeBackgroundTransparent: onMakeBackgroundTransparent,
          onEditMetadata: onEditMetadata,
          onCopyPath: onCopyPath,
          onOpenLocation: onOpenLocation,
          onDelete: onDelete,
          onOpenSliceExplorer: onOpenSliceExplorer,
          savedFrameCountFor: viewData.savedFrameCountFor,
          showStandaloneFrames: showStandaloneFrames,
          groupedFrameCount: viewData.groupedFrameCount,
          onToggleStandaloneFrames: onToggleStandaloneFrames,
        ),
      ],
    );
  }
}
