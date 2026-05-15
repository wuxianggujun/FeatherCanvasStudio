import 'package:flutter/material.dart';

import '../services/image_api_client.dart';
import '../widgets/common_form_widgets.dart';

class PreviewPanelShell extends StatelessWidget {
  const PreviewPanelShell({
    required this.title,
    required this.child,
    this.debugRecord,
    this.showDebugButton = false,
    super.key,
  });

  final String title;
  final Widget child;
  final ImageRequestDebugRecord? debugRecord;
  final bool showDebugButton;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      trailing: showDebugButton
          ? RequestDebugButton(record: debugRecord)
          : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: child,
      ),
    );
  }
}

enum _PreviewStateKind { empty, loading, error }

class PreviewStateSurface extends StatelessWidget {
  const PreviewStateSurface.empty({super.key, required this.message})
    : _kind = _PreviewStateKind.empty,
      title = null,
      onRetry = null,
      retryLabel = '重试生成',
      minHeight = 420;

  const PreviewStateSurface.loading({super.key, required this.message})
    : _kind = _PreviewStateKind.loading,
      title = null,
      onRetry = null,
      retryLabel = '重试生成',
      minHeight = 420;

  const PreviewStateSurface.error({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  }) : _kind = _PreviewStateKind.error,
       retryLabel = '重试生成',
       minHeight = 420;

  final _PreviewStateKind _kind;
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isError = _kind == _PreviewStateKind.error;
    final icon = switch (_kind) {
      _PreviewStateKind.empty => Icons.image_outlined,
      _PreviewStateKind.loading => Icons.hourglass_top_outlined,
      _PreviewStateKind.error => Icons.error_outline,
    };

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? colorScheme.error : colorScheme.outlineVariant,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_kind == _PreviewStateKind.loading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ] else ...[
              Icon(
                icon,
                size: 38,
                color: isError ? colorScheme.error : colorScheme.primary,
              ),
              const SizedBox(height: 12),
            ],
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
