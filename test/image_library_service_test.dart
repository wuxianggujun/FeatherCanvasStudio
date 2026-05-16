import 'dart:io';
import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('builds image library items only for cached file images', () {
    final createdAt = DateTime.parse('2026-05-15T12:00:00Z');

    final items = buildGeneratedImageItems(
      images: [
        GeneratedImage.file('/tmp/first.png'),
        GeneratedImage.bytes(Uint8List.fromList([1, 2, 3])),
      ],
      kindBuilder: (index, image) => ImageAssetKind.editedImage,
      titleBuilder: (index, image) => 'Custom ${index + 1}',
      titlePrefix: 'Generated',
      source: 'source',
      prompt: 'prompt',
      groupId: 'group',
      createdAt: createdAt,
    );

    expect(items, hasLength(1));
    expect(items.single.path, '/tmp/first.png');
    expect(items.single.kind, ImageAssetKind.editedImage);
    expect(items.single.title, 'Custom 1');
    expect(items.single.source, 'source');
    expect(items.single.prompt, 'prompt');
    expect(items.single.groupId, 'group');
    expect(items.single.createdAt, createdAt);
  });

  test('adds generated image items to the local store', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppLocalStore();
    const service = ImageLibraryService();

    final items = await service.addGeneratedImages(
      store: store,
      images: [
        GeneratedImage.file('/tmp/first.png'),
        GeneratedImage.file('/tmp/second.png'),
      ],
      titlePrefix: 'Generated',
      source: 'source',
      prompt: 'prompt',
      groupId: 'group',
    );

    final restored = await store.loadImageLibrary();

    expect(items, hasLength(2));
    expect(restored.map((item) => item.path).toSet(), {
      '/tmp/first.png',
      '/tmp/second.png',
    });
  });

  test(
    'restores image library items from legacy json without grouping fields',
    () {
      final item = ImageLibraryItem.fromJson({
        'id': 'legacy',
        'path': '/tmp/legacy.png',
        'createdAt': '2026-05-15T12:00:00.000Z',
        'kind': 'generatedImage',
        'title': 'Legacy',
        'source': 'test',
        'note': 'note',
      });

      expect(item.tags, isEmpty);
      expect(item.project, isEmpty);
      expect(item.toJson()['tags'], isEmpty);
      expect(item.toJson()['project'], isEmpty);
    },
  );

  test('adds fixed output items with domain metadata', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppLocalStore();
    const service = ImageLibraryService();

    final gif = await service.addGif(
      store: store,
      path: '/tmp/output.gif',
      frameCount: 3,
    );
    final exportedSheet = await service.addExportedSpriteSheet(
      store: store,
      path: '/tmp/sheet.png',
      rows: 2,
      columns: 4,
    );
    final editedSheet = await service.addEditedSpriteSheet(
      store: store,
      path: '/tmp/edited.png',
      frameIndex: 1,
      rows: 2,
      columns: 4,
    );
    final restored = await store.loadImageLibrary();

    expect(gif.kind, ImageAssetKind.gif);
    expect(gif.prompt, '3 张图片合成');
    expect(exportedSheet.kind, ImageAssetKind.spriteSheet);
    expect(exportedSheet.prompt, '2 x 4');
    expect(editedSheet.kind, ImageAssetKind.editedImage);
    expect(editedSheet.prompt, contains('第 2 帧'));
    expect(restored.map((item) => item.id).toSet(), {
      gif.id,
      exportedSheet.id,
      editedSheet.id,
    });
  });

  test('updates image library item metadata and trims user input', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppLocalStore();
    const service = ImageLibraryService();
    final original = _item(
      id: 'item',
      path: '/tmp/item.png',
      kind: ImageAssetKind.generatedImage,
    );

    final updated = await service.updateItemMetadata(
      store: store,
      library: [original],
      itemId: original.id,
      title: '  New title  ',
      note: '  New note  ',
    );
    final restored = await store.loadImageLibrary();

    expect(updated.single.title, 'New title');
    expect(updated.single.note, 'New note');
    expect(restored.single.title, 'New title');
    expect(restored.single.note, 'New note');
  });

  test('updates image library item project and tags metadata', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppLocalStore();
    const service = ImageLibraryService();
    final original = _item(
      id: 'item',
      path: '/tmp/item.png',
      kind: ImageAssetKind.generatedImage,
    );

    final updated = await service.updateItemMetadata(
      store: store,
      library: [original],
      itemId: original.id,
      title: original.title,
      note: original.note,
      project: '  Project Alpha  ',
      tags: ['  Character ', 'character', '', ' Pixel '],
    );
    final restored = await store.loadImageLibrary();

    expect(updated.single.project, 'Project Alpha');
    expect(updated.single.tags, ['Character', 'Pixel']);
    expect(restored.single.project, 'Project Alpha');
    expect(restored.single.tags, ['Character', 'Pixel']);
  });

  test('deletes image library items from store and disk', () async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = await Directory.systemTemp.createTemp(
      'image_library_delete_items_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final removedFile = File(
      '${tempDir.path}${Platform.pathSeparator}removed.png',
    );
    final keptFile = File('${tempDir.path}${Platform.pathSeparator}kept.png');
    await removedFile.writeAsBytes([1, 2, 3], flush: true);
    await keptFile.writeAsBytes([4, 5, 6], flush: true);

    final removed = _item(
      id: 'removed',
      path: removedFile.path,
      kind: ImageAssetKind.generatedImage,
    );
    final kept = _item(
      id: 'kept',
      path: keptFile.path,
      kind: ImageAssetKind.generatedImage,
    );
    final store = AppLocalStore();
    await store.saveImageLibrary([removed, kept]);

    final impact = await const ImageLibraryService().deleteItems(
      store: store,
      fileService: const ImageLibraryFileService(),
      library: [removed, kept],
      ids: {'removed'},
    );
    final restored = await store.loadImageLibrary();

    expect(impact.removedItems, [removed]);
    expect(impact.remainingItems, [kept]);
    expect(await removedFile.exists(), isFalse);
    expect(await keptFile.exists(), isTrue);
    expect(restored.single.id, 'kept');
  });

  test(
    'caches generated images into files and preserves revised prompt',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'image_library_service_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final store = AppLocalStore(baseDirectoryOverride: tempDir);
      const service = ImageLibraryService();

      final cached = await service.cacheGeneratedImages(
        store: store,
        groupId: 'group',
        images: [GeneratedImage.bytes(Uint8List(0), revisedPrompt: 'revised')],
        resolveImageBytes: (_) async => Uint8List.fromList([1, 2, 3]),
      );

      expect(cached, hasLength(1));
      expect(cached.single.filePath, isNotNull);
      expect(cached.single.revisedPrompt, 'revised');
      expect(await File(cached.single.filePath!).readAsBytes(), [1, 2, 3]);
    },
  );

  test('finds saved sprite frame indexes for a sheet', () {
    final sheet = _item(
      id: 'sheet',
      path: '/tmp/sheet.png',
      kind: ImageAssetKind.spriteSheet,
      groupId: 'group',
    );

    final indexes = savedSpriteFrameIndexesForSheet([
      sheet,
      _item(
        id: 'frame-1',
        path: '/tmp/frame-1.png',
        kind: ImageAssetKind.spriteFrame,
        groupId: 'group',
        frameIndex: 2,
      ),
      _item(
        id: 'frame-2',
        path: '/tmp/frame-2.png',
        kind: ImageAssetKind.spriteFrame,
        groupId: 'other',
        frameIndex: 3,
      ),
    ], sheet);

    expect(indexes, {2});
  });

  test('saves a sprite frame file and adds it to the library', () async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = await Directory.systemTemp.createTemp(
      'image_library_sprite_frame_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final store = AppLocalStore(baseDirectoryOverride: tempDir);
    const service = ImageLibraryService();
    final sheet = _item(
      id: 'sheet',
      path: '/tmp/sheet.png',
      kind: ImageAssetKind.spriteSheet,
      groupId: 'group',
    );

    final frame = await service.saveSpriteFrame(
      store: store,
      sheet: sheet,
      frameIndex: 4,
      bytes: Uint8List.fromList([7, 8, 9]),
    );

    final restored = await store.loadImageLibrary();

    expect(frame.kind, ImageAssetKind.spriteFrame);
    expect(frame.groupId, 'group');
    expect(frame.frameIndex, 4);
    expect(await File(frame.path).readAsBytes(), [7, 8, 9]);
    expect(restored.single.id, frame.id);
  });
}

ImageLibraryItem _item({
  required String id,
  required String path,
  required ImageAssetKind kind,
  String? groupId,
  int? frameIndex,
}) {
  return ImageLibraryItem(
    id: id,
    path: path,
    createdAt: DateTime.parse('2026-05-15T12:00:00Z'),
    kind: kind,
    title: id,
    source: 'test',
    groupId: groupId,
    frameIndex: frameIndex,
  );
}
