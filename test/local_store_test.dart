import 'package:feather_canvas_studio/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists and restores settings and history', () async {
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
    );

    final historyEntry = GenerationHistoryEntry(
      id: '1',
      createdAt: DateTime.parse('2026-05-13T10:00:00Z'),
      baseUrl: settings.baseUrl,
      model: settings.model,
      prompt: settings.prompt,
      negativePrompt: settings.negativePrompt,
      size: settings.size,
      imageCount: settings.imageCount,
      resultCount: 2,
    );

    await store.saveSettings(settings);
    await store.addHistoryEntry(historyEntry);

    final restoredSettings = await store.loadSettings();
    final restoredHistory = await store.loadHistory();

    expect(restoredSettings.baseUrl, settings.baseUrl);
    expect(restoredSettings.apiKey, settings.apiKey);
    expect(restoredSettings.model, settings.model);
    expect(restoredSettings.prompt, settings.prompt);
    expect(restoredSettings.negativePrompt, settings.negativePrompt);
    expect(restoredSettings.size, settings.size);
    expect(restoredSettings.imageCount, settings.imageCount);

    expect(restoredHistory, hasLength(1));
    expect(restoredHistory.single.id, historyEntry.id);
    expect(restoredHistory.single.prompt, historyEntry.prompt);
    expect(restoredHistory.single.resultCount, historyEntry.resultCount);
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
      ),
      ApiConfig(
        id: 'proxy',
        name: '本地代理',
        baseUrl: 'http://127.0.0.1:8080/v1',
        apiKey: 'proxy-key',
        model: 'gpt-image-2',
      ),
    ];

    await store.saveApiConfigs(configs);
    await store.saveSelectedApiConfigId('proxy');

    final restoredConfigs = await store.loadApiConfigs();
    final selectedId = await store.loadSelectedApiConfigId();

    expect(restoredConfigs, hasLength(2));
    expect(restoredConfigs.first.name, 'OpenAI 官方');
    expect(restoredConfigs.last.baseUrl, 'http://127.0.0.1:8080/v1');
    expect(restoredConfigs.last.apiKey, 'proxy-key');
    expect(selectedId, 'proxy');
  });
}
