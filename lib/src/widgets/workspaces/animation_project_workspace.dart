import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/animation_project.dart';
import '../../models/app_config.dart';
import '../../models/generated_image.dart';
import '../../models/image_advanced_settings.dart';
import '../../models/sprite_sheet_grid_spec.dart';
import '../../services/animation_project_service.dart';
import '../../services/gif_composer_service.dart';
import '../../services/image_api_client.dart';
import '../../services/sprite_sheet_service.dart';
import '../../l10n/app_l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/layout_constants.dart';
import '../../utils/display_labels.dart' show fileNameFromPath;
import '../../utils/localized_display_labels.dart';
import '../common_form_widgets.dart';
import '../generation_form_widgets.dart';
import '../layout_navigation_widgets.dart';
import '../preview_common_widgets.dart';

class AnimationProjectWorkspace extends StatelessWidget {
  const AnimationProjectWorkspace({
    required this.apiConfigs,
    required this.selectedApiConfig,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.rows,
    required this.columns,
    required this.gridSpec,
    required this.templateImagePath,
    required this.advancedSettings,
    required this.userController,
    required this.isGenerating,
    required this.errorMessage,
    required this.debugRecord,
    required this.generatedImages,
    required this.project,
    required this.selectedTrackId,
    required this.isProjectBusy,
    required this.projectErrorMessage,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onGridSpecChanged,
    required this.onAdvancedSettingsChanged,
    required this.onPickTemplateImage,
    required this.onClearTemplateImage,
    required this.onGenerate,
    required this.onImportGeneratedSheet,
    required this.onImportImageSequence,
    required this.onImportLibraryImageSequence,
    required this.onClearProject,
    required this.onTrackSelected,
    required this.onTrackAdded,
    required this.onTrackDuplicated,
    required this.onTrackDeleted,
    required this.onTrackMoved,
    required this.onTrackRenamed,
    required this.onProjectDefaultDelayChanged,
    required this.onProjectPlaybackModeChanged,
    required this.onProjectLoopCountChanged,
    required this.onProjectIncludeHiddenTracksChanged,
    required this.onTrackDelayChanged,
    required this.onTrackPlaybackModeChanged,
    required this.onTrackVisibilityChanged,
    required this.onTrackLockChanged,
    required this.onFrameMoved,
    required this.onFrameDuplicated,
    required this.onFrameDeleted,
    required this.onFrameDelayChanged,
    required this.onFrameTransformChanged,
    required this.onFrameReplaced,
    required this.onFrameCleared,
    required this.onFramePixelated,
    required this.onBlankFrameInserted,
    required this.onImageFrameInserted,
    required this.onFrameAssetRebound,
    required this.onProjectAutoRepaired,
    required this.onExportProjectSpriteSheet,
    required this.onExportProjectGif,
    required this.onExportProjectPngSequence,
    required this.onExportTrackGif,
    required this.onExportTrackPngSequence,
    required this.onExportSourceSpriteSheet,
    this.enablePreviewPlayback = true,
    this.historyControls,
    super.key,
  });

  final List<ApiConfig> apiConfigs;
  final ApiConfig selectedApiConfig;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;
  final String? templateImagePath;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final bool isGenerating;
  final String? errorMessage;
  final ImageRequestDebugRecord? debugRecord;
  final List<GeneratedImage> generatedImages;
  final AnimationProject? project;
  final String? selectedTrackId;
  final bool isProjectBusy;
  final String? projectErrorMessage;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<SpriteSheetGridSpec> onGridSpecChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onPickTemplateImage;
  final VoidCallback onClearTemplateImage;
  final VoidCallback onGenerate;
  final VoidCallback onImportGeneratedSheet;
  final VoidCallback onImportImageSequence;
  final VoidCallback onImportLibraryImageSequence;
  final VoidCallback onClearProject;
  final ValueChanged<String> onTrackSelected;
  final VoidCallback onTrackAdded;
  final ValueChanged<String> onTrackDuplicated;
  final ValueChanged<String> onTrackDeleted;
  final void Function(String trackId, int delta) onTrackMoved;
  final void Function(String trackId, String name) onTrackRenamed;
  final ValueChanged<int> onProjectDefaultDelayChanged;
  final ValueChanged<AnimationPlaybackMode> onProjectPlaybackModeChanged;
  final ValueChanged<int> onProjectLoopCountChanged;
  final ValueChanged<bool> onProjectIncludeHiddenTracksChanged;
  final void Function(String trackId, int delayMs) onTrackDelayChanged;
  final void Function(String trackId, AnimationPlaybackMode mode)
  onTrackPlaybackModeChanged;
  final void Function(String trackId, bool visible) onTrackVisibilityChanged;
  final void Function(String trackId, bool locked) onTrackLockChanged;
  final void Function(String trackId, int fromIndex, int toIndex) onFrameMoved;
  final void Function(String trackId, int frameIndex) onFrameDuplicated;
  final void Function(String trackId, int frameIndex) onFrameDeleted;
  final void Function(String trackId, int frameIndex, int delayMs)
  onFrameDelayChanged;
  final void Function(String trackId, int frameIndex, FrameTransform transform)
  onFrameTransformChanged;
  final void Function(String trackId, int frameIndex) onFrameReplaced;
  final void Function(String trackId, int frameIndex) onFrameCleared;
  final void Function(String trackId, int frameIndex, int blockSize)
  onFramePixelated;
  final void Function(String trackId, int insertIndex) onBlankFrameInserted;
  final void Function(String trackId, int insertIndex) onImageFrameInserted;
  final ValueChanged<String> onFrameAssetRebound;
  final VoidCallback onProjectAutoRepaired;
  final VoidCallback onExportProjectSpriteSheet;
  final VoidCallback onExportProjectGif;
  final VoidCallback onExportProjectPngSequence;
  final VoidCallback onExportTrackGif;
  final VoidCallback onExportTrackPngSequence;
  final ValueChanged<Uint8List> onExportSourceSpriteSheet;
  final bool enablePreviewPlayback;
  final Widget? historyControls;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final currentProject = project;
    final generationPanel = _buildGenerationPanel();
    return WorkspacePage(
      title: l10n.navAnimationProject,
      description: l10n.animationProjectWorkspaceDescription,
      trailing: historyControls,
      scrollable: currentProject == null,
      children: [
        if (currentProject == null)
          _AnimationProjectCreationView(
            generatedImages: generatedImages,
            rows: rows,
            columns: columns,
            gridSpec: gridSpec,
            isBusy: isProjectBusy,
            isGenerating: isGenerating,
            errorMessage: projectErrorMessage ?? errorMessage,
            debugRecord: debugRecord,
            generationPanel: generationPanel,
            onImportGeneratedSheet: onImportGeneratedSheet,
            onImportImageSequence: onImportImageSequence,
            onImportLibraryImageSequence: onImportLibraryImageSequence,
            onExportSourceSpriteSheet: onExportSourceSpriteSheet,
          )
        else
          Expanded(
            child: _AnimationProjectWorkbench(
              project: currentProject,
              selectedTrackId: selectedTrackId,
              generatedImages: generatedImages,
              isBusy: isProjectBusy,
              errorMessage: projectErrorMessage,
              onImportGeneratedSheet: onImportGeneratedSheet,
              onImportImageSequence: onImportImageSequence,
              onImportLibraryImageSequence: onImportLibraryImageSequence,
              onClearProject: onClearProject,
              onTrackSelected: onTrackSelected,
              onTrackAdded: onTrackAdded,
              onTrackDuplicated: onTrackDuplicated,
              onTrackDeleted: onTrackDeleted,
              onTrackMoved: onTrackMoved,
              onTrackRenamed: onTrackRenamed,
              onProjectDefaultDelayChanged: onProjectDefaultDelayChanged,
              onProjectPlaybackModeChanged: onProjectPlaybackModeChanged,
              onProjectLoopCountChanged: onProjectLoopCountChanged,
              onProjectIncludeHiddenTracksChanged:
                  onProjectIncludeHiddenTracksChanged,
              onTrackDelayChanged: onTrackDelayChanged,
              onTrackPlaybackModeChanged: onTrackPlaybackModeChanged,
              onTrackVisibilityChanged: onTrackVisibilityChanged,
              onTrackLockChanged: onTrackLockChanged,
              onFrameMoved: onFrameMoved,
              onFrameDuplicated: onFrameDuplicated,
              onFrameDeleted: onFrameDeleted,
              onFrameDelayChanged: onFrameDelayChanged,
              onFrameTransformChanged: onFrameTransformChanged,
              onFrameReplaced: onFrameReplaced,
              onFrameCleared: onFrameCleared,
              onFramePixelated: onFramePixelated,
              onBlankFrameInserted: onBlankFrameInserted,
              onImageFrameInserted: onImageFrameInserted,
              onFrameAssetRebound: onFrameAssetRebound,
              onProjectAutoRepaired: onProjectAutoRepaired,
              onExportProjectSpriteSheet: onExportProjectSpriteSheet,
              onExportProjectGif: onExportProjectGif,
              onExportProjectPngSequence: onExportProjectPngSequence,
              onExportTrackGif: onExportTrackGif,
              onExportTrackPngSequence: onExportTrackPngSequence,
              enablePlayback: enablePreviewPlayback,
            ),
          ),
      ],
    );
  }

  Widget _buildGenerationPanel() {
    return SpriteSheetGenerationPanel(
      apiConfigs: apiConfigs,
      selectedApiConfigId: selectedApiConfig.id,
      providerKind: selectedApiConfig.providerKind,
      model: selectedApiConfig.model,
      imageSizeCapabilityOverride:
          selectedApiConfig.imageSizeCapabilityOverride,
      promptController: promptController,
      negativePromptController: negativePromptController,
      size: size,
      rows: rows,
      columns: columns,
      gridSpec: gridSpec,
      templateImagePath: templateImagePath,
      advancedSettings: advancedSettings,
      userController: userController,
      isGenerating: isGenerating,
      onApiConfigChanged: onApiConfigChanged,
      onOpenApiSettings: onOpenApiSettings,
      onSizeChanged: onSizeChanged,
      onRowsChanged: onRowsChanged,
      onColumnsChanged: onColumnsChanged,
      onGridSpecChanged: onGridSpecChanged,
      onAdvancedSettingsChanged: onAdvancedSettingsChanged,
      onPickTemplateImage: onPickTemplateImage,
      onClearTemplateImage: onClearTemplateImage,
      onGenerate: onGenerate,
    );
  }
}

