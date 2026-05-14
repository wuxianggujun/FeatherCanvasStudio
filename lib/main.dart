import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image_lib;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FeatherCanvasApp());
}

class FeatherCanvasApp extends StatelessWidget {
  const FeatherCanvasApp({super.key});

  static const String _fontFamily = 'Microsoft YaHei UI';
  static const List<String> _fontFamilyFallback = <String>[
    'Microsoft YaHei',
    'Segoe UI',
    'Arial',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'FeatherCanvas Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const FeatherCanvasHomePage(),
    );
  }
}

class FeatherCanvasHomePage extends StatefulWidget {
  const FeatherCanvasHomePage({super.key});

  @override
  State<FeatherCanvasHomePage> createState() => _FeatherCanvasHomePageState();
}

enum _WorkspaceFeature {
  imageGeneration,
  frameAnimation,
  imageEditor,
  gifComposer,
  imageLibrary,
  apiSettings,
}

const double _workspacePadding = 12;
const double _sectionGap = 12;
const double _fieldGap = 12;
const double _layoutGap = 12;
const double _panelPadding = 14;
const List<int> _gifFrameDelayOptions = <int>[60, 80, 100, 120, 160, 200, 300];
const List<String> _gptImageQualityOptions = <String>[
  'auto',
  'low',
  'medium',
  'high',
];
const List<String> _gptImageBackgroundOptions = <String>[
  'auto',
  'transparent',
  'opaque',
];
const List<String> _gptImageOutputFormatOptions = <String>[
  'png',
  'jpeg',
  'webp',
];
const List<String> _gptImageModerationOptions = <String>['auto', 'low'];
const int _openAIImageSizeStep = 16;
const int _openAIDefaultImageSide = 1024;
const int _openAIMinImageSide = 256;
const int _openAIMaxImageSide = 4096;
const int _openAIMaxImageAspectRatio = 4;

String _imageQualityLabel(String value) {
  return switch (value) {
    'auto' => '自动',
    'low' => '低',
    'medium' => '中',
    'high' => '高',
    'standard' => '标准',
    'hd' => '高清',
    _ => value,
  };
}

String _imageBackgroundLabel(String value) {
  return switch (value) {
    'auto' => '自动',
    'transparent' => '透明',
    'opaque' => '不透明',
    _ => value,
  };
}

String _imageOutputFormatLabel(String value) {
  return switch (value) {
    'png' => 'PNG',
    'jpeg' => 'JPEG',
    'webp' => 'WebP',
    _ => value,
  };
}

String _imageModerationLabel(String value) {
  return switch (value) {
    'auto' => '自动',
    'low' => '低',
    _ => value,
  };
}

class ImageAdvancedSettings {
  const ImageAdvancedSettings({
    this.quality = 'auto',
    this.background = 'auto',
    this.outputFormat = 'png',
    this.outputCompression = 100,
    this.moderation = 'auto',
    this.user = '',
    this.inputFidelity = 'low',
  });

  factory ImageAdvancedSettings.fromJson(Map<String, dynamic> json) {
    const defaults = ImageAdvancedSettings();
    return ImageAdvancedSettings(
      quality: _readOption(
        json['quality'],
        _gptImageQualityOptions,
        defaults.quality,
      ),
      background: _readOption(
        json['background'],
        _gptImageBackgroundOptions,
        defaults.background,
      ),
      outputFormat: _readOption(
        json['outputFormat'] ?? json['output_format'],
        _gptImageOutputFormatOptions,
        defaults.outputFormat,
      ),
      outputCompression: _readCompression(
        json['outputCompression'] ?? json['output_compression'],
        defaults.outputCompression,
      ),
      moderation: _readOption(
        json['moderation'],
        _gptImageModerationOptions,
        defaults.moderation,
      ),
      user: json['user'] as String? ?? defaults.user,
      inputFidelity: _readOption(
        json['inputFidelity'] ?? json['input_fidelity'],
        const ['low', 'high'],
        defaults.inputFidelity,
      ),
    );
  }

  final String quality;
  final String background;
  final String outputFormat;
  final int outputCompression;
  final String moderation;
  final String user;
  final String inputFidelity;

  bool get supportsOutputCompression =>
      outputFormat == 'jpeg' || outputFormat == 'webp';

  ImageAdvancedSettings copyWith({
    String? quality,
    String? background,
    String? outputFormat,
    int? outputCompression,
    String? moderation,
    String? user,
    String? inputFidelity,
  }) {
    return ImageAdvancedSettings(
      quality: quality ?? this.quality,
      background: background ?? this.background,
      outputFormat: outputFormat ?? this.outputFormat,
      outputCompression: outputCompression ?? this.outputCompression,
      moderation: moderation ?? this.moderation,
      user: user ?? this.user,
      inputFidelity: inputFidelity ?? this.inputFidelity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality': quality,
      'background': background,
      'outputFormat': outputFormat,
      'outputCompression': outputCompression,
      'moderation': moderation,
      'user': user,
      'inputFidelity': inputFidelity,
    };
  }

  Map<String, dynamic> toRequestFields({
    required bool hasTemplateImage,
    ApiProviderKind providerKind = ApiProviderKind.official,
  }) {
    if (providerKind != ApiProviderKind.official) {
      // 兼容档（sub2api / 反代 / 第三方网关）和 Gemini 等非 OpenAI 协议
      // 都不能接收这些 OpenAI Images 专属字段；请求层只发送各协议安全字段。
      return const <String, dynamic>{};
    }

    final normalizedBackground =
        background == 'transparent' && outputFormat == 'jpeg'
        ? 'auto'
        : background;
    return {
      if (quality.trim().isNotEmpty) 'quality': quality,
      if (normalizedBackground.trim().isNotEmpty)
        'background': normalizedBackground,
      if (outputFormat.trim().isNotEmpty) 'output_format': outputFormat,
      if (supportsOutputCompression)
        'output_compression': outputCompression.clamp(0, 100),
      if (!hasTemplateImage && moderation.trim().isNotEmpty)
        'moderation': moderation,
      if (user.trim().isNotEmpty) 'user': user.trim(),
      if (hasTemplateImage && inputFidelity.trim().isNotEmpty)
        'input_fidelity': inputFidelity,
    };
  }

  Map<String, String> toMultipartFields({
    required bool hasTemplateImage,
    ApiProviderKind providerKind = ApiProviderKind.official,
  }) {
    return toRequestFields(
      hasTemplateImage: hasTemplateImage,
      providerKind: providerKind,
    ).map((key, value) => MapEntry(key, value.toString()));
  }

  static String _readOption(
    Object? value,
    List<String> allowedValues,
    String fallback,
  ) {
    if (value is! String) {
      return fallback;
    }

    final normalized = value.trim();
    return allowedValues.contains(normalized) ? normalized : fallback;
  }

  static int _readCompression(Object? value, int fallback) {
    final number = value is num ? value.toInt() : int.tryParse('$value');
    return number == null ? fallback : number.clamp(0, 100);
  }
}

enum GifPlaybackMode { normal, reverse, pingPong }

enum SpriteSheetFrameFit { contain, cover, stretch }

enum ImageAssetKind {
  generatedImage,
  spriteSheet,
  spriteFrame,
  editedImage,
  gif,
}

enum _ImagePickSource { localFile, imageLibrary }

enum _ImageLibraryKindFilter { all, generated, sprite, edited, gif }

enum _ImageLibrarySortOrder { newest, oldest, titleAscending }

enum _ImageLibraryTileMenuAction {
  useInEditor,
  reuseGeneration,
  copyGeneration,
  copyPath,
  openLocation,
  delete,
}

enum _ApiConfigSaveStatus { saved, pending, saving, failed }

/// 标识接口提供方与它对应的请求协议。
///
/// - [official] 直连 OpenAI 官方 GPT Image 接口，可发送全部高级参数
///   （`quality` / `background` / `output_format` / `output_compression` /
///   `moderation` / `input_fidelity` / `user`）。
/// - [compatible] 走 sub2api、各类 OpenAI 兼容反代或第三方网关，这些后端常常
///   只透传基础字段，遇到 GPT Image 专属参数会返回 5xx。请求层在该模式下只
///   发送 `model` / `prompt` / `size` / `n`。
/// - [gemini] 走 Google Gemini 原生 `generateContent` 协议，从响应的
///   `inlineData` 中读取图片。
enum ApiProviderKind { official, compatible, gemini }

String _apiProviderKindLabel(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official => 'OpenAI 官方',
    ApiProviderKind.compatible => 'OpenAI 兼容',
    ApiProviderKind.gemini => 'Gemini',
  };
}

IconData _apiProviderKindIcon(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official => Icons.verified_outlined,
    ApiProviderKind.compatible => Icons.swap_horiz,
    ApiProviderKind.gemini => Icons.auto_awesome_outlined,
  };
}

String _apiProviderKindDescription(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official =>
      '发送完整 GPT Image 参数（quality/background/output_format 等）',
    ApiProviderKind.compatible => '只发送 model/prompt/size/n，避免兼容层 502',
    ApiProviderKind.gemini => '使用 Gemini generateContent 协议，支持文本生图和带参考图编辑',
  };
}

String _serializeApiProviderKind(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official => 'official',
    ApiProviderKind.compatible => 'compatible',
    ApiProviderKind.gemini => 'gemini',
  };
}

ApiProviderKind _parseApiProviderKind(
  Object? value, {
  required ApiProviderKind fallback,
}) {
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'official':
        return ApiProviderKind.official;
      case 'compatible':
        return ApiProviderKind.compatible;
      case 'gemini':
        return ApiProviderKind.gemini;
    }
  }
  return fallback;
}

String _defaultBaseUrlForProviderKind(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official => 'https://api.openai.com/v1',
    ApiProviderKind.compatible => 'https://api.openai.com/v1',
    ApiProviderKind.gemini =>
      'https://generativelanguage.googleapis.com/v1beta',
  };
}

String _defaultModelForProviderKind(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official => 'gpt-image-2',
    ApiProviderKind.compatible => 'gpt-image-2',
    ApiProviderKind.gemini => 'gemini-2.5-flash-image',
  };
}

String _apiKeyHintForProviderKind(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.gemini => 'Google AI Studio API Key',
    _ => 'sk-...',
  };
}

String _imageAssetKindLabel(ImageAssetKind kind) {
  return switch (kind) {
    ImageAssetKind.generatedImage => '生图',
    ImageAssetKind.spriteSheet => '切片图',
    ImageAssetKind.spriteFrame => '帧图',
    ImageAssetKind.editedImage => '编辑图',
    ImageAssetKind.gif => 'GIF',
  };
}

String _imageLibraryKindFilterLabel(_ImageLibraryKindFilter filter) {
  return switch (filter) {
    _ImageLibraryKindFilter.all => '全部',
    _ImageLibraryKindFilter.generated => '生图',
    _ImageLibraryKindFilter.sprite => '切片 / 帧',
    _ImageLibraryKindFilter.edited => '编辑图',
    _ImageLibraryKindFilter.gif => 'GIF',
  };
}

bool _imageLibraryKindFilterMatches(
  _ImageLibraryKindFilter filter,
  ImageAssetKind kind,
) {
  return switch (filter) {
    _ImageLibraryKindFilter.all => true,
    _ImageLibraryKindFilter.generated => kind == ImageAssetKind.generatedImage,
    _ImageLibraryKindFilter.sprite =>
      kind == ImageAssetKind.spriteSheet || kind == ImageAssetKind.spriteFrame,
    _ImageLibraryKindFilter.edited => kind == ImageAssetKind.editedImage,
    _ImageLibraryKindFilter.gif => kind == ImageAssetKind.gif,
  };
}

String _imageLibrarySortOrderLabel(_ImageLibrarySortOrder sortOrder) {
  return switch (sortOrder) {
    _ImageLibrarySortOrder.newest => '最新优先',
    _ImageLibrarySortOrder.oldest => '最旧优先',
    _ImageLibrarySortOrder.titleAscending => '标题 A-Z',
  };
}

bool _imageLibraryItemMatchesSearch(ImageLibraryItem item, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return true;
  }

  final searchableText = [
    item.displayTitle,
    item.source,
    item.note,
    item.prompt ?? '',
    item.generation?.prompt ?? '',
    item.generation?.negativePrompt ?? '',
    item.generation?.model ?? '',
    item.generation?.size ?? '',
    item.generation == null
        ? ''
        : _apiProviderKindLabel(item.generation!.providerKind),
    _imageAssetKindLabel(item.kind),
    _fileNameFromPath(item.path),
  ].join(' ').toLowerCase();

  return normalizedQuery
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .every(searchableText.contains);
}

int _compareImageLibraryItems(
  ImageLibraryItem a,
  ImageLibraryItem b,
  _ImageLibrarySortOrder sortOrder,
) {
  return switch (sortOrder) {
    _ImageLibrarySortOrder.newest => b.createdAt.compareTo(a.createdAt),
    _ImageLibrarySortOrder.oldest => a.createdAt.compareTo(b.createdAt),
    _ImageLibrarySortOrder.titleAscending =>
      a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()),
  };
}

const List<XTypeGroup> _imageTypeGroups = <XTypeGroup>[
  XTypeGroup(
    label: 'Images',
    extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
  ),
];

const List<XTypeGroup> _templateImageTypeGroups = <XTypeGroup>[
  XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp']),
];

const List<ImageAssetKind> _spriteSheetLibraryKinds = <ImageAssetKind>[
  ImageAssetKind.spriteSheet,
  ImageAssetKind.editedImage,
];

const List<ImageAssetKind> _singleFrameLibraryKinds = <ImageAssetKind>[
  ImageAssetKind.generatedImage,
  ImageAssetKind.spriteFrame,
];

const List<ImageAssetKind> _templateLibraryKinds = <ImageAssetKind>[
  ImageAssetKind.generatedImage,
  ImageAssetKind.spriteSheet,
  ImageAssetKind.spriteFrame,
  ImageAssetKind.editedImage,
];

const List<ImageAssetKind> _gifSourceLibraryKinds = <ImageAssetKind>[
  ImageAssetKind.generatedImage,
  ImageAssetKind.spriteSheet,
  ImageAssetKind.spriteFrame,
];

class GifSourceFrame {
  const GifSourceFrame({
    required this.id,
    required this.path,
    required this.delayMs,
    this.inlineBytes,
    this.label,
  });

  factory GifSourceFrame.fromPath(
    String path, {
    required int delayMs,
    required int seed,
    String? label,
  }) {
    return GifSourceFrame(
      id: '${DateTime.now().microsecondsSinceEpoch}_$seed',
      path: path,
      delayMs: delayMs,
      label: label,
    );
  }

  factory GifSourceFrame.fromBytes(
    Uint8List bytes, {
    required String sourcePath,
    required int delayMs,
    required int seed,
    String? label,
  }) {
    return GifSourceFrame(
      id: '${DateTime.now().microsecondsSinceEpoch}_$seed',
      path: sourcePath,
      delayMs: delayMs,
      inlineBytes: bytes,
      label: label,
    );
  }

  final String id;
  final String path;
  final int delayMs;
  final Uint8List? inlineBytes;
  final String? label;

  GifSourceFrame copyWith({
    String? id,
    String? path,
    int? delayMs,
    Uint8List? inlineBytes,
    String? label,
  }) {
    return GifSourceFrame(
      id: id ?? this.id,
      path: path ?? this.path,
      delayMs: delayMs ?? this.delayMs,
      inlineBytes: inlineBytes ?? this.inlineBytes,
      label: label ?? this.label,
    );
  }
}

class _FeatherCanvasHomePageState extends State<FeatherCanvasHomePage> {
  static const AppSettings _defaultSettings = AppSettings(
    baseUrl: 'https://api.openai.com/v1',
    apiKey: '',
    model: 'gpt-image-2',
    prompt:
        'A clean product render of a futuristic camera on a neutral background',
    negativePrompt: '',
    size: '1024x1024',
    imageCount: 1,
  );
  static const String _defaultAnimationPrompt =
      'A small paper boat crossing a glowing city canal at night, cinematic pixel art, 16-bit, high contrast, clean outline, camera slowly pushes forward, water ripples';

  final TextEditingController _baseUrlController = TextEditingController(
    text: _defaultSettings.baseUrl,
  );
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController(
    text: _defaultSettings.model,
  );
  final TextEditingController _apiConfigNameController = TextEditingController(
    text: '默认配置',
  );
  final TextEditingController _promptController = TextEditingController(
    text: _defaultSettings.prompt,
  );
  final TextEditingController _negativePromptController =
      TextEditingController();
  final TextEditingController _animationPromptController =
      TextEditingController(text: _defaultAnimationPrompt);
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _imageLibrarySearchController =
      TextEditingController();

  final OpenAICompatibleImageClient _client = OpenAICompatibleImageClient();
  final AppLocalStore _store = AppLocalStore();
  final ScrollController _scrollController = ScrollController();

  _WorkspaceFeature _selectedFeature = _WorkspaceFeature.imageGeneration;
  String _size = _defaultSettings.size;
  int _imageCount = _defaultSettings.imageCount;
  ImageAdvancedSettings _advancedSettings = _defaultSettings.advancedSettings;
  int _animationRows = 4;
  int _animationColumns = 4;
  int _editorRows = 4;
  int _editorColumns = 4;
  int _editorTargetFrameIndex = 0;
  SpriteSheetFrameFit _editorFrameFit = SpriteSheetFrameFit.contain;
  bool _isGenerating = false;
  bool _isGeneratingAnimation = false;
  bool _isComposingGif = false;
  bool _isReplacingEditorFrame = false;
  bool _isTestingApiConfig = false;
  bool _showApiKey = false;
  bool _isBootstrapping = true;
  bool _isRestoringState = false;
  String? _errorMessage;
  String? _animationErrorMessage;
  ImageRequestDebugRecord? _imageRequestDebugRecord;
  ImageRequestDebugRecord? _animationRequestDebugRecord;
  List<ApiConfig> _apiConfigs = const [];
  String? _selectedApiConfigId;
  ApiProviderKind _apiConfigProviderKind = ApiProviderKind.compatible;
  List<GeneratedImage> _generatedImages = const [];
  List<GeneratedImage> _animationFrames = const [];
  List<ImageLibraryItem> _imageLibrary = const [];
  _ImageLibraryKindFilter _imageLibraryKindFilter = _ImageLibraryKindFilter.all;
  _ImageLibrarySortOrder _imageLibrarySortOrder = _ImageLibrarySortOrder.newest;
  String _imageLibrarySearchQuery = '';
  Set<String> _selectedImageLibraryItemIds = <String>{};
  bool _showStandaloneSpriteFrames = false;
  final Set<String> _ephemeralTemplatePaths = <String>{};
  String? _animationTemplateImagePath;
  String? _editorImagePath;
  String? _editorPatchImagePath;
  String? _editorErrorMessage;
  List<GifSourceFrame> _gifSourceFrames = const [];
  String? _gifOutputPath;
  String? _gifErrorMessage;
  int _gifDefaultFrameDelayMs = 120;
  int _gifLoopCount = 0;
  GifPlaybackMode _gifPlaybackMode = GifPlaybackMode.normal;
  _ApiConfigSaveStatus _apiConfigSaveStatus = _ApiConfigSaveStatus.saved;
  String? _apiConfigSaveErrorMessage;
  ImageRequestDebugRecord? _apiTestDebugRecord;
  int _apiConfigSaveVersion = 0;
  Timer? _settingsSaveDebounce;
  Timer? _apiConfigSaveDebounce;

  int get _animationFrameCount => _animationRows * _animationColumns;
  int get _editorFrameCount => _editorRows * _editorColumns;

  ApiConfig get _selectedApiConfig {
    final selectedId = _selectedApiConfigId;
    for (final config in _apiConfigs) {
      if (config.id == selectedId) {
        return config;
      }
    }

    return _apiConfigs.isEmpty ? ApiConfig.defaults() : _apiConfigs.first;
  }

  @override
  void initState() {
    super.initState();

    _apiConfigNameController.addListener(_markApiConfigDirty);
    _baseUrlController.addListener(_markApiConfigDirty);
    _apiKeyController.addListener(_markApiConfigDirty);
    _modelController.addListener(_markApiConfigDirty);
    _promptController.addListener(_scheduleSettingsSave);
    _negativePromptController.addListener(_scheduleSettingsSave);
    _userController.addListener(_syncUserAndScheduleSettingsSave);

    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _settingsSaveDebounce?.cancel();
    _apiConfigSaveDebounce?.cancel();
    _client.close();
    _scrollController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _apiConfigNameController.dispose();
    _promptController.dispose();
    _negativePromptController.dispose();
    _userController.dispose();
    _imageLibrarySearchController.dispose();
    _animationPromptController.dispose();
    for (final path in _ephemeralTemplatePaths) {
      unawaited(_safeDeleteFile(path));
    }
    _ephemeralTemplatePaths.clear();
    super.dispose();
  }

