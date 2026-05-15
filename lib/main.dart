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
part 'src/home/editor_gif_state.dart';
part 'src/home/home_shell_state.dart';
part 'src/home/image_generation_state.dart';
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
        _ImageLibraryStateMixin,
        _EditorGifStateMixin,
        _ImageGenerationStateMixin,
        _HomeShellStateMixin {
  @override
  final TextEditingController _animationPromptController =
      TextEditingController(text: defaultAnimationPrompt);

  @override
  final OpenAICompatibleImageClient _client = OpenAICompatibleImageClient();
  @override
  final AppLocalStore _store = AppLocalStore();
  @override
  final ImageGenerationService _imageGenerationService =
      const ImageGenerationService();
  @override
  final ScrollController _scrollController = ScrollController();

  @override
  WorkspaceFeature _selectedFeature = WorkspaceFeature.imageGeneration;
  @override
  int _animationRows = defaultAnimationRows;
  @override
  int _animationColumns = defaultAnimationColumns;
  @override
  int _editorRows = defaultEditorRows;
  @override
  int _editorColumns = defaultEditorColumns;
  @override
  int _editorTargetFrameIndex = defaultEditorTargetFrameIndex;
  @override
  SpriteSheetFrameFit _editorFrameFit = defaultEditorFrameFit;
  @override
  bool _isGenerating = false;
  @override
  bool _isGeneratingAnimation = false;
  @override
  bool _isComposingGif = false;
  @override
  bool _isReplacingEditorFrame = false;
  @override
  bool _isBootstrapping = true;
  @override
  bool _isRestoringState = false;
  @override
  String? _errorMessage;
  @override
  String? _animationErrorMessage;
  @override
  ImageRequestDebugRecord? _imageRequestDebugRecord;
  @override
  ImageRequestDebugRecord? _animationRequestDebugRecord;
  @override
  List<GeneratedImage> _generatedImages = const [];
  @override
  List<GeneratedImage> _animationFrames = const [];
  @override
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
  @override
  String? _gifOutputPath;
  @override
  String? _gifErrorMessage;
  @override
  int _gifDefaultFrameDelayMs = defaultGifFrameDelayMs;
  @override
  int _gifLoopCount = defaultGifLoopCount;
  @override
  GifPlaybackMode _gifPlaybackMode = defaultGifPlaybackMode;

  @override
  int get _animationFrameCount => _animationRows * _animationColumns;
  @override
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
}
