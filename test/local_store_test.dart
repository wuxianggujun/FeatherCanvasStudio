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
}
