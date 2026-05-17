import 'dart:typed_data';

import '../models/image_asset_kind.dart';
import '../models/image_library_item.dart';
import '../services/gif_composer_service.dart';

List<ImageLibraryItem> availableImageLibraryItems(
  List<ImageLibraryItem> library, {
  List<ImageAssetKind>? allowedKinds,
  bool Function(ImageLibraryItem item)? itemExists,
}) {
  final itemExistsPredicate = itemExists ?? (item) => item.existsSync;
  return [
    for (final item in library)
      if (itemExistsPredicate(item) &&
          item.isImageFile &&
          (allowedKinds == null || allowedKinds.contains(item.kind)))
        item,
  ];
}

List<GifSourceFrame> buildGifFramesFromPaths(
  List<String> paths, {
  required int delayMs,
  int seedStart = 0,
}) {
  return [
    for (var index = 0; index < paths.length; index++)
      GifSourceFrame.fromPath(
        paths[index],
        delayMs: delayMs,
        seed: seedStart + index,
      ),
  ];
}

GifSourceFrame buildGifFrameFromLibraryItem(
  ImageLibraryItem item, {
  required int delayMs,
  required int seed,
}) {
  return GifSourceFrame.fromPath(item.path, delayMs: delayMs, seed: seed);
}

List<GifSourceFrame> buildGifFramesFromSlices({
  required ImageLibraryItem sheet,
  required List<MapEntry<int, Uint8List>> slices,
  required int delayMs,
  int seedStart = 0,
}) {
  return [
    for (var index = 0; index < slices.length; index++)
      GifSourceFrame.fromBytes(
        slices[index].value,
        sourcePath: sheet.path,
        delayMs: delayMs,
        seed: seedStart + index,
        label: '${sheet.displayTitle} · 帧 ${slices[index].key + 1}',
      ),
  ];
}
