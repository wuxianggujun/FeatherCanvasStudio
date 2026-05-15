import 'dart:io';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds image library view data with grouped frame counts', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'image_library_view_data_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<String> touch(String name) async {
      final file = File('${tempDir.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes([1], flush: true);
      return file.path;
    }

    final sheet = _item(
      id: 'sheet',
      path: await touch('sheet.png'),
      kind: ImageAssetKind.spriteSheet,
      groupId: 'group',
      createdAt: DateTime.parse('2026-05-15T12:00:00Z'),
    );
    final groupedFrame = _item(
      id: 'frame',
      path: await touch('frame.png'),
      kind: ImageAssetKind.spriteFrame,
      groupId: 'group',
      createdAt: DateTime.parse('2026-05-15T12:01:00Z'),
    );
    final standaloneFrame = _item(
      id: 'standalone',
      path: await touch('standalone.png'),
      kind: ImageAssetKind.spriteFrame,
      groupId: 'other',
      createdAt: DateTime.parse('2026-05-15T12:02:00Z'),
    );
    final missing = _item(
      id: 'missing',
      path: '${tempDir.path}${Platform.pathSeparator}missing.png',
      kind: ImageAssetKind.generatedImage,
      createdAt: DateTime.parse('2026-05-15T12:03:00Z'),
    );

    final hiddenGroupedFrames = buildImageLibraryViewData(
      library: [sheet, groupedFrame, standaloneFrame, missing],
      filter: ImageLibraryKindFilter.all,
      sortOrder: ImageLibrarySortOrder.newest,
      searchQuery: '',
      showStandaloneFrames: false,
    );
    final shownGroupedFrames = buildImageLibraryViewData(
      library: [sheet, groupedFrame, standaloneFrame],
      filter: ImageLibraryKindFilter.sprite,
      sortOrder: ImageLibrarySortOrder.oldest,
      searchQuery: 'sheet',
      showStandaloneFrames: true,
    );

    expect(hiddenGroupedFrames.availableItems, [
      sheet,
      groupedFrame,
      standaloneFrame,
    ]);
    expect(hiddenGroupedFrames.visibleItems, [sheet, standaloneFrame]);
    expect(hiddenGroupedFrames.filteredItems, [standaloneFrame, sheet]);
    expect(hiddenGroupedFrames.groupedFrameCount, 1);
    expect(hiddenGroupedFrames.savedFrameCountFor(sheet), 1);
    expect(shownGroupedFrames.filteredItems, [sheet]);
  });
}

ImageLibraryItem _item({
  required String id,
  required String path,
  required ImageAssetKind kind,
  required DateTime createdAt,
  String? groupId,
}) {
  return ImageLibraryItem(
    id: id,
    path: path,
    createdAt: createdAt,
    kind: kind,
    title: id,
    source: 'test',
    groupId: groupId,
  );
}
