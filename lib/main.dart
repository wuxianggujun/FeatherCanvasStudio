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
  apiSettings,
}

const double _workspacePadding = 12;
const double _sectionGap = 12;
const double _fieldGap = 12;
const double _layoutGap = 12;
const double _panelPadding = 14;
const List<int> _gifFrameDelayOptions = <int>[60, 80, 100, 120, 160, 200, 300];

enum GifPlaybackMode { normal, reverse, pingPong }

enum SpriteSheetFrameFit { contain, cover, stretch }

enum _ApiConfigSaveStatus { saved, pending, saving, failed }

class GifSourceFrame {
  const GifSourceFrame({
    required this.id,
    required this.path,
    required this.delayMs,
  });

  factory GifSourceFrame.fromPath(
    String path, {
    required int delayMs,
    required int seed,
  }) {
    return GifSourceFrame(
      id: '${DateTime.now().microsecondsSinceEpoch}_$seed',
      path: path,
      delayMs: delayMs,
    );
  }

  final String id;
  final String path;
  final int delayMs;

  GifSourceFrame copyWith({String? id, String? path, int? delayMs}) {
    return GifSourceFrame(
      id: id ?? this.id,
      path: path ?? this.path,
      delayMs: delayMs ?? this.delayMs,
    );
  }
}

class _FeatherCanvasHomePageState extends State<FeatherCanvasHomePage> {
  static const List<String> _sizes = <String>[
    'auto',
    '1024x1024',
    '1024x1536',
    '1536x1024',
    '2048x2048',
    '2048x3072',
    '3072x2048',
    '4096x4096',
    '4096x6144',
    '6144x4096',
  ];

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

  final OpenAICompatibleImageClient _client = OpenAICompatibleImageClient();
  final AppLocalStore _store = AppLocalStore();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _historySectionKey = GlobalKey();
  String? _generatedImagesDirectoryPath;

  _WorkspaceFeature _selectedFeature = _WorkspaceFeature.imageGeneration;
  String _size = _defaultSettings.size;
  int _imageCount = _defaultSettings.imageCount;
  int _animationDirectionCount = 4;
  int _animationRows = 4;
  int _animationColumns = 4;
  int _editorDirectionCount = 4;
  int _editorRows = 4;
  int _editorColumns = 4;
  int _editorTargetFrameIndex = 0;
  SpriteSheetFrameFit _editorFrameFit = SpriteSheetFrameFit.contain;
  bool _isGenerating = false;
  bool _isGeneratingAnimation = false;
  bool _isComposingGif = false;
  bool _isReplacingEditorFrame = false;
  bool _showApiKey = false;
  bool _isBootstrapping = true;
  bool _isRestoringState = false;
  String? _errorMessage;
  String? _animationErrorMessage;
  List<ApiConfig> _apiConfigs = const [];
  String? _selectedApiConfigId;
  List<GeneratedImage> _generatedImages = const [];
  List<GeneratedImage> _animationFrames = const [];
  List<GenerationHistoryEntry> _history = const [];
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

    _apiConfigNameController.addListener(_scheduleApiConfigSave);
    _baseUrlController.addListener(_scheduleApiConfigSave);
    _apiKeyController.addListener(_scheduleApiConfigSave);
    _modelController.addListener(_scheduleApiConfigSave);
    _promptController.addListener(_scheduleSettingsSave);
    _negativePromptController.addListener(_scheduleSettingsSave);

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
    _animationPromptController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final settings = await _store.loadSettings();
    final storedApiConfigs = await _store.loadApiConfigs();
    final storedSelectedApiConfigId = await _store.loadSelectedApiConfigId();
    final history = await _store.loadHistory();

    if (!mounted) {
      return;
    }

    final apiConfigs = storedApiConfigs.isEmpty
        ? [ApiConfig.fromSettings(settings)]
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

    setState(() {
      _apiConfigs = apiConfigs;
      _selectedApiConfigId = selectedApiConfig.id;
      _size = settings.size;
      _imageCount = settings.imageCount;
      _history = history;
      _isBootstrapping = false;
    });
    _isRestoringState = false;
    await _store.saveApiConfigs(apiConfigs);
    await _store.saveSelectedApiConfigId(selectedApiConfig.id);
    unawaited(_loadGeneratedImagesDirectory());
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

    if (_selectedFeature == _WorkspaceFeature.apiSettings) {
      _apiConfigSaveDebounce?.cancel();
      await _saveCurrentApiConfig();
    }

    if (!mounted) {
      return;
    }

