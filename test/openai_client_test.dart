import 'dart:convert';

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
        size: '1024x1024',
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
}
