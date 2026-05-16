import '../models/app_config.dart';
import '../models/image_advanced_settings.dart';
import '../services/image_api_client.dart';
import 'generation_limits.dart';

OpenAIImageRequest buildImageGenerationRequest({
  required ApiConfig apiConfig,
  required String prompt,
  required String negativePrompt,
  required String requestSize,
  required int imageCount,
  required ImageAdvancedSettings advancedSettings,
  required String user,
  String? templateImagePath,
}) {
  final normalizedImageCount = normalizeImageGenerationRequestCount(imageCount);
  return OpenAIImageRequest(
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey.trim(),
    model: apiConfig.model,
    prompt: prompt,
    negativePrompt: negativePrompt,
    size: requestSize,
    imageCount: normalizedImageCount,
    providerKind: apiConfig.providerKind,
    imageSizeCapabilityOverride: apiConfig.imageSizeCapabilityOverride,
    advancedSettings: advancedSettings.copyWith(user: user.trim()),
    templateImagePath: templateImagePath,
    generationTimeout: apiConfig.generationTimeout,
  );
}

GenerationSnapshot buildGenerationSnapshot({
  required String groupId,
  required ApiConfig apiConfig,
  required String prompt,
  required String negativePrompt,
  required String requestSize,
  required int imageCount,
  required int resultCount,
  required ImageAdvancedSettings advancedSettings,
  required String user,
  DateTime? createdAt,
}) {
  final normalizedImageCount = normalizeImageGenerationRequestCount(imageCount);
  return GenerationSnapshot(
    id: groupId,
    createdAt: createdAt ?? DateTime.now(),
    baseUrl: apiConfig.baseUrl,
    model: apiConfig.model,
    providerKind: apiConfig.providerKind,
    imageSizeCapabilityOverride: apiConfig.imageSizeCapabilityOverride,
    prompt: prompt,
    negativePrompt: negativePrompt,
    size: requestSize,
    imageCount: normalizedImageCount,
    advancedSettings: advancedSettings.copyWith(user: user.trim()),
    resultCount: resultCount,
  );
}
