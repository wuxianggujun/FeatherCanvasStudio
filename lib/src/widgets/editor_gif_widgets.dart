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
            first: _TargetFrameSelector(
              frameIndex: safeFrameIndex,
              frameTotal: frameTotal,
              columns: columns,
              enabled: !isReplacingFrame,
              label: '替换目标',
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

class _TargetFrameSelector extends StatefulWidget {
  const _TargetFrameSelector({
    required this.frameIndex,
    required this.frameTotal,
    required this.columns,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  final int frameIndex;
  final int frameTotal;
  final int columns;
  final bool enabled;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  State<_TargetFrameSelector> createState() => _TargetFrameSelectorState();
}

class _TargetFrameSelectorState extends State<_TargetFrameSelector> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayValue.toString());
    _focusNode = FocusNode()..addListener(_normalizeWhenUnfocused);
  }

  @override
  void didUpdateWidget(covariant _TargetFrameSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frameIndex == oldWidget.frameIndex &&
        widget.frameTotal == oldWidget.frameTotal) {
      return;
    }

    final currentValue = int.tryParse(_controller.text);
    if (!_focusNode.hasFocus || currentValue != _displayValue) {
      _setText(_displayValue);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_normalizeWhenUnfocused)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  int get _safeFrameTotal => widget.frameTotal.clamp(1, 9999).toInt();

  int get _safeFrameIndex =>
      widget.frameIndex.clamp(0, _safeFrameTotal - 1).toInt();

  int get _displayValue => _safeFrameIndex + 1;

  String get _helperText {
    final safeColumns = widget.columns.clamp(1, 9999).toInt();
    final row = _safeFrameIndex ~/ safeColumns + 1;
    final column = _safeFrameIndex % safeColumns + 1;
    return '第 $row 行 · 第 $column 列 · 共 $_safeFrameTotal 帧';
  }

  void _normalizeWhenUnfocused() {
    if (!_focusNode.hasFocus) {
      _setText(_normalizeInput(_controller.text));
    }
  }

  void _setText(int value) {
    final text = value.toString();
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  int _normalizeInput(String input) {
    final parsed = int.tryParse(input);
    if (parsed == null) {
      return _displayValue;
    }
    return parsed.clamp(1, _safeFrameTotal).toInt();
  }

  void _emitInput(String input) {
    final parsed = int.tryParse(input);
    if (parsed == null) {
      return;
    }
    widget.onChanged(parsed.clamp(1, _safeFrameTotal).toInt() - 1);
  }

  void _step(int delta) {
    final nextIndex = (_safeFrameIndex + delta)
        .clamp(0, _safeFrameTotal - 1)
        .toInt();
    widget.onChanged(nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: '上一帧',
          onPressed: widget.enabled && _safeFrameIndex > 0
              ? () => _step(-1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: widget.label,
              helperText: _helperText,
              suffixText: '/ $_safeFrameTotal',
            ),
            onChanged: _emitInput,
            onSubmitted: (value) => _setText(_normalizeInput(value)),
          ),
        ),
        IconButton(
          tooltip: '下一帧',
          onPressed: widget.enabled && _safeFrameIndex < _safeFrameTotal - 1
              ? () => _step(1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
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
