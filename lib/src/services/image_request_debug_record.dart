import 'dart:convert';

import 'package:http/http.dart' as http;

import 'image_api_request.dart';

const int _kBase64ElisionThreshold = 256;
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

  ImageRequestDebugRecord copyWith({
    http.Response? response,
    Map<String, dynamic>? decodedResponse,
    String? errorMessage,
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
      },
    };
  }

  String get formattedJson {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
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
  final pattern = RegExp(
    '"(b64_json|data)"\\s*:\\s*"([^"\\\\]{$_kBase64ElisionThreshold,})"',
  );
  return body.replaceAllMapped(pattern, (match) {
    final field = match.group(1);
    final length = match.group(2)?.length ?? 0;
    return '"$field": "<base64 elided: $length chars>"';
  });
}
