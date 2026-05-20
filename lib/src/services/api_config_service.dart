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
  ApiConfigServiceLabels labels = const ApiConfigServiceLabels(),
}) async {
  if (apiConfig.apiKey.trim().isEmpty) {
    return ApiConfigTestResult(success: false, message: labels.apiKeyRequired);
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
      message: basic ? labels.basicTestSuccess : labels.fullTestSuccess,
      debugRecord: latestDebugRecord,
    );
  } on ImageGenerationException catch (error) {
    return ApiConfigTestResult(
      success: false,
      message: decorateApiTestErrorMessage(
        baseMessage: error.message,
        providerKind: request.providerKind,
        basic: basic,
        labels: labels,
      ),
      debugRecord: latestDebugRecord,
    );
  } on TimeoutException {
    return ApiConfigTestResult(
      success: false,
      message: labels.testTimeout,
      debugRecord: latestDebugRecord,
    );
  } catch (error) {
    return ApiConfigTestResult(
      success: false,
      message: labels.fullTestFailedWithError(error),
      debugRecord: latestDebugRecord,
    );
  }
}

Future<ApiModelFetchResult> fetchApiModelsForConfig({
  required OpenAICompatibleImageClient client,
  required ApiConfig apiConfig,
  ApiConfigServiceLabels labels = const ApiConfigServiceLabels(),
}) async {
  final requestKey = apiModelRequestKey(apiConfig);
  if (apiConfig.apiKey.trim().isEmpty) {
    return ApiModelFetchResult(
      requestKey: requestKey,
      models: const [],
      message: labels.modelFetchApiKeyRequired,
      errorMessage: labels.modelFetchApiKeyRequired,
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
        labels: labels,
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
    final message = labels.modelFetchTimeout;
    return ApiModelFetchResult(
      requestKey: requestKey,
      models: const [],
      message: message,
      errorMessage: message,
    );
  } catch (error) {
    final message = labels.modelFetchFailed(error);
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
  ApiConfigServiceLabels labels = const ApiConfigServiceLabels(),
}) {
  if (models.isEmpty) {
    return labels.modelFetchEmpty;
  }
  if (autoSelectedModel != null) {
    return labels.modelFetchSelected(models.length, autoSelectedModel.id);
  }
  return labels.modelFetchSuccess(models.length);
}

class ApiConfigServiceLabels extends ApiConfigDisplayLabels {
  const ApiConfigServiceLabels();

  String get apiKeyRequired => '请先填写 API Key';
  String get basicTestSuccess => '基础测试通过：接口可用，可尝试切换到完整测试验证高级参数';
  String get fullTestSuccess => '接口测试成功，已收到图片数据';
  String get testTimeout => '接口测试超时，请检查反代或网络';

  String fullTestFailedWithError(Object error) {
    return '接口测试失败：$error';
  }

  String get modelFetchApiKeyRequired => '请先填写 API Key 再拉取模型列表';
  String get modelFetchTimeout => '获取模型列表超时，请检查反代或网络';
  String get modelFetchEmpty => '接口没有返回可用模型，仍可手动填写模型名称';

  String modelFetchFailed(Object error) {
    return '获取模型列表失败：$error';
  }

  String modelFetchSelected(int count, String modelId) {
    return '已获取 $count 个模型，并选择 $modelId';
  }

  String modelFetchSuccess(int count) {
    return '已获取 $count 个模型，可从列表中选择';
  }
}
