import '../models/batch_generation_job.dart';
import '../models/image_asset_kind.dart';
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
    void Function(ImageRequestDebugRecord record)? onDebugRecord,
  }) async {
    final result = await imageGenerationService.generateTextImages(
      client: client,
      store: store,
      imageLibraryService: imageLibraryService,
      apiConfig: job.apiConfig,
      prompt: job.prompt,
      negativePrompt: job.negativePrompt,
      size: job.size,
      imageCount: job.imageCount,
      advancedSettings: job.advancedSettings,
      user: job.user,
      libraryKind: ImageAssetKind.generatedImage,
      titlePrefix: '批量生图',
      source: '批量生成',
      onDebugRecord: onDebugRecord,
    );

    return job.copyWith(
      status: BatchGenerationJobStatus.succeeded,
      resultImages: result.cachedImages,
      libraryItems: result.libraryItems,
      clearErrorMessage: true,
    );
  }
}
