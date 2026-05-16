import 'dart:io';

import 'package:flutter/material.dart';

import '../models/sprite_sheet_frame_fit.dart';
import '../services/gif_composer_service.dart';
import '../theme/layout_constants.dart';
import '../utils/display_labels.dart';
import '../widgets/common_form_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';
import '../widgets/preview_widgets.dart';

part 'gif_composer_widgets.dart';

class SpriteSheetEditorPanel extends StatelessWidget {
  const SpriteSheetEditorPanel({
    required this.imagePath,
    required this.patchImagePath,
    required this.rows,
    required this.columns,
    required this.targetFrameIndex,
    required this.frameFit,
    required this.isReplacingFrame,
    required this.onPickImage,
    required this.onClearImage,
    required this.onPickPatchImage,
    required this.onClearPatchImage,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onTargetFrameChanged,
    required this.onFrameFitChanged,
    required this.onReplaceFrame,
    super.key,
  });

  static const List<int> _gridSizes = <int>[1, 2, 3, 4, 5, 6, 7, 8];

  final String? imagePath;
  final String? patchImagePath;
  final int rows;
  final int columns;
  final int targetFrameIndex;
  final SpriteSheetFrameFit frameFit;
  final bool isReplacingFrame;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onPickPatchImage;
  final VoidCallback onClearPatchImage;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<int> onTargetFrameChanged;
  final ValueChanged<SpriteSheetFrameFit> onFrameFitChanged;
  final VoidCallback onReplaceFrame;

  @override
  Widget build(BuildContext context) {
    final frameTotal = rows * columns;
    final safeFrameIndex = targetFrameIndex.clamp(0, frameTotal - 1);
    final canReplace =
        imagePath != null && patchImagePath != null && !isReplacingFrame;

    return AppPanel(
      title: '编辑配置',
      trailing: FrameCountBadge(count: frameTotal),
      child: Column(
        children: [
          TemplateImagePicker(
            imagePath: imagePath,
            title: 'Sprite Sheet 图片',
            pickLabel: imagePath == null ? '选择' : '更换',
            clearTooltip: '清除图片',
            onPick: onPickImage,
            onClear: imagePath == null ? null : onClearImage,
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: OptionDropdown<int>(
              label: '行数',
              value: rows,
              options: _gridSizes,
              labelBuilder: (value) => '$value 行',
              onChanged: onRowsChanged,
            ),
            second: OptionDropdown<int>(
              label: '列数',
              value: columns,
              options: _gridSizes,
              labelBuilder: (value) => '$value 列',
              onChanged: onColumnsChanged,
            ),
          ),
          const SizedBox(height: fieldGap),
          TemplateImagePicker(
            imagePath: patchImagePath,
            title: '单帧图片',
            pickLabel: patchImagePath == null ? '选择' : '更换',
            clearTooltip: '清除单帧图片',
            previewHeight: 148,
            onPick: onPickPatchImage,
            onClear: patchImagePath == null ? null : onClearPatchImage,
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: OptionDropdown<int>(
              fieldKey: ValueKey(
                'editor-target-frame-$safeFrameIndex-$frameTotal',
              ),
              label: '替换目标',
              value: safeFrameIndex,
              options: [for (var index = 0; index < frameTotal; index++) index],
              labelBuilder: (index) => editorFrameOptionLabel(index, columns),
              onChanged: onTargetFrameChanged,
            ),
            second: OptionDropdown<SpriteSheetFrameFit>(
              label: '适配方式',
              value: frameFit,
              options: SpriteSheetFrameFit.values,
              labelBuilder: spriteSheetFrameFitLabel,
              onChanged: onFrameFitChanged,
            ),
          ),
          const SizedBox(height: fieldGap),
          PrimaryActionButton(
            onPressed: canReplace ? onReplaceFrame : null,
            icon: Icons.published_with_changes_outlined,
            label: '插入 / 替换到当前格',
            busyLabel: '替换中',
            isBusy: isReplacingFrame,
          ),
        ],
      ),
    );
  }
}
