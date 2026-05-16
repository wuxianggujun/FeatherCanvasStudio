import 'dart:convert';
import 'dart:io';

import '../models/api_provider.dart';
import '../models/exceptions.dart';
import '../models/generated_image.dart';
import '../models/image_advanced_settings.dart';
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
  final Duration? generationTimeout;

  bool get hasTemplateImage =>
      templateImagePath != null && templateImagePath!.trim().isNotEmpty;

  void validateForGeneration() {
    if (model.trim().isEmpty) {
      throw const ImageGenerationException('请先在接口配置页获取模型列表并选择模型，或手动填写模型名称。');
    }
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
      'n': imageCount,
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
        'apiKey': apiKey.trim().isEmpty ? '未填写' : '已填写（已隐藏）',
        if (hasTemplateImage) 'templateImagePath': templateImagePath,
        'jsonBody': toGeminiDebugJson(),
      };
    }

    return {
      'endpoint': endpoint.toString(),
      'method': hasTemplateImage ? 'POST multipart/form-data' : 'POST JSON',
      'providerKind': serializeApiProviderKind(providerKind),
      'apiKey': apiKey.trim().isEmpty ? '未填写' : '已填写（已隐藏）',
      if (hasTemplateImage) 'templateImagePath': templateImagePath,
      if (hasTemplateImage)
        'multipartFields': toMultipartFields()
      else
        'jsonBody': toJson(),
    };
  }

  Map<String, String> toMultipartFields() {
    return {
      'model': _effectiveModel,
      'prompt': _mergedPrompt,
      'size': _effectiveRequestSize,
      'n': imageCount.toString(),
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

  String get _effectiveRequestSize =>
      requestSizeForProvider(size, providerKind);

  String get _effectiveGeminiModel {
    return model.trim().replaceFirst(RegExp(r'^models/'), '');
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
