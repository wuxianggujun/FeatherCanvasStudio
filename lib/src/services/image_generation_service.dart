import '../models/app_config.dart';
import '../models/exceptions.dart';
import '../models/generated_image.dart';
import '../models/image_advanced_settings.dart';
import '../models/image_asset_kind.dart';
import '../models/image_library_item.dart';
import '../utils/image_dimensions.dart';
import '../utils/image_generation_builders.dart';
import '../utils/sprite_sheet_text.dart';
import 'app_local_store.dart';
import 'image_api_client.dart';
import 'image_library_service.dart';
import 'sprite_sheet_service.dart';

class TextImageGenerationResult {
  const TextImageGenerationResult({
    required this.groupId,
    required this.cachedImages,
    required this.generation,
    required this.libraryItems,
  });

  final String groupId;
  final List<GeneratedImage> cachedImages;
  final GenerationSnapshot generation;
  final List<ImageLibraryItem> libraryItems;
}

class SpriteSheetGenerationResult {
  const SpriteSheetGenerationResult({
    required this.groupId,
    required this.cachedSheet,
    required this.saveResult,
    required this.generation,
    this.libraryItem,
  });

  final String groupId;
  final GeneratedImage cachedSheet;
  final SpriteSheetSaveResult saveResult;
  final GenerationSnapshot generation;
  final ImageLibraryItem? libraryItem;
}

class ImageGenerationService {
  const ImageGenerationService();

  Future<TextImageGenerationResult> generateTextImages({
    required OpenAICompatibleImageClient client,
    required AppLocalStore store,
    required ImageLibraryService imageLibraryService,
    required ApiConfig apiConfig,
    required String prompt,
    required String negativePrompt,
    required String size,
    required int imageCount,
    required ImageAdvancedSettings advancedSettings,
    required String user,
    ImageAssetKind libraryKind = ImageAssetKind.generatedImage,
    String titlePrefix = '文本生图',
    String source = '文本生图',
    void Function(ImageRequestDebugRecord record)? onDebugRecord,
  }) async {
    final groupId = DateTime.now().microsecondsSinceEpoch.toString();
    final requestSize = requestSizeForProvider(size, apiConfig.providerKind);
    final request = buildImageGenerationRequest(
      apiConfig: apiConfig,
      prompt: prompt,
      negativePrompt: negativePrompt,
      requestSize: requestSize,
      imageCount: imageCount,
      advancedSettings: advancedSettings,
      user: user,
    );
    final response = await client.generate(
      request,
      onDebugRecord: onDebugRecord,
    );
    final cachedImages = await imageLibraryService.cacheGeneratedImages(
      store: store,
      groupId: groupId,
      images: response.images,
      resolveImageBytes: client.resolveImageBytes,
    );
    final generation = buildGenerationSnapshot(
      groupId: groupId,
      apiConfig: apiConfig,
      prompt: prompt,
      negativePrompt: negativePrompt,
      requestSize: requestSize,
      imageCount: imageCount,
      resultCount: cachedImages.length,
      advancedSettings: advancedSettings,
      user: user,
    );
    final libraryItems = await imageLibraryService.addGeneratedImages(
      store: store,
      images: cachedImages,
      kind: libraryKind,
      titlePrefix: titlePrefix,
      source: source,
      prompt: prompt,
      generation: generation,
      groupId: groupId,
    );

    return TextImageGenerationResult(
      groupId: groupId,
      cachedImages: cachedImages,
      generation: generation,
      libraryItems: libraryItems,
    );
  }

  Future<SpriteSheetGenerationResult> generateSpriteSheet({
    required OpenAICompatibleImageClient client,
    required AppLocalStore store,
    required ImageLibraryService imageLibraryService,
    required ApiConfig apiConfig,
    required String prompt,
    required String negativePrompt,
    required String size,
    required int rows,
    required int columns,
    required ImageAdvancedSettings advancedSettings,
    required String user,
    String? templateImagePath,
    String title = 'Sprite Sheet',
    String source = '帧动',
    void Function(ImageRequestDebugRecord record)? onDebugRecord,
  }) async {
    final groupId = 'animation_${DateTime.now().microsecondsSinceEpoch}';
    final requestSize = requestSizeForProvider(size, apiConfig.providerKind);
    final request = buildImageGenerationRequest(
      apiConfig: apiConfig,
      prompt: buildSpriteSheetPromptText(
        prompt: prompt,
        rows: rows,
        columns: columns,
        hasTemplate: templateImagePath != null,
      ),
      negativePrompt: negativePrompt,
      requestSize: requestSize,
      imageCount: 1,
      advancedSettings: advancedSettings,
      user: user,
      templateImagePath: templateImagePath,
    );
    final response = await client.generate(
      request,
      onDebugRecord: onDebugRecord,
    );

    if (response.images.isEmpty) {
      throw const ImageGenerationException('接口没有返回 Sprite Sheet 图片');
    }

    final saveResult = await SpriteSheetOutputCache.saveSheetOnly(
      store: store,
      groupId: groupId,
      sourceImage: response.images.first,
      rows: rows,
      columns: columns,
      resolveImageBytes: client.resolveImageBytes,
    );
    final generation = buildGenerationSnapshot(
      groupId: groupId,
      apiConfig: apiConfig,
      prompt: prompt,
      negativePrompt: negativePrompt,
      requestSize: requestSize,
      imageCount: 1,
      resultCount: 1,
      advancedSettings: advancedSettings,
      user: user,
    );
    final sheetPath = saveResult.sheet.filePath;
    final libraryItem = sheetPath == null
        ? null
        : await imageLibraryService.addItem(
            store: store,
            path: sheetPath,
            kind: ImageAssetKind.spriteSheet,
            title: title,
            source: source,
            prompt: prompt,
            generation: generation,
            groupId: groupId,
            rows: saveResult.rows,
            columns: saveResult.columns,
            frameWidth: saveResult.frameWidth,
            frameHeight: saveResult.frameHeight,
          );

    return SpriteSheetGenerationResult(
      groupId: groupId,
      cachedSheet: saveResult.sheet,
      saveResult: saveResult,
      generation: generation,
      libraryItem: libraryItem,
    );
  }
}
