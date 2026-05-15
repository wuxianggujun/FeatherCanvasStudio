import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/generated_image.dart';
import '../services/image_api_client.dart';
import '../services/sprite_sheet_service.dart';
import '../theme/layout_constants.dart';
import 'common_form_widgets.dart';
import 'preview_common_widgets.dart';

part 'frame_animation_preview_parts.dart';

enum _FramePreviewMode { playback, grid }

class FrameAnimationPreviewPanel extends StatefulWidget {
  const FrameAnimationPreviewPanel({
    required this.title,
    required this.emptyMessage,
    required this.errorMessage,
    required this.debugRecord,
    required this.generatedImages,
    required this.isGenerating,
    required this.rows,
    required this.columns,
    required this.onExportSpriteSheet,
    this.labelBuilder,
    this.onRetry,
    super.key,
  });

  final String title;
  final String emptyMessage;
  final String? errorMessage;
  final ImageRequestDebugRecord? debugRecord;
  final List<GeneratedImage> generatedImages;
  final bool isGenerating;
  final int rows;
  final int columns;
  final ValueChanged<Uint8List> onExportSpriteSheet;
  final String Function(int index)? labelBuilder;
  final VoidCallback? onRetry;

  @override
  State<FrameAnimationPreviewPanel> createState() =>
      FrameAnimationPreviewPanelState();
}

