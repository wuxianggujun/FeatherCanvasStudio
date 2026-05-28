import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds image generation request from API config and UI values', () {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: ' key ',
      model: 'gpt-image-2',
      providerKind: ApiProviderKind.official,
      imageSizeCapabilityOverride: ImageSizeCapabilityOverride.customPixels,
    );

    final request = buildImageGenerationRequest(
      apiConfig: config,
      prompt: 'prompt',
      negativePrompt: 'negative',
      requestSize: '1024x1024',
      imageCount: 2,
      advancedSettings: const ImageAdvancedSettings(user: 'old-user'),
      user: ' new-user ',
      templateImagePath: '/tmp/template.png',
      templateImagePaths: const ['/tmp/style.png'],
    );

    expect(request.baseUrl, 'https://example.com/v1');
    expect(request.apiKey, 'key');
    expect(request.model, 'gpt-image-2');
    expect(request.prompt, 'prompt');
    expect(request.negativePrompt, 'negative');
    expect(request.size, '1024x1024');
    expect(request.imageCount, 2);
    expect(request.providerKind, ApiProviderKind.official);
    expect(
      request.imageSizeCapabilityOverride,
      ImageSizeCapabilityOverride.customPixels,
    );
    expect(request.advancedSettings.user, 'new-user');
    expect(request.templateImagePath, '/tmp/template.png');
    expect(request.normalizedTemplateImagePaths, [
      '/tmp/template.png',
      '/tmp/style.png',
    ]);
  });

  test('builds generation snapshot with reusable metadata', () {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
      providerKind: ApiProviderKind.compatible,
      imageSizeCapabilityOverride: ImageSizeCapabilityOverride.fixedPresets,
    );
    final createdAt = DateTime.parse('2026-05-15T12:00:00Z');

    final snapshot = buildGenerationSnapshot(
      groupId: 'group',
      apiConfig: config,
      prompt: 'prompt',
      negativePrompt: 'negative',
      requestSize: '1024x1536',
      imageCount: 3,
      resultCount: 2,
      advancedSettings: const ImageAdvancedSettings(quality: 'high'),
      user: ' user-1 ',
      createdAt: createdAt,
    );

    expect(snapshot.id, 'group');
    expect(snapshot.createdAt, createdAt);
    expect(snapshot.baseUrl, 'https://example.com/v1');
    expect(snapshot.model, 'gpt-image-2');
    expect(snapshot.providerKind, ApiProviderKind.compatible);
    expect(
      snapshot.imageSizeCapabilityOverride,
      ImageSizeCapabilityOverride.fixedPresets,
    );
    expect(snapshot.prompt, 'prompt');
    expect(snapshot.negativePrompt, 'negative');
    expect(snapshot.size, '1024x1536');
    expect(snapshot.imageCount, 3);
    expect(snapshot.resultCount, 2);
    expect(snapshot.advancedSettings.quality, 'high');
    expect(snapshot.advancedSettings.user, 'user-1');
  });

  test(
    'caps request image count and leaves large totals to batch splitting',
    () {
      const config = ApiConfig(
        id: 'config',
        name: 'Config',
        baseUrl: 'https://example.com/v1',
        apiKey: 'key',
        model: 'gpt-image-2',
        providerKind: ApiProviderKind.compatible,
      );

      final request = buildImageGenerationRequest(
        apiConfig: config,
        prompt: 'prompt',
        negativePrompt: '',
        requestSize: '1024x1024',
        imageCount: 12,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      );
      final snapshot = buildGenerationSnapshot(
        groupId: 'group',
        apiConfig: config,
        prompt: 'prompt',
        negativePrompt: '',
        requestSize: '1024x1024',
        imageCount: 12,
        resultCount: 8,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      );

      expect(request.imageCount, maxImageGenerationRequestCount);
      expect(request.toJson()['n'], maxImageGenerationRequestCount);
      expect(snapshot.imageCount, maxImageGenerationRequestCount);
      expect(splitImageGenerationBatches(targetCount: 12, requestCount: 4), [
        4,
        4,
        4,
      ]);
      expect(splitImageGenerationBatches(targetCount: 10, requestCount: 4), [
        4,
        4,
        2,
      ]);
    },
  );
}
