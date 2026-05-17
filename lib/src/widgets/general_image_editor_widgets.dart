import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';

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

class _GeneralImageEditorContentState extends State<GeneralImageEditorContent> {
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

  @override
  void initState() {
    super.initState();
    _annotationTextController = TextEditingController(text: 'Label');
    _syncResizeWithImageInfo();
  }

  @override
  void dispose() {
    _annotationTextController.dispose();
    super.dispose();
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
    return ResponsiveWorkspaceSplit(
      storageKey: 'general_image_editor',
      controlsWidth: 432,
      minControlsWidth: 320,
      maxControlsWidth: 560,
      controls: _buildControls(context),
      preview: _buildPreview(context),
    );
  }

  Widget _buildControls(BuildContext context) {
    final hasImage = widget.imagePath != null && widget.imageInfo != null;
    final info = widget.imageInfo;

    return _BoundedHeightScrollView(
      child: AppPanel(
        title: '通用图片编辑',
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
              title: '待编辑图片',
              pickLabel: widget.imagePath == null ? '选择' : '更换',
              clearTooltip: '清除图片',
              previewHeight: 132,
              onPick: widget.onPickImage,
              onClear: widget.imagePath == null ? null : widget.onClearImage,
            ),
            const SizedBox(height: fieldGap),
            _EditorControlGroup(
              icon: Icons.auto_awesome_outlined,
              title: '快捷处理',
              subtitle: '常用导出风格与版本快照',
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
            _buildControlPanelTabs(),
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
            _buildActionBar(hasImage),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanelTabs() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _EditorPanelChoiceChip(
          icon: Icons.crop_rotate_outlined,
          label: '几何',
          selected: _activePanel == _GeneralImageEditorPanel.geometry,
          onSelected: () =>
              setState(() => _activePanel = _GeneralImageEditorPanel.geometry),
        ),
        _EditorPanelChoiceChip(
          icon: Icons.palette_outlined,
          label: '外观',
          selected: _activePanel == _GeneralImageEditorPanel.appearance,
          onSelected: () => setState(
            () => _activePanel = _GeneralImageEditorPanel.appearance,
          ),
        ),
        _EditorPanelChoiceChip(
          icon: Icons.edit_note_outlined,
          label: '标注',
          selected: _activePanel == _GeneralImageEditorPanel.annotation,
          onSelected: () => setState(
            () => _activePanel = _GeneralImageEditorPanel.annotation,
          ),
        ),
        _EditorPanelChoiceChip(
          icon: Icons.file_download_outlined,
          label: '输出',
          selected: _activePanel == _GeneralImageEditorPanel.output,
          onSelected: () =>
              setState(() => _activePanel = _GeneralImageEditorPanel.output),
        ),
      ],
    );
  }

  Widget _buildActiveControlPanel(bool hasImage) {
    return switch (_activePanel) {
      _GeneralImageEditorPanel.geometry => _EditorControlGroup(
        icon: Icons.crop_rotate_outlined,
        title: '几何调整',
        subtitle: '旋转、翻转、裁剪和输出尺寸',
        child: Column(
          children: [
            _buildTransformSection(hasImage),
            const SizedBox(height: fieldGap),
            _buildCropSection(hasImage),
            const SizedBox(height: fieldGap),
            _buildResizeSection(hasImage),
          ],
        ),
      ),
      _GeneralImageEditorPanel.appearance => _EditorControlGroup(
        icon: Icons.palette_outlined,
        title: '外观处理',
        subtitle: '色彩、滤镜、锐化、透明与局部选区',
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
        title: '标注',
        subtitle: '文字、形状、箭头与标记位置',
        child: _buildAnnotationSection(hasImage),
      ),
      _GeneralImageEditorPanel.output => _EditorControlGroup(
        icon: Icons.file_download_outlined,
        title: '输出',
        subtitle: '保存格式、质量和最终预览',
        child: _buildOutputSection(hasImage),
      ),
    };
  }

