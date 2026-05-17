import 'dart:async';
import 'dart:io' show Platform;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/l10n/generated/app_localizations.dart';
import 'src/state/batch_generation_notifier.dart';
import 'src/state/gif_composer_notifier.dart';
import 'src/state/image_editor_notifier.dart';
import 'src/state/image_generation_notifier.dart';
import 'src/state/image_library_notifier.dart';
import 'src/theme/app_theme.dart';
import 'src/theme/layout_constants.dart';

import 'src/history/history_action.dart';
import 'src/history/history_intents.dart';
import 'src/history/history_stack.dart';
import 'src/models/animation_project.dart';
import 'src/models/api_provider.dart';
import 'src/models/app_config.dart';
import 'src/models/app_preset.dart';
import 'src/models/batch_generation_job.dart';
import 'src/models/exceptions.dart';
import 'src/models/image_asset_kind.dart';
import 'src/models/generated_image.dart';
import 'src/models/image_library_item.dart';
import 'src/models/image_advanced_settings.dart';
import 'src/models/sprite_sheet_frame_fit.dart';
import 'src/models/sprite_sheet_grid_spec.dart';
import 'src/models/workspace_feature.dart';
import 'src/models/ui_state.dart';
import 'src/services/api_config_service.dart';
import 'src/services/animation_project_service.dart';
import 'src/services/app_local_store.dart';
import 'src/services/batch_image_generation_service.dart';
import 'src/services/background_transparency_service.dart';
import 'src/services/gif_composer_service.dart';
import 'src/services/general_image_editing_service.dart';
import 'src/services/image_api_client.dart';
import 'src/services/image_generation_service.dart';
import 'src/services/image_library_archive_service.dart';
import 'src/services/image_library_file_service.dart';
import 'src/services/image_library_service.dart';
import 'src/services/patch_image_framing_service.dart';
import 'src/services/pixelation_service.dart';
import 'src/services/sprite_sheet_service.dart';
import 'src/shortcuts/app_shortcuts.dart';
import 'src/utils/api_config_logic.dart';
import 'src/utils/app_defaults.dart';
import 'src/utils/batch_generation_queue.dart';
import 'src/utils/display_labels.dart';
import 'src/utils/file_type_groups.dart';
import 'src/utils/generation_limits.dart';
import 'src/utils/generation_snapshot_summary.dart';
import 'src/utils/image_library_deletion.dart';
import 'src/utils/image_library_generation_reuse.dart';
import 'src/utils/image_library_view_data.dart';
import 'src/utils/image_selection_logic.dart';
import 'src/utils/image_dimensions.dart';
import 'src/utils/list_reorder.dart';
import 'src/widgets/app_dialogs.dart';
import 'src/widgets/background_transparency_dialog.dart';
import 'src/widgets/layout_navigation_widgets.dart';
import 'src/widgets/patch_image_framing_dialog.dart';
import 'src/widgets/workspaces.dart';
part 'src/home/api_config_state.dart';
part 'src/home/batch_generation_state.dart';
part 'src/home/editor_gif_state.dart';
part 'src/home/history_state.dart';
part 'src/home/home_shell_state.dart';
part 'src/home/image_generation_state.dart';
part 'src/home/image_library_state.dart';
part 'src/home/local_settings_state.dart';

const String _themeModePrefsKey = 'app.themeMode';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.system);

