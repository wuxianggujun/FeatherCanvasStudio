import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/generated_image.dart';
import '../../models/sprite_sheet_frame_fit.dart';
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
    required this.targetFrameIndex,
    required this.frameFit,
    required this.isReplacingFrame,
    required this.errorMessage,
    required this.onPickImage,
    required this.onClearImage,
    required this.onPickPatchImage,
    required this.onClearPatchImage,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onTargetFrameChanged,
    required this.onFrameFitChanged,
    required this.onReplaceFrame,
    required this.onExportSpriteSheet,
    super.key,
  });

  final String? imagePath;
  final String? patchImagePath;
  final int rows;
  final int columns;
  final int targetFrameIndex;
  final SpriteSheetFrameFit frameFit;
  final bool isReplacingFrame;
  final String? errorMessage;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onPickPatchImage;
  final VoidCallback onClearPatchImage;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<int> onTargetFrameChanged;
  final ValueChanged<SpriteSheetFrameFit> onFrameFitChanged;
  final VoidCallback onReplaceFrame;
  final ValueChanged<Uint8List> onExportSpriteSheet;

  @override
  Widget build(BuildContext context) {
    final editorImages = imagePath == null
        ? const <GeneratedImage>[]
        : [GeneratedImage.file(imagePath!)];

    return WorkspacePage(
      title: '图片编辑',
      description: '载入一张 Sprite Sheet，按行列快速查看第几帧',
      children: [
        ResponsiveWorkspaceSplit(
          controls: SpriteSheetEditorPanel(
            imagePath: imagePath,
            patchImagePath: patchImagePath,
            rows: rows,
            columns: columns,
            targetFrameIndex: targetFrameIndex.clamp(0, rows * columns - 1),
            frameFit: frameFit,
            isReplacingFrame: isReplacingFrame,
            onPickImage: onPickImage,
            onClearImage: onClearImage,
            onPickPatchImage: onPickPatchImage,
            onClearPatchImage: onClearPatchImage,
            onRowsChanged: onRowsChanged,
            onColumnsChanged: onColumnsChanged,
            onTargetFrameChanged: onTargetFrameChanged,
            onFrameFitChanged: onFrameFitChanged,
            onReplaceFrame: onReplaceFrame,
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
            labelBuilder: (index) =>
                editorFrameGridLabel(index, columns: columns),
            onExportSpriteSheet: onExportSpriteSheet,
          ),
        ),
      ],
    );
  }
}
