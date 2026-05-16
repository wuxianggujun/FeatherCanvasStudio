import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/generated_image.dart';
import '../models/sprite_sheet_grid_spec.dart';
import '../services/image_api_client.dart';
import '../services/sprite_sheet_service.dart';
import '../theme/layout_constants.dart';
import 'common_form_widgets.dart';
import 'preview_common_widgets.dart';

part 'frame_animation_preview_parts.dart';
part 'frame_animation_preview_builders.dart';

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
    required this.gridSpec,
    required this.onExportSpriteSheet,
    this.selectedFrameIndex,
    this.onFrameSelected,
    this.onSendToGif,
    this.labelBuilder,
    this.onRetry,
    this.enablePlayback = true,
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
  final SpriteSheetGridSpec gridSpec;
  final ValueChanged<Uint8List> onExportSpriteSheet;
  final int? selectedFrameIndex;
  final ValueChanged<int>? onFrameSelected;
  final ValueChanged<SpriteSheetPreviewData>? onSendToGif;
  final String Function(int index)? labelBuilder;
  final VoidCallback? onRetry;
  final bool enablePlayback;

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
  late bool _isPlaying;
  int _selectedRow = 0;
  int _currentColumn = 0;
  int _frameDelayMs = 120;
  final Set<int> _collapsedRows = <int>{};

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.enablePlayback;
    _syncSelectedFrameIndex();
    _refreshPreviewFuture();
    _restartPlaybackTimer();
  }

  @override
  void didUpdateWidget(covariant FrameAnimationPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generatedImages != widget.generatedImages ||
        oldWidget.rows != widget.rows ||
        oldWidget.columns != widget.columns ||
        oldWidget.gridSpec != widget.gridSpec) {
      _selectedRow = _selectedRow.clamp(0, (widget.rows - 1).clamp(0, 99));
      _currentColumn = _currentColumn.clamp(
        0,
        (widget.columns - 1).clamp(0, 99),
      );
      _refreshPreviewFuture();
    }

    if (oldWidget.selectedFrameIndex != widget.selectedFrameIndex ||
        oldWidget.rows != widget.rows ||
        oldWidget.columns != widget.columns) {
      _syncSelectedFrameIndex();
    }

    if (oldWidget.columns != widget.columns &&
        widget.selectedFrameIndex == null) {
      _currentColumn = 0;
    }

    if (oldWidget.rows != widget.rows && _selectedRow >= widget.rows) {
      _selectedRow = 0;
    }
    _collapsedRows.removeWhere((row) => row >= widget.rows);

    if (oldWidget.enablePlayback != widget.enablePlayback) {
      _isPlaying = widget.enablePlayback;
    }

    if (oldWidget.isGenerating != widget.isGenerating ||
        oldWidget.enablePlayback != widget.enablePlayback) {
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
      gridSpec: widget.gridSpec,
      sourceMode: SpriteSheetPreviewSourceMode.sheet,
    );
  }

  void _syncSelectedFrameIndex() {
    final index = widget.selectedFrameIndex;
    if (index == null || widget.columns <= 0) {
      return;
    }

    final safeIndex = index.clamp(0, _frameTotal - 1).toInt();
    _selectedRow = safeIndex ~/ widget.columns;
    _currentColumn = safeIndex % widget.columns;
  }

  int get _frameTotal => (widget.rows * widget.columns).clamp(1, 9999).toInt();

  int get _currentFrameIndex {
    if (widget.columns <= 0) {
      return 0;
    }
    return (_selectedRow * widget.columns + _currentColumn)
        .clamp(0, _frameTotal - 1)
        .toInt();
  }

  void _restartPlaybackTimer() {
    _playbackTimer?.cancel();
    if (!widget.enablePlayback ||
        widget.onFrameSelected != null ||
        !_isPlaying ||
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
    if (!widget.enablePlayback) {
      return;
    }

    setState(() => _isPlaying = !_isPlaying);
    _restartPlaybackTimer();
  }

  void _selectMode(_FramePreviewMode mode) {
    setState(() => _mode = mode);
    _restartPlaybackTimer();
  }

  void _selectRow(int row) {
    final safeRow = row.clamp(0, widget.rows - 1).toInt();
    setState(() {
      _selectedRow = safeRow;
      _currentColumn = 0;
    });
    widget.onFrameSelected?.call(_currentFrameIndex);
  }

  void _selectFrameIndex(int index) {
    if (widget.columns <= 0) {
      return;
    }

    final safeIndex = index.clamp(0, _frameTotal - 1).toInt();
    setState(() {
      _selectedRow = safeIndex ~/ widget.columns;
      _currentColumn = safeIndex % widget.columns;
    });
    widget.onFrameSelected?.call(safeIndex);
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
    widget.onFrameSelected?.call(_currentFrameIndex);
  }

  void _stepFrame(int delta) {
    if (widget.columns <= 0) {
      return;
    }

    if (widget.onFrameSelected != null) {
      final nextIndex = (_currentFrameIndex + delta) % _frameTotal;
      _selectFrameIndex(nextIndex < 0 ? nextIndex + _frameTotal : nextIndex);
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
        'frame-preview-${widget.generatedImages.length}-${widget.rows}-${widget.columns}-${widget.gridSpec.toJson()}',
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
              segments: [
                ButtonSegment<_FramePreviewMode>(
                  value: _FramePreviewMode.playback,
                  icon: Icon(
                    widget.onFrameSelected == null
                        ? Icons.play_circle_outline
                        : Icons.ads_click_outlined,
                  ),
                  label: Text(widget.onFrameSelected == null ? '切片播放' : '目标选择'),
                ),
                const ButtonSegment<_FramePreviewMode>(
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
}