ThemeMode _decodeThemeMode(String? raw) {
  switch (raw) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

String _encodeThemeMode(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

Future<void> setAppThemeMode(ThemeMode mode) async {
  appThemeMode.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themeModePrefsKey, _encodeThemeMode(mode));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  appThemeMode.value = _decodeThemeMode(prefs.getString(_themeModePrefsKey));
  runApp(const FeatherCanvasApp());
}

class FeatherCanvasApp extends StatelessWidget {
  const FeatherCanvasApp({super.key});

  static String? get _platformFontFamily {
    if (kIsWeb) return null;
    if (Platform.isWindows) return 'Microsoft YaHei UI';
    return null;
  }

  static const List<String> _platformFontFallback = <String>[
    'Microsoft YaHei',
    'PingFang SC',
    'Hiragino Sans GB',
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    'WenQuanYi Micro Hei',
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'FeatherCanvas Studio',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light().copyWith(
            textTheme: AppTheme.light().textTheme.apply(
              fontFamily: _platformFontFamily,
              fontFamilyFallback: _platformFontFallback,
            ),
          ),
          darkTheme: AppTheme.dark().copyWith(
            textTheme: AppTheme.dark().textTheme.apply(
              fontFamily: _platformFontFamily,
              fontFamilyFallback: _platformFontFallback,
            ),
          ),
          themeMode: mode,
          home: const FeatherCanvasHomePage(),
        );
      },
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
        _BatchGenerationStateMixin,
        _HistoryStateMixin,
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
  final AnimationProjectImporter _animationProjectImporter =
      const AnimationProjectImporter();
  @override
  final AnimationProjectStore _animationProjectStore =
      const AnimationProjectStore();
  @override
  final AnimationProjectExportService _animationProjectExportService =
      const AnimationProjectExportService();
  @override
  final ScrollController _scrollController = ScrollController();

  @override
  final ImageGenerationNotifier _imageGenerationNotifier =
      ImageGenerationNotifier();

  @override
  final BatchGenerationNotifier _batchGenerationNotifier =
      BatchGenerationNotifier();

  @override
  WorkspaceFeature _selectedFeature = WorkspaceFeature.imageGeneration;
  @override
  int _animationRows = defaultAnimationRows;
  @override
  int _animationColumns = defaultAnimationColumns;
  @override
  SpriteSheetGridSpec _animationGridSpec = const SpriteSheetGridSpec(
    rows: defaultAnimationRows,
    columns: defaultAnimationColumns,
  );
  @override
  // ignore: unused_element
  bool get _isGenerating => _imageGenerationNotifier.isGenerating;
  @override
  // ignore: unused_element
  set _isGenerating(bool value) =>
      _imageGenerationNotifier.isGenerating = value;
  @override
  bool _isGeneratingAnimation = false;
  @override
  bool _isAnimationProjectBusy = false;
  @override
  bool _isBootstrapping = true;
  @override
  bool _isRestoringState = false;
  @override
  List<AppPreset> _appPresets = const [];
  @override
  String? get _errorMessage => _imageGenerationNotifier.errorMessage;
  @override
  set _errorMessage(String? value) =>
      _imageGenerationNotifier.errorMessage = value;
  @override
  String? _animationErrorMessage;
  @override
  String? _animationProjectErrorMessage;
  @override
  ImageRequestDebugRecord? get _imageRequestDebugRecord =>
      _imageGenerationNotifier.debugRecord;
  @override
  set _imageRequestDebugRecord(ImageRequestDebugRecord? value) =>
      _imageGenerationNotifier.debugRecord = value;
  @override
  ImageRequestDebugRecord? _animationRequestDebugRecord;
  @override
  List<GeneratedImage> get _generatedImages =>
      _imageGenerationNotifier.generatedImages;
  @override
  set _generatedImages(List<GeneratedImage> value) =>
      _imageGenerationNotifier.generatedImages = value;
  @override
  List<GeneratedImage> _animationFrames = const [];
  @override
  AnimationProject? _animationProject;
  @override
  String? _selectedAnimationTrackId;
  @override
  final Set<String> _ephemeralTemplatePaths = <String>{};
  @override
  String? _animationTemplateImagePath;
  WorkspaceFeature? _focusedFeature;
  @override
  bool get _isImageEditorFocusMode =>
      _focusedFeature == WorkspaceFeature.imageEditor;
  @override
  set _isImageEditorFocusMode(bool value) {
    if (value) {
      _focusedFeature = WorkspaceFeature.imageEditor;
    } else if (_focusedFeature == WorkspaceFeature.imageEditor) {
      _focusedFeature = null;
    }
  }

  @override
  bool get _isPixelArtFocusMode =>
      _focusedFeature == WorkspaceFeature.pixelArtEditor;
  @override
  set _isPixelArtFocusMode(bool value) {
    if (value) {
      _focusedFeature = WorkspaceFeature.pixelArtEditor;
    } else if (_focusedFeature == WorkspaceFeature.pixelArtEditor) {
      _focusedFeature = null;
    }
  }

  @override
  final GifComposerNotifier _gifComposerNotifier = GifComposerNotifier();

  @override
  final ImageEditorNotifier _imageEditorNotifier = ImageEditorNotifier();

  @override
  final ImageLibraryNotifier _imageLibraryNotifier = ImageLibraryNotifier();

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
    _disposeBatchGenerationState();
    _disposeHistoryState();
    _client.close();
    _scrollController.dispose();
    _animationPromptController.dispose();
    _imageGenerationNotifier.dispose();
    _batchGenerationNotifier.dispose();
    _gifComposerNotifier.dispose();
    _imageEditorNotifier.dispose();
    _imageLibraryNotifier.dispose();
    for (final path in _ephemeralTemplatePaths) {
      unawaited(_fileService.safeDeleteFile(path));
    }
    _ephemeralTemplatePaths.clear();
    unawaited(_fileService.purgeCurrentTrashSession());
    super.dispose();
  }
}
