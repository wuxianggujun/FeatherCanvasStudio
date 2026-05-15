import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../models/image_advanced_settings.dart';
import '../services/image_api_client.dart';

const String unnamedApiConfigName = '未命名配置';
const String newApiConfigName = '新接口配置';

class ApiConfigDeletionResult {
  const ApiConfigDeletionResult({
    required this.configs,
    required this.selectedConfig,
  });

  final List<ApiConfig> configs;
  final ApiConfig selectedConfig;
}

ApiConfig buildApiConfigDraft({
  required String? selectedId,
  required String nameText,
  required String baseUrlText,
  required String apiKeyText,
  required String modelText,
  required ApiProviderKind providerKind,
}) {
  final name = nameText.trim();
  return ApiConfig(
    id: selectedId ?? ApiConfig.newId(),
    name: name.isEmpty ? unnamedApiConfigName : name,
    baseUrl: baseUrlText.trim(),
    apiKey: apiKeyText,
    model: modelText.trim(),
    providerKind: providerKind,
  );
}

ApiConfig resolveApiConfig(List<ApiConfig> configs, String? selectedId) {
  for (final config in configs) {
    if (config.id == selectedId) {
      return config;
    }
  }

  return configs.isEmpty ? ApiConfig.defaults() : configs.first;
}

List<ApiConfig> upsertApiConfig(List<ApiConfig> configs, ApiConfig nextConfig) {
  return [
    for (final config in configs)
      if (config.id == nextConfig.id) nextConfig else config,
    if (!configs.any((config) => config.id == nextConfig.id)) nextConfig,
  ];
}

ApiConfig createCompatibleApiConfig({String? id}) {
  return ApiConfig(
    id: id ?? ApiConfig.newId(),
    name: newApiConfigName,
    baseUrl: defaultBaseUrlForProviderKind(ApiProviderKind.compatible),
    apiKey: '',
    model: defaultModelForProviderKind(ApiProviderKind.compatible),
    providerKind: ApiProviderKind.compatible,
  );
}

({String baseUrl, String model}) apiProviderKindDefaultedFields({
  required ApiProviderKind previousKind,
  required ApiProviderKind nextKind,
  required String currentBaseUrl,
  required String currentModel,
}) {
  final previousDefaultBaseUrl = defaultBaseUrlForProviderKind(previousKind);
  final previousDefaultModel = defaultModelForProviderKind(previousKind);
  final shouldApplyBaseUrlDefault =
      currentBaseUrl.trim().isEmpty ||
      currentBaseUrl.trim() == previousDefaultBaseUrl;
  final shouldApplyModelDefault =
      currentModel.trim().isEmpty ||
      currentModel.trim() == previousDefaultModel;

  return (
    baseUrl: shouldApplyBaseUrlDefault
        ? defaultBaseUrlForProviderKind(nextKind)
        : currentBaseUrl,
    model: shouldApplyModelDefault
        ? defaultModelForProviderKind(nextKind)
        : currentModel,
  );
}

ApiConfigDeletionResult? deleteApiConfigSelection(
  List<ApiConfig> configs,
  String? selectedId,
) {
  if (configs.length <= 1 || selectedId == null) {
    return null;
  }

  final nextConfigs = [
    for (final config in configs)
      if (config.id != selectedId) config,
  ];
  if (nextConfigs.length == configs.length || nextConfigs.isEmpty) {
    return null;
  }

  return ApiConfigDeletionResult(
    configs: nextConfigs,
    selectedConfig: nextConfigs.first,
  );
}

String apiModelRequestKey(ApiConfig config) {
  return [
    serializeApiProviderKind(config.providerKind),
    config.baseUrl.trim(),
    config.apiKey.trim(),
  ].join('\n');
}

