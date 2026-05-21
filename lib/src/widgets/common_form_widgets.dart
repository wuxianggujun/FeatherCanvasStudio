import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_l10n.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/sprite_sheet_grid_spec.dart';
import '../services/image_api_client.dart';
import '../theme/layout_constants.dart';
import '../utils/display_labels.dart';

class AppPanel extends StatelessWidget {
  const AppPanel({
    required this.title,
    required this.child,
    this.trailing,
    this.expandChild = false,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(panelPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              ?trailing,
            ],
          ),
          const SizedBox(height: sectionGap),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

class FrameCountBadge extends StatelessWidget {
  const FrameCountBadge({required this.count, this.label, super.key});

  final int count;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedLabel = label ?? l10n.frameCountBadgeDefaultLabel;

    return Tooltip(
      message: l10n.frameCountBadgeTooltip(count, resolvedLabel),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.grid_view_outlined,
                size: 16,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                '$count $resolvedLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OptionDropdown<T> extends StatelessWidget {
  const OptionDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.helperText,
    this.fieldKey,
    this.isDense = false,
    super.key,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T>? onChanged;
  final String? helperText;
  final Key? fieldKey;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final T? selectedValue;
    if (options.contains(value)) {
      selectedValue = value;
    } else if (options.isEmpty) {
      selectedValue = null;
    } else {
      selectedValue = options.first;
    }

    return Semantics(
      container: true,
      label: label,
      value: selectedValue == null ? null : labelBuilder(selectedValue),
      enabled: onChanged != null,
      child: DropdownButtonFormField<T>(
        key: fieldKey,
        initialValue: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          isDense: isDense,
        ),
        items: [
          for (final option in options)
            DropdownMenuItem<T>(
              value: option,
              child: Text(
                labelBuilder(option),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged == null
            ? null
            : (value) {
                if (value != null) {
                  onChanged!(value);
                }
              },
      ),
    );
  }
}

class ResponsivePair extends StatelessWidget {
  const ResponsivePair({required this.first, required this.second, super.key});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              first,
              const SizedBox(height: fieldGap),
              second,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: fieldGap),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class SpriteSheetGridSpecControls extends StatelessWidget {
  const SpriteSheetGridSpecControls({
    required this.gridSpec,
    required this.onChanged,
    super.key,
  });

  final SpriteSheetGridSpec gridSpec;
  final ValueChanged<SpriteSheetGridSpec> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
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
            initiallyExpanded: false,
            maintainState: true,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: Icon(
              Icons.tune_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.spriteSheetGridSpecTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (!gridSpec.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.spriteSheetGridSpecAdjusted,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              _gridSpecSummary(l10n, gridSpec),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.spriteSheetGridSpecDescription,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: fieldGap),
              ResponsivePair(
                first: _GridSpecNumberField(
                  label: l10n.spriteSheetGridMarginLeft,
                  value: gridSpec.marginLeft,
                  onChanged: (value) =>
                      onChanged(gridSpec.copyWith(marginLeft: value)),
                ),
                second: _GridSpecNumberField(
                  label: l10n.spriteSheetGridMarginTop,
                  value: gridSpec.marginTop,
                  onChanged: (value) =>
                      onChanged(gridSpec.copyWith(marginTop: value)),
                ),
              ),
              const SizedBox(height: fieldGap),
              ResponsivePair(
                first: _GridSpecNumberField(
                  label: l10n.spriteSheetGridMarginRight,
                  value: gridSpec.marginRight,
                  onChanged: (value) =>
                      onChanged(gridSpec.copyWith(marginRight: value)),
                ),
                second: _GridSpecNumberField(
                  label: l10n.spriteSheetGridMarginBottom,
                  value: gridSpec.marginBottom,
                  onChanged: (value) =>
                      onChanged(gridSpec.copyWith(marginBottom: value)),
                ),
              ),
              const SizedBox(height: fieldGap),
              ResponsivePair(
                first: _GridSpecNumberField(
                  label: l10n.spriteSheetGridColumnGap,
                  value: gridSpec.columnGap,
                  onChanged: (value) =>
                      onChanged(gridSpec.copyWith(columnGap: value)),
                ),
                second: _GridSpecNumberField(
                  label: l10n.spriteSheetGridRowGap,
                  value: gridSpec.rowGap,
                  onChanged: (value) =>
                      onChanged(gridSpec.copyWith(rowGap: value)),
                ),
              ),
              if (!gridSpec.isDefault) ...[
                const SizedBox(height: fieldGap),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => onChanged(
                      SpriteSheetGridSpec(
                        rows: gridSpec.rows,
                        columns: gridSpec.columns,
                      ),
                    ),
                    icon: const Icon(Icons.restart_alt),
                    label: Text(l10n.spriteSheetGridReset),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GridSpecNumberField extends StatefulWidget {
  const _GridSpecNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_GridSpecNumberField> createState() => _GridSpecNumberFieldState();
}

class _GridSpecNumberFieldState extends State<_GridSpecNumberField> {
  static const int _maxValue = 9999;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode()..addListener(_normalizeWhenUnfocused);
  }

  @override
  void didUpdateWidget(covariant _GridSpecNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) {
      return;
    }

    final currentValue = int.tryParse(_controller.text);
    if (!_focusNode.hasFocus || currentValue != widget.value) {
      _setText(widget.value);
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

  void _normalizeWhenUnfocused() {
    if (!_focusNode.hasFocus) {
      _setText(_normalizedValue(_controller.text));
    }
  }

  void _handleTextChanged(String text) {
    if (text.isEmpty) {
      return;
    }
    final value = _normalizedValue(text);
    if (value != widget.value) {
      widget.onChanged(value);
    }
  }

  void _changeBy(int delta) {
    final value = (widget.value + delta).clamp(0, _maxValue).toInt();
    _setText(value);
    if (value != widget.value) {
      widget.onChanged(value);
    }
  }

  int _normalizedValue(String text) {
    final value = int.tryParse(text) ?? widget.value;
    return value.clamp(0, _maxValue).toInt();
  }

  void _setText(int value) {
    final text = value.toString();
    if (_controller.text == text) {
      return;
    }
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);

    return Semantics(
      container: true,
      label: widget.label,
      value: '${widget.value}px',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: widget.label,
                suffixText: 'px',
                isDense: true,
              ),
              onChanged: _handleTextChanged,
              onSubmitted: (value) => _setText(_normalizedValue(value)),
            ),
          ),
          const SizedBox(width: 6),
          _GridSpecStepButton(
            tooltip: l10n.sharedDecreasePxTooltip(widget.label),
            icon: Icons.remove,
            onPressed: widget.value <= 0 ? null : () => _changeBy(-1),
          ),
          _GridSpecStepButton(
            tooltip: l10n.sharedIncreasePxTooltip(widget.label),
            icon: Icons.add,
            onPressed: widget.value >= _maxValue ? null : () => _changeBy(1),
          ),
        ],
      ),
    );
  }
}

class _GridSpecStepButton extends StatelessWidget {
  const _GridSpecStepButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 40,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class IntegerStepperField extends StatefulWidget {
  const IntegerStepperField({
    required this.label,
    required this.value,
    required this.minValue,
    required this.onChanged,
    this.maxValue,
    this.suffixText,
    this.helperText,
    this.enabled = true,
    super.key,
  });

  final String label;
  final int value;
  final int minValue;
  final int? maxValue;
  final String? suffixText;
  final String? helperText;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  State<IntegerStepperField> createState() => _IntegerStepperFieldState();
}

class _IntegerStepperFieldState extends State<IntegerStepperField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _normalizedValue.toString());
    _focusNode = FocusNode()..addListener(_normalizeWhenUnfocused);
  }

  @override
  void didUpdateWidget(covariant IntegerStepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value &&
        widget.minValue == oldWidget.minValue &&
        widget.maxValue == oldWidget.maxValue) {
      return;
    }

    final currentValue = int.tryParse(_controller.text);
    if (!_focusNode.hasFocus || currentValue != _normalizedValue) {
      _setText(_normalizedValue);
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

  int get _minValue {
    final maxValue = widget.maxValue;
    if (maxValue == null || widget.minValue <= maxValue) {
      return widget.minValue;
    }
    return maxValue;
  }

  int? get _maxValue {
    final maxValue = widget.maxValue;
    if (maxValue == null) {
      return null;
    }
    return maxValue >= widget.minValue ? maxValue : widget.minValue;
  }

  int get _normalizedValue => _normalizeValue(widget.value);

  void _normalizeWhenUnfocused() {
    if (!_focusNode.hasFocus) {
      _setText(_normalizedText(_controller.text));
    }
  }

  void _handleTextChanged(String text) {
    if (text.isEmpty) {
      return;
    }
    final value = _normalizedText(text);
    if (value != widget.value) {
      widget.onChanged(value);
    }
  }

  void _changeBy(int delta) {
    final value = _normalizeValue(widget.value + delta);
    _setText(value);
    if (value != widget.value) {
      widget.onChanged(value);
    }
  }

  int _normalizedText(String text) {
    final value = int.tryParse(text) ?? _normalizedValue;
    return _normalizeValue(value);
  }

  int _normalizeValue(int value) {
    final minValue = _minValue;
    if (value < minValue) {
      return minValue;
    }
    final maxValue = _maxValue;
    if (maxValue != null && value > maxValue) {
      return maxValue;
    }
    return value;
  }

  void _setText(int value) {
    final text = value.toString();
    if (_controller.text == text) {
      return;
    }
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final enabled = widget.enabled;

    final semanticValue =
        '$_normalizedValue${widget.suffixText == null ? '' : ' ${widget.suffixText}'}';

    return Semantics(
      container: true,
      label: widget.label,
      value: semanticValue,
      enabled: enabled,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: widget.label,
                suffixText: widget.suffixText,
                helperText: widget.helperText,
              ),
              onChanged: _handleTextChanged,
              onSubmitted: (value) => _setText(_normalizedText(value)),
            ),
          ),
          const SizedBox(width: 6),
          _GridSpecStepButton(
            tooltip: l10n.sharedDecreaseTooltip(widget.label),
            icon: Icons.remove,
            onPressed: enabled && _normalizedValue > _minValue
                ? () => _changeBy(-1)
                : null,
          ),
          _GridSpecStepButton(
            tooltip: l10n.sharedIncreaseTooltip(widget.label),
            icon: Icons.add,
            onPressed:
                enabled && (_maxValue == null || _normalizedValue < _maxValue!)
                ? () => _changeBy(1)
                : null,
          ),
        ],
      ),
    );
  }
}

