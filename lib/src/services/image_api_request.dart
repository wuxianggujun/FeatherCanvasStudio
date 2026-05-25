import 'dart:convert';
import 'dart:io';

import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../models/exceptions.dart';
import '../models/generated_image.dart';
import '../models/image_advanced_settings.dart';
import '../utils/generation_limits.dart';
import '../utils/image_dimensions.dart';

class OpenAIImageRequest {
  const OpenAIImageRequest({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
    this.advancedSettings = const ImageAdvancedSettings(),
    this.templateImagePath,
    this.providerKind = ApiProviderKind.official,
    this.imageSizeCapabilityOverride = ImageSizeCapabilityOverride.auto,
    this.generationTimeout,
  });

  final String baseUrl;
  final String apiKey;
  final String model;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final String? templateImagePath;
  final ApiProviderKind providerKind;
  final ImageSizeCapabilityOverride imageSizeCapabilityOverride;
  final Duration? generationTimeout;

  bool get hasTemplateImage =>
      templateImagePath != null && templateImagePath!.trim().isNotEmpty;

  int get normalizedImageCount =>
      normalizeImageGenerationRequestCount(imageCount);

  void validateForGeneration() {
    validateApiKeyForRequestHeader(apiKey);
    if (model.trim().isEmpty) {
      throw const ImageGenerationException('请先在接口配置页获取模型列表并选择模型，或手动填写模型名称。');
    }
    requestSizeForModel(
      size: size,
      providerKind: providerKind,
      model: model,
      capabilityOverride: imageSizeCapabilityOverride,
    );
  }

  Uri get endpoint {
    if (providerKind == ApiProviderKind.gemini) {
      return geminiEndpoint;
    }

    final normalizedBaseUrl = normalizeOpenAiBaseUrl(baseUrl);
    final imageEndpoint = hasTemplateImage
        ? '/images/edits'
        : '/images/generations';
    final normalizedRoot = normalizedBaseUrl.replaceFirst(
      RegExp(r'/images/(generations|edits)$'),
      '',
    );

    if (normalizedRoot != normalizedBaseUrl) {
      return Uri.parse('$normalizedRoot$imageEndpoint');
    }

    return Uri.parse('$normalizedBaseUrl$imageEndpoint');
  }

  Uri get geminiEndpoint {
    final normalizedBaseUrl = normalizeGeminiBaseUrl(baseUrl);
    final normalizedRoot = normalizedBaseUrl.replaceFirst(
      RegExp(r'/models/[^/]+:generateContent$'),
      '',
    );

    return Uri.parse(
      '$normalizedRoot/models/${Uri.encodeComponent(_effectiveGeminiModel)}:generateContent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': _effectiveModel,
      'prompt': _mergedPrompt,
      'size': _effectiveRequestSize,
      'n': normalizedImageCount,
      ...advancedSettings.toRequestFields(
        hasTemplateImage: hasTemplateImage,
        providerKind: providerKind,
      ),
    };
  }

  Map<String, dynamic> toDebugJson() {
    if (providerKind == ApiProviderKind.gemini) {
      return {
        'endpoint': endpoint.toString(),
        'method': 'POST JSON (Gemini generateContent)',
        'providerKind': serializeApiProviderKind(providerKind),
        'imageSizeCapability': _debugImageSizeCapability,
        'imageSizeCapabilityOverride': imageSizeCapabilityOverrideLabel(
          imageSizeCapabilityOverride,
        ),
        'apiKey': apiKey.trim().isEmpty ? '未填写' : '已填写（已隐藏）',
        if (hasTemplateImage) 'templateImagePath': templateImagePath,
        'jsonBody': toGeminiDebugJson(),
      };
    }

    return {
      'endpoint': endpoint.toString(),
      'method': hasTemplateImage ? 'POST multipart/form-data' : 'POST JSON',
      'providerKind': serializeApiProviderKind(providerKind),
      'imageSizeCapability': _debugImageSizeCapability,
      'imageSizeCapabilityOverride': imageSizeCapabilityOverrideLabel(
        imageSizeCapabilityOverride,
      ),
      'apiKey': apiKey.trim().isEmpty ? '未填写' : '已填写（已隐藏）',
      if (hasTemplateImage) 'templateImagePath': templateImagePath,
      if (hasTemplateImage)
        'multipartFields': _debugMultipartFields()
      else
        'jsonBody': _debugJsonBody(),
    };
  }

  Map<String, String> toMultipartFields() {
    return {
      'model': _effectiveModel,
      'prompt': _mergedPrompt,
      'size': _effectiveRequestSize,
      'n': normalizedImageCount.toString(),
      ...advancedSettings.toMultipartFields(
        hasTemplateImage: hasTemplateImage,
        providerKind: providerKind,
      ),
    };
  }

