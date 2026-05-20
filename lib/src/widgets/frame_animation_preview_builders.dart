part of 'frame_animation_preview_widgets.dart';

extension _FrameAnimationPreviewBuilders on FrameAnimationPreviewPanelState {
  Widget _buildGridPreview(
    ThemeData theme,
    SpriteSheetPreviewData previewData,
  ) {
    final l10n = appL10nOf(context);

    return Column(
      children: [
        for (var row = 0; row < previewData.rows; row++) ...[
          _FrameDirectionSection(
            title: l10n.framePreviewRowTitle(row + 1),
            subtitle: l10n.framePreviewRowSubtitle(
              row + 1,
              previewData.columns,
            ),
            isCollapsed: _collapsedRows.contains(row),
            isSelected: row == _selectedRow,
            onToggle: () => _toggleCollapsedRow(row),
            child: _buildGridRow(theme, previewData, row),
          ),
          if (row != previewData.rows - 1) const SizedBox(height: fieldGap),
        ],
      ],
    );
  }

  Widget _buildGridRow(
    ThemeData theme,
    SpriteSheetPreviewData previewData,
    int row,
  ) {
    final l10n = appL10nOf(context);
    final rowFrames = previewData.framesForRow(row);
    final start = row * previewData.columns;
    final frameCount = rowFrames.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawWidth =
            (constraints.maxWidth - fieldGap * (frameCount - 1)) / frameCount;
        final tileWidth = rawWidth.clamp(92.0, 150.0).toDouble();

        return Wrap(
          spacing: fieldGap,
          runSpacing: fieldGap,
          children: [
            for (var index = 0; index < rowFrames.length; index++)
              SizedBox(
                width: tileWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.labelBuilder != null) ...[
                      Text(
                        widget.labelBuilder!(start + index),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                    ],
                    _SpriteSheetFrameTile(
                      key: ValueKey('sprite-frame-tile-${start + index}'),
                      frameBytes: rowFrames[index],
                      aspectRatio: previewData.frameAspectRatio,
                      semanticsLabel:
                          widget.labelBuilder?.call(start + index) ??
                          l10n.framePreviewFrameOption(start + index + 1),
                      isSelected: _currentFrameIndex == start + index,
                      onTap: () => _selectFrameIndex(start + index),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPlaybackPreview(
    ThemeData theme,
    SpriteSheetPreviewData previewData,
  ) {
    final safeRow = _selectedRow.clamp(0, previewData.rows - 1);
    final safeColumn = _currentColumn.clamp(0, previewData.columns - 1);
    final safeFrameIndex = safeRow * previewData.columns + safeColumn;
    final currentFrame = previewData.frameAt(safeRow, safeColumn);
    final isTargetSelection = widget.onFrameSelected != null;
    final l10n = appL10nOf(context);
    final frameNavigationDisabledReason = previewData.columns <= 1
        ? l10n.framePreviewPlaybackSingleFrameUnavailable
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: fieldGap,
          runSpacing: fieldGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 172,
              child: OptionDropdown<int>(
                fieldKey: ValueKey('preview-frame-$safeFrameIndex'),
                label: isTargetSelection
                    ? l10n.framePreviewTargetFrameLabel
                    : l10n.framePreviewFrameNumberLabel,
                value: safeFrameIndex,
                options: [
                  for (
                    var index = 0;
                    index < previewData.rows * previewData.columns;
                    index++
                  )
                    index,
                ],
                labelBuilder: (index) =>
                    l10n.framePreviewFrameOption(index + 1),
                onChanged: _selectFrameIndex,
              ),
            ),
            SizedBox(
              width: 172,
              child: OptionDropdown<int>(
                fieldKey: ValueKey('preview-row-$safeRow'),
                label: l10n.framePreviewRowNumberLabel,
                value: safeRow,
                options: [for (var row = 0; row < previewData.rows; row++) row],
                labelBuilder: (row) => l10n.framePreviewRowTitle(row + 1),
                onChanged: _selectRow,
              ),
            ),
            if (widget.enablePlayback && !_usesCustomPlaybackDelays)
              SizedBox(
                width: 156,
                child: OptionDropdown<int>(
                  fieldKey: ValueKey('preview-speed-$_frameDelayMs'),
                  label: l10n.framePreviewPlaybackSpeedLabel,
                  value: _frameDelayMs,
                  options: FrameAnimationPreviewPanelState._playbackSpeeds,
                  labelBuilder: (speed) => '$speed ms',
                  onChanged: _setFrameDelay,
                ),
              ),
            if (widget.enablePlayback)
              _DisabledActionSemantics(
                label: _isPlaying ? l10n.pauseAction : l10n.playAction,
                disabledReason: frameNavigationDisabledReason,
                child: FilledButton.tonalIcon(
                  onPressed: previewData.columns <= 1 ? null : _togglePlayback,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_outline : Icons.play_arrow,
                  ),
                  label: Text(_isPlaying ? l10n.pauseAction : l10n.playAction),
                ),
              ),
            FilledButton.tonalIcon(
              onPressed: () =>
                  widget.onExportSpriteSheet(previewData.sheetBytes),
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.framePreviewExportPng),
            ),
            if (widget.onSendToGif != null)
              FilledButton.tonalIcon(
                onPressed: () => widget.onSendToGif!(previewData),
                icon: const Icon(Icons.gif_box_outlined),
                label: Text(l10n.framePreviewConvertGif),
              ),
            if (widget.onOpenInEditor != null)
              FilledButton.tonalIcon(
                onPressed: () => widget.onOpenInEditor!(previewData),
                icon: const Icon(Icons.grid_on_outlined),
                label: Text(l10n.framePreviewPixelEdit),
              ),
            Tooltip(
              message: l10n.framePreviewPreviousFrameTooltip,
              child: _DisabledActionSemantics(
                label: l10n.framePreviewPreviousFrameTooltip,
                disabledReason: frameNavigationDisabledReason,
                child: IconButton(
                  onPressed: previewData.columns <= 1
                      ? null
                      : () => _stepFrame(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
              ),
            ),
            Tooltip(
              message: l10n.framePreviewNextFrameTooltip,
              child: _DisabledActionSemantics(
                label: l10n.framePreviewNextFrameTooltip,
                disabledReason: frameNavigationDisabledReason,
                child: IconButton(
                  onPressed: previewData.columns <= 1
                      ? null
                      : () => _stepFrame(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: fieldGap),
        Text(
          l10n.framePreviewCurrentStatus(
            isTargetSelection
                ? l10n.framePreviewCurrentTargetPrefix
                : l10n.framePreviewCurrentPlaybackPrefix,
            safeFrameIndex + 1,
            safeRow + 1,
            safeColumn + 1,
            previewData.columns,
          ),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Text(
          isTargetSelection
              ? l10n.framePreviewTargetSelectionHint
              : l10n.framePreviewPlaybackHint,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: fieldGap),
        LayoutBuilder(
          builder: (context, constraints) {
            final frameCard = _PreviewSurfaceCard(
              title: l10n.framePreviewPlaybackFrameTitle,
              aspectRatio: previewData.frameAspectRatio,
              child: _ZoomableFramePreview(frameBytes: currentFrame),
            );
            final sheetCard = _PreviewSurfaceCard(
              title: l10n.framePreviewSpriteSheetTitle,
              subtitle: l10n.framePreviewSpriteSheetSubtitle(
                previewData.rows,
                previewData.columns,
                widget.generatedImages.length,
              ),
              aspectRatio: previewData.sheetAspectRatio,
              child: _SpriteSheetPreviewCanvas(
                previewData: previewData,
                selectedRow: safeRow,
                selectedColumn: safeColumn,
                onFrameSelected: _selectFrameIndex,
              ),
            );

            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  frameCard,
                  const SizedBox(height: fieldGap),
                  sheetCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: frameCard),
                const SizedBox(width: fieldGap),
                Expanded(flex: 7, child: sheetCard),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DisabledActionSemantics extends StatelessWidget {
  const _DisabledActionSemantics({
    required this.label,
    required this.disabledReason,
    required this.child,
  });

  final String label;
  final String? disabledReason;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (disabledReason == null) {
      return child;
    }

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      value: disabledReason,
      button: true,
      enabled: false,
      child: child,
    );
  }
}
