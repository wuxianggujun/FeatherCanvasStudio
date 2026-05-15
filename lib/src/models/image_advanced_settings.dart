import 'api_provider.dart';

const List<String> gptImageQualityOptions = <String>[
  'auto',
  'low',
  'medium',
  'high',
];
const List<String> gptImageBackgroundOptions = <String>[
  'auto',
  'transparent',
  'opaque',
];
const List<String> gptImageOutputFormatOptions = <String>[
  'png',
  'jpeg',
  'webp',
];
const List<String> gptImageModerationOptions = <String>['auto', 'low'];

class ImageAdvancedSettings {
  const ImageAdvancedSettings({
    this.quality = 'auto',
    this.background = 'auto',
    this.outputFormat = 'png',
    this.outputCompression = 100,
    this.moderation = 'auto',
    this.user = '',
    this.inputFidelity = 'low',
  });

  factory ImageAdvancedSettings.fromJson(Map<String, dynamic> json) {
    const defaults = ImageAdvancedSettings();
    return ImageAdvancedSettings(
      quality: _readOption(
        json['quality'],
        gptImageQualityOptions,
        defaults.quality,
      ),
      background: _readOption(
        json['background'],
        gptImageBackgroundOptions,
        defaults.background,
      ),
      outputFormat: _readOption(
        json['outputFormat'] ?? json['output_format'],
        gptImageOutputFormatOptions,
        defaults.outputFormat,
      ),
      outputCompression: _readCompression(
        json['outputCompression'] ?? json['output_compression'],
        defaults.outputCompression,
      ),
      moderation: _readOption(
        json['moderation'],
        gptImageModerationOptions,
        defaults.moderation,
      ),
      user: json['user'] as String? ?? defaults.user,
      inputFidelity: _readOption(
        json['inputFidelity'] ?? json['input_fidelity'],
        const ['low', 'high'],
        defaults.inputFidelity,
      ),
    );
  }

  final String quality;
  final String background;
  final String outputFormat;
  final int outputCompression;
  final String moderation;
  final String user;
  final String inputFidelity;

  bool get supportsOutputCompression =>
      outputFormat == 'jpeg' || outputFormat == 'webp';

  ImageAdvancedSettings copyWith({
    String? quality,
    String? background,
    String? outputFormat,
    int? outputCompression,
    String? moderation,
    String? user,
    String? inputFidelity,
  }) {
    return ImageAdvancedSettings(
      quality: quality ?? this.quality,
      background: background ?? this.background,
      outputFormat: outputFormat ?? this.outputFormat,
      outputCompression: outputCompression ?? this.outputCompression,
      moderation: moderation ?? this.moderation,
      user: user ?? this.user,
      inputFidelity: inputFidelity ?? this.inputFidelity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality': quality,
      'background': background,
      'outputFormat': outputFormat,
      'outputCompression': outputCompression,
      'moderation': moderation,
      'user': user,
      'inputFidelity': inputFidelity,
    };
  }

  Map<String, dynamic> toRequestFields({
    required bool hasTemplateImage,
    ApiProviderKind providerKind = ApiProviderKind.official,
  }) {
    if (providerKind != ApiProviderKind.official) {
      // 兼容档和 Gemini 等非 OpenAI 协议不能接收 OpenAI Images 专属字段。
      return const <String, dynamic>{};
    }

    final normalizedBackground =
        background == 'transparent' && outputFormat == 'jpeg'
        ? 'auto'
        : background;
    return {
      if (quality.trim().isNotEmpty) 'quality': quality,
      if (normalizedBackground.trim().isNotEmpty)
        'background': normalizedBackground,
      if (outputFormat.trim().isNotEmpty) 'output_format': outputFormat,
      if (supportsOutputCompression)
        'output_compression': outputCompression.clamp(0, 100),
      if (!hasTemplateImage && moderation.trim().isNotEmpty)
        'moderation': moderation,
      if (user.trim().isNotEmpty) 'user': user.trim(),
      if (hasTemplateImage && inputFidelity.trim().isNotEmpty)
        'input_fidelity': inputFidelity,
    };
  }

  Map<String, String> toMultipartFields({
    required bool hasTemplateImage,
    ApiProviderKind providerKind = ApiProviderKind.official,
  }) {
    return toRequestFields(
      hasTemplateImage: hasTemplateImage,
      providerKind: providerKind,
    ).map((key, value) => MapEntry(key, value.toString()));
  }

  static String _readOption(
    Object? value,
    List<String> allowedValues,
    String fallback,
  ) {
    if (value is! String) {
      return fallback;
    }

    final normalized = value.trim();
    return allowedValues.contains(normalized) ? normalized : fallback;
  }

  static int _readCompression(Object? value, int fallback) {
    final number = value is num ? value.toInt() : int.tryParse('$value');
    return number == null ? fallback : number.clamp(0, 100);
  }
}
