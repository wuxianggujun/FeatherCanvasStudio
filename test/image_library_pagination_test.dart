import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('image library paginates large result sets', (tester) async {
    final items = [
      for (var index = 0; index < 30; index++)
        ImageLibraryItem(
          id: 'item-$index',
          path: 'missing-$index.png',
          createdAt: DateTime(2026, 5, 17, 8, index),
          kind: ImageAssetKind.generatedImage,
          title: '作品 ${index + 1}',
          source: '测试',
        ),
    ];
    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1200,
              child: ImageLibraryPanel(
                items: items,
                totalCount: items.length,
                searchController: searchController,
                searchQuery: '',
                onSearchChanged: (_) {},
                onClearSearch: () {},
                selectedFilter: ImageLibraryKindFilter.all,
                onFilterChanged: (_) {},
                availableProjects: const [],
                selectedProject: '',
                onProjectChanged: (_) {},
                availableTags: const [],
                selectedTag: '',
                onTagChanged: (_) {},
                sortOrder: ImageLibrarySortOrder.newest,
                onSortOrderChanged: (_) {},
                selectedItemIds: const <String>{},
                onSelectionChanged: (_, _) {},
                onSelectVisible: () {},
                onClearSelection: () {},
                onDeleteSelected: () {},
                onExportSelected: () {},
                onUseInEditor: (_) {},
                onReuseGeneration: (_) {},
                onCopyGeneration: (_) {},
                onMakeBackgroundTransparent: (_) {},
                onEditMetadata: (_) {},
                onCopyImage: (_) {},
                onExportImage: (_) {},
                onCopyPath: (_) {},
                onOpenLocation: (_) {},
                onDelete: (_) {},
                onOpenSliceExplorer: (_) {},
                savedFrameCountFor: (_) => 0,
                showStandaloneFrames: false,
                groupedFrameCount: 0,
                onToggleStandaloneFrames: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('第 1 / 2 页 · 1-24 / 30'), findsNWidgets(2));
    expect(find.text('作品 1'), findsOneWidget);
    expect(find.text('作品 25'), findsNothing);

    await tester.tap(find.byTooltip('下一页').first);
    await tester.pump();

    expect(find.text('第 2 / 2 页 · 25-30 / 30'), findsNWidgets(2));
    expect(find.text('作品 1'), findsNothing);
    expect(find.text('作品 25'), findsOneWidget);
  });
}
