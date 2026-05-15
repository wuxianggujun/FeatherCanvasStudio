import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists and restores settings', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final store = AppLocalStore();

    const settings = AppSettings(
      baseUrl: 'https://example.com/v1',
      apiKey: 'secret',
      model: 'gpt-image-2',
      prompt: 'hello world',
      negativePrompt: 'blurry',
      size: '1024x1536',
      imageCount: 3,
      advancedSettings: ImageAdvancedSettings(
        quality: 'high',
        background: 'transparent',
        outputFormat: 'webp',
        outputCompression: 80,
        moderation: 'low',
        user: 'user-123',
        inputFidelity: 'high',
      ),
    );

    await store.saveSettings(settings);

    final restoredSettings = await store.loadSettings();
    final prefs = await SharedPreferences.getInstance();

    expect(restoredSettings.baseUrl, settings.baseUrl);
    expect(restoredSettings.apiKey, settings.apiKey);
    expect(prefs.getString('settings.apiKey'), isNull);
    expect(restoredSettings.model, settings.model);
    expect(restoredSettings.prompt, settings.prompt);
    expect(restoredSettings.negativePrompt, settings.negativePrompt);
    expect(restoredSettings.size, settings.size);
    expect(restoredSettings.imageCount, settings.imageCount);
    expect(restoredSettings.advancedSettings.quality, 'high');
    expect(restoredSettings.advancedSettings.background, 'transparent');
    expect(restoredSettings.advancedSettings.outputFormat, 'webp');
    expect(restoredSettings.advancedSettings.outputCompression, 80);
    expect(restoredSettings.advancedSettings.moderation, 'low');
    expect(restoredSettings.advancedSettings.user, 'user-123');
    expect(restoredSettings.advancedSettings.inputFidelity, 'high');
  });

  test('persists API configurations and selected configuration id', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final store = AppLocalStore();

    const configs = [
      ApiConfig(
        id: 'official',
        name: 'OpenAI 官方',
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'official-key',
        model: 'gpt-image-2',
        providerKind: ApiProviderKind.official,
      ),
      ApiConfig(
        id: 'proxy',
        name: '本地代理',
        baseUrl: 'http://127.0.0.1:8080/v1',
        apiKey: 'proxy-key',
        model: 'gpt-image-2',
        providerKind: ApiProviderKind.compatible,
      ),
      ApiConfig(
        id: 'gemini',
        name: 'Gemini',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'gemini-key',
        model: 'gemini-2.5-flash-image',
        providerKind: ApiProviderKind.gemini,
      ),
    ];

    await store.saveApiConfigs(configs);
    await store.saveSelectedApiConfigId('proxy');

    final restoredConfigs = await store.loadApiConfigs();
    final selectedId = await store.loadSelectedApiConfigId();
    final prefs = await SharedPreferences.getInstance();
    final rawConfigs = prefs.getString('apiConfigs.entries') ?? '';

    expect(restoredConfigs, hasLength(3));
    expect(rawConfigs, isNot(contains('official-key')));
    expect(rawConfigs, isNot(contains('proxy-key')));
    expect(rawConfigs, isNot(contains('gemini-key')));
    expect(restoredConfigs.first.name, 'OpenAI 官方');
    expect(restoredConfigs.first.providerKind, ApiProviderKind.official);
    expect(restoredConfigs[1].baseUrl, 'http://127.0.0.1:8080/v1');
    expect(restoredConfigs[1].apiKey, 'proxy-key');
    expect(restoredConfigs[1].providerKind, ApiProviderKind.compatible);
    expect(restoredConfigs.last.model, 'gemini-2.5-flash-image');
    expect(restoredConfigs.last.providerKind, ApiProviderKind.gemini);
    expect(selectedId, 'proxy');
  });

  test('migrates legacy API keys out of shared preferences', () async {
    SharedPreferences.setMockInitialValues({
      'settings.apiKey': 'legacy-settings-key',
      'apiConfigs.entries': jsonEncode([
        {
          'id': 'legacy',
          'name': 'Legacy',
          'baseUrl': 'https://example.com/v1',
          'apiKey': 'legacy-config-key',
          'model': 'legacy-image-model',
          'providerKind': 'compatible',
        },
      ]),
    });
    FlutterSecureStorage.setMockInitialValues({});
    final store = AppLocalStore();

    final settings = await store.loadSettings();
    final configs = await store.loadApiConfigs();
    final prefs = await SharedPreferences.getInstance();
    final rawConfigs = prefs.getString('apiConfigs.entries') ?? '';

    expect(settings.apiKey, 'legacy-settings-key');
    expect(configs.single.apiKey, 'legacy-config-key');
    expect(prefs.getString('settings.apiKey'), isNull);
    expect(rawConfigs, isNot(contains('legacy-config-key')));
  });

  test('persists and restores image library items', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final store = AppLocalStore();

    final libraryItem = ImageLibraryItem(
      id: 'library-1',
      path: '/tmp/generated/sheet.png',
      createdAt: DateTime.parse('2026-05-13T11:00:00Z'),
      kind: ImageAssetKind.spriteSheet,
      title: '导出 Sprite Sheet',
      source: 'Sprite Sheet 导出',
      note: '主角行走动画',
      prompt: '4 x 4',
      generation: GenerationSnapshot(
        id: 'group-1',
        createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-image-2',
        providerKind: ApiProviderKind.official,
        prompt: '主角行走动画',
        negativePrompt: 'blurry',
        size: '1024x1024',
        imageCount: 1,
        resultCount: 1,
        advancedSettings: const ImageAdvancedSettings(
          quality: 'high',
          outputFormat: 'webp',
        ),
      ),
      groupId: 'group-1',
    );

    await store.addImageLibraryItems([libraryItem]);

    final restoredItems = await store.loadImageLibrary();

    expect(restoredItems, hasLength(1));
    expect(restoredItems.single.id, libraryItem.id);
    expect(restoredItems.single.path, libraryItem.path);
    expect(restoredItems.single.kind, ImageAssetKind.spriteSheet);
    expect(restoredItems.single.title, libraryItem.title);
    expect(restoredItems.single.source, libraryItem.source);
    expect(restoredItems.single.note, libraryItem.note);
    expect(restoredItems.single.groupId, libraryItem.groupId);
    expect(restoredItems.single.generation?.model, 'gpt-image-2');
    expect(
      restoredItems.single.generation?.providerKind,
      ApiProviderKind.official,
    );
    expect(
      restoredItems.single.generation?.advancedSettings.outputFormat,
      'webp',
    );
  });

  test('cleans generated files that are no longer referenced', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final tempDir = await Directory.systemTemp.createTemp(
      'local_store_cleanup_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    final store = AppLocalStore(baseDirectoryOverride: tempDir);
    final generatedDirectory = await store.ensureGeneratedImagesDirectory();
    final keptFile = File(
      '${generatedDirectory.path}${Platform.pathSeparator}kept.png',
    );
    final orphanFile = File(
      '${generatedDirectory.path}${Platform.pathSeparator}orphan.png',
    );
    await keptFile.writeAsBytes([1, 2, 3], flush: true);
    await orphanFile.writeAsBytes([4, 5, 6, 7], flush: true);
    final ephemeralFile = await store.saveEphemeralBytes(
      prefix: 'template',
      bytes: Uint8List.fromList([8, 9]),
    );

    final summary = await store.cleanupGeneratedFiles(
      libraryItems: [
        ImageLibraryItem(
          id: 'kept',
          path: keptFile.path,
          createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
          kind: ImageAssetKind.generatedImage,
          title: 'Kept',
          source: 'Test',
        ),
      ],
    );

    expect(await keptFile.exists(), isTrue);
    expect(await orphanFile.exists(), isFalse);
    expect(await ephemeralFile.exists(), isFalse);
    expect(summary.removedGeneratedFiles, 1);
    expect(summary.removedEphemeralFiles, 1);
    expect(summary.freedBytes, 6);
  });
}