  Future<void> _safeDeleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 临时文件清理失败可忽略：操作系统会回收。
    }
  }

  Future<void> _bootstrap() async {
    final settings = await _store.loadSettings();
    final storedApiConfigs = await _store.loadApiConfigs();
    final storedSelectedApiConfigId = await _store.loadSelectedApiConfigId();
    final imageLibrary = await _store.loadImageLibrary();

    if (!mounted) {
      return;
    }

    final apiConfigs = storedApiConfigs.isEmpty
        ? [ApiConfig.defaults()]
        : storedApiConfigs;
    final selectedApiConfig = _resolveApiConfig(
      apiConfigs,
      storedSelectedApiConfigId,
    );

    _isRestoringState = true;
    _apiConfigNameController.text = selectedApiConfig.name;
    _baseUrlController.text = selectedApiConfig.baseUrl;
    _apiKeyController.text = selectedApiConfig.apiKey;
    _modelController.text = selectedApiConfig.model;
    _promptController.text = settings.prompt;
    _negativePromptController.text = settings.negativePrompt;
    _userController.text = settings.advancedSettings.user;

    setState(() {
      _apiConfigs = apiConfigs;
      _selectedApiConfigId = selectedApiConfig.id;
      _apiConfigProviderKind = selectedApiConfig.providerKind;
      _size = _imageDimensionsFromSize(settings.size).size;
      _imageCount = settings.imageCount;
      _advancedSettings = settings.advancedSettings;
      _imageLibrary = imageLibrary;
      _isBootstrapping = false;
    });
    _isRestoringState = false;
    await _store.saveApiConfigs(apiConfigs);
    await _store.saveSelectedApiConfigId(selectedApiConfig.id);
  }

  ApiConfig _resolveApiConfig(List<ApiConfig> configs, String? selectedId) {
    for (final config in configs) {
      if (config.id == selectedId) {
        return config;
      }
    }

    return configs.isEmpty ? ApiConfig.defaults() : configs.first;
  }

  Future<void> _selectFeature(_WorkspaceFeature feature) async {
    if (_selectedFeature == feature) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _selectedFeature = feature);
  }

  Future<ApiConfig> _prepareSelectedApiConfigForRequest() async {
    _apiConfigSaveDebounce?.cancel();
    return _selectedApiConfig;
  }

  void _scheduleSettingsSave() {
    if (_isBootstrapping || _isRestoringState) {
      return;
    }

    _settingsSaveDebounce?.cancel();
    _settingsSaveDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_saveSettings());
    });
  }

  void _syncUserAndScheduleSettingsSave() {
    _advancedSettings = _advancedSettings.copyWith(
      user: _userController.text.trim(),
    );
    _scheduleSettingsSave();
  }

  void _markApiConfigDirty() {
    if (_isBootstrapping || _isRestoringState) {
      return;
    }

    _apiConfigSaveDebounce?.cancel();
    ++_apiConfigSaveVersion;
    setState(() {
      _apiConfigSaveStatus = _ApiConfigSaveStatus.pending;
      _apiConfigSaveErrorMessage = null;
    });
  }

  Future<void> _saveSettings() async {
    final apiConfig = _selectedApiConfig;
    final normalizedSize = _imageDimensionsFromSize(_size).size;
    await _store.saveSettings(
      AppSettings(
        baseUrl: apiConfig.baseUrl,
        apiKey: apiConfig.apiKey,
        model: apiConfig.model,
        prompt: _promptController.text,
        negativePrompt: _negativePromptController.text,
        size: normalizedSize,
        imageCount: _imageCount,
        advancedSettings: _advancedSettings.copyWith(
          user: _userController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _saveCurrentApiConfig({int? saveVersion}) async {
    final activeSaveVersion = saveVersion ?? _apiConfigSaveVersion;
    if (mounted) {
      setState(() {
        _apiConfigSaveStatus = _ApiConfigSaveStatus.saving;
        _apiConfigSaveErrorMessage = null;
      });
    }

    final selectedId = _selectedApiConfigId ?? ApiConfig.newId();
    final nextConfig = ApiConfig(
      id: selectedId,
      name: _apiConfigNameController.text.trim().isEmpty
          ? '未命名配置'
          : _apiConfigNameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text,
      model: _modelController.text.trim(),
      providerKind: _apiConfigProviderKind,
    );

    final nextConfigs = [
      for (final config in _apiConfigs)
        if (config.id == selectedId) nextConfig else config,
      if (!_apiConfigs.any((config) => config.id == selectedId)) nextConfig,
    ];

    if (mounted) {
      setState(() {
        _apiConfigs = nextConfigs;
        _selectedApiConfigId = selectedId;
      });
    } else {
      _apiConfigs = nextConfigs;
      _selectedApiConfigId = selectedId;
    }

    try {
      await _store.saveApiConfigs(nextConfigs);
      await _store.saveSelectedApiConfigId(selectedId);
      await _saveSettings();
      if (mounted && activeSaveVersion == _apiConfigSaveVersion) {
        setState(() {
          _apiConfigSaveStatus = _ApiConfigSaveStatus.saved;
          _apiConfigSaveErrorMessage = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _apiConfigSaveStatus = _ApiConfigSaveStatus.failed;
          _apiConfigSaveErrorMessage = error.toString();
        });
      }
    }
  }

  void _saveSelectedApiConfig() {
    _apiConfigSaveDebounce?.cancel();
    final saveVersion = ++_apiConfigSaveVersion;
    unawaited(_saveCurrentApiConfig(saveVersion: saveVersion));
  }

  Future<void> _testCurrentApiConfig({bool basic = false}) async {
    final apiConfig = ApiConfig(
      id: _selectedApiConfigId ?? ApiConfig.newId(),
      name: _apiConfigNameController.text.trim().isEmpty
          ? '未命名配置'
          : _apiConfigNameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text,
      model: _modelController.text.trim(),
      providerKind: _apiConfigProviderKind,
    );

    if (apiConfig.apiKey.trim().isEmpty) {
      _showMessage('请先填写 API Key。');
      return;
    }

    setState(() {
      _isTestingApiConfig = true;
      _apiTestDebugRecord = null;
    });

    // 基础测试：OpenAI 协议强制使用 compatible 档位 + 默认 advanced settings，
    // 仅发送 model/prompt/size/n，用来排查 baseUrl/key/model 本身是否可用。
    // Gemini 没有 OpenAI 兼容最小 payload，基础测试仍使用 Gemini 原生协议。
    // 完整测试：保留 providerKind 与一组保守的高级参数，验证当前档位是否
    // 与后端兼容。
    final providerKind =
        basic && apiConfig.providerKind != ApiProviderKind.gemini
        ? ApiProviderKind.compatible
        : apiConfig.providerKind;
    final advancedSettings = basic
        ? const ImageAdvancedSettings()
        : const ImageAdvancedSettings(
            quality: 'low',
            background: 'auto',
            outputFormat: 'png',
            moderation: 'low',
          );

    try {
      await _client.generate(
        OpenAIImageRequest(
          baseUrl: apiConfig.baseUrl,
          apiKey: apiConfig.apiKey.trim(),
          model: apiConfig.model,
          prompt: 'API connection test. Generate a tiny neutral test image.',
          negativePrompt: '',
          size: '1024x1024',
          imageCount: 1,
          providerKind: providerKind,
          advancedSettings: advancedSettings,
        ),
        onDebugRecord: (record) => _apiTestDebugRecord = record,
      );

      if (!mounted) {
        return;
      }
      _showMessage(basic ? '基础测试通过：接口可用，可尝试切换到完整测试验证高级参数。' : '接口测试成功，已收到图片数据。');
    } on ImageGenerationException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(
        _decorateTestErrorMessage(
          baseMessage: error.message,
          providerKind: providerKind,
          basic: basic,
        ),
      );
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      _showMessage('接口测试超时，请检查反代或网络。');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('接口测试失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isTestingApiConfig = false);
      }
    }
  }

  String _decorateTestErrorMessage({
    required String baseMessage,
    required ApiProviderKind providerKind,
    required bool basic,
  }) {
    final prefix = basic ? '基础测试失败' : '接口测试失败';
    // 若已经是最小 payload 还报错，几乎可以确定是 baseUrl / key / model 错了；
    // 完整测试在 official 档位下报错且像 5xx，提示可切到兼容档再试。
    if (!basic &&
        providerKind == ApiProviderKind.official &&
        _looksLikeUpstreamError(baseMessage)) {
      return '$prefix：$baseMessage\n'
          '提示：当前为「OpenAI 官方」档位，反代/兼容层可能不支持 input_fidelity、'
          'output_compression、moderation 等参数，可切换到「OpenAI 兼容」档位再试。';
    }
    return '$prefix：$baseMessage';
  }

  bool _looksLikeUpstreamError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('502') ||
        normalized.contains('503') ||
        normalized.contains('504') ||
        normalized.contains('bad gateway') ||
        normalized.contains('gateway timeout');
  }

  Future<void> _selectApiConfig(String id) async {
    _apiConfigSaveDebounce?.cancel();
    final nextConfig = _resolveApiConfig(_apiConfigs, id);
    _isRestoringState = true;
    _apiConfigNameController.text = nextConfig.name;
    _baseUrlController.text = nextConfig.baseUrl;
    _apiKeyController.text = nextConfig.apiKey;
    _modelController.text = nextConfig.model;
    if (mounted) {
      setState(() {
        _selectedApiConfigId = nextConfig.id;
        _apiConfigProviderKind = nextConfig.providerKind;
        _apiConfigSaveStatus = _ApiConfigSaveStatus.saved;
        _apiConfigSaveErrorMessage = null;
      });
    } else {
      _selectedApiConfigId = nextConfig.id;
      _apiConfigProviderKind = nextConfig.providerKind;
    }
    _isRestoringState = false;

    await _store.saveSelectedApiConfigId(nextConfig.id);
    await _saveSettings();
  }

  Future<void> _addApiConfig() async {
    _apiConfigSaveDebounce?.cancel();

    final nextConfig = ApiConfig(
      id: ApiConfig.newId(),
      name: '新接口配置',
      baseUrl: _defaultBaseUrlForProviderKind(ApiProviderKind.compatible),
      apiKey: '',
      model: _defaultModelForProviderKind(ApiProviderKind.compatible),
      // 新建接口默认走兼容档位，避免新手粘贴反代地址后被高级参数打到 502。
      providerKind: ApiProviderKind.compatible,
    );
    final nextConfigs = [..._apiConfigs, nextConfig];
    setState(() => _apiConfigs = nextConfigs);
    await _store.saveApiConfigs(nextConfigs);
    await _selectApiConfig(nextConfig.id);
  }

  void _setApiConfigProviderKind(ApiProviderKind kind) {
    if (kind == _apiConfigProviderKind) {
      return;
    }
    final previousKind = _apiConfigProviderKind;
    final previousDefaultBaseUrl = _defaultBaseUrlForProviderKind(previousKind);
    final previousDefaultModel = _defaultModelForProviderKind(previousKind);
    final shouldApplyBaseUrlDefault =
        _baseUrlController.text.trim().isEmpty ||
        _baseUrlController.text.trim() == previousDefaultBaseUrl;
    final shouldApplyModelDefault =
        _modelController.text.trim().isEmpty ||
        _modelController.text.trim() == previousDefaultModel;

    _isRestoringState = true;
    if (shouldApplyBaseUrlDefault) {
      _baseUrlController.text = _defaultBaseUrlForProviderKind(kind);
    }
    if (shouldApplyModelDefault) {
      _modelController.text = _defaultModelForProviderKind(kind);
    }
    _isRestoringState = false;
    setState(() => _apiConfigProviderKind = kind);
    _markApiConfigDirty();
  }

  Future<void> _deleteSelectedApiConfig() async {
    if (_apiConfigs.length <= 1) {
      _showMessage('至少需要保留一个接口配置。');
      return;
    }

    final selectedId = _selectedApiConfigId;
    final nextConfigs = _apiConfigs
        .where((config) => config.id != selectedId)
        .toList();
    final nextSelected = nextConfigs.first;

    setState(() => _apiConfigs = nextConfigs);
    await _store.saveApiConfigs(nextConfigs);
    await _selectApiConfig(nextSelected.id);
  }

  void _setSize(String value) {
    setState(() => _size = value.trim());
    _scheduleSettingsSave();
  }

  void _setImageCount(int value) {
    setState(() => _imageCount = value);
    _scheduleSettingsSave();
  }

  void _setAdvancedSettings(ImageAdvancedSettings value) {
    setState(() => _advancedSettings = value);
    if (_userController.text != value.user) {
      _userController.text = value.user;
    }
    _scheduleSettingsSave();
  }

  void _setAnimationRows(int value) {
    setState(() => _animationRows = value);
  }

  void _setAnimationColumns(int value) {
    setState(() => _animationColumns = value);
  }

  void _setEditorRows(int value) {
    setState(() {
      _editorRows = value;
      _normalizeEditorTargetFrameIndex();
    });
  }

  void _setEditorColumns(int value) {
    setState(() {
      _editorColumns = value;
      _normalizeEditorTargetFrameIndex();
    });
  }

  void _setEditorTargetFrameIndex(int value) {
    setState(() {
      _editorTargetFrameIndex = value.clamp(0, _editorFrameCount - 1);
    });
  }

  void _setEditorFrameFit(SpriteSheetFrameFit value) {
    setState(() => _editorFrameFit = value);
  }

  void _normalizeEditorTargetFrameIndex() {
    _editorTargetFrameIndex = _editorTargetFrameIndex.clamp(
      0,
      _editorFrameCount - 1,
    );
  }

  Future<String?> _pickSingleImagePathFromSource({
    required String title,
    List<XTypeGroup> acceptedTypeGroups = _imageTypeGroups,
    String? libraryEmptyMessage,
    List<ImageAssetKind>? allowedLibraryKinds,
  }) async {
    final availableLibraryItems = _availableImageLibraryItems(
      allowedKinds: allowedLibraryKinds,
    );
    final source = await _selectImagePickSource(
      title: title,
      allowLibrary: availableLibraryItems.isNotEmpty,
      libraryEmptyMessage: libraryEmptyMessage,
    );
    if (source == null) {
      return null;
    }

    if (source == _ImagePickSource.localFile) {
      final image = await openFile(acceptedTypeGroups: acceptedTypeGroups);
      return image?.path;
    }

    final item = await _showImageLibraryPicker<ImageLibraryItem>(
      title: title,
      allowedKinds: allowedLibraryKinds,
    );
    return item?.path;
  }

  Future<_ImagePickSource?> _selectImagePickSource({
    required String title,
    required bool allowLibrary,
    String? libraryEmptyMessage,
  }) async {
    if (!mounted) {
      return null;
    }

    return showDialog<_ImagePickSource>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DesktopPickSourceTile(
                  icon: Icons.folder_open_outlined,
                  title: '从本地文件选择',
                  subtitle: '打开电脑文件选择窗口',
                  onTap: () =>
                      Navigator.of(context).pop(_ImagePickSource.localFile),
                ),
                const SizedBox(height: 8),
                _DesktopPickSourceTile(
                  icon: Icons.collections_bookmark_outlined,
                  title: '从作品库选择',
                  subtitle: allowLibrary
                      ? '直接使用已保存到作品库的图片'
                      : libraryEmptyMessage ?? '作品库还没有可用图片',
                  onTap: () =>
                      Navigator.of(context).pop(_ImagePickSource.imageLibrary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Future<T?> _showImageLibraryPicker<T extends Object>({
    required String title,
    bool allowMultiple = false,
    List<ImageAssetKind>? allowedKinds,
  }) async {
    if (!mounted) {
      return null;
    }

    final candidates = _availableImageLibraryItems(allowedKinds: allowedKinds);
    if (candidates.isEmpty) {
      _showMessage('作品库还没有可用图片。');
      return null;
    }

    final result = await showDialog<Object>(
      context: context,
      builder: (context) {
        return _ImageLibraryPickerDialog(
          title: title,
          items: candidates,
          allowMultiple: allowMultiple,
        );
      },
    );

    return result is T ? result : null;
  }

  List<ImageLibraryItem> _availableImageLibraryItems({
    List<ImageAssetKind>? allowedKinds,
  }) {
    return [
      for (final item in _imageLibrary)
        if (item.existsSync &&
            item.isImageFile &&
            (allowedKinds == null || allowedKinds.contains(item.kind)))
          item,
    ];
  }

  Future<void> _pickEditorImage() async {
    final imagePath = await _pickSingleImagePathFromSource(
      title: '选择 Sprite Sheet 图片',
      libraryEmptyMessage: '生成或导出 Sprite Sheet 后可从这里复用',
      allowedLibraryKinds: _spriteSheetLibraryKinds,
    );

    if (imagePath == null || !mounted) {
      return;
    }

    setState(() {
      _editorImagePath = imagePath;
      _editorErrorMessage = null;
    });
    _showMessage('已载入图片：${_fileNameFromPath(imagePath)}');
  }

  void _clearEditorImage() {
    setState(() {
      _editorImagePath = null;
      _editorErrorMessage = null;
    });
  }

  Future<void> _pickEditorPatchImage() async {
    final imagePath = await _pickSingleImagePathFromSource(
      title: '选择单帧图片',
      libraryEmptyMessage: '保存到作品库后的单帧图片会显示在这里',
      allowedLibraryKinds: _singleFrameLibraryKinds,
    );

    if (imagePath == null || !mounted) {
      return;
    }

    setState(() {
      _editorPatchImagePath = imagePath;
      _editorErrorMessage = null;
    });
    _showMessage('已选择单帧图片：${_fileNameFromPath(imagePath)}');
  }

  void _clearEditorPatchImage() {
    setState(() {
      _editorPatchImagePath = null;
      _editorErrorMessage = null;
    });
  }

  Future<void> _pickAnimationTemplateImage() async {
    final candidates = _availableImageLibraryItems(
      allowedKinds: _templateLibraryKinds,
    );
    final source = await _selectImagePickSource(
      title: '选择模板图片',
      allowLibrary: candidates.isNotEmpty,
      libraryEmptyMessage: '保存到作品库后的图片会显示在这里',
    );
    if (source == null || !mounted) {
      return;
    }

    String? imagePath;
    String? sliceLabel;
    if (source == _ImagePickSource.localFile) {
      final image = await openFile(
        acceptedTypeGroups: _templateImageTypeGroups,
      );
      imagePath = image?.path;
    } else {
      final item = await _showImageLibraryPicker<ImageLibraryItem>(
        title: '选择模板图片',
        allowedKinds: _templateLibraryKinds,
      );
      if (item == null || !mounted) {
        return;
      }
      if (item.isSpriteSheetWithMetadata) {
        final picked = await _showSlicePicker(item, allowMultiple: false);
        if (picked == null || picked.isEmpty || !mounted) {
          return;
        }
        final entry = picked.first;
        final file = await _store.saveEphemeralBytes(
          prefix: 'template',
          bytes: entry.value,
        );
        _ephemeralTemplatePaths.add(file.path);
        imagePath = file.path;
        sliceLabel = '${item.displayTitle} · 帧 ${entry.key + 1}';
      } else {
        imagePath = item.path;
      }
    }

    if (imagePath == null || !mounted) {
      return;
    }

    final previous = _animationTemplateImagePath;
    setState(() {
      _animationTemplateImagePath = imagePath;
      _animationErrorMessage = null;
    });
    if (previous != null &&
        previous != imagePath &&
        _ephemeralTemplatePaths.remove(previous)) {
      unawaited(_safeDeleteFile(previous));
    }
    _showMessage(
      sliceLabel != null
          ? '已选择模板切片：$sliceLabel'
          : '已选择模板图片：${_fileNameFromPath(imagePath)}',
    );
  }

  void _clearAnimationTemplateImage() {
    final previous = _animationTemplateImagePath;
    setState(() => _animationTemplateImagePath = null);
    if (previous != null && _ephemeralTemplatePaths.remove(previous)) {
      unawaited(_safeDeleteFile(previous));
    }
  }

  Future<List<MapEntry<int, Uint8List>>?> _showSlicePicker(
    ImageLibraryItem sheet, {
    required bool allowMultiple,
    String? title,
  }) async {
    if (!sheet.isSpriteSheetWithMetadata) {
      _showMessage('该 Sprite Sheet 缺少行列元数据，无法切片。');
      return null;
    }
    return showDialog<List<MapEntry<int, Uint8List>>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _SpriteSheetSlicePickerDialog(
          sheet: sheet,
          allowMultiple: allowMultiple,
          title: title,
        );
      },
    );
  }

  Future<void> _pickGifSourceImages() async {
    final candidates = _availableImageLibraryItems(
      allowedKinds: _gifSourceLibraryKinds,
    );
    final source = await _selectImagePickSource(
      title: '选择 GIF 图片序列',
      allowLibrary: candidates.isNotEmpty,
      libraryEmptyMessage: '保存到作品库后的图片会显示在这里',
    );
    if (source == null || !mounted) {
      return;
    }

    final newFrames = <GifSourceFrame>[];
    var seed = 0;

    if (source == _ImagePickSource.localFile) {
      final images = await openFiles(acceptedTypeGroups: _imageTypeGroups);
      for (final image in images) {
        newFrames.add(
          GifSourceFrame.fromPath(
            image.path,
            delayMs: _gifDefaultFrameDelayMs,
            seed: seed++,
          ),
        );
      }
    } else {
      final items = await _showImageLibraryPicker<List<ImageLibraryItem>>(
        title: '选择 GIF 图片序列',
        allowMultiple: true,
        allowedKinds: _gifSourceLibraryKinds,
      );
      if (items == null || items.isEmpty || !mounted) {
        return;
      }
      for (final item in items) {
        if (item.isSpriteSheetWithMetadata) {
          final picked = await _showSlicePicker(item, allowMultiple: true);
          if (picked == null || !mounted) {
            continue;
          }
          for (final entry in picked) {
            newFrames.add(
              GifSourceFrame.fromBytes(
                entry.value,
                sourcePath: item.path,
                delayMs: _gifDefaultFrameDelayMs,
                seed: seed++,
                label: '${item.displayTitle} · 帧 ${entry.key + 1}',
              ),
            );
          }
        } else {
          newFrames.add(
            GifSourceFrame.fromPath(
              item.path,
              delayMs: _gifDefaultFrameDelayMs,
              seed: seed++,
            ),
          );
        }
      }
    }

    if (newFrames.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _gifSourceFrames = newFrames;
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  void _clearGifSourceImages() {
    setState(() {
      _gifSourceFrames = const [];
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  void _setGifDefaultFrameDelay(int value) {
    setState(() => _gifDefaultFrameDelayMs = value);
  }

  void _applyGifFrameDelayToAll() {
    if (_gifSourceFrames.isEmpty) {
      return;
    }

    setState(() {
      _gifSourceFrames = [
        for (final frame in _gifSourceFrames)
          frame.copyWith(delayMs: _gifDefaultFrameDelayMs),
      ];
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  void _setGifSourceFrameDelay(int index, int delayMs) {
    if (index < 0 || index >= _gifSourceFrames.length) {
      return;
    }

    final nextFrames = [..._gifSourceFrames];
    nextFrames[index] = nextFrames[index].copyWith(delayMs: delayMs);
    setState(() {
      _gifSourceFrames = nextFrames;
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  void _setGifLoopCount(int value) {
    setState(() => _gifLoopCount = value);
  }

  void _setGifPlaybackMode(GifPlaybackMode value) {
    setState(() => _gifPlaybackMode = value);
  }

  void _reorderGifSourceImages(int oldIndex, int newIndex) {
    setState(() {
      _gifSourceFrames = reorderListItems(_gifSourceFrames, oldIndex, newIndex);
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  void _removeGifSourceImageAt(int index) {
    if (index < 0 || index >= _gifSourceFrames.length) {
      return;
    }

    final nextFrames = [..._gifSourceFrames]..removeAt(index);
    setState(() {
      _gifSourceFrames = nextFrames;
      _gifOutputPath = null;
      _gifErrorMessage = null;
    });
  }

  Future<void> _resetToDefaults() async {
    _settingsSaveDebounce?.cancel();
    _apiConfigSaveDebounce?.cancel();
    _isRestoringState = true;

    final defaultApiConfig = ApiConfig.defaults();
    _apiConfigNameController.text = defaultApiConfig.name;
    _baseUrlController.text = defaultApiConfig.baseUrl;
    _apiKeyController.clear();
    _modelController.text = defaultApiConfig.model;
    _promptController.text = _defaultSettings.prompt;
    _negativePromptController.clear();
    _animationPromptController.text = _defaultAnimationPrompt;
    _userController.clear();

    setState(() {
      _apiConfigs = [defaultApiConfig];
      _selectedApiConfigId = defaultApiConfig.id;
      _apiConfigProviderKind = defaultApiConfig.providerKind;
      _size = _defaultSettings.size;
      _imageCount = _defaultSettings.imageCount;
      _advancedSettings = _defaultSettings.advancedSettings;
      _animationRows = 4;
      _animationColumns = 4;
      _editorRows = 4;
      _editorColumns = 4;
      _editorTargetFrameIndex = 0;
      _editorFrameFit = SpriteSheetFrameFit.contain;
      _errorMessage = null;
      _animationErrorMessage = null;
      _imageRequestDebugRecord = null;
      _animationRequestDebugRecord = null;
      _generatedImages = const [];
      _animationFrames = const [];
      _animationTemplateImagePath = null;
      _editorImagePath = null;
      _editorPatchImagePath = null;
      _editorErrorMessage = null;
      _gifSourceFrames = const [];
      _gifOutputPath = null;
      _gifErrorMessage = null;
      _gifDefaultFrameDelayMs = 120;
      _gifLoopCount = 0;
      _gifPlaybackMode = GifPlaybackMode.normal;
      _apiTestDebugRecord = null;
      _isTestingApiConfig = false;
    });

    _isRestoringState = false;
    await _store.saveApiConfigs([defaultApiConfig]);
    await _store.saveSelectedApiConfigId(defaultApiConfig.id);
    await _saveSettings();
    if (mounted) {
      _showMessage('表单已重置。');
    }
  }

  Future<void> _generateImage() async {
    final apiConfig = await _prepareSelectedApiConfigForRequest();
    if (!mounted) {
      return;
    }

    final prompt = _promptController.text.trim();

    if (apiConfig.apiKey.trim().isEmpty) {
      _showMessage('请先在接口配置页填写 API Key。');
      return;
    }

    if (prompt.isEmpty) {
      _showMessage('请先填写正向提示词。');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _imageRequestDebugRecord = null;
      _generatedImages = const [];
    });

    try {
      final requestSize = _requestSizeForProvider(
        _size,
        apiConfig.providerKind,
      );
      final request = OpenAIImageRequest(
        baseUrl: apiConfig.baseUrl,
        apiKey: apiConfig.apiKey.trim(),
        model: apiConfig.model,
        prompt: prompt,
        negativePrompt: _negativePromptController.text.trim(),
        size: requestSize,
        imageCount: _imageCount,
        providerKind: apiConfig.providerKind,
        advancedSettings: _advancedSettings.copyWith(
          user: _userController.text.trim(),
        ),
      );
      final response = await _client.generate(
        request,
        onDebugRecord: (record) => _imageRequestDebugRecord = record,
      );

      if (!mounted) {
        return;
      }

      final groupId = DateTime.now().microsecondsSinceEpoch.toString();
      final cachedImages = <GeneratedImage>[];
      for (var index = 0; index < response.images.length; index++) {
        cachedImages.add(
          await _cacheGeneratedImage(
            groupId: groupId,
            index: index,
            image: response.images[index],
          ),
        );
      }

      setState(() => _generatedImages = cachedImages);
      final generation = GenerationSnapshot(
        id: groupId,
        createdAt: DateTime.now(),
        baseUrl: apiConfig.baseUrl,
        model: apiConfig.model,
        providerKind: apiConfig.providerKind,
        prompt: prompt,
        negativePrompt: _negativePromptController.text.trim(),
        size: requestSize,
        imageCount: _imageCount,
        advancedSettings: _advancedSettings.copyWith(
          user: _userController.text.trim(),
        ),
        resultCount: cachedImages.length,
      );
      await _addLibraryItemsForGeneratedImages(
        cachedImages,
        kind: ImageAssetKind.generatedImage,
        titlePrefix: '文本生图',
        source: '文本生图',
        prompt: prompt,
        generation: generation,
        groupId: groupId,
      );
      if (!mounted) {
        return;
      }
      _showMessage('图片生成完成。');
    } on ImageGenerationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = '请求超时，请检查接口地址或稍后重试。');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = '生成失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateAnimationFrames() async {
    final apiConfig = await _prepareSelectedApiConfigForRequest();
    if (!mounted) {
      return;
    }

    final prompt = _animationPromptController.text.trim();
    final totalFrames = _animationFrameCount;
    final templatePath = _animationTemplateImagePath;

    if (apiConfig.apiKey.trim().isEmpty) {
      setState(() => _animationErrorMessage = '请先在接口配置页填写 API Key。');
      return;
    }

    if (prompt.isEmpty) {
      setState(() => _animationErrorMessage = '请先填写动画描述。');
      return;
    }

    if (totalFrames <= 0) {
      setState(() => _animationErrorMessage = '请先设置有效的行列数量。');
      return;
    }

    if (templatePath != null && !await File(templatePath).exists()) {
      setState(() => _animationErrorMessage = '模板图片不存在，请重新选择。');
      return;
    }

    setState(() {
      _isGeneratingAnimation = true;
      _animationErrorMessage = null;
      _animationRequestDebugRecord = null;
      _animationFrames = const [];
    });

    try {
      final groupId =
          'animation_${DateTime.now().microsecondsSinceEpoch.toString()}';
      final requestSize = _requestSizeForProvider(
        _size,
        apiConfig.providerKind,
      );
      final request = OpenAIImageRequest(
        baseUrl: apiConfig.baseUrl,
        apiKey: apiConfig.apiKey.trim(),
        model: apiConfig.model,
        prompt: _buildSpriteSheetPrompt(),
        negativePrompt: _negativePromptController.text.trim(),
        size: requestSize,
        imageCount: 1,
        providerKind: apiConfig.providerKind,
        advancedSettings: _advancedSettings.copyWith(
          user: _userController.text.trim(),
        ),
        templateImagePath: templatePath,
      );
      final response = await _client.generate(
        request,
        onDebugRecord: (record) => _animationRequestDebugRecord = record,
      );

      if (response.images.isEmpty) {
        throw const ImageGenerationException('接口没有返回 Sprite Sheet 图片。');
      }

      final saveResult = await SpriteSheetOutputCache.saveSheetOnly(
        store: _store,
        groupId: groupId,
        sourceImage: response.images.first,
        rows: _animationRows,
        columns: _animationColumns,
        resolveImageBytes: _client.resolveImageBytes,
      );
      final cachedSheet = saveResult.sheet;
      if (!mounted) {
        return;
      }

      final generation = GenerationSnapshot(
        id: groupId,
        createdAt: DateTime.now(),
        baseUrl: apiConfig.baseUrl,
        model: apiConfig.model,
        providerKind: apiConfig.providerKind,
        prompt: prompt,
        negativePrompt: _negativePromptController.text.trim(),
        size: requestSize,
        imageCount: 1,
        advancedSettings: _advancedSettings.copyWith(
          user: _userController.text.trim(),
        ),
        resultCount: 1,
      );
      final sheetPath = cachedSheet.filePath;
      if (sheetPath != null) {
        await _addImageLibraryItem(
          path: sheetPath,
          kind: ImageAssetKind.spriteSheet,
          title: 'Sprite Sheet',
          source: '帧动画',
          prompt: prompt,
          generation: generation,
          groupId: groupId,
          rows: saveResult.rows,
          columns: saveResult.columns,
          frameWidth: saveResult.frameWidth,
          frameHeight: saveResult.frameHeight,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() => _animationFrames = [cachedSheet]);
      _showMessage('Sprite Sheet 已生成，可在作品集中按需切片或直接导出。');
    } on ImageGenerationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _animationErrorMessage = error.message);
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() => _animationErrorMessage = '请求超时，请检查接口地址或稍后重试。');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _animationErrorMessage = '帧动画生成失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAnimation = false);
      }
    }
  }

  Future<void> _composeGif() async {
    if (_gifSourceFrames.length < 2) {
      _showMessage('请至少选择 2 张图片。');
      return;
    }

    setState(() {
      _isComposingGif = true;
      _gifErrorMessage = null;
      _gifOutputPath = null;
    });

    try {
      final outputFile = await _store.createGeneratedGifFile();
      final outputPath = await GifComposer.compose(
        frames: _gifSourceFrames,
        outputPath: outputFile.path,
        loopCount: _gifLoopCount,
        playbackMode: _gifPlaybackMode,
      );

      if (!mounted) {
        return;
      }

      setState(() => _gifOutputPath = outputPath);
      await _addImageLibraryItem(
        path: outputPath,
        kind: ImageAssetKind.gif,
        title: 'GIF 合成',
        source: 'GIF 合成',
        prompt: '由 ${_gifSourceFrames.length} 张图片合成',
      );
      if (!mounted) {
        return;
      }
      _showMessage(
        'GIF 已生成：${_fileNameFromPath(outputPath)} · 目录：${outputFile.parent.path}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _gifErrorMessage = 'GIF 生成失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isComposingGif = false);
      }
    }
  }

  Future<void> _exportSpriteSheet({
    required Uint8List pngBytes,
    required int rows,
    required int columns,
  }) async {
    final outputFile = await _store.createGeneratedSpriteSheetFile(
      rows: rows,
      columns: columns,
    );
    await outputFile.writeAsBytes(pngBytes, flush: true);
    if (!mounted) {
      return;
    }
    await _addImageLibraryItem(
      path: outputFile.path,
      kind: ImageAssetKind.spriteSheet,
      title: '导出 Sprite Sheet',
      source: 'Sprite Sheet 导出',
      prompt: '$rows x $columns',
    );
    if (!mounted) {
      return;
    }
    _showMessage(
      '已导出 Sprite Sheet：${_fileNameFromPath(outputFile.path)} · 目录：${outputFile.parent.path}',
    );
  }

  Future<void> _replaceEditorFrame() async {
    final sheetPath = _editorImagePath;
    final patchPath = _editorPatchImagePath;
    if (sheetPath == null) {
      _showMessage('请先选择一张 Sprite Sheet。');
      return;
    }
    if (patchPath == null) {
      _showMessage('请先选择要插入的单帧图片。');
      return;
    }

    setState(() {
      _isReplacingEditorFrame = true;
      _editorErrorMessage = null;
    });

    try {
      final sheetBytes = await File(sheetPath).readAsBytes();
      final patchBytes = await File(patchPath).readAsBytes();
      final editedBytes = SpriteSheetEditorComposer.replaceFrame(
        sheetBytes: sheetBytes,
        patchBytes: patchBytes,
        rows: _editorRows,
        columns: _editorColumns,
        frameIndex: _editorTargetFrameIndex,
        fit: _editorFrameFit,
      );
      final outputFile = await _store.createGeneratedSpriteSheetFile(
        rows: _editorRows,
        columns: _editorColumns,
      );
      await outputFile.writeAsBytes(editedBytes, flush: true);

      if (!mounted) {
        return;
      }

      setState(() => _editorImagePath = outputFile.path);
      await _addImageLibraryItem(
        path: outputFile.path,
        kind: ImageAssetKind.editedImage,
        title: '编辑后的 Sprite Sheet',
        source: '图片编辑器',
        prompt:
            '替换第 ${_editorTargetFrameIndex + 1} 帧 · $_editorRows x $_editorColumns',
      );
      if (!mounted) {
        return;
      }
      _showMessage(
        '已替换第 ${_editorTargetFrameIndex + 1} 帧：${_fileNameFromPath(outputFile.path)} · 目录：${outputFile.parent.path}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _editorErrorMessage = '单帧替换失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isReplacingEditorFrame = false);
      }
    }
  }

  String _buildSpriteSheetPrompt() {
    final hasTemplate = _animationTemplateImagePath != null;

    return [
      _animationPromptController.text.trim(),
      'Create ONE complete sprite sheet image, not separate files.',
      'The sprite sheet must be arranged as exactly $_animationRows rows x $_animationColumns columns, total $_animationFrameCount cells.',
      'Each cell must have equal size and align to a clean grid.',
      'Rows may represent separate animation tracks, poses, actions, or variants as implied by the prompt.',
      'Columns represent sequential animation frames from left to right.',
      'Keep the same character, silhouette, scale, camera angle, lighting, palette, and visual style across every cell.',
      if (hasTemplate)
        'Use the provided template image as the core reference and preserve its silhouette, key colors, and subject identity.',
      'Output only the final sprite sheet image. No labels, no text, no decorative border, no extra margin.',
    ].join('\n');
  }

  String _buildAnimationFrameLabel(int index) {
    final row = index ~/ _animationColumns;
    final column = index % _animationColumns + 1;
    return '第 ${row + 1} 行 · 第 $column 列';
  }

  String _buildEditorFrameLabel(int index) {
    final row = index ~/ _editorColumns;
    final column = index % _editorColumns + 1;
    return '第 ${index + 1} 帧 · 第 ${row + 1} 行 · 第 $column 列';
  }

  Future<GeneratedImage> _cacheGeneratedImage({
    required String groupId,
    required int index,
    required GeneratedImage image,
  }) async {
    try {
      final bytes = await _client.resolveImageBytes(image);
      final file = await _store.saveGeneratedImageBytes(
        groupId: groupId,
        index: index,
        bytes: bytes,
      );
      return GeneratedImage.file(file.path, revisedPrompt: image.revisedPrompt);
    } catch (_) {
      return image;
    }
  }

  Future<void> _addLibraryItemsForGeneratedImages(
    List<GeneratedImage> images, {
    ImageAssetKind kind = ImageAssetKind.generatedImage,
    ImageAssetKind Function(int index, GeneratedImage image)? kindBuilder,
    String Function(int index, GeneratedImage image)? titleBuilder,
    required String titlePrefix,
    required String source,
    required String prompt,
    GenerationSnapshot? generation,
    String? groupId,
  }) async {
    final now = DateTime.now();
    final items = <ImageLibraryItem>[];
    for (var index = 0; index < images.length; index++) {
      final filePath = images[index].filePath;
      if (filePath == null) {
        continue;
      }
      final title =
          titleBuilder?.call(index, images[index]) ??
          '$titlePrefix ${index + 1}';
      items.add(
        ImageLibraryItem(
          id: ImageLibraryItem.newId(seed: index),
          path: filePath,
          createdAt: now.add(Duration(microseconds: index)),
          kind: kindBuilder?.call(index, images[index]) ?? kind,
          title: title,
          source: source,
          prompt: prompt,
          generation: generation,
          groupId: groupId,
        ),
      );
    }

    if (items.isEmpty) {
      return;
    }

    await _store.addImageLibraryItems(items);
    if (!mounted) {
      return;
    }
    setState(() => _imageLibrary = [...items, ..._imageLibrary]);
  }

  Future<void> _addImageLibraryItem({
    required String path,
    required ImageAssetKind kind,
    required String title,
    required String source,
    String? prompt,
    GenerationSnapshot? generation,
    String? groupId,
    int? rows,
    int? columns,
    int? frameWidth,
    int? frameHeight,
    int? frameIndex,
  }) async {
    final item = ImageLibraryItem(
      id: ImageLibraryItem.newId(),
      path: path,
      createdAt: DateTime.now(),
      kind: kind,
      title: title,
      source: source,
      prompt: prompt,
      generation: generation,
      groupId: groupId,
      rows: rows,
      columns: columns,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      frameIndex: frameIndex,
    );
    await _store.addImageLibraryItems([item]);
    if (!mounted) {
      return;
    }
    setState(() => _imageLibrary = [item, ..._imageLibrary]);
  }

  Set<int> _savedFrameIndexesForSheet(ImageLibraryItem sheet) {
    if (sheet.groupId == null) return const <int>{};
    return <int>{
      for (final item in _imageLibrary)
        if (item.kind == ImageAssetKind.spriteFrame &&
            item.groupId == sheet.groupId &&
            item.frameIndex != null)
          item.frameIndex!,
    };
  }

  Future<bool> _saveSingleSlice(
    ImageLibraryItem sheet,
    int frameIndex,
    Uint8List bytes,
  ) async {
    final groupId = sheet.groupId;
    if (groupId == null) {
      _showMessage('该 Sprite Sheet 缺少 groupId，无法保存切片。');
      return false;
    }
    if (_savedFrameIndexesForSheet(sheet).contains(frameIndex)) {
      return false;
    }
    try {
      final file = await _store.saveGeneratedImageBytes(
        groupId: groupId,
        index: 100 + frameIndex,
        bytes: bytes,
      );
      await _addImageLibraryItem(
        path: file.path,
        kind: ImageAssetKind.spriteFrame,
        title: '${sheet.displayTitle} · 帧 ${frameIndex + 1}',
        source: sheet.source.isEmpty ? '帧动画' : sheet.source,
        prompt: sheet.prompt,
        generation: sheet.generation,
        groupId: groupId,
        frameWidth: sheet.frameWidth,
        frameHeight: sheet.frameHeight,
        frameIndex: frameIndex,
      );
      return true;
    } catch (error) {
      _showMessage('保存切片失败：$error');
      return false;
    }
  }

  Future<int> _saveAllSlices(
    ImageLibraryItem sheet,
    List<MapEntry<int, Uint8List>> framesToSave,
  ) async {
    var saved = 0;
    for (final entry in framesToSave) {
      final ok = await _saveSingleSlice(sheet, entry.key, entry.value);
      if (!ok) break;
      saved++;
    }
    if (mounted) {
      _showMessage('已保存 $saved 个切片帧到作品集。');
    }
    return saved;
  }

  Future<void> _openSliceExplorer(ImageLibraryItem sheet) async {
    if (!sheet.isSpriteSheetWithMetadata) {
      _showMessage('该作品缺少行列元数据，无法切片。');
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _SpriteSheetSliceExplorerDialog(
          sheet: sheet,
          savedFrameIndexes: _savedFrameIndexesForSheet(sheet),
          onSaveSlice: (frameIndex, bytes) =>
              _saveSingleSlice(sheet, frameIndex, bytes),
          onSaveAllSlices: (frames) => _saveAllSlices(sheet, frames),
        );
      },
    );
  }

  Future<void> _updateImageLibraryItemMetadata(
    ImageLibraryItem item, {
    required String title,
    required String note,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedNote = note.trim();
    final nextLibrary = [
      for (final current in _imageLibrary)
        if (current.id == item.id)
          current.copyWith(title: normalizedTitle, note: normalizedNote)
        else
          current,
    ];

    await _store.saveImageLibrary(nextLibrary);
    if (!mounted) {
      return;
    }

    setState(() => _imageLibrary = nextLibrary);
    _showMessage('作品信息已更新。');
  }

  Future<void> _showEditImageLibraryItemDialog(ImageLibraryItem item) async {
    final titleController = TextEditingController(text: item.displayTitle);
    final noteController = TextEditingController(text: item.note);
    final result = await showDialog<({String title, String note})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑作品信息'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '标题'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: _fieldGap),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    hintText: '记录用途、版本或修改说明',
                  ),
                  minLines: 3,
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop((title: titleController.text, note: noteController.text)),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    noteController.dispose();

    if (result == null || !mounted) {
      return;
    }

    await _updateImageLibraryItemMetadata(
      item,
      title: result.title,
      note: result.note,
    );
  }

  Future<void> _copyImageLibraryItemPath(ImageLibraryItem item) async {
    await Clipboard.setData(ClipboardData(text: item.path));
    _showMessage('作品路径已复制。');
  }

  Future<void> _openImageLibraryItemLocation(ImageLibraryItem item) async {
    final file = File(item.path);
    final directory = file.parent;
    if (!await directory.exists()) {
      _showMessage('作品所在目录不存在。');
      return;
    }

    try {
      if (Platform.isWindows) {
        await Process.start('explorer.exe', ['/select,${file.path}']);
      } else if (Platform.isMacOS) {
        await Process.start('open', ['-R', file.path]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [directory.path]);
      } else {
        await Clipboard.setData(ClipboardData(text: directory.path));
        _showMessage('已复制作品目录路径。');
        return;
      }
      _showMessage('已打开作品所在位置。');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: directory.path));
      _showMessage('无法打开目录，已复制作品目录路径。');
    }
  }

  void _setImageLibraryKindFilter(_ImageLibraryKindFilter filter) {
    setState(() {
      _imageLibraryKindFilter = filter;
      _selectedImageLibraryItemIds = <String>{};
    });
  }

  void _setImageLibrarySortOrder(_ImageLibrarySortOrder sortOrder) {
    setState(() => _imageLibrarySortOrder = sortOrder);
  }

  void _setImageLibrarySearchQuery(String value) {
    setState(() {
      _imageLibrarySearchQuery = value;
      _selectedImageLibraryItemIds = <String>{};
    });
  }

  void _clearImageLibrarySearchQuery() {
    _imageLibrarySearchController.clear();
    _setImageLibrarySearchQuery('');
  }

  void _setImageLibraryItemSelected(ImageLibraryItem item, bool selected) {
    setState(() {
      final nextSelection = Set<String>.from(_selectedImageLibraryItemIds);
      if (selected) {
        nextSelection.add(item.id);
      } else {
        nextSelection.remove(item.id);
      }
      _selectedImageLibraryItemIds = nextSelection;
    });
  }

  void _selectVisibleImageLibraryItems(List<ImageLibraryItem> items) {
    if (items.isEmpty) {
      return;
    }

    setState(() {
      _selectedImageLibraryItemIds = {
        ..._selectedImageLibraryItemIds,
        for (final item in items) item.id,
      };
    });
  }

  void _clearImageLibrarySelection() {
    setState(() => _selectedImageLibraryItemIds = <String>{});
  }

  Future<void> _confirmDeleteImageLibraryItem(String id) async {
    final items = [
      for (final item in _imageLibrary)
        if (item.id == id) item,
    ];
    await _confirmDeleteImageLibraryItems(items);
  }

  Future<void> _confirmDeleteSelectedImageLibraryItems() async {
    final selectedIds = _selectedImageLibraryItemIds;
    final items = [
      for (final item in _imageLibrary)
        if (selectedIds.contains(item.id)) item,
    ];
    await _confirmDeleteImageLibraryItems(items);
  }

  Future<void> _confirmDeleteImageLibraryItems(
    List<ImageLibraryItem> items,
  ) async {
    if (items.isEmpty) {
      return;
    }

    final selectedIds = items.map((item) => item.id).toSet();
    final childFrames = <ImageLibraryItem>[];
    for (final item in items) {
      if (item.kind == ImageAssetKind.spriteSheet && item.groupId != null) {
        for (final candidate in _imageLibrary) {
          if (candidate.kind == ImageAssetKind.spriteFrame &&
              candidate.groupId == item.groupId &&
              !selectedIds.contains(candidate.id)) {
            childFrames.add(candidate);
          }
        }
      }
    }
    final cascadeCount = childFrames.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isBatch = items.length > 1;
        return AlertDialog(
          title: Text(isBatch ? '删除 ${items.length} 个作品' : '删除作品'),
          content: Text(
            isBatch
                ? '将从作品库移除这些作品，并删除应用缓存中的对应文件。'
                      '${cascadeCount > 0 ? '\n同时会移除 $cascadeCount 个关联的切片帧。' : ''}'
                      '\n此操作不可撤销。'
                : '将从作品库移除「${items.single.displayTitle}」，并删除应用缓存中的对应文件。'
                      '${cascadeCount > 0 ? '\n同时会移除 $cascadeCount 个关联的切片帧。' : ''}'
                      '\n此操作不可撤销。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final allIds = <String>{
      ...selectedIds,
      for (final frame in childFrames) frame.id,
    };
    await _deleteImageLibraryItems(allIds);
  }

  Future<void> _deleteImageLibraryItems(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final removedItems = [
      for (final item in _imageLibrary)
        if (ids.contains(item.id)) item,
    ];
    final removedPaths = {for (final item in removedItems) item.path};
    final nextLibrary = [
      for (final item in _imageLibrary)
        if (!ids.contains(item.id)) item,
    ];

    await _store.saveImageLibrary(nextLibrary);
    for (final item in removedItems) {
      try {
        final file = File(item.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // 文件可能已被外部移动或删除；作品库索引仍然要完成清理。
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _imageLibrary = nextLibrary;
      _selectedImageLibraryItemIds = {
        for (final id in _selectedImageLibraryItemIds)
          if (!ids.contains(id)) id,
      };
      if (removedPaths.contains(_editorImagePath)) {
        _editorImagePath = null;
      }
      if (removedPaths.contains(_editorPatchImagePath)) {
        _editorPatchImagePath = null;
      }
      if (removedPaths.contains(_animationTemplateImagePath)) {
        _animationTemplateImagePath = null;
      }
      _gifSourceFrames = [
        for (final frame in _gifSourceFrames)
          if (!removedPaths.contains(frame.path)) frame,
      ];
    });
    _showMessage(
      removedItems.length == 1 ? '作品已删除。' : '已删除 ${removedItems.length} 个作品。',
    );
  }

  Future<void> _useImageLibraryItemInEditor(ImageLibraryItem item) async {
    if (!item.canUseAsSpriteSheet) {
      _showMessage('这类作品不能直接作为 Sprite Sheet 编辑。');
      return;
    }
    await _selectFeature(_WorkspaceFeature.imageEditor);
    if (!mounted) {
      return;
    }
    setState(() {
      _editorImagePath = item.path;
      _editorErrorMessage = null;
    });
  }

  Future<void> _reuseImageLibraryGeneration(ImageLibraryItem item) async {
    final generation = item.generation;
    if (generation == null) {
      _showMessage('这个作品没有可复用的生成参数。');
      return;
    }

    if (_selectedFeature != _WorkspaceFeature.imageGeneration) {
      await _selectFeature(_WorkspaceFeature.imageGeneration);
      if (!mounted) {
        return;
      }
    }

    _isRestoringState = true;
    _promptController.text = generation.prompt;
    _negativePromptController.text = generation.negativePrompt;
    _userController.text = generation.advancedSettings.user;
    String? matchingConfigId;
    for (final config in _apiConfigs) {
      if (config.baseUrl == generation.baseUrl &&
          config.model == generation.model &&
          config.providerKind == generation.providerKind) {
        matchingConfigId = config.id;
        break;
      }
    }

    setState(() {
      if (matchingConfigId != null) {
        _selectedApiConfigId = matchingConfigId;
      }
      _size = _imageDimensionsFromSize(generation.size).size;
      _imageCount = generation.imageCount;
      _advancedSettings = generation.advancedSettings;
      _errorMessage = null;
    });

    _isRestoringState = false;
    if (matchingConfigId != null) {
      await _selectApiConfig(matchingConfigId);
    }
    await _saveSettings();
    _showMessage(
      matchingConfigId == null
          ? '已载入作品参数，接口配置需要手动选择。'
          : '已载入作品参数。',
    );
  }

  Future<void> _copyImageLibraryGeneration(ImageLibraryItem item) async {
    final generation = item.generation;
    if (generation == null) {
      _showMessage('这个作品没有可复制的生成参数。');
      return;
    }

    final summary = [
      'Provider: ${_apiProviderKindLabel(generation.providerKind)}',
      'Base URL: ${generation.baseUrl}',
      'Model: ${generation.model}',
      'Size: ${generation.size}',
      'Count: ${generation.imageCount}',
      'Result count: ${generation.resultCount}',
      'Quality: ${generation.advancedSettings.quality}',
      'Background: ${generation.advancedSettings.background}',
      'Output format: ${generation.advancedSettings.outputFormat}',
      'Output compression: ${generation.advancedSettings.outputCompression}',
      'Moderation: ${generation.advancedSettings.moderation}',
      if (generation.advancedSettings.user.trim().isNotEmpty)
        'User: ${generation.advancedSettings.user}',
      'Input fidelity: ${generation.advancedSettings.inputFidelity}',
      'Prompt: ${generation.prompt}',
      if (generation.negativePrompt.trim().isNotEmpty)
        'Negative: ${generation.negativePrompt}',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: summary));
    _showMessage('作品参数已复制。');
  }

  Future<void> _showSettingsDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('本地设置'),
          content: const Text('这里可以重置本地表单。作品与生成参数统一在作品库中管理。'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetToDefaults();
              },
              child: const Text('重置表单'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final navigationExtended = MediaQuery.sizeOf(context).width >= 980;

    if (_isBootstrapping) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FeatureNavigationRail(
              selectedFeature: _selectedFeature,
              extended: navigationExtended,
              onFeatureSelected: (feature) =>
                  unawaited(_selectFeature(feature)),
              onOpenSettings: _showSettingsDialog,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _buildSelectedWorkspace()),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedWorkspace() {
    return switch (_selectedFeature) {
      _WorkspaceFeature.imageGeneration => _buildImageGenerationWorkspace(),
      _WorkspaceFeature.frameAnimation => _buildFrameAnimationWorkspace(),
      _WorkspaceFeature.imageEditor => _buildImageEditorWorkspace(),
      _WorkspaceFeature.gifComposer => _buildGifComposerWorkspace(),
      _WorkspaceFeature.imageLibrary => _buildImageLibraryWorkspace(),
      _WorkspaceFeature.apiSettings => _buildApiSettingsWorkspace(),
    };
  }

  Widget _buildImageGenerationWorkspace() {
    return _WorkspacePage(
      title: '文本生图',
      description: '选择已保存的接口配置，再填写提示词生成图片。',
      controller: _scrollController,
      children: [
        _ResponsiveWorkspaceSplit(
          controls: _ControlPanel(
            apiConfigs: _apiConfigs,
            selectedApiConfigId: _selectedApiConfig.id,
            providerKind: _selectedApiConfig.providerKind,
            promptController: _promptController,
            negativePromptController: _negativePromptController,
            size: _size,
            imageCount: _imageCount,
            advancedSettings: _advancedSettings,
            userController: _userController,
            isGenerating: _isGenerating,
            onApiConfigChanged: _selectApiConfig,
            onOpenApiSettings: () =>
                unawaited(_selectFeature(_WorkspaceFeature.apiSettings)),
            onSizeChanged: _setSize,
            onImageCountChanged: _setImageCount,
            onAdvancedSettingsChanged: _setAdvancedSettings,
            onGenerate: _generateImage,
          ),
          preview: _PreviewPanel(
            errorMessage: _errorMessage,
            generatedImages: _generatedImages,
            isGenerating: _isGenerating,
            debugRecord: _imageRequestDebugRecord,
            onRetry: _generateImage,
          ),
        ),
      ],
    );
  }

  Widget _buildFrameAnimationWorkspace() {
    return _WorkspacePage(
      title: '帧动画生成',
      description: '一次生成完整 Sprite Sheet，再按行列切片预览动作连续性。',
      children: [
        _ResponsiveWorkspaceSplit(
          controls: _FrameAnimationPanel(
            apiConfigs: _apiConfigs,
            selectedApiConfigId: _selectedApiConfig.id,
            providerKind: _selectedApiConfig.providerKind,
            promptController: _animationPromptController,
            negativePromptController: _negativePromptController,
            size: _size,
            rows: _animationRows,
            columns: _animationColumns,
            templateImagePath: _animationTemplateImagePath,
            advancedSettings: _advancedSettings,
            userController: _userController,
            isGenerating: _isGeneratingAnimation,
            onApiConfigChanged: _selectApiConfig,
            onOpenApiSettings: () =>
                unawaited(_selectFeature(_WorkspaceFeature.apiSettings)),
            onSizeChanged: _setSize,
            onRowsChanged: _setAnimationRows,
            onColumnsChanged: _setAnimationColumns,
            onAdvancedSettingsChanged: _setAdvancedSettings,
            onPickTemplateImage: _pickAnimationTemplateImage,
            onClearTemplateImage: _clearAnimationTemplateImage,
            onGenerate: _generateAnimationFrames,
          ),
          preview: _FrameAnimationPreviewPanel(
            title: 'Sprite Sheet 预览',
            emptyMessage: '生成后的整张 Sprite Sheet 会显示在这里',
            errorMessage: _animationErrorMessage,
            debugRecord: _animationRequestDebugRecord,
            generatedImages: _animationFrames,
            isGenerating: _isGeneratingAnimation,
            rows: _animationRows,
            columns: _animationColumns,
            labelBuilder: _buildAnimationFrameLabel,
            onRetry: _generateAnimationFrames,
            onExportSpriteSheet: (bytes) => unawaited(
              _exportSpriteSheet(
                pngBytes: bytes,
                rows: _animationRows,
                columns: _animationColumns,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageEditorWorkspace() {
    final editorImagePath = _editorImagePath;
    final editorImages = editorImagePath == null
        ? const <GeneratedImage>[]
        : [GeneratedImage.file(editorImagePath)];

    return _WorkspacePage(
      title: '图片编辑器',
      description: '载入一张 Sprite Sheet，按行列快速查看第几帧。',
      children: [
        _ResponsiveWorkspaceSplit(
          controls: _SpriteSheetEditorPanel(
            imagePath: editorImagePath,
            patchImagePath: _editorPatchImagePath,
            rows: _editorRows,
            columns: _editorColumns,
            targetFrameIndex: _editorTargetFrameIndex.clamp(
              0,
              _editorFrameCount - 1,
            ),
            frameFit: _editorFrameFit,
            isReplacingFrame: _isReplacingEditorFrame,
            onPickImage: _pickEditorImage,
            onClearImage: _clearEditorImage,
            onPickPatchImage: _pickEditorPatchImage,
            onClearPatchImage: _clearEditorPatchImage,
            onRowsChanged: _setEditorRows,
            onColumnsChanged: _setEditorColumns,
            onTargetFrameChanged: _setEditorTargetFrameIndex,
            onFrameFitChanged: _setEditorFrameFit,
            onReplaceFrame: _replaceEditorFrame,
          ),
          preview: _FrameAnimationPreviewPanel(
            title: '切片查看',
            emptyMessage: '选择一张 Sprite Sheet 后，可以按行列查看第几帧',
            errorMessage: _editorErrorMessage,
            debugRecord: null,
            generatedImages: editorImages,
            isGenerating: false,
            rows: _editorRows,
            columns: _editorColumns,
            labelBuilder: _buildEditorFrameLabel,
            onExportSpriteSheet: (bytes) => unawaited(
              _exportSpriteSheet(
                pngBytes: bytes,
                rows: _editorRows,
                columns: _editorColumns,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGifComposerWorkspace() {
    return _WorkspacePage(
      title: 'GIF 合成',
      description: '选择多张本地图片，按当前顺序合成为一个 GIF 动图。',
      children: [
        _ResponsiveWorkspaceSplit(
          controls: _GifComposerPanel(
            frames: _gifSourceFrames,
            defaultFrameDelayMs: _gifDefaultFrameDelayMs,
            loopCount: _gifLoopCount,
            playbackMode: _gifPlaybackMode,
            isComposing: _isComposingGif,
            outputPath: _gifOutputPath,
            errorMessage: _gifErrorMessage,
            onPickImages: _pickGifSourceImages,
            onClearImages: _clearGifSourceImages,
            onReorderImages: _reorderGifSourceImages,
            onRemoveImageAt: _removeGifSourceImageAt,
            onFrameDelayChanged: _setGifDefaultFrameDelay,
            onApplyFrameDelayToAll: _applyGifFrameDelayToAll,
            onFrameDelayForImageChanged: _setGifSourceFrameDelay,
            onLoopCountChanged: _setGifLoopCount,
            onPlaybackModeChanged: _setGifPlaybackMode,
            onCompose: _composeGif,
          ),
          preview: _GifSourcePreviewPanel(
            frames: _gifSourceFrames,
            outputPath: _gifOutputPath,
          ),
        ),
      ],
    );
  }

  Widget _buildImageLibraryWorkspace() {
    final availableItems = [
      for (final item in _imageLibrary)
        if (item.existsSync) item,
    ];
    final sheetGroupIds = <String>{
      for (final item in availableItems)
        if (item.kind == ImageAssetKind.spriteSheet && item.groupId != null)
          item.groupId!,
    };
    final savedFrameCounts = <String, int>{};
    for (final item in availableItems) {
      if (item.kind == ImageAssetKind.spriteFrame &&
          item.groupId != null &&
          sheetGroupIds.contains(item.groupId)) {
        savedFrameCounts[item.groupId!] =
            (savedFrameCounts[item.groupId!] ?? 0) + 1;
      }
    }
    final visibleItems = [
      for (final item in availableItems)
        if (!(item.kind == ImageAssetKind.spriteFrame &&
                item.groupId != null &&
                sheetGroupIds.contains(item.groupId) &&
                !_showStandaloneSpriteFrames))
          item,
    ];
    final items = [
      for (final item in visibleItems)
        if (_imageLibraryKindFilterMatches(
              _imageLibraryKindFilter,
              item.kind,
            ) &&
            _imageLibraryItemMatchesSearch(item, _imageLibrarySearchQuery))
          item,
    ]..sort((a, b) => _compareImageLibraryItems(a, b, _imageLibrarySortOrder));
    final groupedFrameCount = availableItems
        .where(
          (item) =>
              item.kind == ImageAssetKind.spriteFrame &&
              item.groupId != null &&
              sheetGroupIds.contains(item.groupId),
        )
        .length;

    return _WorkspacePage(
      title: '作品库',
      description: '集中保存生成、切片、编辑和合成后的图片，其他功能可以直接复用。',
      children: [
        _ImageLibraryPanel(
          items: items,
          totalCount: visibleItems.length,
          searchController: _imageLibrarySearchController,
          searchQuery: _imageLibrarySearchQuery,
          onSearchChanged: _setImageLibrarySearchQuery,
          onClearSearch: _clearImageLibrarySearchQuery,
          selectedFilter: _imageLibraryKindFilter,
          onFilterChanged: _setImageLibraryKindFilter,
          sortOrder: _imageLibrarySortOrder,
          onSortOrderChanged: _setImageLibrarySortOrder,
          selectedItemIds: _selectedImageLibraryItemIds,
          onSelectionChanged: _setImageLibraryItemSelected,
          onSelectVisible: () => _selectVisibleImageLibraryItems(items),
          onClearSelection: _clearImageLibrarySelection,
          onDeleteSelected: _confirmDeleteSelectedImageLibraryItems,
          onUseInEditor: _useImageLibraryItemInEditor,
          onReuseGeneration: _reuseImageLibraryGeneration,
          onCopyGeneration: _copyImageLibraryGeneration,
          onEditMetadata: _showEditImageLibraryItemDialog,
          onCopyPath: _copyImageLibraryItemPath,
          onOpenLocation: _openImageLibraryItemLocation,
          onDelete: _confirmDeleteImageLibraryItem,
          onOpenSliceExplorer: _openSliceExplorer,
          savedFrameCountFor: (item) =>
              item.groupId == null ? 0 : (savedFrameCounts[item.groupId!] ?? 0),
          showStandaloneFrames: _showStandaloneSpriteFrames,
          groupedFrameCount: groupedFrameCount,
          onToggleStandaloneFrames: (value) =>
              setState(() => _showStandaloneSpriteFrames = value),
        ),
      ],
    );
  }

  Widget _buildApiSettingsWorkspace() {
    return _WorkspacePage(
      title: '接口配置',
      description: '集中管理不同供应商的接口，其他功能页只需要选择这里保存的配置。',
      children: [
        _ApiSettingsPanel(
          apiConfigs: _apiConfigs,
          selectedApiConfigId: _selectedApiConfig.id,
          saveStatus: _apiConfigSaveStatus,
          saveErrorMessage: _apiConfigSaveErrorMessage,
          isTestingApiConfig: _isTestingApiConfig,
          apiTestDebugRecord: _apiTestDebugRecord,
          nameController: _apiConfigNameController,
          baseUrlController: _baseUrlController,
          apiKeyController: _apiKeyController,
          modelController: _modelController,
          providerKind: _apiConfigProviderKind,
          showApiKey: _showApiKey,
          onApiConfigChanged: _selectApiConfig,
          onAddApiConfig: _addApiConfig,
          onDeleteApiConfig: _deleteSelectedApiConfig,
          onSaveApiConfig: _saveSelectedApiConfig,
          onTestApiConfig: () => _testCurrentApiConfig(),
          onBasicTestApiConfig: () => _testCurrentApiConfig(basic: true),
          onProviderKindChanged: _setApiConfigProviderKind,
          onToggleApiKeyVisibility: () =>
              setState(() => _showApiKey = !_showApiKey),
        ),
      ],
    );
  }
}

class _WorkspacePage extends StatelessWidget {
  const _WorkspacePage({
    required this.title,
    required this.description,
    required this.children,
    this.controller,
  });

  final String title;
  final String description;
  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.all(_workspacePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: _sectionGap),
          ...children,
        ],
      ),
    );
  }
}

class _ResponsiveWorkspaceSplit extends StatelessWidget {
  const _ResponsiveWorkspaceSplit({
    required this.controls,
    required this.preview,
  });

  static const double _controlsWidth = 392;
  static const double _breakpoint = 900;

  final Widget controls;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _breakpoint) {
          return Column(
            children: [
              controls,
              const SizedBox(height: _layoutGap),
              preview,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: _controlsWidth, child: controls),
            const SizedBox(width: _layoutGap),
            Expanded(child: preview),
          ],
        );
      },
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.busyLabel,
    this.isBusy = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final String? busyLabel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: _ButtonProgressIcon(isBusy: isBusy, icon: icon),
        label: Text(isBusy ? busyLabel ?? label : label),
      ),
    );
  }
}

class _ButtonProgressIcon extends StatelessWidget {
  const _ButtonProgressIcon({required this.isBusy, required this.icon});

  final bool isBusy;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (!isBusy) {
      return Icon(icon);
    }

    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _FeatureNavigationRail extends StatelessWidget {
  const _FeatureNavigationRail({
    required this.selectedFeature,
    required this.extended,
    required this.onFeatureSelected,
    required this.onOpenSettings,
  });

  final _WorkspaceFeature selectedFeature;
  final bool extended;
  final ValueChanged<_WorkspaceFeature> onFeatureSelected;
  final VoidCallback onOpenSettings;

  int? get _selectedDestinationIndex {
    return switch (selectedFeature) {
      _WorkspaceFeature.imageGeneration => 0,
      _WorkspaceFeature.frameAnimation => 1,
      _WorkspaceFeature.imageEditor => 2,
      _WorkspaceFeature.gifComposer => 3,
      _WorkspaceFeature.imageLibrary => 4,
      _WorkspaceFeature.apiSettings => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedDestinationIndex,
      extended: extended,
      minWidth: 92,
      minExtendedWidth: 208,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.image_outlined),
          selectedIcon: Icon(Icons.image),
          label: Text('文本生图'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.movie_creation_outlined),
          selectedIcon: Icon(Icons.movie_creation),
          label: Text('帧动画'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.grid_on_outlined),
          selectedIcon: Icon(Icons.grid_on),
          label: Text('图片编辑器'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.gif_box_outlined),
          selectedIcon: Icon(Icons.gif_box),
          label: Text('GIF 合成'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.collections_outlined),
          selectedIcon: Icon(Icons.collections),
          label: Text('作品库'),
        ),
      ],
      onDestinationSelected: (index) {
        final feature = switch (index) {
          0 => _WorkspaceFeature.imageGeneration,
          1 => _WorkspaceFeature.frameAnimation,
          2 => _WorkspaceFeature.imageEditor,
          3 => _WorkspaceFeature.gifComposer,
          _ => _WorkspaceFeature.imageLibrary,
        };
        onFeatureSelected(feature);
      },
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: extended ? 184 : 72,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 24),
                  _NavigationRailAction(
                    extended: extended,
                    selected: selectedFeature == _WorkspaceFeature.apiSettings,
                    icon: Icons.tune_outlined,
                    selectedIcon: Icons.tune,
                    label: '接口配置',
                    onPressed: () =>
                        onFeatureSelected(_WorkspaceFeature.apiSettings),
                  ),
                  const SizedBox(height: 4),
                  _NavigationRailAction(
                    extended: extended,
                    selected: false,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: '设置',
                    onPressed: onOpenSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationRailAction extends StatelessWidget {
  const _NavigationRailAction({
    required this.extended,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onPressed,
  });

  final bool extended;
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;
    final background = selected
        ? colors.secondaryContainer
        : Colors.transparent;
    final currentIcon = selected ? selectedIcon : icon;

    if (extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(currentIcon, color: foreground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: SizedBox(
            width: 72,
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(currentIcon, color: foreground),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopPickSourceTile extends StatelessWidget {
  const _DesktopPickSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    final foreground = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Material(
      color: enabled
          ? theme.colorScheme.surfaceContainerLowest
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: enabled ? 0.72 : 1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApiConfigSelector extends StatelessWidget {
  const _ApiConfigSelector({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.onChanged,
    this.onOpenSettings,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ValueChanged<String> onChanged;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final selectedExists = apiConfigs.any(
      (config) => config.id == selectedApiConfigId,
    );
    final String? selectedValue;
    if (selectedExists) {
      selectedValue = selectedApiConfigId;
    } else if (apiConfigs.isEmpty) {
      selectedValue = null;
    } else {
      selectedValue = apiConfigs.first.id;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('api-config-$selectedValue'),
            initialValue: selectedValue,
            decoration: const InputDecoration(labelText: '接口配置'),
            items: [
              for (final config in apiConfigs)
                DropdownMenuItem<String>(
                  value: config.id,
                  child: Text(config.name),
                ),
            ],
            onChanged: apiConfigs.isEmpty
                ? null
                : (value) {
                    if (value != null) {
                      onChanged(value);
                    }
                  },
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: '管理接口配置',
          child: IconButton.filledTonal(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.tune_outlined),
          ),
        ),
      ],
    );
  }
}

class _ApiSettingsPanel extends StatelessWidget {
  const _ApiSettingsPanel({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.saveStatus,
    required this.saveErrorMessage,
    required this.isTestingApiConfig,
    required this.apiTestDebugRecord,
    required this.nameController,
    required this.baseUrlController,
    required this.apiKeyController,
    required this.modelController,
    required this.providerKind,
    required this.showApiKey,
    required this.onApiConfigChanged,
    required this.onAddApiConfig,
    required this.onDeleteApiConfig,
    required this.onSaveApiConfig,
    required this.onTestApiConfig,
    required this.onBasicTestApiConfig,
    required this.onProviderKindChanged,
    required this.onToggleApiKeyVisibility,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final _ApiConfigSaveStatus saveStatus;
  final String? saveErrorMessage;
  final bool isTestingApiConfig;
  final ImageRequestDebugRecord? apiTestDebugRecord;
  final TextEditingController nameController;
  final TextEditingController baseUrlController;
  final TextEditingController apiKeyController;
  final TextEditingController modelController;
  final ApiProviderKind providerKind;
  final bool showApiKey;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onAddApiConfig;
  final VoidCallback onDeleteApiConfig;
  final VoidCallback onSaveApiConfig;
  final VoidCallback onTestApiConfig;
  final VoidCallback onBasicTestApiConfig;
  final ValueChanged<ApiProviderKind> onProviderKindChanged;
  final VoidCallback onToggleApiKeyVisibility;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '接口配置',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ApiConfigSaveIndicator(
            status: saveStatus,
            errorMessage: saveErrorMessage,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '新增配置',
            onPressed: onAddApiConfig,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: '删除当前配置',
            onPressed: apiConfigs.length <= 1 ? null : onDeleteApiConfig,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      child: Column(
        children: [
          _ApiConfigNameField(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfigId,
            controller: nameController,
            onConfigSelected: onApiConfigChanged,
          ),
          const SizedBox(height: _fieldGap),
          _ApiProviderKindDropdown(
            value: providerKind,
            onChanged: onProviderKindChanged,
          ),
          const SizedBox(height: _fieldGap),
          _ConnectionSettingsFields(
            baseUrlController: baseUrlController,
            apiKeyController: apiKeyController,
            modelController: modelController,
            providerKind: providerKind,
            showApiKey: showApiKey,
            onToggleApiKeyVisibility: onToggleApiKeyVisibility,
          ),
          const SizedBox(height: _fieldGap),
          _ApiConfigActions(
            saveStatus: saveStatus,
            isTestingApiConfig: isTestingApiConfig,
            apiTestDebugRecord: apiTestDebugRecord,
            onSaveApiConfig: onSaveApiConfig,
            onTestApiConfig: onTestApiConfig,
            onBasicTestApiConfig: onBasicTestApiConfig,
          ),
        ],
      ),
    );
  }
}

class _ApiConfigNameField extends StatelessWidget {
  const _ApiConfigNameField({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.controller,
    required this.onConfigSelected,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final TextEditingController controller;
  final ValueChanged<String> onConfigSelected;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '接口名称',
        hintText: '例如 OpenAI 官方、内网代理、备用接口',
        suffixIcon: PopupMenuButton<String>(
          tooltip: '切换接口配置',
          enabled: apiConfigs.isNotEmpty,
          icon: const Icon(Icons.arrow_drop_down),
          onSelected: onConfigSelected,
          itemBuilder: (context) => [
            for (final config in apiConfigs)
              PopupMenuItem<String>(
                value: config.id,
                child: Row(
                  children: [
                    Icon(
                      config.id == selectedApiConfigId
                          ? Icons.check
                          : Icons.http_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(config.name)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApiProviderKindDropdown extends StatelessWidget {
  const _ApiProviderKindDropdown({
    required this.value,
    required this.onChanged,
  });

  final ApiProviderKind value;
  final ValueChanged<ApiProviderKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<ApiProviderKind>(
          key: ValueKey('api-provider-$value'),
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '供应商'),
          items: [
            for (final kind in ApiProviderKind.values)
              DropdownMenuItem<ApiProviderKind>(
                value: kind,
                child: Row(
                  children: [
                    Icon(_apiProviderKindIcon(kind), size: 18),
                    const SizedBox(width: 8),
                    Text(_apiProviderKindLabel(kind)),
                  ],
                ),
              ),
          ],
          onChanged: (kind) {
            if (kind != null) {
              onChanged(kind);
            }
          },
        ),
        const SizedBox(height: 4),
        Text(
          _apiProviderKindDescription(value),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ApiConfigActions extends StatelessWidget {
  const _ApiConfigActions({
    required this.saveStatus,
    required this.isTestingApiConfig,
    required this.apiTestDebugRecord,
    required this.onSaveApiConfig,
    required this.onTestApiConfig,
    required this.onBasicTestApiConfig,
  });

  final _ApiConfigSaveStatus saveStatus;
  final bool isTestingApiConfig;
  final ImageRequestDebugRecord? apiTestDebugRecord;
  final VoidCallback onSaveApiConfig;
  final VoidCallback onTestApiConfig;
  final VoidCallback onBasicTestApiConfig;

  @override
  Widget build(BuildContext context) {
    final saveButton = FilledButton.icon(
      onPressed: saveStatus == _ApiConfigSaveStatus.saving
          ? null
          : onSaveApiConfig,
      icon: _ButtonProgressIcon(
        isBusy: saveStatus == _ApiConfigSaveStatus.saving,
        icon: Icons.save_outlined,
      ),
      label: Text(saveStatus == _ApiConfigSaveStatus.saving ? '保存中' : '保存配置'),
    );
    final testButton = OutlinedButton.icon(
      onPressed: isTestingApiConfig ? null : onTestApiConfig,
      icon: _ButtonProgressIcon(
        isBusy: isTestingApiConfig,
        icon: Icons.cloud_sync_outlined,
      ),
      label: Text(isTestingApiConfig ? '测试中' : '测试接口'),
    );
    final basicTestButton = Tooltip(
      message: '只发送 model/prompt/size/n，先确认接口本身可用',
      child: TextButton.icon(
        onPressed: isTestingApiConfig ? null : onBasicTestApiConfig,
        icon: const Icon(Icons.bolt_outlined, size: 18),
        label: const Text('基础测试'),
      ),
    );
    final debugButton = _RequestDebugButton(record: apiTestDebugRecord);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              saveButton,
              const SizedBox(height: 8),
              testButton,
              const SizedBox(height: 8),
              Row(children: [basicTestButton, const Spacer(), debugButton]),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: saveButton),
            const SizedBox(width: 8),
            testButton,
            const SizedBox(width: 8),
            basicTestButton,
            const SizedBox(width: 8),
            debugButton,
          ],
        );
      },
    );
  }
}

class _ApiConfigSaveIndicator extends StatelessWidget {
  const _ApiConfigSaveIndicator({
    required this.status,
    required this.errorMessage,
  });

  final _ApiConfigSaveStatus status;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (label, color, icon) = switch (status) {
      _ApiConfigSaveStatus.saved => (
        '已保存',
        colorScheme.primary,
        Icons.check_circle_outline,
      ),
      _ApiConfigSaveStatus.pending => (
        '未保存',
        colorScheme.secondary,
        Icons.schedule,
      ),
      _ApiConfigSaveStatus.saving => ('保存中', colorScheme.secondary, Icons.sync),
      _ApiConfigSaveStatus.failed => (
        '保存失败',
        colorScheme.error,
        Icons.error_outline,
      ),
    };
    final tooltip = status == _ApiConfigSaveStatus.failed
        ? '保存失败：${errorMessage ?? '未知错误'}'
        : label;

    return Tooltip(
      message: tooltip,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: Container(
          key: ValueKey(status),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == _ApiConfigSaveStatus.saving)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionSettingsFields extends StatelessWidget {
  const _ConnectionSettingsFields({
    required this.baseUrlController,
    required this.apiKeyController,
    required this.modelController,
    required this.providerKind,
    required this.showApiKey,
    required this.onToggleApiKeyVisibility,
  });

  final TextEditingController baseUrlController;
  final TextEditingController apiKeyController;
  final TextEditingController modelController;
  final ApiProviderKind providerKind;
  final bool showApiKey;
  final VoidCallback onToggleApiKeyVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: baseUrlController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Base URL',
            hintText: _defaultBaseUrlForProviderKind(providerKind),
          ),
        ),
        const SizedBox(height: _fieldGap),
        TextField(
          controller: apiKeyController,
          obscureText: !showApiKey,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: _apiKeyHintForProviderKind(providerKind),
            suffixIcon: IconButton(
              tooltip: showApiKey ? '隐藏密钥' : '显示密钥',
              onPressed: onToggleApiKeyVisibility,
              icon: Icon(
                showApiKey
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: _fieldGap),
        TextField(
          controller: modelController,
          decoration: InputDecoration(
            labelText: '模型',
            hintText: _defaultModelForProviderKind(providerKind),
          ),
        ),
      ],
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.providerKind,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.imageCount,
    required this.advancedSettings,
    required this.userController,
    required this.isGenerating,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onImageCountChanged,
    required this.onAdvancedSettingsChanged,
    required this.onGenerate,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ApiProviderKind providerKind;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final bool isGenerating;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onImageCountChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '生成配置',
      child: Column(
        children: [
          _ApiConfigSelector(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfigId,
            onChanged: onApiConfigChanged,
            onOpenSettings: onOpenApiSettings,
          ),
          const SizedBox(height: _fieldGap),
          TextField(
            controller: promptController,
            minLines: 5,
            maxLines: 9,
            decoration: const InputDecoration(
              labelText: '正向提示词',
              hintText: '描述你想生成的图片',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: _fieldGap),
          TextField(
            controller: negativePromptController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '负向提示词',
              hintText: '会合并到 prompt 中，不额外发送非 OpenAI 字段',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: _fieldGap),
          _ImageSizeInput(
            size: size,
            providerKind: providerKind,
            onChanged: onSizeChanged,
          ),
          const SizedBox(height: _fieldGap),
          _ImageAdvancedSettingsSection(
            settings: advancedSettings,
            userController: userController,
            hasTemplateImage: false,
            onChanged: onAdvancedSettingsChanged,
          ),
          const SizedBox(height: _fieldGap),
          _OptionDropdown<int>(
            label: '数量',
            value: imageCount,
            options: const [1, 2, 3, 4],
            labelBuilder: (value) => '$value 张',
            onChanged: onImageCountChanged,
          ),
          const SizedBox(height: _sectionGap),
          _PrimaryActionButton(
            onPressed: isGenerating ? null : onGenerate,
            icon: Icons.auto_awesome,
            label: '生成图片',
            busyLabel: '生成中',
            isBusy: isGenerating,
          ),
        ],
      ),
    );
  }
}

class _FrameAnimationPanel extends StatelessWidget {
  const _FrameAnimationPanel({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.providerKind,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.rows,
    required this.columns,
    required this.templateImagePath,
    required this.advancedSettings,
    required this.userController,
    required this.isGenerating,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onAdvancedSettingsChanged,
    required this.onPickTemplateImage,
    required this.onClearTemplateImage,
    required this.onGenerate,
  });

  static const List<int> _gridSizes = <int>[1, 2, 3, 4, 5, 6, 7, 8];

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ApiProviderKind providerKind;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int rows;
  final int columns;
  final String? templateImagePath;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final bool isGenerating;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onPickTemplateImage;
  final VoidCallback onClearTemplateImage;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final frameTotal = rows * columns;

    return _Panel(
      title: '帧动画配置',
      child: Column(
        children: [
          _ApiConfigSelector(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfigId,
            onChanged: onApiConfigChanged,
            onOpenSettings: onOpenApiSettings,
          ),
          const SizedBox(height: _fieldGap),
          _TemplateImagePicker(
            imagePath: templateImagePath,
            onPick: isGenerating ? null : onPickTemplateImage,
            onClear: templateImagePath == null || isGenerating
                ? null
                : onClearTemplateImage,
          ),
          const SizedBox(height: _fieldGap),
          TextField(
            controller: promptController,
            minLines: 7,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: '提示词内容',
              hintText: '把主体、场景、风格、动作变化写在这里即可',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: _fieldGap),
          TextField(
            controller: negativePromptController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '负向提示词',
              hintText: '会应用到每一帧',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: _fieldGap),
          _ImageSizeInput(
            size: size,
            providerKind: providerKind,
            onChanged: onSizeChanged,
            compact: true,
          ),
          const SizedBox(height: _fieldGap),
          _ImageAdvancedSettingsSection(
            settings: advancedSettings,
            userController: userController,
            hasTemplateImage: templateImagePath != null,
            onChanged: onAdvancedSettingsChanged,
          ),
          const SizedBox(height: _fieldGap),
          _ResponsivePair(
            first: _OptionDropdown<int>(
              label: '行数',
              value: rows,
              options: _gridSizes,
              labelBuilder: (value) => '$value 行',
              onChanged: onRowsChanged,
            ),
            second: _OptionDropdown<int>(
              label: '列数',
              value: columns,
              options: _gridSizes,
              labelBuilder: (value) => '$value 列',
              helperText:
                  '生成 1 张 $rows x $columns 的 Sprite Sheet，共 $frameTotal 格',
              onChanged: onColumnsChanged,
            ),
          ),
          const SizedBox(height: _sectionGap),
          _PrimaryActionButton(
            onPressed: isGenerating ? null : onGenerate,
            icon: Icons.movie_filter_outlined,
            label: '生成 Sprite Sheet',
            busyLabel: '生成 Sprite Sheet 中',
            isBusy: isGenerating,
          ),
        ],
      ),
    );
  }
}

class _ImageAdvancedSettingsSection extends StatelessWidget {
  const _ImageAdvancedSettingsSection({
    required this.settings,
    required this.userController,
    required this.hasTemplateImage,
    required this.onChanged,
  });

  final ImageAdvancedSettings settings;
  final TextEditingController userController;
  final bool hasTemplateImage;
  final ValueChanged<ImageAdvancedSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final compressionEnabled = settings.supportsOutputCompression;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 4),
      title: const Text('高级输出参数'),
      subtitle: Text(
        '${_imageQualityLabel(settings.quality)}质量 · '
        '${_imageOutputFormatLabel(settings.outputFormat)} · '
        '${_imageBackgroundLabel(settings.background)}背景',
      ),
      children: [
        _ResponsivePair(
          first: _ImageOptionDropdown(
            label: '质量',
            value: settings.quality,
            options: _gptImageQualityOptions,
            labelBuilder: _imageQualityLabel,
            onChanged: (value) => onChanged(settings.copyWith(quality: value)),
          ),
          second: _ImageOptionDropdown(
            label: '背景',
            value: settings.background,
            options: _gptImageBackgroundOptions,
            labelBuilder: _imageBackgroundLabel,
            onChanged: (value) =>
                onChanged(settings.copyWith(background: value)),
          ),
        ),
        const SizedBox(height: _fieldGap),
        _ResponsivePair(
          first: _ImageOptionDropdown(
            label: '输出格式',
            value: settings.outputFormat,
            options: _gptImageOutputFormatOptions,
            labelBuilder: _imageOutputFormatLabel,
            onChanged: (value) {
              final nextBackground =
                  value == 'jpeg' && settings.background == 'transparent'
                  ? 'auto'
                  : settings.background;
              onChanged(
                settings.copyWith(
                  outputFormat: value,
                  background: nextBackground,
                ),
              );
            },
          ),
          second: _ImageOptionDropdown(
            label: '审核强度',
            value: settings.moderation,
            options: _gptImageModerationOptions,
            labelBuilder: _imageModerationLabel,
            onChanged: hasTemplateImage
                ? null
                : (value) => onChanged(settings.copyWith(moderation: value)),
          ),
        ),
        const SizedBox(height: _fieldGap),
        _ImageCompressionSlider(
          value: settings.outputCompression,
          enabled: compressionEnabled,
          onChanged: (value) =>
              onChanged(settings.copyWith(outputCompression: value)),
        ),
        const SizedBox(height: _fieldGap),
        TextField(
          controller: userController,
          decoration: const InputDecoration(
            labelText: '最终用户 ID',
            hintText: '可选，用于 OpenAI 滥用监控',
          ),
        ),
        if (hasTemplateImage) ...[
          const SizedBox(height: _fieldGap),
          _ImageOptionDropdown(
            label: '参考图保真度',
            value: settings.inputFidelity,
            options: const ['low', 'high'],
            labelBuilder: (value) => value == 'high' ? '高' : '低',
            onChanged: (value) =>
                onChanged(settings.copyWith(inputFidelity: value)),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

class _OptionDropdown<T> extends StatelessWidget {
  const _OptionDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.helperText,
    this.fieldKey,
    this.isDense = false,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T>? onChanged;
  final String? helperText;
  final Key? fieldKey;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final T? selectedValue;
    if (options.contains(value)) {
      selectedValue = value;
    } else if (options.isEmpty) {
      selectedValue = null;
    } else {
      selectedValue = options.first;
    }

    return DropdownButtonFormField<T>(
      key: fieldKey,
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        isDense: isDense,
      ),
      items: [
        for (final option in options)
          DropdownMenuItem<T>(
            value: option,
            child: Text(
              labelBuilder(option),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged == null
          ? null
          : (value) {
              if (value != null) {
                onChanged!(value);
              }
            },
    );
  }
}

class _ImageOptionDropdown extends StatelessWidget {
  const _ImageOptionDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final String Function(String value) labelBuilder;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _OptionDropdown<String>(
      label: label,
      value: value,
      options: options,
      labelBuilder: labelBuilder,
      onChanged: onChanged,
    );
  }
}

class _ImageCompressionSlider extends StatelessWidget {
  const _ImageCompressionSlider({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = value.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          enabled ? '输出压缩率 $normalized%' : '输出压缩率仅用于 JPEG / WebP',
          style: theme.textTheme.bodySmall,
        ),
        Slider(
          value: normalized.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: '$normalized%',
          onChanged: enabled ? (value) => onChanged(value.round()) : null,
        ),
      ],
    );
  }
}

class _SpriteSheetEditorPanel extends StatelessWidget {
  const _SpriteSheetEditorPanel({
    required this.imagePath,
    required this.patchImagePath,
    required this.rows,
    required this.columns,
    required this.targetFrameIndex,
    required this.frameFit,
    required this.isReplacingFrame,
    required this.onPickImage,
    required this.onClearImage,
    required this.onPickPatchImage,
    required this.onClearPatchImage,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onTargetFrameChanged,
    required this.onFrameFitChanged,
    required this.onReplaceFrame,
  });

  static const List<int> _gridSizes = <int>[1, 2, 3, 4, 5, 6, 7, 8];

  final String? imagePath;
  final String? patchImagePath;
  final int rows;
  final int columns;
  final int targetFrameIndex;
  final SpriteSheetFrameFit frameFit;
  final bool isReplacingFrame;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onPickPatchImage;
  final VoidCallback onClearPatchImage;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<int> onTargetFrameChanged;
  final ValueChanged<SpriteSheetFrameFit> onFrameFitChanged;
  final VoidCallback onReplaceFrame;

  @override
  Widget build(BuildContext context) {
    final frameTotal = rows * columns;
    final safeFrameIndex = targetFrameIndex.clamp(0, frameTotal - 1);
    final canReplace =
        imagePath != null && patchImagePath != null && !isReplacingFrame;

    return _Panel(
      title: '编辑配置',
      child: Column(
        children: [
          _TemplateImagePicker(
            imagePath: imagePath,
            title: 'Sprite Sheet 图片',
            pickLabel: imagePath == null ? '选择' : '更换',
            clearTooltip: '清除图片',
            onPick: onPickImage,
            onClear: imagePath == null ? null : onClearImage,
          ),
          const SizedBox(height: _fieldGap),
          _ResponsivePair(
            first: _OptionDropdown<int>(
              label: '行数',
              value: rows,
              options: _gridSizes,
              labelBuilder: (value) => '$value 行',
              onChanged: onRowsChanged,
            ),
            second: _OptionDropdown<int>(
              label: '列数',
              value: columns,
              options: _gridSizes,
              labelBuilder: (value) => '$value 列',
              helperText: '共 $frameTotal 帧',
              onChanged: onColumnsChanged,
            ),
          ),
          const SizedBox(height: _fieldGap),
          _TemplateImagePicker(
            imagePath: patchImagePath,
            title: '单帧图片',
            pickLabel: patchImagePath == null ? '选择' : '更换',
            clearTooltip: '清除单帧图片',
            previewHeight: 148,
            onPick: onPickPatchImage,
            onClear: patchImagePath == null ? null : onClearPatchImage,
          ),
          const SizedBox(height: _fieldGap),
          _ResponsivePair(
            first: _OptionDropdown<int>(
              fieldKey: ValueKey(
                'editor-target-frame-$safeFrameIndex-$frameTotal',
              ),
              label: '替换目标',
              value: safeFrameIndex,
              options: [for (var index = 0; index < frameTotal; index++) index],
              labelBuilder: (index) => _editorFrameOptionLabel(index, columns),
              onChanged: onTargetFrameChanged,
            ),
            second: _OptionDropdown<SpriteSheetFrameFit>(
              label: '适配方式',
              value: frameFit,
              options: SpriteSheetFrameFit.values,
              labelBuilder: _spriteSheetFrameFitLabel,
              onChanged: onFrameFitChanged,
            ),
          ),
          const SizedBox(height: _fieldGap),
          _PrimaryActionButton(
            onPressed: canReplace ? onReplaceFrame : null,
            icon: Icons.published_with_changes_outlined,
            label: '插入 / 替换到当前格',
            busyLabel: '替换中',
            isBusy: isReplacingFrame,
          ),
        ],
      ),
    );
  }
}

class _TemplateImagePicker extends StatelessWidget {
  const _TemplateImagePicker({
    required this.imagePath,
    required this.onPick,
    required this.onClear,
    this.title = '模板图片',
    this.pickLabel,
    this.clearTooltip = '清除模板图片',
    this.previewHeight,
  });

  final String? imagePath;
  final VoidCallback? onPick;
  final VoidCallback? onClear;
  final String title;
  final String? pickLabel;
  final String clearTooltip;
  final double? previewHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = imagePath;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  path == null ? title : _fileNameFromPath(path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.image_search_outlined),
                label: Text(pickLabel ?? (path == null ? '选择' : '更换')),
              ),
              IconButton(
                tooltip: clearTooltip,
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (path != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: previewHeight ?? 220,
                width: double.infinity,
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('模板图片加载失败：$error'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GifComposerPanel extends StatelessWidget {
  const _GifComposerPanel({
    required this.frames,
    required this.defaultFrameDelayMs,
    required this.loopCount,
    required this.playbackMode,
    required this.isComposing,
    required this.outputPath,
    required this.errorMessage,
    required this.onPickImages,
    required this.onClearImages,
    required this.onReorderImages,
    required this.onRemoveImageAt,
    required this.onFrameDelayChanged,
    required this.onApplyFrameDelayToAll,
    required this.onFrameDelayForImageChanged,
    required this.onLoopCountChanged,
    required this.onPlaybackModeChanged,
    required this.onCompose,
  });

  final List<GifSourceFrame> frames;
  final int defaultFrameDelayMs;
  final int loopCount;
  final GifPlaybackMode playbackMode;
  final bool isComposing;
  final String? outputPath;
  final String? errorMessage;
  final VoidCallback onPickImages;
  final VoidCallback onClearImages;
  final void Function(int oldIndex, int newIndex) onReorderImages;
  final ValueChanged<int> onRemoveImageAt;
  final ValueChanged<int> onFrameDelayChanged;
  final VoidCallback onApplyFrameDelayToAll;
  final void Function(int index, int delayMs) onFrameDelayForImageChanged;
  final ValueChanged<int> onLoopCountChanged;
  final ValueChanged<GifPlaybackMode> onPlaybackModeChanged;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFrames = frames.isNotEmpty;

    return _Panel(
      title: 'GIF 配置',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isComposing ? null : onPickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('选择图片'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: '清空图片',
                onPressed: hasFrames && !isComposing ? onClearImages : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: _fieldGap),
          Text(
            hasFrames ? '已选择 ${frames.length} 张图片' : '尚未选择图片',
            style: theme.textTheme.bodyMedium,
          ),
          if (hasFrames) ...[
            const SizedBox(height: _fieldGap),
            Text('拖拽排序', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('从上到下就是 GIF 的播放顺序。', style: theme.textTheme.bodySmall),
            const SizedBox(height: _fieldGap),
            SizedBox(
              height: frames.length < 4 ? frames.length * 122.0 : 320.0,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: frames.length,
                onReorder: onReorderImages,
                itemBuilder: (context, index) {
                  final frame = frames[index];
                  return Container(
                    key: ValueKey(frame.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Image.file(
                                File(frame.path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return ColoredBox(
                                    color: theme.colorScheme.errorContainer,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}. ${_fileNameFromPath(frame.path)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                _OptionDropdown<int>(
                                  label: '帧时长',
                                  value: frame.delayMs,
                                  options: _gifFrameDelayOptions,
                                  labelBuilder: (value) => '$value ms',
                                  isDense: true,
                                  onChanged: isComposing
                                      ? null
                                      : (value) => onFrameDelayForImageChanged(
                                          index,
                                          value,
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: '移除图片',
                                child: IconButton(
                                  onPressed: isComposing
                                      ? null
                                      : () => onRemoveImageAt(index),
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                enabled: !isComposing,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(Icons.drag_indicator),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: _fieldGap),
          Row(
            children: [
              Expanded(
                child: _OptionDropdown<int>(
                  label: '默认帧时长',
                  value: defaultFrameDelayMs,
                  options: _gifFrameDelayOptions,
                  labelBuilder: (value) => '$value ms',
                  onChanged: isComposing ? null : onFrameDelayChanged,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '应用到全部',
                onPressed: isComposing || !hasFrames
                    ? null
                    : onApplyFrameDelayToAll,
                icon: const Icon(Icons.playlist_add_check_outlined),
              ),
            ],
          ),
          const SizedBox(height: _fieldGap),
          _OptionDropdown<int>(
            label: '循环次数',
            value: loopCount,
            options: const [0, 1, 3, 5],
            labelBuilder: (value) => value == 0 ? '无限循环' : '播放 $value 次',
            onChanged: isComposing ? null : onLoopCountChanged,
          ),
          const SizedBox(height: _fieldGap),
          _OptionDropdown<GifPlaybackMode>(
            label: '播放模式',
            value: playbackMode,
            options: GifPlaybackMode.values,
            labelBuilder: _gifPlaybackModeLabel,
            onChanged: isComposing ? null : onPlaybackModeChanged,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: _fieldGap),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
          if (outputPath != null) ...[
            const SizedBox(height: _fieldGap),
            SelectableText('输出：$outputPath', style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: _sectionGap),
          _PrimaryActionButton(
            onPressed: isComposing || frames.length < 2 ? null : onCompose,
            icon: Icons.gif_box_outlined,
            label: '生成 GIF',
            busyLabel: '合成中',
            isBusy: isComposing,
          ),
        ],
      ),
    );
  }
}

class _GifSourcePreviewPanel extends StatelessWidget {
  const _GifSourcePreviewPanel({
    required this.frames,
    required this.outputPath,
  });

  final List<GifSourceFrame> frames;
  final String? outputPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _PreviewPanelShell(
      title: outputPath == null ? '图片序列预览' : 'GIF 预览',
      child: outputPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(outputPath!), fit: BoxFit.contain),
            )
          : frames.isEmpty
          ? const _PreviewStateSurface.empty(message: '选择多张图片后会显示在这里')
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: frames.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final frame = frames[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${_fileNameFromPath(frame.path)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${frame.delayMs} ms',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(frame.path),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return ColoredBox(
                              color: theme.colorScheme.errorContainer,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    '加载失败',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.errorMessage,
    required this.generatedImages,
    required this.isGenerating,
    required this.debugRecord,
    required this.onRetry,
  });

  final String? errorMessage;
  final List<GeneratedImage> generatedImages;
  final bool isGenerating;
  final ImageRequestDebugRecord? debugRecord;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _PreviewPanelShell(
      title: '结果预览',
      debugRecord: debugRecord,
      showDebugButton: true,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isGenerating) {
      return const _PreviewStateSurface.loading(
        key: ValueKey('loading'),
        message: '正在生成图片',
      );
    }

    if (errorMessage != null) {
      return _PreviewStateSurface.error(
        key: const ValueKey('error'),
        title: '生成失败',
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    if (generatedImages.isEmpty) {
      return const _PreviewStateSurface.empty(
        key: ValueKey('empty'),
        message: '生成后的图片会显示在这里',
      );
    }

    return LayoutBuilder(
      key: const ValueKey('images'),
      builder: (context, constraints) {
        final width = generatedImages.length <= 1 || constraints.maxWidth < 540
            ? constraints.maxWidth
            : (constraints.maxWidth - _layoutGap) / 2;

        return Wrap(
          spacing: _layoutGap,
          runSpacing: _layoutGap,
          children: [
            for (var index = 0; index < generatedImages.length; index++)
              SizedBox(
                width: width,
                child: _GeneratedImageTile(image: generatedImages[index]),
              ),
          ],
        );
      },
    );
  }
}

class _PreviewPanelShell extends StatelessWidget {
  const _PreviewPanelShell({
    required this.title,
    required this.child,
    this.debugRecord,
    this.showDebugButton = false,
  });

  final String title;
  final Widget child;
  final ImageRequestDebugRecord? debugRecord;
  final bool showDebugButton;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      trailing: showDebugButton
          ? _RequestDebugButton(record: debugRecord)
          : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: child,
      ),
    );
  }
}

enum _PreviewStateKind { empty, loading, error }

class _PreviewStateSurface extends StatelessWidget {
  const _PreviewStateSurface.empty({super.key, required this.message})
    : kind = _PreviewStateKind.empty,
      title = null,
      onRetry = null,
      retryLabel = '重试生成',
      minHeight = 420;

  const _PreviewStateSurface.loading({super.key, required this.message})
    : kind = _PreviewStateKind.loading,
      title = null,
      onRetry = null,
      retryLabel = '重试生成',
      minHeight = 420;

  const _PreviewStateSurface.error({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  }) : kind = _PreviewStateKind.error,
       retryLabel = '重试生成',
       minHeight = 420;

  final _PreviewStateKind kind;
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isError = kind == _PreviewStateKind.error;
    final icon = switch (kind) {
      _PreviewStateKind.empty => Icons.image_outlined,
      _PreviewStateKind.loading => Icons.hourglass_top_outlined,
      _PreviewStateKind.error => Icons.error_outline,
    };

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? colorScheme.error : colorScheme.outlineVariant,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kind == _PreviewStateKind.loading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ] else ...[
              Icon(
                icon,
                size: 38,
                color: isError ? colorScheme.error : colorScheme.primary,
              ),
              const SizedBox(height: 12),
            ],
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _FramePreviewMode { playback, grid }

class _FramePreviewProgressBanner extends StatelessWidget {
  const _FramePreviewProgressBanner({
    required this.totalCount,
    required this.isGenerating,
    required this.errorMessage,
  });

  final int totalCount;
  final bool isGenerating;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;
    final message = hasError
        ? 'Sprite Sheet 生成失败，可调整参数后重试。$errorMessage'
        : isGenerating
        ? '正在生成 1 张 Sprite Sheet，完成后会按 $totalCount 格切片预览。'
        : '已生成 1 张 Sprite Sheet，并按 $totalCount 格切片预览。';

    return _FramePreviewStatusBanner(message: message, isError: hasError);
  }
}

class _FramePreviewStatusBanner extends StatelessWidget {
  const _FramePreviewStatusBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer
            : colorScheme.secondaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.downloading_outlined,
            color: foreground,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestDebugButton extends StatelessWidget {
  const _RequestDebugButton({required this.record});

  final ImageRequestDebugRecord? record;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: record == null ? '生成后可查看请求和返回值' : '查看请求参数和返回值',
      child: OutlinedButton.icon(
        onPressed: record == null
            ? null
            : () => _showRequestDebugDialog(context, record!),
        icon: const Icon(Icons.bug_report_outlined),
        label: const Text('调试详情'),
      ),
    );
  }
}

Future<void> _showRequestDebugDialog(
  BuildContext context,
  ImageRequestDebugRecord record,
) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: const Text('请求调试详情'),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: SelectableText(
              record.formattedJson,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'Consolas',
                fontFamilyFallback: const ['Courier New', 'monospace'],
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: record.formattedJson));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('调试详情已复制。')));
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('复制'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      );
    },
  );
}

class _FrameAnimationPreviewPanel extends StatefulWidget {
  const _FrameAnimationPreviewPanel({
    required this.title,
    required this.emptyMessage,
    required this.errorMessage,
    required this.debugRecord,
    required this.generatedImages,
    required this.isGenerating,
    required this.rows,
    required this.columns,
    required this.onExportSpriteSheet,
    this.labelBuilder,
    this.onRetry,
  });

  final String title;
  final String emptyMessage;
  final String? errorMessage;
  final ImageRequestDebugRecord? debugRecord;
  final List<GeneratedImage> generatedImages;
  final bool isGenerating;
  final int rows;
  final int columns;
  final ValueChanged<Uint8List> onExportSpriteSheet;
  final String Function(int index)? labelBuilder;
  final VoidCallback? onRetry;

  @override
  State<_FrameAnimationPreviewPanel> createState() =>
      _FrameAnimationPreviewPanelState();
}

class _FrameAnimationPreviewPanelState
    extends State<_FrameAnimationPreviewPanel> {
  static const List<int> _playbackSpeeds = <int>[80, 120, 160, 220];

  Future<SpriteSheetPreviewData>? _previewFuture;
  _FramePreviewMode _mode = _FramePreviewMode.playback;
  Timer? _playbackTimer;
  bool _isPlaying = true;
  int _selectedRow = 0;
  int _currentColumn = 0;
  int _frameDelayMs = 120;
  final Set<int> _collapsedRows = <int>{};

  @override
  void initState() {
    super.initState();
    _refreshPreviewFuture();
    _restartPlaybackTimer();
  }

  @override
  void didUpdateWidget(covariant _FrameAnimationPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generatedImages != widget.generatedImages ||
        oldWidget.rows != widget.rows ||
        oldWidget.columns != widget.columns) {
      _selectedRow = _selectedRow.clamp(0, (widget.rows - 1).clamp(0, 99));
      _currentColumn = _currentColumn.clamp(
        0,
        (widget.columns - 1).clamp(0, 99),
      );
      _refreshPreviewFuture();
    }

    if (oldWidget.columns != widget.columns) {
      _currentColumn = 0;
    }

    if (oldWidget.rows != widget.rows && _selectedRow >= widget.rows) {
      _selectedRow = 0;
    }
    _collapsedRows.removeWhere((row) => row >= widget.rows);

    if (oldWidget.isGenerating != widget.isGenerating) {
      _restartPlaybackTimer();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _refreshPreviewFuture() {
    if (widget.generatedImages.isEmpty) {
      _previewFuture = null;
      return;
    }

    _previewFuture = SpriteSheetPreviewComposer.build(
      images: widget.generatedImages,
      rows: widget.rows,
      columns: widget.columns,
      sourceMode: SpriteSheetPreviewSourceMode.sheet,
    );
  }

  void _restartPlaybackTimer() {
    _playbackTimer?.cancel();
    if (!_isPlaying ||
        _mode != _FramePreviewMode.playback ||
        widget.columns <= 1) {
      return;
    }

    _playbackTimer = Timer.periodic(Duration(milliseconds: _frameDelayMs), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentColumn = (_currentColumn + 1) % widget.columns;
      });
    });
  }

  void _togglePlayback() {
    setState(() => _isPlaying = !_isPlaying);
    _restartPlaybackTimer();
  }

  void _selectMode(_FramePreviewMode mode) {
    setState(() => _mode = mode);
    _restartPlaybackTimer();
  }

  void _selectRow(int row) {
    setState(() {
      _selectedRow = row;
      _currentColumn = 0;
    });
  }

  void _selectFrameIndex(int index) {
    if (widget.columns <= 0) {
      return;
    }

    setState(() {
      _selectedRow = index ~/ widget.columns;
      _currentColumn = index % widget.columns;
    });
  }

  void _setFrameDelay(int value) {
    setState(() => _frameDelayMs = value);
    _restartPlaybackTimer();
  }

  void _toggleCollapsedRow(int row) {
    setState(() {
      _selectedRow = row;
      if (_collapsedRows.contains(row)) {
        _collapsedRows.remove(row);
      } else {
        _collapsedRows.add(row);
      }
    });
  }

  void _stepFrame(int delta) {
    if (widget.columns <= 0) {
      return;
    }

    setState(() {
      _currentColumn = (_currentColumn + delta) % widget.columns;
      if (_currentColumn < 0) {
        _currentColumn += widget.columns;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _PreviewPanelShell(
      title: widget.title,
      debugRecord: widget.debugRecord,
      showDebugButton: true,
      child: _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (widget.generatedImages.isEmpty || _previewFuture == null) {
      if (widget.isGenerating) {
        return const _PreviewStateSurface.loading(
          key: ValueKey('frame-preview-loading'),
          message: '正在生成 Sprite Sheet',
        );
      }

      if (widget.errorMessage != null) {
        return _PreviewStateSurface.error(
          key: const ValueKey('frame-preview-error'),
          title: '生成失败',
          message: widget.errorMessage!,
          onRetry: widget.onRetry,
        );
      }

      return _PreviewStateSurface.empty(
        key: const ValueKey('frame-preview-empty'),
        message: widget.emptyMessage,
      );
    }

    return FutureBuilder<SpriteSheetPreviewData>(
      key: ValueKey(
        'frame-preview-${widget.generatedImages.length}-${widget.rows}-${widget.columns}',
      ),
      future: _previewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PreviewStateSurface.loading(
            key: ValueKey('frame-preview-building'),
            message: '正在生成切片预览',
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _PreviewStateSurface.error(
            title: '预览失败',
            message: '切片预览失败：${snapshot.error ?? '没有可用的预览数据'}',
            onRetry: widget.onRetry,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FramePreviewProgressBanner(
              totalCount: widget.rows * widget.columns,
              isGenerating: widget.isGenerating,
              errorMessage: widget.errorMessage,
            ),
            const SizedBox(height: _fieldGap),
            SegmentedButton<_FramePreviewMode>(
              segments: const [
                ButtonSegment<_FramePreviewMode>(
                  value: _FramePreviewMode.playback,
                  icon: Icon(Icons.play_circle_outline),
                  label: Text('切片播放'),
                ),
                ButtonSegment<_FramePreviewMode>(
                  value: _FramePreviewMode.grid,
                  icon: Icon(Icons.grid_view_outlined),
                  label: Text('网格检查'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => _selectMode(selection.single),
            ),
            const SizedBox(height: _fieldGap),
            if (_mode == _FramePreviewMode.playback)
              _buildPlaybackPreview(theme, snapshot.data!)
            else
              _buildGridPreview(theme, snapshot.data!),
          ],
        );
      },
    );
  }

  Widget _buildGridPreview(
    ThemeData theme,
    SpriteSheetPreviewData previewData,
  ) {
    return Column(
      children: [
        for (var row = 0; row < previewData.rows; row++) ...[
          _FrameDirectionSection(
            title: '第 ${row + 1} 行',
            subtitle: '第 ${row + 1} 行 · ${previewData.columns} 帧',
            isCollapsed: _collapsedRows.contains(row),
            isSelected: row == _selectedRow,
            onToggle: () => _toggleCollapsedRow(row),
            child: _buildGridRow(theme, previewData, row),
          ),
          if (row != previewData.rows - 1) const SizedBox(height: _fieldGap),
        ],
      ],
    );
  }

  Widget _buildGridRow(
    ThemeData theme,
    SpriteSheetPreviewData previewData,
    int row,
  ) {
    final rowFrames = previewData.framesForRow(row);
    final start = row * previewData.columns;
    final frameCount = rowFrames.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawWidth =
            (constraints.maxWidth - _fieldGap * (frameCount - 1)) / frameCount;
        final tileWidth = rawWidth.clamp(92.0, 150.0).toDouble();

        return Wrap(
          spacing: _fieldGap,
          runSpacing: _fieldGap,
          children: [
            for (var index = 0; index < rowFrames.length; index++)
              SizedBox(
                width: tileWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.labelBuilder != null) ...[
                      Text(
                        widget.labelBuilder!(start + index),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                    ],
                    _SpriteSheetFrameTile(
                      frameBytes: rowFrames[index],
                      aspectRatio: previewData.frameAspectRatio,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPlaybackPreview(
    ThemeData theme,
    SpriteSheetPreviewData previewData,
  ) {
    final safeRow = _selectedRow.clamp(0, previewData.rows - 1);
    final safeColumn = _currentColumn.clamp(0, previewData.columns - 1);
    final safeFrameIndex = safeRow * previewData.columns + safeColumn;
    final currentFrame = previewData.frameAt(safeRow, safeColumn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: _fieldGap,
          runSpacing: _fieldGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 172,
              child: _OptionDropdown<int>(
                fieldKey: ValueKey('preview-frame-$safeFrameIndex'),
                label: '帧号',
                value: safeFrameIndex,
                options: [
                  for (
                    var index = 0;
                    index < previewData.rows * previewData.columns;
                    index++
                  )
                    index,
                ],
                labelBuilder: (index) => '第 ${index + 1} 帧',
                onChanged: _selectFrameIndex,
              ),
            ),
            SizedBox(
              width: 172,
              child: _OptionDropdown<int>(
                fieldKey: ValueKey('preview-row-$safeRow'),
                label: '行号',
                value: safeRow,
                options: [for (var row = 0; row < previewData.rows; row++) row],
                labelBuilder: (row) => '第 ${row + 1} 行',
                onChanged: _selectRow,
              ),
            ),
            SizedBox(
              width: 156,
              child: _OptionDropdown<int>(
                fieldKey: ValueKey('preview-speed-$_frameDelayMs'),
                label: '播放速度',
                value: _frameDelayMs,
                options: _playbackSpeeds,
                labelBuilder: (speed) => '$speed ms',
                onChanged: _setFrameDelay,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: previewData.columns <= 1 ? null : _togglePlayback,
              icon: Icon(
                _isPlaying ? Icons.pause_circle_outline : Icons.play_arrow,
              ),
              label: Text(_isPlaying ? '暂停' : '播放'),
            ),
            FilledButton.tonalIcon(
              onPressed: () =>
                  widget.onExportSpriteSheet(previewData.sheetBytes),
              icon: const Icon(Icons.download_outlined),
              label: const Text('导出 PNG'),
            ),
            Tooltip(
              message: '上一帧',
              child: IconButton(
                onPressed: previewData.columns <= 1
                    ? null
                    : () => _stepFrame(-1),
                icon: const Icon(Icons.chevron_left),
              ),
            ),
            Tooltip(
              message: '下一帧',
              child: IconButton(
                onPressed: previewData.columns <= 1
                    ? null
                    : () => _stepFrame(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
        const SizedBox(height: _fieldGap),
        Text(
          '第 ${safeFrameIndex + 1} 帧 · 第 ${safeRow + 1} 行 · 第 ${safeColumn + 1} / ${previewData.columns} 列',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Text('按行检查动画轨道，按列检查动作连续性。', style: theme.textTheme.bodySmall),
        const SizedBox(height: _fieldGap),
        LayoutBuilder(
          builder: (context, constraints) {
            final frameCard = _PreviewSurfaceCard(
              title: '播放帧',
              aspectRatio: previewData.frameAspectRatio,
              child: Image.memory(
                currentFrame,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            );
            final sheetCard = _PreviewSurfaceCard(
              title: 'Sprite Sheet',
              subtitle:
                  '${previewData.rows} 行 x ${previewData.columns} 列，来源 ${widget.generatedImages.length} 张结果图',
              aspectRatio: previewData.sheetAspectRatio,
              child: _SpriteSheetPreviewCanvas(
                previewData: previewData,
                selectedRow: safeRow,
                selectedColumn: safeColumn,
              ),
            );

            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  frameCard,
                  const SizedBox(height: _fieldGap),
                  sheetCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: frameCard),
                const SizedBox(width: _fieldGap),
                Expanded(flex: 7, child: sheetCard),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PreviewSurfaceCard extends StatelessWidget {
  const _PreviewSurfaceCard({
    required this.title,
    required this.aspectRatio,
    required this.child,
    this.subtitle,
  });

  final String title;
  final double aspectRatio;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_fieldGap),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: _fieldGap),
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _SpriteSheetPreviewCanvas extends StatelessWidget {
  const _SpriteSheetPreviewCanvas({
    required this.previewData,
    required this.selectedRow,
    required this.selectedColumn,
  });

  final SpriteSheetPreviewData previewData;
  final int selectedRow;
  final int selectedColumn;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            previewData.sheetBytes,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
          ),
          CustomPaint(
            painter: _SpriteSheetHighlightPainter(
              previewData: previewData,
              selectedRow: selectedRow,
              selectedColumn: selectedColumn,
              rowColor: colorScheme.primary.withValues(alpha: 0.18),
              rowBorderColor: colorScheme.primary,
              cellBorderColor: colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpriteSheetHighlightPainter extends CustomPainter {
  const _SpriteSheetHighlightPainter({
    required this.previewData,
    required this.selectedRow,
    required this.selectedColumn,
    required this.rowColor,
    required this.rowBorderColor,
    required this.cellBorderColor,
  });

  final SpriteSheetPreviewData previewData;
  final int selectedRow;
  final int selectedColumn;
  final Color rowColor;
  final Color rowBorderColor;
  final Color cellBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final safeRow = selectedRow.clamp(0, previewData.rows - 1);
    final safeColumn = selectedColumn.clamp(0, previewData.columns - 1);
    final rowRect = previewData.rowRectForDisplay(size, safeRow);
    final cellRect = previewData.cellRectForDisplay(size, safeRow, safeColumn);

    final rowFillPaint = Paint()..color = rowColor;
    final rowBorderPaint = Paint()
      ..color = rowBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final cellBorderPaint = Paint()
      ..color = cellBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(rowRect, rowFillPaint);
    canvas.drawRect(rowRect, rowBorderPaint);
    canvas.drawRect(cellRect.deflate(1), cellBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpriteSheetHighlightPainter oldDelegate) {
    return previewData != oldDelegate.previewData ||
        selectedRow != oldDelegate.selectedRow ||
        selectedColumn != oldDelegate.selectedColumn ||
        rowColor != oldDelegate.rowColor ||
        rowBorderColor != oldDelegate.rowBorderColor ||
        cellBorderColor != oldDelegate.cellBorderColor;
  }
}

class _FrameDirectionSection extends StatelessWidget {
  const _FrameDirectionSection({
    required this.title,
    required this.subtitle,
    required this.isCollapsed,
    required this.isSelected,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final bool isCollapsed;
  final bool isSelected;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _fieldGap,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    isCollapsed
                        ? Icons.keyboard_arrow_right
                        : Icons.keyboard_arrow_down,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isCollapsed) ...[
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Padding(padding: const EdgeInsets.all(_fieldGap), child: child),
          ],
        ],
      ),
    );
  }
}

class _GeneratedImageTile extends StatelessWidget {
  const _GeneratedImageTile({required this.image});

  final GeneratedImage image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 1,
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: _buildImageContent(),
            ),
          ),
        ),
        if (image.revisedPrompt != null && image.revisedPrompt!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            image.revisedPrompt!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildImageContent() {
    if (image.filePath != null) {
      return Image.file(File(image.filePath!), fit: BoxFit.cover);
    }

    if (image.bytes != null) {
      return Image.memory(image.bytes!, fit: BoxFit.cover);
    }

    return Image.network(
      image.url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('图片加载失败：$error'),
          ),
        );
      },
    );
  }
}

class _SpriteSheetFrameTile extends StatelessWidget {
  const _SpriteSheetFrameTile({
    required this.frameBytes,
    required this.aspectRatio,
  });

  final Uint8List frameBytes;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Image.memory(
            frameBytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_panelPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: _fieldGap),
          child,
        ],
      ),
    );
  }
}

class _ImageLibraryPanel extends StatelessWidget {
  const _ImageLibraryPanel({
    required this.items,
    required this.totalCount,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.sortOrder,
    required this.onSortOrderChanged,
    required this.selectedItemIds,
    required this.onSelectionChanged,
    required this.onSelectVisible,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.onUseInEditor,
    required this.onReuseGeneration,
    required this.onCopyGeneration,
    required this.onEditMetadata,
    required this.onCopyPath,
    required this.onOpenLocation,
    required this.onDelete,
    required this.onOpenSliceExplorer,
    required this.savedFrameCountFor,
    required this.showStandaloneFrames,
    required this.groupedFrameCount,
    required this.onToggleStandaloneFrames,
  });

  final List<ImageLibraryItem> items;
  final int totalCount;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final _ImageLibraryKindFilter selectedFilter;
  final ValueChanged<_ImageLibraryKindFilter> onFilterChanged;
  final _ImageLibrarySortOrder sortOrder;
  final ValueChanged<_ImageLibrarySortOrder> onSortOrderChanged;
  final Set<String> selectedItemIds;
  final void Function(ImageLibraryItem item, bool selected) onSelectionChanged;
  final VoidCallback onSelectVisible;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final ValueChanged<ImageLibraryItem> onUseInEditor;
  final ValueChanged<ImageLibraryItem> onReuseGeneration;
  final ValueChanged<ImageLibraryItem> onCopyGeneration;
  final ValueChanged<ImageLibraryItem> onEditMetadata;
  final ValueChanged<ImageLibraryItem> onCopyPath;
  final ValueChanged<ImageLibraryItem> onOpenLocation;
  final ValueChanged<String> onDelete;
  final ValueChanged<ImageLibraryItem> onOpenSliceExplorer;
  final int Function(ImageLibraryItem item) savedFrameCountFor;
  final bool showStandaloneFrames;
  final int groupedFrameCount;
  final ValueChanged<bool> onToggleStandaloneFrames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = selectedItemIds.length;
    final visibleSelectedCount = items
        .where((item) => selectedItemIds.contains(item.id))
        .length;

    return _Panel(
      title: '应用内作品',
      trailing: Text(
        items.length == totalCount
            ? '$totalCount 个作品'
            : '${items.length} / $totalCount',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: '搜索作品',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清空搜索',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: _fieldGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in _ImageLibraryKindFilter.values)
                FilterChip(
                  selected: selectedFilter == filter,
                  label: Text(_imageLibraryKindFilterLabel(filter)),
                  onSelected: (_) => onFilterChanged(filter),
                ),
            ],
          ),
          const SizedBox(height: _fieldGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: _OptionDropdown<_ImageLibrarySortOrder>(
                  label: '排序',
                  value: sortOrder,
                  options: _ImageLibrarySortOrder.values,
                  labelBuilder: _imageLibrarySortOrderLabel,
                  onChanged: onSortOrderChanged,
                  isDense: true,
                ),
              ),
              OutlinedButton.icon(
                onPressed: items.isEmpty || visibleSelectedCount == items.length
                    ? null
                    : onSelectVisible,
                icon: const Icon(Icons.checklist_outlined),
                label: const Text('选择当前结果'),
              ),
              if (groupedFrameCount > 0)
                FilterChip(
                  selected: showStandaloneFrames,
                  avatar: Icon(
                    showStandaloneFrames
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  label: Text('展开切片 ($groupedFrameCount)'),
                  onSelected: onToggleStandaloneFrames,
                ),
              if (selectedCount > 0) ...[
                TextButton.icon(
                  onPressed: onClearSelection,
                  icon: const Icon(Icons.close),
                  label: Text('已选 $selectedCount'),
                ),
                FilledButton.icon(
                  onPressed: onDeleteSelected,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除已选'),
                ),
              ],
            ],
          ),
          const SizedBox(height: _fieldGap),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 220),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                totalCount == 0
                    ? '暂无作品。生成、导出、编辑或合成后的图片会保存到这里。'
                    : '当前条件下没有作品。',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.69,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _ImageLibraryTile(
                  item: item,
                  selected: selectedItemIds.contains(item.id),
                  onSelectionChanged: (selected) =>
                      onSelectionChanged(item, selected),
                  onUseInEditor: () => onUseInEditor(item),
                  onReuseGeneration: () => onReuseGeneration(item),
                  onCopyGeneration: () => onCopyGeneration(item),
                  onEditMetadata: () => onEditMetadata(item),
                  onCopyPath: () => onCopyPath(item),
                  onOpenLocation: () => onOpenLocation(item),
                  onDelete: () => onDelete(item.id),
                  onOpenSliceExplorer: () => onOpenSliceExplorer(item),
                  savedFrameCount: savedFrameCountFor(item),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ImageLibraryTile extends StatelessWidget {
  const _ImageLibraryTile({
    required this.item,
    required this.selected,
    required this.onSelectionChanged,
    required this.onUseInEditor,
    required this.onReuseGeneration,
    required this.onCopyGeneration,
    required this.onEditMetadata,
    required this.onCopyPath,
    required this.onOpenLocation,
    required this.onDelete,
    required this.onOpenSliceExplorer,
    required this.savedFrameCount,
  });

  final ImageLibraryItem item;
  final bool selected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onUseInEditor;
  final VoidCallback onReuseGeneration;
  final VoidCallback onCopyGeneration;
  final VoidCallback onEditMetadata;
  final VoidCallback onCopyPath;
  final VoidCallback onOpenLocation;
  final VoidCallback onDelete;
  final VoidCallback onOpenSliceExplorer;
  final int savedFrameCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSheetWithMeta = item.isSpriteSheetWithMetadata;
    final totalFrames = item.totalFrameCount;
    final generation = item.generation;
    final displayPrompt = item.prompt ?? generation?.prompt;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isSheetWithMeta
              ? onOpenSliceExplorer
              : item.canUseAsSpriteSheet
              ? onUseInEditor
              : generation != null
              ? onReuseGeneration
              : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: _ImageLibraryPreview(item: item),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.88,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Checkbox(
                            value: selected,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) =>
                                onSelectionChanged(value ?? false),
                          ),
                        ),
                      ),
                      if (isSheetWithMeta)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.dashboard_customize_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$savedFrameCount/$totalFrames 帧',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _ImageKindChip(kind: item.kind),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.source} · ${_formatTimestamp(item.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                if (generation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_apiProviderKindLabel(generation.providerKind)} · '
                    '${generation.model} · ${generation.size}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (item.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (displayPrompt != null &&
                    displayPrompt.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    displayPrompt.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isSheetWithMeta)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onOpenSliceExplorer,
                          icon: const Icon(Icons.dashboard_customize_outlined),
                          label: const Text('切片'),
                        ),
                      )
                    else if (generation != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReuseGeneration,
                          icon: const Icon(Icons.restore_outlined),
                          label: const Text('复用'),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: item.canUseAsSpriteSheet
                              ? onUseInEditor
                              : null,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('编辑'),
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: '编辑作品信息',
                      onPressed: onEditMetadata,
                      icon: const Icon(Icons.drive_file_rename_outline),
                    ),
                    PopupMenuButton<_ImageLibraryTileMenuAction>(
                      tooltip: '更多操作',
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (action) {
                        switch (action) {
                          case _ImageLibraryTileMenuAction.useInEditor:
                            onUseInEditor();
                          case _ImageLibraryTileMenuAction.reuseGeneration:
                            onReuseGeneration();
                          case _ImageLibraryTileMenuAction.copyGeneration:
                            onCopyGeneration();
                          case _ImageLibraryTileMenuAction.copyPath:
                            onCopyPath();
                          case _ImageLibraryTileMenuAction.openLocation:
                            onOpenLocation();
                          case _ImageLibraryTileMenuAction.delete:
                            onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        if (isSheetWithMeta && item.canUseAsSpriteSheet)
                          const PopupMenuItem(
                            value: _ImageLibraryTileMenuAction.useInEditor,
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('在编辑器中打开'),
                            ),
                          ),
                        if (generation != null) ...[
                          const PopupMenuItem(
                            value:
                                _ImageLibraryTileMenuAction.reuseGeneration,
                            child: ListTile(
                              leading: Icon(Icons.restore_outlined),
                              title: Text('复用生成参数'),
                            ),
                          ),
                          const PopupMenuItem(
                            value:
                                _ImageLibraryTileMenuAction.copyGeneration,
                            child: ListTile(
                              leading: Icon(Icons.content_copy_outlined),
                              title: Text('复制生成参数'),
                            ),
                          ),
                        ],
                        const PopupMenuItem(
                          value: _ImageLibraryTileMenuAction.copyPath,
                          child: ListTile(
                            leading: Icon(Icons.copy_outlined),
                            title: Text('复制路径'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: _ImageLibraryTileMenuAction.openLocation,
                          child: ListTile(
                            leading: Icon(Icons.folder_open_outlined),
                            title: Text('打开位置'),
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: _ImageLibraryTileMenuAction.delete,
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('删除作品'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageLibraryPreview extends StatelessWidget {
  const _ImageLibraryPreview({required this.item});

  final ImageLibraryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!item.isImageFile) {
      return Center(
        child: Icon(
          Icons.gif_box_outlined,
          size: 42,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return Image.file(
      File(item.path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.error,
          ),
        );
      },
    );
  }
}

class _SpriteSheetSliceExplorerDialog extends StatefulWidget {
  const _SpriteSheetSliceExplorerDialog({
    required this.sheet,
    required this.savedFrameIndexes,
    required this.onSaveSlice,
    required this.onSaveAllSlices,
  });

  final ImageLibraryItem sheet;
  final Set<int> savedFrameIndexes;
  final Future<bool> Function(int frameIndex, Uint8List bytes) onSaveSlice;
  final Future<int> Function(List<MapEntry<int, Uint8List>> framesToSave)
  onSaveAllSlices;

  @override
  State<_SpriteSheetSliceExplorerDialog> createState() =>
      _SpriteSheetSliceExplorerDialogState();
}

class _SpriteSheetSliceExplorerDialogState
    extends State<_SpriteSheetSliceExplorerDialog> {
  SpriteSheetPreviewData? _previewData;
  String? _errorMessage;
  final Set<int> _savingIndexes = <int>{};
  final Set<int> _justSaved = <int>{};
  bool _isSavingAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.sheet.path).readAsBytes();
      final rows = widget.sheet.rows;
      final columns = widget.sheet.columns;
      if (rows == null || columns == null || rows <= 0 || columns <= 0) {
        throw const ImageGenerationException('该 Sprite Sheet 缺少行列元数据。');
      }
      final data = SpriteSheetPreviewComposer.buildFromSheetBytes(
        bytes,
        rows: rows,
        columns: columns,
      );
      if (!mounted) return;
      setState(() => _previewData = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = '加载切片失败：$error');
    }
  }

  bool _isSaved(int frameIndex) =>
      widget.savedFrameIndexes.contains(frameIndex) ||
      _justSaved.contains(frameIndex);

  Future<void> _saveOne(int frameIndex) async {
    final data = _previewData;
    if (data == null || _savingIndexes.contains(frameIndex)) return;
    setState(() => _savingIndexes.add(frameIndex));
    try {
      final saved = await widget.onSaveSlice(
        frameIndex,
        data.frames[frameIndex],
      );
      if (!mounted) return;
      if (saved) {
        setState(() => _justSaved.add(frameIndex));
      }
    } finally {
      if (mounted) {
        setState(() => _savingIndexes.remove(frameIndex));
      }
    }
  }

  Future<void> _saveAll() async {
    final data = _previewData;
    if (data == null || _isSavingAll) return;
    final pending = <MapEntry<int, Uint8List>>[];
    for (var i = 0; i < data.frames.length; i++) {
      if (!_isSaved(i)) {
        pending.add(MapEntry(i, data.frames[i]));
      }
    }
    if (pending.isEmpty) return;
    setState(() => _isSavingAll = true);
    try {
      final actuallySaved = await widget.onSaveAllSlices(pending);
      if (!mounted) return;
      setState(() {
        _justSaved.addAll(pending.take(actuallySaved).map((e) => e.key));
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingAll = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _previewData;
    final error = _errorMessage;
    final totalCount = (widget.sheet.rows ?? 0) * (widget.sheet.columns ?? 0);
    final savedCount = data == null
        ? widget.savedFrameIndexes.length
        : List.generate(
            data.frames.length,
            (i) => _isSaved(i),
          ).where((e) => e).length;
    final remaining = (data?.frames.length ?? totalCount) - savedCount;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text('切片管理 · ${widget.sheet.displayTitle}'),
          ),
          if (data != null)
            Text(
              '已保存 $savedCount / ${data.frames.length}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 520,
        child: error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _previewData = null;
                        });
                        _load();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              )
            : data == null
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio:
                      data.frameWidth /
                      (data.frameHeight == 0 ? 1 : data.frameHeight),
                ),
                itemCount: data.frames.length,
                itemBuilder: (context, index) {
                  final bytes = data.frames[index];
                  final saved = _isSaved(index);
                  final saving = _savingIndexes.contains(index);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: saved
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.outlineVariant,
                        width: saved ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Image.memory(bytes, fit: BoxFit.contain),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.85,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${index + 1}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ),
                          if (saved)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '已保存',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          if (!saved)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Material(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.85,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                child: IconButton(
                                  tooltip: '保存这一帧',
                                  iconSize: 20,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: saving ? null : () => _saveOne(index),
                                  icon: saving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.bookmark_add_outlined,
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: data == null || _isSavingAll || remaining <= 0
              ? null
              : _saveAll,
          icon: _isSavingAll
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.select_all),
          label: Text(
            remaining <= 0
                ? '已全部保存'
                : '全部保存为切片 ($remaining)',
          ),
        ),
      ],
    );
  }
}

class _SpriteSheetSlicePickerDialog extends StatefulWidget {
  const _SpriteSheetSlicePickerDialog({
    required this.sheet,
    required this.allowMultiple,
    this.title,
  });

  final ImageLibraryItem sheet;
  final bool allowMultiple;
  final String? title;

  @override
  State<_SpriteSheetSlicePickerDialog> createState() =>
      _SpriteSheetSlicePickerDialogState();
}

class _SpriteSheetSlicePickerDialogState
    extends State<_SpriteSheetSlicePickerDialog> {
  SpriteSheetPreviewData? _previewData;
  String? _errorMessage;
  final Set<int> _selected = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.sheet.path).readAsBytes();
      final rows = widget.sheet.rows;
      final columns = widget.sheet.columns;
      if (rows == null || columns == null || rows <= 0 || columns <= 0) {
        throw const ImageGenerationException('该 Sprite Sheet 缺少行列元数据。');
      }
      final data = SpriteSheetPreviewComposer.buildFromSheetBytes(
        bytes,
        rows: rows,
        columns: columns,
      );
      if (!mounted) return;
      setState(() => _previewData = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = '加载切片失败：$error');
    }
  }

  void _toggle(int index) {
    setState(() {
      if (widget.allowMultiple) {
        if (_selected.contains(index)) {
          _selected.remove(index);
        } else {
          _selected.add(index);
        }
      } else {
        _selected
          ..clear()
          ..add(index);
      }
    });
  }

  void _confirm() {
    final data = _previewData;
    if (data == null || _selected.isEmpty) return;
    final ordered = _selected.toList()..sort();
    Navigator.of(context).pop(
      <MapEntry<int, Uint8List>>[
        for (final idx in ordered) MapEntry(idx, data.frames[idx]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _previewData;
    final error = _errorMessage;
    final title =
        widget.title ?? (widget.allowMultiple ? '挑选切片帧' : '挑选一帧作为来源');

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('$title · ${widget.sheet.displayTitle}')),
          if (data != null)
            Text(
              widget.allowMultiple
                  ? '已选 ${_selected.length} / ${data.frames.length}'
                  : _selected.isEmpty
                  ? '尚未选择'
                  : '已选 #${_selected.first + 1}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 520,
        child: error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _previewData = null;
                        });
                        _load();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              )
            : data == null
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio:
                      data.frameWidth /
                      (data.frameHeight == 0 ? 1 : data.frameHeight),
                ),
                itemCount: data.frames.length,
                itemBuilder: (context, index) {
                  final bytes = data.frames[index];
                  final selected = _selected.contains(index);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _toggle(index),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child:
                                      Image.memory(bytes, fit: BoxFit.contain),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface
                                        .withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                              ),
                              if (selected)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.check,
                                      size: 14,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: data == null || _selected.isEmpty ? null : _confirm,
          icon: const Icon(Icons.check),
          label: Text(
            widget.allowMultiple
                ? '确认选择 (${_selected.length})'
                : '确认选择',
          ),
        ),
      ],
    );
  }
}

class _ImageKindChip extends StatelessWidget {
  const _ImageKindChip({required this.kind});

  final ImageAssetKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _imageAssetKindLabel(kind),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _ImageLibraryPickerDialog extends StatefulWidget {
  const _ImageLibraryPickerDialog({
    required this.title,
    required this.items,
    required this.allowMultiple,
  });

  final String title;
  final List<ImageLibraryItem> items;
  final bool allowMultiple;

  @override
  State<_ImageLibraryPickerDialog> createState() =>
      _ImageLibraryPickerDialogState();
}

class _ImageLibraryPickerDialogState extends State<_ImageLibraryPickerDialog> {
  final Set<String> _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 760,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: widget.items.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final selected = _selectedIds.contains(item.id);
              return Material(
                color: selected
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _toggleSelection(item),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: _ImageLibraryPreview(item: item),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: selected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _imageAssetKindLabel(item.kind),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selectedIds.isEmpty ? null : _confirm,
          child: Text(
            widget.allowMultiple ? '选择 ${_selectedIds.length} 张' : '选择',
          ),
        ),
      ],
    );
  }

  void _toggleSelection(ImageLibraryItem item) {
    setState(() {
      if (widget.allowMultiple) {
        if (!_selectedIds.add(item.id)) {
          _selectedIds.remove(item.id);
        }
      } else {
        _selectedIds
          ..clear()
          ..add(item.id);
      }
    });
  }

  void _confirm() {
    if (widget.allowMultiple) {
      Navigator.of(context).pop([
        for (final item in widget.items)
          if (_selectedIds.contains(item.id)) item,
      ]);
      return;
    }

    final selectedId = _selectedIds.first;
    for (final item in widget.items) {
      if (item.id == selectedId) {
        Navigator.of(context).pop(item);
        return;
      }
    }
  }
}

List<T> reorderListItems<T>(List<T> items, int oldIndex, int newIndex) {
  if (items.isEmpty) {
    return <T>[];
  }
  if (oldIndex < 0 ||
      oldIndex >= items.length ||
      newIndex < 0 ||
      newIndex > items.length) {
    return List<T>.from(items);
  }

  final reordered = List<T>.from(items);
  final normalizedNewIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
  final item = reordered.removeAt(oldIndex);
  reordered.insert(normalizedNewIndex, item);
  return reordered;
}

List<T> expandGifFrameSequence<T>(List<T> items, GifPlaybackMode mode) {
  if (items.length <= 1) {
    return List<T>.from(items);
  }

  return switch (mode) {
    GifPlaybackMode.normal => List<T>.from(items),
    GifPlaybackMode.reverse => items.reversed.toList(),
    GifPlaybackMode.pingPong => [
      ...items,
      ...items.reversed.skip(1).take(items.length - 2),
    ],
  };
}

String _fileNameFromPath(String path) {
  final parts = path.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty);
  return parts.isEmpty ? path : parts.last;
}

String _editorFrameOptionLabel(int index, int columns) {
  final row = index ~/ columns + 1;
  final column = index % columns + 1;
  return '${index + 1}帧 · $row行$column列';
}

String _spriteSheetFrameFitLabel(SpriteSheetFrameFit fit) {
  return switch (fit) {
    SpriteSheetFrameFit.contain => '完整放入',
    SpriteSheetFrameFit.cover => '裁剪填满',
    SpriteSheetFrameFit.stretch => '拉伸填满',
  };
}

String _gifPlaybackModeLabel(GifPlaybackMode mode) {
  return switch (mode) {
    GifPlaybackMode.normal => '正向',
    GifPlaybackMode.reverse => '反向',
    GifPlaybackMode.pingPong => '乒乓',
  };
}

_ImageDimensions _imageDimensionsFromSize(String size) {
  final parts = size.toLowerCase().split('x');
  if (parts.length != 2) {
    return const _ImageDimensions(
      _openAIDefaultImageSide,
      _openAIDefaultImageSide,
    );
  }

  final width = int.tryParse(parts[0].trim());
  final height = int.tryParse(parts[1].trim());
  if (width == null || height == null || width <= 0 || height <= 0) {
    return const _ImageDimensions(
      _openAIDefaultImageSide,
      _openAIDefaultImageSide,
    );
  }

  return _ImageDimensions(width, height);
}

String _requestSizeForProvider(String size, ApiProviderKind providerKind) {
  return _requestDimensionsForProvider(
    _imageDimensionsFromSize(size),
    providerKind,
  ).size;
}

_ImageDimensions _requestDimensionsForProvider(
  _ImageDimensions dimensions,
  ApiProviderKind providerKind,
) {
  if (providerKind == ApiProviderKind.gemini) {
    return dimensions;
  }

  return _normalizeOpenAIImageDimensions(dimensions);
}

_ImageDimensions _normalizeOpenAIImageDimensions(_ImageDimensions dimensions) {
  var width = _snapImageSideToStep(dimensions.width);
  var height = _snapImageSideToStep(dimensions.height);
  if (width > height * _openAIMaxImageAspectRatio) {
    height = _ceilImageSideToStep(width ~/ _openAIMaxImageAspectRatio);
  } else if (height > width * _openAIMaxImageAspectRatio) {
    width = _ceilImageSideToStep(height ~/ _openAIMaxImageAspectRatio);
  }
  return _ImageDimensions(width, height);
}

int _snapImageSideToStep(int value) {
  final clamped = value.clamp(_openAIMinImageSide, _openAIMaxImageSide).toInt();
  final snapped =
      (clamped / _openAIImageSizeStep).round() * _openAIImageSizeStep;
  return snapped.clamp(_openAIMinImageSide, _openAIMaxImageSide).toInt();
}

int _ceilImageSideToStep(int value) {
  final clamped = value.clamp(_openAIMinImageSide, _openAIMaxImageSide).toInt();
  final snapped =
      ((clamped + _openAIImageSizeStep - 1) ~/ _openAIImageSizeStep) *
      _openAIImageSizeStep;
  return snapped.clamp(_openAIMinImageSide, _openAIMaxImageSide).toInt();
}

String _geminiAspectRatioForDimensions(_ImageDimensions dimensions) {
  final ratio = dimensions.width / dimensions.height;
  var best = _geminiAspectRatioOptions.first;
  var bestDistance = (ratio - best.value).abs();
  for (final option in _geminiAspectRatioOptions.skip(1)) {
    final distance = (ratio - option.value).abs();
    if (distance < bestDistance) {
      best = option;
      bestDistance = distance;
    }
  }
  return best.label;
}

String _imageAspectName(int width, int height) {
  if (width == height) {
    return '方图';
  }
  return width > height ? '横图' : '竖图';
}

class _ImageDimensions {
  const _ImageDimensions(this.width, this.height);

  final int width;
  final int height;

  String get size => '${width}x$height';

  @override
  bool operator ==(Object other) {
    return other is _ImageDimensions &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);
}

class _GeminiAspectRatioOption {
  const _GeminiAspectRatioOption(this.label, this.width, this.height);

  final String label;
  final int width;
  final int height;

  double get value => width / height;
}

const List<_GeminiAspectRatioOption> _geminiAspectRatioOptions =
    <_GeminiAspectRatioOption>[
      _GeminiAspectRatioOption('1:1', 1, 1),
      _GeminiAspectRatioOption('2:3', 2, 3),
      _GeminiAspectRatioOption('3:2', 3, 2),
      _GeminiAspectRatioOption('3:4', 3, 4),
      _GeminiAspectRatioOption('4:3', 4, 3),
      _GeminiAspectRatioOption('4:5', 4, 5),
      _GeminiAspectRatioOption('5:4', 5, 4),
      _GeminiAspectRatioOption('9:16', 9, 16),
      _GeminiAspectRatioOption('16:9', 16, 9),
      _GeminiAspectRatioOption('21:9', 21, 9),
    ];

enum _ImageAspectPreset { square, landscape, portrait, custom }

String _imageAspectPresetLabel(_ImageAspectPreset preset) {
  return switch (preset) {
    _ImageAspectPreset.square => '方图',
    _ImageAspectPreset.landscape => '横图',
    _ImageAspectPreset.portrait => '竖图',
    _ImageAspectPreset.custom => '自定义',
  };
}

class _ImageSizeInput extends StatefulWidget {
  const _ImageSizeInput({
    required this.size,
    required this.providerKind,
    required this.onChanged,
    this.compact = false,
  });

  final String size;
  final ApiProviderKind providerKind;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  State<_ImageSizeInput> createState() => _ImageSizeInputState();
}

class _ImageSizeInputState extends State<_ImageSizeInput> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late _ImageAspectPreset _preset;

  @override
  void initState() {
    super.initState();
    final dimensions = _imageDimensionsFromSize(widget.size);
    _widthController = TextEditingController(text: dimensions.width.toString());
    _heightController = TextEditingController(
      text: dimensions.height.toString(),
    );
    _preset = _presetFromDimensions(dimensions);
  }

  @override
  void didUpdateWidget(covariant _ImageSizeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size == widget.size) {
      return;
    }

    final dimensions = _imageDimensionsFromSize(widget.size);
    final widthText = dimensions.width.toString();
    final heightText = dimensions.height.toString();
    if (_widthController.text != widthText) {
      _widthController.value = TextEditingValue(
        text: widthText,
        selection: TextSelection.collapsed(offset: widthText.length),
      );
    }
    if (_heightController.text != heightText) {
      _heightController.value = TextEditingValue(
        text: heightText,
        selection: TextSelection.collapsed(offset: heightText.length),
      );
    }
    _preset = _presetFromDimensions(dimensions);
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = int.tryParse(_widthController.text);
    final height = int.tryParse(_heightController.text);
    final helperText = _buildHelperText(width, height);

    final aspectPicker = _OptionDropdown<_ImageAspectPreset>(
      label: '画幅',
      value: _preset,
      options: _ImageAspectPreset.values,
      labelBuilder: _imageAspectPresetLabel,
      onChanged: _applyPreset,
    );

    final widthInput = TextField(
      controller: _widthController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(labelText: '宽度'),
      onChanged: (_) => _commitManualSize(),
    );
    final heightInput = TextField(
      controller: _heightController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(labelText: '高度'),
      onChanged: (_) => _commitManualSize(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.compact) ...[
          aspectPicker,
          const SizedBox(height: _fieldGap),
          _ResponsivePair(first: widthInput, second: heightInput),
        ] else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 520) {
                return Column(
                  children: [
                    aspectPicker,
                    const SizedBox(height: _fieldGap),
                    _ResponsivePair(first: widthInput, second: heightInput),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: aspectPicker),
                  const SizedBox(width: _fieldGap),
                  Expanded(child: widthInput),
                  const SizedBox(width: _fieldGap),
                  Expanded(child: heightInput),
                ],
              );
            },
          ),
        const SizedBox(height: 6),
        Text(helperText, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _applyPreset(_ImageAspectPreset preset) {
    final next = switch (preset) {
      _ImageAspectPreset.square => const _ImageDimensions(1024, 1024),
      _ImageAspectPreset.landscape => const _ImageDimensions(1536, 1024),
      _ImageAspectPreset.portrait => const _ImageDimensions(1024, 1536),
      _ImageAspectPreset.custom => _readCurrentDimensions(),
    };

    setState(() {
      _preset = preset;
      _widthController.text = next.width.toString();
      _heightController.text = next.height.toString();
    });
    widget.onChanged(next.size);
  }

  void _commitManualSize() {
    final width = int.tryParse(_widthController.text);
    final height = int.tryParse(_heightController.text);
    if (width == null || height == null || width <= 0 || height <= 0) {
      setState(() => _preset = _ImageAspectPreset.custom);
      return;
    }

    final dimensions = _ImageDimensions(width, height);
    setState(() => _preset = _ImageAspectPreset.custom);
    widget.onChanged(dimensions.size);
  }

  _ImageDimensions _readCurrentDimensions() {
    final width = int.tryParse(_widthController.text);
    final height = int.tryParse(_heightController.text);
    if (width == null || height == null || width <= 0 || height <= 0) {
      return const _ImageDimensions(
        _openAIDefaultImageSide,
        _openAIDefaultImageSide,
      );
    }
    return _ImageDimensions(width, height);
  }

  _ImageAspectPreset _presetFromDimensions(_ImageDimensions dimensions) {
    if (dimensions == const _ImageDimensions(1024, 1024)) {
      return _ImageAspectPreset.square;
    }
    if (dimensions == const _ImageDimensions(1536, 1024)) {
      return _ImageAspectPreset.landscape;
    }
    if (dimensions == const _ImageDimensions(1024, 1536)) {
      return _ImageAspectPreset.portrait;
    }
    return _ImageAspectPreset.custom;
  }

  String _buildHelperText(int? width, int? height) {
    if (width == null || height == null || width <= 0 || height <= 0) {
      return '请输入有效的宽度和高度';
    }

    final dimensions = _ImageDimensions(width, height);
    final aspectName = _imageAspectName(width, height);
    if (widget.providerKind == ApiProviderKind.gemini) {
      final aspectRatio = _geminiAspectRatioForDimensions(dimensions);
      return '$aspectName · Gemini 画幅比例 $aspectRatio';
    }

    final requestDimensions = _normalizeOpenAIImageDimensions(dimensions);
    if (requestDimensions == dimensions) {
      return '$aspectName · 请求尺寸 ${requestDimensions.size}';
    }

    return '$aspectName · 输入值保持 ${dimensions.size}，生成时请求 ${requestDimensions.size}';
  }
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              first,
              const SizedBox(height: _fieldGap),
              second,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: _fieldGap),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class SpriteSheetPreviewData {
  const SpriteSheetPreviewData({
    required this.sheetBytes,
    required this.frames,
    required this.rows,
    required this.columns,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.frameWidth,
    required this.frameHeight,
  });

  final Uint8List sheetBytes;
  final List<Uint8List> frames;
  final int rows;
  final int columns;
  final int sheetWidth;
  final int sheetHeight;
  final int frameWidth;
  final int frameHeight;

  double get sheetAspectRatio => sheetWidth / sheetHeight;
  double get frameAspectRatio => frameWidth / frameHeight;

  Uint8List frameAt(int row, int column) {
    return frames[row * columns + column];
  }

  List<Uint8List> framesForRow(int row) {
    final start = row * columns;
    return frames.sublist(start, start + columns);
  }

  Size frameDisplaySizeForCell(double cellWidth) {
    return Size(cellWidth, cellWidth * frameHeight / frameWidth);
  }

  Size sheetDisplaySizeForCell(double cellWidth) {
    final frameSize = frameDisplaySizeForCell(cellWidth);
    return Size(frameSize.width * columns, frameSize.height * rows);
  }

  Rect rowRectForDisplay(Size displaySize, int row) {
    final rowHeight = displaySize.height / rows;
    return Rect.fromLTWH(0, rowHeight * row, displaySize.width, rowHeight);
  }

  Rect cellRectForDisplay(Size displaySize, int row, int column) {
    final cellWidth = displaySize.width / columns;
    final cellHeight = displaySize.height / rows;
    return Rect.fromLTWH(
      cellWidth * column,
      cellHeight * row,
      cellWidth,
      cellHeight,
    );
  }
}

enum SpriteSheetPreviewSourceMode { auto, frames, sheet }

class SpriteSheetPreviewComposer {
  const SpriteSheetPreviewComposer._();

  static Future<SpriteSheetPreviewData> build({
    required List<GeneratedImage> images,
    required int rows,
    required int columns,
    SpriteSheetPreviewSourceMode sourceMode = SpriteSheetPreviewSourceMode.auto,
  }) async {
    if (rows <= 0 || columns <= 0) {
      throw const ImageGenerationException('切片预览需要有效的行列数。');
    }
    if (images.isEmpty) {
      throw const ImageGenerationException('没有可用于切片预览的图片。');
    }

    if (sourceMode == SpriteSheetPreviewSourceMode.sheet ||
        (sourceMode == SpriteSheetPreviewSourceMode.auto &&
            images.length == 1)) {
      final sheetBytes = await _resolveGeneratedImageBytesForPreview(
        images.single,
      );
      return buildFromSheetBytes(sheetBytes, rows: rows, columns: columns);
    }

    return _buildFromFrames(images, rows: rows, columns: columns);
  }

  static SpriteSheetPreviewData buildFromSheetBytes(
    Uint8List sheetBytes, {
    required int rows,
    required int columns,
  }) {
    if (rows <= 0 || columns <= 0) {
      throw const ImageGenerationException('切片预览需要有效的行列数。');
    }

    return _buildFromSheetBytes(sheetBytes, rows: rows, columns: columns);
  }

  static Future<SpriteSheetPreviewData> _buildFromFrames(
    List<GeneratedImage> images, {
    required int rows,
    required int columns,
  }) async {
    final totalFrames = rows * columns;
    final decodedFrames = <image_lib.Image>[];

    for (final image in images.take(totalFrames)) {
      final bytes = await _resolveGeneratedImageBytesForPreview(image);
      final decodedFrame = image_lib.decodeImage(bytes);
      if (decodedFrame == null) {
        throw const ImageGenerationException('有图片无法解码，无法生成切片预览。');
      }
      decodedFrames.add(decodedFrame);
    }

    if (decodedFrames.isEmpty) {
      throw const ImageGenerationException('没有可用的帧图片。');
    }

    final frameWidth = decodedFrames.first.width;
    final frameHeight = decodedFrames.first.height;
    final sheet = image_lib.Image(
      width: frameWidth * columns,
      height: frameHeight * rows,
    );
    final frames = <Uint8List>[];

    for (var index = 0; index < totalFrames; index++) {
      final rawFrame = index < decodedFrames.length
          ? decodedFrames[index]
          : image_lib.Image(width: frameWidth, height: frameHeight);
      final normalizedFrame =
          rawFrame.width == frameWidth && rawFrame.height == frameHeight
          ? rawFrame
          : image_lib.copyResize(
              rawFrame,
              width: frameWidth,
              height: frameHeight,
            );
      frames.add(Uint8List.fromList(image_lib.encodePng(normalizedFrame)));
      image_lib.compositeImage(
        sheet,
        normalizedFrame,
        dstX: (index % columns) * frameWidth,
        dstY: (index ~/ columns) * frameHeight,
      );
    }

    return SpriteSheetPreviewData(
      sheetBytes: Uint8List.fromList(image_lib.encodePng(sheet)),
      frames: frames,
      rows: rows,
      columns: columns,
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );
  }

  static SpriteSheetPreviewData _buildFromSheetBytes(
    Uint8List sheetBytes, {
    required int rows,
    required int columns,
  }) {
    final sheet = image_lib.decodeImage(sheetBytes);
    if (sheet == null) {
      throw const ImageGenerationException('整张图片无法解码，无法切片。');
    }

    final frameWidth = (sheet.width / columns).floor();
    final frameHeight = (sheet.height / rows).floor();
    if (frameWidth <= 0 || frameHeight <= 0) {
      throw const ImageGenerationException('整张图片尺寸不足，无法按当前行列切片。');
    }

    final frames = <Uint8List>[];
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final frame = image_lib.copyCrop(
          sheet,
          x: column * frameWidth,
          y: row * frameHeight,
          width: frameWidth,
          height: frameHeight,
        );
        frames.add(Uint8List.fromList(image_lib.encodePng(frame)));
      }
    }

    return SpriteSheetPreviewData(
      sheetBytes: sheetBytes,
      frames: frames,
      rows: rows,
      columns: columns,
      sheetWidth: sheet.width,
      sheetHeight: sheet.height,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );
  }
}

class SpriteSheetOutputCache {
  const SpriteSheetOutputCache._();

  static Future<SpriteSheetSaveResult> saveSheetOnly({
    required AppLocalStore store,
    required String groupId,
    required GeneratedImage sourceImage,
    required int rows,
    required int columns,
    required Future<Uint8List> Function(GeneratedImage image) resolveImageBytes,
  }) async {
    final sourceBytes = await resolveImageBytes(sourceImage);
    final previewData = SpriteSheetPreviewComposer.buildFromSheetBytes(
      sourceBytes,
      rows: rows,
      columns: columns,
    );

    final sheetFile = await store.saveGeneratedImageBytes(
      groupId: groupId,
      index: 0,
      bytes: previewData.sheetBytes,
    );
    final cachedSheet = GeneratedImage.file(
      sheetFile.path,
      revisedPrompt: sourceImage.revisedPrompt,
    );

    return SpriteSheetSaveResult(
      sheet: cachedSheet,
      rows: previewData.rows,
      columns: previewData.columns,
      frameWidth: previewData.frameWidth,
      frameHeight: previewData.frameHeight,
    );
  }
}

class SpriteSheetSaveResult {
  const SpriteSheetSaveResult({
    required this.sheet,
    required this.rows,
    required this.columns,
    required this.frameWidth,
    required this.frameHeight,
  });

  final GeneratedImage sheet;
  final int rows;
  final int columns;
  final int frameWidth;
  final int frameHeight;
}

class SpriteSheetEditorComposer {
  const SpriteSheetEditorComposer._();

  static Uint8List replaceFrame({
    required Uint8List sheetBytes,
    required Uint8List patchBytes,
    required int rows,
    required int columns,
    required int frameIndex,
    required SpriteSheetFrameFit fit,
  }) {
    if (rows <= 0 || columns <= 0) {
      throw const ImageGenerationException('替换帧需要有效的行列数。');
    }

    final totalFrames = rows * columns;
    if (frameIndex < 0 || frameIndex >= totalFrames) {
      throw ImageGenerationException('目标帧超出范围：当前只有 $totalFrames 帧。');
    }

    final sheet = image_lib.decodeImage(sheetBytes);
    if (sheet == null) {
      throw const ImageGenerationException('Sprite Sheet 无法解码。');
    }

    final patch = image_lib.decodeImage(patchBytes);
    if (patch == null) {
      throw const ImageGenerationException('单帧图片无法解码。');
    }

    final frameWidth = (sheet.width / columns).floor();
    final frameHeight = (sheet.height / rows).floor();
    if (frameWidth <= 0 || frameHeight <= 0) {
      throw const ImageGenerationException('Sprite Sheet 尺寸不足，无法替换帧。');
    }

    final editedSheet = sheet.clone(noAnimation: true);
    final normalizedPatch = _normalizePatch(
      patch,
      width: frameWidth,
      height: frameHeight,
      fit: fit,
    );
    final row = frameIndex ~/ columns;
    final column = frameIndex % columns;

    image_lib.compositeImage(
      editedSheet,
      normalizedPatch,
      dstX: column * frameWidth,
      dstY: row * frameHeight,
    );

    return Uint8List.fromList(image_lib.encodePng(editedSheet));
  }

  static image_lib.Image _normalizePatch(
    image_lib.Image patch, {
    required int width,
    required int height,
    required SpriteSheetFrameFit fit,
  }) {
    return switch (fit) {
      SpriteSheetFrameFit.stretch => image_lib.copyResize(
        patch,
        width: width,
        height: height,
      ),
      SpriteSheetFrameFit.contain => _containPatch(
        patch,
        width: width,
        height: height,
      ),
      SpriteSheetFrameFit.cover => _coverPatch(
        patch,
        width: width,
        height: height,
      ),
    };
  }

  static image_lib.Image _containPatch(
    image_lib.Image patch, {
    required int width,
    required int height,
  }) {
    final scale = _minDouble(width / patch.width, height / patch.height);
    final resizedWidth = (patch.width * scale).round().clamp(1, width);
    final resizedHeight = (patch.height * scale).round().clamp(1, height);
    final resized = image_lib.copyResize(
      patch,
      width: resizedWidth,
      height: resizedHeight,
    );
    final canvas = image_lib.Image(width: width, height: height, numChannels: 4)
      ..clear(image_lib.ColorRgba8(0, 0, 0, 0));

    image_lib.compositeImage(
      canvas,
      resized,
      dstX: (width - resizedWidth) ~/ 2,
      dstY: (height - resizedHeight) ~/ 2,
    );
    return canvas;
  }

  static image_lib.Image _coverPatch(
    image_lib.Image patch, {
    required int width,
    required int height,
  }) {
    final scale = _maxDouble(width / patch.width, height / patch.height);
    final resizedWidth = (patch.width * scale).round().clamp(width, 1 << 30);
    final resizedHeight = (patch.height * scale).round().clamp(height, 1 << 30);
    final resized = image_lib.copyResize(
      patch,
      width: resizedWidth,
      height: resizedHeight,
    );

    return image_lib.copyCrop(
      resized,
      x: ((resizedWidth - width) / 2).floor(),
      y: ((resizedHeight - height) / 2).floor(),
      width: width,
      height: height,
    );
  }
}

double _minDouble(double a, double b) => a < b ? a : b;

double _maxDouble(double a, double b) => a > b ? a : b;

Future<Uint8List> _resolveGeneratedImageBytesForPreview(
  GeneratedImage image,
) async {
  if (image.bytes != null) {
    return image.bytes!;
  }

  if (image.filePath != null) {
    return File(image.filePath!).readAsBytes();
  }

  if (image.url != null) {
    final response = await http
        .get(Uri.parse(image.url!))
        .timeout(const Duration(minutes: 2));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ImageGenerationException(
        '切片预览下载图片失败：HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}',
      );
    }
    return response.bodyBytes;
  }

  throw const ImageGenerationException('图片没有可供切片预览的内容。');
}

class OpenAICompatibleImageClient {
  OpenAICompatibleImageClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<OpenAIImageResponse> generate(
    OpenAIImageRequest request, {
    ValueChanged<ImageRequestDebugRecord>? onDebugRecord,
  }) async {
    final debugRecord = ImageRequestDebugRecord.fromRequest(request);
    void publishDebugRecord([
      http.Response? response,
      Map<String, dynamic>? decodedResponse,
    ]) {
      onDebugRecord?.call(
        debugRecord.copyWith(
          response: response,
          decodedResponse: decodedResponse,
        ),
      );
    }

    publishDebugRecord();
    final response = request.providerKind == ApiProviderKind.gemini
        ? await _postGeminiGenerateContent(request)
        : request.hasTemplateImage
        ? await _postImageEdit(request)
        : await _postImageGeneration(request);

    publishDebugRecord(response);
    final decoded = _decodeJsonObject(
      response.bodyBytes,
      statusCode: response.statusCode,
      reasonPhrase: response.reasonPhrase,
    );
    publishDebugRecord(response, decoded);
    final responseErrorMessage = _extractErrorMessage(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ImageGenerationException(
        responseErrorMessage ??
            '请求失败：HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}',
      );
    }

    if (responseErrorMessage != null) {
      throw ImageGenerationException(responseErrorMessage);
    }

    if (request.providerKind == ApiProviderKind.gemini) {
      return OpenAIImageResponse(images: _parseGeminiImages(decoded));
    }

    final data = decoded['data'];
    if (data is! List || data.isEmpty) {
      throw const ImageGenerationException('接口没有返回图片数据。');
    }

    final images = <GeneratedImage>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final nestedError = item['error'];
      if (nestedError is Map<String, dynamic>) {
        final message = nestedError['message'];
        if (message is String && message.trim().isNotEmpty) {
          throw ImageGenerationException(message);
        }
      }

      final message = item['message'];
      if (message is String &&
          message.trim().isNotEmpty &&
          item['b64_json'] == null &&
          item['url'] == null) {
        throw ImageGenerationException(message);
      }

      final b64Json = item['b64_json'];
      final url = item['url'];
      final revisedPrompt = item['revised_prompt'];

      if (b64Json is String && b64Json.trim().isNotEmpty) {
        images.add(
          GeneratedImage.bytes(
            _decodeBase64Image(b64Json),
            revisedPrompt: revisedPrompt is String ? revisedPrompt : null,
          ),
        );
        continue;
      }

      if (url is String && url.trim().isNotEmpty) {
        images.add(
          GeneratedImage.url(
            url,
            revisedPrompt: revisedPrompt is String ? revisedPrompt : null,
          ),
        );
      }
    }

    if (images.isEmpty) {
      throw const ImageGenerationException('接口返回了 data，但未包含 b64_json 或 url。');
    }

    return OpenAIImageResponse(images: images);
  }

  Future<http.Response> _postGeminiGenerateContent(
    OpenAIImageRequest request,
  ) async {
    return _httpClient
        .post(
          request.endpoint,
          headers: {
            'x-goog-api-key': request.apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(await request.toGeminiJson()),
        )
        .timeout(const Duration(minutes: 2));
  }

  Future<http.Response> _postImageGeneration(OpenAIImageRequest request) {
    return _httpClient
        .post(
          request.endpoint,
          headers: {
            'Authorization': 'Bearer ${request.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(minutes: 2));
  }

  Future<http.Response> _postImageEdit(OpenAIImageRequest request) async {
    final multipartRequest = http.MultipartRequest('POST', request.endpoint)
      ..headers['Authorization'] = 'Bearer ${request.apiKey}'
      ..fields.addAll(request.toMultipartFields())
      ..files.add(
        await http.MultipartFile.fromPath('image', request.templateImagePath!),
      );

    final streamedResponse = await _httpClient
        .send(multipartRequest)
        .timeout(const Duration(minutes: 2));
    return http.Response.fromStream(
      streamedResponse,
    ).timeout(const Duration(minutes: 2));
  }

  Future<Uint8List> resolveImageBytes(GeneratedImage image) async {
    if (image.bytes != null) {
      return image.bytes!;
    }

    if (image.filePath != null) {
      return File(image.filePath!).readAsBytes();
    }

    if (image.url != null) {
      final response = await _httpClient
          .get(Uri.parse(image.url!))
          .timeout(const Duration(minutes: 2));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ImageGenerationException(
          '图片下载失败：HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}',
        );
      }
      return response.bodyBytes;
    }

    throw const ImageGenerationException('图片没有可用的二进制内容。');
  }

  void close() => _httpClient.close();

  static Map<String, dynamic> _decodeJsonObject(
    List<int> bodyBytes, {
    required int statusCode,
    String? reasonPhrase,
  }) {
    final body = utf8.decode(bodyBytes, allowMalformed: true);
    final decoded = _tryDecodeJson(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    final responseSummary = statusCode == 0
        ? ''
        : 'HTTP $statusCode ${reasonPhrase ?? ''}'.trim();
    final bodyPreview = _compactResponsePreview(body);
    throw ImageGenerationException(
      [
        if (responseSummary.isNotEmpty) '接口返回异常：$responseSummary。',
        '接口返回的不是 JSON 数据，可能是 Base URL 填错、网关/登录页拦截，或服务端返回了 HTML。',
        if (bodyPreview.isNotEmpty) '响应开头：$bodyPreview',
      ].join('\n'),
    );
  }

  static dynamic _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static String _compactResponsePreview(String body) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 120) {
      return normalized;
    }

    return '${normalized.substring(0, 120)}...';
  }

  static Uint8List _decodeBase64Image(String value) {
    final normalized = value.contains(',') ? value.split(',').last : value;
    return base64Decode(normalized.trim());
  }

  static String? _extractErrorMessage(Map<String, dynamic> decoded) {
    final error = decoded['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    final message = decoded['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return null;
  }

  static List<GeneratedImage> _parseGeminiImages(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const ImageGenerationException('Gemini 接口没有返回候选结果。');
    }

    final images = <GeneratedImage>[];
    final textParts = <String>[];
    for (final candidate in candidates) {
      if (candidate is! Map<String, dynamic>) {
        continue;
      }

      final content = candidate['content'];
      if (content is! Map<String, dynamic>) {
        continue;
      }

      final parts = content['parts'];
      if (parts is! List) {
        continue;
      }

      for (final part in parts) {
        if (part is! Map<String, dynamic>) {
          continue;
        }

        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) {
          textParts.add(text.trim());
        }

        final inlineData = part['inlineData'] ?? part['inline_data'];
        if (inlineData is! Map<String, dynamic>) {
          continue;
        }

        final mimeType =
            inlineData['mimeType'] as String? ??
            inlineData['mime_type'] as String? ??
            '';
        final data = inlineData['data'];
        if (data is String &&
            data.trim().isNotEmpty &&
            mimeType.toLowerCase().startsWith('image/')) {
          final revisedPrompt = textParts.join('\n\n').trim();
          images.add(
            GeneratedImage.bytes(
              _decodeBase64Image(data),
              revisedPrompt: revisedPrompt.isEmpty ? null : revisedPrompt,
            ),
          );
        }
      }
    }

    if (images.isEmpty) {
      final textPreview = textParts.join('\n\n').trim();
      throw ImageGenerationException(
        textPreview.isEmpty
            ? 'Gemini 接口返回了候选结果，但没有包含图片 inlineData。'
            : 'Gemini 没有返回图片，只返回了文本：$textPreview',
      );
    }

    return images;
  }
}

class OpenAIImageRequest {
  const OpenAIImageRequest({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
    this.advancedSettings = const ImageAdvancedSettings(),
    this.templateImagePath,
    this.providerKind = ApiProviderKind.official,
  });

  final String baseUrl;
  final String apiKey;
  final String model;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final String? templateImagePath;
  final ApiProviderKind providerKind;

  bool get hasTemplateImage =>
      templateImagePath != null && templateImagePath!.trim().isNotEmpty;

  Uri get endpoint {
    if (providerKind == ApiProviderKind.gemini) {
      return geminiEndpoint;
    }

    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);
    final imageEndpoint = hasTemplateImage
        ? '/images/edits'
        : '/images/generations';
    final normalizedRoot = normalizedBaseUrl.replaceFirst(
      RegExp(r'/images/(generations|edits)$'),
      '',
    );

    if (normalizedRoot != normalizedBaseUrl) {
      return Uri.parse('$normalizedRoot$imageEndpoint');
    }

    return Uri.parse('$normalizedBaseUrl$imageEndpoint');
  }

  Uri get geminiEndpoint {
    final normalizedBaseUrl = _normalizeGeminiBaseUrl(baseUrl);
    final normalizedRoot = normalizedBaseUrl.replaceFirst(
      RegExp(r'/models/[^/]+:generateContent$'),
      '',
    );

    return Uri.parse(
      '$normalizedRoot/models/${Uri.encodeComponent(_effectiveGeminiModel)}:generateContent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': _effectiveModel,
      'prompt': _mergedPrompt,
      'size': _effectiveRequestSize,
      'n': imageCount,
      ...advancedSettings.toRequestFields(
        hasTemplateImage: hasTemplateImage,
        providerKind: providerKind,
      ),
    };
  }

  Map<String, dynamic> toDebugJson() {
    if (providerKind == ApiProviderKind.gemini) {
      return {
        'endpoint': endpoint.toString(),
        'method': 'POST JSON (Gemini generateContent)',
        'providerKind': _serializeApiProviderKind(providerKind),
        'apiKey': apiKey.trim().isEmpty ? '未填写' : '已填写（已隐藏）',
        if (hasTemplateImage) 'templateImagePath': templateImagePath,
        'jsonBody': toGeminiDebugJson(),
      };
    }

    return {
      'endpoint': endpoint.toString(),
      'method': hasTemplateImage ? 'POST multipart/form-data' : 'POST JSON',
      'providerKind': _serializeApiProviderKind(providerKind),
      'apiKey': apiKey.trim().isEmpty ? '未填写' : '已填写（已隐藏）',
      if (hasTemplateImage) 'templateImagePath': templateImagePath,
      if (hasTemplateImage)
        'multipartFields': toMultipartFields()
      else
        'jsonBody': toJson(),
    };
  }

  Map<String, String> toMultipartFields() {
    return {
      'model': _effectiveModel,
      'prompt': _mergedPrompt,
      'size': _effectiveRequestSize,
      'n': imageCount.toString(),
      ...advancedSettings.toMultipartFields(
        hasTemplateImage: hasTemplateImage,
        providerKind: providerKind,
      ),
    };
  }

  Future<Map<String, dynamic>> toGeminiJson() async {
    final parts = <Map<String, dynamic>>[
      {'text': _geminiPrompt},
    ];

    if (hasTemplateImage) {
      final path = templateImagePath!.trim();
      parts.add({
        'inlineData': {
          'mimeType': _mimeTypeForPath(path),
          'data': base64Encode(await File(path).readAsBytes()),
        },
      });
    }

    return {
      'contents': [
        {'role': 'user', 'parts': parts},
      ],
      'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
        'responseFormat': {
          'image': {'aspectRatio': _geminiAspectRatio},
        },
      },
    };
  }

  Map<String, dynamic> toGeminiDebugJson() {
    return {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': _geminiPrompt},
            if (hasTemplateImage)
              {
                'inlineData': {
                  'mimeType': _mimeTypeForPath(templateImagePath!.trim()),
                  'data': '已省略（本地参考图）',
                },
              },
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
        'responseFormat': {
          'image': {'aspectRatio': _geminiAspectRatio},
        },
      },
    };
  }

  String get _effectiveModel => model.isEmpty ? 'gpt-image-2' : model;

  String get _effectiveRequestSize =>
      _requestSizeForProvider(size, providerKind);

  String get _effectiveGeminiModel {
    final normalized = model.trim().replaceFirst(RegExp(r'^models/'), '');
    return normalized.isEmpty
        ? _defaultModelForProviderKind(ApiProviderKind.gemini)
        : normalized;
  }

  String get _mergedPrompt {
    final negative = negativePrompt.trim();
    if (negative.isEmpty) {
      return prompt;
    }

    return '$prompt\n\nAvoid: $negative';
  }

  String get _geminiPrompt => _mergedPrompt;

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    final fallback = trimmed.isEmpty ? 'https://api.openai.com/v1' : trimmed;
    return fallback.replaceFirst(RegExp(r'/+$'), '');
  }

  static String _normalizeGeminiBaseUrl(String value) {
    final trimmed = value.trim();
    final fallback = trimmed.isEmpty
        ? _defaultBaseUrlForProviderKind(ApiProviderKind.gemini)
        : trimmed;
    return fallback.replaceFirst(RegExp(r'/+$'), '');
  }

  String get _geminiAspectRatio {
    return _geminiAspectRatioForDimensions(_imageDimensionsFromSize(size));
  }

  static String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/png';
  }
}

class OpenAIImageResponse {
  const OpenAIImageResponse({required this.images});

  final List<GeneratedImage> images;
}

class ImageRequestDebugRecord {
  const ImageRequestDebugRecord({
    required this.createdAt,
    required this.request,
    this.statusCode,
    this.reasonPhrase,
    this.responseHeaders = const {},
    this.responseBody,
    this.decodedResponse,
  });

  factory ImageRequestDebugRecord.fromRequest(OpenAIImageRequest request) {
    return ImageRequestDebugRecord(
      createdAt: DateTime.now(),
      request: request.toDebugJson(),
    );
  }

  final DateTime createdAt;
  final Map<String, dynamic> request;
  final int? statusCode;
  final String? reasonPhrase;
  final Map<String, String> responseHeaders;
  final String? responseBody;
  final Map<String, dynamic>? decodedResponse;

  ImageRequestDebugRecord copyWith({
    http.Response? response,
    Map<String, dynamic>? decodedResponse,
  }) {
    return ImageRequestDebugRecord(
      createdAt: createdAt,
      request: request,
      statusCode: response?.statusCode ?? statusCode,
      reasonPhrase: response?.reasonPhrase ?? reasonPhrase,
      responseHeaders: response?.headers ?? responseHeaders,
      responseBody: response == null
          ? responseBody
          : utf8.decode(response.bodyBytes, allowMalformed: true),
      decodedResponse: decodedResponse ?? this.decodedResponse,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'request': request,
      'response': {
        'statusCode': statusCode,
        'reasonPhrase': reasonPhrase,
        'headers': responseHeaders,
        'body': responseBody,
        if (decodedResponse != null) 'json': decodedResponse,
      },
    };
  }

  String get formattedJson {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}

class GeneratedImage {
  const GeneratedImage._({
    required this.bytes,
    required this.url,
    required this.filePath,
    required this.revisedPrompt,
  });

  factory GeneratedImage.bytes(Uint8List bytes, {String? revisedPrompt}) {
    return GeneratedImage._(
      bytes: bytes,
      url: null,
      filePath: null,
      revisedPrompt: revisedPrompt,
    );
  }

  factory GeneratedImage.url(String url, {String? revisedPrompt}) {
    return GeneratedImage._(
      bytes: null,
      url: url,
      filePath: null,
      revisedPrompt: revisedPrompt,
    );
  }

  factory GeneratedImage.file(String filePath, {String? revisedPrompt}) {
    return GeneratedImage._(
      bytes: null,
      url: null,
      filePath: filePath,
      revisedPrompt: revisedPrompt,
    );
  }

  final Uint8List? bytes;
  final String? url;
  final String? filePath;
  final String? revisedPrompt;
}

class ImageLibraryItem {
  const ImageLibraryItem({
    required this.id,
    required this.path,
    required this.createdAt,
    required this.kind,
    required this.title,
    required this.source,
    this.note = '',
    this.prompt,
    this.generation,
    this.groupId,
    this.rows,
    this.columns,
    this.frameWidth,
    this.frameHeight,
    this.frameIndex,
  });

  factory ImageLibraryItem.fromJson(Map<String, dynamic> json) {
    return ImageLibraryItem(
      id: json['id'] as String? ?? newId(),
      path: json['path'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      kind: switch (json['kind']) {
        'spriteSheet' => ImageAssetKind.spriteSheet,
        'spriteFrame' => ImageAssetKind.spriteFrame,
        'editedImage' => ImageAssetKind.editedImage,
        'gif' => ImageAssetKind.gif,
        _ => ImageAssetKind.generatedImage,
      },
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? '',
      note: json['note'] as String? ?? '',
      prompt: json['prompt'] as String?,
      generation: _generationFromJson(json['generation']),
      groupId: json['groupId'] as String?,
      rows: (json['rows'] as num?)?.toInt(),
      columns: (json['columns'] as num?)?.toInt(),
      frameWidth: (json['frameWidth'] as num?)?.toInt(),
      frameHeight: (json['frameHeight'] as num?)?.toInt(),
      frameIndex: (json['frameIndex'] as num?)?.toInt(),
    );
  }

  static String newId({int seed = 0}) {
    return '${DateTime.now().microsecondsSinceEpoch}_$seed';
  }

  static GenerationSnapshot? _generationFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }

    return GenerationSnapshot.fromJson(Map<String, dynamic>.from(value));
  }

  final String id;
  final String path;
  final DateTime createdAt;
  final ImageAssetKind kind;
  final String title;
  final String source;
  final String note;
  final String? prompt;
  final GenerationSnapshot? generation;
  final String? groupId;
  final int? rows;
  final int? columns;
  final int? frameWidth;
  final int? frameHeight;
  final int? frameIndex;

  bool get existsSync => File(path).existsSync();
  bool get canUseAsSpriteSheet =>
      kind == ImageAssetKind.spriteSheet || kind == ImageAssetKind.editedImage;
  bool get isSpriteSheetWithMetadata =>
      kind == ImageAssetKind.spriteSheet &&
      rows != null &&
      columns != null &&
      rows! > 0 &&
      columns! > 0;
  int get totalFrameCount => isSpriteSheetWithMetadata ? rows! * columns! : 0;
  bool get isImageFile {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.gif');
  }

  String get displayTitle => title.isEmpty ? _fileNameFromPath(path) : title;

  ImageLibraryItem copyWith({
    String? title,
    String? note,
    int? rows,
    int? columns,
    int? frameWidth,
    int? frameHeight,
    int? frameIndex,
    GenerationSnapshot? generation,
  }) {
    return ImageLibraryItem(
      id: id,
      path: path,
      createdAt: createdAt,
      kind: kind,
      title: title ?? this.title,
      source: source,
      note: note ?? this.note,
      prompt: prompt,
      generation: generation ?? this.generation,
      groupId: groupId,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      frameWidth: frameWidth ?? this.frameWidth,
      frameHeight: frameHeight ?? this.frameHeight,
      frameIndex: frameIndex ?? this.frameIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'createdAt': createdAt.toIso8601String(),
      'kind': kind.name,
      'title': title,
      'source': source,
      'note': note,
      'prompt': prompt,
      if (generation != null) 'generation': generation!.toJson(),
      'groupId': groupId,
      if (rows != null) 'rows': rows,
      if (columns != null) 'columns': columns,
      if (frameWidth != null) 'frameWidth': frameWidth,
      if (frameHeight != null) 'frameHeight': frameHeight,
      if (frameIndex != null) 'frameIndex': frameIndex,
    };
  }
}

class ImageGenerationException implements Exception {
  const ImageGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GifComposerException implements Exception {
  const GifComposerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GifComposer {
  const GifComposer._();

  static Future<String> compose({
    required List<GifSourceFrame> frames,
    required String outputPath,
    required int loopCount,
    required GifPlaybackMode playbackMode,
  }) async {
    if (frames.length < 2) {
      throw const GifComposerException('至少需要 2 张图片。');
    }

    final orderedFrames = expandGifFrameSequence(frames, playbackMode);
    final decodedFrames = <({image_lib.Image image, int delayMs})>[];
    for (final sourceFrame in orderedFrames) {
      final inline = sourceFrame.inlineBytes;
      final bytes = inline ?? await File(sourceFrame.path).readAsBytes();
      final frame = image_lib.decodeImage(bytes);
      if (frame == null) {
        final label =
            sourceFrame.label ?? _fileNameFromPath(sourceFrame.path);
        throw GifComposerException('无法解析图片：$label');
      }
      decodedFrames.add((image: frame, delayMs: sourceFrame.delayMs));
    }

    final baseWidth = decodedFrames.first.image.width;
    final baseHeight = decodedFrames.first.image.height;
    final encoder = image_lib.GifEncoder(
      delay: (decodedFrames.first.delayMs / 10).round().clamp(1, 65535),
      repeat: loopCount,
    );

    for (final frame in decodedFrames) {
      final normalizedFrame =
          frame.image.width == baseWidth && frame.image.height == baseHeight
          ? frame.image
          : image_lib.copyResize(
              frame.image,
              width: baseWidth,
              height: baseHeight,
              maintainAspect: true,
            );
      encoder.addFrame(
        normalizedFrame,
        duration: (frame.delayMs / 10).round().clamp(1, 65535),
      );
    }

    final bytes = encoder.finish();
    if (bytes == null || bytes.isEmpty) {
      throw const GifComposerException('GIF 编码没有输出内容。');
    }

    await File(outputPath).writeAsBytes(bytes, flush: true);
    return outputPath;
  }
}

class ApiConfig {
  const ApiConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.providerKind = ApiProviderKind.compatible,
  });

  factory ApiConfig.defaults() {
    return const ApiConfig(
      id: 'default',
      name: '默认配置',
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      model: 'gpt-image-2',
      providerKind: ApiProviderKind.official,
    );
  }

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    final defaults = ApiConfig.defaults();
    final baseUrl = json['baseUrl'] as String? ?? defaults.baseUrl;
    return ApiConfig(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? defaults.name,
      baseUrl: baseUrl,
      apiKey: json['apiKey'] as String? ?? defaults.apiKey,
      model: json['model'] as String? ?? defaults.model,
      providerKind: _parseApiProviderKind(
        json['providerKind'],
        fallback: defaults.providerKind,
      ),
    );
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String model;
  final ApiProviderKind providerKind;

  ApiConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    ApiProviderKind? providerKind,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      providerKind: providerKind ?? this.providerKind,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'providerKind': _serializeApiProviderKind(providerKind),
    };
  }
}

class AppSettings {
  const AppSettings({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
    this.advancedSettings = const ImageAdvancedSettings(),
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      model: 'gpt-image-2',
      prompt:
          'A clean product render of a futuristic camera on a neutral background',
      negativePrompt: '',
      size: '1024x1024',
      imageCount: 1,
      advancedSettings: ImageAdvancedSettings(),
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      baseUrl: json['baseUrl'] as String? ?? defaults.baseUrl,
      apiKey: json['apiKey'] as String? ?? defaults.apiKey,
      model: json['model'] as String? ?? defaults.model,
      prompt: json['prompt'] as String? ?? defaults.prompt,
      negativePrompt:
          json['negativePrompt'] as String? ?? defaults.negativePrompt,
      size: json['size'] as String? ?? defaults.size,
      imageCount: (json['imageCount'] as num?)?.toInt() ?? defaults.imageCount,
      advancedSettings: ImageAdvancedSettings.fromJson(json),
    );
  }

  final String baseUrl;
  final String apiKey;
  final String model;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'size': size,
      'imageCount': imageCount,
      ...advancedSettings.toJson(),
    };
  }
}

class GenerationSnapshot {
  const GenerationSnapshot({
    required this.id,
    required this.createdAt,
    required this.baseUrl,
    required this.model,
    required this.providerKind,
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
    required this.resultCount,
    this.advancedSettings = const ImageAdvancedSettings(),
  });

  factory GenerationSnapshot.fromJson(Map<String, dynamic> json) {
    return GenerationSnapshot(
      id: json['id'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      baseUrl: json['baseUrl'] as String? ?? '',
      model: json['model'] as String? ?? '',
      providerKind: _parseApiProviderKind(
        json['providerKind'],
        fallback: ApiProviderKind.official,
      ),
      prompt: json['prompt'] as String? ?? '',
      negativePrompt: json['negativePrompt'] as String? ?? '',
      size: json['size'] as String? ?? '',
      imageCount: (json['imageCount'] as num?)?.toInt() ?? 1,
      resultCount: (json['resultCount'] as num?)?.toInt() ?? 0,
      advancedSettings: ImageAdvancedSettings.fromJson(json),
    );
  }

  final String id;
  final DateTime createdAt;
  final String baseUrl;
  final String model;
  final ApiProviderKind providerKind;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final int resultCount;
  final ImageAdvancedSettings advancedSettings;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'baseUrl': baseUrl,
      'model': model,
      'providerKind': _serializeApiProviderKind(providerKind),
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'size': size,
      'imageCount': imageCount,
      'resultCount': resultCount,
      ...advancedSettings.toJson(),
    };
  }
}

class AppLocalStore {
  AppLocalStore({Directory? baseDirectoryOverride})
    : _baseDirectoryOverride = baseDirectoryOverride;

  final Directory? _baseDirectoryOverride;

  static const String _baseUrlKey = 'settings.baseUrl';
  static const String _apiKeyKey = 'settings.apiKey';
  static const String _modelKey = 'settings.model';
  static const String _promptKey = 'settings.prompt';
  static const String _negativePromptKey = 'settings.negativePrompt';
  static const String _sizeKey = 'settings.size';
  static const String _imageCountKey = 'settings.imageCount';
  static const String _apiConfigsKey = 'apiConfigs.entries';
  static const String _selectedApiConfigIdKey = 'apiConfigs.selectedId';
  static const String _imageLibraryKey = 'imageLibrary.entries';
  static const int _maxImageLibraryEntries = 200;

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    return AppSettings(
      baseUrl: prefs.getString(_baseUrlKey) ?? defaults.baseUrl,
      apiKey: prefs.getString(_apiKeyKey) ?? defaults.apiKey,
      model: prefs.getString(_modelKey) ?? defaults.model,
      prompt: prefs.getString(_promptKey) ?? defaults.prompt,
      negativePrompt:
          prefs.getString(_negativePromptKey) ?? defaults.negativePrompt,
      size: prefs.getString(_sizeKey) ?? defaults.size,
      imageCount: prefs.getInt(_imageCountKey) ?? defaults.imageCount,
      advancedSettings: ImageAdvancedSettings(
        quality:
            prefs.getString('settings.quality') ??
            defaults.advancedSettings.quality,
        background:
            prefs.getString('settings.background') ??
            defaults.advancedSettings.background,
        outputFormat:
            prefs.getString('settings.outputFormat') ??
            defaults.advancedSettings.outputFormat,
        outputCompression:
            prefs.getInt('settings.outputCompression') ??
            defaults.advancedSettings.outputCompression,
        moderation:
            prefs.getString('settings.moderation') ??
            defaults.advancedSettings.moderation,
        user:
            prefs.getString('settings.user') ?? defaults.advancedSettings.user,
        inputFidelity:
            prefs.getString('settings.inputFidelity') ??
            defaults.advancedSettings.inputFidelity,
      ),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, settings.baseUrl);
    await prefs.setString(_apiKeyKey, settings.apiKey);
    await prefs.setString(_modelKey, settings.model);
    await prefs.setString(_promptKey, settings.prompt);
    await prefs.setString(_negativePromptKey, settings.negativePrompt);
    await prefs.setString(_sizeKey, settings.size);
    await prefs.setInt(_imageCountKey, settings.imageCount);
    await prefs.setString(
      'settings.quality',
      settings.advancedSettings.quality,
    );
    await prefs.setString(
      'settings.background',
      settings.advancedSettings.background,
    );
    await prefs.setString(
      'settings.outputFormat',
      settings.advancedSettings.outputFormat,
    );
    await prefs.setInt(
      'settings.outputCompression',
      settings.advancedSettings.outputCompression,
    );
    await prefs.setString(
      'settings.moderation',
      settings.advancedSettings.moderation,
    );
    await prefs.setString('settings.user', settings.advancedSettings.user);
    await prefs.setString(
      'settings.inputFidelity',
      settings.advancedSettings.inputFidelity,
    );
  }

  Future<List<ApiConfig>> loadApiConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_apiConfigsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((entry) => ApiConfig.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  Future<void> saveApiConfigs(List<ApiConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _apiConfigsKey,
      jsonEncode(configs.map((config) => config.toJson()).toList()),
    );
  }

  Future<String?> loadSelectedApiConfigId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedApiConfigIdKey);
  }

  Future<void> saveSelectedApiConfigId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedApiConfigIdKey, id);
  }

  Future<List<ImageLibraryItem>> loadImageLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_imageLibraryKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final items = decoded
        .whereType<Map>()
        .map(
          (entry) =>
              ImageLibraryItem.fromJson(Map<String, dynamic>.from(entry)),
        )
        .where((item) => item.path.isNotEmpty)
        .toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(_maxImageLibraryEntries).toList();
  }

  Future<void> saveImageLibrary(List<ImageLibraryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = items.take(_maxImageLibraryEntries).toList();
    await prefs.setString(
      _imageLibraryKey,
      jsonEncode(normalized.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> addImageLibraryItems(List<ImageLibraryItem> items) async {
    if (items.isEmpty) {
      return;
    }

    final library = await loadImageLibrary();
    await saveImageLibrary([...items, ...library]);
  }

  Future<Directory> ensureGeneratedImagesDirectory() async {
    Directory baseDirectory;
    final baseDirectoryOverride = _baseDirectoryOverride;
    if (baseDirectoryOverride != null) {
      baseDirectory = baseDirectoryOverride;
    } else {
      try {
        baseDirectory = await getApplicationSupportDirectory();
      } catch (_) {
        baseDirectory = Directory.systemTemp;
      }
    }
    final directory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}generated-images',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<File> saveGeneratedImageBytes({
    required String groupId,
    required int index,
    required Uint8List bytes,
  }) async {
    final directory = await ensureGeneratedImagesDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}${groupId}_${(index + 1).toString().padLeft(2, '0')}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> createGeneratedGifFile() async {
    final directory = await ensureGeneratedImagesDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}gif_${DateTime.now().microsecondsSinceEpoch}.gif',
    );
  }

  Future<Directory> ensureEphemeralDirectory() async {
    Directory baseDirectory;
    final baseDirectoryOverride = _baseDirectoryOverride;
    if (baseDirectoryOverride != null) {
      baseDirectory = baseDirectoryOverride;
    } else {
      try {
        baseDirectory = await getApplicationSupportDirectory();
      } catch (_) {
        baseDirectory = Directory.systemTemp;
      }
    }
    final directory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}ephemeral',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> saveEphemeralBytes({
    required String prefix,
    required Uint8List bytes,
  }) async {
    final directory = await ensureEphemeralDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> createGeneratedSpriteSheetFile({
    required int rows,
    required int columns,
  }) async {
    final directory = await ensureGeneratedImagesDirectory();
    final timestamp = DateTime.now().toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final dateStamp =
        '${timestamp.year}${twoDigits(timestamp.month)}${twoDigits(timestamp.day)}'
        '_${twoDigits(timestamp.hour)}${twoDigits(timestamp.minute)}${twoDigits(timestamp.second)}';
    return File(
      '${directory.path}${Platform.pathSeparator}'
      'sheet_${rows}x${columns}_$dateStamp.png',
    );
  }
}