String _gridSpecSummary(AppLocalizations l10n, SpriteSheetGridSpec gridSpec) {
  final parts = <String>[
    if (gridSpec.marginLeft > 0)
      l10n.spriteSheetGridMarginLeftSummary(gridSpec.marginLeft),
    if (gridSpec.marginTop > 0)
      l10n.spriteSheetGridMarginTopSummary(gridSpec.marginTop),
    if (gridSpec.marginRight > 0)
      l10n.spriteSheetGridMarginRightSummary(gridSpec.marginRight),
    if (gridSpec.marginBottom > 0)
      l10n.spriteSheetGridMarginBottomSummary(gridSpec.marginBottom),
    if (gridSpec.columnGap > 0)
      l10n.spriteSheetGridColumnGapSummary(gridSpec.columnGap),
    if (gridSpec.rowGap > 0) l10n.spriteSheetGridRowGapSummary(gridSpec.rowGap),
  ];

  if (parts.isEmpty) {
    return l10n.spriteSheetGridSpecDefaultSummary;
  }
  return parts.join(' · ');
}

class RequestDebugButton extends StatelessWidget {
  const RequestDebugButton({required this.record, super.key});

  final ImageRequestDebugRecord? record;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);

    return Tooltip(
      message: record == null
          ? l10n.requestDebugUnavailableTooltip
          : l10n.requestDebugAvailableTooltip,
      child: OutlinedButton.icon(
        onPressed: record == null
            ? null
            : () => showRequestDebugDialog(context, record!),
        icon: const Icon(Icons.bug_report_outlined),
        label: Text(l10n.requestDebugButtonLabel),
      ),
    );
  }
}

