part of 'frame_animation_preview_widgets.dart';

extension _FrameAnimationPreviewBuilders on FrameAnimationPreviewPanelState {
  Widget _buildGridPreview(
    ThemeData theme,
    SpriteSheetPreviewData previewData,
  ) {
    return Column(
      children: [
        for (var row = 0; row < previewData.rows; row++) ...[
          _FrameDirectionSection(
            title: '第 ${row + 1} 行',
            subtitle: '第 ${row + 1} 行 · ${previewData.columns} 列',
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
                label: isTargetSelection ? '目标帧' : '帧号',
                value: safeFrameIndex,
                options: [
                  for (
                    var index = 0;
                    index < previewData.rows * previewData.columns;
                    index++
                  )
                    index,
                ],
                labelBuilder: (index) => '第 ${index + 1} 帧',
                onChanged: _selectFrameIndex,
              ),
            ),
            SizedBox(
              width: 172,
              child: OptionDropdown<int>(
                fieldKey: ValueKey('preview-row-$safeRow'),
                label: '行号',
                value: safeRow,
                options: [for (var row = 0; row < previewData.rows; row++) row],
                labelBuilder: (row) => '第 ${row + 1} 行',
                onChanged: _selectRow,
              ),
            ),
            if (widget.enablePlayback)
              SizedBox(
                width: 156,
                child: OptionDropdown<int>(
                  fieldKey: ValueKey('preview-speed-$_frameDelayMs'),
                  label: '播放速度',
                  value: _frameDelayMs,
                  options: FrameAnimationPreviewPanelState._playbackSpeeds,
                  labelBuilder: (speed) => '$speed ms',
                  onChanged: _setFrameDelay,
                ),
              ),
            if (widget.enablePlayback)
              FilledButton.tonalIcon(
                onPressed: previewData.columns <= 1 ? null : _togglePlayback,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_outline : Icons.play_arrow,
                ),
                label: Text(_isPlaying ? '暂停' : '播放'),
              ),
            FilledButton.tonalIcon(
              onPressed: () =>
                  widget.onExportSpriteSheet(previewData.sheetBytes),
              icon: const Icon(Icons.download_outlined),
              label: const Text('导出 PNG'),
            ),
            if (widget.onSendToGif != null)
              FilledButton.tonalIcon(
                onPressed: () => widget.onSendToGif!(previewData),
                icon: const Icon(Icons.gif_box_outlined),
                label: const Text('转 GIF'),
              ),
            if (widget.onOpenInEditor != null)
              FilledButton.tonalIcon(
                onPressed: () => widget.onOpenInEditor!(previewData),
                icon: const Icon(Icons.grid_on_outlined),
                label: const Text('像素化编辑'),
              ),
            Tooltip(
              message: '上一帧',
              child: IconButton(
                onPressed: previewData.columns <= 1
                    ? null
                    : () => _stepFrame(-1),
                icon: const Icon(Icons.chevron_left),
              ),
            ),
            Tooltip(
              message: '下一帧',
              child: IconButton(
                onPressed: previewData.columns <= 1
                    ? null
                    : () => _stepFrame(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
        const SizedBox(height: fieldGap),
        Text(
          '${isTargetSelection ? '当前目标' : '当前播放'}：第 ${safeFrameIndex + 1} 帧 · 第 ${safeRow + 1} 行 · 第 ${safeColumn + 1} / ${previewData.columns} 列',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Text(
          isTargetSelection
              ? '点击右侧 Sprite Sheet 或网格切片，可以直接选择要替换的目标帧。'
              : '按行检查动画轨道，按列检查动作连续性。',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: fieldGap),
        LayoutBuilder(
          builder: (context, constraints) {
            final frameCard = _PreviewSurfaceCard(
              title: '播放帧',
              aspectRatio: previewData.frameAspectRatio,
              child: _ZoomableFramePreview(frameBytes: currentFrame),
            );
            final sheetCard = _PreviewSurfaceCard(
              title: 'Sprite Sheet',
              subtitle:
                  '${previewData.rows} 行 x ${previewData.columns} 列，来源 ${widget.generatedImages.length} 张结果图',
              aspectRatio: previewData.sheetAspectRatio,
              child: _SpriteSheetPreviewCanvas(
                previewData: previewData,
                selectedRow: safeRow,
                selectedColumn: safeColumn,
                onFrameSelected: widget.onFrameSelected == null
                    ? null
                    : _selectFrameIndex,
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
