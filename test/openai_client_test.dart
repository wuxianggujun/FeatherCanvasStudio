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
        templateImagePath: templateFile.path,
      ),
    );

    expect(response.images, hasLength(1));
    expect(response.images.single.bytes, isNotNull);
  });
}
