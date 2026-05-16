part of 'image_library_dialog_widgets.dart';

class SpriteSheetSlicePickerDialog extends StatefulWidget {
  const SpriteSheetSlicePickerDialog({
    required this.sheet,
    required this.allowMultiple,
    this.title,
    super.key,
  });

  final ImageLibraryItem sheet;
  final bool allowMultiple;
  final String? title;

  @override
  State<SpriteSheetSlicePickerDialog> createState() =>
      SpriteSheetSlicePickerDialogState();
}

class SpriteSheetSlicePickerDialogState
    extends State<SpriteSheetSlicePickerDialog> {
  SpriteSheetPreviewData? _previewData;
  String? _errorMessage;
  final Set<int> _selected = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.sheet.path).readAsBytes();
      final gridSpec = widget.sheet.effectiveGridSpec;
      if (gridSpec.rows <= 0 || gridSpec.columns <= 0) {
        throw const ImageGenerationException('该 Sprite Sheet 缺少行列元数据。');
      }
      final data = SpriteSheetPreviewComposer.buildFromSheetBytes(
        bytes,
        rows: gridSpec.rows,
        columns: gridSpec.columns,
        gridSpec: gridSpec,
      );
      if (!mounted) return;
      setState(() => _previewData = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = '加载切片失败：$error');
    }
  }

  void _toggle(int index) {
    setState(() {
      if (widget.allowMultiple) {
        if (_selected.contains(index)) {
          _selected.remove(index);
        } else {
          _selected.add(index);
        }
      } else {
        _selected
          ..clear()
          ..add(index);
      }
    });
  }

  void _confirm() {
    final data = _previewData;
    if (data == null || _selected.isEmpty) return;
    final ordered = _selected.toList()..sort();
    Navigator.of(context).pop(<MapEntry<int, Uint8List>>[
      for (final idx in ordered) MapEntry(idx, data.frames[idx]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _previewData;
    final error = _errorMessage;
    final title = widget.title ?? (widget.allowMultiple ? '挑选切片帧' : '挑选一帧作为来源');

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('$title · ${widget.sheet.displayTitle}')),
          if (data != null)
            Text(
              widget.allowMultiple
                  ? '已选 ${_selected.length} / ${data.frames.length}'
                  : _selected.isEmpty
                  ? '尚未选择'
                  : '已选 #${_selected.first + 1}',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 520,
        child: error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _previewData = null;
                        });
                        _load();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              )
            : data == null
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio:
                      data.frameWidth /
                      (data.frameHeight == 0 ? 1 : data.frameHeight),
                ),
                itemCount: data.frames.length,
                itemBuilder: (context, index) {
                  final bytes = data.frames[index];
                  final selected = _selected.contains(index);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _toggle(index),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: Image.memory(
                                    bytes,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface.withValues(
                                      alpha: 0.85,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                              ),
                              if (selected)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.check,
                                      size: 14,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: data == null || _selected.isEmpty ? null : _confirm,
          icon: const Icon(Icons.check),
          label: Text(
            widget.allowMultiple ? '确认选择 (${_selected.length})' : '确认选择',
          ),
        ),
      ],
    );
  }
}