class _AnimationProjectCreationView extends StatelessWidget {
  const _AnimationProjectCreationView({
    required this.generatedImages,
    required this.rows,
    required this.columns,
    required this.gridSpec,
    required this.isBusy,
    required this.isGenerating,
    required this.errorMessage,
    required this.debugRecord,
    required this.generationPanel,
    required this.onImportGeneratedSheet,
    required this.onImportImageSequence,
    required this.onImportLibraryImageSequence,
    required this.onExportSourceSpriteSheet,
  });

  final List<GeneratedImage> generatedImages;
  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;
  final bool isBusy;
  final bool isGenerating;
  final String? errorMessage;
  final ImageRequestDebugRecord? debugRecord;
  final Widget generationPanel;
  final VoidCallback onImportGeneratedSheet;
  final VoidCallback onImportImageSequence;
  final VoidCallback onImportLibraryImageSequence;
  final ValueChanged<Uint8List> onExportSourceSpriteSheet;

  @override
  Widget build(BuildContext context) {
    return ResponsiveWorkspaceSplit(
      storageKey: 'animationProject.creation',
      controlsWidth: 440,
      minControlsWidth: 340,
      maxControlsWidth: 560,
      controls: generationPanel,
      preview: _AnimationProjectCreationPanel(
        generatedImages: generatedImages,
        rows: rows,
        columns: columns,
        gridSpec: gridSpec,
        isBusy: isBusy,
        isGenerating: isGenerating,
        errorMessage: errorMessage,
        debugRecord: debugRecord,
        onImportGeneratedSheet: onImportGeneratedSheet,
        onImportImageSequence: onImportImageSequence,
        onImportLibraryImageSequence: onImportLibraryImageSequence,
        onExportSourceSpriteSheet: onExportSourceSpriteSheet,
      ),
    );
  }
}

class _AnimationProjectCreationPanel extends StatefulWidget {
  const _AnimationProjectCreationPanel({
    required this.generatedImages,
    required this.rows,
    required this.columns,
    required this.gridSpec,
    required this.isBusy,
    required this.isGenerating,
    required this.errorMessage,
    required this.debugRecord,
    required this.onImportGeneratedSheet,
    required this.onImportImageSequence,
    required this.onImportLibraryImageSequence,
    required this.onExportSourceSpriteSheet,
  });

  final List<GeneratedImage> generatedImages;
  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;
  final bool isBusy;
  final bool isGenerating;
  final String? errorMessage;
  final ImageRequestDebugRecord? debugRecord;
  final VoidCallback onImportGeneratedSheet;
  final VoidCallback onImportImageSequence;
  final VoidCallback onImportLibraryImageSequence;
  final ValueChanged<Uint8List> onExportSourceSpriteSheet;

  @override
  State<_AnimationProjectCreationPanel> createState() =>
      _AnimationProjectCreationPanelState();
}

