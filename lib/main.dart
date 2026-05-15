import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'src/models/api_provider.dart';
import 'src/models/app_config.dart';
import 'src/models/exceptions.dart';
import 'src/models/image_asset_kind.dart';
import 'src/models/generated_image.dart';
import 'src/models/image_library_item.dart';
import 'src/models/image_advanced_settings.dart';
import 'src/models/sprite_sheet_frame_fit.dart';
import 'src/models/workspace_feature.dart';
import 'src/models/ui_state.dart';
import 'src/services/api_config_service.dart';
import 'src/services/app_local_store.dart';
import 'src/services/gif_composer_service.dart';
import 'src/services/image_api_client.dart';
import 'src/services/image_generation_service.dart';
import 'src/services/image_library_file_service.dart';
import 'src/services/image_library_service.dart';
import 'src/services/sprite_sheet_service.dart';
import 'src/utils/api_config_logic.dart';
import 'src/utils/app_defaults.dart';
import 'src/utils/display_labels.dart';
import 'src/utils/file_type_groups.dart';
import 'src/utils/generation_snapshot_summary.dart';
import 'src/utils/image_library_deletion.dart';
import 'src/utils/image_library_generation_reuse.dart';
import 'src/utils/image_library_view_data.dart';
import 'src/utils/image_selection_logic.dart';
import 'src/utils/image_dimensions.dart';
import 'src/utils/list_reorder.dart';
import 'src/widgets/app_dialogs.dart';
import 'src/widgets/layout_navigation_widgets.dart';
import 'src/widgets/workspaces.dart';
export 'src/models/api_provider.dart';
export 'src/models/app_config.dart';
export 'src/models/exceptions.dart';
export 'src/models/image_asset_kind.dart';
export 'src/models/generated_image.dart';
export 'src/models/image_library_item.dart';
export 'src/models/image_advanced_settings.dart';
export 'src/models/sprite_sheet_frame_fit.dart';
export 'src/models/workspace_feature.dart';
export 'src/models/ui_state.dart';
export 'src/services/api_config_service.dart';
export 'src/services/app_local_store.dart';
export 'src/services/gif_composer_service.dart';
export 'src/services/image_api_client.dart';
export 'src/services/image_generation_service.dart';
export 'src/services/image_library_file_service.dart';
export 'src/services/image_library_service.dart';
export 'src/services/sprite_sheet_service.dart';
export 'src/utils/api_config_logic.dart';
export 'src/utils/app_defaults.dart';
export 'src/theme/layout_constants.dart';
export 'src/utils/date_formatting.dart';
export 'src/utils/display_labels.dart';
export 'src/utils/file_type_groups.dart';
export 'src/utils/generation_snapshot_summary.dart';
export 'src/utils/image_generation_builders.dart';
export 'src/utils/image_library_deletion.dart';
export 'src/utils/image_library_filters.dart';
export 'src/utils/image_library_generation_reuse.dart';
export 'src/utils/image_library_view_data.dart';
export 'src/utils/image_selection_logic.dart';
export 'src/utils/image_dimensions.dart';
export 'src/utils/list_reorder.dart';
export 'src/utils/sprite_sheet_text.dart';
export 'src/widgets/common_form_widgets.dart';
export 'src/widgets/api_settings_widgets.dart';
export 'src/widgets/app_dialogs.dart';
export 'src/widgets/editor_gif_widgets.dart';
export 'src/widgets/generation_form_widgets.dart';
export 'src/widgets/image_library_widgets.dart';
export 'src/widgets/image_advanced_settings_widgets.dart';
export 'src/widgets/image_size_widgets.dart';
export 'src/widgets/layout_navigation_widgets.dart';
export 'src/widgets/local_settings_widgets.dart';
export 'src/widgets/preview_widgets.dart';
export 'src/widgets/workspaces.dart';

part 'src/home/api_config_state.dart';
part 'src/home/image_library_state.dart';
part 'src/home/local_settings_state.dart';

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

