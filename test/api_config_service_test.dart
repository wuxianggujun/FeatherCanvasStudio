import 'dart:convert';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'tests API config connection and keeps the latest debug record',
    () async {
      ImageRequestDebugRecord? callbackRecord;
      final client = OpenAICompatibleImageClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'https://proxy.example.com/v1/images/generations',
          );

          return http.Response(
            jsonEncode({
              'data': [
                {
                  'b64_json': base64Encode([1, 2, 3]),
                },
              ],
            }),
            200,
          );
        }),
      );

      final result = await testApiConfigConnection(
        client: client,
        apiConfig: const ApiConfig(
          id: 'proxy',
          name: 'Proxy',
          baseUrl: 'https://proxy.example.com/v1',
          apiKey: 'token',
          model: 'gpt-image-2',
          providerKind: ApiProviderKind.compatible,
        ),
        basic: false,
        onDebugRecord: (record) => callbackRecord = record,
      );

      expect(result.success, isTrue);
      expect(result.message, contains('接口测试成功'));
      expect(result.debugRecord?.statusCode, 200);
      expect(callbackRecord?.statusCode, 200);
    },
  );

  test('decorates official API config test upstream errors', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': '502 Bad Gateway'},
          }),
          502,
          reasonPhrase: 'Bad Gateway',
        );
      }),
    );

    final result = await testApiConfigConnection(
      client: client,
      apiConfig: const ApiConfig(
        id: 'official',
        name: 'Official',
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'token',
        model: 'gpt-image-2',
        providerKind: ApiProviderKind.official,
      ),
      basic: false,
    );

    expect(result.success, isFalse);
    expect(result.message, contains('接口测试失败'));
    expect(result.message, contains('OpenAI 官方'));
  });

  test('fetches models and selects a preferred image model', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://proxy.example.com/v1/models');

        return http.Response(
          jsonEncode({
            'data': [
              {'id': 'text-model'},
              {'id': 'imagen-pro'},
            ],
          }),
          200,
        );
      }),
    );

    final result = await fetchApiModelsForConfig(
      client: client,
      apiConfig: const ApiConfig(
        id: 'proxy',
        name: 'Proxy',
        baseUrl: 'https://proxy.example.com/v1',
        apiKey: 'token',
        model: '',
        providerKind: ApiProviderKind.compatible,
      ),
    );

    expect(result.success, isTrue);
    expect(result.models.map((model) => model.id), [
      'imagen-pro',
      'text-model',
    ]);
    expect(result.autoSelectedModel?.id, 'imagen-pro');
    expect(result.message, contains('并选择 imagen-pro'));
  });

  test('treats an empty model response as a successful fetch', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://proxy.example.com/v1/models');

        return http.Response(jsonEncode({'data': []}), 200);
      }),
    );

    final result = await fetchApiModelsForConfig(
      client: client,
      apiConfig: const ApiConfig(
        id: 'proxy',
        name: 'Proxy',
        baseUrl: 'https://proxy.example.com/v1',
        apiKey: 'token',
        model: 'gpt-image-2',
        providerKind: ApiProviderKind.compatible,
      ),
    );

    expect(result.success, isTrue);
    expect(result.models, isEmpty);
    expect(result.errorMessage, isNull);
    expect(result.autoSelectedModel, isNull);
    expect(result.message, contains('没有返回可用模型'));
  });

  test('validates API key before fetching model lists', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        fail('empty API key should not issue a network request');
      }),
    );

    final result = await fetchApiModelsForConfig(
      client: client,
      apiConfig: const ApiConfig(
        id: 'empty',
        name: 'Empty',
        baseUrl: 'https://proxy.example.com/v1',
        apiKey: '',
        model: 'gpt-image-2',
        providerKind: ApiProviderKind.compatible,
      ),
    );

    expect(result.success, isFalse);
    expect(result.models, isEmpty);
    expect(result.errorMessage, contains('API Key'));
  });
}