  Widget _buildActionBar(bool hasImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsivePair(
          first: OutlinedButton.icon(
            onPressed: hasImage && _undoStack.isNotEmpty ? _undoEdit : null,
            icon: const Icon(Icons.undo),
            label: const Text('撤销'),
          ),
          second: OutlinedButton.icon(
            onPressed: hasImage && _redoStack.isNotEmpty ? _redoEdit : null,
            icon: const Icon(Icons.redo),
            label: const Text('重做'),
          ),
        ),
        const SizedBox(height: fieldGap),
        ResponsivePair(
          first: OutlinedButton.icon(
            onPressed: hasImage && !widget.isProcessing
                ? _refreshPreview
                : null,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('生成完整预览'),
          ),
          second: OutlinedButton.icon(
            onPressed: !widget.isProcessing ? _resetOptions : null,
            icon: const Icon(Icons.restart_alt),
            label: const Text('重置参数'),
          ),
        ),
        const SizedBox(height: fieldGap),
        PrimaryActionButton(
          onPressed: hasImage && !widget.isProcessing
              ? () => widget.onApplyEdit(_currentOptions())
              : null,
          icon: Icons.save_alt_outlined,
          label: '应用并保存',
          busyLabel: '处理中',
          isBusy: widget.isProcessing,
        ),
      ],
    );
  }

  Widget _buildPresetSection(bool enabled) {
    return _EditorExpansionSection(
      icon: Icons.auto_awesome_outlined,
      title: '预设',
      subtitle: '透明 / 社媒 / 清晰 / 像素风',
      initiallyExpanded: enabled,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PresetActionChip(
            icon: Icons.layers_clear_outlined,
            label: '透明 PNG',
            enabled: enabled,
            onPressed: () =>
                _applyPreset(_GeneralImageEditorPreset.transparentPng),
          ),
          _PresetActionChip(
            icon: Icons.public_outlined,
            label: '社媒 JPEG',
            enabled: enabled,
            onPressed: () => _applyPreset(_GeneralImageEditorPreset.socialJpeg),
          ),
          _PresetActionChip(
            icon: Icons.hdr_strong_outlined,
            label: '清晰 JPEG',
            enabled: enabled,
            onPressed: () => _applyPreset(_GeneralImageEditorPreset.sharpJpeg),
          ),
          _PresetActionChip(
            icon: Icons.grid_on_outlined,
            label: '像素风 PNG',
            enabled: enabled,
            onPressed: () => _applyPreset(_GeneralImageEditorPreset.pixelPng),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionSection(bool enabled) {
    return _EditorExpansionSection(
      icon: Icons.history_edu_outlined,
      title: '版本',
      subtitle: _versionSummary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: enabled ? _saveCurrentVersion : null,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('保存当前版本'),
          ),
          if (_savedSnapshots.isEmpty) ...[
            const SizedBox(height: fieldGap),
            Text('暂无保存的版本', style: Theme.of(context).textTheme.bodySmall),
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

  Widget _buildTransformSection(bool enabled) {
    return _EditorExpansionSection(
      icon: Icons.transform_outlined,
      title: '变换',
      subtitle: _transformSummary,
      initiallyExpanded: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsivePair(
            first: OutlinedButton.icon(
              onPressed: enabled ? () => _rotateBy(-1) : null,
              icon: const Icon(Icons.rotate_left_outlined),
              label: const Text('左转 90°'),
            ),
            second: OutlinedButton.icon(
              onPressed: enabled ? () => _rotateBy(1) : null,
              icon: const Icon(Icons.rotate_right_outlined),
              label: const Text('右转 90°'),
            ),
          ),
          const SizedBox(height: 8),
          ResponsivePair(
            first: FilterChip(
              selected: _flipHorizontal,
              onSelected: enabled
                  ? (value) =>
                        _commitOptionChange(() => _flipHorizontal = value)
                  : null,
              avatar: const Icon(Icons.swap_horiz_outlined),
              label: const Text('水平翻转'),
            ),
            second: FilterChip(
              selected: _flipVertical,
              onSelected: enabled
                  ? (value) => _commitOptionChange(() => _flipVertical = value)
                  : null,
              avatar: const Icon(Icons.swap_vert_outlined),
              label: const Text('垂直翻转'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropSection(bool enabled) {
    final info = widget.imageInfo;
    final maxHorizontal = info == null ? 1 : (info.width - 1).clamp(1, 99999);
    final maxVertical = info == null ? 1 : (info.height - 1).clamp(1, 99999);

    return _EditorExpansionSection(
      icon: Icons.crop_outlined,
      title: '裁剪',
      subtitle: _cropSummary,
      child: Column(
        children: [
          ResponsivePair(
            first: IntegerStepperField(
              label: '左边',
              value: _cropLeft,
              minValue: 0,
              maxValue: maxHorizontal.toInt(),
              suffixText: 'px',
              enabled: enabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _cropLeft = value),
            ),
            second: IntegerStepperField(
              label: '上边',
              value: _cropTop,
              minValue: 0,
              maxValue: maxVertical.toInt(),
              suffixText: 'px',
              enabled: enabled,
              onChanged: (value) => _commitOptionChange(() => _cropTop = value),
            ),
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: IntegerStepperField(
              label: '右边',
              value: _cropRight,
              minValue: 0,
              maxValue: maxHorizontal.toInt(),
              suffixText: 'px',
              enabled: enabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _cropRight = value),
            ),
            second: IntegerStepperField(
              label: '下边',
              value: _cropBottom,
              minValue: 0,
              maxValue: maxVertical.toInt(),
              suffixText: 'px',
              enabled: enabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _cropBottom = value),
            ),
          ),
          const SizedBox(height: fieldGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: enabled ? () => _setCenteredCropRatio(1, 1) : null,
                icon: const Icon(Icons.aspect_ratio_outlined),
                label: const Text('1:1'),
              ),
              OutlinedButton.icon(
                onPressed: enabled ? () => _setCenteredCropRatio(4, 3) : null,
                icon: const Icon(Icons.aspect_ratio_outlined),
                label: const Text('4:3'),
              ),
              OutlinedButton.icon(
                onPressed: enabled ? () => _setCenteredCropRatio(16, 9) : null,
                icon: const Icon(Icons.aspect_ratio_outlined),
                label: const Text('16:9'),
              ),
              OutlinedButton.icon(
                onPressed: enabled ? _clearCrop : null,
                icon: const Icon(Icons.crop_free_outlined),
                label: const Text('清除裁剪'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResizeSection(bool enabled) {
    return _EditorExpansionSection(
      icon: Icons.photo_size_select_large_outlined,
      title: '尺寸',
      subtitle: _resizeSummary,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _resizeEnabled,
            onChanged: enabled
                ? (value) => _commitOptionChange(() => _resizeEnabled = value)
                : null,
            title: const Text('调整输出尺寸'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _lockAspectRatio,
            onChanged: enabled && _resizeEnabled
                ? (value) => _commitOptionChange(
                    () => _lockAspectRatio = value ?? true,
                  )
                : null,
            title: const Text('保持比例'),
          ),
          ResponsivePair(
            first: IntegerStepperField(
              label: '宽度',
              value: _resizeWidth,
              minValue: 1,
              maxValue: _maxEditDimension,
              suffixText: 'px',
              enabled: enabled && _resizeEnabled,
              onChanged: _setResizeWidth,
            ),
            second: IntegerStepperField(
              label: '高度',
              value: _resizeHeight,
              minValue: 1,
              maxValue: _maxEditDimension,
              suffixText: 'px',
              enabled: enabled && _resizeEnabled,
              onChanged: _setResizeHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(bool enabled) {
    return _EditorExpansionSection(
      icon: Icons.tune_outlined,
      title: '色彩',
      subtitle: _colorSummary,
      child: Column(
        children: [
          _LabeledSlider(
            label: '亮度',
            value: _brightness,
            min: -100,
            max: 100,
            enabled: enabled,
            onChanged: (value) =>
                _commitOptionChange(() => _brightness = value),
          ),
          _LabeledSlider(
            label: '对比度',
            value: _contrast,
            min: -100,
            max: 100,
            enabled: enabled,
            onChanged: (value) => _commitOptionChange(() => _contrast = value),
          ),
          _LabeledSlider(
            label: '饱和度',
            value: _saturation,
            min: -100,
            max: 100,
            enabled: enabled,
            onChanged: (value) =>
                _commitOptionChange(() => _saturation = value),
          ),
          _LabeledSlider(
            label: '冷暖',
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
    return _EditorExpansionSection(
      icon: Icons.auto_fix_high_outlined,
      title: '效果',
      subtitle: _effectSummary,
      child: Column(
        children: [
          OptionDropdown<ImageEditColorEffect>(
            label: '滤镜',
            value: _effect,
            options: ImageEditColorEffect.values,
            labelBuilder: _effectLabel,
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
            title: const Text('模糊'),
          ),
          IntegerStepperField(
            label: '模糊半径',
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
            title: const Text('锐化'),
          ),
          _LabeledSlider(
            label: '锐化强度',
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
            title: const Text('边缘背景转透明'),
          ),
          _LabeledSlider(
            label: '透明容差',
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
            title: const Text('像素化'),
          ),
          IntegerStepperField(
            label: '像素块',
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
    return _EditorExpansionSection(
      icon: Icons.select_all_outlined,
      title: '选区',
      subtitle: _effectRegionSummary,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _effectRegionEnabled,
            onChanged: enabled
                ? (value) =>
                      _commitOptionChange(() => _effectRegionEnabled = value)
                : null,
            title: const Text('只处理选区'),
          ),
          ResponsivePair(
            first: IntegerStepperField(
              label: '左边界',
              value: _effectRegionLeftPercent,
              minValue: 0,
              maxValue: _effectRegionRightPercent - 1,
              suffixText: '%',
              enabled: enabled && _effectRegionEnabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _effectRegionLeftPercent = value),
            ),
            second: IntegerStepperField(
              label: '上边界',
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
              label: '右边界',
              value: _effectRegionRightPercent,
              minValue: _effectRegionLeftPercent + 1,
              maxValue: 100,
              suffixText: '%',
              enabled: enabled && _effectRegionEnabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _effectRegionRightPercent = value),
            ),
            second: IntegerStepperField(
              label: '下边界',
              value: _effectRegionBottomPercent,
              minValue: _effectRegionTopPercent + 1,
              maxValue: 100,
              suffixText: '%',
              enabled: enabled && _effectRegionEnabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _effectRegionBottomPercent = value),
            ),
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: OutlinedButton.icon(
              onPressed: enabled && _effectRegionEnabled
                  ? () => _commitOptionChange(_setCenteredEffectRegionInPlace)
                  : null,
              icon: const Icon(Icons.center_focus_strong_outlined),
              label: const Text('居中 50%'),
            ),
            second: OutlinedButton.icon(
              onPressed: enabled && _effectRegionEnabled
                  ? () => _commitOptionChange(_setFullEffectRegionInPlace)
                  : null,
              icon: const Icon(Icons.fullscreen_outlined),
              label: const Text('全图选区'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationSection(bool enabled) {
    final canFill = _annotationSupportsFill(_annotationKind);

    return _EditorExpansionSection(
      icon: Icons.edit_note_outlined,
      title: '标注',
      subtitle: _annotationSummary,
      initiallyExpanded: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OptionDropdown<ImageAnnotationKind>(
            label: '类型',
            value: _annotationKind,
            options: ImageAnnotationKind.values,
            labelBuilder: _annotationKindLabel,
            onChanged: enabled
                ? (value) => _commitOptionChange(() => _annotationKind = value)
                : null,
          ),
          if (_annotationKind == ImageAnnotationKind.text) ...[
            const SizedBox(height: fieldGap),
            TextField(
              controller: _annotationTextController,
              enabled: enabled,
              decoration: const InputDecoration(labelText: '文字'),
              textInputAction: TextInputAction.done,
            ),
          ],
          const SizedBox(height: fieldGap),
          Text('位置（百分比）', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ResponsivePair(
            first: IntegerStepperField(
              label: '起点 X',
              value: _annotationStartXPercent,
              minValue: 0,
              maxValue: 100,
              suffixText: '%',
              enabled: enabled,
              onChanged: (value) =>
                  _commitOptionChange(() => _annotationStartXPercent = value),
            ),
            second: IntegerStepperField(
              label: '起点 Y',
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
              label: '终点 X',
              value: _annotationEndXPercent,
              minValue: 0,
              maxValue: 100,
              suffixText: '%',
              enabled: enabled && _annotationKind != ImageAnnotationKind.text,
              onChanged: (value) =>
                  _commitOptionChange(() => _annotationEndXPercent = value),
            ),
            second: IntegerStepperField(
              label: '终点 Y',
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
              label: '线宽',
              value: _annotationStrokeWidth,
              minValue: 1,
              maxValue: 32,
              suffixText: 'px',
              enabled: enabled && _annotationKind != ImageAnnotationKind.text,
              onChanged: (value) =>
                  _commitOptionChange(() => _annotationStrokeWidth = value),
            ),
            second: IntegerStepperField(
              label: '字号',
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
              title: const Text('填充形状'),
            ),
          ],
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: OutlinedButton.icon(
              onPressed: enabled ? _addAnnotation : null,
              icon: const Icon(Icons.add_outlined),
              label: const Text('添加标注'),
            ),
            second: OutlinedButton.icon(
              onPressed: enabled && _annotations.isNotEmpty
                  ? _clearAnnotations
                  : null,
              icon: const Icon(Icons.layers_clear_outlined),
              label: const Text('清空标注'),
            ),
          ),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final argb in _annotationColorOptions)
          _AnnotationColorSwatch(
            color: Color(argb),
            label: _annotationColorLabel(argb),
            selected: _annotationColorArgb == argb,
            onTap: enabled
                ? () => _commitOptionChange(() => _annotationColorArgb = argb)
                : null,
          ),
      ],
    );
  }

  Widget _buildOutputSection(bool enabled) {
    return _EditorExpansionSection(
      icon: Icons.file_download_outlined,
      title: '输出',
      subtitle: _outputSummary,
      initiallyExpanded: enabled,
      child: Column(
        children: [
          OptionDropdown<GeneralImageOutputFormat>(
            label: '保存格式',
            value: _outputFormat,
            options: GeneralImageOutputFormat.values,
            labelBuilder: _outputFormatLabel,
            onChanged: enabled
                ? (value) => _commitOptionChange(() => _outputFormat = value)
                : null,
          ),
          const SizedBox(height: fieldGap),
          IntegerStepperField(
            label: 'JPEG 质量',
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
    final imagePath = widget.imagePath;
    final previewFuture = _previewFuture;

    if (imagePath == null) {
      return const PreviewPanelShell(
        title: '编辑预览',
        child: PreviewStateSurface.empty(message: '选择图片后开始编辑'),
      );
    }

    if (previewFuture != null && _previewSourcePath == imagePath) {
      return PreviewPanelShell(
        title: '编辑预览',
        child: FutureBuilder<GeneralImageEditResult>(
          future: previewFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const PreviewStateSurface.loading(message: '正在生成预览');
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return PreviewStateSurface.error(
                title: '预览失败',
                message: '${snapshot.error ?? '没有可用的预览结果'}',
              );
            }
            final result = snapshot.data!;
            return _ImagePreviewSurface(
              footer: '${result.width} x ${result.height} · ${result.summary}',
              child: Image.memory(result.bytes, fit: BoxFit.contain),
            );
          },
        ),
      );
    }

    return PreviewPanelShell(
      title: '编辑预览',
      child: _ImagePreviewSurface(
        footer: '${fileNameFromPath(imagePath)} · 拖拽裁剪框或选区，点击标注可删除',
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
    );
  }

  void _refreshPreview() {
    final imagePath = widget.imagePath;
    if (imagePath == null) {
      return;
    }
    setState(() {
      _previewSourcePath = imagePath;
      _previewFuture = File(imagePath).readAsBytes().then(
        (bytes) => GeneralImageEditingService.editInBackground(
          bytes,
          options: _currentOptions(),
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
    final snapshot = _snapshot();
    final label = '版本 ${_savedSnapshotSerial++}';
    setState(() {
      _savedSnapshots.insert(
        0,
        _GeneralImageEditorSavedSnapshot(
          label: label,
          summary: _snapshotSummary(snapshot),
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

  void _setCenteredCropRatio(int ratioWidth, int ratioHeight) {
    final info = widget.imageInfo;
    if (info == null || ratioWidth <= 0 || ratioHeight <= 0) {
      return;
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

    _commitOptionChange(() {
      _cropLeft = left;
      _cropRight = right;
      _cropTop = top;
      _cropBottom = bottom;
    });
  }

  void _clearCrop() {
    _commitOptionChange(() {
      _cropLeft = 0;
      _cropTop = 0;
      _cropRight = 0;
      _cropBottom = 0;
    });
  }

  void _setResizeWidth(int value) {
    _commitOptionChange(() {
      _resizeWidth = value;
      if (_lockAspectRatio) {
        final info = widget.imageInfo;
        if (info != null && info.width > 0) {
          _resizeHeight = (value * info.height / info.width)
              .round()
              .clamp(1, _maxEditDimension)
              .toInt();
        }
      }
    });
  }

  void _setResizeHeight(int value) {
    _commitOptionChange(() {
      _resizeHeight = value;
      if (_lockAspectRatio) {
        final info = widget.imageInfo;
        if (info != null && info.height > 0) {
          _resizeWidth = (value * info.width / info.height)
              .round()
              .clamp(1, _maxEditDimension)
              .toInt();
        }
      }
    });
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

  String get _transformSummary {
    final parts = <String>[
      if (_quarterTurns != 0) '旋转 ${_quarterTurns * 90}°',
      if (_flipHorizontal) '水平翻转',
      if (_flipVertical) '垂直翻转',
    ];
    return parts.isEmpty ? '未变换' : parts.join(' · ');
  }

  String get _cropSummary {
    final parts = <String>[
      if (_cropLeft > 0) '左 $_cropLeft',
      if (_cropTop > 0) '上 $_cropTop',
      if (_cropRight > 0) '右 $_cropRight',
      if (_cropBottom > 0) '下 $_cropBottom',
    ];
    return parts.isEmpty ? '不裁剪' : '${parts.join(' · ')} px';
  }

  String get _resizeSummary {
    if (!_resizeEnabled) {
      return '保持原尺寸';
    }
    return '$_resizeWidth x $_resizeHeight';
  }

  String get _colorSummary {
    final parts = <String>[
      if (_brightness != 0) '亮度 $_brightness',
      if (_contrast != 0) '对比 $_contrast',
      if (_saturation != 0) '饱和 $_saturation',
      if (_warmth != 0) '冷暖 $_warmth',
    ];
    return parts.isEmpty ? '未调整' : parts.join(' · ');
  }

  String get _effectSummary {
    final parts = <String>[
      if (_effect != ImageEditColorEffect.none) _effectLabel(_effect),
      if (_blurEnabled) '模糊 ${_blurRadius}px',
      if (_sharpenEnabled) '锐化 $_sharpenAmount%',
      if (_transparentBackgroundEnabled) '透明背景',
      if (_pixelationEnabled) '像素化 $_pixelationBlockSize px',
    ];
    return parts.isEmpty ? '无滤镜' : parts.join(' · ');
  }

  String get _effectRegionSummary {
    if (!_effectRegionEnabled) {
      return '全图处理';
    }
    return '$_effectRegionLeftPercent,$_effectRegionTopPercent → '
        '$_effectRegionRightPercent,$_effectRegionBottomPercent%';
  }

  String get _versionSummary {
    return _savedSnapshots.isEmpty ? '未保存版本' : '${_savedSnapshots.length} 个版本';
  }

  String get _annotationSummary {
    if (_annotations.isEmpty) {
      return '未添加';
    }
    return '${_annotations.length} 个标注';
  }

  String get _outputSummary {
    if (_outputFormat == GeneralImageOutputFormat.jpeg) {
      return 'JPEG · $_jpegQuality%';
    }
    return 'PNG · 保留透明';
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

String _snapshotSummary(_GeneralImageEditorSnapshot snapshot) {
  final parts = <String>[
    if (snapshot.resizeEnabled)
      '${snapshot.resizeWidth} x ${snapshot.resizeHeight}'
    else
      '原尺寸',
    switch (snapshot.outputFormat) {
      GeneralImageOutputFormat.png => 'PNG',
      GeneralImageOutputFormat.jpeg => 'JPEG ${snapshot.jpegQuality}%',
    },
    if (snapshot.effect != ImageEditColorEffect.none)
      _effectLabel(snapshot.effect),
    if (snapshot.blurEnabled) '模糊 ${snapshot.blurRadius}px',
    if (snapshot.sharpenEnabled) '锐化 ${snapshot.sharpenAmount}%',
    if (snapshot.pixelationEnabled) '像素化 ${snapshot.pixelationBlockSize}px',
    if (snapshot.effectRegionEnabled) '局部选区',
    if (snapshot.annotations.isNotEmpty) '标注 ${snapshot.annotations.length}',
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
            tooltip: '恢复版本',
            onPressed: onRestore,
            icon: const Icon(Icons.restore_outlined),
          ),
          IconButton(
            tooltip: '删除版本',
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
              '${index + 1}. ${_annotationDescription(annotation)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: '删除标注',
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

        return Stack(
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
                  tooltip: '删除选中的标注',
                  onPressed: () {
                    widget.onAnnotationDeleted(selectedIndex);
                    setState(() => _selectedAnnotationIndex = null);
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
          ],
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
            errorBuilder: (_, _, _) => const Center(child: Text('图片加载失败')),
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
    return SizedBox(
      height: 36,
      child: ChoiceChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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

String _annotationKindLabel(ImageAnnotationKind kind) {
  return switch (kind) {
    ImageAnnotationKind.text => '文字',
    ImageAnnotationKind.rectangle => '矩形',
    ImageAnnotationKind.ellipse => '椭圆',
    ImageAnnotationKind.line => '直线',
    ImageAnnotationKind.arrow => '箭头',
  };
}

String _annotationColorLabel(int argb) {
  return switch (argb) {
    0xFFFF3B30 => '红色',
    0xFFFFD400 => '黄色',
    0xFF34C759 => '绿色',
    0xFF007AFF => '蓝色',
    0xFF111111 => '黑色',
    0xFFFFFFFF => '白色',
    _ => '自定义',
  };
}

String _annotationDescription(ImageAnnotation annotation) {
  final startX = (annotation.startXRatio * 100).round();
  final startY = (annotation.startYRatio * 100).round();
  final endX = (annotation.endXRatio * 100).round();
  final endY = (annotation.endYRatio * 100).round();
  final label = _annotationKindLabel(annotation.kind);
  if (annotation.kind == ImageAnnotationKind.text) {
    return '$label · ${annotation.text.trim()} · $startX%, $startY%';
  }
  final filled = annotation.filled ? ' · 填充' : '';
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

String _effectLabel(ImageEditColorEffect effect) {
  return switch (effect) {
    ImageEditColorEffect.none => '原色',
    ImageEditColorEffect.grayscale => '灰度',
    ImageEditColorEffect.sepia => '复古',
    ImageEditColorEffect.invert => '反相',
  };
}

class PixelationDefaults {
  const PixelationDefaults._();

  static const int minBlockSize = 2;
  static const int maxBlockSize = 128;
}