class _AnimationProjectCreationPanelState
    extends State<_AnimationProjectCreationPanel> {
  bool _isExporting = false;
  String? _exportErrorMessage;

  bool get _hasGeneratedSource => widget.generatedImages.isNotEmpty;

  Future<void> _exportSourceSpriteSheet() async {
    if (!_hasGeneratedSource || _isExporting) {
      return;
    }
    setState(() {
      _isExporting = true;
      _exportErrorMessage = null;
    });
    try {
      final preview = await SpriteSheetPreviewComposer.build(
        images: widget.generatedImages,
        rows: widget.rows,
        columns: widget.columns,
        gridSpec: widget.gridSpec,
      );
      widget.onExportSourceSpriteSheet(preview.sheetBytes);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _exportErrorMessage = '$error');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    final sourceText = _hasGeneratedSource
        ? widget.generatedImages.length == 1
              ? l10n.animationProjectGeneratedSourceGrid(
                  widget.rows,
                  widget.columns,
                  widget.gridSpec.totalFrameCount,
                )
              : l10n.animationProjectGeneratedSequenceSource(
                  widget.generatedImages.length,
                )
        : l10n.animationProjectNoImportSource;
    final canUseSource =
        _hasGeneratedSource && !widget.isBusy && !widget.isGenerating;

    return AppPanel(
      title: l10n.animationProjectCreateTitle,
      trailing: RequestDebugButton(record: widget.debugRecord),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CreationSourceSummary(
            label: sourceText,
            isGenerating: widget.isGenerating,
            hasSource: _hasGeneratedSource,
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: fieldGap),
            Text(
              widget.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (_exportErrorMessage != null) ...[
            const SizedBox(height: fieldGap),
            Text(
              _exportErrorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: sectionGap),
          PrimaryActionButton(
            onPressed: canUseSource ? widget.onImportGeneratedSheet : null,
            icon: Icons.account_tree_outlined,
            label: l10n.animationProjectImportAsProject,
            busyLabel: l10n.animationProjectImportingProject,
            isBusy: widget.isBusy,
          ),
          const SizedBox(height: fieldGap),
          Wrap(
            spacing: fieldGap,
            runSpacing: fieldGap,
            children: [
              OutlinedButton.icon(
                onPressed: widget.isBusy ? null : widget.onImportImageSequence,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(l10n.animationProjectImportLocalSequence),
              ),
              OutlinedButton.icon(
                onPressed: widget.isBusy
                    ? null
                    : widget.onImportLibraryImageSequence,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.animationProjectImportLibrarySequence),
              ),
              OutlinedButton.icon(
                onPressed: canUseSource && !_isExporting
                    ? _exportSourceSpriteSheet
                    : null,
                icon: ButtonProgressIcon(
                  isBusy: _isExporting,
                  icon: Icons.download_outlined,
                ),
                label: Text(
                  _isExporting
                      ? l10n.animationProjectExporting
                      : l10n.animationProjectExportSourceSpriteSheet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreationSourceSummary extends StatelessWidget {
  const _CreationSourceSummary({
    required this.label,
    required this.isGenerating,
    required this.hasSource,
  });

  final String label;
  final bool isGenerating;
  final bool hasSource;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            isGenerating
                ? Icons.hourglass_top_outlined
                : hasSource
                ? Icons.grid_on_outlined
                : Icons.account_tree_outlined,
            color: hasSource || isGenerating
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.animationProjectSourceTitle,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  isGenerating ? l10n.animationProjectGeneratingSource : label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimationProjectWorkbench extends StatefulWidget {
  const _AnimationProjectWorkbench({
    required this.project,
    required this.selectedTrackId,
    required this.generatedImages,
    required this.isBusy,
    required this.errorMessage,
    required this.onImportGeneratedSheet,
    required this.onImportImageSequence,
    required this.onImportLibraryImageSequence,
    required this.onClearProject,
    required this.onTrackSelected,
    required this.onTrackAdded,
    required this.onTrackDuplicated,
    required this.onTrackDeleted,
    required this.onTrackMoved,
    required this.onTrackRenamed,
    required this.onProjectDefaultDelayChanged,
    required this.onProjectPlaybackModeChanged,
    required this.onProjectLoopCountChanged,
    required this.onProjectIncludeHiddenTracksChanged,
    required this.onTrackDelayChanged,
    required this.onTrackPlaybackModeChanged,
    required this.onTrackVisibilityChanged,
    required this.onTrackLockChanged,
    required this.onFrameMoved,
    required this.onFrameDuplicated,
    required this.onFrameDeleted,
    required this.onFrameDelayChanged,
    required this.onFrameTransformChanged,
    required this.onFrameReplaced,
    required this.onFrameCleared,
    required this.onFramePixelated,
    required this.onBlankFrameInserted,
    required this.onImageFrameInserted,
    required this.onFrameAssetRebound,
    required this.onProjectAutoRepaired,
    required this.onExportProjectSpriteSheet,
    required this.onExportProjectGif,
    required this.onExportProjectPngSequence,
    required this.onExportTrackGif,
    required this.onExportTrackPngSequence,
    required this.enablePlayback,
  });

  final AnimationProject project;
  final String? selectedTrackId;
  final List<GeneratedImage> generatedImages;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onImportGeneratedSheet;
  final VoidCallback onImportImageSequence;
  final VoidCallback onImportLibraryImageSequence;
  final VoidCallback onClearProject;
  final ValueChanged<String> onTrackSelected;
  final VoidCallback onTrackAdded;
  final ValueChanged<String> onTrackDuplicated;
  final ValueChanged<String> onTrackDeleted;
  final void Function(String trackId, int delta) onTrackMoved;
  final void Function(String trackId, String name) onTrackRenamed;
  final ValueChanged<int> onProjectDefaultDelayChanged;
  final ValueChanged<AnimationPlaybackMode> onProjectPlaybackModeChanged;
  final ValueChanged<int> onProjectLoopCountChanged;
  final ValueChanged<bool> onProjectIncludeHiddenTracksChanged;
  final void Function(String trackId, int delayMs) onTrackDelayChanged;
  final void Function(String trackId, AnimationPlaybackMode mode)
  onTrackPlaybackModeChanged;
  final void Function(String trackId, bool visible) onTrackVisibilityChanged;
  final void Function(String trackId, bool locked) onTrackLockChanged;
  final void Function(String trackId, int fromIndex, int toIndex) onFrameMoved;
  final void Function(String trackId, int frameIndex) onFrameDuplicated;
  final void Function(String trackId, int frameIndex) onFrameDeleted;
  final void Function(String trackId, int frameIndex, int delayMs)
  onFrameDelayChanged;
  final void Function(String trackId, int frameIndex, FrameTransform transform)
  onFrameTransformChanged;
  final void Function(String trackId, int frameIndex) onFrameReplaced;
  final void Function(String trackId, int frameIndex) onFrameCleared;
  final void Function(String trackId, int frameIndex, int blockSize)
  onFramePixelated;
  final void Function(String trackId, int insertIndex) onBlankFrameInserted;
  final void Function(String trackId, int insertIndex) onImageFrameInserted;
  final ValueChanged<String> onFrameAssetRebound;
  final VoidCallback onProjectAutoRepaired;
  final VoidCallback onExportProjectSpriteSheet;
  final VoidCallback onExportProjectGif;
  final VoidCallback onExportProjectPngSequence;
  final VoidCallback onExportTrackGif;
  final VoidCallback onExportTrackPngSequence;
  final bool enablePlayback;

  @override
  State<_AnimationProjectWorkbench> createState() =>
      _AnimationProjectWorkbenchState();
}

class _AnimationProjectWorkbenchState
    extends State<_AnimationProjectWorkbench> {
  static const double _defaultControlsWidth = 420;
  static const double _minControlsWidth = 320;
  static const double _maxControlsWidth = 540;
  static const double _minPreviewWidth = 360;
  static const double _minStageHeight = 320;
  static const double _minTimelineHeight = 240;
  static const double _maxTimelineHeight = 520;
  static const String _controlsWidthPrefsKey =
      'animationProject.workbench.controlsWidth';
  static const String _timelineHeightPrefsKey =
      'animationProject.workbench.timelineHeight';

  double? _controlsWidth;
  double? _timelineHeight;

  @override
  void initState() {
    super.initState();
    _restoreLayout();
  }

  Future<void> _restoreLayout() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _controlsWidth = prefs.getDouble(_controlsWidthPrefsKey);
      _timelineHeight = prefs.getDouble(_timelineHeightPrefsKey);
    });
  }

  Future<void> _persistControlsWidth() async {
    final width = _controlsWidth;
    if (width == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_controlsWidthPrefsKey, width);
  }

  Future<void> _persistTimelineHeight() async {
    final height = _timelineHeight;
    if (height == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_timelineHeightPrefsKey, height);
  }

  Future<void> _resetControlsWidth() async {
    setState(() => _controlsWidth = _defaultControlsWidth);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_controlsWidthPrefsKey);
  }

  Future<void> _resetTimelineHeight(double defaultHeight) async {
    setState(() => _timelineHeight = defaultHeight);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timelineHeightPrefsKey);
  }

  double _defaultTimelineHeight(double maxHeight) {
    return maxHeight < 760 ? 280 : 320;
  }

  double _clampControlsWidth(double width, double maxWidth) {
    final availableMax = math.max(
      _minControlsWidth,
      maxWidth - layoutGap - _minPreviewWidth,
    );
    final maxControlsWidth = math.min(_maxControlsWidth, availableMax);
    return width.clamp(_minControlsWidth, maxControlsWidth).toDouble();
  }

  double _clampTimelineHeight(double height, double maxHeight) {
    final availableMax = math.max(
      _minTimelineHeight,
      maxHeight - WorkspaceResizeHandle.hitExtent - _minStageHeight,
    );
    final maxTimelineHeight = math.min(_maxTimelineHeight, availableMax);
    return height.clamp(_minTimelineHeight, maxTimelineHeight).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final defaultTimelineHeight = _defaultTimelineHeight(
          constraints.maxHeight,
        );
        final timelineHeight = _clampTimelineHeight(
          _timelineHeight ?? defaultTimelineHeight,
          constraints.maxHeight,
        );
        final compact =
            constraints.maxWidth < AppBreakpoints.medium ||
            constraints.maxHeight < 640;
        if (compact) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildControlPanel(),
                const SizedBox(height: layoutGap),
                _AnimationProjectPreview(
                  project: widget.project,
                  enablePlayback: widget.enablePlayback,
                ),
                const SizedBox(height: layoutGap),
                SizedBox(height: timelineHeight, child: _buildTimelineDock()),
              ],
            ),
          );
        }

        final controlsWidth = _clampControlsWidth(
          _controlsWidth ?? _defaultControlsWidth,
          constraints.maxWidth,
        );
        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: controlsWidth,
                    child: SingleChildScrollView(child: _buildControlPanel()),
                  ),
                  WorkspaceResizeHandle(
                    axis: Axis.vertical,
                    tooltip: appL10nOf(
                      context,
                    ).animationProjectResizeControlsTooltip,
                    onDragUpdate: (details) {
                      setState(() {
                        _controlsWidth = _clampControlsWidth(
                          controlsWidth + details.delta.dx,
                          constraints.maxWidth,
                        );
                      });
                    },
                    onDragEnd: _persistControlsWidth,
                    onDoubleTap: _resetControlsWidth,
                  ),
                  Expanded(
                    child: _AnimationProjectPreview(
                      project: widget.project,
                      enablePlayback: widget.enablePlayback,
                    ),
                  ),
                ],
              ),
            ),
            WorkspaceResizeHandle(
              axis: Axis.horizontal,
              tooltip: appL10nOf(context).animationProjectResizeTimelineTooltip,
              onDragUpdate: (details) {
                setState(() {
                  _timelineHeight = _clampTimelineHeight(
                    timelineHeight - details.delta.dy,
                    constraints.maxHeight,
                  );
                });
              },
              onDragEnd: _persistTimelineHeight,
              onDoubleTap: () => _resetTimelineHeight(defaultTimelineHeight),
            ),
            SizedBox(height: timelineHeight, child: _buildTimelineDock()),
          ],
        );
      },
    );
  }

  Widget _buildControlPanel() {
    return _AnimationProjectPanel(
      project: widget.project,
      generatedImages: widget.generatedImages,
      isBusy: widget.isBusy,
      errorMessage: widget.errorMessage,
      onImportGeneratedSheet: widget.onImportGeneratedSheet,
      onImportImageSequence: widget.onImportImageSequence,
      onImportLibraryImageSequence: widget.onImportLibraryImageSequence,
      onClearProject: widget.onClearProject,
      onTrackAdded: widget.onTrackAdded,
      onProjectDefaultDelayChanged: widget.onProjectDefaultDelayChanged,
      onProjectPlaybackModeChanged: widget.onProjectPlaybackModeChanged,
      onProjectLoopCountChanged: widget.onProjectLoopCountChanged,
      onProjectIncludeHiddenTracksChanged:
          widget.onProjectIncludeHiddenTracksChanged,
      onFrameAssetRebound: widget.onFrameAssetRebound,
      onProjectAutoRepaired: widget.onProjectAutoRepaired,
      onExportProjectSpriteSheet: widget.onExportProjectSpriteSheet,
      onExportProjectGif: widget.onExportProjectGif,
      onExportProjectPngSequence: widget.onExportProjectPngSequence,
      onExportTrackGif: widget.onExportTrackGif,
      onExportTrackPngSequence: widget.onExportTrackPngSequence,
    );
  }

  Widget _buildTimelineDock() {
    return _AnimationTimelineDock(
      project: widget.project,
      selectedTrackId: widget.selectedTrackId,
      onTrackSelected: widget.onTrackSelected,
      onTrackDuplicated: widget.onTrackDuplicated,
      onTrackDeleted: widget.onTrackDeleted,
      onTrackMoved: widget.onTrackMoved,
      onTrackRenamed: widget.onTrackRenamed,
      onTrackDelayChanged: widget.onTrackDelayChanged,
      onTrackPlaybackModeChanged: widget.onTrackPlaybackModeChanged,
      onTrackVisibilityChanged: widget.onTrackVisibilityChanged,
      onTrackLockChanged: widget.onTrackLockChanged,
      onFrameMoved: widget.onFrameMoved,
      onFrameDuplicated: widget.onFrameDuplicated,
      onFrameDeleted: widget.onFrameDeleted,
      onFrameDelayChanged: widget.onFrameDelayChanged,
      onFrameTransformChanged: widget.onFrameTransformChanged,
      onFrameReplaced: widget.onFrameReplaced,
      onFrameCleared: widget.onFrameCleared,
      onFramePixelated: widget.onFramePixelated,
      onBlankFrameInserted: widget.onBlankFrameInserted,
      onImageFrameInserted: widget.onImageFrameInserted,
    );
  }
}

class _AnimationProjectPanel extends StatelessWidget {
  const _AnimationProjectPanel({
    required this.project,
    required this.generatedImages,
    required this.isBusy,
    required this.errorMessage,
    required this.onImportGeneratedSheet,
    required this.onImportImageSequence,
    required this.onImportLibraryImageSequence,
    required this.onClearProject,
    required this.onTrackAdded,
    required this.onProjectDefaultDelayChanged,
    required this.onProjectPlaybackModeChanged,
    required this.onProjectLoopCountChanged,
    required this.onProjectIncludeHiddenTracksChanged,
    required this.onFrameAssetRebound,
    required this.onProjectAutoRepaired,
    required this.onExportProjectSpriteSheet,
    required this.onExportProjectGif,
    required this.onExportProjectPngSequence,
    required this.onExportTrackGif,
    required this.onExportTrackPngSequence,
  });

