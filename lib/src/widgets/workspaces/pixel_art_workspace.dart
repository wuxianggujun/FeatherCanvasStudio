import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;

import '../../theme/layout_constants.dart';
import '../common_form_widgets.dart';
import '../layout_navigation_widgets.dart';

enum PixelArtTool { brush, eraser, eyedropper }

typedef PixelArtSaveCallback =
    Future<void> Function(Uint8List pngBytes, int width, int height);

class PixelArtWorkspace extends StatefulWidget {
  const PixelArtWorkspace({
    required this.onSaveToLibrary,
    this.isFocusMode = false,
    this.onFocusModeChanged,
    this.historyControls,
    super.key,
  });

  final PixelArtSaveCallback onSaveToLibrary;
  final bool isFocusMode;
  final ValueChanged<bool>? onFocusModeChanged;
  final Widget? historyControls;

  @override
  State<PixelArtWorkspace> createState() => _PixelArtWorkspaceState();
}

class _PixelArtWorkspaceState extends State<PixelArtWorkspace> {
  static const int _minCanvasDimension = 1;
  static const int _maxCanvasDimension = 512;
  static const List<int> _canvasPresets = <int>[16, 32, 64, 128, 256];
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
  bool _isSaving = false;
  bool _isDrawingStroke = false;

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onFocusModeChanged = widget.onFocusModeChanged;
    final focusButton = onFocusModeChanged == null
        ? null
        : IconButton.filledTonal(
            tooltip: widget.isFocusMode ? '退出全屏编辑' : '进入全屏编辑',
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
      title: '像素画编辑',
      description: '逐格绘制像素画，支持画笔、橡皮、取色和保存到作品库',
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
    final hasPendingSize =
        _draftCanvasWidth != _canvasWidth ||
        _draftCanvasHeight != _canvasHeight;

    return AppPanel(
      title: '像素画工具',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('画布尺寸', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ResponsivePair(
            first: KeyedSubtree(
              key: const ValueKey('pixel-art-width-control'),
              child: IntegerStepperField(
                label: '画布宽度',
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
                label: '画布高度',
                value: _draftCanvasHeight,
                minValue: _minCanvasDimension,
                maxValue: _maxCanvasDimension,
                suffixText: 'px',
                helperText: '修改后应用',
                onChanged: (value) => setState(() {
                  _draftCanvasHeight = value;
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final size in _canvasPresets)
                ActionChip(
                  avatar: const Icon(Icons.crop_square_outlined, size: 18),
                  label: Text('$size x $size'),
                  onPressed: () => _resizeCanvas(width: size, height: size),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasPendingSize ? _applyDraftCanvasSize : null,
              icon: const Icon(Icons.check_outlined),
              label: const Text('应用画布尺寸'),
            ),
          ),
          const SizedBox(height: fieldGap),
          SegmentedButton<PixelArtTool>(
            segments: const [
              ButtonSegment(
                value: PixelArtTool.brush,
                icon: Icon(Icons.brush_outlined),
                label: Text('画笔'),
              ),
              ButtonSegment(
                value: PixelArtTool.eraser,
                icon: Icon(Icons.cleaning_services_outlined),
                label: Text('橡皮'),
              ),
              ButtonSegment(
                value: PixelArtTool.eyedropper,
                icon: Icon(Icons.colorize_outlined),
                label: Text('取色'),
              ),
            ],
            selected: {_tool},
            onSelectionChanged: (selection) {
              setState(() => _tool = selection.single);
            },
          ),
          const SizedBox(height: fieldGap),
          IntegerStepperField(
            label: '画笔大小',
            value: _brushSize,
            minValue: 1,
            maxValue: 8,
            suffixText: '格',
            helperText: '按方形笔刷覆盖像素格',
            onChanged: (value) => setState(() => _brushSize = value),
          ),
          const SizedBox(height: fieldGap),
          Text('颜色', style: theme.textTheme.titleSmall),
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
          Text('缩放', style: theme.textTheme.titleSmall),
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
            first: OutlinedButton.icon(
              onPressed: _undoStack.isEmpty ? null : _undo,
              icon: const Icon(Icons.undo_outlined),
              label: const Text('撤销'),
            ),
            second: OutlinedButton.icon(
              onPressed: _redoStack.isEmpty ? null : _redo,
              icon: const Icon(Icons.redo_outlined),
              label: const Text('重做'),
            ),
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: OutlinedButton.icon(
              onPressed: _newCanvas,
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('新建空白'),
            ),
            second: OutlinedButton.icon(
              onPressed: _clearCanvas,
              icon: const Icon(Icons.backspace_outlined),
              label: const Text('清空'),
            ),
          ),
          const SizedBox(height: fieldGap),
          PrimaryActionButton(
            onPressed: _isSaving ? null : () => _saveToLibrary(),
            icon: Icons.collections_bookmark_outlined,
            label: '保存到作品库',
            busyLabel: '保存中',
            isBusy: _isSaving,
          ),
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
        : math.max(640.0, viewportHeight - 360);

    return AppPanel(
      title: '像素画画布',
      trailing: Text(
        '$_canvasWidth x $_canvasHeight',
        style: theme.textTheme.labelLarge,
      ),
      child: SizedBox(
        height: panelHeight,
        child: Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: canvasWidth,
                      height: canvasHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) {
                          _isDrawingStroke = false;
                          _paintAt(details.localPosition);
                        },
                        onPanUpdate: (details) =>
                            _paintAt(details.localPosition),
                        onPanEnd: (_) => _isDrawingStroke = false,
                        onTapDown: (details) {
                          _isDrawingStroke = false;
                          _paintAt(details.localPosition);
                          _isDrawingStroke = false;
                        },
                        child: CustomPaint(
                          key: const ValueKey('pixel-art-canvas'),
                          painter: _PixelArtPainter(
                            pixels: _pixels,
                            canvasWidth: _canvasWidth,
                            canvasHeight: _canvasHeight,
                            cellSize: _cellSize,
                            gridColor: theme.colorScheme.outlineVariant,
                            checkerLightColor: theme.brightness == Brightness.dark
                                ? const Color(0xFF2A2D35)
                                : const Color(0xFFFFFFFF),
                            checkerDarkColor: theme.brightness == Brightness.dark
                                ? const Color(0xFF1F222A)
                                : const Color(0xFFE5E7EB),
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
    });
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

  Uint8List _encodePng() {
    final image = image_lib.Image(width: _canvasWidth, height: _canvasHeight);
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

    return Tooltip(
      message: '选择颜色',
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
    );
  }
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
  });

  final List<int> pixels;
  final int canvasWidth;
  final int canvasHeight;
  final double cellSize;
  final Color gridColor;
  final Color checkerLightColor;
  final Color checkerDarkColor;

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
  }

  @override
  bool shouldRepaint(covariant _PixelArtPainter oldDelegate) {
    return oldDelegate.pixels != pixels ||
        oldDelegate.canvasWidth != canvasWidth ||
        oldDelegate.canvasHeight != canvasHeight ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.checkerLightColor != checkerLightColor ||
        oldDelegate.checkerDarkColor != checkerDarkColor;
  }
}
