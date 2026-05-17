import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/generated_image.dart';
import '../../models/sprite_sheet_frame_fit.dart';
import '../../models/sprite_sheet_grid_spec.dart';
import '../../services/sprite_sheet_service.dart';
import '../../utils/sprite_sheet_text.dart';
import '../editor_gif_widgets.dart';
import '../layout_navigation_widgets.dart';
import '../preview_widgets.dart';

class ImageEditorWorkspace extends StatelessWidget {
  const ImageEditorWorkspace({
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
  Widget build(BuildContext context) {
    final editorImages = imagePath == null
        ? const <GeneratedImage>[]
        : [GeneratedImage.file(imagePath!)];

    return WorkspacePage(
      title: '图片编辑',
      description: '载入一张 Sprite Sheet，按行列快速查看第几帧',
      compactHeader: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          historyControls,
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: isFocusMode ? '退出专注模式' : '进入专注模式',
            onPressed: () => onFocusModeChanged(!isFocusMode),
            icon: Icon(
              isFocusMode
                  ? Icons.fullscreen_exit_outlined
                  : Icons.fullscreen_outlined,
            ),
          ),
        ],
      ),
      children: [
        ResponsiveWorkspaceSplit(
          controlsWidth: isFocusMode ? 316 : 352,
          minControlsWidth: isFocusMode ? 276 : 300,
          maxControlsWidth: isFocusMode ? 420 : 500,
          controls: SpriteSheetEditorPanel(
            imagePath: imagePath,
            patchImagePath: patchImagePath,
            rows: rows,
            columns: columns,
            gridSpec: gridSpec,
            targetFrameIndex: targetFrameIndex.clamp(0, rows * columns - 1),
            frameFit: frameFit,
            isReplacingFrame: isReplacingFrame,
            onPickImage: onPickImage,
            onClearImage: onClearImage,
            onPickPatchImage: onPickPatchImage,
            onClearPatchImage: onClearPatchImage,
            onAdjustPatchFraming: onAdjustPatchFraming,
            onMakePatchBackgroundTransparent: onMakePatchBackgroundTransparent,
            onPixelateCurrentFrame: onPixelateCurrentFrame,
            onPixelateWholeSheet: onPixelateWholeSheet,
            onRowsChanged: onRowsChanged,
            onColumnsChanged: onColumnsChanged,
            onGridSpecChanged: onGridSpecChanged,
            onTargetFrameChanged: onTargetFrameChanged,
            onFrameFitChanged: onFrameFitChanged,
            onReplaceFrame: onReplaceFrame,
            onCopyPreviousFrame: onCopyPreviousFrame,
            onClearTargetFrame: onClearTargetFrame,
          ),
          preview: FrameAnimationPreviewPanel(
            title: '切片查看',
            emptyMessage: '选择一张 Sprite Sheet 后，可以按行列查看第几帧',
            errorMessage: errorMessage,
            debugRecord: null,
            generatedImages: editorImages,
            isGenerating: false,
            rows: rows,
            columns: columns,
            gridSpec: gridSpec,
            selectedFrameIndex: targetFrameIndex,
            onFrameSelected: onTargetFrameChanged,
            enablePlayback: false,
            labelBuilder: (index) =>
                editorFrameGridLabel(index, columns: columns),
            onExportSpriteSheet: onExportSpriteSheet,
            onSendToGif: onSendToGif,
          ),
        ),
      ],
    );
  }
}