  final AnimationProject project;
  final List<GeneratedImage> generatedImages;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onImportGeneratedSheet;
  final VoidCallback onImportImageSequence;
  final VoidCallback onImportLibraryImageSequence;
  final VoidCallback onClearProject;
  final VoidCallback onTrackAdded;
  final ValueChanged<int> onProjectDefaultDelayChanged;
  final ValueChanged<AnimationPlaybackMode> onProjectPlaybackModeChanged;
  final ValueChanged<int> onProjectLoopCountChanged;
  final ValueChanged<bool> onProjectIncludeHiddenTracksChanged;
  final ValueChanged<String> onFrameAssetRebound;
  final VoidCallback onProjectAutoRepaired;
  final VoidCallback onExportProjectSpriteSheet;
  final VoidCallback onExportProjectGif;
  final VoidCallback onExportProjectPngSequence;
  final VoidCallback onExportTrackGif;
  final VoidCallback onExportTrackPngSequence;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final busyDisabledReason = isBusy
        ? l10n.animationProjectActionBusyUnavailable
        : null;
    return AppPanel(
      title: l10n.animationProjectControlsTitle,
      trailing: FrameCountBadge(
        count: project.totalFrameRefs,
        label: l10n.animationProjectFrameUnit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            l10n.animationProjectSummary(
              project.tracks.length,
              project.totalFrameRefs,
              project.canvasWidth,
              project.canvasHeight,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          PrimaryActionButton(
            onPressed: generatedImages.isEmpty || isBusy
                ? null
                : onImportGeneratedSheet,
            icon: Icons.account_tree_outlined,
            label: l10n.animationProjectImportAsProject,
            busyLabel: l10n.animationProjectImportingProject,
            isBusy: isBusy,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DisabledActionSemantics(
                label: l10n.animationProjectImportLocalSequence,
                disabledReason: busyDisabledReason,
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onImportImageSequence,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.animationProjectImportLocalSequence),
                ),
              ),
              _DisabledActionSemantics(
                label: l10n.animationProjectImportLibrarySequence,
                disabledReason: busyDisabledReason,
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onImportLibraryImageSequence,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.animationProjectImportLibrarySequence),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DisabledActionSemantics(
                label: l10n.animationProjectAddTrack,
                disabledReason: busyDisabledReason,
                child: FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onTrackAdded,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.animationProjectAddTrack),
                ),
              ),
              _ProjectExportMenuButton(
                enabled: !isBusy,
                disabledReason: busyDisabledReason,
                onExportProjectSpriteSheet: onExportProjectSpriteSheet,
                onExportProjectGif: onExportProjectGif,
                onExportProjectPngSequence: onExportProjectPngSequence,
                onExportTrackGif: onExportTrackGif,
                onExportTrackPngSequence: onExportTrackPngSequence,
              ),
              _DisabledActionSemantics(
                label: l10n.animationProjectCloseProject,
                disabledReason: busyDisabledReason,
                child: TextButton.icon(
                  onPressed: isBusy ? null : onClearProject,
                  icon: const Icon(Icons.close),
                  label: Text(l10n.animationProjectCloseProject),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProjectSettingsSection(
            project: project,
            enabled: !isBusy,
            onDefaultDelayChanged: onProjectDefaultDelayChanged,
            onPlaybackModeChanged: onProjectPlaybackModeChanged,
            onLoopCountChanged: onProjectLoopCountChanged,
            onIncludeHiddenTracksChanged: onProjectIncludeHiddenTracksChanged,
          ),
          const SizedBox(height: 16),
          _AssetDiagnosticsSection(
            project: project,
            enabled: !isBusy,
            onAssetRebound: onFrameAssetRebound,
            onProjectAutoRepaired: onProjectAutoRepaired,
          ),
        ],
      ),
    );
  }
}

class _DisabledActionSemantics extends StatelessWidget {
  const _DisabledActionSemantics({
    required this.label,
    required this.disabledReason,
    required this.child,
  });

  final String label;
  final String? disabledReason;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (disabledReason == null) {
      return child;
    }

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      value: disabledReason,
      button: true,
      enabled: false,
      child: child,
    );
  }
}

class _ProjectExportMenuButton extends StatelessWidget {
  const _ProjectExportMenuButton({
    required this.enabled,
    required this.disabledReason,
    required this.onExportProjectSpriteSheet,
    required this.onExportProjectGif,
    required this.onExportProjectPngSequence,
    required this.onExportTrackGif,
    required this.onExportTrackPngSequence,
  });

  final bool enabled;
  final String? disabledReason;
  final VoidCallback onExportProjectSpriteSheet;
  final VoidCallback onExportProjectGif;
  final VoidCallback onExportProjectPngSequence;
  final VoidCallback onExportTrackGif;
  final VoidCallback onExportTrackPngSequence;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    return _DisabledActionSemantics(
      label: l10n.exportImageTooltip,
      disabledReason: disabledReason,
      child: PopupMenuButton<VoidCallback>(
        tooltip: l10n.exportImageTooltip,
        enabled: enabled,
        onSelected: (action) => action(),
        itemBuilder: (context) => [
          PopupMenuItem<VoidCallback>(
            value: onExportProjectSpriteSheet,
            child: _MenuActionLabel(
              icon: Icons.grid_on_outlined,
              label: l10n.animationProjectExportCompositedSpriteSheet,
            ),
          ),
          PopupMenuItem<VoidCallback>(
            value: onExportProjectGif,
            child: _MenuActionLabel(
              icon: Icons.movie_outlined,
              label: l10n.animationProjectExportProjectGif,
            ),
          ),
          PopupMenuItem<VoidCallback>(
            value: onExportProjectPngSequence,
            child: _MenuActionLabel(
              icon: Icons.collections_outlined,
              label: l10n.animationProjectExportProjectPngSequence,
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<VoidCallback>(
            value: onExportTrackGif,
            child: _MenuActionLabel(
              icon: Icons.gif_box_outlined,
              label: l10n.animationProjectExportTrackGif,
            ),
          ),
          PopupMenuItem<VoidCallback>(
            value: onExportTrackPngSequence,
            child: _MenuActionLabel(
              icon: Icons.photo_library_outlined,
              label: l10n.animationProjectExportPngSequence,
            ),
          ),
        ],
        child: IgnorePointer(
          child: FilledButton.tonalIcon(
            onPressed: enabled ? () {} : null,
            icon: const Icon(Icons.ios_share_outlined),
            label: Text(l10n.exportImageTooltip),
          ),
        ),
      ),
    );
  }
}

class _MenuActionLabel extends StatelessWidget {
  const _MenuActionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    );
  }
}

class _AnimationTimelineDock extends StatelessWidget {
  const _AnimationTimelineDock({
    required this.project,
    required this.selectedTrackId,
    required this.onTrackSelected,
    required this.onTrackDuplicated,
    required this.onTrackDeleted,
    required this.onTrackMoved,
    required this.onTrackRenamed,
    required this.onTrackDelayChanged,
    required this.onTrackPlaybackModeChanged,
    required this.onTrackVisibilityChanged,
    required this.onTrackLockChanged,
    required this.onFrameMoved,
    required this.onFrameDuplicated,
    required this.onFrameDeleted,
    required this.onFrameDelayChanged,
    required this.onFrameTransformChanged,
    required this.onFrameReplaced,
    required this.onFrameCleared,
    required this.onFramePixelated,
    required this.onBlankFrameInserted,
    required this.onImageFrameInserted,
  });