    setState(() => _selectedFeature = feature);
  }

  Future<ApiConfig> _prepareSelectedApiConfigForRequest() async {
    _apiConfigSaveDebounce?.cancel();
    await _saveCurrentApiConfig();
    return _selectedApiConfig;
  }

  Future<void> _loadGeneratedImagesDirectory() async {
    final generatedImagesDirectory = await _store
        .ensureGeneratedImagesDirectory();
    if (!mounted) {
      return;
    }

    setState(
      () => _generatedImagesDirectoryPath = generatedImagesDirectory.path,
    );
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

  void _scheduleApiConfigSave() {
    if (_isBootstrapping || _isRestoringState) {
      return;
    }

    _apiConfigSaveDebounce?.cancel();
    final saveVersion = ++_apiConfigSaveVersion;
    setState(() {
      _apiConfigSaveStatus = _ApiConfigSaveStatus.pending;
      _apiConfigSaveErrorMessage = null;
    });
    _apiConfigSaveDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_saveCurrentApiConfig(saveVersion: saveVersion));
    });
  }

  Future<void> _saveSettings() async {
    await _store.saveSettings(
      AppSettings(
        baseUrl: _baseUrlController.text.trim(),
        apiKey: _apiKeyController.text,
        model: _modelController.text.trim(),
        prompt: _promptController.text,
        negativePrompt: _negativePromptController.text,
        size: _size,
        imageCount: _imageCount,
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

  Future<void> _selectApiConfig(String id, {bool saveCurrent = true}) async {
    _apiConfigSaveDebounce?.cancel();
    if (saveCurrent &&
        _apiConfigs.any((config) => config.id == _selectedApiConfigId)) {
      await _saveCurrentApiConfig();
    }

    final nextConfig = _resolveApiConfig(_apiConfigs, id);
    _isRestoringState = true;
    _apiConfigNameController.text = nextConfig.name;
    _baseUrlController.text = nextConfig.baseUrl;
    _apiKeyController.text = nextConfig.apiKey;
    _modelController.text = nextConfig.model;
    if (mounted) {
      setState(() => _selectedApiConfigId = nextConfig.id);
    } else {
      _selectedApiConfigId = nextConfig.id;
    }
    _isRestoringState = false;

    await _store.saveSelectedApiConfigId(nextConfig.id);
    await _saveSettings();
  }

  Future<void> _addApiConfig() async {
    _apiConfigSaveDebounce?.cancel();
    await _saveCurrentApiConfig();

    final nextConfig = ApiConfig(
      id: ApiConfig.newId(),
      name: '新接口配置',
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      model: 'gpt-image-2',
    );
    final nextConfigs = [..._apiConfigs, nextConfig];
    setState(() => _apiConfigs = nextConfigs);
    await _store.saveApiConfigs(nextConfigs);
    await _selectApiConfig(nextConfig.id, saveCurrent: false);
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
    await _selectApiConfig(nextSelected.id, saveCurrent: false);
  }

  void _setSize(String value) {
    setState(() => _size = value);
    _scheduleSettingsSave();
  }

  void _setImageCount(int value) {
    setState(() => _imageCount = value);
    _scheduleSettingsSave();
  }

  void _setAnimationDirectionCount(int value) {
    setState(() => _animationDirectionCount = value);
  }

  void _setAnimationRows(int value) {
    setState(() => _animationRows = value);
  }

  void _setAnimationColumns(int value) {
    setState(() => _animationColumns = value);
  }

  void _setEditorDirectionCount(int value) {
    setState(() => _editorDirectionCount = value);
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

  Future<void> _pickEditorImage() async {
    final image = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Images',
          extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
        ),
      ],
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _editorImagePath = image.path;
      _editorErrorMessage = null;
    });
    _showMessage('已载入图片：${_fileNameFromPath(image.path)}');
  }

  void _clearEditorImage() {
    setState(() {
      _editorImagePath = null;
      _editorErrorMessage = null;
    });
  }

  Future<void> _pickEditorPatchImage() async {
    final image = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Images',
          extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
        ),
      ],
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _editorPatchImagePath = image.path;
      _editorErrorMessage = null;
    });
    _showMessage('已选择单帧图片：${_fileNameFromPath(image.path)}');
  }

  void _clearEditorPatchImage() {
    setState(() {
      _editorPatchImagePath = null;
      _editorErrorMessage = null;
    });
  }

  Future<void> _pickAnimationTemplateImage() async {
    final image = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp']),
      ],
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _animationTemplateImagePath = image.path;
      _animationErrorMessage = null;
    });
    _showMessage('已选择模板图片：${_fileNameFromPath(image.path)}');
  }

  void _clearAnimationTemplateImage() {
    setState(() => _animationTemplateImagePath = null);
  }

  Future<void> _pickGifSourceImages() async {
    final images = await openFiles(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Images',
          extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
        ),
      ],
    );

    if (images.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _gifSourceFrames = [
        for (var index = 0; index < images.length; index++)
          GifSourceFrame.fromPath(
            images[index].path,
            delayMs: _gifDefaultFrameDelayMs,
            seed: index,
          ),
      ];
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

    setState(() {
      _apiConfigs = [defaultApiConfig];
      _selectedApiConfigId = defaultApiConfig.id;
      _size = _defaultSettings.size;
      _imageCount = _defaultSettings.imageCount;
      _animationDirectionCount = 4;
      _animationRows = 4;
      _animationColumns = 4;
      _editorDirectionCount = 4;
      _editorRows = 4;
      _editorColumns = 4;
      _editorTargetFrameIndex = 0;
      _editorFrameFit = SpriteSheetFrameFit.contain;
      _errorMessage = null;
      _animationErrorMessage = null;
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
      _generatedImages = const [];
    });

    try {
      final response = await _client.generate(
        OpenAIImageRequest(
          baseUrl: apiConfig.baseUrl,
          apiKey: apiConfig.apiKey.trim(),
          model: apiConfig.model,
          prompt: prompt,
          negativePrompt: _negativePromptController.text.trim(),
          size: _size,
          imageCount: _imageCount,
        ),
      );

      if (!mounted) {
        return;
      }

      final historyId = DateTime.now().microsecondsSinceEpoch.toString();
      final cachedImages = <GeneratedImage>[];
      for (var index = 0; index < response.images.length; index++) {
        cachedImages.add(
          await _cacheGeneratedImage(
            historyId: historyId,
            index: index,
            image: response.images[index],
          ),
        );
      }

      setState(() => _generatedImages = cachedImages);
      final historyEntry = GenerationHistoryEntry(
        id: historyId,
        createdAt: DateTime.now(),
        baseUrl: apiConfig.baseUrl,
        model: apiConfig.model,
        prompt: prompt,
        negativePrompt: _negativePromptController.text.trim(),
        size: _size,
        imageCount: _imageCount,
        resultCount: cachedImages.length,
      );
      await _store.addHistoryEntry(historyEntry);
      if (mounted) {
        setState(() => _history = [historyEntry, ..._history]);
      }
      _showMessage('图片生成完成。');
    } on ImageGenerationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
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
      _animationFrames = const [];
    });

    try {
      final historyId =
          'animation_${DateTime.now().microsecondsSinceEpoch.toString()}';
      final response = await _client.generate(
        OpenAIImageRequest(
          baseUrl: apiConfig.baseUrl,
          apiKey: apiConfig.apiKey.trim(),
          model: apiConfig.model,
          prompt: _buildSpriteSheetPrompt(),
          negativePrompt: _negativePromptController.text.trim(),
          size: _size,
          imageCount: 1,
          templateImagePath: templatePath,
        ),
      );

      if (response.images.isEmpty) {
        throw const ImageGenerationException('接口没有返回 Sprite Sheet 图片。');
      }

      final cachedImages = await SpriteSheetOutputCache.saveSheetAndFrames(
        store: _store,
        historyId: historyId,
        sourceImage: response.images.first,
        rows: _animationRows,
        columns: _animationColumns,
        resolveImageBytes: _client.resolveImageBytes,
      );
      final cachedSheet = cachedImages.first;
      final savedDirectoryPath = cachedSheet.filePath == null
          ? null
          : File(cachedSheet.filePath!).parent.path;

      if (!mounted) {
        return;
      }

      final historyEntry = GenerationHistoryEntry(
        id: historyId,
        createdAt: DateTime.now(),
        baseUrl: apiConfig.baseUrl,
        model: apiConfig.model,
        prompt: prompt,
        negativePrompt: _negativePromptController.text.trim(),
        size: _size,
        imageCount: 1,
        resultCount: cachedImages.length,
      );
      await _store.addHistoryEntry(historyEntry);
      if (!mounted) {
        return;
      }

      setState(() {
        _animationFrames = [cachedSheet];
        _history = [historyEntry, ..._history];
        if (savedDirectoryPath != null) {
          _generatedImagesDirectoryPath = savedDirectoryPath;
        }
      });
      _showMessage(
        savedDirectoryPath == null
            ? 'Sprite Sheet 已生成，并保存 ${cachedImages.length - 1} 张切片帧。'
            : 'Sprite Sheet 已生成，并保存 ${cachedImages.length - 1} 张切片帧。目录：$savedDirectoryPath',
      );
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
    required int directionCount,
    required int rows,
    required int columns,
  }) async {
    final outputFile = await _store.createGeneratedSpriteSheetFile(
      directionCount: directionCount,
      rows: rows,
      columns: columns,
    );
    await outputFile.writeAsBytes(pngBytes, flush: true);
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
        directionCount: _editorDirectionCount,
        rows: _editorRows,
        columns: _editorColumns,
      );
      await outputFile.writeAsBytes(editedBytes, flush: true);

      if (!mounted) {
        return;
      }

      setState(() => _editorImagePath = outputFile.path);
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
    final directions = [
      for (var row = 0; row < _animationRows; row++)
        '${row + 1}. ${_animationDirectionPromptForRow(row, _animationDirectionCount)}',
    ].join('\n');

    return [
      _animationPromptController.text.trim(),
      'Create ONE complete sprite sheet image, not separate files.',
      'The sprite sheet must be arranged as exactly $_animationRows rows x $_animationColumns columns, total $_animationFrameCount cells.',
      'Each cell must have equal size and align to a clean grid.',
      'Rows represent facing directions in this order:\n$directions',
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
    return '${_animationDirectionDisplayForRow(row, _animationDirectionCount)} · 第 $column 列';
  }

  String _buildEditorFrameLabel(int index) {
    final row = index ~/ _editorColumns;
    final column = index % _editorColumns + 1;
    return '第 ${index + 1} 帧 · ${_animationDirectionDisplayForRow(row, _editorDirectionCount)} · 第 $column 列';
  }

  Future<GeneratedImage> _cacheGeneratedImage({
    required String historyId,
    required int index,
    required GeneratedImage image,
  }) async {
    try {
      final bytes = await _client.resolveImageBytes(image);
      final file = await _store.saveGeneratedImageBytes(
        historyId: historyId,
        index: index,
        bytes: bytes,
      );
      return GeneratedImage.file(file.path, revisedPrompt: image.revisedPrompt);
    } catch (_) {
      return image;
    }
  }

  Future<void> _reuseHistoryEntry(GenerationHistoryEntry entry) async {
    _isRestoringState = true;
    _promptController.text = entry.prompt;
    _negativePromptController.text = entry.negativePrompt;
    String? matchingConfigId;
    for (final config in _apiConfigs) {
      if (config.baseUrl == entry.baseUrl && config.model == entry.model) {
        matchingConfigId = config.id;
        break;
      }
    }

    setState(() {
      if (matchingConfigId != null) {
        _selectedApiConfigId = matchingConfigId;
      }
      _size = entry.size;
      _imageCount = entry.imageCount;
      _errorMessage = null;
    });

    _isRestoringState = false;
    if (matchingConfigId != null) {
      await _selectApiConfig(matchingConfigId, saveCurrent: false);
    }
    await _saveSettings();
    _showMessage('已载入历史参数。');
  }

  Future<void> _copyHistoryEntry(GenerationHistoryEntry entry) async {
    final summary = [
      'Base URL: ${entry.baseUrl}',
      'Model: ${entry.model}',
      'Size: ${entry.size}',
      'Count: ${entry.imageCount}',
      'Prompt: ${entry.prompt}',
      if (entry.negativePrompt.trim().isNotEmpty)
        'Negative: ${entry.negativePrompt}',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: summary));
    _showMessage('历史参数已复制。');
  }

  Future<void> _deleteHistoryEntry(String id) async {
    final removedEntry = _history.where((entry) => entry.id == id).toList();
    final nextHistory = _history.where((entry) => entry.id != id).toList();
    if (removedEntry.isNotEmpty) {
      await _store.deleteGeneratedImageFiles(
        removedEntry.first.id,
        removedEntry.first.resultCount,
      );
    }
    await _store.saveHistory(nextHistory);
    if (!mounted) {
      return;
    }
    setState(() => _history = nextHistory);
  }

  Future<void> _clearHistory() async {
    await _store.clearGeneratedImageFiles();
    await _store.saveHistory(const []);
    if (!mounted) {
      return;
    }
    setState(() => _history = const []);
    _showMessage('历史记录已清空。');
  }

  Future<void> _scrollToHistory() async {
    final context = _historySectionKey.currentContext;
    if (context == null) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  Future<void> _openImageHistory() async {
    if (_selectedFeature != _WorkspaceFeature.imageGeneration) {
      await _selectFeature(_WorkspaceFeature.imageGeneration);
      await WidgetsBinding.instance.endOfFrame;
    }

    await _scrollToHistory();
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
          content: const Text('这里可以重置本地表单或清空历史记录。'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetToDefaults();
              },
              child: const Text('重置表单'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearHistory();
              },
              child: const Text('清空历史'),
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
    final theme = Theme.of(context);
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
              onOpenHistory: _openImageHistory,
              onOpenSettings: _showSettingsDialog,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _buildSelectedWorkspace(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedWorkspace(ThemeData theme) {
    return switch (_selectedFeature) {
      _WorkspaceFeature.imageGeneration => _buildImageGenerationWorkspace(
        theme,
      ),
      _WorkspaceFeature.frameAnimation => _buildFrameAnimationWorkspace(theme),
      _WorkspaceFeature.imageEditor => _buildImageEditorWorkspace(theme),
      _WorkspaceFeature.gifComposer => _buildGifComposerWorkspace(theme),
      _WorkspaceFeature.apiSettings => _buildApiSettingsWorkspace(theme),
    };
  }

  Widget _buildImageGenerationWorkspace(ThemeData theme) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(_workspacePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OpenAI 兼容生图', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('选择已保存的接口配置，再填写提示词生成图片。', style: theme.textTheme.bodyLarge),
          const SizedBox(height: _sectionGap),
          LayoutBuilder(
            builder: (context, constraints) {
              final controls = _ControlPanel(
                apiConfigs: _apiConfigs,
                selectedApiConfigId: _selectedApiConfig.id,
                promptController: _promptController,
                negativePromptController: _negativePromptController,
                size: _size,
                sizes: _sizes,
                imageCount: _imageCount,
                isGenerating: _isGenerating,
                onApiConfigChanged: _selectApiConfig,
                onOpenApiSettings: () =>
                    unawaited(_selectFeature(_WorkspaceFeature.apiSettings)),
                onSizeChanged: _setSize,
                onImageCountChanged: _setImageCount,
                onGenerate: _generateImage,
              );
              final preview = _PreviewPanel(
                errorMessage: _errorMessage,
                generatedImages: _generatedImages,
                isGenerating: _isGenerating,
              );

              if (constraints.maxWidth < 900) {
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
                  SizedBox(width: 392, child: controls),
                  const SizedBox(width: _layoutGap),
                  Expanded(child: preview),
                ],
              );
            },
          ),
          const SizedBox(height: _layoutGap),
          _HistoryPanel(
            key: _historySectionKey,
            entries: _history,
            generatedImagesDirectoryPath: _generatedImagesDirectoryPath,
            onReuse: _reuseHistoryEntry,
            onCopy: _copyHistoryEntry,
            onDelete: _deleteHistoryEntry,
            onClear: _history.isEmpty ? null : _clearHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildFrameAnimationWorkspace(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_workspacePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('帧动画生成', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '一次生成完整 Sprite Sheet，再按行列切片预览动作连续性。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: _sectionGap),
          LayoutBuilder(
            builder: (context, constraints) {
              final controls = _FrameAnimationPanel(
                apiConfigs: _apiConfigs,
                selectedApiConfigId: _selectedApiConfig.id,
                promptController: _animationPromptController,
                negativePromptController: _negativePromptController,
                size: _size,
                sizes: _sizes,
                directionCount: _animationDirectionCount,
                rows: _animationRows,
                columns: _animationColumns,
                templateImagePath: _animationTemplateImagePath,
                isGenerating: _isGeneratingAnimation,
                onApiConfigChanged: _selectApiConfig,
                onOpenApiSettings: () =>
                    unawaited(_selectFeature(_WorkspaceFeature.apiSettings)),
                onSizeChanged: _setSize,
                onDirectionCountChanged: _setAnimationDirectionCount,
                onRowsChanged: _setAnimationRows,
                onColumnsChanged: _setAnimationColumns,
                onPickTemplateImage: _pickAnimationTemplateImage,
                onClearTemplateImage: _clearAnimationTemplateImage,
                onGenerate: _generateAnimationFrames,
              );
              final preview = _FrameAnimationPreviewPanel(
                title: 'Sprite Sheet 预览',
                emptyMessage: '生成后的整张 Sprite Sheet 会显示在这里',
                errorMessage: _animationErrorMessage,
                generatedImages: _animationFrames,
                isGenerating: _isGeneratingAnimation,
                rows: _animationRows,
                columns: _animationColumns,
                directionCount: _animationDirectionCount,
                labelBuilder: _buildAnimationFrameLabel,
                onRetry: _generateAnimationFrames,
                onExportSpriteSheet: (bytes) => unawaited(
                  _exportSpriteSheet(
                    pngBytes: bytes,
                    directionCount: _animationDirectionCount,
                    rows: _animationRows,
                    columns: _animationColumns,
                  ),
                ),
              );

              if (constraints.maxWidth < 900) {
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
                  SizedBox(width: 392, child: controls),
                  const SizedBox(width: _layoutGap),
                  Expanded(child: preview),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageEditorWorkspace(ThemeData theme) {
    final editorImagePath = _editorImagePath;
    final editorImages = editorImagePath == null
        ? const <GeneratedImage>[]
        : [GeneratedImage.file(editorImagePath)];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(_workspacePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('图片编辑器', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '载入一张 Sprite Sheet，按行列快速查看第几帧。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: _sectionGap),
          LayoutBuilder(
            builder: (context, constraints) {
              final controls = _SpriteSheetEditorPanel(
                imagePath: editorImagePath,
                patchImagePath: _editorPatchImagePath,
                directionCount: _editorDirectionCount,
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
                onDirectionCountChanged: _setEditorDirectionCount,
                onRowsChanged: _setEditorRows,
                onColumnsChanged: _setEditorColumns,
                onTargetFrameChanged: _setEditorTargetFrameIndex,
                onFrameFitChanged: _setEditorFrameFit,
                onReplaceFrame: _replaceEditorFrame,
              );
              final preview = _FrameAnimationPreviewPanel(
                title: '切片查看',
                emptyMessage: '选择一张 Sprite Sheet 后，可以按行列查看第几帧',
                errorMessage: _editorErrorMessage,
                generatedImages: editorImages,
                isGenerating: false,
                rows: _editorRows,
                columns: _editorColumns,
                directionCount: _editorDirectionCount,
                labelBuilder: _buildEditorFrameLabel,
                onExportSpriteSheet: (bytes) => unawaited(
                  _exportSpriteSheet(
                    pngBytes: bytes,
                    directionCount: _editorDirectionCount,
                    rows: _editorRows,
                    columns: _editorColumns,
                  ),
                ),
              );

              if (constraints.maxWidth < 900) {
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
                  SizedBox(width: 392, child: controls),
                  const SizedBox(width: _layoutGap),
                  Expanded(child: preview),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGifComposerWorkspace(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_workspacePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GIF 合成', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('选择多张本地图片，按当前顺序合成为一个 GIF 动图。', style: theme.textTheme.bodyLarge),
          const SizedBox(height: _sectionGap),
          LayoutBuilder(
            builder: (context, constraints) {
              final controls = _GifComposerPanel(
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
              );
              final preview = _GifSourcePreviewPanel(
                frames: _gifSourceFrames,
                outputPath: _gifOutputPath,
              );

              if (constraints.maxWidth < 900) {
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
                  SizedBox(width: 392, child: controls),
                  const SizedBox(width: _layoutGap),
                  Expanded(child: preview),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApiSettingsWorkspace(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_workspacePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('接口配置', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '集中管理 OpenAI 兼容接口，其他功能页只需要选择这里保存的配置。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: _sectionGap),
          _ApiSettingsPanel(
            apiConfigs: _apiConfigs,
            selectedApiConfigId: _selectedApiConfig.id,
            saveStatus: _apiConfigSaveStatus,
            saveErrorMessage: _apiConfigSaveErrorMessage,
            nameController: _apiConfigNameController,
            baseUrlController: _baseUrlController,
            apiKeyController: _apiKeyController,
            modelController: _modelController,
            showApiKey: _showApiKey,
            onApiConfigChanged: _selectApiConfig,
            onAddApiConfig: _addApiConfig,
            onDeleteApiConfig: _deleteSelectedApiConfig,
            onToggleApiKeyVisibility: () =>
                setState(() => _showApiKey = !_showApiKey),
          ),
        ],
      ),
    );
  }
}

class _FeatureNavigationRail extends StatelessWidget {
  const _FeatureNavigationRail({
    required this.selectedFeature,
    required this.extended,
    required this.onFeatureSelected,
    required this.onOpenHistory,
    required this.onOpenSettings,
  });

  final _WorkspaceFeature selectedFeature;
  final bool extended;
  final ValueChanged<_WorkspaceFeature> onFeatureSelected;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;

  int? get _selectedDestinationIndex {
    return switch (selectedFeature) {
      _WorkspaceFeature.imageGeneration => 0,
      _WorkspaceFeature.frameAnimation => 1,
      _WorkspaceFeature.imageEditor => 2,
      _WorkspaceFeature.gifComposer => 3,
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
          label: Text('正常生图'),
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
      ],
      onDestinationSelected: (index) {
        final feature = switch (index) {
          0 => _WorkspaceFeature.imageGeneration,
          1 => _WorkspaceFeature.frameAnimation,
          2 => _WorkspaceFeature.imageEditor,
          _ => _WorkspaceFeature.gifComposer,
        };
        onFeatureSelected(feature);
      },
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: '历史',
                  onPressed: onOpenHistory,
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

class _ApiConfigSelector extends StatelessWidget {
  const _ApiConfigSelector({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.onChanged,
    required this.onOpenSettings,
    this.showSettingsButton = true,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenSettings;
  final bool showSettingsButton;

  @override
  Widget build(BuildContext context) {
    final selectedExists = apiConfigs.any(
      (config) => config.id == selectedApiConfigId,
    );
    final selectedValue = selectedExists
        ? selectedApiConfigId
        : apiConfigs.isEmpty
        ? null
        : apiConfigs.first.id;

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
        if (showSettingsButton) ...[
          const SizedBox(width: 12),
          Tooltip(
            message: '管理接口配置',
            child: IconButton.filledTonal(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.tune_outlined),
            ),
          ),
        ],
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
    required this.nameController,
    required this.baseUrlController,
    required this.apiKeyController,
    required this.modelController,
    required this.showApiKey,
    required this.onApiConfigChanged,
    required this.onAddApiConfig,
    required this.onDeleteApiConfig,
    required this.onToggleApiKeyVisibility,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final _ApiConfigSaveStatus saveStatus;
  final String? saveErrorMessage;
  final TextEditingController nameController;
  final TextEditingController baseUrlController;
  final TextEditingController apiKeyController;
  final TextEditingController modelController;
  final bool showApiKey;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onAddApiConfig;
  final VoidCallback onDeleteApiConfig;
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
          _ApiConfigSelector(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfigId,
            onChanged: onApiConfigChanged,
            onOpenSettings: () {},
            showSettingsButton: false,
          ),
          const SizedBox(height: _fieldGap),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '配置名称',
              hintText: '例如 OpenAI 官方、内网代理、备用接口',
            ),
          ),
          const SizedBox(height: _fieldGap),
          _ConnectionSettingsFields(
            baseUrlController: baseUrlController,
            apiKeyController: apiKeyController,
            modelController: modelController,
            showApiKey: showApiKey,
            onToggleApiKeyVisibility: onToggleApiKeyVisibility,
          ),
        ],
      ),
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
        '已自动保存',
        colorScheme.primary,
        Icons.check_circle_outline,
      ),
      _ApiConfigSaveStatus.pending => (
        '等待保存',
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
    required this.showApiKey,
    required this.onToggleApiKeyVisibility,
  });

  final TextEditingController baseUrlController;
  final TextEditingController apiKeyController;
  final TextEditingController modelController;
  final bool showApiKey;
  final VoidCallback onToggleApiKeyVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: baseUrlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Base URL',
            hintText: 'https://api.openai.com/v1',
          ),
        ),
        const SizedBox(height: _fieldGap),
        TextField(
          controller: apiKeyController,
          obscureText: !showApiKey,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: 'sk-...',
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
          decoration: const InputDecoration(
            labelText: '模型',
            hintText: 'gpt-image-2',
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
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.sizes,
    required this.imageCount,
    required this.isGenerating,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onImageCountChanged,
    required this.onGenerate,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final List<String> sizes;
  final int imageCount;
  final bool isGenerating;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onImageCountChanged;
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
          _ResponsivePair(
            first: DropdownButtonFormField<String>(
              initialValue: size,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '清晰度 / 尺寸'),
              items: sizes
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        _imageSizePresetLabel(item),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onSizeChanged(value);
                }
              },
            ),
            second: DropdownButtonFormField<int>(
              initialValue: imageCount,
              decoration: const InputDecoration(labelText: '数量'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 张')),
                DropdownMenuItem(value: 2, child: Text('2 张')),
                DropdownMenuItem(value: 3, child: Text('3 张')),
                DropdownMenuItem(value: 4, child: Text('4 张')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onImageCountChanged(value);
                }
              },
            ),
          ),
          const SizedBox(height: _sectionGap),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isGenerating ? null : onGenerate,
              icon: isGenerating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(isGenerating ? '生成中' : '生成图片'),
            ),
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
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.sizes,
    required this.directionCount,
    required this.rows,
    required this.columns,
    required this.templateImagePath,
    required this.isGenerating,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onDirectionCountChanged,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onPickTemplateImage,
    required this.onClearTemplateImage,
    required this.onGenerate,
  });

  static const List<int> _gridSizes = <int>[1, 2, 3, 4, 5, 6, 7, 8];

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final List<String> sizes;
  final int directionCount;
  final int rows;
  final int columns;
  final String? templateImagePath;
  final bool isGenerating;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onDirectionCountChanged;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
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
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 4,
                  icon: Icon(Icons.crop_square_outlined),
                  label: Text('4 向'),
                ),
                ButtonSegment<int>(
                  value: 8,
                  icon: Icon(Icons.explore_outlined),
                  label: Text('8 向'),
                ),
              ],
              selected: {directionCount},
              onSelectionChanged: isGenerating
                  ? null
                  : (selection) => onDirectionCountChanged(selection.single),
            ),
          ),
          const SizedBox(height: _fieldGap),
          _ResponsivePair(
            first: DropdownButtonFormField<String>(
              initialValue: size,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '清晰度 / 尺寸'),
              items: sizes
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        _imageSizePresetLabel(item),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onSizeChanged(value);
                }
              },
            ),
            second: DropdownButtonFormField<int>(
              initialValue: rows,
              decoration: const InputDecoration(labelText: '行数'),
              items: _gridSizes
                  .map(
                    (item) => DropdownMenuItem<int>(
                      value: item,
                      child: Text('$item 行'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onRowsChanged(value);
                }
              },
            ),
          ),
          const SizedBox(height: _fieldGap),
          DropdownButtonFormField<int>(
            initialValue: columns,
            decoration: InputDecoration(
              labelText: '列数',
              helperText:
                  '生成 1 张 $rows x $columns 的 Sprite Sheet，共 $frameTotal 格',
            ),
            items: _gridSizes
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item,
                    child: Text('$item 列'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onColumnsChanged(value);
              }
            },
          ),
          const SizedBox(height: _sectionGap),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isGenerating ? null : onGenerate,
              icon: isGenerating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.movie_filter_outlined),
              label: Text(
                isGenerating ? '生成 Sprite Sheet 中' : '生成 Sprite Sheet',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpriteSheetEditorPanel extends StatelessWidget {
  const _SpriteSheetEditorPanel({
    required this.imagePath,
    required this.patchImagePath,
    required this.directionCount,
    required this.rows,
    required this.columns,
    required this.targetFrameIndex,
    required this.frameFit,
    required this.isReplacingFrame,
    required this.onPickImage,
    required this.onClearImage,
    required this.onPickPatchImage,
    required this.onClearPatchImage,
    required this.onDirectionCountChanged,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onTargetFrameChanged,
    required this.onFrameFitChanged,
    required this.onReplaceFrame,
  });

  static const List<int> _gridSizes = <int>[1, 2, 3, 4, 5, 6, 7, 8];

  final String? imagePath;
  final String? patchImagePath;
  final int directionCount;
  final int rows;
  final int columns;
  final int targetFrameIndex;
  final SpriteSheetFrameFit frameFit;
  final bool isReplacingFrame;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onPickPatchImage;
  final VoidCallback onClearPatchImage;
  final ValueChanged<int> onDirectionCountChanged;
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
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 4,
                  icon: Icon(Icons.crop_square_outlined),
                  label: Text('4 向'),
                ),
                ButtonSegment<int>(
                  value: 8,
                  icon: Icon(Icons.explore_outlined),
                  label: Text('8 向'),
                ),
              ],
              selected: {directionCount},
              onSelectionChanged: (selection) =>
                  onDirectionCountChanged(selection.single),
            ),
          ),
          const SizedBox(height: _fieldGap),
          _ResponsivePair(
            first: DropdownButtonFormField<int>(
              initialValue: rows,
              decoration: const InputDecoration(labelText: '行数'),
              items: _gridSizes
                  .map(
                    (item) => DropdownMenuItem<int>(
                      value: item,
                      child: Text('$item 行'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onRowsChanged(value);
                }
              },
            ),
            second: DropdownButtonFormField<int>(
              initialValue: columns,
              decoration: InputDecoration(
                labelText: '列数',
                helperText: '共 $frameTotal 帧',
              ),
              items: _gridSizes
                  .map(
                    (item) => DropdownMenuItem<int>(
                      value: item,
                      child: Text('$item 列'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onColumnsChanged(value);
                }
              },
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
            first: DropdownButtonFormField<int>(
              key: ValueKey('editor-target-frame-$safeFrameIndex-$frameTotal'),
              initialValue: safeFrameIndex,
              decoration: const InputDecoration(labelText: '替换目标'),
              items: [
                for (var index = 0; index < frameTotal; index++)
                  DropdownMenuItem<int>(
                    value: index,
                    child: Text(_editorFrameOptionLabel(index, columns)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onTargetFrameChanged(value);
                }
              },
            ),
            second: DropdownButtonFormField<SpriteSheetFrameFit>(
              initialValue: frameFit,
              decoration: const InputDecoration(labelText: '适配方式'),
              items: [
                for (final fit in SpriteSheetFrameFit.values)
                  DropdownMenuItem<SpriteSheetFrameFit>(
                    value: fit,
                    child: Text(_spriteSheetFrameFitLabel(fit)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onFrameFitChanged(value);
                }
              },
            ),
          ),
          const SizedBox(height: _fieldGap),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canReplace ? onReplaceFrame : null,
              icon: isReplacingFrame
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.published_with_changes_outlined),
              label: Text(isReplacingFrame ? '替换中' : '插入 / 替换到当前格'),
            ),
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
                                DropdownButtonFormField<int>(
                                  initialValue: frame.delayMs,
                                  decoration: const InputDecoration(
                                    labelText: '帧时长',
                                    isDense: true,
                                  ),
                                  items: [
                                    for (final value in _gifFrameDelayOptions)
                                      DropdownMenuItem(
                                        value: value,
                                        child: Text('$value ms'),
                                      ),
                                  ],
                                  onChanged: isComposing
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            onFrameDelayForImageChanged(
                                              index,
                                              value,
                                            );
                                          }
                                        },
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
                child: DropdownButtonFormField<int>(
                  initialValue: defaultFrameDelayMs,
                  decoration: const InputDecoration(labelText: '默认帧时长'),
                  items: [
                    for (final value in _gifFrameDelayOptions)
                      DropdownMenuItem(value: value, child: Text('$value ms')),
                  ],
                  onChanged: isComposing
                      ? null
                      : (value) {
                          if (value != null) {
                            onFrameDelayChanged(value);
                          }
                        },
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
          DropdownButtonFormField<int>(
            initialValue: loopCount,
            decoration: const InputDecoration(labelText: '循环次数'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('无限循环')),
              DropdownMenuItem(value: 1, child: Text('播放 1 次')),
              DropdownMenuItem(value: 3, child: Text('播放 3 次')),
              DropdownMenuItem(value: 5, child: Text('播放 5 次')),
            ],
            onChanged: isComposing
                ? null
                : (value) {
                    if (value != null) {
                      onLoopCountChanged(value);
                    }
                  },
          ),
          const SizedBox(height: _fieldGap),
          DropdownButtonFormField<GifPlaybackMode>(
            initialValue: playbackMode,
            decoration: const InputDecoration(labelText: '播放模式'),
            items: const [
              DropdownMenuItem(
                value: GifPlaybackMode.normal,
                child: Text('正向'),
              ),
              DropdownMenuItem(
                value: GifPlaybackMode.reverse,
                child: Text('反向'),
              ),
              DropdownMenuItem(
                value: GifPlaybackMode.pingPong,
                child: Text('乒乓'),
              ),
            ],
            onChanged: isComposing
                ? null
                : (value) {
                    if (value != null) {
                      onPlaybackModeChanged(value);
                    }
                  },
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isComposing || frames.length < 2 ? null : onCompose,
              icon: isComposing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.gif_box_outlined),
              label: Text(isComposing ? '合成中' : '生成 GIF'),
            ),
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

    return _Panel(
      title: outputPath == null ? '图片序列预览' : 'GIF 预览',
      child: outputPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(outputPath!), fit: BoxFit.contain),
            )
          : frames.isEmpty
          ? Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 420),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text('选择多张图片后会显示在这里', style: theme.textTheme.bodyLarge),
            )
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
  });

  final String? errorMessage;
  final List<GeneratedImage> generatedImages;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Panel(
      title: '结果预览',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _buildContent(context, theme),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    if (isGenerating) {
      return const SizedBox(
        key: ValueKey('loading'),
        height: 420,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Container(
        key: const ValueKey('error'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
      );
    }

    if (generatedImages.isEmpty) {
      return Container(
        key: const ValueKey('empty'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 420),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text('生成后的图片会显示在这里', style: theme.textTheme.bodyLarge),
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

class _FramePreviewErrorState extends StatelessWidget {
  const _FramePreviewErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 38, color: colorScheme.error),
          const SizedBox(height: 12),
          Text(
            '生成失败',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
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
              label: const Text('重试生成'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FrameAnimationPreviewPanel extends StatefulWidget {
  const _FrameAnimationPreviewPanel({
    required this.title,
    required this.emptyMessage,
    required this.errorMessage,
    required this.generatedImages,
    required this.isGenerating,
    required this.rows,
    required this.columns,
    required this.directionCount,
    required this.onExportSpriteSheet,
    this.labelBuilder,
    this.onRetry,
  });

  final String title;
  final String emptyMessage;
  final String? errorMessage;
  final List<GeneratedImage> generatedImages;
  final bool isGenerating;
  final int rows;
  final int columns;
  final int directionCount;
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

    return _Panel(
      title: widget.title,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (widget.generatedImages.isEmpty || _previewFuture == null) {
      return Container(
        key: const ValueKey('frame-preview-empty'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 420),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: widget.isGenerating
            ? const CircularProgressIndicator()
            : widget.errorMessage != null
            ? _FramePreviewErrorState(
                message: widget.errorMessage!,
                onRetry: widget.onRetry,
              )
            : Text(widget.emptyMessage, style: theme.textTheme.bodyLarge),
      );
    }

    return FutureBuilder<SpriteSheetPreviewData>(
      key: ValueKey(
        'frame-preview-${widget.generatedImages.length}-${widget.rows}-${widget.columns}',
      ),
      future: _previewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 420,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 420),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: _FramePreviewErrorState(
              message: '切片预览失败：${snapshot.error ?? '没有可用的预览数据'}',
              onRetry: widget.onRetry,
            ),
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
            title: _animationDirectionDisplayForRow(row, widget.directionCount),
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
              child: DropdownButtonFormField<int>(
                key: ValueKey('preview-frame-$safeFrameIndex'),
                initialValue: safeFrameIndex,
                decoration: const InputDecoration(labelText: '帧号'),
                items: [
                  for (
                    var index = 0;
                    index < previewData.rows * previewData.columns;
                    index++
                  )
                    DropdownMenuItem<int>(
                      value: index,
                      child: Text('第 ${index + 1} 帧'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _selectFrameIndex(value);
                  }
                },
              ),
            ),
            SizedBox(
              width: 172,
              child: DropdownButtonFormField<int>(
                key: ValueKey('preview-row-$safeRow'),
                initialValue: safeRow,
                decoration: const InputDecoration(labelText: '方向行'),
                items: [
                  for (var row = 0; row < previewData.rows; row++)
                    DropdownMenuItem<int>(
                      value: row,
                      child: Text(
                        _animationDirectionDisplayForRow(
                          row,
                          widget.directionCount,
                        ),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _selectRow(value);
                  }
                },
              ),
            ),
            SizedBox(
              width: 156,
              child: DropdownButtonFormField<int>(
                key: ValueKey('preview-speed-$_frameDelayMs'),
                initialValue: _frameDelayMs,
                decoration: const InputDecoration(labelText: '播放速度'),
                items: [
                  for (final speed in _playbackSpeeds)
                    DropdownMenuItem<int>(
                      value: speed,
                      child: Text('$speed ms'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _setFrameDelay(value);
                  }
                },
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
          '第 ${safeFrameIndex + 1} 帧 · ${_animationDirectionDisplayForRow(safeRow, widget.directionCount)} · 第 ${safeColumn + 1} / ${previewData.columns} 列',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Text('按行检查方向，按列检查动作连续性。', style: theme.textTheme.bodySmall),
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

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    super.key,
    required this.entries,
    required this.generatedImagesDirectoryPath,
    required this.onReuse,
    required this.onCopy,
    required this.onDelete,
    required this.onClear,
  });

  final List<GenerationHistoryEntry> entries;
  final String? generatedImagesDirectoryPath;
  final ValueChanged<GenerationHistoryEntry> onReuse;
  final ValueChanged<GenerationHistoryEntry> onCopy;
  final ValueChanged<String> onDelete;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Panel(
      title: '生成历史',
      trailing: onClear == null
          ? null
          : TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('清空'),
            ),
      child: entries.isEmpty
          ? Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                '暂无历史记录，生成一次图片后会自动保存。',
                style: theme.textTheme.bodyMedium,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  _HistoryEntryTile(
                    entry: entries[index],
                    generatedImagesDirectoryPath: generatedImagesDirectoryPath,
                    onReuse: onReuse,
                    onCopy: onCopy,
                    onDelete: onDelete,
                  ),
                  if (index != entries.length - 1)
                    const SizedBox(height: _fieldGap),
                ],
              ],
            ),
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({
    required this.entry,
    required this.generatedImagesDirectoryPath,
    required this.onReuse,
    required this.onCopy,
    required this.onDelete,
  });

  final GenerationHistoryEntry entry;
  final String? generatedImagesDirectoryPath;
  final ValueChanged<GenerationHistoryEntry> onReuse;
  final ValueChanged<GenerationHistoryEntry> onCopy;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onReuse(entry),
        child: Padding(
          padding: const EdgeInsets.all(_fieldGap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HistoryThumbnail(
                thumbnailPath: _thumbnailPath,
                fallbackColor: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shorten(entry.prompt.replaceAll('\n', ' '), 80),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.model} · ${entry.size} · ${entry.imageCount} 张 · ${entry.resultCount} 结果 · ${_formatTimestamp(entry.createdAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Tooltip(
                    message: '复用参数',
                    child: IconButton(
                      onPressed: () => onReuse(entry),
                      icon: const Icon(Icons.restore_outlined),
                    ),
                  ),
                  Tooltip(
                    message: '复制参数',
                    child: IconButton(
                      onPressed: () => onCopy(entry),
                      icon: const Icon(Icons.copy_outlined),
                    ),
                  ),
                  Tooltip(
                    message: '删除记录',
                    child: IconButton(
                      onPressed: () => onDelete(entry.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? get _thumbnailPath {
    final directoryPath = generatedImagesDirectoryPath;
    if (directoryPath == null || entry.resultCount <= 0) {
      return null;
    }

    final file = File(
      '$directoryPath${Platform.pathSeparator}${entry.id}_01.png',
    );
    return file.existsSync() ? file.path : null;
  }
}

class _HistoryThumbnail extends StatelessWidget {
  const _HistoryThumbnail({
    required this.thumbnailPath,
    required this.fallbackColor,
  });

  final String? thumbnailPath;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    if (thumbnailPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Image.file(
            File(thumbnailPath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _placeholder();
            },
          ),
        ),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fallbackColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.image_outlined, color: fallbackColor),
    );
  }
}

String _shorten(String text, int maxLength) {
  if (text.length <= maxLength) {
    return text;
  }

  return '${text.substring(0, maxLength - 1)}…';
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
  return '第 ${index + 1} 帧 · $row 行 $column 列';
}

String _spriteSheetFrameFitLabel(SpriteSheetFrameFit fit) {
  return switch (fit) {
    SpriteSheetFrameFit.contain => '完整放入',
    SpriteSheetFrameFit.cover => '裁剪填满',
    SpriteSheetFrameFit.stretch => '拉伸填满',
  };
}

String _imageSizePresetLabel(String size) {
  if (size == 'auto') {
    return '自动';
  }

  final parts = size.split('x');
  final width = int.tryParse(parts.first);
  final height = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (width == null || height == null) {
    return size;
  }

  final shortestSide = width < height ? width : height;
  final quality = shortestSide >= 4096
      ? '4K'
      : shortestSide >= 2048
      ? '2K'
      : '1K';
  final orientation = width == height
      ? '方图'
      : width > height
      ? '横图'
      : '竖图';
  return '$quality $orientation · $size';
}

String _animationDirectionDisplayForRow(int row, int directionCount) {
  final directions = directionCount == 8
      ? const ['上', '右上', '右', '右下', '下', '左下', '左', '左上']
      : const ['上', '右', '下', '左'];
  if (row < directions.length) {
    return directions[row];
  }

  return '第 ${row + 1} 行';
}

String _animationDirectionPromptForRow(int row, int directionCount) {
  final directions = directionCount == 8
      ? const [
          'north/up',
          'north-east/up-right',
          'east/right',
          'south-east/down-right',
          'south/down',
          'south-west/down-left',
          'west/left',
          'north-west/up-left',
        ]
      : const ['north/up', 'east/right', 'south/down', 'west/left'];
  if (row < directions.length) {
    return directions[row];
  }

  return 'custom-row-${row + 1}';
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

  static Future<List<GeneratedImage>> saveSheetAndFrames({
    required AppLocalStore store,
    required String historyId,
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

    final cachedImages = <GeneratedImage>[];
    final sheetFile = await store.saveGeneratedImageBytes(
      historyId: historyId,
      index: 0,
      bytes: previewData.sheetBytes,
    );
    cachedImages.add(
      GeneratedImage.file(
        sheetFile.path,
        revisedPrompt: sourceImage.revisedPrompt,
      ),
    );

    for (var index = 0; index < previewData.frames.length; index++) {
      final frameFile = await store.saveGeneratedImageBytes(
        historyId: historyId,
        index: index + 1,
        bytes: previewData.frames[index],
      );
      cachedImages.add(GeneratedImage.file(frameFile.path));
    }

    return cachedImages;
  }
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

  Future<OpenAIImageResponse> generate(OpenAIImageRequest request) async {
    final response = request.hasTemplateImage
        ? await _postImageEdit(request)
        : await _postImageGeneration(request);

    final decoded = _decodeJsonObject(response.bodyBytes);
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

  static Map<String, dynamic> _decodeJsonObject(List<int> bodyBytes) {
    final decoded = jsonDecode(utf8.decode(bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ImageGenerationException('接口返回的不是 JSON 对象。');
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
    this.templateImagePath,
  });

  final String baseUrl;
  final String apiKey;
  final String model;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final String? templateImagePath;

  bool get hasTemplateImage =>
      templateImagePath != null && templateImagePath!.trim().isNotEmpty;

  Uri get endpoint {
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

  Map<String, dynamic> toJson() {
    return {
      'model': _effectiveModel,
      'prompt': _mergedPrompt,
      'size': size,
      'n': imageCount,
    };
  }

  Map<String, String> toMultipartFields() {
    return {
      'model': _effectiveModel,
      'prompt': _mergedPrompt,
      'size': size,
      'n': imageCount.toString(),
    };
  }

  String get _effectiveModel => model.isEmpty ? 'gpt-image-2' : model;

  String get _mergedPrompt {
    final negative = negativePrompt.trim();
    if (negative.isEmpty) {
      return prompt;
    }

    return '$prompt\n\nAvoid: $negative';
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    final fallback = trimmed.isEmpty ? 'https://api.openai.com/v1' : trimmed;
    return fallback.replaceFirst(RegExp(r'/+$'), '');
  }
}

class OpenAIImageResponse {
  const OpenAIImageResponse({required this.images});

  final List<GeneratedImage> images;
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
      final bytes = await File(sourceFrame.path).readAsBytes();
      final frame = image_lib.decodeImage(bytes);
      if (frame == null) {
        throw GifComposerException(
          '无法解析图片：${_fileNameFromPath(sourceFrame.path)}',
        );
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
  });

  factory ApiConfig.defaults() {
    return const ApiConfig(
      id: 'default',
      name: '默认配置',
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      model: 'gpt-image-2',
    );
  }

  factory ApiConfig.fromSettings(AppSettings settings) {
    return ApiConfig(
      id: 'default',
      name: '默认配置',
      baseUrl: settings.baseUrl,
      apiKey: settings.apiKey,
      model: settings.model,
    );
  }

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    final defaults = ApiConfig.defaults();
    return ApiConfig(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? defaults.name,
      baseUrl: json['baseUrl'] as String? ?? defaults.baseUrl,
      apiKey: json['apiKey'] as String? ?? defaults.apiKey,
      model: json['model'] as String? ?? defaults.model,
    );
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String model;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
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
    );
  }

  final String baseUrl;
  final String apiKey;
  final String model;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'size': size,
      'imageCount': imageCount,
    };
  }
}

class GenerationHistoryEntry {
  const GenerationHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.baseUrl,
    required this.model,
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
    required this.resultCount,
  });

  factory GenerationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return GenerationHistoryEntry(
      id: json['id'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      baseUrl: json['baseUrl'] as String? ?? '',
      model: json['model'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      negativePrompt: json['negativePrompt'] as String? ?? '',
      size: json['size'] as String? ?? '',
      imageCount: (json['imageCount'] as num?)?.toInt() ?? 1,
      resultCount: (json['resultCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final DateTime createdAt;
  final String baseUrl;
  final String model;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final int resultCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'baseUrl': baseUrl,
      'model': model,
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'size': size,
      'imageCount': imageCount,
      'resultCount': resultCount,
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
  static const String _historyKey = 'history.entries';
  static const int _maxHistoryEntries = 20;

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

  Future<List<GenerationHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (entry) =>
              GenerationHistoryEntry.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList()
        .reversed
        .toList();
  }

  Future<void> saveHistory(List<GenerationHistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = history.take(_maxHistoryEntries).toList();
    await prefs.setString(
      _historyKey,
      jsonEncode(normalized.reversed.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> addHistoryEntry(GenerationHistoryEntry entry) async {
    final history = await loadHistory();
    await saveHistory([entry, ...history]);
  }

  Future<void> deleteGeneratedImageFiles(
    String historyId,
    int resultCount,
  ) async {
    final directory = await ensureGeneratedImagesDirectory();
    for (var index = 0; index < resultCount; index++) {
      final file = File(
        '${directory.path}${Platform.pathSeparator}${historyId}_${(index + 1).toString().padLeft(2, '0')}.png',
      );
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> clearGeneratedImageFiles() async {
    final directory = await ensureGeneratedImagesDirectory();
    if (!await directory.exists()) {
      return;
    }

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File) {
        await entity.delete();
      } else if (entity is Directory) {
        await entity.delete(recursive: true);
      }
    }
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
    required String historyId,
    required int index,
    required Uint8List bytes,
  }) async {
    final directory = await ensureGeneratedImagesDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}${historyId}_${(index + 1).toString().padLeft(2, '0')}.png',
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

  Future<File> createGeneratedSpriteSheetFile({
    required int directionCount,
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
      'sheet_${rows}x${columns}_${directionCount}dir_$dateStamp.png',
    );
  }
}
