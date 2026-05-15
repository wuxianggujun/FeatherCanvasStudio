import 'dart:convert';

import 'package:http/http.dart' as http;

import 'image_api_request.dart';

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
      responseBody: response == null
          ? responseBody
          : utf8.decode(response.bodyBytes, allowMalformed: true),
      decodedResponse: decodedResponse ?? this.decodedResponse,
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