class TemplateImagePicker extends StatelessWidget {
  const TemplateImagePicker({
    required this.imagePath,
    required this.onPick,
    required this.onClear,
    this.title,
    this.pickLabel,
    this.clearTooltip,
    this.previewHeight,
    super.key,
  });

  final String? imagePath;
  final VoidCallback? onPick;
  final VoidCallback? onClear;
  final String? title;
  final String? pickLabel;
  final String? clearTooltip;
  final double? previewHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final path = imagePath;
    final resolvedTitle = title ?? l10n.templateImagePickerDefaultTitle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  path == null ? resolvedTitle : fileNameFromPath(path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.image_search_outlined),
                label: Text(
                  pickLabel ??
                      (path == null ? l10n.selectAction : l10n.replaceAction),
                ),
              ),
              IconButton(
                tooltip: clearTooltip ?? l10n.templateImagePickerClearTooltip,
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (path != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: previewHeight ?? 220,
                width: double.infinity,
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  semanticLabel: fileNameFromPath(path),
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.templateImagePickerLoadFailed),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showRequestDebugDialog(
  BuildContext context,
  ImageRequestDebugRecord record,
) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final l10n = appL10nOf(context);
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(l10n.requestDebugDialogTitle),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: SelectableText(
              record.formattedJson,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'Consolas',
                fontFamilyFallback: const ['Courier New', 'monospace'],
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: record.formattedJson));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.requestDebugCopied)));
            },
            icon: const Icon(Icons.copy_outlined),
            label: Text(l10n.copyAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.closeAction),
          ),
        ],
      );
    },
  );
}
