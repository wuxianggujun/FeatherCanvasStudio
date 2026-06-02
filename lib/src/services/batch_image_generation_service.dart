import '../models/batch_generation_job.dart';
import '../models/exceptions.dart';
import '../models/generated_image.dart';
import '../models/image_asset_kind.dart';
import '../models/image_library_item.dart';
import 'app_local_store.dart';
import 'image_api_client.dart';
import 'image_generation_service.dart';
import 'image_library_service.dart';

class BatchImageGenerationService {
  const BatchImageGenerationService();

  Future<BatchGenerationJob> runJob({
    required BatchGenerationJob job,
    required OpenAICompatibleImageClient client,
    required AppLocalStore store,
    required ImageLibraryService imageLibraryService,
    required ImageGenerationService imageGenerationService,
    required String titlePrefix,
    required String source,
    void Function(ImageRequestDebugRecord record)? onDebugRecord,
  }) async {
    final resultImages = <GeneratedImage>[];
    final libraryItems = <ImageLibraryItem>[];

    while (resultImages.length < job.imageCount) {
      final missingImageCount = job.imageCount - resultImages.length;
      final result = await imageGenerationService.generateTextImages(
        client: client,
        store: store,
        imageLibraryService: imageLibraryService,
        apiConfig: job.apiConfig,
        prompt: job.prompt,
        negativePrompt: job.negativePrompt,
        size: job.size,
        imageCount: missingImageCount,
        advancedSettings: job.advancedSettings,
        user: job.user,
        libraryKind: ImageAssetKind.generatedImage,
        titlePrefix: titlePrefix,
        source: source,
        onDebugRecord: onDebugRecord,
      );

      if (result.cachedImages.isEmpty) {
        throw const ImageGenerationException('接口本次没有返回图片，无法补齐当前批量任务。');
      }

      resultImages.addAll(result.cachedImages.take(missingImageCount));
      libraryItems.addAll(result.libraryItems.take(missingImageCount));
    }

    return job.copyWith(
      status: BatchGenerationJobStatus.succeeded,
      resultImages: List.unmodifiable(resultImages),
      libraryItems: List.unmodifiable(libraryItems),
      clearErrorMessage: true,
    );
  }
}