  Future<Map<String, dynamic>> toGeminiJson() async {
    final parts = <Map<String, dynamic>>[
      {'text': _geminiPrompt},
    ];

    if (hasTemplateImage) {
      final path = templateImagePath!.trim();
      parts.add({
        'inlineData': {
          'mimeType': _mimeTypeForPath(path),
          'data': base64Encode(await File(path).readAsBytes()),
        },
      });
    }

    return {
      'contents': [
        {'role': 'user', 'parts': parts},
      ],
      'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
        'responseFormat': {
          'image': {'aspectRatio': _geminiAspectRatio},
        },
      },
    };
  }

  Map<String, dynamic> toGeminiDebugJson() {
    return {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': _geminiPrompt},
            if (hasTemplateImage)
              {
                'inlineData': {
                  'mimeType': _mimeTypeForPath(templateImagePath!.trim()),
                  'data': '已省略（本地参考图）',
                },
              },
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
        'responseFormat': {
          'image': {'aspectRatio': _geminiAspectRatio},
        },
      },
    };
  }

  String get _effectiveModel => model.trim();

  String get _debugImageSizeCapability {
    return imageSizeCapabilityLabel(
      imageModelCapabilitiesFor(
        providerKind: providerKind,
        model: model,
        capabilityOverride: imageSizeCapabilityOverride,
      ),
    );
  }

  String get _effectiveRequestSize => requestSizeForModel(
    size: size,
    providerKind: providerKind,
    model: model,
    capabilityOverride: imageSizeCapabilityOverride,
  );

  String get _effectiveGeminiModel {
    return model.trim().replaceFirst(RegExp(r'^models/'), '');
  }

  Map<String, dynamic> _debugJsonBody() {
    try {
      return toJson();
    } on ImageGenerationException catch (error) {
      return {
        'model': _effectiveModel,
        'prompt': _mergedPrompt,
        'size': size,
        'n': normalizedImageCount,
        'validation_error': error.message,
      };
    }
  }

  Map<String, String> _debugMultipartFields() {
    try {
      return toMultipartFields();
    } on ImageGenerationException catch (error) {
      return {
        'model': _effectiveModel,
        'prompt': _mergedPrompt,
        'size': size,
        'n': normalizedImageCount.toString(),
        'validation_error': error.message,
      };
    }
  }

  String get _mergedPrompt {
    final negative = negativePrompt.trim();
    if (negative.isEmpty) {
      return prompt;
    }

    return '$prompt\n\nAvoid: $negative';
  }

  String get _geminiPrompt => _mergedPrompt;

  String get _geminiAspectRatio {
    return geminiAspectRatioForDimensions(imageDimensionsFromSize(size));
  }

  static String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/png';
  }
}

class OpenAIImageResponse {
  const OpenAIImageResponse({required this.images});

  final List<GeneratedImage> images;
}

String normalizeOpenAiBaseUrl(String value) {
  final trimmed = value.trim();
  final fallback = trimmed.isEmpty ? 'https://api.openai.com/v1' : trimmed;
  return fallback.replaceFirst(RegExp(r'/+$'), '');
}

String normalizeGeminiBaseUrl(String value) {
  final trimmed = value.trim();
  final fallback = trimmed.isEmpty
      ? defaultBaseUrlForProviderKind(ApiProviderKind.gemini)
      : trimmed;
  return fallback.replaceFirst(RegExp(r'/+$'), '');
}

void validateApiKeyForRequestHeader(String apiKey) {
  final value = apiKey.trim();
  if (value.isEmpty) {
    throw const ImageGenerationException('请先填写 API Key。');
  }
  if (value.toLowerCase().startsWith('bearer ')) {
    throw const ImageGenerationException('API Key 输入框只需要填写密钥本身，请去掉 Bearer 前缀。');
  }
  if (_containsInvalidApiKeyHeaderCharacter(value)) {
    throw const ImageGenerationException(
      'API Key 含有无法作为 HTTP 请求头发送的字符。请检查是否把提示词、URL、JSON '
      '或其他说明文字填到了 API Key 输入框；这里只能填写接口密钥本身。',
    );
  }
}

bool _containsInvalidApiKeyHeaderCharacter(String value) {
  for (var i = 0; i < value.length; i++) {
    final codeUnit = value.codeUnitAt(i);
    if (codeUnit < 0x21 || codeUnit > 0x7e) {
      return true;
    }
  }
  return false;
}