  final AnimationProject project;
  final String? selectedTrackId;
  final ValueChanged<String> onTrackSelected;
  final ValueChanged<String> onTrackDuplicated;
  final ValueChanged<String> onTrackDeleted;
  final void Function(String trackId, int delta) onTrackMoved;
  final void Function(String trackId, String name) onTrackRenamed;
  final void Function(String trackId, int delayMs) onTrackDelayChanged;
  final void Function(String trackId, AnimationPlaybackMode mode)
  onTrackPlaybackModeChanged;
  final void Function(String trackId, bool visible) onTrackVisibilityChanged;
  final void Function(String trackId, bool locked) onTrackLockChanged;
  final void Function(String trackId, int fromIndex, int toIndex) onFrameMoved;
  final void Function(String trackId, int frameIndex) onFrameDuplicated;
  final void Function(String trackId, int frameIndex) onFrameDeleted;
  final void Function(String trackId, int frameIndex, int delayMs)
  onFrameDelayChanged;
  final void Function(String trackId, int frameIndex, FrameTransform transform)
  onFrameTransformChanged;
  final void Function(String trackId, int frameIndex) onFrameReplaced;
  final void Function(String trackId, int frameIndex) onFrameCleared;
  final void Function(String trackId, int frameIndex, int blockSize)
  onFramePixelated;
  final void Function(String trackId, int insertIndex) onBlankFrameInserted;
  final void Function(String trackId, int insertIndex) onImageFrameInserted;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    return AppPanel(
      title: l10n.animationProjectTrackTimelineTitle,
      trailing: FrameCountBadge(
        count: project.tracks.length,
        label: l10n.animationProjectTrackUnit,
      ),
      expandChild: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackList = _TrackList(
            project: project,
            selectedTrackId: selectedTrackId,
            onTrackSelected: onTrackSelected,
            onTrackDuplicated: onTrackDuplicated,
            onTrackDeleted: onTrackDeleted,
            onTrackMoved: onTrackMoved,
            onTrackRenamed: onTrackRenamed,
            onTrackDelayChanged: onTrackDelayChanged,
            onTrackPlaybackModeChanged: onTrackPlaybackModeChanged,
            onTrackVisibilityChanged: onTrackVisibilityChanged,
            onTrackLockChanged: onTrackLockChanged,
          );
          final timeline = _AnimationTimelinePanel(
            project: project,
            track: _selectedTrack(project, selectedTrackId),
            onFrameMoved: onFrameMoved,
            onFrameDuplicated: onFrameDuplicated,
            onFrameDeleted: onFrameDeleted,
            onFrameDelayChanged: onFrameDelayChanged,
            onFrameTransformChanged: onFrameTransformChanged,
            onFrameReplaced: onFrameReplaced,
            onFrameCleared: onFrameCleared,
            onFramePixelated: onFramePixelated,
            onBlankFrameInserted: onBlankFrameInserted,
            onImageFrameInserted: onImageFrameInserted,
          );

          if (constraints.maxWidth < 840) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  trackList,
                  const SizedBox(height: layoutGap),
                  timeline,
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: (constraints.maxWidth * 0.34).clamp(300, 340),
                child: SingleChildScrollView(child: trackList),
              ),
              const SizedBox(width: layoutGap),
              Expanded(child: SingleChildScrollView(child: timeline)),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectSettingsSection extends StatelessWidget {
  const _ProjectSettingsSection({
    required this.project,
    required this.enabled,
    required this.onDefaultDelayChanged,
    required this.onPlaybackModeChanged,
    required this.onLoopCountChanged,
    required this.onIncludeHiddenTracksChanged,
  });

  final AnimationProject project;
  final bool enabled;
  final ValueChanged<int> onDefaultDelayChanged;
  final ValueChanged<AnimationPlaybackMode> onPlaybackModeChanged;
  final ValueChanged<int> onLoopCountChanged;
  final ValueChanged<bool> onIncludeHiddenTracksChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.animationProjectSettingsTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ResponsivePair(
          breakpoint: 480,
          first: IntegerStepperField(
            label: l10n.animationProjectDefaultFrameDelay,
            value: project.timeline.defaultFrameDelayMs,
            minValue: 20,
            maxValue: 2000,
            suffixText: 'ms',
            enabled: enabled,
            onChanged: onDefaultDelayChanged,
          ),
          second: OptionDropdown<AnimationPlaybackMode>(
            label: l10n.animationProjectPlaybackMode,
            value: project.timeline.playbackMode,
            options: AnimationPlaybackMode.values,
            labelBuilder: (mode) => _animationPlaybackModeLabel(l10n, mode),
            onChanged: enabled ? onPlaybackModeChanged : null,
          ),
        ),
        const SizedBox(height: 8),
        ResponsivePair(
          breakpoint: 480,
          first: IntegerStepperField(
            label: l10n.animationProjectGifLoopCount,
            value: project.exportSettings.loopCount,
            minValue: 0,
            maxValue: 99,
            suffixText: l10n.animationProjectLoopCountSuffix,
            enabled: enabled,
            onChanged: onLoopCountChanged,
          ),
          second: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.animationProjectIncludeHiddenTracks),
            value: project.exportSettings.includeHiddenTracks,
            onChanged: enabled ? onIncludeHiddenTracksChanged : null,
          ),
        ),
      ],
    );
  }
}

class _AssetDiagnosticsSection extends StatefulWidget {
  const _AssetDiagnosticsSection({
    required this.project,
    required this.enabled,
    required this.onAssetRebound,
    required this.onProjectAutoRepaired,
  });

  final AnimationProject project;
  final bool enabled;
  final ValueChanged<String> onAssetRebound;
  final VoidCallback onProjectAutoRepaired;

  @override
  State<_AssetDiagnosticsSection> createState() =>
      _AssetDiagnosticsSectionState();
}

