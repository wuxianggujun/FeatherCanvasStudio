import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;

import '../../l10n/app_l10n.dart';
import '../../theme/layout_constants.dart';
import '../common_form_widgets.dart';
import '../layout_navigation_widgets.dart';

enum PixelArtTool { brush, eraser, eyedropper }

typedef PixelArtSaveCallback =
    Future<void> Function(Uint8List pngBytes, int width, int height);

class PixelArtWorkspace extends StatefulWidget {
  const PixelArtWorkspace({
    required this.onSaveToLibrary,
    this.onExportPng,
    this.isFocusMode = false,
    this.onFocusModeChanged,
    this.historyControls,
    super.key,
  });

  final PixelArtSaveCallback onSaveToLibrary;
  final PixelArtSaveCallback? onExportPng;
  final bool isFocusMode;
  final ValueChanged<bool>? onFocusModeChanged;
  final Widget? historyControls;

  @override
  State<PixelArtWorkspace> createState() => _PixelArtWorkspaceState();
}

class _PixelArtWorkspaceState extends State<PixelArtWorkspace> {
  static const int _minCanvasDimension = 1;
  static const int _maxCanvasDimension = 512;
  static const List<Color> _palette = <Color>[
    Color(0xFF111827),
    Color(0xFFFFFFFF),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFFACC15),
    Color(0xFF22C55E),
    Color(0xFF14B8A6),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF78350F),
    Color(0xFF94A3B8),
  ];
  static const int _transparentPixel = 0x00000000;
  static const int _maxHistoryLength = 40;
  static const Duration _canvasPanLongPressDelay = Duration(milliseconds: 500);
  static const double _canvasPanMoveTolerance = 8;

  int _canvasWidth = 32;
  int _canvasHeight = 32;
  int _draftCanvasWidth = 32;
  int _draftCanvasHeight = 32;
  int _brushSize = 1;
  double _cellSize = 24;
  Color _selectedColor = _palette.first;
  PixelArtTool _tool = PixelArtTool.brush;
  List<int> _pixels = List<int>.filled(32 * 32, _transparentPixel);
  final List<List<int>> _undoStack = <List<int>>[];
  final List<List<int>> _redoStack = <List<int>>[];
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final FocusNode _canvasFocusNode = FocusNode(debugLabel: 'pixel_art_canvas');
  bool _isSaving = false;
  bool _isExporting = false;
  bool _isDrawingStroke = false;
  bool _isCanvasPanning = false;
  bool _suppressCanvasTapAfterPan = false;
  Offset? _canvasPointerDownGlobalPosition;
  Offset? _canvasPointerDownLocalPosition;
  Offset? _lastCanvasPanGlobalPosition;
  Timer? _canvasLongPressTimer;
  bool _canvasPointerMovedBeyondTapThreshold = false;
  bool _canvasTapHandled = false;
  int _keyboardCursorX = 0;
  int _keyboardCursorY = 0;

  @override
  void dispose() {
    _canvasLongPressTimer?.cancel();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _canvasFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final onFocusModeChanged = widget.onFocusModeChanged;
    final focusButton = onFocusModeChanged == null
        ? null
        : IconButton.filledTonal(
            tooltip: widget.isFocusMode
                ? l10n.pixelArtExitFocusTooltip
                : l10n.pixelArtEnterFocusTooltip,
            onPressed: () => onFocusModeChanged(!widget.isFocusMode),
            icon: Icon(
              widget.isFocusMode
                  ? Icons.fullscreen_exit_outlined
                  : Icons.fullscreen_outlined,
            ),
          );
    final trailingChildren = <Widget>[
      if (widget.historyControls != null) widget.historyControls!,
      ?focusButton,
    ];

    return WorkspacePage(
      title: l10n.navPixelArtEditor,
      description: l10n.pixelArtWorkspaceDescription,
      compactHeader: widget.isFocusMode,
      trailing: trailingChildren.isEmpty
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: trailingChildren,
            ),
      children: [
        ResponsiveWorkspaceSplit(
          storageKey: 'pixel_art',
          controlsWidth: widget.isFocusMode ? 320 : 392,
          minControlsWidth: widget.isFocusMode ? 280 : 304,
          maxControlsWidth: widget.isFocusMode ? 420 : 520,
          controls: _buildControls(context),
          preview: _buildCanvasPanel(context),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10nOf(context);
    final hasPendingSize =
        _draftCanvasWidth != _canvasWidth ||
        _draftCanvasHeight != _canvasHeight;
    final canUndo = _undoStack.isNotEmpty;
    final canRedo = _redoStack.isNotEmpty;

    return AppPanel(
      title: l10n.pixelArtToolsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.pixelArtCanvasSizeTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ResponsivePair(
            first: KeyedSubtree(
              key: const ValueKey('pixel-art-width-control'),
              child: IntegerStepperField(
                label: l10n.pixelArtCanvasWidthLabel,
                value: _draftCanvasWidth,
                minValue: _minCanvasDimension,
                maxValue: _maxCanvasDimension,
                suffixText: 'px',
                helperText: '$_minCanvasDimension-$_maxCanvasDimension px',
                onChanged: (value) => setState(() {
                  _draftCanvasWidth = value;
                }),
              ),
            ),
            second: KeyedSubtree(
              key: const ValueKey('pixel-art-height-control'),
              child: IntegerStepperField(
                label: l10n.pixelArtCanvasHeightLabel,
                value: _draftCanvasHeight,
                minValue: _minCanvasDimension,
                maxValue: _maxCanvasDimension,
                suffixText: 'px',
                helperText: l10n.pixelArtApplyAfterChangeHelper,
                onChanged: (value) => setState(() {
                  _draftCanvasHeight = value;
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('pixel-art-apply-canvas-size'),
              onPressed: hasPendingSize ? _applyDraftCanvasSize : null,
              icon: const Icon(Icons.check_outlined),
              label: Text(l10n.pixelArtApplyCanvasSize),
            ),
          ),
          const SizedBox(height: fieldGap),
          SegmentedButton<PixelArtTool>(
            segments: [
              ButtonSegment(
                value: PixelArtTool.brush,
                icon: const Icon(Icons.brush_outlined),
                label: Text(l10n.pixelArtBrushTool),
              ),
              ButtonSegment(
                value: PixelArtTool.eraser,
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text(l10n.pixelArtEraserTool),
              ),
              ButtonSegment(
                value: PixelArtTool.eyedropper,
                icon: const Icon(Icons.colorize_outlined),
                label: Text(l10n.pixelArtEyedropperTool),
              ),
            ],
            selected: {_tool},
            onSelectionChanged: (selection) {
              setState(() => _tool = selection.single);
            },
          ),
          const SizedBox(height: fieldGap),
          IntegerStepperField(
            label: l10n.pixelArtBrushSizeLabel,
            value: _brushSize,
            minValue: 1,
            maxValue: 8,
            suffixText: l10n.pixelArtCellSuffix,
            helperText: l10n.pixelArtBrushSizeHelper,
            onChanged: (value) => setState(() => _brushSize = value),
          ),
          const SizedBox(height: fieldGap),
          Text(l10n.pixelArtColorTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in _palette)
                _ColorSwatchButton(
                  color: color,
                  selected: color.toARGB32() == _selectedColor.toARGB32(),
                  onTap: () => setState(() {
                    _selectedColor = color;
                    _tool = PixelArtTool.brush;
                  }),
                ),
            ],
          ),
          const SizedBox(height: fieldGap),
          Text(l10n.pixelArtZoomTitle, style: theme.textTheme.titleSmall),
          Slider(
            value: _cellSize,
            min: 8,
            max: 72,
            divisions: 64,
            label: '${_cellSize.round()} px',
            onChanged: (value) => setState(() => _cellSize = value),
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: Semantics(
              container: true,
              label: l10n.historyUndo,
              value: canUndo ? null : l10n.historyUndoUnavailable,
              button: true,
              enabled: canUndo,
              child: OutlinedButton.icon(
                onPressed: canUndo ? _undo : null,
                icon: const Icon(Icons.undo_outlined),
                label: Text(l10n.historyUndo),
              ),
            ),
            second: Semantics(
              container: true,
              label: l10n.historyRedo,
              value: canRedo ? null : l10n.historyRedoUnavailable,
              button: true,
              enabled: canRedo,
              child: OutlinedButton.icon(
                onPressed: canRedo ? _redo : null,
                icon: const Icon(Icons.redo_outlined),
                label: Text(l10n.historyRedo),
              ),
            ),
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: OutlinedButton.icon(
              onPressed: _newCanvas,
              icon: const Icon(Icons.note_add_outlined),
              label: Text(l10n.pixelArtNewBlankCanvas),
            ),
            second: OutlinedButton.icon(
              onPressed: _clearCanvas,
              icon: const Icon(Icons.backspace_outlined),
              label: Text(l10n.pixelArtClearCanvas),
            ),
          ),
          const SizedBox(height: fieldGap),
          PrimaryActionButton(
            onPressed: _isSaving ? null : () => _saveToLibrary(),
            icon: Icons.collections_bookmark_outlined,
            label: l10n.pixelArtSaveToLibrary,
            busyLabel: l10n.pixelArtSaving,
            isBusy: _isSaving,
          ),
          if (widget.onExportPng != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('pixel-art-export-png'),
                onPressed: _isExporting ? null : () => _exportPng(),
                icon: _isExporting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined),
                label: Text(
                  _isExporting
                      ? l10n.pixelArtExporting
                      : l10n.pixelArtExportPng,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCanvasPanel(BuildContext context) {
    final theme = Theme.of(context);
    final canvasWidth = _canvasWidth * _cellSize;
    final canvasHeight = _canvasHeight * _cellSize;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final panelHeight = widget.isFocusMode
        ? math.max(640.0, viewportHeight - 128)
        : math.max(640.0, viewportHeight - 220);

    return AppPanel(
      title: appL10nOf(context).pixelArtCanvasTitle,
      trailing: Text(
        '$_canvasWidth x $_canvasHeight',
        style: theme.textTheme.labelLarge,
      ),
      child: SizedBox(
        height: panelHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              key: const ValueKey('pixel-art-canvas-panel'),
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerLowest,
              child: Scrollbar(
                controller: _verticalScrollController,
                thumbVisibility: true,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.vertical,
                child: SingleChildScrollView(
                  controller: _verticalScrollController,
                  child: Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                        notification.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Semantics(
                              label: appL10nOf(context)
                                  .pixelArtCanvasSemanticLabel(
                                    _canvasWidth,
                                    _canvasHeight,
                                    _keyboardCursorX + 1,
                                    _keyboardCursorY + 1,
                                  ),
                              image: true,
                              button: true,
                              onTap: _paintAtKeyboardCursor,
                              child: Focus(
                                focusNode: _canvasFocusNode,
                                onKeyEvent: _handleCanvasKeyEvent,
                                child: SizedBox(
                                  width: canvasWidth,
                                  height: canvasHeight,
                                  child: Listener(
                                    behavior: HitTestBehavior.opaque,
                                    onPointerDown: (event) {
                                      _canvasFocusNode.requestFocus();
                                      _isDrawingStroke = false;
                                      _suppressCanvasTapAfterPan = false;
                                      _canvasTapHandled = false;
                                      _canvasPointerMovedBeyondTapThreshold =
                                          false;
                                      _canvasPointerDownGlobalPosition =
                                          event.position;
                                      _canvasPointerDownLocalPosition =
                                          event.localPosition;
                                      _lastCanvasPanGlobalPosition =
                                          event.position;
                                      _canvasLongPressTimer?.cancel();
                                      _canvasLongPressTimer = Timer(
                                        _canvasPanLongPressDelay,
                                        () {
                                          if (!mounted ||
                                              _canvasPointerDownGlobalPosition ==
                                                  null) {
                                            return;
                                          }
                                          _isCanvasPanning = true;
                                          _isDrawingStroke = false;
                                        },
                                      );
                                    },
                                    onPointerMove: (event) {
                                      if (!_isCanvasPanning) {
                                        final pointerDownPosition =
                                            _canvasPointerDownGlobalPosition;
                                        if (pointerDownPosition != null &&
                                            (event.position -
                                                        pointerDownPosition)
                                                    .distance >
                                                _canvasPanMoveTolerance) {
                                          _canvasLongPressTimer?.cancel();
                                          _canvasLongPressTimer = null;
                                        }
                                        if (pointerDownPosition != null &&
                                            (event.position -
                                                        pointerDownPosition)
                                                    .distance >
                                                4) {
                                          _canvasPointerMovedBeyondTapThreshold =
                                              true;
                                        }
                                        return;
                                      }
                                      final previous =
                                          _lastCanvasPanGlobalPosition;
                                      if (previous == null) {
                                        _lastCanvasPanGlobalPosition =
                                            event.position;
                                        return;
                                      }
                                      _scrollCanvasBy(
                                        event.position - previous,
                                      );
                                      _suppressCanvasTapAfterPan = true;
                                      _lastCanvasPanGlobalPosition =
                                          event.position;
                                    },
                                    onPointerUp: (_) {
                                      final didPan =
                                          _isCanvasPanning ||
                                          _suppressCanvasTapAfterPan;
                                      if (!didPan &&
                                          !_canvasPointerMovedBeyondTapThreshold &&
                                          !_canvasTapHandled) {
                                        final localPosition =
                                            _canvasPointerDownLocalPosition;
                                        if (localPosition != null) {
                                          _canvasTapHandled = true;
                                          _moveKeyboardCursorTo(localPosition);
                                          _paintAt(localPosition);
                                        }
                                      }
                                      _canvasLongPressTimer?.cancel();
                                      _canvasLongPressTimer = null;
                                      _canvasPointerDownGlobalPosition = null;
                                      _canvasPointerDownLocalPosition = null;
                                      _isCanvasPanning = false;
                                      _suppressCanvasTapAfterPan = didPan;
                                      _lastCanvasPanGlobalPosition = null;
                                    },
                                    onPointerCancel: (_) {
                                      _canvasLongPressTimer?.cancel();
                                      _canvasLongPressTimer = null;
                                      _canvasPointerDownGlobalPosition = null;
                                      _canvasPointerDownLocalPosition = null;
                                      _isCanvasPanning = false;
                                      _lastCanvasPanGlobalPosition = null;
                                      _isDrawingStroke = false;
                                    },
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onPanStart: (details) {
                                        if (_isCanvasPanning) {
                                          return;
                                        }
                                        _isDrawingStroke = false;
                                        _paintAt(details.localPosition);
                                      },
                                      onPanUpdate: (details) {
                                        if (_isCanvasPanning) {
                                          return;
                                        }
                                        _paintAt(details.localPosition);
                                      },
                                      onPanEnd: (_) {
                                        _isDrawingStroke = false;
                                      },
                                      onTapDown: (details) {
                                        _moveKeyboardCursorTo(
                                          details.localPosition,
                                        );
                                      },
                                      onTapUp: (details) {
                                        if (_isCanvasPanning ||
                                            _suppressCanvasTapAfterPan ||
                                            _canvasTapHandled) {
                                          _suppressCanvasTapAfterPan = false;
                                          return;
                                        }
                                        _canvasTapHandled = true;
                                        _isDrawingStroke = false;
                                        _moveKeyboardCursorTo(
                                          details.localPosition,
                                        );
                                        _paintAt(details.localPosition);
                                        _isDrawingStroke = false;
                                      },
                                      onTapCancel: () {
                                        _isDrawingStroke = false;
                                      },
                                      child: CustomPaint(
                                        key: const ValueKey('pixel-art-canvas'),
                                        painter: _PixelArtPainter(
                                          pixels: _pixels,
                                          canvasWidth: _canvasWidth,
                                          canvasHeight: _canvasHeight,
                                          cellSize: _cellSize,
                                          gridColor:
                                              theme.colorScheme.outlineVariant,
                                          checkerLightColor:
                                              theme.brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF2A2D35)
                                              : const Color(0xFFFFFFFF),
                                          checkerDarkColor:
                                              theme.brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF1F222A)
                                              : const Color(0xFFE5E7EB),
                                          cursorX: _keyboardCursorX,
                                          cursorY: _keyboardCursorY,
                                          cursorColor:
                                              theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _applyDraftCanvasSize() {
    _resizeCanvas(width: _draftCanvasWidth, height: _draftCanvasHeight);
  }

  void _resizeCanvas({int? width, int? height}) {
    final nextWidth = width ?? _canvasWidth;
    final nextHeight = height ?? _canvasHeight;
    if (nextWidth == _canvasWidth && nextHeight == _canvasHeight) {
      return;
    }

    _pushUndoSnapshot();
    final nextPixels = List<int>.filled(
      nextWidth * nextHeight,
      _transparentPixel,
    );
    final copyWidth = math.min(_canvasWidth, nextWidth);
    final copyHeight = math.min(_canvasHeight, nextHeight);
    for (var y = 0; y < copyHeight; y++) {
      for (var x = 0; x < copyWidth; x++) {
        nextPixels[y * nextWidth + x] = _pixels[y * _canvasWidth + x];
      }
    }

    setState(() {
      _canvasWidth = nextWidth;
      _canvasHeight = nextHeight;
      _draftCanvasWidth = nextWidth;
      _draftCanvasHeight = nextHeight;
      _pixels = nextPixels;
      _keyboardCursorX = _keyboardCursorX.clamp(0, nextWidth - 1);
      _keyboardCursorY = _keyboardCursorY.clamp(0, nextHeight - 1);
    });
  }

  KeyEventResult _handleCanvasKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _moveKeyboardCursorBy(dx: -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _moveKeyboardCursorBy(dx: 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveKeyboardCursorBy(dy: -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveKeyboardCursorBy(dy: 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _paintAtKeyboardCursor();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveKeyboardCursorBy({int dx = 0, int dy = 0}) {
    final nextX = (_keyboardCursorX + dx).clamp(0, _canvasWidth - 1);
    final nextY = (_keyboardCursorY + dy).clamp(0, _canvasHeight - 1);
    if (nextX == _keyboardCursorX && nextY == _keyboardCursorY) {
      return;
    }
    setState(() {
      _keyboardCursorX = nextX;
      _keyboardCursorY = nextY;
    });
  }

  void _moveKeyboardCursorTo(Offset position) {
    final nextX = (position.dx / _cellSize).floor().clamp(0, _canvasWidth - 1);
    final nextY = (position.dy / _cellSize).floor().clamp(0, _canvasHeight - 1);
    if (nextX == _keyboardCursorX && nextY == _keyboardCursorY) {
      return;
    }
    setState(() {
      _keyboardCursorX = nextX;
      _keyboardCursorY = nextY;
    });
  }

  void _paintAtKeyboardCursor() {
    _isDrawingStroke = false;
    _paintAt(
      Offset(
        (_keyboardCursorX + 0.5) * _cellSize,
        (_keyboardCursorY + 0.5) * _cellSize,
      ),
    );
    _isDrawingStroke = false;
  }

  void _scrollCanvasBy(Offset delta) {
    if (_horizontalScrollController.hasClients) {
      final position = _horizontalScrollController.position;
      final nextOffset = (position.pixels - delta.dx)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      _horizontalScrollController.jumpTo(nextOffset);
    }
    if (_verticalScrollController.hasClients) {
      final position = _verticalScrollController.position;
      final nextOffset = (position.pixels - delta.dy)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      _verticalScrollController.jumpTo(nextOffset);
    }
  }

  void _paintAt(Offset position) {
    final x = (position.dx / _cellSize).floor();
    final y = (position.dy / _cellSize).floor();
    if (x < 0 || y < 0 || x >= _canvasWidth || y >= _canvasHeight) {
      return;
    }

    if (_tool == PixelArtTool.eyedropper) {
      final colorValue = _pixels[y * _canvasWidth + x];
      if (colorValue != _transparentPixel) {
        setState(() {
          _selectedColor = Color(colorValue);
          _tool = PixelArtTool.brush;
        });
      }
      return;
    }

    if (!_isDrawingStroke) {
      _pushUndoSnapshot();
      _isDrawingStroke = true;
    }

    final nextPixels = List<int>.of(_pixels);
    final color = _tool == PixelArtTool.eraser
        ? _transparentPixel
        : _selectedColor.toARGB32();
    final radius = (_brushSize - 1) ~/ 2;
    final evenOffset = _brushSize.isEven ? 1 : 0;
    var changed = false;

    for (var py = y - radius; py <= y + radius + evenOffset; py++) {
      for (var px = x - radius; px <= x + radius + evenOffset; px++) {
        if (px < 0 || py < 0 || px >= _canvasWidth || py >= _canvasHeight) {
          continue;
        }
        final index = py * _canvasWidth + px;
        if (nextPixels[index] != color) {
          nextPixels[index] = color;
          changed = true;
        }
      }
    }

    if (changed) {
      setState(() => _pixels = nextPixels);
    }
  }

  void _pushUndoSnapshot() {
    _undoStack.add(List<int>.of(_pixels));
    if (_undoStack.length > _maxHistoryLength) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    setState(() {
      _redoStack.add(List<int>.of(_pixels));
      _pixels = _undoStack.removeLast();
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    setState(() {
      _undoStack.add(List<int>.of(_pixels));
      _pixels = _redoStack.removeLast();
    });
  }

  void _newCanvas() {
    _pushUndoSnapshot();
    setState(() {
      _pixels = List<int>.filled(
        _canvasWidth * _canvasHeight,
        _transparentPixel,
      );
    });
  }

  void _clearCanvas() {
    if (_pixels.every((pixel) => pixel == _transparentPixel)) {
      return;
    }
    _newCanvas();
  }

  Future<void> _saveToLibrary() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSaveToLibrary(_encodePng(), _canvasWidth, _canvasHeight);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _exportPng() async {
    final onExportPng = widget.onExportPng;
    if (onExportPng == null) {
      return;
    }
    setState(() => _isExporting = true);
    try {
      await onExportPng(_encodePng(), _canvasWidth, _canvasHeight);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Uint8List _encodePng() {
    final image = image_lib.Image(
      width: _canvasWidth,
      height: _canvasHeight,
      numChannels: 4,
    );
    for (var y = 0; y < _canvasHeight; y++) {
      for (var x = 0; x < _canvasWidth; x++) {
        final value = _pixels[y * _canvasWidth + x];
        image.setPixelRgba(
          x,
          y,
          (value >> 16) & 0xff,
          (value >> 8) & 0xff,
          value & 0xff,
          (value >> 24) & 0xff,
        );
      }
    }
    return Uint8List.fromList(image_lib.encodePng(image));
  }
}

class _ColorSwatchButton extends StatelessWidget {
  const _ColorSwatchButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;
    final label =
        '${appL10nOf(context).pixelArtChooseColorTooltip} ${_colorHexLabel(color)}';

    return Tooltip(
      message: label,
      child: Semantics(
        container: true,
        label: label,
        button: true,
        selected: selected,
        enabled: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: selected ? 3 : 1),
            ),
          ),
        ),
      ),
    );
  }
}

String _colorHexLabel(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class _PixelArtPainter extends CustomPainter {
  const _PixelArtPainter({
    required this.pixels,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.cellSize,
    required this.gridColor,
    required this.checkerLightColor,
    required this.checkerDarkColor,
    required this.cursorX,
    required this.cursorY,
    required this.cursorColor,
  });

  final List<int> pixels;
  final int canvasWidth;
  final int canvasHeight;
  final double cellSize;
  final Color gridColor;
  final Color checkerLightColor;
  final Color checkerDarkColor;
  final int cursorX;
  final int cursorY;
  final Color cursorColor;

  @override
  void paint(Canvas canvas, Size size) {
    final checkerPaint = Paint()..style = PaintingStyle.fill;
    final pixelPaint = Paint()..style = PaintingStyle.fill;
    for (var y = 0; y < canvasHeight; y++) {
      for (var x = 0; x < canvasWidth; x++) {
        final rect = Rect.fromLTWH(
          x * cellSize,
          y * cellSize,
          cellSize,
          cellSize,
        );
        checkerPaint.color = (x + y).isOdd
            ? checkerDarkColor
            : checkerLightColor;
        canvas.drawRect(rect, checkerPaint);

        final value = pixels[y * canvasWidth + x];
        if (((value >> 24) & 0xff) == 0) {
          continue;
        }
        pixelPaint.color = Color(value);
        canvas.drawRect(rect, pixelPaint);
      }
    }

    if (cellSize < 5) {
      return;
    }

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.72)
      ..strokeWidth = 1;
    for (var x = 0; x <= canvasWidth; x++) {
      final dx = x * cellSize;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 0; y <= canvasHeight; y++) {
      final dy = y * cellSize;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final cursorPaint = Paint()
      ..color = cursorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final cursorRect = Rect.fromLTWH(
      cursorX * cellSize,
      cursorY * cellSize,
      cellSize,
      cellSize,
    ).deflate(1.5);
    canvas.drawRect(cursorRect, cursorPaint);
  }

  @override
  bool shouldRepaint(covariant _PixelArtPainter oldDelegate) {
    return oldDelegate.pixels != pixels ||
        oldDelegate.canvasWidth != canvasWidth ||
        oldDelegate.canvasHeight != canvasHeight ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.checkerLightColor != checkerLightColor ||
        oldDelegate.checkerDarkColor != checkerDarkColor ||
        oldDelegate.cursorX != cursorX ||
        oldDelegate.cursorY != cursorY ||
        oldDelegate.cursorColor != cursorColor;
  }
}
