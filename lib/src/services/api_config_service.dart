import 'dart:async';

import '../models/app_config.dart';
import '../models/exceptions.dart';
import '../utils/api_config_logic.dart';
import 'image_api_client.dart';

class ApiConfigTestResult {
  const ApiConfigTestResult({
    required this.success,
    required this.message,
    this.debugRecord,
  });

  final bool success;
  final String message;
  final ImageRequestDebugRecord? debugRecord;
}

class ApiModelFetchResult {
  const ApiModelFetchResult({
    required this.requestKey,
    required this.models,
    required this.message,
    this.errorMessage,
    this.autoSelectedModel,
  });

  final String requestKey;
  final List<ApiModelInfo> models;
  final String message;
  final String? errorMessage;
  final ApiModelInfo? autoSelectedModel;

  bool get success => errorMessage == null;
}

Future<ApiConfigTestResult> testApiConfigConnection({
  required OpenAICompatibleImageClient client,
  required ApiConfig apiConfig,
  required bool basic,
  void Function(ImageRequestDebugRecord record)? onDebugRecord,
}) async {
  if (apiConfig.apiKey.trim().isEmpty) {
    return const ApiConfigTestResult(success: false, message: '请先填写 API Key');
  }

  final request = buildApiConfigTestRequest(apiConfig: apiConfig, basic: basic);
  ImageRequestDebugRecord? latestDebugRecord;

  try {
    await client.generate(
      request,
      onDebugRecord: (record) {
        latestDebugRecord = record;
        onDebugRecord?.call(record);
      },
    );

    return ApiConfigTestResult(
      success: true,
      message: basic ? '基础测试通过：接口可用，可尝试切换到完整测试验证高级参数' : '接口测试成功，已收到图片数据',
      debugRecord: latestDebugRecord,
    );
  } on ImageGenerationException catch (error) {
    return ApiConfigTestResult(
      success: false,
      message: decorateApiTestErrorMessage(
        baseMessage: error.message,
        providerKind: request.providerKind,
        basic: basic,
      ),
      debugRecord: latestDebugRecord,
    );
  } on TimeoutException {
    return ApiConfigTestResult(
      success: false,
      message: '接口测试超时，请检查反代或网络',
      debugRecord: latestDebugRecord,
    );
  } catch (error) {
    return ApiConfigTestResult(
      success: false,
      message: '接口测试失败：$error',
      debugRecord: latestDebugRecord,
    );
  }
}

Future<ApiModelFetchResult> fetchApiModelsForConfig({
  required OpenAICompatibleImageClient client,
  required ApiConfig apiConfig,
}) async {
  final requestKey = apiModelRequestKey(apiConfig);
  if (apiConfig.apiKey.trim().isEmpty) {
    return ApiModelFetchResult(
      requestKey: requestKey,
      models: const [],
      message: '请先填写 API Key 再拉取模型列表',
      errorMessage: '请先填写 API Key 再拉取模型列表',
    );
  }

  try {
    final models = await client.fetchAvailableModels(
      baseUrl: apiConfig.baseUrl,
      apiKey: apiConfig.apiKey,
      providerKind: apiConfig.providerKind,
    );
    final autoSelectedModel = preferredFetchedModel(models, apiConfig);

    return ApiModelFetchResult(
      requestKey: requestKey,
      models: models,
      autoSelectedModel: autoSelectedModel,
      message: modelFetchSuccessMessage(
        models: models,
        autoSelectedModel: autoSelectedModel,
      ),
      errorMessage: null,
    );
  } on ImageGenerationException catch (error) {
    return ApiModelFetchResult(
      requestKey: requestKey,
      models: const [],
      message: error.message,
      errorMessage: error.message,
    );
  } on TimeoutException {
    const message = '获取模型列表超时，请检查反代或网络';
    return ApiModelFetchResult(
      requestKey: requestKey,
      models: const [],
      message: message,
      errorMessage: message,
    );
  } catch (error) {
    final message = '获取模型列表失败：$error';
    return ApiModelFetchResult(
      requestKey: requestKey,
      models: const [],
      message: message,
      errorMessage: message,
    );
  }
}

String modelFetchSuccessMessage({
  required List<ApiModelInfo> models,
  required ApiModelInfo? autoSelectedModel,
}) {
  if (models.isEmpty) {
    return '接口没有返回可用模型，仍可手动填写模型名称';
  }
  if (autoSelectedModel != null) {
    return '已获取 ${models.length} 个模型，并选择 ${autoSelectedModel.id}';
  }
  return '已获取 ${models.length} 个模型，可从列表中选择';
}
