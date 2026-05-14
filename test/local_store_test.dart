import 'package:feather_canvas_studio/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists and restores settings', () async {
    SharedPreferences.setMockInitialValues({});
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

    expect(restoredSettings.baseUrl, settings.baseUrl);
    expect(restoredSettings.apiKey, settings.apiKey);
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

    expect(restoredConfigs, hasLength(3));
    expect(restoredConfigs.first.name, 'OpenAI 官方');
    expect(restoredConfigs.first.providerKind, ApiProviderKind.official);
    expect(restoredConfigs[1].baseUrl, 'http://127.0.0.1:8080/v1');
    expect(restoredConfigs[1].apiKey, 'proxy-key');
    expect(restoredConfigs[1].providerKind, ApiProviderKind.compatible);
    expect(restoredConfigs.last.model, 'gemini-2.5-flash-image');
    expect(restoredConfigs.last.providerKind, ApiProviderKind.gemini);
    expect(selectedId, 'proxy');
  });

  test('persists and restores image library items', () async {
    SharedPreferences.setMockInitialValues({});
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
}
