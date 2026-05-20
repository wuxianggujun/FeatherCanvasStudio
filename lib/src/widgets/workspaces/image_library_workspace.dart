import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/image_library_item.dart';
import '../../models/ui_state.dart';
import '../../state/image_library_notifier.dart';
import '../../l10n/app_l10n.dart';
import '../../theme/layout_constants.dart';
import '../../utils/image_library_view_data.dart';
import '../image_library_widgets.dart';

class ImageLibraryWorkspace extends StatefulWidget {
  const ImageLibraryWorkspace({
    required this.itemExists,
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
    required this.onExportSelected,
    required this.onOpenAnimationProject,
    required this.onUseInEditor,
    required this.onReuseGeneration,
    required this.onCopyGeneration,
    required this.onMakeBackgroundTransparent,
    required this.onEditMetadata,
    required this.onCopyImage,
    required this.onExportImage,
    required this.onCopyPath,
    required this.onOpenLocation,
    required this.onDelete,
    required this.onOpenSliceExplorer,
    required this.showStandaloneFrames,
    required this.onToggleStandaloneFrames,
    this.historyControls,
    super.key,
  });

  final bool Function(ImageLibraryItem item) itemExists;
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
  final ValueChanged<List<ImageLibraryItem>> onSelectVisible;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final VoidCallback onExportSelected;
  final ValueChanged<ImageLibraryItem> onOpenAnimationProject;
  final ValueChanged<ImageLibraryItem> onUseInEditor;
  final ValueChanged<ImageLibraryItem> onReuseGeneration;
  final ValueChanged<ImageLibraryItem> onCopyGeneration;
  final ValueChanged<ImageLibraryItem> onMakeBackgroundTransparent;
  final ValueChanged<ImageLibraryItem> onEditMetadata;
  final ValueChanged<ImageLibraryItem> onCopyImage;
  final ValueChanged<ImageLibraryItem> onExportImage;
  final ValueChanged<ImageLibraryItem> onCopyPath;
  final ValueChanged<ImageLibraryItem> onOpenLocation;
  final ValueChanged<String> onDelete;
  final ValueChanged<ImageLibraryItem> onOpenSliceExplorer;
  final bool showStandaloneFrames;
  final ValueChanged<bool> onToggleStandaloneFrames;
  final Widget? historyControls;

  @override
  State<ImageLibraryWorkspace> createState() => _ImageLibraryWorkspaceState();
}

class _ImageLibraryWorkspaceState extends State<ImageLibraryWorkspace> {
  final _viewDataMemoizer = ImageLibraryViewDataMemoizer();

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(workspacePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.imageLibraryWorkspaceTitle,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              if (widget.historyControls != null) ...[
                const SizedBox(width: fieldGap),
                widget.historyControls!,
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.imageLibraryWorkspaceDescription,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: sectionGap),
          Expanded(
            child: Selector<ImageLibraryNotifier, List<ImageLibraryItem>>(
              selector: (_, n) => n.items,
              builder: (context, library, _) {
                final viewData = _viewDataMemoizer.build(
                  library: library,
                  filter: widget.selectedFilter,
                  sortOrder: widget.sortOrder,
                  searchQuery: widget.searchQuery,
                  showStandaloneFrames: widget.showStandaloneFrames,
                  projectFilter: widget.selectedProject,
                  tagFilter: widget.selectedTag,
                  itemExists: widget.itemExists,
                  l10n: l10n,
                );
                return ImageLibraryPanel(
                  fillAvailableHeight: true,
                  items: viewData.filteredItems,
                  totalCount: viewData.visibleItems.length,
                  searchController: widget.searchController,
                  searchQuery: widget.searchQuery,
                  onSearchChanged: widget.onSearchChanged,
                  onClearSearch: widget.onClearSearch,
                  selectedFilter: widget.selectedFilter,
                  onFilterChanged: widget.onFilterChanged,
                  availableProjects: viewData.availableProjects,
                  selectedProject: widget.selectedProject,
                  onProjectChanged: widget.onProjectChanged,
                  availableTags: viewData.availableTags,
                  selectedTag: widget.selectedTag,
                  onTagChanged: widget.onTagChanged,
                  sortOrder: widget.sortOrder,
                  onSortOrderChanged: widget.onSortOrderChanged,
                  selectedItemIds: widget.selectedItemIds,
                  onSelectionChanged: widget.onSelectionChanged,
                  onSelectVisible: () =>
                      widget.onSelectVisible(viewData.filteredItems),
                  onClearSelection: widget.onClearSelection,
                  onDeleteSelected: widget.onDeleteSelected,
                  onExportSelected: widget.onExportSelected,
                  onOpenAnimationProject: widget.onOpenAnimationProject,
                  onUseInEditor: widget.onUseInEditor,
                  onReuseGeneration: widget.onReuseGeneration,
                  onCopyGeneration: widget.onCopyGeneration,
                  onMakeBackgroundTransparent:
                      widget.onMakeBackgroundTransparent,
                  onEditMetadata: widget.onEditMetadata,
                  onCopyImage: widget.onCopyImage,
                  onExportImage: widget.onExportImage,
                  onCopyPath: widget.onCopyPath,
                  onOpenLocation: widget.onOpenLocation,
                  onDelete: widget.onDelete,
                  onOpenSliceExplorer: widget.onOpenSliceExplorer,
                  savedFrameCountFor: viewData.savedFrameCountFor,
                  showStandaloneFrames: widget.showStandaloneFrames,
                  groupedFrameCount: viewData.groupedFrameCount,
                  onToggleStandaloneFrames: widget.onToggleStandaloneFrames,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