class _AssetDiagnosticsSectionState extends State<_AssetDiagnosticsSection> {
  Future<AnimationProjectAssetDiagnostics>? _future;
  AnimationProject? _lastProject;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _AssetDiagnosticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshIfNeeded();
  }

  void _refreshIfNeeded() {
    if (identical(_lastProject, widget.project)) {
      return;
    }
    _lastProject = widget.project;
    _future = _inspect(widget.project);
  }

  Future<AnimationProjectAssetDiagnostics> _inspect(AnimationProject project) {
    return const AnimationProjectAssetInspector().inspectInBackground(project);
  }

  void _refresh() {
    setState(() {
      _future = _inspect(widget.project);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.animationProjectAssetDiagnosticsTitle,
                style: theme.textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              onPressed: widget.enabled ? _refresh : null,
              icon: const Icon(Icons.refresh_outlined),
              label: Text(l10n.animationProjectRecheckAssets),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<AnimationProjectAssetDiagnostics>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _AssetDiagnosticsSurface(
                icon: Icons.manage_search_outlined,
                title: l10n.animationProjectCheckingFrameAssets,
                message: l10n.animationProjectCheckingFrameAssetsMessage,
                color: theme.colorScheme.primary,
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _AssetDiagnosticsSurface(
                icon: Icons.error_outline,
                title: l10n.animationProjectAssetCheckFailed,
                message:
                    '${snapshot.error ?? l10n.animationProjectNoAssetCheckResult}',
                color: theme.colorScheme.error,
              );
            }

            final diagnostics = snapshot.data!;
            if (!diagnostics.hasIssues) {
              return _AssetDiagnosticsSurface(
                icon: Icons.check_circle_outline,
                title: l10n.animationProjectAssetsHealthy,
                message: l10n.animationProjectAssetsHealthyMessage(
                  diagnostics.totalAssetCount,
                  diagnostics.referencedAssetCount,
                ),
                color: theme.colorScheme.primary,
              );
            }

            final missingTimelineCount =
                diagnostics.missingReferencedAssetCount;
            final hasMissingAssets = diagnostics.hasMissingAssets;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (hasMissingAssets
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.secondaryContainer)
                        .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasMissingAssets
                      ? theme.colorScheme.error
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasMissingAssets
                            ? Icons.warning_amber_outlined
                            : Icons.inventory_2_outlined,
                        color: hasMissingAssets
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasMissingAssets
                              ? l10n.animationProjectMissingAssetsTitle
                              : l10n.animationProjectRepairableTitle,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: hasMissingAssets
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasMissingAssets && missingTimelineCount > 0
                        ? l10n.animationProjectMissingTimelineAssetsMessage(
                            missingTimelineCount,
                          )
                        : hasMissingAssets
                        ? l10n.animationProjectMissingUnusedAssetsMessage
                        : l10n.animationProjectRepairableMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasMissingAssets
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (diagnostics.hasAutoRepairableIssues) ...[
                    const SizedBox(height: 8),
                    _AutoRepairSummary(
                      diagnostics: diagnostics,
                      enabled: widget.enabled,
                      onProjectAutoRepaired: widget.onProjectAutoRepaired,
                    ),
                  ],
                  if (diagnostics.hasMissingAssets) ...[
                    const SizedBox(height: 10),
                    for (final issue in diagnostics.missingAssets) ...[
                      _AssetIssueRow(
                        issue: issue,
                        enabled: widget.enabled,
                        onAssetRebound: widget.onAssetRebound,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AssetDiagnosticsSurface extends StatelessWidget {
  const _AssetDiagnosticsSurface({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoRepairSummary extends StatelessWidget {
  const _AutoRepairSummary({
    required this.diagnostics,
    required this.enabled,
    required this.onProjectAutoRepaired,
  });

  final AnimationProjectAssetDiagnostics diagnostics;
  final bool enabled;
  final VoidCallback onProjectAutoRepaired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    final assets = diagnostics.unusedAssets;
    final previewNames = assets
        .take(3)
        .map((asset) {
          final path = asset.path.trim();
          return path.isEmpty ? asset.id : fileNameFromPath(path);
        })
        .join('、');
    final extraCount = assets.length > 3
        ? l10n.animationProjectAssetPreviewExtraCount(assets.length)
        : '';
    final details = [
      if (diagnostics.unusedAssetCount > 0)
        l10n.animationProjectUnusedAssetsDetail(diagnostics.unusedAssetCount),
      if (diagnostics.invalidFrameReferenceCount > 0)
        l10n.animationProjectInvalidFrameRefsDetail(
          diagnostics.invalidFrameReferenceCount,
        ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.animationProjectAutoRepairableCount(
                    diagnostics.autoRepairableIssueCount,
                  ),
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    details.join(' · '),
                    if (previewNames.isNotEmpty) '$previewNames$extraCount',
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ResponsiveTrailingAction(
            onPressed: enabled ? onProjectAutoRepaired : null,
            icon: Icons.cleaning_services_outlined,
            label: l10n.animationProjectAutoRepairAction,
          ),
        ],
      ),
    );
  }
}

class _AssetIssueRow extends StatelessWidget {
  const _AssetIssueRow({
    required this.issue,
    required this.enabled,
    required this.onAssetRebound,
  });

  final AnimationProjectAssetIssue issue;
  final bool enabled;
  final ValueChanged<String> onAssetRebound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    final asset = issue.asset;
    final fileName = asset.path.trim().isEmpty
        ? l10n.animationProjectMissingRecordedPath
        : fileNameFromPath(asset.path);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.broken_image_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.animationProjectAssetIssueTimelineRefs(
                    issue.message,
                    issue.referenceCount,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ResponsiveTrailingAction(
            onPressed: enabled ? () => onAssetRebound(asset.id) : null,
            icon: Icons.link_outlined,
            label: l10n.animationProjectRebindAsset,
          ),
        ],
      ),
    );
  }
}

class _ResponsiveTrailingAction extends StatelessWidget {
  const _ResponsiveTrailingAction({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 152;
        if (compact) {
          return Tooltip(
            message: label,
            child: IconButton.outlined(onPressed: onPressed, icon: Icon(icon)),
          );
        }

        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        );
      },
    );
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({
    required this.project,
    required this.selectedTrackId,
    required this.onTrackSelected,
    required this.onTrackDuplicated,
    required this.onTrackDeleted,
    required this.onTrackMoved,
    required this.onTrackRenamed,
    required this.onTrackDelayChanged,
    required this.onTrackPlaybackModeChanged,
    required this.onTrackVisibilityChanged,
    required this.onTrackLockChanged,
  });

  final AnimationProject project;
  final String? selectedTrackId;
  final ValueChanged<String> onTrackSelected;
  final ValueChanged<String> onTrackDuplicated;
  final ValueChanged<String> onTrackDeleted;
  final void Function(String trackId, int delta) onTrackMoved;
  final void Function(String trackId, String name) onTrackRenamed;
  final void Function(String trackId, int delayMs) onTrackDelayChanged;
  final void Function(String trackId, AnimationPlaybackMode mode)
  onTrackPlaybackModeChanged;
  final void Function(String trackId, bool visible) onTrackVisibilityChanged;
  final void Function(String trackId, bool locked) onTrackLockChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.animationProjectTracksSectionTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < project.tracks.length; index++) ...[
          Builder(
            builder: (context) {
              final track = project.tracks[index];
              return _TrackTile(
                track: track,
                selected: track.id == selectedTrackId,
                canMoveUp: index > 0,
                canMoveDown: index < project.tracks.length - 1,
                canDelete: project.tracks.length > 1,
                onSelected: () => onTrackSelected(track.id),
                onDuplicated: () => onTrackDuplicated(track.id),
                onDeleted: () => onTrackDeleted(track.id),
                onMoveUp: () => onTrackMoved(track.id, -1),
                onMoveDown: () => onTrackMoved(track.id, 1),
                onRenamed: (name) => onTrackRenamed(track.id, name),
                onDelayChanged: (delay) => onTrackDelayChanged(track.id, delay),
                onPlaybackModeChanged: (mode) =>
                    onTrackPlaybackModeChanged(track.id, mode),
                onVisibilityChanged: (visible) =>
                    onTrackVisibilityChanged(track.id, visible),
                onLockChanged: (locked) => onTrackLockChanged(track.id, locked),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TrackTile extends StatefulWidget {
  const _TrackTile({
    required this.track,
    required this.selected,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canDelete,
    required this.onSelected,
    required this.onDuplicated,
    required this.onDeleted,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRenamed,
    required this.onDelayChanged,
    required this.onPlaybackModeChanged,
    required this.onVisibilityChanged,
    required this.onLockChanged,
  });

  final AnimationTrack track;
  final bool selected;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool canDelete;
  final VoidCallback onSelected;
  final VoidCallback onDuplicated;
  final VoidCallback onDeleted;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final ValueChanged<String> onRenamed;
  final ValueChanged<int> onDelayChanged;
  final ValueChanged<AnimationPlaybackMode> onPlaybackModeChanged;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<bool> onLockChanged;

  @override
  State<_TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<_TrackTile> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.track.name);
  }

  @override
  void didUpdateWidget(covariant _TrackTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.track.name != oldWidget.track.name &&
        _controller.text != widget.track.name) {
      _controller.text = widget.track.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.track.name,
      button: true,
      selected: widget.selected,
      enabled: true,
      child: InkWell(
        onTap: widget.onSelected,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.selected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        IconButton.filledTonal(
                          tooltip: l10n.animationProjectMoveTrackUp,
                          onPressed: widget.canMoveUp ? widget.onMoveUp : null,
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton.filledTonal(
                          tooltip: l10n.animationProjectMoveTrackDown,
                          onPressed: widget.canMoveDown
                              ? widget.onMoveDown
                              : null,
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        IconButton.filledTonal(
                          tooltip: l10n.animationProjectDuplicateTrack,
                          onPressed: widget.onDuplicated,
                          icon: const Icon(Icons.content_copy_outlined),
                        ),
                        IconButton.filledTonal(
                          tooltip: l10n.animationProjectDeleteTrack,
                          onPressed: widget.canDelete ? widget.onDeleted : null,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: widget.track.visible
                        ? l10n.animationProjectHideTrack
                        : l10n.animationProjectShowTrack,
                    onPressed: () =>
                        widget.onVisibilityChanged(!widget.track.visible),
                    icon: Icon(
                      widget.track.visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  IconButton(
                    tooltip: widget.track.locked
                        ? l10n.animationProjectUnlockTrack
                        : l10n.animationProjectLockTrack,
                    onPressed: () => widget.onLockChanged(!widget.track.locked),
                    icon: Icon(
                      widget.track.locked
                          ? Icons.lock_outline
                          : Icons.lock_open_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: l10n.animationProjectTrackNameLabel,
                  isDense: true,
                ),
                onSubmitted: widget.onRenamed,
                onEditingComplete: () => widget.onRenamed(_controller.text),
              ),
              const SizedBox(height: 8),
              ResponsivePair(
                breakpoint: 480,
                first: IntegerStepperField(
                  label: l10n.animationProjectFrameDelayLabel,
                  value: widget.track.defaultDelayMs,
                  minValue: 20,
                  maxValue: 2000,
                  suffixText: 'ms',
                  onChanged: widget.onDelayChanged,
                ),
                second: OptionDropdown<AnimationPlaybackMode>(
                  label: l10n.animationProjectPlaybackMode,
                  value: widget.track.playbackMode,
                  options: AnimationPlaybackMode.values,
                  labelBuilder: (mode) =>
                      _animationPlaybackModeLabel(l10n, mode),
                  onChanged: widget.onPlaybackModeChanged,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.animationProjectFrameCount(widget.track.totalFrameRefs),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimationTimelinePanel extends StatefulWidget {
  const _AnimationTimelinePanel({
    required this.project,
    required this.track,
    required this.onFrameMoved,
    required this.onFrameDuplicated,
    required this.onFrameDeleted,
    required this.onFrameDelayChanged,
    required this.onFrameTransformChanged,
    required this.onFrameReplaced,
    required this.onFrameCleared,
    required this.onFramePixelated,
    required this.onBlankFrameInserted,
    required this.onImageFrameInserted,
  });

  final AnimationProject project;
  final AnimationTrack? track;
  final void Function(String trackId, int fromIndex, int toIndex) onFrameMoved;
  final void Function(String trackId, int frameIndex) onFrameDuplicated;
  final void Function(String trackId, int frameIndex) onFrameDeleted;
  final void Function(String trackId, int frameIndex, int delayMs)
  onFrameDelayChanged;
  final void Function(String trackId, int frameIndex, FrameTransform transform)
  onFrameTransformChanged;
  final void Function(String trackId, int frameIndex) onFrameReplaced;
  final void Function(String trackId, int frameIndex) onFrameCleared;
  final void Function(String trackId, int frameIndex, int blockSize)
  onFramePixelated;
  final void Function(String trackId, int insertIndex) onBlankFrameInserted;
  final void Function(String trackId, int insertIndex) onImageFrameInserted;

  @override
  State<_AnimationTimelinePanel> createState() =>
      _AnimationTimelinePanelState();
}

class _AnimationTimelinePanelState extends State<_AnimationTimelinePanel> {
  int _selectedFrameIndex = 0;

  @override
  void didUpdateWidget(covariant _AnimationTimelinePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track?.id != widget.track?.id) {
      _selectedFrameIndex = 0;
      return;
    }
    _selectedFrameIndex = _clampedSelectedIndex;
  }

  int get _clampedSelectedIndex {
    final frames = widget.track?.orderedFrames ?? const <FrameRef>[];
    if (frames.isEmpty) {
      return 0;
    }
    return _selectedFrameIndex.clamp(0, frames.length - 1).toInt();
  }

  void _selectFrame(int index) {
    setState(() => _selectedFrameIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    if (track == null) {
      return _TimelineEmptyState(
        message: l10n.animationProjectSelectTrackFirst,
      );
    }

    final frames = track.orderedFrames;
    if (frames.isEmpty) {
      return _TimelineEmptyState(
        actions: [
          FilledButton.tonalIcon(
            onPressed: track.locked
                ? null
                : () => widget.onBlankFrameInserted(track.id, 0),
            icon: const Icon(Icons.add_box_outlined),
            label: Text(l10n.animationProjectInsertBlankFrame),
          ),
          FilledButton.tonalIcon(
            onPressed: track.locked
                ? null
                : () => widget.onImageFrameInserted(track.id, 0),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(l10n.animationProjectInsertImageFrame),
          ),
        ],
        message: track.locked
            ? l10n.animationProjectTrackLockedNoFrames
            : l10n.animationProjectTrackNoFrames,
      );
    }

    final selectedIndex = _clampedSelectedIndex;
    final selectedFrame = frames[selectedIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.animationProjectSequenceTimelineTitle,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              l10n.animationProjectTrackFrameStatus(track.name, frames.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SelectedFrameEditor(
          enabled: !track.locked,
          frameIndex: selectedIndex,
          frame: selectedFrame,
          canvasWidth: widget.project.canvasWidth,
          canvasHeight: widget.project.canvasHeight,
          onDelayChanged: (delayMs) =>
              widget.onFrameDelayChanged(track.id, selectedIndex, delayMs),
          onTransformChanged: (transform) => widget.onFrameTransformChanged(
            track.id,
            selectedIndex,
            transform,
          ),
          onDuplicated: () => widget.onFrameDuplicated(track.id, selectedIndex),
          onDeleted: frames.length <= 1
              ? null
              : () => widget.onFrameDeleted(track.id, selectedIndex),
          onReplaced: () => widget.onFrameReplaced(track.id, selectedIndex),
          onCleared: () => widget.onFrameCleared(track.id, selectedIndex),
          onPixelated: (blockSize) =>
              widget.onFramePixelated(track.id, selectedIndex, blockSize),
          onBlankInserted: () =>
              widget.onBlankFrameInserted(track.id, selectedIndex + 1),
          onImageInserted: () =>
              widget.onImageFrameInserted(track.id, selectedIndex + 1),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 148,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            itemCount: frames.length,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              if (track.locked) {
                return;
              }
              final targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
              widget.onFrameMoved(track.id, oldIndex, targetIndex);
              setState(() => _selectedFrameIndex = targetIndex);
            },
            itemBuilder: (context, index) {
              final frame = frames[index];
              return _TimelineFrameTile(
                key: ValueKey('${track.id}_${frame.assetId}_$index'),
                project: widget.project,
                frame: frame,
                index: index,
                selected: index == selectedIndex,
                locked: track.locked,
                onSelected: () => _selectFrame(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelectedFrameEditor extends StatelessWidget {
  const _SelectedFrameEditor({
    required this.enabled,
    required this.frameIndex,
    required this.frame,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.onDelayChanged,
    required this.onTransformChanged,
    required this.onDuplicated,
    required this.onDeleted,
    required this.onReplaced,
    required this.onCleared,
    required this.onPixelated,
    required this.onBlankInserted,
    required this.onImageInserted,
  });

  final bool enabled;
  final int frameIndex;
  final FrameRef frame;
  final int canvasWidth;
  final int canvasHeight;
  final ValueChanged<int> onDelayChanged;
  final ValueChanged<FrameTransform> onTransformChanged;
  final VoidCallback onDuplicated;
  final VoidCallback? onDeleted;
  final VoidCallback onReplaced;
  final VoidCallback onCleared;
  final ValueChanged<int> onPixelated;
  final VoidCallback onBlankInserted;
  final VoidCallback onImageInserted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    final transform = frame.transform;
    final xLimit = canvasWidth <= 0 ? 1.0 : canvasWidth.toDouble();
    final yLimit = canvasHeight <= 0 ? 1.0 : canvasHeight.toDouble();
    final offsetX = transform.offsetX.clamp(-xLimit, xLimit).toDouble();
    final offsetY = transform.offsetY.clamp(-yLimit, yLimit).toDouble();
    final opacity = transform.opacity.clamp(0, 1).toDouble();
    const pixelBlockSizes = [2, 4, 8, 16, 32];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsivePair(
          breakpoint: 520,
          first: IntegerStepperField(
            label: l10n.animationProjectSingleFrameDelay,
            value: frame.delayMs,
            minValue: 20,
            maxValue: 2000,
            suffixText: 'ms',
            enabled: enabled,
            onChanged: onDelayChanged,
          ),
          second: Align(
            alignment: Alignment.centerLeft,
            child: _FrameActionBar(
              enabled: enabled,
              frameLabel: l10n.animationProjectCurrentFrame(frameIndex + 1),
              pixelBlockSizes: pixelBlockSizes,
              onBlankInserted: onBlankInserted,
              onImageInserted: onImageInserted,
              onReplaced: onReplaced,
              onCleared: onCleared,
              onPixelated: onPixelated,
              onDuplicated: onDuplicated,
              onDeleted: onDeleted,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.animationProjectSingleFrameTransform,
                style: theme.textTheme.labelLarge,
              ),
            ),
            Tooltip(
              message: l10n.animationProjectFlipHorizontal,
              child: IconButton(
                onPressed: enabled
                    ? () => onTransformChanged(
                        transform.copyWith(flipX: !transform.flipX),
                      )
                    : null,
                color: transform.flipX ? theme.colorScheme.primary : null,
                icon: const Icon(Icons.swap_horiz),
              ),
            ),
            Tooltip(
              message: l10n.animationProjectFlipVertical,
              child: IconButton(
                onPressed: enabled
                    ? () => onTransformChanged(
                        transform.copyWith(flipY: !transform.flipY),
                      )
                    : null,
                color: transform.flipY ? theme.colorScheme.primary : null,
                icon: const Icon(Icons.swap_vert),
              ),
            ),
            Tooltip(
              message: l10n.animationProjectResetFrameTransform,
              child: IconButton(
                onPressed: enabled && !transform.isIdentity
                    ? () => onTransformChanged(const FrameTransform())
                    : null,
                icon: const Icon(Icons.restart_alt),
              ),
            ),
          ],
        ),
        _FrameTransformSlider(
          label: 'X',
          valueLabel: '${offsetX.round()}px',
          value: offsetX,
          min: -xLimit,
          max: xLimit,
          divisions: (xLimit * 2).round(),
          enabled: enabled,
          onChanged: (value) => onTransformChanged(
            transform.copyWith(offsetX: value.roundToDouble()),
          ),
        ),
        _FrameTransformSlider(
          label: 'Y',
          valueLabel: '${offsetY.round()}px',
          value: offsetY,
          min: -yLimit,
          max: yLimit,
          divisions: (yLimit * 2).round(),
          enabled: enabled,
          onChanged: (value) => onTransformChanged(
            transform.copyWith(offsetY: value.roundToDouble()),
          ),
        ),
        _FrameTransformSlider(
          label: l10n.animationProjectOpacity,
          valueLabel: '${(opacity * 100).round()}%',
          value: opacity,
          min: 0,
          max: 1,
          divisions: 20,
          enabled: enabled,
          onChanged: (value) =>
              onTransformChanged(transform.copyWith(opacity: value)),
        ),
      ],
    );
  }
}

class _FrameTransformSlider extends StatelessWidget {
  const _FrameTransformSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 88, child: Text('$label $valueLabel')),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions <= 0 ? null : divisions,
            label: valueLabel,
            semanticFormatterCallback: (_) => '$label $valueLabel',
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

class _FrameActionBar extends StatelessWidget {
  const _FrameActionBar({
    required this.enabled,
    required this.frameLabel,
    required this.pixelBlockSizes,
    required this.onBlankInserted,
    required this.onImageInserted,
    required this.onReplaced,
    required this.onCleared,
    required this.onPixelated,
    required this.onDuplicated,
    required this.onDeleted,
  });

  final bool enabled;
  final String frameLabel;
  final List<int> pixelBlockSizes;
  final VoidCallback onBlankInserted;
  final VoidCallback onImageInserted;
  final VoidCallback onReplaced;
  final VoidCallback onCleared;
  final ValueChanged<int> onPixelated;
  final VoidCallback onDuplicated;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(frameLabel),
        _FrameIconActionButton(
          tooltip: l10n.animationProjectInsertBlankFrame,
          icon: Icons.add_box_outlined,
          enabled: enabled,
          onPressed: onBlankInserted,
        ),
        _FrameIconActionButton(
          tooltip: l10n.animationProjectInsertImageFrame,
          icon: Icons.add_photo_alternate_outlined,
          enabled: enabled,
          onPressed: onImageInserted,
        ),
        _FrameIconActionButton(
          tooltip: l10n.animationProjectReplaceFrame,
          icon: Icons.find_replace_outlined,
          enabled: enabled,
          onPressed: onReplaced,
        ),
        _FrameIconActionButton(
          tooltip: l10n.animationProjectDuplicateFrame,
          icon: Icons.content_copy_outlined,
          enabled: enabled,
          onPressed: onDuplicated,
        ),
        _FrameMoreActionMenu(
          enabled: enabled,
          pixelBlockSizes: pixelBlockSizes,
          onCleared: onCleared,
          onDeleted: onDeleted,
          onPixelated: onPixelated,
        ),
      ],
    );
  }
}

class _FrameIconActionButton extends StatelessWidget {
  const _FrameIconActionButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
      ),
    );
  }
}

class _FrameMoreActionMenu extends StatelessWidget {
  const _FrameMoreActionMenu({
    required this.enabled,
    required this.pixelBlockSizes,
    required this.onCleared,
    required this.onDeleted,
    required this.onPixelated,
  });

  final bool enabled;
  final List<int> pixelBlockSizes;
  final VoidCallback onCleared;
  final VoidCallback? onDeleted;
  final ValueChanged<int> onPixelated;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    return Semantics(
      container: true,
      label: l10n.imageLibraryMoreActionsTooltip,
      button: true,
      enabled: enabled,
      child: PopupMenuButton<_FrameMenuAction>(
        tooltip: l10n.imageLibraryMoreActionsTooltip,
        enabled: enabled,
        onSelected: (action) {
          if (action is _ClearFrameAction) {
            onCleared();
          } else if (action is _DeleteFrameAction) {
            onDeleted?.call();
          } else if (action is _PixelateFrameAction) {
            onPixelated(action.blockSize);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<_FrameMenuAction>(
            value: const _ClearFrameAction(),
            child: _MenuActionLabel(
              icon: Icons.layers_clear_outlined,
              label: l10n.animationProjectClearFrame,
            ),
          ),
          PopupMenuItem<_FrameMenuAction>(
            enabled: onDeleted != null,
            value: const _DeleteFrameAction(),
            child: _MenuActionLabel(
              icon: Icons.delete_outline,
              label: l10n.animationProjectDeleteFrame,
            ),
          ),
          const PopupMenuDivider(),
          for (final blockSize in pixelBlockSizes)
            PopupMenuItem<_FrameMenuAction>(
              value: _PixelateFrameAction(blockSize),
              child: _MenuActionLabel(
                icon: Icons.grid_4x4_outlined,
                label: '${l10n.animationProjectPixelateFrame} $blockSize px',
              ),
            ),
        ],
        child: IgnorePointer(
          child: IconButton.filledTonal(
            tooltip: l10n.imageLibraryMoreActionsTooltip,
            onPressed: enabled ? () {} : null,
            icon: const Icon(Icons.more_horiz),
          ),
        ),
      ),
    );
  }
}

sealed class _FrameMenuAction {
  const _FrameMenuAction();
}

class _ClearFrameAction extends _FrameMenuAction {
  const _ClearFrameAction();
}

class _DeleteFrameAction extends _FrameMenuAction {
  const _DeleteFrameAction();
}

class _PixelateFrameAction extends _FrameMenuAction {
  const _PixelateFrameAction(this.blockSize);

  final int blockSize;
}

class _TimelineFrameTile extends StatelessWidget {
  const _TimelineFrameTile({
    required super.key,
    required this.project,
    required this.frame,
    required this.index,
    required this.selected,
    required this.locked,
    required this.onSelected,
  });

  final AnimationProject project;
  final FrameRef frame;
  final int index;
  final bool selected;
  final bool locked;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    final asset = project.assetById(frame.assetId);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label:
            '${l10n.animationProjectCurrentFrame(index + 1)} · '
            '${frame.delayMs}ms',
        button: true,
        selected: selected,
        enabled: true,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 104,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.58)
                  : theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: double.infinity,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: asset == null || asset.path.isEmpty
                          ? const Icon(Icons.broken_image_outlined)
                          : Image.file(
                              File(asset.path),
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'F${index + 1} · ${frame.delayMs}ms',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    if (!locked)
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_indicator, size: 18),
                      )
                    else
                      const Icon(Icons.lock_outline, size: 16),
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

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState({required this.message, this.actions = const []});

  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: theme.textTheme.bodyMedium),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimationProjectPreview extends StatefulWidget {
  const _AnimationProjectPreview({
    required this.project,
    required this.enablePlayback,
  });

  final AnimationProject project;
  final bool enablePlayback;

  @override
  State<_AnimationProjectPreview> createState() =>
      _AnimationProjectPreviewState();
}

class _AnimationProjectPreviewState extends State<_AnimationProjectPreview> {
  Future<List<RenderedAnimationFrame>>? _renderFuture;
  AnimationProject? _lastProject;
  Timer? _playbackTimer;
  int _currentFrameIndex = 0;
  bool _isPlaying = false;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshRenderFutureIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _AnimationProjectPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshRenderFutureIfNeeded();
  }

  void _refreshRenderFutureIfNeeded() {
    final project = widget.project;
    if (identical(_lastProject, project)) {
      return;
    }
    _lastProject = project;
    _currentFrameIndex = 0;
    _stopPlayback();
    _renderFuture = _renderProject(project);
  }

  Future<List<RenderedAnimationFrame>> _renderProject(
    AnimationProject project,
  ) {
    return const AnimationProjectRenderer().renderProjectFramesInBackground(
      project: project,
    );
  }

  void _retryRender() {
    final project = widget.project;
    setState(() {
      _renderFuture = _renderProject(project);
      _currentFrameIndex = 0;
    });
  }

  void _togglePlayback(List<RenderedAnimationFrame> frames) {
    if (_isPlaying) {
      _stopPlayback(updateState: true);
      return;
    }
    if (frames.length <= 1) {
      return;
    }
    setState(() => _isPlaying = true);
    _scheduleNextFrame(frames);
  }

  void _stepFrame(List<RenderedAnimationFrame> frames, int delta) {
    if (frames.isEmpty) {
      return;
    }
    _stopPlayback(updateState: true);
    setState(() {
      _currentFrameIndex =
          (_currentFrameIndex + delta + frames.length) % frames.length;
    });
  }

  void _scheduleNextFrame(List<RenderedAnimationFrame> frames) {
    _playbackTimer?.cancel();
    if (!_isPlaying || frames.length <= 1) {
      return;
    }
    final index = _currentFrameIndex.clamp(0, frames.length - 1).toInt();
    final delayMs = frames[index].delayMs.clamp(20, 2000);
    _playbackTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || !_isPlaying) {
        return;
      }
      setState(() {
        _currentFrameIndex = (_currentFrameIndex + 1) % frames.length;
      });
      _scheduleNextFrame(frames);
    });
  }

  void _stopPlayback({bool updateState = false}) {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (updateState && mounted) {
      setState(() => _isPlaying = false);
    } else {
      _isPlaying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    if (_renderFuture == null) {
      return PreviewPanelShell(
        title: l10n.animationProjectPreviewTitle,
        child: PreviewStateSurface.loading(
          message: l10n.animationProjectRenderingComposite,
        ),
      );
    }

    return FutureBuilder<List<RenderedAnimationFrame>>(
      future: _renderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return PreviewPanelShell(
            title: l10n.animationProjectPreviewTitle,
            child: PreviewStateSurface.loading(
              message: l10n.animationProjectRenderingComposite,
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return PreviewPanelShell(
            title: l10n.animationProjectPreviewTitle,
            child: PreviewStateSurface.error(
              title: l10n.animationProjectRenderFailed,
              message: '${snapshot.error ?? l10n.animationProjectNoRenderData}',
              onRetry: _retryRender,
              retryLabel: l10n.animationProjectRetryRender,
            ),
          );
        }
        final frames = snapshot.data!;
        if (frames.isEmpty) {
          return PreviewPanelShell(
            title: l10n.animationProjectPreviewTitle,
            child: PreviewStateSurface.empty(
              message: l10n.animationProjectNoVisibleFrames,
            ),
          );
        }
        final safeIndex = _currentFrameIndex
            .clamp(0, frames.length - 1)
            .toInt();
        final frame = frames[safeIndex];
        return PreviewPanelShell(
          title: l10n.animationProjectPreviewTitle,
          child: _RenderedAnimationPreview(
            frame: frame,
            frameIndex: safeIndex,
            frameCount: frames.length,
            isPlaying: _isPlaying,
            playbackEnabled: widget.enablePlayback,
            onTogglePlayback: () => _togglePlayback(frames),
            onPreviousFrame: () => _stepFrame(frames, -1),
            onNextFrame: () => _stepFrame(frames, 1),
          ),
        );
      },
    );
  }
}

class _RenderedAnimationPreview extends StatelessWidget {
  const _RenderedAnimationPreview({
    required this.frame,
    required this.frameIndex,
    required this.frameCount,
    required this.isPlaying,
    required this.playbackEnabled,
    required this.onTogglePlayback,
    required this.onPreviousFrame,
    required this.onNextFrame,
  });

  final RenderedAnimationFrame frame;
  final int frameIndex;
  final int frameCount;
  final bool isPlaying;
  final bool playbackEnabled;
  final VoidCallback onTogglePlayback;
  final VoidCallback onPreviousFrame;
  final VoidCallback onNextFrame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    final canStep = frameCount > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: fieldGap,
          runSpacing: fieldGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.tonalIcon(
              onPressed: playbackEnabled && canStep ? onTogglePlayback : null,
              icon: Icon(
                isPlaying ? Icons.pause_circle_outline : Icons.play_arrow,
              ),
              label: Text(
                isPlaying
                    ? l10n.animationProjectPausePreview
                    : l10n.animationProjectPlayPreview,
              ),
            ),
            Tooltip(
              message: l10n.animationProjectPreviousFrame,
              child: IconButton(
                onPressed: canStep ? onPreviousFrame : null,
                icon: const Icon(Icons.chevron_left),
              ),
            ),
            Tooltip(
              message: l10n.animationProjectNextFrame,
              child: IconButton(
                onPressed: canStep ? onNextFrame : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ),
            Text(
              l10n.animationProjectCompositeFrameStatus(
                frameIndex + 1,
                frameCount,
                frame.delayMs,
              ),
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: fieldGap),
        Text(
          frame.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: fieldGap),
        Semantics(
          container: true,
          explicitChildNodes: true,
          label:
              '${l10n.animationProjectPreviewTitle} · '
              '${l10n.animationProjectCompositeFrameStatus(frameIndex + 1, frameCount, frame.delayMs)}',
          image: true,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 320),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(frame.bytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ],
    );
  }
}

String _animationPlaybackModeLabel(
  AppLocalizations l10n,
  AnimationPlaybackMode mode,
) {
  final gifMode = switch (mode) {
    AnimationPlaybackMode.normal => GifPlaybackMode.normal,
    AnimationPlaybackMode.reverse => GifPlaybackMode.reverse,
    AnimationPlaybackMode.pingPong => GifPlaybackMode.pingPong,
  };
  return localizedGifPlaybackModeLabel(l10n, gifMode);
}

AnimationTrack? _selectedTrack(AnimationProject project, String? selectedId) {
  if (selectedId != null) {
    final selected = project.trackById(selectedId);
    if (selected != null) {
      return selected;
    }
  }
  return project.tracks.isEmpty ? null : project.tracks.first;
}
