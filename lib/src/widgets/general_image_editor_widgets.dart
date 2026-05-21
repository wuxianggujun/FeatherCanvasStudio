import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/library_label_builders.dart';
import '../services/general_image_editing_service.dart';
import '../theme/layout_constants.dart';
import '../utils/display_labels.dart';
import 'common_form_widgets.dart';
import 'layout_navigation_widgets.dart';
import 'preview_widgets.dart';

typedef GeneralImageEditApplyCallback =
    Future<void> Function(GeneralImageEditOptions options);

enum _GeneralImageEditorPanel { geometry, appearance, annotation, output }

class GeneralImageEditorContent extends StatefulWidget {
  const GeneralImageEditorContent({
    required this.imagePath,
    required this.imageInfo,
    required this.isProcessing,
    required this.errorMessage,
    required this.onPickImage,
    required this.onClearImage,
    required this.onApplyEdit,
    super.key,
  });

  final String? imagePath;
  final ImageInspectionResult? imageInfo;
  final bool isProcessing;
  final String? errorMessage;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final GeneralImageEditApplyCallback onApplyEdit;

  @override
  State<GeneralImageEditorContent> createState() =>
      _GeneralImageEditorContentState();
}

class _GeneralImageEditorContentState extends State<GeneralImageEditorContent>
    with WidgetsBindingObserver {
  static const int _maxEditDimension = 8192;
  static const List<int> _annotationColorOptions = [
    0xFFFF3B30,
    0xFFFFD400,
    0xFF34C759,
    0xFF007AFF,
    0xFF111111,
    0xFFFFFFFF,
  ];

  int _cropLeft = 0;
  int _cropTop = 0;
  int _cropRight = 0;
  int _cropBottom = 0;
  int _quarterTurns = 0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;
  bool _resizeEnabled = false;
  bool _lockAspectRatio = true;
  int _resizeWidth = 1;
  int _resizeHeight = 1;
  int _brightness = 0;
  int _contrast = 0;
  int _saturation = 0;
  int _warmth = 0;
  ImageEditColorEffect _effect = ImageEditColorEffect.none;
  bool _effectRegionEnabled = false;
  int _effectRegionLeftPercent = 15;
  int _effectRegionTopPercent = 15;
  int _effectRegionRightPercent = 85;
  int _effectRegionBottomPercent = 85;
  bool _blurEnabled = false;
  int _blurRadius = 2;
  bool _sharpenEnabled = false;
  int _sharpenAmount = 50;
  bool _pixelationEnabled = false;
  int _pixelationBlockSize = 8;
  bool _transparentBackgroundEnabled = false;
  int _transparentTolerance = 28;
  GeneralImageOutputFormat _outputFormat = GeneralImageOutputFormat.png;
  int _jpegQuality = 92;
  final List<ImageAnnotation> _annotations = <ImageAnnotation>[];
  late final TextEditingController _annotationTextController;
  ImageAnnotationKind _annotationKind = ImageAnnotationKind.rectangle;
  int _annotationStartXPercent = 15;
  int _annotationStartYPercent = 15;
  int _annotationEndXPercent = 85;
  int _annotationEndYPercent = 85;
  int _annotationColorArgb = 0xFFFFD400;
  int _annotationStrokeWidth = 4;
  bool _annotationFilled = false;
  int _annotationFontSize = 24;
  final List<_GeneralImageEditorSnapshot> _undoStack =
      <_GeneralImageEditorSnapshot>[];
  final List<_GeneralImageEditorSnapshot> _redoStack =
      <_GeneralImageEditorSnapshot>[];
  final List<_GeneralImageEditorSavedSnapshot> _savedSnapshots =
      <_GeneralImageEditorSavedSnapshot>[];
  int _savedSnapshotSerial = 1;
  Future<GeneralImageEditResult>? _previewFuture;
  String? _previewSourcePath;
  _GeneralImageEditorPanel _activePanel = _GeneralImageEditorPanel.geometry;
  bool _geometryDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _annotationTextController = TextEditingController(text: 'Label');
    _syncResizeWithImageInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _annotationTextController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant GeneralImageEditorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _resetOptionsInPlace();
      _undoStack.clear();
      _redoStack.clear();
      _savedSnapshots.clear();
      _savedSnapshotSerial = 1;
      return;
    }
    if (oldWidget.imageInfo?.width != widget.imageInfo?.width ||
        oldWidget.imageInfo?.height != widget.imageInfo?.height) {
      _previewFuture = null;
      _previewSourcePath = null;
      _syncResizeWithImageInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ResponsiveWorkspaceSplit(
        storageKey: 'general_image_editor',
        controlsWidth: 432,
        minControlsWidth: 320,
        maxControlsWidth: 560,
        controls: _buildControls(context),
        preview: _buildPreview(context),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final l10n = appL10nOf(context);
    final hasImage = widget.imagePath != null && widget.imageInfo != null;
    final info = widget.imageInfo;

    return _BoundedHeightScrollView(
      child: AppPanel(
        title: l10n.generalImageEditorTitle,
        trailing: info == null
            ? null
            : Text(
                '${info.width} x ${info.height}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TemplateImagePicker(
              imagePath: widget.imagePath,
              title: l10n.generalImageEditorSourceImageTitle,
              pickLabel: widget.imagePath == null
                  ? l10n.selectAction
                  : l10n.generalImageEditorReplaceAction,
              clearTooltip: l10n.generalImageEditorClearImageTooltip,
              previewHeight: 132,
              onPick: widget.onPickImage,
              onClear: widget.imagePath == null ? null : widget.onClearImage,
            ),
            const SizedBox(height: fieldGap),
            _EditorControlGroup(
              icon: Icons.auto_awesome_outlined,
              title: l10n.generalImageEditorQuickActionsTitle,
              subtitle: l10n.generalImageEditorQuickActionsSubtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPresetSection(hasImage),
                  const SizedBox(height: fieldGap),
                  _buildVersionSection(hasImage),
                ],
              ),
            ),
            const SizedBox(height: fieldGap),
            _buildApplyAndSaveAction(hasImage),
            if (_activePanel != _GeneralImageEditorPanel.geometry)
              const SizedBox(height: fieldGap),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(
                key: ValueKey(_activePanel),
                child: _buildActiveControlPanel(hasImage),
              ),
            ),
            const SizedBox(height: fieldGap),
            if (widget.errorMessage != null) ...[
              Text(
                widget.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: fieldGap),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanelTabs() {
    final l10n = appL10nOf(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _EditorPanelChoiceChip(
          icon: Icons.crop_rotate_outlined,
          label: l10n.generalImageEditorGeometryTab,
          selected: _activePanel == _GeneralImageEditorPanel.geometry,
          onSelected: () =>
              setState(() => _activePanel = _GeneralImageEditorPanel.geometry),
        ),
        _EditorPanelChoiceChip(
          icon: Icons.palette_outlined,
          label: l10n.generalImageEditorAppearanceTab,
          selected: _activePanel == _GeneralImageEditorPanel.appearance,
          onSelected: () => setState(
            () => _activePanel = _GeneralImageEditorPanel.appearance,
          ),
        ),
        _EditorPanelChoiceChip(
          icon: Icons.edit_note_outlined,
          label: l10n.generalImageEditorAnnotationTab,
          selected: _activePanel == _GeneralImageEditorPanel.annotation,
          onSelected: () => setState(
            () => _activePanel = _GeneralImageEditorPanel.annotation,
          ),
        ),
        _EditorPanelChoiceChip(
          icon: Icons.file_download_outlined,
          label: l10n.generalImageEditorOutputTab,
          selected: _activePanel == _GeneralImageEditorPanel.output,
          onSelected: () =>
              setState(() => _activePanel = _GeneralImageEditorPanel.output),
        ),
      ],
    );
  }

  Widget _buildActiveControlPanel(bool hasImage) {
    final l10n = appL10nOf(context);

    return switch (_activePanel) {
      _GeneralImageEditorPanel.geometry => const SizedBox.shrink(),
      _GeneralImageEditorPanel.appearance => _EditorControlGroup(
        icon: Icons.palette_outlined,
        title: l10n.generalImageEditorAppearanceTitle,
        subtitle: l10n.generalImageEditorAppearanceSubtitle,
        child: Column(
          children: [
            _buildColorSection(hasImage),
            const SizedBox(height: fieldGap),
            _buildEffectSection(hasImage),
            const SizedBox(height: fieldGap),
            _buildEffectRegionSection(hasImage),
          ],
        ),
      ),
      _GeneralImageEditorPanel.annotation => _EditorControlGroup(
        icon: Icons.edit_note_outlined,
        title: l10n.generalImageEditorAnnotationTab,
        subtitle: l10n.generalImageEditorAnnotationSubtitle,
        child: _buildAnnotationSection(hasImage),
      ),
      _GeneralImageEditorPanel.output => _EditorControlGroup(
        icon: Icons.file_download_outlined,
        title: l10n.generalImageEditorOutputTab,
        subtitle: l10n.generalImageEditorOutputSubtitle,
        child: _buildOutputSection(hasImage),
      ),
    };
  }

  Widget _buildApplyAndSaveAction(bool hasImage) {
    final l10n = appL10nOf(context);

    return PrimaryActionButton(
      onPressed: hasImage && !widget.isProcessing
          ? () => widget.onApplyEdit(_currentOptions())
          : null,
      icon: Icons.save_alt_outlined,
      label: l10n.generalImageEditorApplyAndSave,
      busyLabel: l10n.generalImageEditorProcessing,
      isBusy: widget.isProcessing,
    );
  }

  Widget _buildPreviewActionBar(bool hasImage) {
    final l10n = appL10nOf(context);
    final canUndo = hasImage && _undoStack.isNotEmpty;
    final canRedo = hasImage && _redoStack.isNotEmpty;
    final canEdit = hasImage && !widget.isProcessing;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Semantics(
          container: true,
          label: l10n.historyUndo,
          value: canUndo ? null : l10n.historyUndoUnavailable,
          button: true,
          enabled: canUndo,
          child: OutlinedButton.icon(
            onPressed: canUndo ? _undoEdit : null,
            icon: const Icon(Icons.undo),
            label: Text(l10n.historyUndo),
          ),
        ),
        Semantics(
          container: true,
          label: l10n.historyRedo,
          value: canRedo ? null : l10n.historyRedoUnavailable,
          button: true,
          enabled: canRedo,
          child: OutlinedButton.icon(
            onPressed: canRedo ? _redoEdit : null,
            icon: const Icon(Icons.redo),
            label: Text(l10n.historyRedo),
          ),
        ),
        OutlinedButton.icon(
          onPressed: canEdit ? _refreshPreview : null,
          icon: const Icon(Icons.visibility_outlined),
          label: Text(l10n.generalImageEditorGeneratePreview),
        ),
        OutlinedButton.icon(
          onPressed: canEdit ? _resetOptions : null,
          icon: const Icon(Icons.restart_alt),
          label: Text(l10n.generalImageEditorResetOptions),
        ),
      ],
    );
  }

  Widget _buildGeometryActionBar() {
    final l10n = appL10nOf(context);
    final canEdit =
        widget.imagePath != null &&
        !widget.isProcessing &&
        !_geometryDialogOpen;
    final geometrySummary = '${_cropSummary(l10n)} · ${_resizeSummary(l10n)}';

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        Tooltip(
          message: geometrySummary,
          child: Chip(
            avatar: const Icon(Icons.transform_outlined, size: 18),
            label: Text(_transformSummary(l10n)),
          ),
        ),
        Chip(
          avatar: const Icon(Icons.crop_outlined, size: 18),
          label: Text(_cropSummary(l10n)),
        ),
        Chip(
          avatar: const Icon(Icons.photo_size_select_large_outlined, size: 18),
          label: Text(_resizeSummary(l10n)),
        ),
        OutlinedButton.icon(
          onPressed: canEdit ? _showCropDialog : null,
          icon: const Icon(Icons.crop_outlined),
          label: Text(l10n.generalImageEditorCropTitle),
        ),
        OutlinedButton.icon(
          onPressed: canEdit ? _showResizeDialog : null,
          icon: const Icon(Icons.photo_size_select_large_outlined),
          label: Text(l10n.generalImageEditorResizeTitle),
        ),
        OutlinedButton.icon(
          onPressed: canEdit ? () => _rotateBy(-1) : null,
          icon: const Icon(Icons.rotate_left),
          label: Text(l10n.generalImageEditorRotateLeft),
        ),
        OutlinedButton.icon(
          onPressed: canEdit ? () => _rotateBy(1) : null,
          icon: const Icon(Icons.rotate_right),
          label: Text(l10n.generalImageEditorRotateRight),
        ),
        OutlinedButton.icon(
          onPressed: canEdit
              ? () => _commitOptionChange(
                  () => _flipHorizontal = !_flipHorizontal,
                )
              : null,
          icon: const Icon(Icons.flip),
          label: Text(l10n.generalImageEditorFlipHorizontal),
        ),
        OutlinedButton.icon(
          onPressed: canEdit
              ? () => _commitOptionChange(() => _flipVertical = !_flipVertical)
              : null,
          icon: const Icon(Icons.flip_camera_android_outlined),
          label: Text(l10n.generalImageEditorFlipVertical),
        ),
      ],
    );
  }

  Widget _buildPresetSection(bool enabled) {
    final l10n = appL10nOf(context);

    return _EditorExpansionSection(
      icon: Icons.auto_awesome_outlined,
      title: l10n.generalImageEditorPresetsTitle,
      subtitle: l10n.generalImageEditorPresetsSubtitle,
      initiallyExpanded: enabled,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PresetActionChip(
            icon: Icons.layers_clear_outlined,
            label: l10n.generalImageEditorTransparentPngPreset,
            enabled: enabled,
            onPressed: () =>
                _applyPreset(_GeneralImageEditorPreset.transparentPng),
          ),
          _PresetActionChip(
            icon: Icons.public_outlined,
            label: l10n.generalImageEditorSocialJpegPreset,
            enabled: enabled,
            onPressed: () => _applyPreset(_GeneralImageEditorPreset.socialJpeg),
          ),
          _PresetActionChip(
            icon: Icons.hdr_strong_outlined,
            label: l10n.generalImageEditorSharpJpegPreset,
            enabled: enabled,
            onPressed: () => _applyPreset(_GeneralImageEditorPreset.sharpJpeg),
          ),
          _PresetActionChip(
            icon: Icons.grid_on_outlined,
            label: l10n.generalImageEditorPixelPngPreset,
            enabled: enabled,
            onPressed: () => _applyPreset(_GeneralImageEditorPreset.pixelPng),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionSection(bool enabled) {
    final l10n = appL10nOf(context);

    return _EditorExpansionSection(
      icon: Icons.history_edu_outlined,
      title: l10n.generalImageEditorVersionTitle,
      subtitle: _versionSummary(l10n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: enabled ? _saveCurrentVersion : null,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(l10n.generalImageEditorSaveCurrentVersion),
          ),
          if (_savedSnapshots.isEmpty) ...[
            const SizedBox(height: fieldGap),
            Text(
              l10n.generalImageEditorNoSavedVersions,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            const SizedBox(height: fieldGap),
            for (var index = 0; index < _savedSnapshots.length; index++)
              _VersionSnapshotRow(
                snapshot: _savedSnapshots[index],
                onRestore: enabled ? () => _restoreSavedVersion(index) : null,
                onDelete: enabled ? () => _deleteSavedVersion(index) : null,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorSection(bool enabled) {
    final l10n = appL10nOf(context);

    return _EditorExpansionSection(
      icon: Icons.tune_outlined,
      title: l10n.generalImageEditorColorTitle,
      subtitle: _colorSummary(l10n),
      child: Column(
        children: [
          _LabeledSlider(
            label: l10n.generalImageEditorBrightness,
            value: _brightness,
            min: -100,
            max: 100,
            enabled: enabled,
            onChanged: (value) =>
                _commitOptionChange(() => _brightness = value),
          ),
          _LabeledSlider(
            label: l10n.generalImageEditorContrast,
            value: _contrast,
            min: -100,
            max: 100,
            enabled: enabled,
            onChanged: (value) => _commitOptionChange(() => _contrast = value),
          ),
          _LabeledSlider(
            label: l10n.generalImageEditorSaturation,
            value: _saturation,
            min: -100,
            max: 100,
            enabled: enabled,
            onChanged: (value) =>
                _commitOptionChange(() => _saturation = value),
          ),
          _LabeledSlider(
            label: l10n.generalImageEditorWarmth,
            value: _warmth,
            min: -100,
            max: 100,
            enabled: enabled,
            onChanged: (value) => _commitOptionChange(() => _warmth = value),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectSection(bool enabled) {
    final l10n = appL10nOf(context);

    return _EditorExpansionSection(
      icon: Icons.auto_fix_high_outlined,
      title: l10n.generalImageEditorEffectTitle,
      subtitle: _effectSummary(l10n),
      child: Column(
        children: [
          OptionDropdown<ImageEditColorEffect>(
            label: l10n.generalImageEditorFilterLabel,
            value: _effect,
            options: ImageEditColorEffect.values,
            labelBuilder: (effect) => _effectLabel(l10n, effect),
            onChanged: enabled
                ? (value) => _commitOptionChange(() => _effect = value)
                : null,
          ),
          const SizedBox(height: fieldGap),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _blurEnabled,
            onChanged: enabled
                ? (value) => _commitOptionChange(() => _blurEnabled = value)
                : null,
            title: Text(l10n.generalImageEditorBlur),
          ),
          IntegerStepperField(
            label: l10n.generalImageEditorBlurRadius,
            value: _blurRadius,
            minValue: 1,
            maxValue: 20,
            suffixText: 'px',
            enabled: enabled && _blurEnabled,
            onChanged: (value) =>
                _commitOptionChange(() => _blurRadius = value),
          ),
          const SizedBox(height: fieldGap),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _sharpenEnabled,
            onChanged: enabled
                ? (value) => _commitOptionChange(() => _sharpenEnabled = value)
                : null,
            title: Text(l10n.generalImageEditorSharpen),
          ),
          _LabeledSlider(
            label: l10n.generalImageEditorSharpenAmount,
            value: _sharpenAmount,
            min: 0,
            max: 100,
            enabled: enabled && _sharpenEnabled,
            onChanged: (value) =>
                _commitOptionChange(() => _sharpenAmount = value),
          ),
          const SizedBox(height: fieldGap),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _transparentBackgroundEnabled,
            onChanged: enabled
                ? (value) => _commitOptionChange(
                    () => _transparentBackgroundEnabled = value,
                  )
                : null,
            title: Text(l10n.generalImageEditorTransparentBackground),
          ),
          _LabeledSlider(
            label: l10n.generalImageEditorTransparentTolerance,
            value: _transparentTolerance,
            min: 0,
            max: 80,
            enabled: enabled && _transparentBackgroundEnabled,
            onChanged: (value) =>
                _commitOptionChange(() => _transparentTolerance = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _pixelationEnabled,
            onChanged: enabled
                ? (value) =>
                      _commitOptionChange(() => _pixelationEnabled = value)
                : null,
            title: Text(l10n.generalImageEditorPixelation),
          ),
          IntegerStepperField(
            label: l10n.generalImageEditorPixelBlock,
            value: _pixelationBlockSize,
            minValue: PixelationDefaults.minBlockSize,
            maxValue: PixelationDefaults.maxBlockSize,
            suffixText: 'px',
            enabled: enabled && _pixelationEnabled,
            onChanged: (value) =>
                _commitOptionChange(() => _pixelationBlockSize = value),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectRegionSection(bool enabled) {
    final l10n = appL10nOf(context);

    return _EditorExpansionSection(
      icon: Icons.select_all_outlined,
      title: l10n.generalImageEditorRegionTitle,
      subtitle: _effectRegionSummary(l10n),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _effectRegionEnabled,
            onChanged: enabled
                ? (value) =>
                      _commitOptionChange(() => _effectRegionEnabled = value)
                : null,
            title: Text(l10n.generalImageEditorProcessRegionOnly),
          ),
          ResponsivePair(
            first: IntegerStepperField(
              label: l10n.generalImageEditorLeftBoundary,
              value: _effectRegionLeftPercent,
              minValue: 0,
              maxValue: _effectRegionRightPercent - 1,
              suffixText: '%',
              enabled: enabled && _effectRegionEnabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _effectRegionLeftPercent = value),
            ),
            second: IntegerStepperField(
              label: l10n.generalImageEditorTopBoundary,
              value: _effectRegionTopPercent,
              minValue: 0,
              maxValue: _effectRegionBottomPercent - 1,
              suffixText: '%',
              enabled: enabled && _effectRegionEnabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _effectRegionTopPercent = value),
            ),
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: IntegerStepperField(
              label: l10n.generalImageEditorRightBoundary,
              value: _effectRegionRightPercent,
              minValue: _effectRegionLeftPercent + 1,
              maxValue: 100,
              suffixText: '%',
              enabled: enabled && _effectRegionEnabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _effectRegionRightPercent = value),
            ),
            second: IntegerStepperField(
              label: l10n.generalImageEditorBottomBoundary,
              value: _effectRegionBottomPercent,
              minValue: _effectRegionTopPercent + 1,
              maxValue: 100,
              suffixText: '%',
              enabled: enabled && _effectRegionEnabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _effectRegionBottomPercent = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationSection(bool enabled) {
    final l10n = appL10nOf(context);
    final canFill = _annotationSupportsFill(_annotationKind);

    return _EditorExpansionSection(
      icon: Icons.edit_note_outlined,
      title: l10n.generalImageEditorAnnotationTab,
      subtitle: _annotationSummary(l10n),
      initiallyExpanded: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OptionDropdown<ImageAnnotationKind>(
            label: l10n.generalImageEditorAnnotationType,
            value: _annotationKind,
            options: ImageAnnotationKind.values,
            labelBuilder: (kind) => _annotationKindLabel(l10n, kind),
            onChanged: enabled
                ? (value) => _commitOptionChange(() => _annotationKind = value)
                : null,
          ),
          if (_annotationKind == ImageAnnotationKind.text) ...[
            const SizedBox(height: fieldGap),
            TextField(
              controller: _annotationTextController,
              enabled: enabled,
              decoration: InputDecoration(
                labelText: l10n.generalImageEditorAnnotationText,
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
          const SizedBox(height: fieldGap),
          Text(
            l10n.generalImageEditorAnnotationPositionPercent,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          ResponsivePair(
            first: IntegerStepperField(
              label: l10n.generalImageEditorStartX,
              value: _annotationStartXPercent,
              minValue: 0,
              maxValue: 100,
              suffixText: '%',
              enabled: enabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _annotationStartXPercent = value),
            ),
            second: IntegerStepperField(
              label: l10n.generalImageEditorStartY,
              value: _annotationStartYPercent,
              minValue: 0,
              maxValue: 100,
              suffixText: '%',
              enabled: enabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _annotationStartYPercent = value),
            ),
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: IntegerStepperField(
              label: l10n.generalImageEditorEndX,
              value: _annotationEndXPercent,
              minValue: 0,
              maxValue: 100,
              suffixText: '%',
              enabled: enabled && _annotationKind != ImageAnnotationKind.text,
              onChanged: (value) =>
                  _commitOptionChange(() => _annotationEndXPercent = value),
            ),
            second: IntegerStepperField(
              label: l10n.generalImageEditorEndY,
              value: _annotationEndYPercent,
              minValue: 0,
              maxValue: 100,
              suffixText: '%',
              enabled: enabled && _annotationKind != ImageAnnotationKind.text,
              onChanged: (value) =>
                  _commitOptionChange(() => _annotationEndYPercent = value),
            ),
          ),
          const SizedBox(height: fieldGap),
          _buildAnnotationColorSelector(enabled),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: IntegerStepperField(
              label: l10n.generalImageEditorStrokeWidth,
              value: _annotationStrokeWidth,
              minValue: 1,
              maxValue: 32,
              suffixText: 'px',
              enabled: enabled && _annotationKind != ImageAnnotationKind.text,
              onChanged: (value) =>
                  _commitOptionChange(() => _annotationStrokeWidth = value),
            ),
            second: IntegerStepperField(
              label: l10n.generalImageEditorFontSize,
              value: _annotationFontSize,
              minValue: 14,
              maxValue: 48,
              suffixText: 'px',
              enabled: enabled && _annotationKind == ImageAnnotationKind.text,
              onChanged: (value) =>
                  _commitOptionChange(() => _annotationFontSize = value),
            ),
          ),
          if (canFill) ...[
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _annotationFilled,
              onChanged: enabled
                  ? (value) =>
                        _commitOptionChange(() => _annotationFilled = value)
                  : null,
              title: Text(l10n.generalImageEditorFillShape),
            ),
          ],
          if (_annotations.isNotEmpty) ...[
            const SizedBox(height: fieldGap),
            for (var index = 0; index < _annotations.length; index++)
              _AnnotationRow(
                annotation: _annotations[index],
                index: index,
                onDelete: enabled ? () => _removeAnnotation(index) : null,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnnotationColorSelector(bool enabled) {
    final l10n = appL10nOf(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final argb in _annotationColorOptions)
          _AnnotationColorSwatch(
            color: Color(argb),
            label: _annotationColorLabel(l10n, argb),
            selected: _annotationColorArgb == argb,
            onTap: enabled
                ? () => _commitOptionChange(() => _annotationColorArgb = argb)
                : null,
          ),
      ],
    );
  }

  Widget _buildOutputSection(bool enabled) {
    final l10n = appL10nOf(context);

    return _EditorExpansionSection(
      icon: Icons.file_download_outlined,
      title: l10n.generalImageEditorOutputTab,
      subtitle: _outputSummary(l10n),
      initiallyExpanded: enabled,
      child: Column(
        children: [
          OptionDropdown<GeneralImageOutputFormat>(
            label: l10n.generalImageEditorOutputFormat,
            value: _outputFormat,
            options: GeneralImageOutputFormat.values,
            labelBuilder: _outputFormatLabel,
            onChanged: enabled
                ? (value) => _commitOptionChange(() => _outputFormat = value)
                : null,
          ),
          const SizedBox(height: fieldGap),
          IntegerStepperField(
            label: l10n.generalImageEditorJpegQuality,
            value: _jpegQuality,
            minValue: 1,
            maxValue: 100,
            suffixText: '%',
            enabled: enabled && _outputFormat == GeneralImageOutputFormat.jpeg,
            onChanged: (value) =>
                _commitOptionChange(() => _jpegQuality = value),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final l10n = appL10nOf(context);
    final imagePath = widget.imagePath;
    final previewFuture = _previewFuture;

    if (imagePath == null) {
      return _buildPreviewSurface(
        hasImage: false,
        preview: PreviewPanelShell(
          key: const ValueKey('general-image-editor-preview-panel'),
          title: l10n.generalImageEditorPreviewTitle,
          child: PreviewStateSurface.empty(
            message: l10n.generalImageEditorPreviewEmpty,
          ),
        ),
      );
    }

    if (previewFuture != null && _previewSourcePath == imagePath) {
      return _buildPreviewSurface(
        hasImage: true,
        preview: PreviewPanelShell(
          key: const ValueKey('general-image-editor-preview-panel'),
          title: l10n.generalImageEditorPreviewTitle,
          child: FutureBuilder<GeneralImageEditResult>(
            future: previewFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return PreviewStateSurface.loading(
                  message: l10n.generalImageEditorPreviewLoading,
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return PreviewStateSurface.error(
                  title: l10n.generalImageEditorPreviewFailed,
                  message:
                      '${snapshot.error ?? l10n.generalImageEditorNoPreviewResult}',
                );
              }
              final result = snapshot.data!;
              return _ImagePreviewSurface(
                footer:
                    '${result.width} x ${result.height} · ${result.summary}',
                child: Image.memory(result.bytes, fit: BoxFit.contain),
              );
            },
          ),
        ),
      );
    }

    return _buildPreviewSurface(
      hasImage: true,
      preview: PreviewPanelShell(
        key: const ValueKey('general-image-editor-preview-panel'),
        title: l10n.generalImageEditorPreviewTitle,
        child: _ImagePreviewSurface(
          footer: l10n.generalImageEditorPreviewFooter(
            fileNameFromPath(imagePath),
          ),
          child: _EditableImagePreview(
            key: const ValueKey('general-image-editable-preview'),
            imagePath: imagePath,
            imageInfo: widget.imageInfo!,
            displayInfo: _currentDisplayInfo(),
            crop: ImageCropMargins(
              left: _cropLeft,
              top: _cropTop,
              right: _cropRight,
              bottom: _cropBottom,
            ),
            quarterTurns: _quarterTurns,
            flipHorizontal: _flipHorizontal,
            flipVertical: _flipVertical,
            effectRegion: _currentEffectRegion(),
            annotations: _annotations,
            onCropChanged: _setCropMargins,
            onEffectRegionChanged: _setEffectRegion,
            onAnnotationDeleted: _removeAnnotation,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSurface({
    required bool hasImage,
    required Widget preview,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPreviewTopToolbar(hasImage),
          if (hasImage &&
              _activePanel == _GeneralImageEditorPanel.geometry) ...[
            const SizedBox(height: fieldGap),
            Align(
              alignment: Alignment.centerRight,
              child: KeyedSubtree(
                key: const ValueKey('general-image-editor-geometry-actions'),
                child: _buildGeometryActionBar(),
              ),
            ),
          ],
          if (hasImage &&
              _activePanel == _GeneralImageEditorPanel.appearance) ...[
            const SizedBox(height: fieldGap),
            Align(
              alignment: Alignment.centerRight,
              child: KeyedSubtree(
                key: const ValueKey('general-image-editor-appearance-actions'),
                child: _buildAppearanceActionBar(),
              ),
            ),
          ],
          if (hasImage &&
              _activePanel == _GeneralImageEditorPanel.annotation) ...[
            const SizedBox(height: fieldGap),
            Align(
              alignment: Alignment.centerRight,
              child: KeyedSubtree(
                key: const ValueKey('general-image-editor-annotation-actions'),
                child: _buildAnnotationActionBar(),
              ),
            ),
          ],
          const SizedBox(height: fieldGap),
          preview,
        ],
      ),
    );
  }

  Widget _buildPreviewTopToolbar(bool hasImage) {
    final panelTabs = KeyedSubtree(
      key: const ValueKey('general-image-editor-panel-tabs'),
      child: _buildControlPanelTabs(),
    );
    final previewActions = KeyedSubtree(
      key: const ValueKey('general-image-editor-preview-actions'),
      child: _buildPreviewActionBar(hasImage),
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runAlignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: fieldGap,
      runSpacing: fieldGap,
      children: [panelTabs, previewActions],
    );
  }

  Widget _buildAppearanceActionBar() {
    final l10n = appL10nOf(context);
    final canEdit =
        widget.imagePath != null &&
        !widget.isProcessing &&
        _effectRegionEnabled;

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: canEdit
              ? () => _commitOptionChange(_setCenteredEffectRegionInPlace)
              : null,
          icon: const Icon(Icons.center_focus_strong_outlined),
          label: Text(l10n.generalImageEditorCenterHalfRegion),
        ),
        OutlinedButton.icon(
          onPressed: canEdit
              ? () => _commitOptionChange(_setFullEffectRegionInPlace)
              : null,
          icon: const Icon(Icons.fullscreen_outlined),
          label: Text(l10n.generalImageEditorFullImageRegion),
        ),
      ],
    );
  }

  Widget _buildAnnotationActionBar() {
    final l10n = appL10nOf(context);
    final canEdit = widget.imagePath != null && !widget.isProcessing;

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: canEdit ? _addAnnotation : null,
          icon: const Icon(Icons.add_outlined),
          label: Text(l10n.generalImageEditorAddAnnotation),
        ),
        OutlinedButton.icon(
          onPressed: canEdit && _annotations.isNotEmpty
              ? _clearAnnotations
              : null,
          icon: const Icon(Icons.layers_clear_outlined),
          label: Text(l10n.generalImageEditorClearAnnotations),
        ),
      ],
    );
  }

  Future<void> _showCropDialog() async {
    if (_geometryDialogOpen) {
      return;
    }

    final l10n = appL10nOf(context);
    final info = widget.imageInfo;
    if (info == null) {
      return;
    }

    var left = _cropLeft;
    var top = _cropTop;
    var right = _cropRight;
    var bottom = _cropBottom;
    final maxHorizontal = (info.width - 1).clamp(1, 99999).toInt();
    final maxVertical = (info.height - 1).clamp(1, 99999).toInt();

    setState(() => _geometryDialogOpen = true);
    final bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              void applyRatio(int ratioWidth, int ratioHeight) {
                final crop = _centeredCropMarginsForRatio(
                  ratioWidth,
                  ratioHeight,
                );
                if (crop == null) {
                  return;
                }
                setDialogState(() {
                  left = crop.left;
                  top = crop.top;
                  right = crop.right;
                  bottom = crop.bottom;
                });
              }

              return AlertDialog(
                title: Text(l10n.generalImageEditorCropTitle),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ResponsivePair(
                          first: IntegerStepperField(
                            label: l10n.generalImageEditorLeftSide,
                            value: left,
                            minValue: 0,
                            maxValue: maxHorizontal,
                            suffixText: 'px',
                            onChanged: (value) =>
                                setDialogState(() => left = value),
                          ),
                          second: IntegerStepperField(
                            label: l10n.generalImageEditorTopSide,
                            value: top,
                            minValue: 0,
                            maxValue: maxVertical,
                            suffixText: 'px',
                            onChanged: (value) =>
                                setDialogState(() => top = value),
                          ),
                        ),
                        const SizedBox(height: fieldGap),
                        ResponsivePair(
                          first: IntegerStepperField(
                            label: l10n.generalImageEditorRightSide,
                            value: right,
                            minValue: 0,
                            maxValue: maxHorizontal,
                            suffixText: 'px',
                            onChanged: (value) =>
                                setDialogState(() => right = value),
                          ),
                          second: IntegerStepperField(
                            label: l10n.generalImageEditorBottomSide,
                            value: bottom,
                            minValue: 0,
                            maxValue: maxVertical,
                            suffixText: 'px',
                            onChanged: (value) =>
                                setDialogState(() => bottom = value),
                          ),
                        ),
                        const SizedBox(height: fieldGap),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => applyRatio(1, 1),
                              icon: const Icon(Icons.aspect_ratio_outlined),
                              label: const Text('1:1'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => applyRatio(4, 3),
                              icon: const Icon(Icons.aspect_ratio_outlined),
                              label: const Text('4:3'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => applyRatio(16, 9),
                              icon: const Icon(Icons.aspect_ratio_outlined),
                              label: const Text('16:9'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => setDialogState(() {
                                left = 0;
                                top = 0;
                                right = 0;
                                bottom = 0;
                              }),
                              icon: const Icon(Icons.crop_free_outlined),
                              label: Text(l10n.generalImageEditorClearCrop),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(l10n.cancelAction),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(l10n.saveAction),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _geometryDialogOpen = false);
      } else {
        _geometryDialogOpen = false;
      }
    }

    if (confirmed != true || !mounted) {
      return;
    }
    _commitOptionChange(() {
      _cropLeft = left;
      _cropTop = top;
      _cropRight = right;
      _cropBottom = bottom;
    });
  }

  Future<void> _showResizeDialog() async {
    if (_geometryDialogOpen) {
      return;
    }

    final l10n = appL10nOf(context);
    final info = widget.imageInfo;

    var resizeEnabled = _resizeEnabled;
    var lockAspectRatio = _lockAspectRatio;
    var width = _resizeWidth;
    var height = _resizeHeight;

    setState(() => _geometryDialogOpen = true);
    final bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              void setWidth(int value) {
                setDialogState(() {
                  width = value;
                  if (lockAspectRatio && info != null && info.width > 0) {
                    height = (value * info.height / info.width)
                        .round()
                        .clamp(1, _maxEditDimension)
                        .toInt();
                  }
                });
              }

              void setHeight(int value) {
                setDialogState(() {
                  height = value;
                  if (lockAspectRatio && info != null && info.height > 0) {
                    width = (value * info.width / info.height)
                        .round()
                        .clamp(1, _maxEditDimension)
                        .toInt();
                  }
                });
              }

              return AlertDialog(
                title: Text(l10n.generalImageEditorResizeTitle),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: resizeEnabled,
                          onChanged: (value) =>
                              setDialogState(() => resizeEnabled = value),
                          title: Text(l10n.generalImageEditorResizeOutput),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: lockAspectRatio,
                          onChanged: resizeEnabled
                              ? (value) => setDialogState(
                                  () => lockAspectRatio = value ?? true,
                                )
                              : null,
                          title: Text(l10n.generalImageEditorLockAspectRatio),
                        ),
                        ResponsivePair(
                          first: IntegerStepperField(
                            label: l10n.generalImageEditorWidth,
                            value: width,
                            minValue: 1,
                            maxValue: _maxEditDimension,
                            suffixText: 'px',
                            enabled: resizeEnabled,
                            onChanged: setWidth,
                          ),
                          second: IntegerStepperField(
                            label: l10n.generalImageEditorHeight,
                            value: height,
                            minValue: 1,
                            maxValue: _maxEditDimension,
                            suffixText: 'px',
                            enabled: resizeEnabled,
                            onChanged: setHeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(l10n.cancelAction),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(l10n.saveAction),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _geometryDialogOpen = false);
      } else {
        _geometryDialogOpen = false;
      }
    }

    if (confirmed != true || !mounted) {
      return;
    }
    _commitOptionChange(() {
      _resizeEnabled = resizeEnabled;
      _lockAspectRatio = lockAspectRatio;
      _resizeWidth = width;
      _resizeHeight = height;
    });
  }

  void _refreshPreview() {
    final imagePath = widget.imagePath;
    if (imagePath == null) {
      return;
    }
    final labels = generalImageEditSummaryLabels(appL10nOf(context));
    setState(() {
      _previewSourcePath = imagePath;
      _previewFuture = File(imagePath).readAsBytes().then(
        (bytes) => GeneralImageEditingService.editInBackground(
          bytes,
          options: _currentOptions(),
          labels: labels,
        ),
      );
    });
  }

  void _commitOptionChange(VoidCallback change) {
    final before = _snapshot();
    setState(() {
      change();
      final after = _snapshot();
      if (after != before) {
        _undoStack.add(before);
        if (_undoStack.length > 60) {
          _undoStack.removeAt(0);
        }
        _redoStack.clear();
      }
      _previewFuture = null;
      _previewSourcePath = null;
    });
  }

  void _saveCurrentVersion() {
    final l10n = appL10nOf(context);
    final snapshot = _snapshot();
    final label = l10n.generalImageEditorVersionLabel(_savedSnapshotSerial++);
    setState(() {
      _savedSnapshots.insert(
        0,
        _GeneralImageEditorSavedSnapshot(
          label: label,
          summary: _snapshotSummary(l10n, snapshot),
          snapshot: snapshot,
        ),
      );
      if (_savedSnapshots.length > 8) {
        _savedSnapshots.removeLast();
      }
    });
  }

  void _restoreSavedVersion(int index) {
    if (index < 0 || index >= _savedSnapshots.length) {
      return;
    }
    final target = _savedSnapshots[index].snapshot;
    _commitOptionChange(() => _applySnapshot(target));
  }

  void _deleteSavedVersion(int index) {
    if (index < 0 || index >= _savedSnapshots.length) {
      return;
    }
    setState(() => _savedSnapshots.removeAt(index));
  }

  void _undoEdit() {
    if (_undoStack.isEmpty) {
      return;
    }
    final current = _snapshot();
    final target = _undoStack.removeLast();
    setState(() {
      _redoStack.add(current);
      _applySnapshot(target);
      _previewFuture = null;
      _previewSourcePath = null;
    });
  }

  void _redoEdit() {
    if (_redoStack.isEmpty) {
      return;
    }
    final current = _snapshot();
    final target = _redoStack.removeLast();
    setState(() {
      _undoStack.add(current);
      _applySnapshot(target);
      _previewFuture = null;
      _previewSourcePath = null;
    });
  }

  void _rotateBy(int delta) {
    _commitOptionChange(
      () => _quarterTurns = ((_quarterTurns + delta) % 4 + 4) % 4,
    );
  }

  void _setCropMargins(ImageCropMargins margins) {
    final info = widget.imageInfo;
    if (info == null) {
      return;
    }

    final left = margins.left.clamp(0, info.width - 1).toInt();
    final top = margins.top.clamp(0, info.height - 1).toInt();
    final right = margins.right.clamp(0, info.width - left - 1).toInt();
    final bottom = margins.bottom.clamp(0, info.height - top - 1).toInt();

    _commitOptionChange(() {
      _cropLeft = left;
      _cropTop = top;
      _cropRight = right;
      _cropBottom = bottom;
    });
  }

  void _setEffectRegion(ImageEffectRegion region) {
    if (!region.enabled) {
      return;
    }

    final left = (region.leftRatio * 100).round().clamp(0, 99).toInt();
    final top = (region.topRatio * 100).round().clamp(0, 99).toInt();
    final right = (region.rightRatio * 100)
        .round()
        .clamp(left + 1, 100)
        .toInt();
    final bottom = (region.bottomRatio * 100)
        .round()
        .clamp(top + 1, 100)
        .toInt();

    _commitOptionChange(() {
      _effectRegionEnabled = true;
      _effectRegionLeftPercent = left;
      _effectRegionTopPercent = top;
      _effectRegionRightPercent = right;
      _effectRegionBottomPercent = bottom;
    });
  }

  ImageCropMargins? _centeredCropMarginsForRatio(
    int ratioWidth,
    int ratioHeight,
  ) {
    final info = widget.imageInfo;
    if (info == null || ratioWidth <= 0 || ratioHeight <= 0) {
      return null;
    }

    final sourceRatio = info.width / info.height;
    final targetRatio = ratioWidth / ratioHeight;
    var left = 0;
    var right = 0;
    var top = 0;
    var bottom = 0;

    if (sourceRatio > targetRatio) {
      final targetWidth = (info.height * targetRatio)
          .round()
          .clamp(1, info.width)
          .toInt();
      final totalCrop = info.width - targetWidth;
      left = totalCrop ~/ 2;
      right = totalCrop - left;
    } else if (sourceRatio < targetRatio) {
      final targetHeight = (info.width / targetRatio)
          .round()
          .clamp(1, info.height)
          .toInt();
      final totalCrop = info.height - targetHeight;
      top = totalCrop ~/ 2;
      bottom = totalCrop - top;
    }

    return ImageCropMargins(left: left, top: top, right: right, bottom: bottom);
  }

  void _setCenteredEffectRegionInPlace() {
    _effectRegionLeftPercent = 25;
    _effectRegionTopPercent = 25;
    _effectRegionRightPercent = 75;
    _effectRegionBottomPercent = 75;
  }

  void _setFullEffectRegionInPlace() {
    _effectRegionLeftPercent = 0;
    _effectRegionTopPercent = 0;
    _effectRegionRightPercent = 100;
    _effectRegionBottomPercent = 100;
  }

  void _addAnnotation() {
    final annotation = ImageAnnotation(
      kind: _annotationKind,
      text: _annotationTextController.text,
      startXRatio: _annotationStartXPercent / 100,
      startYRatio: _annotationStartYPercent / 100,
      endXRatio: _annotationEndXPercent / 100,
      endYRatio: _annotationEndYPercent / 100,
      colorArgb: _annotationColorArgb,
      strokeWidth: _annotationStrokeWidth,
      filled: _annotationSupportsFill(_annotationKind) && _annotationFilled,
      fontSize: _annotationFontSize,
    );
    if (!annotation.hasVisibleContent) {
      return;
    }

    _commitOptionChange(() {
      _annotations.add(annotation);
    });
  }

  void _removeAnnotation(int index) {
    if (index < 0 || index >= _annotations.length) {
      return;
    }

    _commitOptionChange(() {
      _annotations.removeAt(index);
    });
  }

  void _clearAnnotations() {
    _commitOptionChange(() {
      _annotations.clear();
    });
  }

  void _applyPreset(_GeneralImageEditorPreset preset) {
    _commitOptionChange(() {
      switch (preset) {
        case _GeneralImageEditorPreset.transparentPng:
          _outputFormat = GeneralImageOutputFormat.png;
          _jpegQuality = 92;
          _transparentBackgroundEnabled = true;
          _transparentTolerance = 28;
          _blurEnabled = false;
          _sharpenEnabled = false;
          _pixelationEnabled = false;
        case _GeneralImageEditorPreset.socialJpeg:
          _outputFormat = GeneralImageOutputFormat.jpeg;
          _jpegQuality = 86;
          _transparentBackgroundEnabled = false;
          _blurEnabled = false;
          _sharpenEnabled = true;
          _sharpenAmount = 35;
          _pixelationEnabled = false;
          _setResizeLongEdgeInPlace(1080);
        case _GeneralImageEditorPreset.sharpJpeg:
          _outputFormat = GeneralImageOutputFormat.jpeg;
          _jpegQuality = 92;
          _transparentBackgroundEnabled = false;
          _blurEnabled = false;
          _sharpenEnabled = true;
          _sharpenAmount = 55;
          _pixelationEnabled = false;
        case _GeneralImageEditorPreset.pixelPng:
          _outputFormat = GeneralImageOutputFormat.png;
          _jpegQuality = 92;
          _transparentBackgroundEnabled = false;
          _blurEnabled = false;
          _sharpenEnabled = false;
          _pixelationEnabled = true;
          _pixelationBlockSize = 8;
          _contrast = 12;
          _saturation = 24;
      }
    });
  }

  void _setResizeLongEdgeInPlace(int longEdge) {
    final info = widget.imageInfo;
    if (info == null || info.width <= 0 || info.height <= 0) {
      return;
    }

    final sourceLongEdge = math.max(info.width, info.height);
    final scale = sourceLongEdge > longEdge ? longEdge / sourceLongEdge : 1.0;
    _resizeEnabled = true;
    _lockAspectRatio = true;
    _resizeWidth = (info.width * scale)
        .round()
        .clamp(1, _maxEditDimension)
        .toInt();
    _resizeHeight = (info.height * scale)
        .round()
        .clamp(1, _maxEditDimension)
        .toInt();
  }

  void _resetOptions() {
    _commitOptionChange(_resetOptionsInPlace);
  }

  void _resetOptionsInPlace() {
    _cropLeft = 0;
    _cropTop = 0;
    _cropRight = 0;
    _cropBottom = 0;
    _quarterTurns = 0;
    _flipHorizontal = false;
    _flipVertical = false;
    _resizeEnabled = false;
    _lockAspectRatio = true;
    _brightness = 0;
    _contrast = 0;
    _saturation = 0;
    _warmth = 0;
    _effect = ImageEditColorEffect.none;
    _effectRegionEnabled = false;
    _effectRegionLeftPercent = 15;
    _effectRegionTopPercent = 15;
    _effectRegionRightPercent = 85;
    _effectRegionBottomPercent = 85;
    _blurEnabled = false;
    _blurRadius = 2;
    _sharpenEnabled = false;
    _sharpenAmount = 50;
    _pixelationEnabled = false;
    _pixelationBlockSize = 8;
    _transparentBackgroundEnabled = false;
    _transparentTolerance = 28;
    _outputFormat = GeneralImageOutputFormat.png;
    _jpegQuality = 92;
    _annotations.clear();
    _annotationKind = ImageAnnotationKind.rectangle;
    _annotationStartXPercent = 15;
    _annotationStartYPercent = 15;
    _annotationEndXPercent = 85;
    _annotationEndYPercent = 85;
    _annotationColorArgb = 0xFFFFD400;
    _annotationStrokeWidth = 4;
    _annotationFilled = false;
    _annotationFontSize = 24;
    _annotationTextController.text = 'Label';
    _previewFuture = null;
    _previewSourcePath = null;
    _syncResizeWithImageInfo();
  }

  _GeneralImageEditorSnapshot _snapshot() {
    return _GeneralImageEditorSnapshot(
      cropLeft: _cropLeft,
      cropTop: _cropTop,
      cropRight: _cropRight,
      cropBottom: _cropBottom,
      quarterTurns: _quarterTurns,
      flipHorizontal: _flipHorizontal,
      flipVertical: _flipVertical,
      resizeEnabled: _resizeEnabled,
      lockAspectRatio: _lockAspectRatio,
      resizeWidth: _resizeWidth,
      resizeHeight: _resizeHeight,
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
      warmth: _warmth,
      effect: _effect,
      effectRegionEnabled: _effectRegionEnabled,
      effectRegionLeftPercent: _effectRegionLeftPercent,
      effectRegionTopPercent: _effectRegionTopPercent,
      effectRegionRightPercent: _effectRegionRightPercent,
      effectRegionBottomPercent: _effectRegionBottomPercent,
      blurEnabled: _blurEnabled,
      blurRadius: _blurRadius,
      sharpenEnabled: _sharpenEnabled,
      sharpenAmount: _sharpenAmount,
      pixelationEnabled: _pixelationEnabled,
      pixelationBlockSize: _pixelationBlockSize,
      transparentBackgroundEnabled: _transparentBackgroundEnabled,
      transparentTolerance: _transparentTolerance,
      outputFormat: _outputFormat,
      jpegQuality: _jpegQuality,
      annotations: List<ImageAnnotation>.unmodifiable(_annotations),
      annotationKind: _annotationKind,
      annotationText: _annotationTextController.text,
      annotationStartXPercent: _annotationStartXPercent,
      annotationStartYPercent: _annotationStartYPercent,
      annotationEndXPercent: _annotationEndXPercent,
      annotationEndYPercent: _annotationEndYPercent,
      annotationColorArgb: _annotationColorArgb,
      annotationStrokeWidth: _annotationStrokeWidth,
      annotationFilled: _annotationFilled,
      annotationFontSize: _annotationFontSize,
    );
  }

  void _applySnapshot(_GeneralImageEditorSnapshot snapshot) {
    _cropLeft = snapshot.cropLeft;
    _cropTop = snapshot.cropTop;
    _cropRight = snapshot.cropRight;
    _cropBottom = snapshot.cropBottom;
    _quarterTurns = snapshot.quarterTurns;
    _flipHorizontal = snapshot.flipHorizontal;
    _flipVertical = snapshot.flipVertical;
    _resizeEnabled = snapshot.resizeEnabled;
    _lockAspectRatio = snapshot.lockAspectRatio;
    _resizeWidth = snapshot.resizeWidth;
    _resizeHeight = snapshot.resizeHeight;
    _brightness = snapshot.brightness;
    _contrast = snapshot.contrast;
    _saturation = snapshot.saturation;
    _warmth = snapshot.warmth;
    _effect = snapshot.effect;
    _effectRegionEnabled = snapshot.effectRegionEnabled;
    _effectRegionLeftPercent = snapshot.effectRegionLeftPercent;
    _effectRegionTopPercent = snapshot.effectRegionTopPercent;
    _effectRegionRightPercent = snapshot.effectRegionRightPercent;
    _effectRegionBottomPercent = snapshot.effectRegionBottomPercent;
    _blurEnabled = snapshot.blurEnabled;
    _blurRadius = snapshot.blurRadius;
    _sharpenEnabled = snapshot.sharpenEnabled;
    _sharpenAmount = snapshot.sharpenAmount;
    _pixelationEnabled = snapshot.pixelationEnabled;
    _pixelationBlockSize = snapshot.pixelationBlockSize;
    _transparentBackgroundEnabled = snapshot.transparentBackgroundEnabled;
    _transparentTolerance = snapshot.transparentTolerance;
    _outputFormat = snapshot.outputFormat;
    _jpegQuality = snapshot.jpegQuality;
    _annotations
      ..clear()
      ..addAll(snapshot.annotations);
    _annotationKind = snapshot.annotationKind;
    _annotationTextController.text = snapshot.annotationText;
    _annotationStartXPercent = snapshot.annotationStartXPercent;
    _annotationStartYPercent = snapshot.annotationStartYPercent;
    _annotationEndXPercent = snapshot.annotationEndXPercent;
    _annotationEndYPercent = snapshot.annotationEndYPercent;
    _annotationColorArgb = snapshot.annotationColorArgb;
    _annotationStrokeWidth = snapshot.annotationStrokeWidth;
    _annotationFilled = snapshot.annotationFilled;
    _annotationFontSize = snapshot.annotationFontSize;
  }

  void _syncResizeWithImageInfo() {
    final info = widget.imageInfo;
    _resizeWidth = (info?.width ?? 1).clamp(1, _maxEditDimension).toInt();
    _resizeHeight = (info?.height ?? 1).clamp(1, _maxEditDimension).toInt();
  }

  ImageEffectRegion _currentEffectRegion() {
    return ImageEffectRegion(
      enabled: _effectRegionEnabled,
      leftRatio: _effectRegionLeftPercent / 100,
      topRatio: _effectRegionTopPercent / 100,
      rightRatio: _effectRegionRightPercent / 100,
      bottomRatio: _effectRegionBottomPercent / 100,
    );
  }

  ImageInspectionResult _currentDisplayInfo() {
    final info = widget.imageInfo!;
    final turns = _normalizedQuarterTurns(_quarterTurns);
    final rotatedWidth = turns.isOdd ? info.height : info.width;
    final rotatedHeight = turns.isOdd ? info.width : info.height;

    if (!_resizeEnabled) {
      return ImageInspectionResult(
        width: rotatedWidth,
        height: rotatedHeight,
        hasAlpha: info.hasAlpha,
      );
    }

    return ImageInspectionResult(
      width: _resizeWidth.clamp(1, _maxEditDimension).toInt(),
      height: _resizeHeight.clamp(1, _maxEditDimension).toInt(),
      hasAlpha: info.hasAlpha,
    );
  }

  GeneralImageEditOptions _currentOptions() {
    return GeneralImageEditOptions(
      crop: ImageCropMargins(
        left: _cropLeft,
        top: _cropTop,
        right: _cropRight,
        bottom: _cropBottom,
      ),
      quarterTurns: _quarterTurns,
      flipHorizontal: _flipHorizontal,
      flipVertical: _flipVertical,
      resize: _resizeEnabled
          ? ImageResizeOptions(width: _resizeWidth, height: _resizeHeight)
          : const ImageResizeOptions(),
      adjustments: ImageColorAdjustments(
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        warmth: _warmth,
      ),
      effect: _effect,
      effectRegion: _currentEffectRegion(),
      blurRadius: _blurEnabled ? _blurRadius : 0,
      sharpenAmount: _sharpenEnabled ? _sharpenAmount : 0,
      pixelationBlockSize: _pixelationEnabled ? _pixelationBlockSize : 0,
      backgroundTransparencyTolerance: _transparentBackgroundEnabled
          ? _transparentTolerance
          : null,
      annotations: List<ImageAnnotation>.unmodifiable(_annotations),
      outputFormat: _outputFormat,
      jpegQuality: _jpegQuality,
    );
  }

  String _transformSummary(AppLocalizations l10n) {
    final parts = <String>[
      if (_quarterTurns != 0)
        l10n.generalImageEditorRotatedDegrees(_quarterTurns * 90),
      if (_flipHorizontal) l10n.generalImageEditorFlipHorizontal,
      if (_flipVertical) l10n.generalImageEditorFlipVertical,
    ];
    return parts.isEmpty
        ? l10n.generalImageEditorNoTransform
        : parts.join(' · ');
  }

  String _cropSummary(AppLocalizations l10n) {
    final parts = <String>[
      if (_cropLeft > 0) l10n.generalImageEditorCropLeftSummary(_cropLeft),
      if (_cropTop > 0) l10n.generalImageEditorCropTopSummary(_cropTop),
      if (_cropRight > 0) l10n.generalImageEditorCropRightSummary(_cropRight),
      if (_cropBottom > 0)
        l10n.generalImageEditorCropBottomSummary(_cropBottom),
    ];
    return parts.isEmpty
        ? l10n.generalImageEditorNoCrop
        : l10n.generalImageEditorCropSummary(parts.join(' · '));
  }

  String _resizeSummary(AppLocalizations l10n) {
    if (!_resizeEnabled) {
      return l10n.generalImageEditorOriginalSize;
    }
    return '$_resizeWidth x $_resizeHeight';
  }

  String _colorSummary(AppLocalizations l10n) {
    final parts = <String>[
      if (_brightness != 0)
        l10n.generalImageEditorBrightnessSummary(_brightness),
      if (_contrast != 0) l10n.generalImageEditorContrastSummary(_contrast),
      if (_saturation != 0)
        l10n.generalImageEditorSaturationSummary(_saturation),
      if (_warmth != 0) l10n.generalImageEditorWarmthSummary(_warmth),
    ];
    return parts.isEmpty
        ? l10n.generalImageEditorNoColorAdjustment
        : parts.join(' · ');
  }

  String _effectSummary(AppLocalizations l10n) {
    final parts = <String>[
      if (_effect != ImageEditColorEffect.none) _effectLabel(l10n, _effect),
      if (_blurEnabled) l10n.generalImageEditorBlurSummary(_blurRadius),
      if (_sharpenEnabled)
        l10n.generalImageEditorSharpenSummary(_sharpenAmount),
      if (_transparentBackgroundEnabled)
        l10n.generalImageEditorTransparentBackgroundSummary,
      if (_pixelationEnabled)
        l10n.generalImageEditorPixelationSummary(_pixelationBlockSize),
    ];
    return parts.isEmpty ? l10n.generalImageEditorNoFilter : parts.join(' · ');
  }

  String _effectRegionSummary(AppLocalizations l10n) {
    if (!_effectRegionEnabled) {
      return l10n.generalImageEditorFullImageProcessing;
    }
    return '$_effectRegionLeftPercent,$_effectRegionTopPercent → '
        '$_effectRegionRightPercent,$_effectRegionBottomPercent%';
  }

  String _versionSummary(AppLocalizations l10n) {
    return _savedSnapshots.isEmpty
        ? l10n.generalImageEditorNoSavedVersionSummary
        : l10n.generalImageEditorSavedVersionCount(_savedSnapshots.length);
  }

  String _annotationSummary(AppLocalizations l10n) {
    if (_annotations.isEmpty) {
      return l10n.generalImageEditorNoAnnotationSummary;
    }
    return l10n.generalImageEditorAnnotationCount(_annotations.length);
  }

  String _outputSummary(AppLocalizations l10n) {
    if (_outputFormat == GeneralImageOutputFormat.jpeg) {
      return 'JPEG · $_jpegQuality%';
    }
    return l10n.generalImageEditorPngTransparentSummary;
  }
}

int _normalizedQuarterTurns(int quarterTurns) {
  return ((quarterTurns % 4) + 4) % 4;
}

class _GeneralImageEditorSnapshot {
  const _GeneralImageEditorSnapshot({
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
    required this.quarterTurns,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.resizeEnabled,
    required this.lockAspectRatio,
    required this.resizeWidth,
    required this.resizeHeight,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.effect,
    required this.effectRegionEnabled,
    required this.effectRegionLeftPercent,
    required this.effectRegionTopPercent,
    required this.effectRegionRightPercent,
    required this.effectRegionBottomPercent,
    required this.blurEnabled,
    required this.blurRadius,
    required this.sharpenEnabled,
    required this.sharpenAmount,
    required this.pixelationEnabled,
    required this.pixelationBlockSize,
    required this.transparentBackgroundEnabled,
    required this.transparentTolerance,
    required this.outputFormat,
    required this.jpegQuality,
    required this.annotations,
    required this.annotationKind,
    required this.annotationText,
    required this.annotationStartXPercent,
    required this.annotationStartYPercent,
    required this.annotationEndXPercent,
    required this.annotationEndYPercent,
    required this.annotationColorArgb,
    required this.annotationStrokeWidth,
    required this.annotationFilled,
    required this.annotationFontSize,
  });

  final int cropLeft;
  final int cropTop;
  final int cropRight;
  final int cropBottom;
  final int quarterTurns;
  final bool flipHorizontal;
  final bool flipVertical;
  final bool resizeEnabled;
  final bool lockAspectRatio;
  final int resizeWidth;
  final int resizeHeight;
  final int brightness;
  final int contrast;
  final int saturation;
  final int warmth;
  final ImageEditColorEffect effect;
  final bool effectRegionEnabled;
  final int effectRegionLeftPercent;
  final int effectRegionTopPercent;
  final int effectRegionRightPercent;
  final int effectRegionBottomPercent;
  final bool blurEnabled;
  final int blurRadius;
  final bool sharpenEnabled;
  final int sharpenAmount;
  final bool pixelationEnabled;
  final int pixelationBlockSize;
  final bool transparentBackgroundEnabled;
  final int transparentTolerance;
  final GeneralImageOutputFormat outputFormat;
  final int jpegQuality;
  final List<ImageAnnotation> annotations;
  final ImageAnnotationKind annotationKind;
  final String annotationText;
  final int annotationStartXPercent;
  final int annotationStartYPercent;
  final int annotationEndXPercent;
  final int annotationEndYPercent;
  final int annotationColorArgb;
  final int annotationStrokeWidth;
  final bool annotationFilled;
  final int annotationFontSize;

  @override
  bool operator ==(Object other) {
    return other is _GeneralImageEditorSnapshot &&
        cropLeft == other.cropLeft &&
        cropTop == other.cropTop &&
        cropRight == other.cropRight &&
        cropBottom == other.cropBottom &&
        quarterTurns == other.quarterTurns &&
        flipHorizontal == other.flipHorizontal &&
        flipVertical == other.flipVertical &&
        resizeEnabled == other.resizeEnabled &&
        lockAspectRatio == other.lockAspectRatio &&
        resizeWidth == other.resizeWidth &&
        resizeHeight == other.resizeHeight &&
        brightness == other.brightness &&
        contrast == other.contrast &&
        saturation == other.saturation &&
        warmth == other.warmth &&
        effect == other.effect &&
        effectRegionEnabled == other.effectRegionEnabled &&
        effectRegionLeftPercent == other.effectRegionLeftPercent &&
        effectRegionTopPercent == other.effectRegionTopPercent &&
        effectRegionRightPercent == other.effectRegionRightPercent &&
        effectRegionBottomPercent == other.effectRegionBottomPercent &&
        blurEnabled == other.blurEnabled &&
        blurRadius == other.blurRadius &&
        sharpenEnabled == other.sharpenEnabled &&
        sharpenAmount == other.sharpenAmount &&
        pixelationEnabled == other.pixelationEnabled &&
        pixelationBlockSize == other.pixelationBlockSize &&
        transparentBackgroundEnabled == other.transparentBackgroundEnabled &&
        transparentTolerance == other.transparentTolerance &&
        outputFormat == other.outputFormat &&
        jpegQuality == other.jpegQuality &&
        annotationKind == other.annotationKind &&
        annotationText == other.annotationText &&
        annotationStartXPercent == other.annotationStartXPercent &&
        annotationStartYPercent == other.annotationStartYPercent &&
        annotationEndXPercent == other.annotationEndXPercent &&
        annotationEndYPercent == other.annotationEndYPercent &&
        annotationColorArgb == other.annotationColorArgb &&
        annotationStrokeWidth == other.annotationStrokeWidth &&
        annotationFilled == other.annotationFilled &&
        annotationFontSize == other.annotationFontSize &&
        _sameAnnotations(annotations, other.annotations);
  }

  @override
  int get hashCode => Object.hashAll([
    cropLeft,
    cropTop,
    cropRight,
    cropBottom,
    quarterTurns,
    flipHorizontal,
    flipVertical,
    resizeEnabled,
    lockAspectRatio,
    resizeWidth,
    resizeHeight,
    brightness,
    contrast,
    saturation,
    warmth,
    effect,
    effectRegionEnabled,
    effectRegionLeftPercent,
    effectRegionTopPercent,
    effectRegionRightPercent,
    effectRegionBottomPercent,
    blurEnabled,
    blurRadius,
    sharpenEnabled,
    sharpenAmount,
    pixelationEnabled,
    pixelationBlockSize,
    transparentBackgroundEnabled,
    transparentTolerance,
    outputFormat,
    jpegQuality,
    annotationKind,
    annotationText,
    annotationStartXPercent,
    annotationStartYPercent,
    annotationEndXPercent,
    annotationEndYPercent,
    annotationColorArgb,
    annotationStrokeWidth,
    annotationFilled,
    annotationFontSize,
    for (final annotation in annotations) _annotationHash(annotation),
  ]);
}

class _GeneralImageEditorSavedSnapshot {
  const _GeneralImageEditorSavedSnapshot({
    required this.label,
    required this.summary,
    required this.snapshot,
  });

  final String label;
  final String summary;
  final _GeneralImageEditorSnapshot snapshot;
}

String _snapshotSummary(
  AppLocalizations l10n,
  _GeneralImageEditorSnapshot snapshot,
) {
  final parts = <String>[
    if (snapshot.resizeEnabled)
      '${snapshot.resizeWidth} x ${snapshot.resizeHeight}'
    else
      l10n.generalImageEditorSnapshotOriginalSize,
    switch (snapshot.outputFormat) {
      GeneralImageOutputFormat.png => 'PNG',
      GeneralImageOutputFormat.jpeg => 'JPEG ${snapshot.jpegQuality}%',
    },
    if (snapshot.effect != ImageEditColorEffect.none)
      _effectLabel(l10n, snapshot.effect),
    if (snapshot.blurEnabled)
      l10n.generalImageEditorBlurSummary(snapshot.blurRadius),
    if (snapshot.sharpenEnabled)
      l10n.generalImageEditorSharpenSummary(snapshot.sharpenAmount),
    if (snapshot.pixelationEnabled)
      l10n.generalImageEditorPixelationSummary(snapshot.pixelationBlockSize),
    if (snapshot.effectRegionEnabled)
      l10n.generalImageEditorSnapshotLocalRegion,
    if (snapshot.annotations.isNotEmpty)
      l10n.generalImageEditorSnapshotAnnotationCount(
        snapshot.annotations.length,
      ),
  ];
  return parts.join(' · ');
}

class _VersionSnapshotRow extends StatelessWidget {
  const _VersionSnapshotRow({
    required this.snapshot,
    required this.onRestore,
    required this.onDelete,
  });

  final _GeneralImageEditorSavedSnapshot snapshot;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(snapshot.label, style: theme.textTheme.labelLarge),
                Text(
                  snapshot.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.generalImageEditorRestoreVersionTooltip,
            onPressed: onRestore,
            icon: const Icon(Icons.restore_outlined),
          ),
          IconButton(
            tooltip: l10n.generalImageEditorDeleteVersionTooltip,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _AnnotationRow extends StatelessWidget {
  const _AnnotationRow({
    required this.annotation,
    required this.index,
    required this.onDelete,
  });

  final ImageAnnotation annotation;
  final int index;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    final color = Color(annotation.colorArgb);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Icon(
              _annotationIcon(annotation.kind),
              size: 16,
              color: color.computeLuminance() > 0.55
                  ? Colors.black
                  : Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${index + 1}. ${_annotationDescription(l10n, annotation)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: l10n.generalImageEditorDeleteAnnotationTooltip,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _AnnotationColorSwatch extends StatelessWidget {
  const _AnnotationColorSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = color.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        enabled: onTap != null,
        child: Opacity(
          opacity: onTap == null ? 0.52 : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, size: 18, color: foreground)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CropDragMode {
  none,
  move,
  left,
  top,
  right,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class _EditableImagePreview extends StatefulWidget {
  const _EditableImagePreview({
    required this.imagePath,
    required this.imageInfo,
    required this.displayInfo,
    required this.crop,
    required this.quarterTurns,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.effectRegion,
    required this.annotations,
    required this.onCropChanged,
    required this.onEffectRegionChanged,
    required this.onAnnotationDeleted,
    super.key,
  });

  final String imagePath;
  final ImageInspectionResult imageInfo;
  final ImageInspectionResult displayInfo;
  final ImageCropMargins crop;
  final int quarterTurns;
  final bool flipHorizontal;
  final bool flipVertical;
  final ImageEffectRegion effectRegion;
  final List<ImageAnnotation> annotations;
  final ValueChanged<ImageCropMargins> onCropChanged;
  final ValueChanged<ImageEffectRegion> onEffectRegionChanged;
  final ValueChanged<int> onAnnotationDeleted;

  @override
  State<_EditableImagePreview> createState() => _EditableImagePreviewState();
}

class _EditableImagePreviewState extends State<_EditableImagePreview> {
  static const double _handleHitRadius = 18;
  static const int _minCropSize = 1;

  _CropDragMode _dragMode = _CropDragMode.none;
  bool _draggingEffectRegion = false;
  int? _selectedAnnotationIndex;

  @override
  void didUpdateWidget(covariant _EditableImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selectedAnnotationIndex;
    if (selected != null && selected >= widget.annotations.length) {
      _selectedAnnotationIndex = null;
    }
    if (!widget.effectRegion.enabled) {
      _draggingEffectRegion = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = Size(constraints.maxWidth, constraints.maxHeight);
        final imageRect = _containedImageRect(bounds, widget.displayInfo);
        final cropRect = _cropDisplayRect(imageRect);
        final effectRegionRect = widget.effectRegion.enabled
            ? _effectRegionDisplayRect(imageRect)
            : null;
        final selectedIndex = _selectedAnnotationIndex;
        final selectedBounds =
            selectedIndex == null || selectedIndex >= widget.annotations.length
            ? null
            : _annotationDisplayBounds(
                widget.annotations[selectedIndex],
                imageRect,
              );

        return Semantics(
          label: l10n.generalImageEditorPreviewFooter(
            fileNameFromPath(widget.imagePath),
          ),
          image: true,
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: imageRect,
                child: _TransformedPreviewImage(
                  imagePath: widget.imagePath,
                  quarterTurns: widget.quarterTurns,
                  flipHorizontal: widget.flipHorizontal,
                  flipVertical: widget.flipVertical,
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) =>
                      _selectAnnotation(details.localPosition, imageRect),
                  onPanStart: (details) => _startPreviewDrag(
                    details.localPosition,
                    cropRect,
                    effectRegionRect,
                  ),
                  onPanUpdate: (details) =>
                      _updatePreviewDrag(details.delta, imageRect),
                  onPanEnd: (_) => _endPreviewDrag(),
                  onPanCancel: _endPreviewDrag,
                  child: CustomPaint(
                    painter: _EditableImagePreviewPainter(
                      imageRect: imageRect,
                      cropRect: cropRect,
                      effectRegionRect: effectRegionRect,
                      annotations: widget.annotations,
                      selectedAnnotationIndex: selectedIndex,
                      primaryColor: theme.colorScheme.primary,
                      outlineColor: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
              if (selectedIndex != null && selectedBounds != null)
                Positioned(
                  left: (selectedBounds.right + 6)
                      .clamp(0, math.max(0, bounds.width - 40))
                      .toDouble(),
                  top: (selectedBounds.top - 6)
                      .clamp(0, math.max(0, bounds.height - 40))
                      .toDouble(),
                  child: IconButton.filledTonal(
                    key: const ValueKey('delete-selected-annotation'),
                    tooltip:
                        l10n.generalImageEditorDeleteSelectedAnnotationTooltip,
                    onPressed: () {
                      widget.onAnnotationDeleted(selectedIndex);
                      setState(() => _selectedAnnotationIndex = null);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Rect _cropDisplayRect(Rect imageRect) {
    final cropWidth =
        widget.imageInfo.width - widget.crop.left - widget.crop.right;
    final cropHeight =
        widget.imageInfo.height - widget.crop.top - widget.crop.bottom;
    final displayWidth = widget.displayInfo.width;
    final displayHeight = widget.displayInfo.height;
    final sourceWidth = cropWidth <= 0 ? widget.imageInfo.width : cropWidth;
    final sourceHeight = cropHeight <= 0 ? widget.imageInfo.height : cropHeight;
    final rotated = _normalizedQuarterTurns(widget.quarterTurns).isOdd;
    final transformedWidth = rotated ? sourceHeight : sourceWidth;
    final transformedHeight = rotated ? sourceWidth : sourceHeight;
    final widthScale = imageRect.width / math.max(1, displayWidth);
    final heightScale = imageRect.height / math.max(1, displayHeight);
    final renderedWidth = transformedWidth * widthScale;
    final renderedHeight = transformedHeight * heightScale;

    return Rect.fromLTWH(
      imageRect.left + (imageRect.width - renderedWidth) / 2,
      imageRect.top + (imageRect.height - renderedHeight) / 2,
      math.max(1, renderedWidth),
      math.max(1, renderedHeight),
    );
  }

  Rect _sourceCropDisplayRect(Rect imageRect) {
    final scale = imageRect.width / widget.imageInfo.width;
    final left = imageRect.left + widget.crop.left * scale;
    final top = imageRect.top + widget.crop.top * scale;
    final right = imageRect.right - widget.crop.right * scale;
    final bottom = imageRect.bottom - widget.crop.bottom * scale;
    return Rect.fromLTRB(
      math.min(left, right - 1),
      math.min(top, bottom - 1),
      math.max(right, left + 1),
      math.max(bottom, top + 1),
    );
  }

  Rect _effectRegionDisplayRect(Rect imageRect) {
    final leftRatio = math
        .min(widget.effectRegion.leftRatio, widget.effectRegion.rightRatio)
        .clamp(0, 1)
        .toDouble();
    final rightRatio = math
        .max(widget.effectRegion.leftRatio, widget.effectRegion.rightRatio)
        .clamp(0, 1)
        .toDouble();
    final topRatio = math
        .min(widget.effectRegion.topRatio, widget.effectRegion.bottomRatio)
        .clamp(0, 1)
        .toDouble();
    final bottomRatio = math
        .max(widget.effectRegion.topRatio, widget.effectRegion.bottomRatio)
        .clamp(0, 1)
        .toDouble();
    return Rect.fromLTRB(
      imageRect.left + imageRect.width * leftRatio,
      imageRect.top + imageRect.height * topRatio,
      imageRect.left + imageRect.width * rightRatio,
      imageRect.top + imageRect.height * bottomRatio,
    );
  }

  void _selectAnnotation(Offset position, Rect imageRect) {
    for (var index = widget.annotations.length - 1; index >= 0; index--) {
      final bounds = _annotationDisplayBounds(
        widget.annotations[index],
        imageRect,
      ).inflate(14);
      if (bounds.contains(position)) {
        setState(() => _selectedAnnotationIndex = index);
        return;
      }
    }
    setState(() => _selectedAnnotationIndex = null);
  }

  void _startPreviewDrag(
    Offset position,
    Rect cropRect,
    Rect? effectRegionRect,
  ) {
    _dragMode = _CropDragMode.none;
    _draggingEffectRegion = false;

    if (effectRegionRect != null) {
      final regionMode = _cropDragModeFor(position, effectRegionRect);
      if (regionMode != _CropDragMode.none) {
        _dragMode = regionMode;
        _draggingEffectRegion = true;
        return;
      }
    }

    _dragMode = _cropDragModeFor(position, cropRect);
  }

  void _updatePreviewDrag(Offset displayDelta, Rect imageRect) {
    if (_draggingEffectRegion) {
      _updateEffectRegionDrag(displayDelta, imageRect);
      return;
    }
    _updateCropDrag(displayDelta, _sourceCropDisplayRect(imageRect));
  }

  void _endPreviewDrag() {
    _dragMode = _CropDragMode.none;
    _draggingEffectRegion = false;
  }

  void _updateCropDrag(Offset displayDelta, Rect imageRect) {
    if (_dragMode == _CropDragMode.none || imageRect.width <= 0) {
      return;
    }

    final scale = imageRect.width / widget.imageInfo.width;
    if (scale <= 0) {
      return;
    }

    final dx = (displayDelta.dx / scale).round();
    final dy = (displayDelta.dy / scale).round();
    if (dx == 0 && dy == 0) {
      return;
    }

    final width = widget.imageInfo.width;
    final height = widget.imageInfo.height;
    var left = widget.crop.left;
    var top = widget.crop.top;
    var right = widget.crop.right;
    var bottom = widget.crop.bottom;

    switch (_dragMode) {
      case _CropDragMode.none:
        return;
      case _CropDragMode.move:
        final cropWidth = width - left - right;
        final cropHeight = height - top - bottom;
        left = (left + dx).clamp(0, width - cropWidth).toInt();
        right = width - cropWidth - left;
        top = (top + dy).clamp(0, height - cropHeight).toInt();
        bottom = height - cropHeight - top;
      case _CropDragMode.left:
        left += dx;
      case _CropDragMode.top:
        top += dy;
      case _CropDragMode.right:
        right -= dx;
      case _CropDragMode.bottom:
        bottom -= dy;
      case _CropDragMode.topLeft:
        left += dx;
        top += dy;
      case _CropDragMode.topRight:
        right -= dx;
        top += dy;
      case _CropDragMode.bottomLeft:
        left += dx;
        bottom -= dy;
      case _CropDragMode.bottomRight:
        right -= dx;
        bottom -= dy;
    }

    widget.onCropChanged(
      _normalizedCropMargins(
        width: width,
        height: height,
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      ),
    );
  }

  void _updateEffectRegionDrag(Offset displayDelta, Rect imageRect) {
    if (_dragMode == _CropDragMode.none ||
        imageRect.width <= 0 ||
        imageRect.height <= 0) {
      return;
    }

    final dx = displayDelta.dx / imageRect.width;
    final dy = displayDelta.dy / imageRect.height;
    if (dx == 0 && dy == 0) {
      return;
    }

    var left = math
        .min(widget.effectRegion.leftRatio, widget.effectRegion.rightRatio)
        .clamp(0.0, 1.0)
        .toDouble();
    var right = math
        .max(widget.effectRegion.leftRatio, widget.effectRegion.rightRatio)
        .clamp(0.0, 1.0)
        .toDouble();
    var top = math
        .min(widget.effectRegion.topRatio, widget.effectRegion.bottomRatio)
        .clamp(0.0, 1.0)
        .toDouble();
    var bottom = math
        .max(widget.effectRegion.topRatio, widget.effectRegion.bottomRatio)
        .clamp(0.0, 1.0)
        .toDouble();
    const minSize = 0.01;

    switch (_dragMode) {
      case _CropDragMode.none:
        return;
      case _CropDragMode.move:
        final regionWidth = right - left;
        final regionHeight = bottom - top;
        left = (left + dx).clamp(0.0, 1.0 - regionWidth).toDouble();
        right = left + regionWidth;
        top = (top + dy).clamp(0.0, 1.0 - regionHeight).toDouble();
        bottom = top + regionHeight;
      case _CropDragMode.left:
        left = (left + dx).clamp(0.0, right - minSize).toDouble();
      case _CropDragMode.top:
        top = (top + dy).clamp(0.0, bottom - minSize).toDouble();
      case _CropDragMode.right:
        right = (right + dx).clamp(left + minSize, 1.0).toDouble();
      case _CropDragMode.bottom:
        bottom = (bottom + dy).clamp(top + minSize, 1.0).toDouble();
      case _CropDragMode.topLeft:
        left = (left + dx).clamp(0.0, right - minSize).toDouble();
        top = (top + dy).clamp(0.0, bottom - minSize).toDouble();
      case _CropDragMode.topRight:
        right = (right + dx).clamp(left + minSize, 1.0).toDouble();
        top = (top + dy).clamp(0.0, bottom - minSize).toDouble();
      case _CropDragMode.bottomLeft:
        left = (left + dx).clamp(0.0, right - minSize).toDouble();
        bottom = (bottom + dy).clamp(top + minSize, 1.0).toDouble();
      case _CropDragMode.bottomRight:
        right = (right + dx).clamp(left + minSize, 1.0).toDouble();
        bottom = (bottom + dy).clamp(top + minSize, 1.0).toDouble();
    }

    widget.onEffectRegionChanged(
      ImageEffectRegion(
        enabled: true,
        leftRatio: left,
        topRatio: top,
        rightRatio: right,
        bottomRatio: bottom,
      ),
    );
  }

  _CropDragMode _cropDragModeFor(Offset position, Rect rect) {
    if (rect == Rect.zero) {
      return _CropDragMode.none;
    }

    final nearLeft = (position.dx - rect.left).abs() <= _handleHitRadius;
    final nearTop = (position.dy - rect.top).abs() <= _handleHitRadius;
    final nearRight = (position.dx - rect.right).abs() <= _handleHitRadius;
    final nearBottom = (position.dy - rect.bottom).abs() <= _handleHitRadius;
    final nearHorizontal =
        position.dx >= rect.left - _handleHitRadius &&
        position.dx <= rect.right + _handleHitRadius;
    final nearVertical =
        position.dy >= rect.top - _handleHitRadius &&
        position.dy <= rect.bottom + _handleHitRadius;

    if (nearLeft && nearTop) {
      return _CropDragMode.topLeft;
    }
    if (nearRight && nearTop) {
      return _CropDragMode.topRight;
    }
    if (nearLeft && nearBottom) {
      return _CropDragMode.bottomLeft;
    }
    if (nearRight && nearBottom) {
      return _CropDragMode.bottomRight;
    }
    if (nearLeft && nearVertical) {
      return _CropDragMode.left;
    }
    if (nearRight && nearVertical) {
      return _CropDragMode.right;
    }
    if (nearTop && nearHorizontal) {
      return _CropDragMode.top;
    }
    if (nearBottom && nearHorizontal) {
      return _CropDragMode.bottom;
    }
    return rect.contains(position) ? _CropDragMode.move : _CropDragMode.none;
  }

  ImageCropMargins _normalizedCropMargins({
    required int width,
    required int height,
    required int left,
    required int top,
    required int right,
    required int bottom,
  }) {
    final safeLeft = left.clamp(0, width - _minCropSize).toInt();
    final safeRight = right.clamp(0, width - safeLeft - _minCropSize).toInt();
    final safeTop = top.clamp(0, height - _minCropSize).toInt();
    final safeBottom = bottom.clamp(0, height - safeTop - _minCropSize).toInt();

    return ImageCropMargins(
      left: safeLeft,
      top: safeTop,
      right: safeRight,
      bottom: safeBottom,
    );
  }
}

class _TransformedPreviewImage extends StatelessWidget {
  const _TransformedPreviewImage({
    required this.imagePath,
    required this.quarterTurns,
    required this.flipHorizontal,
    required this.flipVertical,
  });

  final String imagePath;
  final int quarterTurns;
  final bool flipHorizontal;
  final bool flipVertical;

  @override
  Widget build(BuildContext context) {
    final turns = _normalizedQuarterTurns(quarterTurns);
    final l10n = appL10nOf(context);

    return ClipRect(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scaleByDouble(
            flipHorizontal ? -1.0 : 1.0,
            flipVertical ? -1.0 : 1.0,
            1,
            1,
          ),
        child: RotatedBox(
          quarterTurns: turns,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.fill,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) =>
                Center(child: Text(l10n.generalImageEditorImageLoadFailed)),
          ),
        ),
      ),
    );
  }
}

class _EditableImagePreviewPainter extends CustomPainter {
  const _EditableImagePreviewPainter({
    required this.imageRect,
    required this.cropRect,
    required this.effectRegionRect,
    required this.annotations,
    required this.selectedAnnotationIndex,
    required this.primaryColor,
    required this.outlineColor,
  });

  final Rect imageRect;
  final Rect cropRect;
  final Rect? effectRegionRect;
  final List<ImageAnnotation> annotations;
  final int? selectedAnnotationIndex;
  final Color primaryColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintCropOverlay(canvas);
    _paintEffectRegion(canvas);
    _paintAnnotations(canvas);
  }

  void _paintCropOverlay(Canvas canvas) {
    final shade = Paint()..color = Colors.black.withValues(alpha: 0.38);
    canvas
      ..drawRect(
        Rect.fromLTRB(
          imageRect.left,
          imageRect.top,
          imageRect.right,
          cropRect.top,
        ),
        shade,
      )
      ..drawRect(
        Rect.fromLTRB(
          imageRect.left,
          cropRect.bottom,
          imageRect.right,
          imageRect.bottom,
        ),
        shade,
      )
      ..drawRect(
        Rect.fromLTRB(
          imageRect.left,
          cropRect.top,
          cropRect.left,
          cropRect.bottom,
        ),
        shade,
      )
      ..drawRect(
        Rect.fromLTRB(
          cropRect.right,
          cropRect.top,
          imageRect.right,
          cropRect.bottom,
        ),
        shade,
      );

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = primaryColor;
    canvas
      ..drawRect(cropRect, border)
      ..drawRect(cropRect.deflate(2), accent);

    final handlePaint = Paint()..color = primaryColor;
    for (final center in _cropHandleCenters(cropRect)) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 11, height: 11),
          const Radius.circular(3),
        ),
        handlePaint,
      );
    }
  }

  void _paintEffectRegion(Canvas canvas) {
    final rect = effectRegionRect;
    if (rect == null || rect.width <= 0 || rect.height <= 0) {
      return;
    }

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.orange.withValues(alpha: 0.14);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.orangeAccent;
    canvas
      ..drawRect(rect, fill)
      ..drawRect(rect, border);

    final handlePaint = Paint()..color = Colors.orangeAccent;
    for (final center in _cropHandleCenters(rect)) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 11, height: 11),
          const Radius.circular(3),
        ),
        handlePaint,
      );
    }
  }

  void _paintAnnotations(Canvas canvas) {
    for (var index = 0; index < annotations.length; index++) {
      final annotation = annotations[index];
      final selected = selectedAnnotationIndex == index;
      final color = Color(annotation.colorArgb);
      final strokeWidth = math.max(
        2.0,
        annotation.strokeWidth * imageRect.width / 360,
      );
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? strokeWidth + 2 : strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = selected ? Colors.white : color;
      final accent = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color;
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: annotation.filled ? 0.36 : 0.12);
      final start = _annotationPoint(annotation, imageRect, start: true);
      final end = _annotationPoint(annotation, imageRect, start: false);

      switch (annotation.kind) {
        case ImageAnnotationKind.text:
          _paintAnnotationText(canvas, annotation, start, color, selected);
        case ImageAnnotationKind.rectangle:
          final rect = Rect.fromPoints(start, end);
          if (annotation.filled) {
            canvas.drawRect(rect, fill);
          }
          if (selected) {
            canvas.drawRect(rect, stroke);
          }
          canvas.drawRect(rect, accent);
        case ImageAnnotationKind.ellipse:
          final rect = Rect.fromPoints(start, end);
          if (annotation.filled) {
            canvas.drawOval(rect, fill);
          }
          if (selected) {
            canvas.drawOval(rect, stroke);
          }
          canvas.drawOval(rect, accent);
        case ImageAnnotationKind.line:
          if (selected) {
            canvas.drawLine(start, end, stroke);
          }
          canvas.drawLine(start, end, accent);
        case ImageAnnotationKind.arrow:
          if (selected) {
            _paintArrow(canvas, start, end, stroke);
          }
          _paintArrow(canvas, start, end, accent);
      }
    }
  }

  void _paintAnnotationText(
    Canvas canvas,
    ImageAnnotation annotation,
    Offset start,
    Color color,
    bool selected,
  ) {
    final fontSize = math
        .max(12.0, annotation.fontSize * imageRect.width / 480)
        .clamp(12.0, 48.0);
    final painter = TextPainter(
      text: TextSpan(
        text: annotation.text.trim(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: imageRect.width);

    if (selected) {
      final background = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          start.dx - 4,
          start.dy - 3,
          painter.width + 8,
          painter.height + 6,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        background,
        Paint()..color = Colors.black.withValues(alpha: 0.46),
      );
      canvas.drawRRect(
        background,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
    }

    painter.paint(canvas, start);
  }

  void _paintArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final delta = end - start;
    if (delta.distance == 0) {
      return;
    }

    final angle = math.atan2(delta.dy, delta.dx);
    final length = math.max(10.0, paint.strokeWidth * 4.2);
    const headAngle = math.pi / 7;
    final first = Offset(
      end.dx - math.cos(angle - headAngle) * length,
      end.dy - math.sin(angle - headAngle) * length,
    );
    final second = Offset(
      end.dx - math.cos(angle + headAngle) * length,
      end.dy - math.sin(angle + headAngle) * length,
    );
    canvas
      ..drawLine(end, first, paint)
      ..drawLine(end, second, paint);
  }

  @override
  bool shouldRepaint(covariant _EditableImagePreviewPainter oldDelegate) {
    return imageRect != oldDelegate.imageRect ||
        cropRect != oldDelegate.cropRect ||
        effectRegionRect != oldDelegate.effectRegionRect ||
        annotations != oldDelegate.annotations ||
        selectedAnnotationIndex != oldDelegate.selectedAnnotationIndex ||
        primaryColor != oldDelegate.primaryColor ||
        outlineColor != oldDelegate.outlineColor;
  }
}

class _BoundedHeightScrollView extends StatelessWidget {
  const _BoundedHeightScrollView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) {
          return child;
        }

        return Scrollbar(child: SingleChildScrollView(child: child));
      },
    );
  }
}

enum _GeneralImageEditorPreset {
  transparentPng,
  socialJpeg,
  sharpJpeg,
  pixelPng,
}

class _PresetActionChip extends StatelessWidget {
  const _PresetActionChip({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: enabled ? onPressed : null,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _EditorControlGroup extends StatelessWidget {
  const _EditorControlGroup({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EditorPanelChoiceChip extends StatelessWidget {
  const _EditorPanelChoiceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = selected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final borderColor = selected
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return SizedBox(
      height: 36,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: selected ? null : onSelected,
          borderRadius: BorderRadius.circular(8),
          hoverColor: colorScheme.primary.withValues(alpha: 0.08),
          focusColor: colorScheme.primary.withValues(alpha: 0.10),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          splashColor: colorScheme.primary.withValues(alpha: 0.10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: foregroundColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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

class _EditorExpansionSection extends StatelessWidget {
  const _EditorExpansionSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            maintainState: true,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: Icon(icon, size: 18, color: theme.colorScheme.primary),
            title: Text(title, style: theme.textTheme.titleSmall),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            children: [child],
          ),
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: '$value',
            onChanged: enabled ? (next) => onChanged(next.round()) : null,
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ImagePreviewSurface extends StatelessWidget {
  const _ImagePreviewSurface({required this.child, required this.footer});

  final Widget child;
  final String footer;

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
      child: Column(
        children: [
          SizedBox(
            height: 560,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
                child: child,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            footer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _annotationKindLabel(AppLocalizations l10n, ImageAnnotationKind kind) {
  return switch (kind) {
    ImageAnnotationKind.text => l10n.generalImageEditorAnnotationKindText,
    ImageAnnotationKind.rectangle =>
      l10n.generalImageEditorAnnotationKindRectangle,
    ImageAnnotationKind.ellipse => l10n.generalImageEditorAnnotationKindEllipse,
    ImageAnnotationKind.line => l10n.generalImageEditorAnnotationKindLine,
    ImageAnnotationKind.arrow => l10n.generalImageEditorAnnotationKindArrow,
  };
}

String _annotationColorLabel(AppLocalizations l10n, int argb) {
  return switch (argb) {
    0xFFFF3B30 => l10n.generalImageEditorColorRed,
    0xFFFFD400 => l10n.generalImageEditorColorYellow,
    0xFF34C759 => l10n.generalImageEditorColorGreen,
    0xFF007AFF => l10n.generalImageEditorColorBlue,
    0xFF111111 => l10n.generalImageEditorColorBlack,
    0xFFFFFFFF => l10n.generalImageEditorColorWhite,
    _ => l10n.generalImageEditorColorCustom,
  };
}

String _annotationDescription(
  AppLocalizations l10n,
  ImageAnnotation annotation,
) {
  final startX = (annotation.startXRatio * 100).round();
  final startY = (annotation.startYRatio * 100).round();
  final endX = (annotation.endXRatio * 100).round();
  final endY = (annotation.endYRatio * 100).round();
  final label = _annotationKindLabel(l10n, annotation.kind);
  if (annotation.kind == ImageAnnotationKind.text) {
    return '$label · ${annotation.text.trim()} · $startX%, $startY%';
  }
  final filled = annotation.filled
      ? ' · ${l10n.generalImageEditorAnnotationFilledSuffix}'
      : '';
  return '$label · $startX%, $startY% → $endX%, $endY%$filled';
}

IconData _annotationIcon(ImageAnnotationKind kind) {
  return switch (kind) {
    ImageAnnotationKind.text => Icons.text_fields,
    ImageAnnotationKind.rectangle => Icons.crop_square_outlined,
    ImageAnnotationKind.ellipse => Icons.circle_outlined,
    ImageAnnotationKind.line => Icons.show_chart_outlined,
    ImageAnnotationKind.arrow => Icons.arrow_forward,
  };
}

bool _annotationSupportsFill(ImageAnnotationKind kind) {
  return kind == ImageAnnotationKind.rectangle ||
      kind == ImageAnnotationKind.ellipse;
}

bool _sameAnnotations(
  List<ImageAnnotation> first,
  List<ImageAnnotation> second,
) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (!_sameAnnotation(first[index], second[index])) {
      return false;
    }
  }
  return true;
}

bool _sameAnnotation(ImageAnnotation first, ImageAnnotation second) {
  return first.kind == second.kind &&
      first.text == second.text &&
      first.startXRatio == second.startXRatio &&
      first.startYRatio == second.startYRatio &&
      first.endXRatio == second.endXRatio &&
      first.endYRatio == second.endYRatio &&
      first.colorArgb == second.colorArgb &&
      first.strokeWidth == second.strokeWidth &&
      first.filled == second.filled &&
      first.fontSize == second.fontSize;
}

int _annotationHash(ImageAnnotation annotation) {
  return Object.hash(
    annotation.kind,
    annotation.text,
    annotation.startXRatio,
    annotation.startYRatio,
    annotation.endXRatio,
    annotation.endYRatio,
    annotation.colorArgb,
    annotation.strokeWidth,
    annotation.filled,
    annotation.fontSize,
  );
}

String _outputFormatLabel(GeneralImageOutputFormat format) {
  return switch (format) {
    GeneralImageOutputFormat.png => 'PNG',
    GeneralImageOutputFormat.jpeg => 'JPEG',
  };
}

Rect _containedImageRect(Size bounds, ImageInspectionResult imageInfo) {
  if (bounds.width <= 0 || bounds.height <= 0) {
    return Rect.zero;
  }

  final widthScale = bounds.width / imageInfo.width;
  final heightScale = bounds.height / imageInfo.height;
  final scale = math.min(widthScale, heightScale);
  final width = imageInfo.width * scale;
  final height = imageInfo.height * scale;
  return Rect.fromLTWH(
    (bounds.width - width) / 2,
    (bounds.height - height) / 2,
    width,
    height,
  );
}

List<Offset> _cropHandleCenters(Rect rect) {
  return [
    rect.topLeft,
    rect.topCenter,
    rect.topRight,
    rect.centerLeft,
    rect.centerRight,
    rect.bottomLeft,
    rect.bottomCenter,
    rect.bottomRight,
  ];
}

Offset _annotationPoint(
  ImageAnnotation annotation,
  Rect imageRect, {
  required bool start,
}) {
  final xRatio = start ? annotation.startXRatio : annotation.endXRatio;
  final yRatio = start ? annotation.startYRatio : annotation.endYRatio;
  return Offset(
    imageRect.left + imageRect.width * xRatio.clamp(0, 1),
    imageRect.top + imageRect.height * yRatio.clamp(0, 1),
  );
}

Rect _annotationDisplayBounds(ImageAnnotation annotation, Rect imageRect) {
  final start = _annotationPoint(annotation, imageRect, start: true);
  final end = _annotationPoint(annotation, imageRect, start: false);

  if (annotation.kind == ImageAnnotationKind.text) {
    final fontSize = math
        .max(12.0, annotation.fontSize * imageRect.width / 480)
        .clamp(12.0, 48.0);
    final width = math.max(
      48.0,
      annotation.text.trim().length * fontSize * 0.62,
    );
    return Rect.fromLTWH(start.dx, start.dy, width, fontSize * 1.3);
  }

  return Rect.fromPoints(start, end);
}

String _effectLabel(AppLocalizations l10n, ImageEditColorEffect effect) {
  return switch (effect) {
    ImageEditColorEffect.none => l10n.generalImageEditorEffectOriginal,
    ImageEditColorEffect.grayscale => l10n.generalImageEditorEffectGrayscale,
    ImageEditColorEffect.sepia => l10n.generalImageEditorEffectSepia,
    ImageEditColorEffect.invert => l10n.generalImageEditorEffectInvert,
  };
}

class PixelationDefaults {
  const PixelationDefaults._();

  static const int minBlockSize = 2;
  static const int maxBlockSize = 128;
}
