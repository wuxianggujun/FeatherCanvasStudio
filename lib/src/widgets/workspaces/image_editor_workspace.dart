import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/generated_image.dart';
import '../../models/sprite_sheet_frame_fit.dart';
import '../../models/sprite_sheet_grid_spec.dart';
import '../../services/general_image_editing_service.dart';
import '../../services/sprite_sheet_service.dart';
import '../../state/image_editor_notifier.dart';
import '../../utils/sprite_sheet_text.dart';
import '../editor_gif_widgets.dart';
import '../general_image_editor_widgets.dart';
import '../layout_navigation_widgets.dart';
import '../preview_widgets.dart';

enum _ImageEditorMode { general, spriteSheet }

class ImageEditorWorkspace extends StatefulWidget {
  const ImageEditorWorkspace({
    required this.onPickGeneralImage,
    required this.onClearGeneralImage,
    required this.onApplyGeneralImageEdit,
    required this.isFocusMode,
    required this.historyControls,
    required this.onPickImage,
    required this.onClearImage,
    required this.onPickPatchImage,
    required this.onClearPatchImage,
    required this.onAdjustPatchFraming,
    required this.onMakePatchBackgroundTransparent,
    required this.onPixelateCurrentFrame,
    required this.onPixelateWholeSheet,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onGridSpecChanged,
    required this.onTargetFrameChanged,
    required this.onFrameFitChanged,
    required this.onFocusModeChanged,
    required this.onReplaceFrame,
    required this.onCopyPreviousFrame,
    required this.onClearTargetFrame,
    required this.onExportSpriteSheet,
    required this.onSendToGif,
    super.key,
  });

  final VoidCallback onPickGeneralImage;
  final VoidCallback onClearGeneralImage;
  final GeneralImageEditApplyCallback onApplyGeneralImageEdit;
  final bool isFocusMode;
  final Widget historyControls;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onPickPatchImage;
  final VoidCallback onClearPatchImage;
  final VoidCallback onAdjustPatchFraming;
  final ValueChanged<int> onMakePatchBackgroundTransparent;
  final ValueChanged<int> onPixelateCurrentFrame;
  final ValueChanged<int> onPixelateWholeSheet;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<SpriteSheetGridSpec> onGridSpecChanged;
  final ValueChanged<int> onTargetFrameChanged;
  final ValueChanged<SpriteSheetFrameFit> onFrameFitChanged;
  final ValueChanged<bool> onFocusModeChanged;
  final VoidCallback onReplaceFrame;
  final VoidCallback onCopyPreviousFrame;
  final VoidCallback onClearTargetFrame;
  final ValueChanged<Uint8List> onExportSpriteSheet;
  final ValueChanged<SpriteSheetPreviewData> onSendToGif;

  @override
  State<ImageEditorWorkspace> createState() => _ImageEditorWorkspaceState();
}