Map<String, List<ApiModelInfo>> cacheApiModelsForRequest({
  required Map<String, List<ApiModelInfo>> cache,
  required String requestKey,
  required List<ApiModelInfo> models,
}) {
  final nextCache = <String, List<ApiModelInfo>>{
    for (final entry in cache.entries)
      entry.key: List<ApiModelInfo>.unmodifiable(entry.value),
  };
  nextCache[requestKey] = List<ApiModelInfo>.unmodifiable(models);
  return Map.unmodifiable(nextCache);
}

Map<String, String> updateApiModelFetchErrorCache({
  required Map<String, String> cache,
  required String requestKey,
  required String? errorMessage,
}) {
  final nextCache = Map<String, String>.of(cache);
  final normalizedMessage = errorMessage?.trim();
  if (normalizedMessage == null || normalizedMessage.isEmpty) {
    nextCache.remove(requestKey);
  } else {
    nextCache[requestKey] = normalizedMessage;
  }
  return Map.unmodifiable(nextCache);
}

OpenAIImageRequest buildApiConfigTestRequest({
  required ApiConfig apiConfig,
  required bool basic,
}) {
  final providerKind = apiConfigTestProviderKind(apiConfig, basic: basic);
  return OpenAIImageRequest(
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey.trim(),
    model: apiConfig.model,
    prompt: 'API connection test. Generate a tiny neutral test image.',
    negativePrompt: '',
    size: '1024x1024',
    imageCount: 1,
    providerKind: providerKind,
    advancedSettings: apiConfigTestAdvancedSettings(basic: basic),
  );
}

ApiProviderKind apiConfigTestProviderKind(
  ApiConfig apiConfig, {
  required bool basic,
}) {
  return basic && apiConfig.providerKind != ApiProviderKind.gemini
      ? ApiProviderKind.compatible
      : apiConfig.providerKind;
}

ImageAdvancedSettings apiConfigTestAdvancedSettings({required bool basic}) {
  return basic
      ? const ImageAdvancedSettings()
      : const ImageAdvancedSettings(
          quality: 'low',
          background: 'auto',
          outputFormat: 'png',
          moderation: 'low',
        );
}

ApiModelInfo? preferredFetchedModel(
  List<ApiModelInfo> models,
  ApiConfig config,
) {
  if (models.isEmpty) {
    return null;
  }

  final currentModel = normalizeModelIdForSelection(config.model);
  final defaultModel = normalizeModelIdForSelection(
    defaultModelForProviderKind(config.providerKind),
  );
  final containsCurrent = models.any(
    (model) => normalizeModelIdForSelection(model.id) == currentModel,
  );
  if (containsCurrent) {
    return null;
  }

  if (currentModel.isNotEmpty && currentModel != defaultModel) {
    return null;
  }

  return bestImageModelCandidate(models) ?? models.first;
}

ApiModelInfo? bestImageModelCandidate(List<ApiModelInfo> models) {
  const preferredKeywords = [
    'gpt-image',
    'gemini-2.5-flash-image',
    'imagen',
    'image',
    'dall-e',
  ];

  for (final keyword in preferredKeywords) {
    for (final model in models) {
      if (model.id.toLowerCase().contains(keyword)) {
        return model;
      }
    }
  }

  return null;
}

String normalizeModelIdForSelection(String value) {
  return value.trim().replaceFirst(RegExp(r'^models/'), '');
}

String decorateApiTestErrorMessage({
  required String baseMessage,
  required ApiProviderKind providerKind,
  required bool basic,
}) {
  final prefix = basic ? '基础测试失败' : '接口测试失败';
  if (!basic &&
      providerKind == ApiProviderKind.official &&
      looksLikeUpstreamError(baseMessage)) {
    return '$prefix：$baseMessage\n'
        '提示：当前为「OpenAI 官方」档位，反代/兼容层可能不支持 input_fidelity、'
        'output_compression、moderation 等参数，可切换到「OpenAI 兼容」档位再试';
  }
  return '$prefix：$baseMessage';
}

bool looksLikeUpstreamError(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('502') ||
      normalized.contains('503') ||
      normalized.contains('504') ||
      normalized.contains('bad gateway') ||
      normalized.contains('gateway timeout');
}
