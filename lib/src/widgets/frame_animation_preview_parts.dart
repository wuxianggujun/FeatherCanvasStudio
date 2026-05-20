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
    final l10n = appL10nOf(context);
    final hasError = errorMessage != null;
    final message = hasError
        ? l10n.framePreviewProgressFailed(errorMessage!)
        : isGenerating
        ? l10n.framePreviewProgressGenerating(totalCount)
        : l10n.framePreviewProgressReady(totalCount);

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

class _ZoomableFramePreview extends StatefulWidget {
  const _ZoomableFramePreview({required this.frameBytes});

  final Uint8List frameBytes;

  @override
  State<_ZoomableFramePreview> createState() => _ZoomableFramePreviewState();
}

class _ZoomableFramePreviewState extends State<_ZoomableFramePreview> {
  static const double _minScale = 1;
  static const double _maxScale = 8;
  static const double _scaleStep = 1.25;

  late final TransformationController _transformationController;
  double _scale = _minScale;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _syncScale() {
    final nextScale = _transformationController.value
        .getMaxScaleOnAxis()
        .clamp(_minScale, _maxScale)
        .toDouble();
    if ((nextScale - _scale).abs() < 0.01) {
      return;
    }
    setState(() => _scale = nextScale);
  }

  void _setScale(double value) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final safeCurrentScale = currentScale <= 0 ? _minScale : currentScale;
    final nextScale = value.clamp(_minScale, _maxScale).toDouble();
    final scaleDelta = nextScale / safeCurrentScale;
    final nextMatrix = Matrix4.copy(_transformationController.value)
      ..scaleByDouble(scaleDelta, scaleDelta, scaleDelta, 1);

    _transformationController.value = nextMatrix;
    setState(() => _scale = nextScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _scale = _minScale);
  }

  void _reserveMouseWheelSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.scrollDelta.dy == 0) {
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox.expand(
      child: Semantics(
        label: l10n.framePreviewPlaybackFrameTitle,
        image: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: Listener(
                onPointerSignal: _reserveMouseWheelSignal,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  boundaryMargin: const EdgeInsets.all(96),
                  clipBehavior: Clip.hardEdge,
                  trackpadScrollCausesScale: true,
                  onInteractionUpdate: (_) => _syncScale(),
                  onInteractionEnd: (_) => _syncScale(),
                  child: SizedBox.expand(
                    child: Center(
                      child: Image.memory(
                        widget.frameBytes,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FrameZoomButton(
                      tooltip: l10n.framePreviewZoomOutTooltip,
                      icon: Icons.remove,
                      onPressed: _scale <= _minScale + 0.01
                          ? null
                          : () => _setScale(_scale / _scaleStep),
                    ),
                    _FrameZoomButton(
                      tooltip: l10n.framePreviewZoomInTooltip,
                      icon: Icons.add,
                      onPressed: _scale >= _maxScale - 0.01
                          ? null
                          : () => _setScale(_scale * _scaleStep),
                    ),
                    _FrameZoomButton(
                      tooltip: l10n.framePreviewResetZoomTooltip,
                      icon: Icons.fit_screen_outlined,
                      onPressed: _resetZoom,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  child: Text(
                    '${(_scale * 100).round()}%',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameZoomButton extends StatelessWidget {
  const _FrameZoomButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: tooltip,
      button: true,
      enabled: onPressed != null,
      child: SizedBox.square(
        dimension: 34,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _SpriteSheetPreviewCanvas extends StatelessWidget {
  const _SpriteSheetPreviewCanvas({
    required this.previewData,
    required this.selectedRow,
    required this.selectedColumn,
    this.onFrameSelected,
  });

  final SpriteSheetPreviewData previewData;
  final int selectedRow;
  final int selectedColumn;
  final ValueChanged<int>? onFrameSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appL10nOf(context);
    final selectedFrame =
        selectedRow * previewData.columns + selectedColumn + 1;
    final canvasLabel =
        '${l10n.framePreviewSpriteSheetTitle} · '
        '${l10n.framePreviewCurrentStatus(l10n.framePreviewCurrentPlaybackPrefix, selectedFrame, selectedRow + 1, selectedColumn + 1, previewData.columns)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvas = Semantics(
          label: canvasLabel,
          image: true,
          button: onFrameSelected != null,
          enabled: true,
          child: SizedBox(
            key: const ValueKey('sprite-sheet-preview-canvas'),
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
          ),
        );

        if (onFrameSelected == null) {
          return canvas;
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final index = _frameIndexAtPosition(
                Size(constraints.maxWidth, constraints.maxHeight),
                details.localPosition,
              );
              if (index != null) {
                onFrameSelected!(index);
              }
            },
            child: canvas,
          ),
        );
      },
    );
  }

  int? _frameIndexAtPosition(Size size, Offset position) {
    for (var row = 0; row < previewData.rows; row++) {
      for (var column = 0; column < previewData.columns; column++) {
        if (previewData
            .cellRectForDisplay(size, row, column)
            .contains(position)) {
          return row * previewData.columns + column;
        }
      }
    }
    return null;
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
    super.key,
    required this.frameBytes,
    required this.aspectRatio,
    required this.semanticsLabel,
    this.isSelected = false,
    this.onTap,
  });

  final Uint8List frameBytes;
  final double aspectRatio;
  final String semanticsLabel;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: semanticsLabel,
      image: true,
      button: onTap != null,
      selected: isSelected,
      enabled: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Image.memory(
                    frameBytes,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