class _ImageEditorWorkspaceState extends State<ImageEditorWorkspace> {
  _ImageEditorMode _mode = _ImageEditorMode.general;
  ImageEditorNotifier? _notifier;
  String? _lastGeneralPath;
  String? _lastSheetPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.read<ImageEditorNotifier>();
    if (!identical(_notifier, notifier)) {
      _notifier?.removeListener(_handleNotifierChanged);
      _notifier = notifier;
      _lastGeneralPath = notifier.generalEditorImagePath;
      _lastSheetPath = notifier.editorImagePath;
      notifier.addListener(_handleNotifierChanged);
    }
  }

  @override
  void dispose() {
    _notifier?.removeListener(_handleNotifierChanged);
    super.dispose();
  }

  void _handleNotifierChanged() {
    final notifier = _notifier;
    if (notifier == null) return;
    final generalPath = notifier.generalEditorImagePath;
    final sheetPath = notifier.editorImagePath;
    if (generalPath != _lastGeneralPath && generalPath != null) {
      if (mounted) setState(() => _mode = _ImageEditorMode.general);
    } else if (sheetPath != _lastSheetPath && sheetPath != null) {
      if (mounted) setState(() => _mode = _ImageEditorMode.spriteSheet);
    }
    _lastGeneralPath = generalPath;
    _lastSheetPath = sheetPath;
  }

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: '图片编辑',
      description: _mode == _ImageEditorMode.general
          ? '裁剪、旋转、缩放、调色和保存图片副本'
          : '载入一张 Sprite Sheet，按行列快速查看第几帧',
      compactHeader: widget.isFocusMode,
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<_ImageEditorMode>(
            segments: const [
              ButtonSegment(
                value: _ImageEditorMode.general,
                icon: Icon(Icons.tune_outlined),
                label: Text('普通图片'),
              ),
              ButtonSegment(
                value: _ImageEditorMode.spriteSheet,
                icon: Icon(Icons.grid_on_outlined),
                label: Text('Sprite Sheet'),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() => _mode = selection.single);
            },
          ),
          widget.historyControls,
          IconButton.filledTonal(
            tooltip: widget.isFocusMode ? '退出专注模式' : '进入专注模式',
            onPressed: () => widget.onFocusModeChanged(!widget.isFocusMode),
            icon: Icon(
              widget.isFocusMode
                  ? Icons.fullscreen_exit_outlined
                  : Icons.fullscreen_outlined,
            ),
          ),
        ],
      ),
      children: [
        if (_mode == _ImageEditorMode.general)
          Selector<ImageEditorNotifier,
              ({
                String? imagePath,
                ImageInspectionResult? imageInfo,
                bool isProcessing,
                String? errorMessage,
              })>(
            selector: (_, n) => (
              imagePath: n.generalEditorImagePath,
              imageInfo: n.generalEditorImageInfo,
              isProcessing: n.isProcessingGeneralImage,
              errorMessage: n.generalEditorErrorMessage,
            ),
            builder: (context, data, _) => GeneralImageEditorContent(
              imagePath: data.imagePath,
              imageInfo: data.imageInfo,
              isProcessing: data.isProcessing,
              errorMessage: data.errorMessage,
              onPickImage: widget.onPickGeneralImage,
              onClearImage: widget.onClearGeneralImage,
              onApplyEdit: widget.onApplyGeneralImageEdit,
            ),
          )
        else
          _buildSpriteSheetEditor(),
      ],
    );
  }

  Widget _buildSpriteSheetEditor() {
    return ResponsiveWorkspaceSplit(
      storageKey: 'image_editor',
      controlsWidth: widget.isFocusMode ? 316 : 352,
      minControlsWidth: widget.isFocusMode ? 276 : 300,
      maxControlsWidth: widget.isFocusMode ? 420 : 500,
      controls: Selector<ImageEditorNotifier,
          ({
            String? imagePath,
            String? patchImagePath,
            int rows,
            int columns,
            SpriteSheetGridSpec gridSpec,
            int targetFrameIndex,
            SpriteSheetFrameFit frameFit,
            bool isReplacingFrame,
          })>(
        selector: (_, n) => (
          imagePath: n.editorImagePath,
          patchImagePath: n.editorPatchImagePath,
          rows: n.editorRows,
          columns: n.editorColumns,
          gridSpec: n.editorGridSpec,
          targetFrameIndex: n.editorTargetFrameIndex,
          frameFit: n.editorFrameFit,
          isReplacingFrame: n.isReplacingEditorFrame,
        ),
        builder: (context, data, _) => SpriteSheetEditorPanel(
          imagePath: data.imagePath,
          patchImagePath: data.patchImagePath,
          rows: data.rows,
          columns: data.columns,
          gridSpec: data.gridSpec,
          targetFrameIndex: data.targetFrameIndex.clamp(
            0,
            data.rows * data.columns - 1,
          ),
          frameFit: data.frameFit,
          isReplacingFrame: data.isReplacingFrame,
          onPickImage: widget.onPickImage,
          onClearImage: widget.onClearImage,
          onPickPatchImage: widget.onPickPatchImage,
          onClearPatchImage: widget.onClearPatchImage,
          onAdjustPatchFraming: widget.onAdjustPatchFraming,
          onMakePatchBackgroundTransparent:
              widget.onMakePatchBackgroundTransparent,
          onPixelateCurrentFrame: widget.onPixelateCurrentFrame,
          onPixelateWholeSheet: widget.onPixelateWholeSheet,
          onRowsChanged: widget.onRowsChanged,
          onColumnsChanged: widget.onColumnsChanged,
          onGridSpecChanged: widget.onGridSpecChanged,
          onTargetFrameChanged: widget.onTargetFrameChanged,
          onFrameFitChanged: widget.onFrameFitChanged,
          onReplaceFrame: widget.onReplaceFrame,
          onCopyPreviousFrame: widget.onCopyPreviousFrame,
          onClearTargetFrame: widget.onClearTargetFrame,
        ),
      ),
      preview: Selector<ImageEditorNotifier,
          ({
            String? imagePath,
            int rows,
            int columns,
            SpriteSheetGridSpec gridSpec,
            int targetFrameIndex,
            String? errorMessage,
          })>(
        selector: (_, n) => (
          imagePath: n.editorImagePath,
          rows: n.editorRows,
          columns: n.editorColumns,
          gridSpec: n.editorGridSpec,
          targetFrameIndex: n.editorTargetFrameIndex,
          errorMessage: n.editorErrorMessage,
        ),
        builder: (context, data, _) {
          final editorImages = data.imagePath == null
              ? const <GeneratedImage>[]
              : [GeneratedImage.file(data.imagePath!)];
          return FrameAnimationPreviewPanel(
            title: '切片查看',
            emptyMessage: '选择一张 Sprite Sheet 后，可以按行列查看第几帧',
            errorMessage: data.errorMessage,
            debugRecord: null,
            generatedImages: editorImages,
            isGenerating: false,
            rows: data.rows,
            columns: data.columns,
            gridSpec: data.gridSpec,
            selectedFrameIndex: data.targetFrameIndex,
            onFrameSelected: widget.onTargetFrameChanged,
            enablePlayback: false,
            labelBuilder: (index) =>
                editorFrameGridLabel(index, columns: data.columns),
            onExportSpriteSheet: widget.onExportSpriteSheet,
            onSendToGif: widget.onSendToGif,
          );
        },
      ),
    );
  }
}
