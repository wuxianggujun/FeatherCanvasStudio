import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_l10n.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/sprite_sheet_frame_fit.dart';
import '../models/sprite_sheet_grid_spec.dart';
import '../theme/layout_constants.dart';
import '../widgets/common_form_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';

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
    required this.onPixelateCurrentFrame,
    required this.onPixelateWholeSheet,
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
  final ValueChanged<int> onPixelateCurrentFrame;
  final ValueChanged<int> onPixelateWholeSheet;
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
    final l10n = appL10nOf(context);
    final frameTotal = rows * columns;
    final safeFrameIndex = targetFrameIndex.clamp(0, frameTotal - 1);
    final canReplace =
        imagePath != null && patchImagePath != null && !isReplacingFrame;

    return AppPanel(
      title: l10n.spriteSheetEditorConfigTitle,
      trailing: FrameCountBadge(count: frameTotal),
      child: Column(
        children: [
          TemplateImagePicker(
            imagePath: imagePath,
            title: l10n.spriteSheetEditorSheetImageTitle,
            pickLabel: imagePath == null
                ? l10n.selectAction
                : l10n.replaceAction,
            clearTooltip: l10n.spriteSheetEditorClearSheetImageTooltip,
            onPick: onPickImage,
            onClear: imagePath == null ? null : onClearImage,
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: OptionDropdown<int>(
              label: l10n.spriteSheetEditorRowsLabel,
              value: rows,
              options: _gridSizes,
              labelBuilder: l10n.spriteSheetEditorRowsValue,
              onChanged: onRowsChanged,
            ),
            second: OptionDropdown<int>(
              label: l10n.spriteSheetEditorColumnsLabel,
              value: columns,
              options: _gridSizes,
              labelBuilder: l10n.spriteSheetEditorColumnsValue,
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
            title: l10n.spriteSheetEditorPatchImageTitle,
            pickLabel: patchImagePath == null
                ? l10n.selectAction
                : l10n.replaceAction,
            clearTooltip: l10n.spriteSheetEditorClearPatchImageTooltip,
            previewHeight: 148,
            onPick: onPickPatchImage,
            onClear: patchImagePath == null ? null : onClearPatchImage,
          ),
          const SizedBox(height: fieldGap),
          _PatchImageToolsSection(
            hasSheetImage: imagePath != null,
            hasPatchImage: patchImagePath != null,
            canAdjustFraming:
                imagePath != null &&
                patchImagePath != null &&
                !isReplacingFrame,
            canMakeTransparent: patchImagePath != null && !isReplacingFrame,
            canPixelateFrame: imagePath != null && !isReplacingFrame,
            canPixelateSheet: imagePath != null && !isReplacingFrame,
            isBusy: isReplacingFrame,
            onAdjustFraming: onAdjustPatchFraming,
            onMakeBackgroundTransparent: onMakePatchBackgroundTransparent,
            onPixelateCurrentFrame: onPixelateCurrentFrame,
            onPixelateWholeSheet: onPixelateWholeSheet,
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: _TargetFrameSelector(
              frameIndex: safeFrameIndex,
              frameTotal: frameTotal,
              columns: columns,
              enabled: !isReplacingFrame,
              label: l10n.spriteSheetEditorReplacementTargetLabel,
              onChanged: onTargetFrameChanged,
            ),
            second: OptionDropdown<SpriteSheetFrameFit>(
              label: l10n.spriteSheetEditorFrameFitLabel,
              value: frameFit,
              options: SpriteSheetFrameFit.values,
              labelBuilder: (value) => switch (value) {
                SpriteSheetFrameFit.contain =>
                  l10n.spriteSheetEditorFrameFitContain,
                SpriteSheetFrameFit.cover =>
                  l10n.spriteSheetEditorFrameFitCover,
                SpriteSheetFrameFit.stretch =>
                  l10n.spriteSheetEditorFrameFitStretch,
              },
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
              label: Text(l10n.spriteSheetEditorCopyPreviousFrame),
            ),
            second: OutlinedButton.icon(
              onPressed: imagePath == null || isReplacingFrame
                  ? null
                  : onClearTargetFrame,
              icon: const Icon(Icons.backspace_outlined),
              label: Text(l10n.spriteSheetEditorClearCurrentCell),
            ),
          ),
          const SizedBox(height: fieldGap),
          PrimaryActionButton(
            onPressed: canReplace ? onReplaceFrame : null,
            icon: Icons.published_with_changes_outlined,
            label: l10n.spriteSheetEditorInsertReplaceCurrentCell,
            busyLabel: l10n.spriteSheetEditorReplacing,
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

  String _helperText(AppLocalizations l10n) {
    final safeColumns = widget.columns.clamp(1, 9999).toInt();
    final row = _safeFrameIndex ~/ safeColumns + 1;
    final column = _safeFrameIndex % safeColumns + 1;
    return l10n.spriteSheetEditorTargetFrameHelper(
      row,
      column,
      _safeFrameTotal,
    );
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
    final l10n = appL10nOf(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: l10n.framePreviewPreviousFrameTooltip,
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
              helperText: _helperText(l10n),
              suffixText: '/ $_safeFrameTotal',
            ),
            onChanged: _emitInput,
            onSubmitted: (value) => _setText(_normalizeInput(value)),
          ),
        ),
        IconButton(
          tooltip: l10n.framePreviewNextFrameTooltip,
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
    required this.hasSheetImage,
    required this.hasPatchImage,
    required this.canAdjustFraming,
    required this.canMakeTransparent,
    required this.canPixelateFrame,
    required this.canPixelateSheet,
    required this.isBusy,
    required this.onAdjustFraming,
    required this.onMakeBackgroundTransparent,
    required this.onPixelateCurrentFrame,
    required this.onPixelateWholeSheet,
  });

  final bool hasSheetImage;
  final bool hasPatchImage;
  final bool canAdjustFraming;
  final bool canMakeTransparent;
  final bool canPixelateFrame;
  final bool canPixelateSheet;
  final bool isBusy;
  final VoidCallback onAdjustFraming;
  final ValueChanged<int> onMakeBackgroundTransparent;
  final ValueChanged<int> onPixelateCurrentFrame;
  final ValueChanged<int> onPixelateWholeSheet;

  @override
  State<_PatchImageToolsSection> createState() =>
      _PatchImageToolsSectionState();
}

class _PatchImageToolsSectionState extends State<_PatchImageToolsSection> {
  static const int _minTolerance = 0;
  static const int _maxTolerance = 80;
  static const int _minPixelationBlockSize = 2;
  static const int _maxPixelationBlockSize = 64;

  int _tolerance = 28;
  int _pixelationBlockSize = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canPixelate = widget.canPixelateFrame || widget.canPixelateSheet;
    final enabled =
        widget.canAdjustFraming || widget.canMakeTransparent || canPixelate;
    final subtitleParts = <String>[
      if (widget.hasPatchImage) l10n.spriteSheetEditorToolFraming,
      if (widget.hasPatchImage) l10n.spriteSheetEditorToolTransparent,
      if (widget.hasSheetImage) l10n.spriteSheetEditorToolPixelate,
    ];
    final toleranceLabel = l10n.backgroundTransparencyTolerance(_tolerance);

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
          key: ValueKey<bool>(enabled),
          initiallyExpanded: enabled,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(
            Icons.handyman_outlined,
            size: 18,
            color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          title: Text(
            l10n.spriteSheetEditorToolsTitle,
            style: theme.textTheme.titleSmall,
          ),
          subtitle: Text(
            subtitleParts.isEmpty
                ? l10n.spriteSheetEditorToolsDisabledHint
                : subtitleParts.join(' · '),
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
                label: Text(l10n.patchImageFramingTitle),
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
                    label: toleranceLabel,
                    onChanged: widget.canMakeTransparent
                        ? (value) => setState(() => _tolerance = value.round())
                        : null,
                  ),
                ),
                SizedBox(
                  width: 74,
                  child: Text(
                    toleranceLabel,
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
                label: Text(
                  widget.isBusy
                      ? l10n.spriteSheetEditorProcessing
                      : l10n.spriteSheetEditorGenerateTransparentPatch,
                ),
              ),
            ),
            const Divider(height: 22),
            IntegerStepperField(
              label: l10n.spriteSheetEditorPixelBlockLabel,
              value: _pixelationBlockSize,
              minValue: _minPixelationBlockSize,
              maxValue: _maxPixelationBlockSize,
              suffixText: 'px',
              helperText: l10n.spriteSheetEditorPixelBlockHelper,
              enabled: canPixelate && !widget.isBusy,
              onChanged: (value) => setState(() {
                _pixelationBlockSize = value
                    .clamp(_minPixelationBlockSize, _maxPixelationBlockSize)
                    .toInt();
              }),
            ),
            const SizedBox(height: 8),
            ResponsivePair(
              first: OutlinedButton.icon(
                onPressed: widget.canPixelateFrame && !widget.isBusy
                    ? () => widget.onPixelateCurrentFrame(_pixelationBlockSize)
                    : null,
                icon: const Icon(Icons.grid_on_outlined),
                label: Text(l10n.spriteSheetEditorPixelateCurrentFrame),
              ),
              second: OutlinedButton.icon(
                onPressed: widget.canPixelateSheet && !widget.isBusy
                    ? () => widget.onPixelateWholeSheet(_pixelationBlockSize)
                    : null,
                icon: const Icon(Icons.grid_4x4_outlined),
                label: Text(l10n.spriteSheetEditorPixelateWholeSheet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
