import '../models/app_config.dart';
import '../models/image_advanced_settings.dart';
import 'generation_limits.dart';
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
        config.providerKind == generation.providerKind &&
        config.imageSizeCapabilityOverride ==
            generation.imageSizeCapabilityOverride) {
      matchingConfigId = config.id;
      break;
    }
  }

  return ImageLibraryGenerationReuseDraft(
    matchingConfigId: matchingConfigId,
    size: safeImageSizeForModel(
      size: generation.size,
      providerKind: generation.providerKind,
      model: generation.model,
      capabilityOverride: generation.imageSizeCapabilityOverride,
    ),
    imageCount: normalizeImageGenerationTargetCount(generation.imageCount),
    advancedSettings: generation.advancedSettings,
  );
}
