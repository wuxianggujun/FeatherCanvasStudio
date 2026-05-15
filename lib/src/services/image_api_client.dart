import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/api_provider.dart';
import '../models/exceptions.dart';
import '../models/generated_image.dart';
import '../models/image_advanced_settings.dart';
import '../utils/image_dimensions.dart';

class OpenAICompatibleImageClient {
  OpenAICompatibleImageClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<OpenAIImageResponse> generate(
    OpenAIImageRequest request, {
    ValueChanged<ImageRequestDebugRecord>? onDebugRecord,
  }) async {
    final debugRecord = ImageRequestDebugRecord.fromRequest(request);
    void publishDebugRecord([
      http.Response? response,
      Map<String, dynamic>? decodedResponse,
    ]) {
      onDebugRecord?.call(
        debugRecord.copyWith(
          response: response,
          decodedResponse: decodedResponse,
        ),
      );
    }

    publishDebugRecord();
    final response = request.providerKind == ApiProviderKind.gemini
        ? await _postGeminiGenerateContent(request)
        : request.hasTemplateImage
        ? await _postImageEdit(request)
        : await _postImageGeneration(request);

    publishDebugRecord(response);
    final decoded = _decodeJsonObject(
      response.bodyBytes,
      statusCode: response.statusCode,
      reasonPhrase: response.reasonPhrase,
    );
    publishDebugRecord(response, decoded);
    final responseErrorMessage = _extractErrorMessage(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ImageGenerationException(
        responseErrorMessage ??
            '请求失败：HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}',
      );
    }

    if (responseErrorMessage != null) {
      throw ImageGenerationException(responseErrorMessage);
    }

    if (request.providerKind == ApiProviderKind.gemini) {
      return OpenAIImageResponse(images: _parseGeminiImages(decoded));
    }

    final data = decoded['data'];
    if (data is! List || data.isEmpty) {
      throw const ImageGenerationException('接口没有返回图片数据。');
    }

    final images = <GeneratedImage>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final nestedError = item['error'];
      if (nestedError is Map<String, dynamic>) {
        final message = nestedError['message'];
        if (message is String && message.trim().isNotEmpty) {
          throw ImageGenerationException(message);
        }
      }

      final message = item['message'];
      if (message is String &&
          message.trim().isNotEmpty &&
          item['b64_json'] == null &&
          item['url'] == null) {
        throw ImageGenerationException(message);
      }

      final b64Json = item['b64_json'];
      final url = item['url'];
      final revisedPrompt = item['revised_prompt'];

      if (b64Json is String && b64Json.trim().isNotEmpty) {
        images.add(
          GeneratedImage.bytes(
            _decodeBase64Image(b64Json),
            revisedPrompt: revisedPrompt is String ? revisedPrompt : null,
          ),
        );
        continue;
      }

      if (url is String && url.trim().isNotEmpty) {
        images.add(
          GeneratedImage.url(
            url,
            revisedPrompt: revisedPrompt is String ? revisedPrompt : null,
          ),
        );
      }
    }

    if (images.isEmpty) {
      throw const ImageGenerationException('接口返回了 data，但未包含 b64_json 或 url。');
    }

