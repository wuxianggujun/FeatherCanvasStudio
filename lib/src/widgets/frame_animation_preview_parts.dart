part of 'frame_animation_preview_widgets.dart';

class _FramePreviewProgressBanner extends StatelessWidget {
  const _FramePreviewProgressBanner({
    required this.totalCount,
    required this.isGenerating,
    required this.errorMessage,
  });

  final int totalCount;
  final bool isGenerating;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;
    final message = hasError
        ? 'Sprite Sheet 生成失败，可调整参数后重试。$errorMessage'
        : isGenerating
        ? '正在生成 1 张 Sprite Sheet，完成后会按 $totalCount 格切片预览。'
        : '已生成 1 张 Sprite Sheet，并按 $totalCount 格切片预览。';

    return _FramePreviewStatusBanner(message: message, isError: hasError);
  }
}

class _FramePreviewStatusBanner extends StatelessWidget {
  const _FramePreviewStatusBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer
            : colorScheme.secondaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.downloading_outlined,
            color: foreground,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSurfaceCard extends StatelessWidget {
  const _PreviewSurfaceCard({
    required this.title,
    required this.aspectRatio,
    required this.child,
    this.subtitle,
  });

  final String title;
  final double aspectRatio;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(fieldGap),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: fieldGap),
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _SpriteSheetPreviewCanvas extends StatelessWidget {
  const _SpriteSheetPreviewCanvas({
    required this.previewData,
    required this.selectedRow,
    required this.selectedColumn,
  });

  final SpriteSheetPreviewData previewData;
  final int selectedRow;
  final int selectedColumn;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            previewData.sheetBytes,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
          ),
          CustomPaint(
            painter: _SpriteSheetHighlightPainter(
              previewData: previewData,
              selectedRow: selectedRow,
              selectedColumn: selectedColumn,
              rowColor: colorScheme.primary.withValues(alpha: 0.18),
              rowBorderColor: colorScheme.primary,
              cellBorderColor: colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpriteSheetHighlightPainter extends CustomPainter {
  const _SpriteSheetHighlightPainter({
    required this.previewData,
    required this.selectedRow,
    required this.selectedColumn,
    required this.rowColor,
    required this.rowBorderColor,
    required this.cellBorderColor,
  });

  final SpriteSheetPreviewData previewData;
  final int selectedRow;
  final int selectedColumn;
  final Color rowColor;
  final Color rowBorderColor;
  final Color cellBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final safeRow = selectedRow.clamp(0, previewData.rows - 1);
    final safeColumn = selectedColumn.clamp(0, previewData.columns - 1);
    final rowRect = previewData.rowRectForDisplay(size, safeRow);
    final cellRect = previewData.cellRectForDisplay(size, safeRow, safeColumn);

    final rowFillPaint = Paint()..color = rowColor;
    final rowBorderPaint = Paint()
      ..color = rowBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final cellBorderPaint = Paint()
      ..color = cellBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(rowRect, rowFillPaint);
    canvas.drawRect(rowRect, rowBorderPaint);
    canvas.drawRect(cellRect.deflate(1), cellBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpriteSheetHighlightPainter oldDelegate) {
    return previewData != oldDelegate.previewData ||
        selectedRow != oldDelegate.selectedRow ||
        selectedColumn != oldDelegate.selectedColumn ||
        rowColor != oldDelegate.rowColor ||
        rowBorderColor != oldDelegate.rowBorderColor ||
        cellBorderColor != oldDelegate.cellBorderColor;
  }
}

class _FrameDirectionSection extends StatelessWidget {
  const _FrameDirectionSection({
    required this.title,
    required this.subtitle,
    required this.isCollapsed,
    required this.isSelected,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final bool isCollapsed;
  final bool isSelected;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: fieldGap,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    isCollapsed
                        ? Icons.keyboard_arrow_right
                        : Icons.keyboard_arrow_down,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isCollapsed) ...[
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Padding(padding: const EdgeInsets.all(fieldGap), child: child),
          ],
        ],
      ),
    );
  }
}

class _SpriteSheetFrameTile extends StatelessWidget {
  const _SpriteSheetFrameTile({
    required this.frameBytes,
    required this.aspectRatio,
  });

  final Uint8List frameBytes;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Image.memory(
            frameBytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
