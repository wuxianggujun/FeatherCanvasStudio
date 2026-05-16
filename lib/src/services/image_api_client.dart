import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/api_provider.dart';
import '../models/exceptions.dart';
import '../models/generated_image.dart';
import 'image_api_models.dart';
import 'image_api_request.dart';
import 'image_request_debug_record.dart';
import 'image_response_parser.dart';

export 'image_api_models.dart';
export 'image_api_request.dart';
export 'image_request_debug_record.dart';
export 'image_response_parser.dart';

class OpenAICompatibleImageClient {
  static const Duration defaultGenerationTimeout = Duration(minutes: 8);
  static const Duration _modelFetchTimeout = Duration(seconds: 30);
  static const Duration _imageDownloadTimeout = Duration(minutes: 2);

  OpenAICompatibleImageClient({
    http.Client? httpClient,
    Duration generationTimeout = defaultGenerationTimeout,
  }) : _httpClient = httpClient ?? http.Client(),
       _generationTimeout = generationTimeout;

  final http.Client _httpClient;
  final Duration _generationTimeout;

  Future<OpenAIImageResponse> generate(
    OpenAIImageRequest request, {
    ValueChanged<ImageRequestDebugRecord>? onDebugRecord,
  }) async {
    var debugRecord = ImageRequestDebugRecord.fromRequest(request);
    void publishDebugRecord({
      http.Response? response,
      Map<String, dynamic>? decodedResponse,
      String? errorMessage,
    }) {
      debugRecord = debugRecord.copyWith(
        response: response,
        decodedResponse: decodedResponse,
        errorMessage: errorMessage,
      );
      onDebugRecord?.call(debugRecord);
    }

    publishDebugRecord();
    late final http.Response response;
    try {
      request.validateForGeneration();
      response = request.providerKind == ApiProviderKind.gemini
          ? await _postGeminiGenerateContent(request)
          : request.hasTemplateImage
          ? await _postImageEdit(request)
          : await _postImageGeneration(request);
    } on TimeoutException catch (_) {
      const message = '生图请求超时：服务端可能正在生成较慢的图片，或网关没有在预期时间内返回完整响应。';
      publishDebugRecord(errorMessage: message);
      throw const ImageGenerationException(message);
    } on ImageGenerationException catch (error) {
      publishDebugRecord(errorMessage: error.message);
      rethrow;
    }

    publishDebugRecord(response: response);
    Map<String, dynamic>? decoded;
    try {
      decoded = ImageResponseParser.decodeJsonObject(
        response.bodyBytes,
        statusCode: response.statusCode,
        reasonPhrase: response.reasonPhrase,
      );
      publishDebugRecord(response: response, decodedResponse: decoded);
      final responseErrorMessage = ImageResponseParser.extractErrorMessage(
        decoded,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ImageGenerationException(
          responseErrorMessage ??
              '请求失败：HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}',
        );
      }

      if (responseErrorMessage != null) {
        throw ImageGenerationException(responseErrorMessage);
      }

      final images = request.providerKind == ApiProviderKind.gemini
          ? ImageResponseParser.parseGeminiImages(decoded)
          : ImageResponseParser.parseOpenAiImages(decoded);
      return OpenAIImageResponse(images: images);
    } on ImageGenerationException catch (error) {
      publishDebugRecord(
        response: response,
        decodedResponse: decoded,
        errorMessage: error.message,
      );
      rethrow;
    }
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
        .timeout(request.generationTimeout ?? _generationTimeout);
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
        .timeout(request.generationTimeout ?? _generationTimeout);
  }

  Future<http.Response> _postImageEdit(OpenAIImageRequest request) async {
    final multipartRequest = http.MultipartRequest('POST', request.endpoint)
      ..headers['Authorization'] = 'Bearer ${request.apiKey}'
      ..fields.addAll(request.toMultipartFields())
      ..files.add(
        await http.MultipartFile.fromPath('image', request.templateImagePath!),
      );

    final timeout = request.generationTimeout ?? _generationTimeout;
    final streamedResponse = await _httpClient
        .send(multipartRequest)
        .timeout(timeout);
    return http.Response.fromStream(streamedResponse).timeout(timeout);
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

    final endpoint = buildModelsEndpoint(
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
        .timeout(_modelFetchTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = safeDecodeJsonObject(response.bodyBytes);
      final message = decoded == null
          ? null
          : ImageResponseParser.extractErrorMessage(decoded);
      throw ImageGenerationException(
        message ??
            '获取模型列表失败：HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}',
      );
    }

    final decoded = ImageResponseParser.decodeJsonObject(
      response.bodyBytes,
      statusCode: response.statusCode,
      reasonPhrase: response.reasonPhrase,
    );

    return providerKind == ApiProviderKind.gemini
        ? parseGeminiModelList(decoded)
        : parseOpenAiModelList(decoded);
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
          .timeout(_imageDownloadTimeout);
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
}