    return OpenAIImageResponse(images: images);
  }

  Future<http.Response> _postGeminiGenerateContent(
    OpenAIImageRequest request,
  ) async {
    return _httpClient
        .post(
          request.endpoint,
          headers: {
            'x-goog-api-key': request.apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(await request.toGeminiJson()),
        )
        .timeout(const Duration(minutes: 2));
  }

  Future<http.Response> _postImageGeneration(OpenAIImageRequest request) {
    return _httpClient
        .post(
          request.endpoint,
          headers: {
            'Authorization': 'Bearer ${request.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(minutes: 2));
  }

  Future<http.Response> _postImageEdit(OpenAIImageRequest request) async {
    final multipartRequest = http.MultipartRequest('POST', request.endpoint)
      ..headers['Authorization'] = 'Bearer ${request.apiKey}'
      ..fields.addAll(request.toMultipartFields())
      ..files.add(
        await http.MultipartFile.fromPath('image', request.templateImagePath!),
      );

    final streamedResponse = await _httpClient
        .send(multipartRequest)
        .timeout(const Duration(minutes: 2));
    return http.Response.fromStream(
      streamedResponse,
    ).timeout(const Duration(minutes: 2));
  }

  Future<List<ApiModelInfo>> fetchAvailableModels({
    required String baseUrl,
    required String apiKey,
    required ApiProviderKind providerKind,
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const ImageGenerationException('请先填写 API Key 再拉取模型列表。');
    }

    final endpoint = _modelsEndpoint(
      baseUrl: baseUrl,
      providerKind: providerKind,
    );
    final headers = providerKind == ApiProviderKind.gemini
        ? <String, String>{
            'x-goog-api-key': trimmedKey,
            'Content-Type': 'application/json',
          }
        : <String, String>{
            'Authorization': 'Bearer $trimmedKey',
            'Content-Type': 'application/json',
          };

    final response = await _httpClient
        .get(endpoint, headers: headers)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _safeDecodeJsonObject(response.bodyBytes);
      final message = decoded == null ? null : _extractErrorMessage(decoded);
      throw ImageGenerationException(
        message ??
            '获取模型列表失败：HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}',
      );
    }

    final decoded = _decodeJsonObject(
      response.bodyBytes,
      statusCode: response.statusCode,
      reasonPhrase: response.reasonPhrase,
    );

    return providerKind == ApiProviderKind.gemini
        ? _parseGeminiModelList(decoded)
        : _parseOpenAiModelList(decoded);
  }

  Uri _modelsEndpoint({
    required String baseUrl,
    required ApiProviderKind providerKind,
  }) {
    final trimmed = baseUrl.trim();
    final fallback = trimmed.isEmpty
        ? defaultBaseUrlForProviderKind(providerKind)
        : trimmed;
    final normalized = providerKind == ApiProviderKind.gemini
        ? OpenAIImageRequest._normalizeGeminiBaseUrl(fallback)
        : OpenAIImageRequest._normalizeBaseUrl(fallback);
    final root = normalized
        .replaceFirst(RegExp(r'/images/(generations|edits)$'), '')
        .replaceFirst(RegExp(r'/models/[^/]+:generateContent$'), '')
        .replaceFirst(RegExp(r'/models$'), '');
    return Uri.parse('$root/models');
  }

  Map<String, dynamic>? _safeDecodeJsonObject(List<int> bodyBytes) {
    try {
      final raw = utf8.decode(bodyBytes, allowMalformed: true);
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  List<ApiModelInfo> _parseOpenAiModelList(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    if (data is! List) {
      throw const ImageGenerationException('接口返回的模型列表格式不正确。');
    }
    final results = <ApiModelInfo>[];
    for (final entry in data) {
      final id = switch (entry) {
        String value => value,
        Map<String, dynamic> value => value['id'] ?? value['name'],
        _ => null,
      };
      if (id is! String || id.trim().isEmpty) continue;
      final ownedBy = entry is Map<String, dynamic>
          ? entry['owned_by'] ?? entry['owner']
          : null;
      results.add(
        ApiModelInfo(
          id: id.trim(),
          ownedBy: ownedBy is String && ownedBy.trim().isNotEmpty
              ? ownedBy.trim()
              : null,
        ),
      );
    }
    results.sort((a, b) => a.id.compareTo(b.id));
    return results;
  }

  List<ApiModelInfo> _parseGeminiModelList(Map<String, dynamic> decoded) {
    final models = decoded['models'];
    if (models is! List) {
      throw const ImageGenerationException('接口返回的模型列表格式不正确。');
    }
    final results = <ApiModelInfo>[];
    for (final entry in models) {
      if (entry is! Map<String, dynamic>) continue;
      final rawName = entry['name'];
      if (rawName is! String || rawName.trim().isEmpty) continue;
      final name = rawName.trim().replaceFirst(RegExp(r'^models/'), '');
      final description = entry['displayName'];
      results.add(
        ApiModelInfo(
          id: name,
          ownedBy: description is String && description.trim().isNotEmpty
              ? description.trim()
              : null,
        ),
      );
    }
    results.sort((a, b) => a.id.compareTo(b.id));
    return results;
  }

  Future<Uint8List> resolveImageBytes(GeneratedImage image) async {
    if (image.bytes != null) {
      return image.bytes!;
    }

    if (image.filePath != null) {
      return File(image.filePath!).readAsBytes();
    }

    if (image.url != null) {
      final response = await _httpClient
          .get(Uri.parse(image.url!))
          .timeout(const Duration(minutes: 2));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ImageGenerationException(
          '图片下载失败：HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}',
        );
      }
      return response.bodyBytes;
    }

    throw const ImageGenerationException('图片没有可用的二进制内容。');
  }

  void close() => _httpClient.close();

  static Map<String, dynamic> _decodeJsonObject(
    List<int> bodyBytes, {
    required int statusCode,
    String? reasonPhrase,
  }) {
    final body = utf8.decode(bodyBytes, allowMalformed: true);
    final decoded = _tryDecodeJson(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    final responseSummary = statusCode == 0
        ? ''
        : 'HTTP $statusCode ${reasonPhrase ?? ''}'.trim();
    final bodyPreview = _compactResponsePreview(body);
    throw ImageGenerationException(
      [
        if (responseSummary.isNotEmpty) '接口返回异常：$responseSummary。',
        '接口返回的不是 JSON 数据，可能是 Base URL 填错、网关/登录页拦截，或服务端返回了 HTML。',
        if (bodyPreview.isNotEmpty) '响应开头：$bodyPreview',
      ].join('\n'),
    );
  }

  static dynamic _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static String _compactResponsePreview(String body) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 120) {
      return normalized;
    }

    return '${normalized.substring(0, 120)}...';
  }

  static Uint8List _decodeBase64Image(String value) {
    final normalized = value.contains(',') ? value.split(',').last : value;
    return base64Decode(normalized.trim());
  }

  static String? _extractErrorMessage(Map<String, dynamic> decoded) {
    final error = decoded['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    final message = decoded['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return null;
  }

  static List<GeneratedImage> _parseGeminiImages(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const ImageGenerationException('Gemini 接口没有返回候选结果。');
    }

    final images = <GeneratedImage>[];
    final textParts = <String>[];
    for (final candidate in candidates) {
      if (candidate is! Map<String, dynamic>) {
        continue;
      }

      final content = candidate['content'];
      if (content is! Map<String, dynamic>) {
        continue;
      }

      final parts = content['parts'];
      if (parts is! List) {
        continue;
      }

      for (final part in parts) {
        if (part is! Map<String, dynamic>) {
          continue;
        }

        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) {
          textParts.add(text.trim());
        }

        final inlineData = part['inlineData'] ?? part['inline_data'];
        if (inlineData is! Map<String, dynamic>) {
          continue;
        }

        final mimeType =
            inlineData['mimeType'] as String? ??
            inlineData['mime_type'] as String? ??
            '';
        final data = inlineData['data'];
        if (data is String &&
            data.trim().isNotEmpty &&
            mimeType.toLowerCase().startsWith('image/')) {
          final revisedPrompt = textParts.join('\n\n').trim();
          images.add(
            GeneratedImage.bytes(
              _decodeBase64Image(data),
              revisedPrompt: revisedPrompt.isEmpty ? null : revisedPrompt,
            ),
          );
        }
      }
    }

    if (images.isEmpty) {
      final textPreview = textParts.join('\n\n').trim();
      throw ImageGenerationException(
        textPreview.isEmpty
            ? 'Gemini 接口返回了候选结果，但没有包含图片 inlineData。'
            : 'Gemini 没有返回图片，只返回了文本：$textPreview',
      );
    }

    return images;
  }
}

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

  bool get hasTemplateImage =>
      templateImagePath != null && templateImagePath!.trim().isNotEmpty;

  Uri get endpoint {
    if (providerKind == ApiProviderKind.gemini) {
      return geminiEndpoint;
    }

    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);
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
    final normalizedBaseUrl = _normalizeGeminiBaseUrl(baseUrl);
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

  String get _effectiveModel => model.isEmpty ? 'gpt-image-2' : model;

  String get _effectiveRequestSize =>
      requestSizeForProvider(size, providerKind);

  String get _effectiveGeminiModel {
    final normalized = model.trim().replaceFirst(RegExp(r'^models/'), '');
    return normalized.isEmpty
        ? defaultModelForProviderKind(ApiProviderKind.gemini)
        : normalized;
  }

  String get _mergedPrompt {
    final negative = negativePrompt.trim();
    if (negative.isEmpty) {
      return prompt;
    }

    return '$prompt\n\nAvoid: $negative';
  }

  String get _geminiPrompt => _mergedPrompt;

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    final fallback = trimmed.isEmpty ? 'https://api.openai.com/v1' : trimmed;
    return fallback.replaceFirst(RegExp(r'/+$'), '');
  }

  static String _normalizeGeminiBaseUrl(String value) {
    final trimmed = value.trim();
    final fallback = trimmed.isEmpty
        ? defaultBaseUrlForProviderKind(ApiProviderKind.gemini)
        : trimmed;
    return fallback.replaceFirst(RegExp(r'/+$'), '');
  }

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