class FrameAnimationPreviewPanelState
    extends State<FrameAnimationPreviewPanel> {
  static const List<int> _playbackSpeeds = <int>[80, 120, 160, 220];

  Future<SpriteSheetPreviewData>? _previewFuture;
  _FramePreviewMode _mode = _FramePreviewMode.playback;
  Timer? _playbackTimer;
  bool _isPlaying = true;
  int _selectedRow = 0;
  int _currentColumn = 0;
  int _frameDelayMs = 120;
  final Set<int> _collapsedRows = <int>{};

  @override
  void initState() {
    super.initState();
    _refreshPreviewFuture();
    _restartPlaybackTimer();
  }

  @override
  void didUpdateWidget(covariant FrameAnimationPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generatedImages != widget.generatedImages ||
        oldWidget.rows != widget.rows ||
        oldWidget.columns != widget.columns) {
      _selectedRow = _selectedRow.clamp(0, (widget.rows - 1).clamp(0, 99));
      _currentColumn = _currentColumn.clamp(
        0,
        (widget.columns - 1).clamp(0, 99),
      );
      _refreshPreviewFuture();
    }

    if (oldWidget.columns != widget.columns) {
      _currentColumn = 0;
    }

    if (oldWidget.rows != widget.rows && _selectedRow >= widget.rows) {
      _selectedRow = 0;
    }
    _collapsedRows.removeWhere((row) => row >= widget.rows);

    if (oldWidget.isGenerating != widget.isGenerating) {
      _restartPlaybackTimer();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _refreshPreviewFuture() {
    if (widget.generatedImages.isEmpty) {
      _previewFuture = null;
      return;
    }

    _previewFuture = SpriteSheetPreviewComposer.build(
      images: widget.generatedImages,
      rows: widget.rows,
      columns: widget.columns,
      sourceMode: SpriteSheetPreviewSourceMode.sheet,
    );
  }

  void _restartPlaybackTimer() {
    _playbackTimer?.cancel();
    if (!_isPlaying ||
        _mode != _FramePreviewMode.playback ||
        widget.columns <= 1) {
      return;
    }

    _playbackTimer = Timer.periodic(Duration(milliseconds: _frameDelayMs), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentColumn = (_currentColumn + 1) % widget.columns;
      });
    });
  }

  void _togglePlayback() {
    setState(() => _isPlaying = !_isPlaying);
    _restartPlaybackTimer();
  }

  void _selectMode(_FramePreviewMode mode) {
    setState(() => _mode = mode);
    _restartPlaybackTimer();
  }

  void _selectRow(int row) {
    setState(() {
      _selectedRow = row;
      _currentColumn = 0;
    });
  }

  void _selectFrameIndex(int index) {
    if (widget.columns <= 0) {
      return;
    }

    setState(() {
      _selectedRow = index ~/ widget.columns;
      _currentColumn = index % widget.columns;
    });
  }

  void _setFrameDelay(int value) {
    setState(() => _frameDelayMs = value);
    _restartPlaybackTimer();
  }

  void _toggleCollapsedRow(int row) {
    setState(() {
      _selectedRow = row;
      if (_collapsedRows.contains(row)) {
        _collapsedRows.remove(row);
      } else {
        _collapsedRows.add(row);
      }
    });
  }

  void _stepFrame(int delta) {
    if (widget.columns <= 0) {
      return;
    }

    setState(() {
      _currentColumn = (_currentColumn + delta) % widget.columns;
      if (_currentColumn < 0) {
        _currentColumn += widget.columns;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PreviewPanelShell(
      title: widget.title,
      debugRecord: widget.debugRecord,
      showDebugButton: true,
      child: _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (widget.generatedImages.isEmpty || _previewFuture == null) {
      if (widget.isGenerating) {
        return const PreviewStateSurface.loading(
          key: ValueKey('frame-preview-loading'),
          message: '正在生成 Sprite Sheet',
        );
      }

      if (widget.errorMessage != null) {
        return PreviewStateSurface.error(
          key: const ValueKey('frame-preview-error'),
          title: '生成失败',
          message: widget.errorMessage!,
          onRetry: widget.onRetry,
        );
      }

      return PreviewStateSurface.empty(
        key: const ValueKey('frame-preview-empty'),
        message: widget.emptyMessage,
      );
    }

    return FutureBuilder<SpriteSheetPreviewData>(
      key: ValueKey(
        'frame-preview-${widget.generatedImages.length}-${widget.rows}-${widget.columns}',
      ),
      future: _previewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PreviewStateSurface.loading(
            key: ValueKey('frame-preview-building'),
            message: '正在生成切片预览',
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return PreviewStateSurface.error(
            title: '预览失败',
            message: '切片预览失败：${snapshot.error ?? '没有可用的预览数据'}',
            onRetry: widget.onRetry,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FramePreviewProgressBanner(
              totalCount: widget.rows * widget.columns,
              isGenerating: widget.isGenerating,
              errorMessage: widget.errorMessage,
            ),
            const SizedBox(height: fieldGap),
            SegmentedButton<_FramePreviewMode>(
              segments: const [
                ButtonSegment<_FramePreviewMode>(
                  value: _FramePreviewMode.playback,
                  icon: Icon(Icons.play_circle_outline),
                  label: Text('切片播放'),
                ),
                ButtonSegment<_FramePreviewMode>(
                  value: _FramePreviewMode.grid,
                  icon: Icon(Icons.grid_view_outlined),
                  label: Text('网格检查'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => _selectMode(selection.single),
            ),
            const SizedBox(height: fieldGap),
            if (_mode == _FramePreviewMode.playback)
              _buildPlaybackPreview(theme, snapshot.data!)
            else
              _buildGridPreview(theme, snapshot.data!),
          ],
        );
      },
    );
  }

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
                      frameBytes: rowFrames[index],
                      aspectRatio: previewData.frameAspectRatio,
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
                label: '帧号',
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
            SizedBox(
              width: 156,
              child: OptionDropdown<int>(
                fieldKey: ValueKey('preview-speed-$_frameDelayMs'),
                label: '播放速度',
                value: _frameDelayMs,
                options: _playbackSpeeds,
                labelBuilder: (speed) => '$speed ms',
                onChanged: _setFrameDelay,
              ),
            ),
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
          '第 ${safeFrameIndex + 1} 帧 · 第 ${safeRow + 1} 行 · 第 ${safeColumn + 1} / ${previewData.columns} 列',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Text('按行检查动画轨道，按列检查动作连续性。', style: theme.textTheme.bodySmall),
        const SizedBox(height: fieldGap),
        LayoutBuilder(
          builder: (context, constraints) {
            final frameCard = _PreviewSurfaceCard(
              title: '播放帧',
              aspectRatio: previewData.frameAspectRatio,
              child: Image.memory(
                currentFrame,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
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
