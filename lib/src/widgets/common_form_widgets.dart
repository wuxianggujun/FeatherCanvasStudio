import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