class ApiModelInfo {
  const ApiModelInfo({required this.id, this.ownedBy});

  final String id;
  final String? ownedBy;

  String get displayLabel {
    final owner = ownedBy?.trim();
    if (owner == null || owner.isEmpty || owner == id) {
      return id;
    }
    return '$id · $owner';
  }
}

class ImageRequestDebugRecord {
  const ImageRequestDebugRecord({
    required this.createdAt,
    required this.request,
    this.statusCode,
    this.reasonPhrase,
    this.responseHeaders = const {},
    this.responseBody,
    this.decodedResponse,
  });

  factory ImageRequestDebugRecord.fromRequest(OpenAIImageRequest request) {
    return ImageRequestDebugRecord(
      createdAt: DateTime.now(),
      request: request.toDebugJson(),
    );
  }

  final DateTime createdAt;
  final Map<String, dynamic> request;
  final int? statusCode;
  final String? reasonPhrase;
  final Map<String, String> responseHeaders;
  final String? responseBody;
  final Map<String, dynamic>? decodedResponse;

  ImageRequestDebugRecord copyWith({
    http.Response? response,
    Map<String, dynamic>? decodedResponse,
  }) {
    return ImageRequestDebugRecord(
      createdAt: createdAt,
      request: request,
      statusCode: response?.statusCode ?? statusCode,
      reasonPhrase: response?.reasonPhrase ?? reasonPhrase,
      responseHeaders: response?.headers ?? responseHeaders,
      responseBody: response == null
          ? responseBody
          : utf8.decode(response.bodyBytes, allowMalformed: true),
      decodedResponse: decodedResponse ?? this.decodedResponse,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'request': request,
      'response': {
        'statusCode': statusCode,
        'reasonPhrase': reasonPhrase,
        'headers': responseHeaders,
        'body': responseBody,
        if (decodedResponse != null) 'json': decodedResponse,
      },
    };
  }

  String get formattedJson {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
