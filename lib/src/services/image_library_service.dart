import 'dart:typed_data';

import '../models/app_config.dart';
import '../models/generated_image.dart';
import '../models/image_asset_kind.dart';
import '../models/image_library_item.dart';
import '../utils/image_library_deletion.dart';
import 'app_local_store.dart';
import 'image_library_file_service.dart';

typedef ImageLibraryItemKindBuilder =
    ImageAssetKind Function(int index, GeneratedImage image);
typedef ImageLibraryItemTitleBuilder =
    String Function(int index, GeneratedImage image);

class ImageLibraryService {
  const ImageLibraryService();

  Future<GeneratedImage> cacheGeneratedImage({
    required AppLocalStore store,
    required String groupId,
    required int index,
    required GeneratedImage image,
    required Future<Uint8List> Function(GeneratedImage image) resolveImageBytes,
  }) async {
    try {
      final bytes = await resolveImageBytes(image);
      final file = await store.saveGeneratedImageBytes(
        groupId: groupId,
        index: index,
        bytes: bytes,
      );
      return GeneratedImage.file(file.path, revisedPrompt: image.revisedPrompt);
    } catch (_) {
      return image;
    }
  }

  Future<List<GeneratedImage>> cacheGeneratedImages({
    required AppLocalStore store,
    required String groupId,
    required List<GeneratedImage> images,
    required Future<Uint8List> Function(GeneratedImage image) resolveImageBytes,
  }) async {
    final cachedImages = <GeneratedImage>[];
    for (var index = 0; index < images.length; index++) {
      cachedImages.add(
        await cacheGeneratedImage(
          store: store,
          groupId: groupId,
          index: index,
          image: images[index],
          resolveImageBytes: resolveImageBytes,
        ),
      );
    }
    return cachedImages;
  }

  Future<List<ImageLibraryItem>> addGeneratedImages({
    required AppLocalStore store,
    required List<GeneratedImage> images,
    ImageAssetKind kind = ImageAssetKind.generatedImage,
    ImageLibraryItemKindBuilder? kindBuilder,
    ImageLibraryItemTitleBuilder? titleBuilder,
    required String titlePrefix,
    required String source,
    required String prompt,
    GenerationSnapshot? generation,
    String? groupId,
  }) async {
    final items = buildGeneratedImageItems(
      images: images,
      kind: kind,
      kindBuilder: kindBuilder,
      titleBuilder: titleBuilder,
      titlePrefix: titlePrefix,
      source: source,
      prompt: prompt,
      generation: generation,
      groupId: groupId,
    );
    await store.addImageLibraryItems(items);
    return items;
  }

  Future<ImageLibraryItem> addItem({
    required AppLocalStore store,
    required String path,
    required ImageAssetKind kind,
    required String title,
    required String source,
    String? prompt,
    GenerationSnapshot? generation,
    String? groupId,
    int? rows,
    int? columns,
    int? frameWidth,
    int? frameHeight,
    int? frameIndex,
  }) async {
    final item = ImageLibraryItem(
      id: ImageLibraryItem.newId(),
      path: path,
      createdAt: DateTime.now(),
      kind: kind,
      title: title,
      source: source,
      prompt: prompt,
      generation: generation,
      groupId: groupId,
      rows: rows,
      columns: columns,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      frameIndex: frameIndex,
    );
    await store.addImageLibraryItems([item]);
    return item;
  }

  Future<ImageLibraryItem> addGif({
    required AppLocalStore store,
    required String path,
    required int frameCount,
  }) {
    return addItem(
      store: store,
      path: path,
      kind: ImageAssetKind.gif,
      title: 'GIF 合成',
      source: 'GIF 合成',
      prompt: '$frameCount 张图片合成',
    );
  }

  Future<ImageLibraryItem> addExportedSpriteSheet({
    required AppLocalStore store,
    required String path,
    required int rows,
    required int columns,
  }) {
    return addItem(
      store: store,
      path: path,
      kind: ImageAssetKind.spriteSheet,
      title: '导出 Sprite Sheet',
      source: 'Sprite Sheet 导出',
      prompt: '$rows x $columns',
    );
  }

