import 'dart:convert';

import '../models/api_provider.dart';
import '../models/exceptions.dart';
import 'image_api_request.dart';

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

Uri buildModelsEndpoint({
  required String baseUrl,
  required ApiProviderKind providerKind,
}) {
  final trimmed = baseUrl.trim();
  final fallback = trimmed.isEmpty
      ? defaultBaseUrlForProviderKind(providerKind)
      : trimmed;
  final normalized = providerKind == ApiProviderKind.gemini
      ? normalizeGeminiBaseUrl(fallback)
      : normalizeOpenAiBaseUrl(fallback);
  final root = normalized
      .replaceFirst(RegExp(r'/images/(generations|edits)$'), '')
      .replaceFirst(RegExp(r'/models/[^/]+:generateContent$'), '')
      .replaceFirst(RegExp(r'/models$'), '');
  return Uri.parse('$root/models');
}

Map<String, dynamic>? safeDecodeJsonObject(List<int> bodyBytes) {
  try {
    final raw = utf8.decode(bodyBytes, allowMalformed: true);
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

List<ApiModelInfo> parseOpenAiModelList(Map<String, dynamic> decoded) {
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

List<ApiModelInfo> parseGeminiModelList(Map<String, dynamic> decoded) {
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
