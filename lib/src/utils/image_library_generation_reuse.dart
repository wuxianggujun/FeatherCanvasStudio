import '../models/app_config.dart';
import '../models/image_advanced_settings.dart';
import 'image_dimensions.dart';

class ImageLibraryGenerationReuseDraft {
  const ImageLibraryGenerationReuseDraft({
    required this.size,
    required this.imageCount,
    required this.advancedSettings,
    this.matchingConfigId,
  });

  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final String? matchingConfigId;
}

ImageLibraryGenerationReuseDraft buildImageLibraryGenerationReuseDraft({
  required GenerationSnapshot generation,
  required List<ApiConfig> apiConfigs,
}) {
  String? matchingConfigId;
  for (final config in apiConfigs) {
    if (config.baseUrl == generation.baseUrl &&
        config.model == generation.model &&
        config.providerKind == generation.providerKind) {
      matchingConfigId = config.id;
      break;
    }
  }

  return ImageLibraryGenerationReuseDraft(
    matchingConfigId: matchingConfigId,
    size: imageDimensionsFromSize(generation.size).size,
    imageCount: generation.imageCount,
    advancedSettings: generation.advancedSettings,
  );
}
