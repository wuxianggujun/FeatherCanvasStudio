import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sprite_sheet_grid_spec.dart';
import '../services/image_api_client.dart';
import '../theme/layout_constants.dart';
import '../utils/display_labels.dart';

class AppPanel extends StatelessWidget {
  const AppPanel({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

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
          child,
        ],
      ),
    );
  }
}

class FrameCountBadge extends StatelessWidget {
  const FrameCountBadge({required this.count, this.label = '帧', super.key});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: '共 $count $label',
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
                '$count $label',
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

    return DropdownButtonFormField<T>(
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
          initiallyExpanded: false,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(
            Icons.tune_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          title: Row(
            children: [
              Expanded(child: Text('切片校准', style: theme.textTheme.titleSmall)),
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
                    '已调整',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            _gridSpecSummary(gridSpec),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '用于处理 Sprite Sheet 外边距或格子间隔，预览、切片和替换都会按这里计算。',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: fieldGap),
            ResponsivePair(
              first: _GridSpecNumberField(
                label: '左边距',
                value: gridSpec.marginLeft,
                onChanged: (value) =>
                    onChanged(gridSpec.copyWith(marginLeft: value)),
              ),
              second: _GridSpecNumberField(
                label: '上边距',
                value: gridSpec.marginTop,
                onChanged: (value) =>
                    onChanged(gridSpec.copyWith(marginTop: value)),
              ),
            ),
            const SizedBox(height: fieldGap),
            ResponsivePair(
              first: _GridSpecNumberField(
                label: '右边距',
                value: gridSpec.marginRight,
                onChanged: (value) =>
                    onChanged(gridSpec.copyWith(marginRight: value)),
              ),
              second: _GridSpecNumberField(
                label: '下边距',
                value: gridSpec.marginBottom,
                onChanged: (value) =>
                    onChanged(gridSpec.copyWith(marginBottom: value)),
              ),
            ),
            const SizedBox(height: fieldGap),
            ResponsivePair(
              first: _GridSpecNumberField(
                label: '列间距',
                value: gridSpec.columnGap,
                onChanged: (value) =>
                    onChanged(gridSpec.copyWith(columnGap: value)),
              ),
              second: _GridSpecNumberField(
                label: '行间距',
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
                  label: const Text('重置切片校准'),
                ),
              ),
            ],
          ],
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
    return Row(
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
          tooltip: '${widget.label}减少 1px',
          icon: Icons.remove,
          onPressed: widget.value <= 0 ? null : () => _changeBy(-1),
        ),
        _GridSpecStepButton(
          tooltip: '${widget.label}增加 1px',
          icon: Icons.add,
          onPressed: widget.value >= _maxValue ? null : () => _changeBy(1),
        ),
      ],
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

String _gridSpecSummary(SpriteSheetGridSpec gridSpec) {
  final parts = <String>[
    if (gridSpec.marginLeft > 0) '左 ${gridSpec.marginLeft}px',
    if (gridSpec.marginTop > 0) '上 ${gridSpec.marginTop}px',
    if (gridSpec.marginRight > 0) '右 ${gridSpec.marginRight}px',
    if (gridSpec.marginBottom > 0) '下 ${gridSpec.marginBottom}px',
    if (gridSpec.columnGap > 0) '列间距 ${gridSpec.columnGap}px',
    if (gridSpec.rowGap > 0) '行间距 ${gridSpec.rowGap}px',
  ];

  if (parts.isEmpty) {
    return '默认：无边距 / 无间距';
  }
  return parts.join(' · ');
}

class RequestDebugButton extends StatelessWidget {
  const RequestDebugButton({required this.record, super.key});

  final ImageRequestDebugRecord? record;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: record == null ? '生成后可查看请求和返回值' : '查看请求参数和返回值',
      child: OutlinedButton.icon(
        onPressed: record == null
            ? null
            : () => showRequestDebugDialog(context, record!),
        icon: const Icon(Icons.bug_report_outlined),
        label: const Text('调试详情'),
      ),
    );
  }
}

class TemplateImagePicker extends StatelessWidget {
  const TemplateImagePicker({
    required this.imagePath,
    required this.onPick,
    required this.onClear,
    this.title = '模板图片',
    this.pickLabel,
    this.clearTooltip = '清除模板图片',
    this.previewHeight,
    super.key,
  });

  final String? imagePath;
  final VoidCallback? onPick;
  final VoidCallback? onClear;
  final String title;
  final String? pickLabel;
  final String clearTooltip;
  final double? previewHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = imagePath;

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
                  path == null ? title : fileNameFromPath(path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.image_search_outlined),
                label: Text(pickLabel ?? (path == null ? '选择' : '更换')),
              ),
              IconButton(
                tooltip: clearTooltip,
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
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('模板图片加载失败。'),
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
      final theme = Theme.of(context);
      return AlertDialog(
        title: const Text('请求调试详情'),
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
              ).showSnackBar(const SnackBar(content: Text('调试详情已复制。')));
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('复制'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      );
    },
  );
}
