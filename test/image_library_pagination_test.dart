import 'dart:ui' show Tristate;

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                onOpenAnimationProject: (_) {},
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

    Finder paginationSemantics(String label) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    );

    expect(find.text('第 1 / 2 页 · 1-24 / 30'), findsNWidgets(2));
    expect(
      paginationSemantics('作品库分页控制 · 第 1 / 2 页 · 1-24 / 30 · 每页 24 个'),
      findsNWidgets(2),
    );
    expect(find.text('作品 1'), findsOneWidget);
    expect(find.bySemanticsLabel('生图 · 作品 1'), findsWidgets);
    expect(find.text('作品 25'), findsNothing);

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await tester.tap(find.byTooltip('下一页').first);
    await tester.pump();

    expect(find.text('第 2 / 2 页 · 25-30 / 30'), findsNWidgets(2));
    expect(
      paginationSemantics('作品库分页控制 · 第 2 / 2 页 · 25-30 / 30 · 每页 24 个'),
      findsNWidgets(2),
    );
    expect(find.text('作品 1'), findsNothing);
    expect(find.text('作品 25'), findsOneWidget);
  });

  testWidgets('image library sliver path paginates large result sets', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final items = [
      for (var index = 0; index < 80; index++)
        ImageLibraryItem(
          id: 'sliver-item-$index',
          path: 'missing-sliver-$index.png',
          createdAt: DateTime(2026, 5, 17, 9, index),
          kind: ImageAssetKind.generatedImage,
          title: 'Sliver 作品 ${index + 1}',
          source: '测试',
        ),
    ];
    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 900,
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
              onOpenAnimationProject: (_) {},
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
              fillAvailableHeight: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverGrid), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.text('第 1 / 4 页 · 1-24 / 80'), findsWidgets);
    expect(find.text('Sliver 作品 1'), findsOneWidget);
    expect(find.text('Sliver 作品 25'), findsNothing);

    await tester.tap(find.byTooltip('下一页').first);
    await tester.pump();

    expect(find.text('第 2 / 4 页 · 25-48 / 80'), findsWidgets);
    expect(find.text('Sliver 作品 1'), findsNothing);
    expect(find.text('Sliver 作品 25'), findsOneWidget);
    expect(find.text('Sliver 作品 49'), findsNothing);
  });

  testWidgets('image library select-visible exposes disabled reasons', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    Widget appWith({
      required List<ImageLibraryItem> items,
      required Set<String> selectedIds,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
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
              selectedItemIds: selectedIds,
              onSelectionChanged: (_, _) {},
              onSelectVisible: () {},
              onClearSelection: () {},
              onDeleteSelected: () {},
              onExportSelected: () {},
              onOpenAnimationProject: (_) {},
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
      );
    }

    await tester.pumpWidget(appWith(items: const [], selectedIds: const {}));
    await tester.pump(const Duration(milliseconds: 200));

    final emptySemantics = tester.getSemantics(
      _semanticsWithLabel('选择当前结果').first,
    );
    expect(emptySemantics.value, '当前没有可选择的作品');
    expect(emptySemantics.flagsCollection.isButton, isTrue);
    expect(emptySemantics.flagsCollection.isEnabled, Tristate.isFalse);

    final item = ImageLibraryItem(
      id: 'item-1',
      path: 'missing.png',
      createdAt: DateTime(2026, 5, 17, 8),
      kind: ImageAssetKind.generatedImage,
      title: '已选作品',
      source: '测试',
    );

    await tester.pumpWidget(appWith(items: [item], selectedIds: {'item-1'}));
    await tester.pump(const Duration(milliseconds: 200));

    final allSelectedSemantics = tester.getSemantics(
      _semanticsWithLabel('选择当前结果').first,
    );
    expect(allSelectedSemantics.value, '当前结果已全部选中');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'image library tiles support keyboard selection and primary open',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1400, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final items = [
        ImageLibraryItem(
          id: 'item-1',
          path: 'missing-1.png',
          createdAt: DateTime(2026, 5, 17, 8),
          kind: ImageAssetKind.generatedImage,
          title: '键盘作品',
          source: '测试',
        ),
      ];
      final searchController = TextEditingController();
      final selectedIds = <String>{};
      ImageLibraryItem? openedItem;
      addTearDown(searchController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
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
                    selectedItemIds: selectedIds,
                    onSelectionChanged: (item, selected) {
                      setState(() {
                        if (selected) {
                          selectedIds.add(item.id);
                        } else {
                          selectedIds.remove(item.id);
                        }
                      });
                    },
                    onSelectVisible: () {},
                    onClearSelection: () {},
                    onDeleteSelected: () {},
                    onExportSelected: () {},
                    onOpenAnimationProject: (_) {},
                    onUseInEditor: (item) => openedItem = item,
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
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final tile = find.bySemanticsLabel('生图 · 键盘作品');
      expect(tile, findsWidgets);
      final semantics = tester.getSemantics(tile.first);
      expect(semantics.hint, '按空格切换选择，按回车打开主要操作');

      await tester.tap(tile.first);
      await tester.pump();
      expect(openedItem?.id, 'item-1');

      await tester.tap(find.byKey(const ValueKey('image-library-tile-item-1')));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selectedIds, {'item-1'});
      expect(find.text('已选 1'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selectedIds, isEmpty);
    },
  );
}

Finder _semanticsWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
  );
}
