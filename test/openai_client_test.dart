import 'dart:convert';
import 'dart:io';

import 'package:feather_canvas_studio/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('normalizes the endpoint path', () {
    const request = OpenAIImageRequest(
      baseUrl: 'https://api.openai.com/v1/',
      apiKey: 'token',
      model: 'gpt-image-2',
      prompt: 'hello',
      negativePrompt: '',
      size: '1024x1024',
      imageCount: 1,
    );

    expect(
      request.endpoint.toString(),
      'https://api.openai.com/v1/images/generations',
    );
  });

  test('parses b64_json image payloads', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.openai.com/v1/images/generations',
        );

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['prompt'], contains('Avoid: blurry'));
        expect(body['size'], '4096x4096');
        expect(body['quality'], 'high');
        expect(body['background'], 'transparent');
        expect(body['output_format'], 'webp');
        expect(body['output_compression'], 80);
        expect(body['moderation'], 'low');
        expect(body['user'], 'user-123');

        return http.Response(
          jsonEncode({
            'data': [
              {
                'b64_json': base64Encode([0, 1, 2, 3]),
                'revised_prompt': 'revised',
              },
            ],
          }),
          200,
        );
      }),
    );

    final response = await client.generate(
      const OpenAIImageRequest(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'token',
        model: 'gpt-image-2',
        prompt: 'hello',
        negativePrompt: 'blurry',
        size: '4096x4096',
        imageCount: 1,
        advancedSettings: ImageAdvancedSettings(
          quality: 'high',
          background: 'transparent',
          outputFormat: 'webp',
          outputCompression: 80,
          moderation: 'low',
          user: 'user-123',
        ),
      ),
    );

    expect(response.images, hasLength(1));
    expect(response.images.single.bytes, isNotNull);
    expect(response.images.single.revisedPrompt, 'revised');
  });

  test('parses url image payloads', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {'url': 'https://example.com/image.png'},
            ],
          }),
          200,
        );
      }),
    );

    final response = await client.generate(
      const OpenAIImageRequest(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'token',
        model: 'gpt-image-2',
        prompt: 'hello',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 1,
      ),
    );

    expect(response.images, hasLength(1));
    expect(response.images.single.url, 'https://example.com/image.png');
  });

  test('OpenAI image request normalizes size to 16-pixel steps', () {
    const request = OpenAIImageRequest(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: 'token',
      model: 'gpt-image-2',
      prompt: 'hello',
      negativePrompt: '',
      size: '683x1024',
      imageCount: 1,
    );

    expect(request.toJson()['size'], '688x1024');
  });

  test('OpenAI image request clamps extreme custom sizes', () {
    const request = OpenAIImageRequest(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: 'token',
      model: 'gpt-image-2',
      prompt: 'hello',
      negativePrompt: '',
      size: '25x2049',
      imageCount: 1,
    );

    expect(request.toJson()['size'], '512x2048');
  });

  test('requests one image when generating a sprite sheet', () async {
    var requestCount = 0;
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        requestCount++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['n'], 1);
        expect(body['prompt'], contains('sprite sheet'));
        expect(body['prompt'], contains('4 rows x 4 columns'));

        return http.Response(
          jsonEncode({
            'data': [
              {
                'b64_json': base64Encode([0, 1, 2, 3]),
              },
            ],
          }),
          200,
        );
      }),
    );

    final response = await client.generate(
      const OpenAIImageRequest(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'token',
        model: 'gpt-image-2',
        prompt: 'Create ONE complete sprite sheet image, 4 rows x 4 columns.',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 1,
      ),
    );

    expect(requestCount, 1);
    expect(response.images, hasLength(1));
  });

  test('treats 200 responses with nested error payloads as failures', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'error': {
                  'message':
                      'Concurrency limit exceeded for account, please retry later',
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    expect(
      () => client.generate(
        const OpenAIImageRequest(
          baseUrl: 'https://api.openai.com/v1',
          apiKey: 'token',
          model: 'gpt-image-2',
          prompt: 'hello',
          negativePrompt: '',
          size: '1024x1024',
          imageCount: 1,
        ),
      ),
      throwsA(
        isA<ImageGenerationException>().having(
          (error) => error.message,
          'message',
          contains('Concurrency limit exceeded'),
        ),
      ),
    );
  });

  test('reports non-json responses without leaking FormatException', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        return http.Response(
          '<!DOCTYPE html><html><body>Not Found</body></html>',
          404,
          reasonPhrase: 'Not Found',
          headers: {'content-type': 'text/html'},
        );
      }),
    );

    expect(
      () => client.generate(
        const OpenAIImageRequest(
          baseUrl: 'https://example.com/wrong',
          apiKey: 'token',
          model: 'gpt-image-2',
          prompt: 'hello',
          negativePrompt: '',
          size: '1024x1024',
          imageCount: 1,
        ),
      ),
      throwsA(
        isA<ImageGenerationException>()
            .having(
              (error) => error.message,
              'message',
              allOf(
                contains('接口返回的不是 JSON 数据'),
                contains('HTTP 404 Not Found'),
                contains('<!DOCTYPE html>'),
              ),
            )
            .having(
              (error) => error.message,
              'message',
              isNot(contains('FormatException')),
            ),
      ),
    );
  });

  test('uses image edit endpoint when a template image is supplied', () async {
    final templateFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}template-image.png',
    );
    await templateFile.writeAsBytes([0, 1, 2, 3], flush: true);
    addTearDown(() {
      if (templateFile.existsSync()) {
        templateFile.deleteSync();
      }
    });

    final client = OpenAICompatibleImageClient(
      httpClient: MockClient.streaming((request, bodyStream) async {
        expect(
          request.url.toString(),
          'https://api.openai.com/v1/images/edits',
        );
        expect(request, isA<http.MultipartRequest>());

        final multipartRequest = request as http.MultipartRequest;
        expect(multipartRequest.fields['prompt'], contains('Avoid: blurry'));
        expect(multipartRequest.fields['size'], '1024x1024');
        expect(multipartRequest.fields['quality'], 'medium');
        expect(multipartRequest.fields['background'], 'opaque');
        expect(multipartRequest.fields['output_format'], 'jpeg');
        expect(multipartRequest.fields['output_compression'], '70');
        expect(multipartRequest.fields['input_fidelity'], 'high');
        expect(multipartRequest.fields.containsKey('moderation'), isFalse);
        expect(multipartRequest.files, hasLength(1));
        expect(multipartRequest.files.single.field, 'image');
        await bodyStream.drain<void>();

        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'data': [
                  {
                    'b64_json': base64Encode([4, 5, 6]),
                  },
                ],
              }),
            ),
          ),
          200,
        );
      }),
    );

    final response = await client.generate(
      OpenAIImageRequest(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'token',
        model: 'gpt-image-2',
        prompt: 'hello',
        negativePrompt: 'blurry',
        size: '1024x1024',
        imageCount: 1,
        advancedSettings: const ImageAdvancedSettings(
          quality: 'medium',
          background: 'opaque',
          outputFormat: 'jpeg',
          outputCompression: 70,
          moderation: 'low',
          inputFidelity: 'high',
        ),
        templateImagePath: templateFile.path,
      ),
    );

    expect(response.images, hasLength(1));
    expect(response.images.single.bytes, isNotNull);
  });

  test(
    'compatible providerKind sends only model/prompt/size/n in JSON body',
    () async {
      final client = OpenAICompatibleImageClient(
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          // 兼容档应该剔除所有 GPT Image 专属参数，避免反代层 502。
          expect(body.keys, unorderedEquals(['model', 'prompt', 'size', 'n']));
          expect(body['model'], 'gpt-image-2');
          expect(body['size'], '1024x1024');
          expect(body['n'], 1);

          return http.Response(
            jsonEncode({
              'data': [
                {
                  'b64_json': base64Encode([0, 1]),
                },
              ],
            }),
            200,
          );
        }),
      );

      await client.generate(
        const OpenAIImageRequest(
          baseUrl: 'https://proxy.example.com/v1',
          apiKey: 'token',
          model: 'gpt-image-2',
          prompt: 'hello',
          negativePrompt: '',
          size: '1024x1024',
          imageCount: 1,
          providerKind: ApiProviderKind.compatible,
          advancedSettings: ImageAdvancedSettings(
            quality: 'high',
            background: 'transparent',
            outputFormat: 'webp',
            outputCompression: 80,
            moderation: 'low',
            user: 'user-123',
            inputFidelity: 'high',
          ),
        ),
      );
    },
  );

  test(
    'compatible providerKind strips advanced fields from multipart edits',
    () async {
      final templateFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}compat-template.png',
      );
      await templateFile.writeAsBytes([0, 1, 2, 3], flush: true);
      addTearDown(() {
        if (templateFile.existsSync()) {
          templateFile.deleteSync();
        }
      });

      final client = OpenAICompatibleImageClient(
        httpClient: MockClient.streaming((request, bodyStream) async {
          final multipart = request as http.MultipartRequest;
          expect(
            multipart.fields.keys,
            unorderedEquals(['model', 'prompt', 'size', 'n']),
          );
          expect(multipart.fields['n'], '1');
          await bodyStream.drain<void>();

          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'data': [
                    {
                      'b64_json': base64Encode([9]),
                    },
                  ],
                }),
              ),
            ),
            200,
          );
        }),
      );

      await client.generate(
        OpenAIImageRequest(
          baseUrl: 'https://proxy.example.com/v1',
          apiKey: 'token',
          model: 'gpt-image-2',
          prompt: 'hello',
          negativePrompt: '',
          size: '1024x1024',
          imageCount: 1,
          providerKind: ApiProviderKind.compatible,
          advancedSettings: const ImageAdvancedSettings(
            quality: 'high',
            outputFormat: 'jpeg',
            outputCompression: 70,
            moderation: 'low',
            inputFidelity: 'high',
          ),
          templateImagePath: templateFile.path,
        ),
      );
    },
  );

  test('gemini provider posts generateContent and parses inlineData', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent',
        );
        expect(request.headers['x-goog-api-key'], 'gemini-key');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['contents'], isA<List>());
        expect(body['generationConfig'], {
          'responseModalities': ['TEXT', 'IMAGE'],
          'responseFormat': {
            'image': {'aspectRatio': '1:1'},
          },
        });
        final contents = body['contents'] as List;
        final firstContent = contents.single as Map<String, dynamic>;
        final parts = firstContent['parts'] as List;
        expect(parts.first['text'], contains('hello'));
        expect(
          parts.first['text'],
          isNot(contains('Requested image aspect ratio')),
        );

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'revised prompt'},
                    {
                      'inlineData': {
                        'mimeType': 'image/png',
                        'data': base64Encode([7, 8, 9]),
                      },
                    },
                  ],
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final response = await client.generate(
      const OpenAIImageRequest(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'gemini-key',
        model: 'gemini-2.5-flash-image',
        prompt: 'hello',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 1,
        providerKind: ApiProviderKind.gemini,
      ),
    );

    expect(response.images, hasLength(1));
    expect(response.images.single.bytes, [7, 8, 9]);
    expect(response.images.single.revisedPrompt, 'revised prompt');
  });

  test('gemini provider sends aspect ratio in responseFormat', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final generationConfig =
            body['generationConfig'] as Map<String, dynamic>;
        expect(generationConfig['responseFormat'], {
          'image': {'aspectRatio': '2:3'},
        });

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'inlineData': {
                        'mimeType': 'image/png',
                        'data': base64Encode([1]),
                      },
                    },
                  ],
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    await client.generate(
      const OpenAIImageRequest(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'gemini-key',
        model: 'gemini-2.5-flash-image',
        prompt: 'hello',
        negativePrompt: '',
        size: '1024x1536',
        imageCount: 1,
        providerKind: ApiProviderKind.gemini,
      ),
    );
  });

  test('gemini provider includes template image inlineData', () async {
    final templateFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}gemini-template.png',
    );
    await templateFile.writeAsBytes([1, 2, 3], flush: true);
    addTearDown(() {
      if (templateFile.existsSync()) {
        templateFile.deleteSync();
      }
    });

    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final contents = body['contents'] as List;
        final firstContent = contents.single as Map<String, dynamic>;
        final parts = firstContent['parts'] as List;
        final inlineData = parts.last['inlineData'] as Map<String, dynamic>;
        expect(inlineData['mimeType'], 'image/png');
        expect(inlineData['data'], base64Encode([1, 2, 3]));

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'inlineData': {
                        'mimeType': 'image/png',
                        'data': base64Encode([4, 5, 6]),
                      },
                    },
                  ],
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final response = await client.generate(
      OpenAIImageRequest(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'gemini-key',
        model: 'gemini-2.5-flash-image',
        prompt: 'edit this image',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 1,
        providerKind: ApiProviderKind.gemini,
        templateImagePath: templateFile.path,
      ),
    );

    expect(response.images.single.bytes, [4, 5, 6]);
  });

  test('fetches OpenAI-compatible model lists', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://proxy.example.com/v1/models');
        expect(request.headers['Authorization'], 'Bearer token');

        return http.Response(
          jsonEncode({
            'data': [
              {'id': 'gpt-image-1', 'owned_by': 'openai'},
              'custom-image-model',
            ],
          }),
          200,
        );
      }),
    );

    final models = await client.fetchAvailableModels(
      baseUrl: 'https://proxy.example.com/v1/images/generations',
      apiKey: 'token',
      providerKind: ApiProviderKind.compatible,
    );

    expect(models.map((model) => model.id), [
      'custom-image-model',
      'gpt-image-1',
    ]);
    expect(models.last.ownedBy, 'openai');
  });

  test('fetches Gemini model lists from a generateContent endpoint', () async {
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://generativelanguage.googleapis.com/v1beta/models',
        );
        expect(request.headers['x-goog-api-key'], 'gemini-key');

        return http.Response(
          jsonEncode({
            'models': [
              {
                'name': 'models/gemini-2.5-flash-image',
                'displayName': 'Gemini 2.5 Flash Image',
              },
            ],
          }),
          200,
        );
      }),
    );

    final models = await client.fetchAvailableModels(
      baseUrl:
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent',
      apiKey: 'gemini-key',
      providerKind: ApiProviderKind.gemini,
    );

    expect(models.single.id, 'gemini-2.5-flash-image');
    expect(models.single.ownedBy, 'Gemini 2.5 Flash Image');
  });
}