class _FeatherCanvasHomePageState extends State<FeatherCanvasHomePage>
    with
        _ApiConfigStateMixin,
        _LocalSettingsStateMixin,
        _ImageLibraryStateMixin {
  final TextEditingController _animationPromptController =
      TextEditingController(text: defaultAnimationPrompt);

  @override
  final OpenAICompatibleImageClient _client = OpenAICompatibleImageClient();
  @override
  final AppLocalStore _store = AppLocalStore();
  final ImageGenerationService _imageGenerationService =
      const ImageGenerationService();
  final ScrollController _scrollController = ScrollController();

  @override
  WorkspaceFeature _selectedFeature = WorkspaceFeature.imageGeneration;
  int _animationRows = defaultAnimationRows;
  int _animationColumns = defaultAnimationColumns;
  int _editorRows = defaultEditorRows;
  int _editorColumns = defaultEditorColumns;
  int _editorTargetFrameIndex = defaultEditorTargetFrameIndex;
  SpriteSheetFrameFit _editorFrameFit = defaultEditorFrameFit;
  bool _isGenerating = false;
  bool _isGeneratingAnimation = false;
  bool _isComposingGif = false;
  bool _isReplacingEditorFrame = false;
  @override
  bool _isBootstrapping = true;
  @override
  bool _isRestoringState = false;
  @override
  String? _errorMessage;
  String? _animationErrorMessage;
  ImageRequestDebugRecord? _imageRequestDebugRecord;
  ImageRequestDebugRecord? _animationRequestDebugRecord;
  @override
  List<GeneratedImage> _generatedImages = const [];
  @override
  List<GeneratedImage> _animationFrames = const [];
  final Set<String> _ephemeralTemplatePaths = <String>{};
  @override
  String? _animationTemplateImagePath;
  @override
  String? _editorImagePath;
  @override
  String? _editorPatchImagePath;
  @override
  String? _editorErrorMessage;
  @override
  List<GifSourceFrame> _gifSourceFrames = const [];
  String? _gifOutputPath;
  String? _gifErrorMessage;
  int _gifDefaultFrameDelayMs = defaultGifFrameDelayMs;
  int _gifLoopCount = defaultGifLoopCount;
  GifPlaybackMode _gifPlaybackMode = defaultGifPlaybackMode;

  int get _animationFrameCount => _animationRows * _animationColumns;
  int get _editorFrameCount => _editorRows * _editorColumns;

  @override
  void initState() {
    super.initState();

    _initApiConfigState();
    _initLocalSettingsState();

    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _disposeApiConfigState();
    _disposeLocalSettingsState();
    _disposeImageLibraryState();
    _client.close();
    _scrollController.dispose();
    _animationPromptController.dispose();
    for (final path in _ephemeralTemplatePaths) {
      unawaited(_fileService.safeDeleteFile(path));
    }
    _ephemeralTemplatePaths.clear();
    super.dispose();
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
    final selectedApiConfig = resolveApiConfig(
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
      _size = imageDimensionsFromSize(settings.size).size;
      _imageCount = settings.imageCount;
      _advancedSettings = settings.advancedSettings;
      _imageLibrary = imageLibrary;
      _isBootstrapping = false;
    });
    _isRestoringState = false;
    await _store.saveApiConfigs(apiConfigs);
    await _store.saveSelectedApiConfigId(selectedApiConfig.id);
  }

  @override
  Future<void> _selectFeature(WorkspaceFeature feature) async {
    if (_selectedFeature == feature) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _selectedFeature = feature);
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
    List<XTypeGroup> acceptedTypeGroups = imageTypeGroups,
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

    if (source == ImagePickSource.localFile) {
      final image = await openFile(acceptedTypeGroups: acceptedTypeGroups);
      return image?.path;
    }

    final item = await _showImageLibraryPicker<ImageLibraryItem>(
      title: title,
      allowedKinds: allowedLibraryKinds,
    );
    return item?.path;
  }

  Future<ImagePickSource?> _selectImagePickSource({
    required String title,
    required bool allowLibrary,
    String? libraryEmptyMessage,
  }) {
    if (!mounted) {
      return Future.value();
    }

    return showImagePickSourceDialog(
      context,
      title: title,
      allowLibrary: allowLibrary,
      libraryEmptyMessage: libraryEmptyMessage,
    );
  }

  Future<void> _pickEditorImage() async {
    final imagePath = await _pickSingleImagePathFromSource(
      title: '选择 Sprite Sheet 图片',
      libraryEmptyMessage: '生成或导出 Sprite Sheet 后可从这里复用',
      allowedLibraryKinds: spriteSheetLibraryKinds,
    );

    if (imagePath == null || !mounted) {
      return;
    }

    setState(() {
      _editorImagePath = imagePath;
      _editorErrorMessage = null;
    });
    _showMessage('已载入图片：${fileNameFromPath(imagePath)}');
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
      allowedLibraryKinds: singleFrameLibraryKinds,
    );

    if (imagePath == null || !mounted) {
      return;
    }

    setState(() {
      _editorPatchImagePath = imagePath;
      _editorErrorMessage = null;
    });
    _showMessage('已选择单帧图片：${fileNameFromPath(imagePath)}');
  }

  void _clearEditorPatchImage() {
    setState(() {
      _editorPatchImagePath = null;
      _editorErrorMessage = null;
    });
  }

  Future<void> _pickAnimationTemplateImage() async {
    final candidates = _availableImageLibraryItems(
      allowedKinds: templateLibraryKinds,
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
    if (source == ImagePickSource.localFile) {
      final image = await openFile(acceptedTypeGroups: templateImageTypeGroups);
      imagePath = image?.path;
    } else {
      final item = await _showImageLibraryPicker<ImageLibraryItem>(
        title: '选择模板图片',
        allowedKinds: templateLibraryKinds,
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
      unawaited(_fileService.safeDeleteFile(previous));
    }
    _showMessage(
      sliceLabel != null
          ? '已选择模板切片：$sliceLabel'
          : '已选择模板图片：${fileNameFromPath(imagePath)}',
    );
  }

  void _clearAnimationTemplateImage() {
    final previous = _animationTemplateImagePath;
    setState(() => _animationTemplateImagePath = null);
    if (previous != null && _ephemeralTemplatePaths.remove(previous)) {
      unawaited(_fileService.safeDeleteFile(previous));
    }
  }

  Future<void> _pickGifSourceImages() async {
    final candidates = _availableImageLibraryItems(
      allowedKinds: gifSourceLibraryKinds,
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

    if (source == ImagePickSource.localFile) {
      final images = await openFiles(acceptedTypeGroups: imageTypeGroups);
      final paths = [for (final image in images) image.path];
      newFrames.addAll(
        buildGifFramesFromPaths(
          paths,
          delayMs: _gifDefaultFrameDelayMs,
          seedStart: seed,
        ),
      );
      seed += paths.length;
    } else {
      final items = await _showImageLibraryPicker<List<ImageLibraryItem>>(
        title: '选择 GIF 图片序列',
        allowMultiple: true,
        allowedKinds: gifSourceLibraryKinds,
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
          newFrames.addAll(
            buildGifFramesFromSlices(
              sheet: item,
              slices: picked,
              delayMs: _gifDefaultFrameDelayMs,
              seedStart: seed,
            ),
          );
          seed += picked.length;
        } else {
          newFrames.add(
            buildGifFrameFromLibraryItem(
              item,
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
    _promptController.text = defaultAppSettings.prompt;
    _negativePromptController.clear();
    _animationPromptController.text = defaultAnimationPrompt;
    _userController.clear();

    setState(() {
      _apiConfigs = [defaultApiConfig];
      _selectedApiConfigId = defaultApiConfig.id;
      _apiConfigProviderKind = defaultApiConfig.providerKind;
      _size = defaultAppSettings.size;
      _imageCount = defaultAppSettings.imageCount;
      _advancedSettings = defaultAppSettings.advancedSettings;
      _animationRows = defaultAnimationRows;
      _animationColumns = defaultAnimationColumns;
      _editorRows = defaultEditorRows;
      _editorColumns = defaultEditorColumns;
      _editorTargetFrameIndex = defaultEditorTargetFrameIndex;
      _editorFrameFit = defaultEditorFrameFit;
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
      _gifDefaultFrameDelayMs = defaultGifFrameDelayMs;
      _gifLoopCount = defaultGifLoopCount;
      _gifPlaybackMode = defaultGifPlaybackMode;
      _apiTestDebugRecord = null;
      _isTestingApiConfig = false;
    });

    _isRestoringState = false;
    await _store.saveApiConfigs([defaultApiConfig]);
    await _store.saveSelectedApiConfigId(defaultApiConfig.id);
    await _saveSettings();
    if (mounted) {
      _showMessage('表单已重置');
    }
  }

  Future<void> _generateImage() async {
    final apiConfig = await _prepareSelectedApiConfigForRequest();
    if (!mounted) {
      return;
    }

    final prompt = _promptController.text.trim();

    if (apiConfig.apiKey.trim().isEmpty) {
      _showMessage('请先在接口配置页填写 API Key');
      return;
    }

    if (prompt.isEmpty) {
      _showMessage('请先填写正向提示词');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _imageRequestDebugRecord = null;
      _generatedImages = const [];
    });

    try {
      final negativePrompt = _negativePromptController.text.trim();
      final user = _userController.text.trim();
      final result = await _imageGenerationService.generateTextImages(
        client: _client,
        store: _store,
        imageLibraryService: _imageLibraryService,
        apiConfig: apiConfig,
        prompt: prompt,
        negativePrompt: negativePrompt,
        size: _size,
        imageCount: _imageCount,
        advancedSettings: _advancedSettings,
        user: user,
        onDebugRecord: (record) => _imageRequestDebugRecord = record,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _generatedImages = result.cachedImages;
        _imageLibrary = [...result.libraryItems, ..._imageLibrary];
      });
      _showMessage('图片生成完成');
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
      setState(() => _errorMessage = '请求超时，请检查接口地址或稍后重试');
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

    if (templatePath != null && !await _fileService.fileExists(templatePath)) {
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
      final negativePrompt = _negativePromptController.text.trim();
      final user = _userController.text.trim();
      final result = await _imageGenerationService.generateSpriteSheet(
        client: _client,
        store: _store,
        imageLibraryService: _imageLibraryService,
        apiConfig: apiConfig,
        prompt: prompt,
        negativePrompt: negativePrompt,
        size: _size,
        rows: _animationRows,
        columns: _animationColumns,
        advancedSettings: _advancedSettings,
        user: user,
        templateImagePath: templatePath,
        onDebugRecord: (record) => _animationRequestDebugRecord = record,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _animationFrames = [result.cachedSheet];
        final libraryItem = result.libraryItem;
        if (libraryItem != null) {
          _imageLibrary = [libraryItem, ..._imageLibrary];
        }
      });
      _showMessage('Sprite Sheet 已生成，可在作品集中按需切片或直接导出');
    } on ImageGenerationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _animationErrorMessage = error.message);
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() => _animationErrorMessage = '请求超时，请检查接口地址或稍后重试');
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
      _showMessage('请至少选择 2 张图片');
      return;
    }

    setState(() {
      _isComposingGif = true;
      _gifErrorMessage = null;
      _gifOutputPath = null;
    });

    try {
      final output = await GifComposer.composeToStore(
        store: _store,
        frames: _gifSourceFrames,
        loopCount: _gifLoopCount,
        playbackMode: _gifPlaybackMode,
      );

      if (!mounted) {
        return;
      }

      final item = await _imageLibraryService.addGif(
        store: _store,
        path: output.path,
        frameCount: _gifSourceFrames.length,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _gifOutputPath = output.path;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _showMessage(
        'GIF 已生成：${fileNameFromPath(output.path)} · 目录：${output.directoryPath}',
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
    final output = await SpriteSheetFileService.exportPng(
      store: _store,
      pngBytes: pngBytes,
      rows: rows,
      columns: columns,
    );
    if (!mounted) {
      return;
    }
    final item = await _imageLibraryService.addExportedSpriteSheet(
      store: _store,
      path: output.path,
      rows: rows,
      columns: columns,
    );
    if (!mounted) {
      return;
    }
    setState(() => _imageLibrary = [item, ..._imageLibrary]);
    _showMessage(
      '已导出 Sprite Sheet：${fileNameFromPath(output.path)} · 目录：${output.directoryPath}',
    );
  }

  Future<void> _replaceEditorFrame() async {
    final sheetPath = _editorImagePath;
    final patchPath = _editorPatchImagePath;
    if (sheetPath == null) {
      _showMessage('请先选择一张 Sprite Sheet');
      return;
    }
    if (patchPath == null) {
      _showMessage('请先选择要插入的单帧图片');
      return;
    }

    setState(() {
      _isReplacingEditorFrame = true;
      _editorErrorMessage = null;
    });

    try {
      final output = await SpriteSheetFileService.replaceFrameAndSave(
        store: _store,
        readFileBytes: _fileService.readFileBytes,
        sheetPath: sheetPath,
        patchPath: patchPath,
        rows: _editorRows,
        columns: _editorColumns,
        frameIndex: _editorTargetFrameIndex,
        fit: _editorFrameFit,
      );

      if (!mounted) {
        return;
      }

      final item = await _imageLibraryService.addEditedSpriteSheet(
        store: _store,
        path: output.path,
        frameIndex: _editorTargetFrameIndex,
        rows: _editorRows,
        columns: _editorColumns,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _editorImagePath = output.path;
        _imageLibrary = [item, ..._imageLibrary];
      });
      _showMessage(
        '已替换第 ${_editorTargetFrameIndex + 1} 帧：${fileNameFromPath(output.path)} · 目录：${output.directoryPath}',
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

  @override
  Future<void> _confirmResetToDefaults() async {
    final shouldReset = await confirmResetToDefaultsDialog(context);
    if (shouldReset) {
      await _resetToDefaults();
    }
  }

  @override
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
            FeatureNavigationRail(
              selectedFeature: _selectedFeature,
              extended: navigationExtended,
              onFeatureSelected: (feature) =>
                  unawaited(_selectFeature(feature)),
              onOpenSettings: () =>
                  unawaited(_selectFeature(WorkspaceFeature.localSettings)),
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
      WorkspaceFeature.imageGeneration => _buildImageGenerationWorkspace(),
      WorkspaceFeature.frameAnimation => _buildFrameAnimationWorkspace(),
      WorkspaceFeature.imageEditor => _buildImageEditorWorkspace(),
      WorkspaceFeature.gifComposer => _buildGifComposerWorkspace(),
      WorkspaceFeature.imageLibrary => _buildImageLibraryWorkspace(),
      WorkspaceFeature.apiSettings => _buildApiSettingsWorkspace(),
      WorkspaceFeature.localSettings => _buildLocalSettingsWorkspace(),
    };
  }

  Widget _buildImageGenerationWorkspace() {
    return ImageGenerationWorkspace(
      controller: _scrollController,
      apiConfigs: _apiConfigs,
      selectedApiConfig: _selectedApiConfig,
      promptController: _promptController,
      negativePromptController: _negativePromptController,
      size: _size,
      imageCount: _imageCount,
      advancedSettings: _advancedSettings,
      userController: _userController,
      isGenerating: _isGenerating,
      errorMessage: _errorMessage,
      generatedImages: _generatedImages,
      debugRecord: _imageRequestDebugRecord,
      onApiConfigChanged: _selectApiConfig,
      onOpenApiSettings: () =>
          unawaited(_selectFeature(WorkspaceFeature.apiSettings)),
      onSizeChanged: _setSize,
      onImageCountChanged: _setImageCount,
      onAdvancedSettingsChanged: _setAdvancedSettings,
      onGenerate: _generateImage,
    );
  }

  Widget _buildFrameAnimationWorkspace() {
    return FrameAnimationWorkspace(
      apiConfigs: _apiConfigs,
      selectedApiConfig: _selectedApiConfig,
      promptController: _animationPromptController,
      negativePromptController: _negativePromptController,
      size: _size,
      rows: _animationRows,
      columns: _animationColumns,
      templateImagePath: _animationTemplateImagePath,
      advancedSettings: _advancedSettings,
      userController: _userController,
      isGenerating: _isGeneratingAnimation,
      errorMessage: _animationErrorMessage,
      debugRecord: _animationRequestDebugRecord,
      generatedImages: _animationFrames,
      onApiConfigChanged: _selectApiConfig,
      onOpenApiSettings: () =>
          unawaited(_selectFeature(WorkspaceFeature.apiSettings)),
      onSizeChanged: _setSize,
      onRowsChanged: _setAnimationRows,
      onColumnsChanged: _setAnimationColumns,
      onAdvancedSettingsChanged: _setAdvancedSettings,
      onPickTemplateImage: _pickAnimationTemplateImage,
      onClearTemplateImage: _clearAnimationTemplateImage,
      onGenerate: _generateAnimationFrames,
      onExportSpriteSheet: (bytes) => unawaited(
        _exportSpriteSheet(
          pngBytes: bytes,
          rows: _animationRows,
          columns: _animationColumns,
        ),
      ),
    );
  }

  Widget _buildImageEditorWorkspace() {
    return ImageEditorWorkspace(
      imagePath: _editorImagePath,
      patchImagePath: _editorPatchImagePath,
      rows: _editorRows,
      columns: _editorColumns,
      targetFrameIndex: _editorTargetFrameIndex.clamp(0, _editorFrameCount - 1),
      frameFit: _editorFrameFit,
      isReplacingFrame: _isReplacingEditorFrame,
      errorMessage: _editorErrorMessage,
      onPickImage: _pickEditorImage,
      onClearImage: _clearEditorImage,
      onPickPatchImage: _pickEditorPatchImage,
      onClearPatchImage: _clearEditorPatchImage,
      onRowsChanged: _setEditorRows,
      onColumnsChanged: _setEditorColumns,
      onTargetFrameChanged: _setEditorTargetFrameIndex,
      onFrameFitChanged: _setEditorFrameFit,
      onReplaceFrame: _replaceEditorFrame,
      onExportSpriteSheet: (bytes) => unawaited(
        _exportSpriteSheet(
          pngBytes: bytes,
          rows: _editorRows,
          columns: _editorColumns,
        ),
      ),
    );
  }

  Widget _buildGifComposerWorkspace() {
    return GifComposerWorkspace(
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
  }
}
