import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sprite_sheet_frame_fit.dart';
import '../models/sprite_sheet_grid_spec.dart';
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
    required this.gridSpec,
    required this.targetFrameIndex,
    required this.frameFit,
    required this.isReplacingFrame,
    required this.onPickImage,
    required this.onClearImage,
    required this.onPickPatchImage,
    required this.onClearPatchImage,
    required this.onAdjustPatchFraming,
    required this.onMakePatchBackgroundTransparent,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onGridSpecChanged,
    required this.onTargetFrameChanged,
    required this.onFrameFitChanged,
    required this.onReplaceFrame,
    required this.onCopyPreviousFrame,
    required this.onClearTargetFrame,
    super.key,
  });

  static const List<int> _gridSizes = <int>[1, 2, 3, 4, 5, 6, 7, 8];

  final String? imagePath;
  final String? patchImagePath;
  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;
  final int targetFrameIndex;
  final SpriteSheetFrameFit frameFit;
  final bool isReplacingFrame;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onPickPatchImage;
  final VoidCallback onClearPatchImage;
  final VoidCallback onAdjustPatchFraming;
  final ValueChanged<int> onMakePatchBackgroundTransparent;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<SpriteSheetGridSpec> onGridSpecChanged;
  final ValueChanged<int> onTargetFrameChanged;
  final ValueChanged<SpriteSheetFrameFit> onFrameFitChanged;
  final VoidCallback onReplaceFrame;
  final VoidCallback onCopyPreviousFrame;
  final VoidCallback onClearTargetFrame;

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
          SpriteSheetGridSpecControls(
            gridSpec: gridSpec,
            onChanged: onGridSpecChanged,
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
          _PatchImageToolsSection(
            hasPatchImage: patchImagePath != null,
            canAdjustFraming:
                imagePath != null &&
                patchImagePath != null &&
                !isReplacingFrame,
            canMakeTransparent: patchImagePath != null && !isReplacingFrame,
            isBusy: isReplacingFrame,
            onAdjustFraming: onAdjustPatchFraming,
            onMakeBackgroundTransparent: onMakePatchBackgroundTransparent,
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
          ResponsivePair(
            first: OutlinedButton.icon(
              onPressed:
                  imagePath == null || targetFrameIndex <= 0 || isReplacingFrame
                  ? null
                  : onCopyPreviousFrame,
              icon: const Icon(Icons.content_copy_outlined),
              label: const Text('复制上一帧'),
            ),
            second: OutlinedButton.icon(
              onPressed: imagePath == null || isReplacingFrame
                  ? null
                  : onClearTargetFrame,
              icon: const Icon(Icons.backspace_outlined),
              label: const Text('清空当前格'),
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

class _PatchImageToolsSection extends StatefulWidget {
  const _PatchImageToolsSection({
    required this.hasPatchImage,
    required this.canAdjustFraming,
    required this.canMakeTransparent,
    required this.isBusy,
    required this.onAdjustFraming,
    required this.onMakeBackgroundTransparent,
  });

  final bool hasPatchImage;
  final bool canAdjustFraming;
  final bool canMakeTransparent;
  final bool isBusy;
  final VoidCallback onAdjustFraming;
  final ValueChanged<int> onMakeBackgroundTransparent;

  @override
  State<_PatchImageToolsSection> createState() =>
      _PatchImageToolsSectionState();
}

class _PatchImageToolsSectionState extends State<_PatchImageToolsSection> {
  static const int _minTolerance = 0;
  static const int _maxTolerance = 80;

  int _tolerance = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = widget.canAdjustFraming || widget.canMakeTransparent;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(
            Icons.handyman_outlined,
            size: 18,
            color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          title: Text('单帧处理', style: theme.textTheme.titleSmall),
          subtitle: Text(
            widget.hasPatchImage ? '调整取景 · 背景转透明' : '选择单帧图片后可用',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: widget.canAdjustFraming && !widget.isBusy
                    ? widget.onAdjustFraming
                    : null,
                icon: const Icon(Icons.crop_outlined),
                label: const Text('调整取景'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _tolerance.toDouble(),
                    min: _minTolerance.toDouble(),
                    max: _maxTolerance.toDouble(),
                    divisions: _maxTolerance - _minTolerance,
                    label: '容差 $_tolerance',
                    onChanged: widget.canMakeTransparent
                        ? (value) => setState(() => _tolerance = value.round())
                        : null,
                  ),
                ),
                SizedBox(
                  width: 74,
                  child: Text(
                    '容差 $_tolerance',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: widget.canMakeTransparent && !widget.isBusy
                    ? () => widget.onMakeBackgroundTransparent(_tolerance)
                    : null,
                icon: widget.isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high_outlined),
                label: Text(widget.isBusy ? '处理中' : '生成透明背景单帧'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
