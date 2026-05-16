import 'api_provider.dart';
import 'image_advanced_settings.dart';

enum ImageSizeCapabilityOverride {
  auto,
  fixedPresets,
  customPixels,
  aspectRatio,
}

String serializeImageSizeCapabilityOverride(
  ImageSizeCapabilityOverride override,
) {
  return switch (override) {
    ImageSizeCapabilityOverride.auto => 'auto',
    ImageSizeCapabilityOverride.fixedPresets => 'fixedPresets',
    ImageSizeCapabilityOverride.customPixels => 'customPixels',
    ImageSizeCapabilityOverride.aspectRatio => 'aspectRatio',
  };
}

ImageSizeCapabilityOverride parseImageSizeCapabilityOverride(
  Object? value, {
  ImageSizeCapabilityOverride fallback = ImageSizeCapabilityOverride.auto,
}) {
  if (value is String) {
    switch (value.trim()) {
      case 'auto':
        return ImageSizeCapabilityOverride.auto;
      case 'fixedPresets':
        return ImageSizeCapabilityOverride.fixedPresets;
      case 'customPixels':
        return ImageSizeCapabilityOverride.customPixels;
      case 'aspectRatio':
        return ImageSizeCapabilityOverride.aspectRatio;
    }
  }
  return fallback;
}

class ApiConfig {
  const ApiConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.providerKind = ApiProviderKind.compatible,
    this.imageSizeCapabilityOverride = ImageSizeCapabilityOverride.auto,
    this.generationTimeoutSeconds = defaultGenerationTimeoutSeconds,
  });

  static const int defaultGenerationTimeoutSeconds = 480;
  static const int minGenerationTimeoutSeconds = 60;
  static const int maxGenerationTimeoutSeconds = 1800;

  factory ApiConfig.defaults() {
    return const ApiConfig(
      id: 'default',
      name: '默认配置',
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      model: '',
      providerKind: ApiProviderKind.official,
    );
  }

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    final defaults = ApiConfig.defaults();
    final baseUrl = json['baseUrl'] as String? ?? defaults.baseUrl;
    return ApiConfig(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? defaults.name,
      baseUrl: baseUrl,
      apiKey: json['apiKey'] as String? ?? defaults.apiKey,
      model: json['model'] as String? ?? defaults.model,
      providerKind: parseApiProviderKind(
        json['providerKind'],
        fallback: defaults.providerKind,
      ),
      imageSizeCapabilityOverride: parseImageSizeCapabilityOverride(
        json['imageSizeCapabilityOverride'],
      ),
      generationTimeoutSeconds: clampGenerationTimeoutSeconds(
        (json['generationTimeoutSeconds'] as num?)?.toInt(),
      ),
    );
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  static int clampGenerationTimeoutSeconds(int? value) {
    if (value == null || value <= 0) {
      return defaultGenerationTimeoutSeconds;
    }
    if (value < minGenerationTimeoutSeconds) {
      return minGenerationTimeoutSeconds;
    }
    if (value > maxGenerationTimeoutSeconds) {
      return maxGenerationTimeoutSeconds;
    }
    return value;
  }

  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String model;
  final ApiProviderKind providerKind;
  final ImageSizeCapabilityOverride imageSizeCapabilityOverride;
  final int generationTimeoutSeconds;

  Duration get generationTimeout => Duration(seconds: generationTimeoutSeconds);

  ApiConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    ApiProviderKind? providerKind,
    ImageSizeCapabilityOverride? imageSizeCapabilityOverride,
    int? generationTimeoutSeconds,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      providerKind: providerKind ?? this.providerKind,
      imageSizeCapabilityOverride:
          imageSizeCapabilityOverride ?? this.imageSizeCapabilityOverride,
      generationTimeoutSeconds:
          generationTimeoutSeconds ?? this.generationTimeoutSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'providerKind': serializeApiProviderKind(providerKind),
      'imageSizeCapabilityOverride': serializeImageSizeCapabilityOverride(
        imageSizeCapabilityOverride,
      ),
      'generationTimeoutSeconds': generationTimeoutSeconds,
    };
  }
}

class AppSettings {
  const AppSettings({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
    this.advancedSettings = const ImageAdvancedSettings(),
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      model: '',
      prompt:
          'A clean product render of a futuristic camera on a neutral background',
      negativePrompt: '',
      size: '1024x1024',
      imageCount: 1,
      advancedSettings: ImageAdvancedSettings(),
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      baseUrl: json['baseUrl'] as String? ?? defaults.baseUrl,
      apiKey: json['apiKey'] as String? ?? defaults.apiKey,
      model: json['model'] as String? ?? defaults.model,
      prompt: json['prompt'] as String? ?? defaults.prompt,
      negativePrompt:
          json['negativePrompt'] as String? ?? defaults.negativePrompt,
      size: json['size'] as String? ?? defaults.size,
      imageCount: (json['imageCount'] as num?)?.toInt() ?? defaults.imageCount,
      advancedSettings: ImageAdvancedSettings.fromJson(json),
    );
  }

  final String baseUrl;
  final String apiKey;
  final String model;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'size': size,
      'imageCount': imageCount,
      ...advancedSettings.toJson(),
    };
  }
}

class GenerationSnapshot {
  const GenerationSnapshot({
    required this.id,
    required this.createdAt,
    required this.baseUrl,
    required this.model,
    required this.providerKind,
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
    required this.resultCount,
    this.imageSizeCapabilityOverride = ImageSizeCapabilityOverride.auto,
    this.advancedSettings = const ImageAdvancedSettings(),
  });

  factory GenerationSnapshot.fromJson(Map<String, dynamic> json) {
    return GenerationSnapshot(
      id: json['id'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      baseUrl: json['baseUrl'] as String? ?? '',
      model: json['model'] as String? ?? '',
      providerKind: parseApiProviderKind(
        json['providerKind'],
        fallback: ApiProviderKind.official,
      ),
      imageSizeCapabilityOverride: parseImageSizeCapabilityOverride(
        json['imageSizeCapabilityOverride'],
      ),
      prompt: json['prompt'] as String? ?? '',
      negativePrompt: json['negativePrompt'] as String? ?? '',
      size: json['size'] as String? ?? '',
      imageCount: (json['imageCount'] as num?)?.toInt() ?? 1,
      resultCount: (json['resultCount'] as num?)?.toInt() ?? 0,
      advancedSettings: ImageAdvancedSettings.fromJson(json),
    );
  }

  final String id;
  final DateTime createdAt;
  final String baseUrl;
  final String model;
  final ApiProviderKind providerKind;
  final ImageSizeCapabilityOverride imageSizeCapabilityOverride;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final int resultCount;
  final ImageAdvancedSettings advancedSettings;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'baseUrl': baseUrl,
      'model': model,
      'providerKind': serializeApiProviderKind(providerKind),
      'imageSizeCapabilityOverride': serializeImageSizeCapabilityOverride(
        imageSizeCapabilityOverride,
      ),
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'size': size,
      'imageCount': imageCount,
      'resultCount': resultCount,
      ...advancedSettings.toJson(),
    };
  }
}
