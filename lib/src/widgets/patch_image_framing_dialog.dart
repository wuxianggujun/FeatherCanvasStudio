import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/patch_image_framing_service.dart';

Future<PatchImageFraming?> showPatchImageFramingDialog(
  BuildContext context, {
  required Uint8List imageBytes,
  required int targetWidth,
  required int targetHeight,
  String? sourceTitle,
}) {
  final source = PatchImageFramingService.readDimensions(imageBytes);

  return showDialog<PatchImageFraming>(
    context: context,
    builder: (context) => _PatchImageFramingDialog(
      imageBytes: imageBytes,
      source: source,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      sourceTitle: sourceTitle,
    ),
  );
}

class _PatchImageFramingDialog extends StatefulWidget {
  const _PatchImageFramingDialog({
    required this.imageBytes,
    required this.source,
    required this.targetWidth,
    required this.targetHeight,
    this.sourceTitle,
  });

  final Uint8List imageBytes;
  final PatchImageDimensions source;
  final int targetWidth;
  final int targetHeight;
  final String? sourceTitle;

  @override
  State<_PatchImageFramingDialog> createState() =>
      _PatchImageFramingDialogState();
}

class _PatchImageFramingDialogState extends State<_PatchImageFramingDialog> {
  late PatchImageFraming _framing;
  late double _minScale;
  late double _maxScale;

  @override
  void initState() {
    super.initState();
    final contain = PatchImageFramingService.containFraming(
      source: widget.source,
      targetWidth: widget.targetWidth,
      targetHeight: widget.targetHeight,
    );
    final cover = PatchImageFramingService.coverFraming(
      source: widget.source,
      targetWidth: widget.targetWidth,
      targetHeight: widget.targetHeight,
    );
    _framing = contain;
    _minScale = math.max(0.02, math.min(contain.scale, cover.scale) / 4);
    _maxScale = math.max(8, math.max(contain.scale, cover.scale) * 6);
  }

  void _setFraming(PatchImageFraming framing) {
    setState(() {
      _framing = framing.copyWith(
        scale: framing.scale.clamp(_minScale, _maxScale).toDouble(),
      );
    });
  }

  void _setScale(double scale) {
    _setFraming(_framing.copyWith(scale: scale));
  }

  void _fitContain() {
    _setFraming(
      PatchImageFramingService.containFraming(
        source: widget.source,
        targetWidth: widget.targetWidth,
        targetHeight: widget.targetHeight,
      ),
    );
  }

  void _fitCover() {
    _setFraming(
      PatchImageFramingService.coverFraming(
        source: widget.source,
        targetWidth: widget.targetWidth,
        targetHeight: widget.targetHeight,
      ),
    );
  }

  void _centerImage() {
    _setFraming(_framing.copyWith(offsetX: 0, offsetY: 0));
  }

  void _resetToOriginalSize() {
    _setFraming(const PatchImageFraming(scale: 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('调整单帧取景'),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.sourceTitle != null) ...[
              Text(
                widget.sourceTitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            _PatchImageViewport(
              imageBytes: widget.imageBytes,
              source: widget.source,
              targetWidth: widget.targetWidth,
              targetHeight: widget.targetHeight,
              framing: _framing,
              onChanged: _setFraming,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _framing.scale.clamp(_minScale, _maxScale),
                    min: _minScale,
                    max: _maxScale,
                    label: '${(_framing.scale * 100).round()}%',
                    onChanged: _setScale,
                  ),
                ),
                SizedBox(
                  width: 68,
                  child: Text(
                    '${(_framing.scale * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _fitContain,
                  icon: const Icon(Icons.fit_screen_outlined),
                  label: const Text('完整显示'),
                ),
                OutlinedButton.icon(
                  onPressed: _fitCover,
                  icon: const Icon(Icons.crop_free_outlined),
                  label: const Text('填满格子'),
                ),
                OutlinedButton.icon(
                  onPressed: _centerImage,
                  icon: const Icon(Icons.center_focus_strong_outlined),
                  label: const Text('居中'),
                ),
                OutlinedButton.icon(
                  onPressed: _resetToOriginalSize,
                  icon: const Icon(Icons.one_x_mobiledata_outlined),
                  label: const Text('100%'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_framing),
          icon: const Icon(Icons.check_outlined),
          label: const Text('生成取景单帧'),
        ),
      ],
    );
  }
}

class _PatchImageViewport extends StatelessWidget {
  const _PatchImageViewport({
    required this.imageBytes,
    required this.source,
    required this.targetWidth,
    required this.targetHeight,
    required this.framing,
    required this.onChanged,
  });

  final Uint8List imageBytes;
  final PatchImageDimensions source;
  final int targetWidth;
  final int targetHeight;
  final PatchImageFraming framing;
  final ValueChanged<PatchImageFraming> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aspectRatio = targetWidth / targetHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        var viewportWidth = constraints.maxWidth;
        var viewportHeight = viewportWidth / aspectRatio;
        if (viewportHeight > 440) {
          viewportHeight = 440;
          viewportWidth = viewportHeight * aspectRatio;
        }
        final displayScale = viewportWidth / targetWidth;
        final imageWidth = source.width * framing.scale * displayScale;
        final imageHeight = source.height * framing.scale * displayScale;
        final imageLeft =
            (viewportWidth - imageWidth) / 2 + framing.offsetX * displayScale;
        final imageTop =
            (viewportHeight - imageHeight) / 2 + framing.offsetY * displayScale;

        return Center(
          child: Listener(
            onPointerSignal: (event) {
              if (event is! PointerScrollEvent) {
                return;
              }
              final factor = event.scrollDelta.dy < 0 ? 1.08 : 0.92;
              onChanged(framing.copyWith(scale: framing.scale * factor));
            },
            child: GestureDetector(
              onPanUpdate: (details) {
                onChanged(
                  framing.copyWith(
                    offsetX: framing.offsetX + details.delta.dx / displayScale,
                    offsetY: framing.offsetY + details.delta.dy / displayScale,
                  ),
                );
              },
              child: ClipRect(
                child: Container(
                  width: viewportWidth,
                  height: viewportHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.primary),
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      const Positioned.fill(child: _Checkerboard()),
                      Positioned(
                        left: imageLeft,
                        top: imageTop,
                        width: imageWidth,
                        height: imageHeight,
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '$targetWidth x $targetHeight',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Checkerboard extends StatelessWidget {
  const _Checkerboard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CheckerboardPainter());
  }
}

class _CheckerboardPainter extends CustomPainter {
  static const double _cellSize = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFF4F4F5);
    final dark = Paint()..color = const Color(0xFFE4E4E7);
    canvas.drawRect(Offset.zero & size, light);

    for (var y = 0.0; y < size.height; y += _cellSize) {
      for (var x = 0.0; x < size.width; x += _cellSize) {
        final column = (x / _cellSize).floor();
        final row = (y / _cellSize).floor();
        if ((row + column).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, _cellSize, _cellSize), dark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
