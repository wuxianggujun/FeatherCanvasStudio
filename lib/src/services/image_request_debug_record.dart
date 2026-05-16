import 'dart:convert';

import 'package:http/http.dart' as http;

import 'image_api_request.dart';

const int _kBase64ElisionThreshold = 256;
const int _kResponseBodyPreviewLimit = 32768;
const Set<String> _kBase64FieldNames = {'b64_json', 'data'};

class ImageRequestDebugRecord {
  const ImageRequestDebugRecord({
    required this.createdAt,
    required this.request,
    this.completedAt,
    this.statusCode,
    this.reasonPhrase,
    this.responseHeaders = const {},
    this.responseBody,
    this.decodedResponse,
    this.errorMessage,
    this.errorStackTrace,
  });

  factory ImageRequestDebugRecord.fromRequest(OpenAIImageRequest request) {
    return ImageRequestDebugRecord(
      createdAt: DateTime.now(),
      request: request.toDebugJson(),
    );
  }

  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic> request;
  final int? statusCode;
  final String? reasonPhrase;
  final Map<String, String> responseHeaders;
  final String? responseBody;
  final Map<String, dynamic>? decodedResponse;
  final String? errorMessage;
  final String? errorStackTrace;

  ImageRequestDebugRecord copyWith({
    http.Response? response,
    Map<String, dynamic>? decodedResponse,
    String? errorMessage,
    StackTrace? stackTrace,
    DateTime? completedAt,
  }) {
    final sanitizedDecoded = decodedResponse == null
        ? this.decodedResponse
        : _sanitizeDebugPayload(decodedResponse) as Map<String, dynamic>?;
    final rawBody = response == null
        ? responseBody
        : utf8.decode(response.bodyBytes, allowMalformed: true);

    return ImageRequestDebugRecord(
      createdAt: createdAt,
      completedAt:
          completedAt ??
          this.completedAt ??
          ((response != null || decodedResponse != null || errorMessage != null)
              ? DateTime.now()
              : null),
      request: request,
      statusCode: response?.statusCode ?? statusCode,
      reasonPhrase: response?.reasonPhrase ?? reasonPhrase,
      responseHeaders: response?.headers ?? responseHeaders,
      responseBody: rawBody == null ? null : _sanitizeResponseBody(rawBody),
      decodedResponse: sanitizedDecoded,
      errorMessage: errorMessage ?? this.errorMessage,
      errorStackTrace: stackTrace == null
          ? errorStackTrace
          : _formatStackTrace(stackTrace),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (completedAt != null)
        'durationMs': completedAt!.difference(createdAt).inMilliseconds,
      'request': request,
      'response': {
        'statusCode': statusCode,
        'reasonPhrase': reasonPhrase,
        'headers': responseHeaders,
        'body': responseBody,
        if (decodedResponse != null) 'json': decodedResponse,
        if (errorMessage != null) 'error': errorMessage,
        if (errorStackTrace != null) 'stackTrace': errorStackTrace,
      },
    };
  }

  String get formattedJson {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}

String _formatStackTrace(StackTrace stackTrace) {
  return stackTrace.toString().split('\n').take(16).join('\n').trim();
}

dynamic _sanitizeDebugPayload(dynamic node) {
  if (node is Map) {
    final out = <String, dynamic>{};
    node.forEach((key, value) {
      final keyName = key.toString();
      if (_kBase64FieldNames.contains(keyName) &&
          value is String &&
          value.length > _kBase64ElisionThreshold) {
        out[keyName] = '<base64 elided: ${value.length} chars>';
      } else {
        out[keyName] = _sanitizeDebugPayload(value);
      }
    });
    return out;
  }
  if (node is List) {
    return [for (final item in node) _sanitizeDebugPayload(item)];
  }
  return node;
}

String _sanitizeResponseBody(String body) {
  try {
    final decoded = jsonDecode(body);
    final sanitized = jsonEncode(_sanitizeDebugPayload(decoded));
    return _truncateResponseBody(sanitized);
  } catch (_) {
    return _truncateResponseBody(body);
  }
}

String _truncateResponseBody(String body) {
  if (body.length <= _kResponseBodyPreviewLimit) {
    return body;
  }
  final omitted = body.length - _kResponseBodyPreviewLimit;
  return '${body.substring(0, _kResponseBodyPreviewLimit)}'
      '\n<response body truncated: $omitted chars omitted>';
}
