import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/generated_image.dart';
import '../../models/sprite_sheet_frame_fit.dart';
import '../../models/sprite_sheet_grid_spec.dart';
import '../../services/general_image_editing_service.dart';
import '../../services/sprite_sheet_service.dart';
import '../../utils/sprite_sheet_text.dart';
import '../editor_gif_widgets.dart';
import '../general_image_editor_widgets.dart';
import '../layout_navigation_widgets.dart';
import '../preview_widgets.dart';

enum _ImageEditorMode { general, spriteSheet }

class ImageEditorWorkspace extends StatefulWidget {
  const ImageEditorWorkspace({
    required this.generalImagePath,
    required this.generalImageInfo,
    required this.isProcessingGeneralImage,
    required this.generalImageErrorMessage,
    required this.onPickGeneralImage,
    required this.onClearGeneralImage,
    required this.onApplyGeneralImageEdit,
    required this.imagePath,
    required this.patchImagePath,
    required this.rows,
    required this.columns,
    required this.gridSpec,
    required this.targetFrameIndex,
    required this.frameFit,
    required this.isReplacingFrame,
    required this.isFocusMode,
    required this.historyControls,
    required this.errorMessage,
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

  final String? generalImagePath;
  final ImageInspectionResult? generalImageInfo;
  final bool isProcessingGeneralImage;
  final String? generalImageErrorMessage;
  final VoidCallback onPickGeneralImage;
  final VoidCallback onClearGeneralImage;
  final GeneralImageEditApplyCallback onApplyGeneralImageEdit;
  final String? imagePath;
  final String? patchImagePath;
  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;
  final int targetFrameIndex;
  final SpriteSheetFrameFit frameFit;
  final bool isReplacingFrame;
  final bool isFocusMode;
  final Widget historyControls;
  final String? errorMessage;
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

  @override
  void didUpdateWidget(covariant ImageEditorWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generalImagePath != widget.generalImagePath &&
        widget.generalImagePath != null) {
      _mode = _ImageEditorMode.general;
      return;
    }
    if (oldWidget.imagePath != widget.imagePath && widget.imagePath != null) {
      _mode = _ImageEditorMode.spriteSheet;
    }
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
          GeneralImageEditorContent(
            imagePath: widget.generalImagePath,
            imageInfo: widget.generalImageInfo,
            isProcessing: widget.isProcessingGeneralImage,
            errorMessage: widget.generalImageErrorMessage,
            onPickImage: widget.onPickGeneralImage,
            onClearImage: widget.onClearGeneralImage,
            onApplyEdit: widget.onApplyGeneralImageEdit,
          )
        else
          _buildSpriteSheetEditor(),
      ],
    );
  }

  Widget _buildSpriteSheetEditor() {
    final editorImages = widget.imagePath == null
        ? const <GeneratedImage>[]
        : [GeneratedImage.file(widget.imagePath!)];

    return ResponsiveWorkspaceSplit(
      storageKey: 'image_editor',
      controlsWidth: widget.isFocusMode ? 316 : 352,
      minControlsWidth: widget.isFocusMode ? 276 : 300,
      maxControlsWidth: widget.isFocusMode ? 420 : 500,
      controls: SpriteSheetEditorPanel(
        imagePath: widget.imagePath,
        patchImagePath: widget.patchImagePath,
        rows: widget.rows,
        columns: widget.columns,
        gridSpec: widget.gridSpec,
        targetFrameIndex: widget.targetFrameIndex.clamp(
          0,
          widget.rows * widget.columns - 1,
        ),
        frameFit: widget.frameFit,
        isReplacingFrame: widget.isReplacingFrame,
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
      preview: FrameAnimationPreviewPanel(
        title: '切片查看',
        emptyMessage: '选择一张 Sprite Sheet 后，可以按行列查看第几帧',
        errorMessage: widget.errorMessage,
        debugRecord: null,
        generatedImages: editorImages,
        isGenerating: false,
        rows: widget.rows,
        columns: widget.columns,
        gridSpec: widget.gridSpec,
        selectedFrameIndex: widget.targetFrameIndex,
        onFrameSelected: widget.onTargetFrameChanged,
        enablePlayback: false,
        labelBuilder: (index) =>
            editorFrameGridLabel(index, columns: widget.columns),
        onExportSpriteSheet: widget.onExportSpriteSheet,
        onSendToGif: widget.onSendToGif,
      ),
    );
  }
}
