import 'api_provider.dart';
import 'image_advanced_settings.dart';

class ApiConfig {
  const ApiConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.providerKind = ApiProviderKind.compatible,
  });

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
    );
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String model;
  final ApiProviderKind providerKind;

  ApiConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    ApiProviderKind? providerKind,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      providerKind: providerKind ?? this.providerKind,
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
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'size': size,
      'imageCount': imageCount,
      'resultCount': resultCount,
      ...advancedSettings.toJson(),
    };
  }
}
