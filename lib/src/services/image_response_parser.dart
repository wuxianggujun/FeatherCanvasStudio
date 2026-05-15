import 'dart:convert';
import 'dart:typed_data';

import '../models/exceptions.dart';
import '../models/generated_image.dart';

class ImageResponseParser {
  const ImageResponseParser._();

  static Map<String, dynamic> decodeJsonObject(
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

  static String? extractErrorMessage(Map<String, dynamic> decoded) {
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

  static List<GeneratedImage> parseOpenAiImages(Map<String, dynamic> decoded) {
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

    return images;
  }

  static List<GeneratedImage> parseGeminiImages(Map<String, dynamic> decoded) {
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
}
