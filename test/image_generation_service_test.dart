import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as image_lib;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'generates text images and caches them with a generation snapshot',
    () async {
      SharedPreferences.setMockInitialValues({});
      final tempDir = await Directory.systemTemp.createTemp(
        'image_generation_service_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      ImageRequestDebugRecord? debugRecord;
      final client = OpenAICompatibleImageClient(
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['prompt'], contains('paint a bird'));
          expect(body['n'], 1);

          return http.Response(
            jsonEncode({
              'data': [
                {
                  'b64_json': base64Encode([4, 5, 6]),
                },
              ],
            }),
            200,
          );
        }),
      );

      final store = AppLocalStore(baseDirectoryOverride: tempDir);
      final result = await const ImageGenerationService().generateTextImages(
        client: client,
        store: store,
        imageLibraryService: const ImageLibraryService(),
        apiConfig: _apiConfig,
        prompt: 'paint a bird',
        negativePrompt: '',
        size: '1024x1024',
        imageCount: 1,
        advancedSettings: const ImageAdvancedSettings(user: 'ignored'),
        user: 'user-123',
        titlePrefix: '文本生图',
        source: '文本生图',
        onDebugRecord: (record) => debugRecord = record,
      );

      expect(result.groupId, isNotEmpty);
      expect(result.cachedImages, hasLength(1));
      expect(result.cachedImages.single.filePath, isNotNull);
      expect(await File(result.cachedImages.single.filePath!).readAsBytes(), [
        4,
        5,
        6,
      ]);
      expect(result.generation.prompt, 'paint a bird');
      expect(result.generation.advancedSettings.user, 'user-123');
      expect(result.libraryItems, hasLength(1));
      expect(result.libraryItems.single.title, '文本生图 1');
      expect(result.libraryItems.single.generation?.id, result.groupId);
      expect(
        (await store.loadImageLibrary()).single.id,
        result.libraryItems.single.id,
      );
      expect(debugRecord?.statusCode, 200);
    },
  );

  test('generates and caches a sprite sheet only once', () async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = await Directory.systemTemp.createTemp(
      'sprite_generation_service_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final spriteSheet = image_lib.Image(width: 4, height: 4)
      ..clear(image_lib.ColorRgb8(255, 0, 0));
    final spriteSheetBytes = Uint8List.fromList(
      image_lib.encodePng(spriteSheet),
    );
    final client = OpenAICompatibleImageClient(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['prompt'], contains('2 rows x 2 columns'));

        return http.Response(
          jsonEncode({
            'data': [
              {'b64_json': base64Encode(spriteSheetBytes)},
            ],
          }),
          200,
        );
      }),
    );

    final store = AppLocalStore(baseDirectoryOverride: tempDir);
    final result = await const ImageGenerationService().generateSpriteSheet(
      client: client,
      store: store,
      imageLibraryService: const ImageLibraryService(),
      apiConfig: _apiConfig,
      prompt: 'walking character',
      negativePrompt: '',
      size: '1024x1024',
      rows: 2,
      columns: 2,
      advancedSettings: const ImageAdvancedSettings(),
      user: '',
      source: '帧动',
    );

    expect(result.groupId, startsWith('animation_'));
    expect(result.cachedSheet.filePath, isNotNull);
    expect(await File(result.cachedSheet.filePath!).exists(), isTrue);
    expect(result.saveResult.frameWidth, 2);
    expect(result.saveResult.frameHeight, 2);
    expect(result.generation.prompt, 'walking character');
    expect(result.libraryItem?.kind, ImageAssetKind.spriteSheet);
    expect(result.libraryItem?.rows, 2);
    expect((await store.loadImageLibrary()).single.id, result.libraryItem?.id);
  });
}

const _apiConfig = ApiConfig(
  id: 'config',
  name: 'Config',
  baseUrl: 'https://proxy.example.com/v1',
  apiKey: 'token',
  model: 'gpt-image-2',
  providerKind: ApiProviderKind.compatible,
);