  Future<ImageLibraryItem> addEditedSpriteSheet({
    required AppLocalStore store,
    required String path,
    required int frameIndex,
    required int rows,
    required int columns,
  }) {
    return addItem(
      store: store,
      path: path,
      kind: ImageAssetKind.editedImage,
      title: '编辑后的 Sprite Sheet',
      source: '图片编辑',
      prompt: '替换第 ${frameIndex + 1} 帧 · $rows x $columns',
    );
  }

  Future<List<ImageLibraryItem>> updateItemMetadata({
    required AppLocalStore store,
    required List<ImageLibraryItem> library,
    required String itemId,
    required String title,
    required String note,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedNote = note.trim();
    final nextLibrary = [
      for (final current in library)
        if (current.id == itemId)
          current.copyWith(title: normalizedTitle, note: normalizedNote)
        else
          current,
    ];

    await store.saveImageLibrary(nextLibrary);
    return nextLibrary;
  }

  Future<ImageLibraryDeleteImpact> deleteItems({
    required AppLocalStore store,
    required ImageLibraryFileService fileService,
    required List<ImageLibraryItem> library,
    required Set<String> ids,
  }) async {
    final impact = buildImageLibraryDeleteImpact(library, ids);
    await store.saveImageLibrary(impact.remainingItems);
    await fileService.deleteExistingFiles(impact.removedPaths);
    return impact;
  }

  Future<ImageLibraryItem> saveSpriteFrame({
    required AppLocalStore store,
    required ImageLibraryItem sheet,
    required int frameIndex,
    required Uint8List bytes,
  }) async {
    final groupId = sheet.groupId;
    if (groupId == null) {
      throw StateError('Sprite Sheet is missing groupId.');
    }

    final file = await store.saveGeneratedImageBytes(
      groupId: groupId,
      index: 100 + frameIndex,
      bytes: bytes,
    );

    return addItem(
      store: store,
      path: file.path,
      kind: ImageAssetKind.spriteFrame,
      title: '${sheet.displayTitle} · 帧 ${frameIndex + 1}',
      source: sheet.source.isEmpty ? '帧动画' : sheet.source,
      prompt: sheet.prompt,
      generation: sheet.generation,
      groupId: groupId,
      frameWidth: sheet.frameWidth,
      frameHeight: sheet.frameHeight,
      frameIndex: frameIndex,
    );
  }
}

Set<int> savedSpriteFrameIndexesForSheet(
  List<ImageLibraryItem> library,
  ImageLibraryItem sheet,
) {
  if (sheet.groupId == null) {
    return const <int>{};
  }

  return <int>{
    for (final item in library)
      if (item.kind == ImageAssetKind.spriteFrame &&
          item.groupId == sheet.groupId &&
          item.frameIndex != null)
        item.frameIndex!,
  };
}

List<ImageLibraryItem> buildGeneratedImageItems({
  required List<GeneratedImage> images,
  ImageAssetKind kind = ImageAssetKind.generatedImage,
  ImageLibraryItemKindBuilder? kindBuilder,
  ImageLibraryItemTitleBuilder? titleBuilder,
  required String titlePrefix,
  required String source,
  required String prompt,
  GenerationSnapshot? generation,
  String? groupId,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime.now();
  final items = <ImageLibraryItem>[];
  for (var index = 0; index < images.length; index++) {
    final image = images[index];
    final filePath = image.filePath;
    if (filePath == null) {
      continue;
    }
    final title =
        titleBuilder?.call(index, image) ?? '$titlePrefix ${index + 1}';
    items.add(
      ImageLibraryItem(
        id: ImageLibraryItem.newId(seed: index),
        path: filePath,
        createdAt: now.add(Duration(microseconds: index)),
        kind: kindBuilder?.call(index, image) ?? kind,
        title: title,
        source: source,
        prompt: prompt,
        generation: generation,
        groupId: groupId,
      ),
    );
  }
  return items;
}
