import 'package:flutter/material.dart';

import '../theme/layout_constants.dart';
import '../widgets/common_form_widgets.dart';

class LocalSettingsPanel extends StatelessWidget {
  const LocalSettingsPanel({
    required this.apiConfigCount,
    required this.imageLibraryCount,
    required this.generatedPreviewCount,
    required this.onOpenApiSettings,
    required this.onResetToDefaults,
    super.key,
  });

  final int apiConfigCount;
  final int imageLibraryCount;
  final int generatedPreviewCount;
  final VoidCallback onOpenApiSettings;
  final VoidCallback onResetToDefaults;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        AppPanel(
          title: '本地状态',
          child: Column(
            children: [
              _SettingsSummaryRow(
                icon: Icons.tune_outlined,
                label: '接口配置',
                value: '$apiConfigCount 个',
              ),
              const Divider(height: 20),
              _SettingsSummaryRow(
                icon: Icons.collections_outlined,
                label: '作品库记录',
                value: '$imageLibraryCount 条',
              ),
              const Divider(height: 20),
              _SettingsSummaryRow(
                icon: Icons.preview_outlined,
                label: '当前预览结果',
                value: '$generatedPreviewCount 张',
              ),
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: '配置入口',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '接口地址、密钥和模型列表统一在接口配置页维护。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: fieldGap),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onOpenApiSettings,
                  icon: const Icon(Icons.tune_outlined),
                  label: const Text('打开接口配置'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: sectionGap),
        AppPanel(
          title: '恢复默认',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '仅在需要重新开始配置时使用。恢复前会再次确认。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: fieldGap),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: onResetToDefaults,
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('恢复默认表单'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSummaryRow extends StatelessWidget {
  const _SettingsSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
