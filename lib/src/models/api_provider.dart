/// 标识接口提供方与它对应的请求协议。
///
/// - [official] 直连 OpenAI 官方 GPT Image 接口，可发送全部高级参数。
/// - [compatible] 走 OpenAI 兼容反代或第三方网关，只发送基础字段。
/// - [gemini] 走 Google Gemini 原生 `generateContent` 协议。
enum ApiProviderKind { official, compatible, gemini }

String serializeApiProviderKind(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official => 'official',
    ApiProviderKind.compatible => 'compatible',
    ApiProviderKind.gemini => 'gemini',
  };
}

ApiProviderKind parseApiProviderKind(
  Object? value, {
  required ApiProviderKind fallback,
}) {
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'official':
        return ApiProviderKind.official;
      case 'compatible':
        return ApiProviderKind.compatible;
      case 'gemini':
        return ApiProviderKind.gemini;
    }
  }
  return fallback;
}

String defaultBaseUrlForProviderKind(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official => 'https://api.openai.com/v1',
    ApiProviderKind.compatible => 'https://api.openai.com/v1',
    ApiProviderKind.gemini =>
      'https://generativelanguage.googleapis.com/v1beta',
  };
}

String defaultModelForProviderKind(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official => 'gpt-image-2',
    ApiProviderKind.compatible => 'gpt-image-2',
    ApiProviderKind.gemini => 'gemini-2.5-flash-image',
  };
}
