import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds API config draft from controller text', () {
    final draft = buildApiConfigDraft(
      selectedId: null,
      nameText: '  ',
      baseUrlText: ' https://example.com/v1 ',
      apiKeyText: ' key ',
      modelText: ' gpt-image-2 ',
      providerKind: ApiProviderKind.official,
      imageSizeCapabilityOverride: ImageSizeCapabilityOverride.customPixels,
    );

    expect(draft.id, isNotEmpty);
    expect(draft.name, unnamedApiConfigName);
    expect(draft.baseUrl, 'https://example.com/v1');
    expect(draft.apiKey, ' key ');
    expect(draft.model, 'gpt-image-2');
    expect(draft.providerKind, ApiProviderKind.official);
    expect(
      draft.imageSizeCapabilityOverride,
      ImageSizeCapabilityOverride.customPixels,
    );
  });

  test('resolves and upserts API configs', () {
    const first = ApiConfig(
      id: 'first',
      name: 'First',
      baseUrl: 'https://first.test/v1',
      apiKey: 'first-key',
      model: 'gpt-image-2',
    );
    const second = ApiConfig(
      id: 'second',
      name: 'Second',
      baseUrl: 'https://second.test/v1',
      apiKey: 'second-key',
      model: 'gpt-image-2',
    );
    final updatedSecond = second.copyWith(model: 'imagen');

    expect(resolveApiConfig([first, second], 'second'), second);
    expect(resolveApiConfig([first, second], 'missing'), first);
    expect(upsertApiConfig([first, second], updatedSecond), [
      first,
      updatedSecond,
    ]);
    expect(upsertApiConfig([first], second), [first, second]);
  });

  test('creates compatible API config with safe defaults', () {
    final config = createCompatibleApiConfig(id: 'new');

    expect(config.id, 'new');
    expect(config.name, newApiConfigName);
    expect(
      config.baseUrl,
      defaultBaseUrlForProviderKind(ApiProviderKind.compatible),
    );
    expect(
      config.model,
      defaultModelForProviderKind(ApiProviderKind.compatible),
    );
    expect(config.providerKind, ApiProviderKind.compatible);
    expect(
      config.imageSizeCapabilityOverride,
      ImageSizeCapabilityOverride.auto,
    );
  });

  test('applies provider defaults only when current fields are unchanged', () {
    final defaulted = apiProviderKindDefaultedFields(
      previousKind: ApiProviderKind.compatible,
      nextKind: ApiProviderKind.gemini,
      currentBaseUrl: defaultBaseUrlForProviderKind(ApiProviderKind.compatible),
      currentModel: defaultModelForProviderKind(ApiProviderKind.compatible),
    );
    final preserved = apiProviderKindDefaultedFields(
      previousKind: ApiProviderKind.compatible,
      nextKind: ApiProviderKind.gemini,
      currentBaseUrl: 'https://proxy.example/v1',
      currentModel: 'custom-model',
    );

    expect(
      defaulted.baseUrl,
      defaultBaseUrlForProviderKind(ApiProviderKind.gemini),
    );
    expect(
      defaulted.model,
      defaultModelForProviderKind(ApiProviderKind.gemini),
    );
    expect(preserved.baseUrl, 'https://proxy.example/v1');
    expect(preserved.model, 'custom-model');
  });

  test(
    'normalizes impossible size capability overrides for provider protocol',
    () {
      final normalized = normalizeImageSizeCapabilityOverrideForProvider(
        providerKind: ApiProviderKind.gemini,
        imageSizeCapabilityOverride: ImageSizeCapabilityOverride.customPixels,
      );

      expect(normalized, ImageSizeCapabilityOverride.aspectRatio);
      expect(
        normalizeImageSizeCapabilityOverrideForProvider(
          providerKind: ApiProviderKind.compatible,
          imageSizeCapabilityOverride: ImageSizeCapabilityOverride.customPixels,
        ),
        ImageSizeCapabilityOverride.customPixels,
      );
      expect(
        normalizeImageSizeCapabilityOverrideForProvider(
          providerKind: ApiProviderKind.official,
          imageSizeCapabilityOverride: ImageSizeCapabilityOverride.aspectRatio,
        ),
        ImageSizeCapabilityOverride.fixedPresets,
      );
    },
  );

  test(
    'deletes selected API config and chooses the first remaining config',
    () {
      const first = ApiConfig(
        id: 'first',
        name: 'First',
        baseUrl: 'https://first.test/v1',
        apiKey: 'first-key',
        model: 'gpt-image-2',
      );
      const second = ApiConfig(
        id: 'second',
        name: 'Second',
        baseUrl: 'https://second.test/v1',
        apiKey: 'second-key',
        model: 'gpt-image-2',
      );

      final result = deleteApiConfigSelection([first, second], 'first');

      expect(result?.configs, [second]);
      expect(result?.selectedConfig, second);
      expect(deleteApiConfigSelection([first], 'first'), isNull);
      expect(deleteApiConfigSelection([first, second], 'missing'), isNull);
    },
  );

  test('builds stable model request key', () {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: ' https://example.com/v1 ',
      apiKey: ' key ',
      model: 'gpt-image-2',
      providerKind: ApiProviderKind.gemini,
    );

    expect(apiModelRequestKey(config), 'gemini\nhttps://example.com/v1\nkey');
  });

  test('caches fetched API models by request key', () {
    final cache = cacheApiModelsForRequest(
      cache: const {
        'first': [ApiModelInfo(id: 'first-image')],
      },
      requestKey: 'second',
      models: const [
        ApiModelInfo(id: 'second-image'),
        ApiModelInfo(id: 'second-text'),
      ],
    );

    expect(cache['first']?.single.id, 'first-image');
    expect(cache['second']?.map((model) => model.id), [
      'second-image',
      'second-text',
    ]);
  });

  test('updates model fetch errors without leaking between request keys', () {
    final withError = updateApiModelFetchErrorCache(
      cache: const {'first': 'first failed'},
      requestKey: 'second',
      errorMessage: ' second failed ',
    );
    final cleared = updateApiModelFetchErrorCache(
      cache: withError,
      requestKey: 'second',
      errorMessage: null,
    );

    expect(withError, {'first': 'first failed', 'second': 'second failed'});
    expect(cleared, {'first': 'first failed'});
  });

  test('builds basic and full API config test requests', () {
    const official = ApiConfig(
      id: 'official',
      name: 'Official',
      baseUrl: 'https://api.openai.com/v1',
      apiKey: ' key ',
      model: 'gpt-image-2',
      providerKind: ApiProviderKind.official,
      imageSizeCapabilityOverride: ImageSizeCapabilityOverride.customPixels,
    );
    const gemini = ApiConfig(
      id: 'gemini',
      name: 'Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      apiKey: ' key ',
      model: 'gemini-2.5-flash-image',
      providerKind: ApiProviderKind.gemini,
    );

    final basicRequest = buildApiConfigTestRequest(
      apiConfig: official,
      basic: true,
    );
    final fullRequest = buildApiConfigTestRequest(
      apiConfig: official,
      basic: false,
    );
    final geminiBasicRequest = buildApiConfigTestRequest(
      apiConfig: gemini,
      basic: true,
    );

    expect(basicRequest.providerKind, ApiProviderKind.compatible);
    expect(basicRequest.advancedSettings.quality, 'auto');
    expect(fullRequest.providerKind, ApiProviderKind.official);
    expect(
      fullRequest.imageSizeCapabilityOverride,
      ImageSizeCapabilityOverride.customPixels,
    );
    expect(fullRequest.advancedSettings.quality, 'low');
    expect(geminiBasicRequest.providerKind, ApiProviderKind.gemini);
    expect(basicRequest.apiKey, 'key');
  });

  test(
    'prefers image-capable fetched models when current model is default',
    () {
      const config = ApiConfig(
        id: 'config',
        name: 'Config',
        baseUrl: 'https://example.com/v1',
        apiKey: 'key',
        model: '',
        providerKind: ApiProviderKind.compatible,
      );
      const customConfig = ApiConfig(
        id: 'custom',
        name: 'Custom',
        baseUrl: 'https://example.com/v1',
        apiKey: 'key',
        model: 'custom-model',
        providerKind: ApiProviderKind.compatible,
      );

      expect(
        preferredFetchedModel(const [
          ApiModelInfo(id: 'text-model'),
          ApiModelInfo(id: 'imagen-pro'),
        ], config)?.id,
        'imagen-pro',
      );
      expect(
        preferredFetchedModel(const [
          ApiModelInfo(id: 'models/gpt-image-2'),
        ], config)?.id,
        'models/gpt-image-2',
      );
      expect(
        preferredFetchedModel(const [
          ApiModelInfo(id: 'imagen-pro'),
        ], customConfig),
        isNull,
      );
    },
  );

  test('matches fetched models by normalized model id', () {
    expect(
      matchingFetchedModel(const [
        ApiModelInfo(id: 'models/gpt-image-2'),
        ApiModelInfo(id: 'custom-model'),
      ], ' gpt-image-2 ')?.id,
      'models/gpt-image-2',
    );
    expect(
      matchingFetchedModel(const [
        ApiModelInfo(id: 'models/gpt-image-2'),
      ], 'missing-model'),
      isNull,
    );
  });

  test('decorates API test errors with provider-specific hint', () {
    final decorated = decorateApiTestErrorMessage(
      baseMessage: '502 Bad Gateway',
      providerKind: ApiProviderKind.official,
      basic: false,
    );

    expect(decorated, contains('接口测试失败'));
    expect(decorated, contains('OpenAI 官方'));
    expect(
      decorateApiTestErrorMessage(
        baseMessage: '502 Bad Gateway',
        providerKind: ApiProviderKind.official,
        basic: true,
      ),
      isNot(contains('OpenAI 官方')),
    );
  });
}
