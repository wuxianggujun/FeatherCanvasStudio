import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/exceptions.dart';
import '../models/image_library_item.dart';
import '../services/sprite_sheet_service.dart';
import '../utils/display_labels.dart';
import 'image_library_common_widgets.dart';

class SpriteSheetSliceExplorerDialog extends StatefulWidget {
  const SpriteSheetSliceExplorerDialog({
    required this.sheet,
    required this.savedFrameIndexes,
    required this.onSaveSlice,
    required this.onSaveAllSlices,
    super.key,
  });

  final ImageLibraryItem sheet;
  final Set<int> savedFrameIndexes;
  final Future<bool> Function(int frameIndex, Uint8List bytes) onSaveSlice;
  final Future<int> Function(List<MapEntry<int, Uint8List>> framesToSave)
  onSaveAllSlices;

  @override
  State<SpriteSheetSliceExplorerDialog> createState() =>
      SpriteSheetSliceExplorerDialogState();
}

class SpriteSheetSliceExplorerDialogState
    extends State<SpriteSheetSliceExplorerDialog> {
  SpriteSheetPreviewData? _previewData;
  String? _errorMessage;
  final Set<int> _savingIndexes = <int>{};
  final Set<int> _justSaved = <int>{};
  bool _isSavingAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.sheet.path).readAsBytes();
      final rows = widget.sheet.rows;
      final columns = widget.sheet.columns;
      if (rows == null || columns == null || rows <= 0 || columns <= 0) {
        throw const ImageGenerationException('该 Sprite Sheet 缺少行列元数据。');
      }
      final data = SpriteSheetPreviewComposer.buildFromSheetBytes(
        bytes,
        rows: rows,
        columns: columns,
      );
      if (!mounted) return;
      setState(() => _previewData = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = '加载切片失败：$error');
    }
  }

  bool _isSaved(int frameIndex) =>
      widget.savedFrameIndexes.contains(frameIndex) ||
      _justSaved.contains(frameIndex);

  Future<void> _saveOne(int frameIndex) async {
    final data = _previewData;
    if (data == null || _savingIndexes.contains(frameIndex)) return;
    setState(() => _savingIndexes.add(frameIndex));
    try {
      final saved = await widget.onSaveSlice(
        frameIndex,
        data.frames[frameIndex],
      );
      if (!mounted) return;
      if (saved) {
        setState(() => _justSaved.add(frameIndex));
      }
    } finally {
      if (mounted) {
        setState(() => _savingIndexes.remove(frameIndex));
      }
    }
  }

  Future<void> _saveAll() async {
    final data = _previewData;
    if (data == null || _isSavingAll) return;
    final pending = <MapEntry<int, Uint8List>>[];
    for (var i = 0; i < data.frames.length; i++) {
      if (!_isSaved(i)) {
        pending.add(MapEntry(i, data.frames[i]));
      }
    }
    if (pending.isEmpty) return;
    setState(() => _isSavingAll = true);
    try {
      final actuallySaved = await widget.onSaveAllSlices(pending);
      if (!mounted) return;
      setState(() {
        _justSaved.addAll(pending.take(actuallySaved).map((e) => e.key));
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingAll = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _previewData;
    final error = _errorMessage;
    final totalCount = (widget.sheet.rows ?? 0) * (widget.sheet.columns ?? 0);
    final savedCount = data == null
        ? widget.savedFrameIndexes.length
        : List.generate(
            data.frames.length,
            (i) => _isSaved(i),
          ).where((e) => e).length;
    final remaining = (data?.frames.length ?? totalCount) - savedCount;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('切片管理 · ${widget.sheet.displayTitle}')),
          if (data != null)
            Text(
              '已保存 $savedCount / ${data.frames.length}',
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
                  final saved = _isSaved(index);
                  final saving = _savingIndexes.contains(index);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: saved
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.outlineVariant,
                        width: saved ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Image.memory(bytes, fit: BoxFit.contain),
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
                          if (saved)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '已保存',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          if (!saved)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Material(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.85,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                child: IconButton(
                                  tooltip: '保存这一帧',
                                  iconSize: 20,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: saving
                                      ? null
                                      : () => _saveOne(index),
                                  icon: saving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.bookmark_add_outlined),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: data == null || _isSavingAll || remaining <= 0
              ? null
              : _saveAll,
          icon: _isSavingAll
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.select_all),
          label: Text(remaining <= 0 ? '已全部保存' : '全部保存为切片 ($remaining)'),
        ),
      ],
    );
  }
}

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
      final rows = widget.sheet.rows;
      final columns = widget.sheet.columns;
      if (rows == null || columns == null || rows <= 0 || columns <= 0) {
        throw const ImageGenerationException('该 Sprite Sheet 缺少行列元数据。');
      }
      final data = SpriteSheetPreviewComposer.buildFromSheetBytes(
        bytes,
        rows: rows,
        columns: columns,
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

class ImageLibraryPickerDialog extends StatefulWidget {
  const ImageLibraryPickerDialog({
    required this.title,
    required this.items,
    required this.allowMultiple,
    super.key,
  });

  final String title;
  final List<ImageLibraryItem> items;
  final bool allowMultiple;

  @override
  State<ImageLibraryPickerDialog> createState() =>
      ImageLibraryPickerDialogState();
}

class ImageLibraryPickerDialogState extends State<ImageLibraryPickerDialog> {
  final Set<String> _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 760,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: widget.items.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final selected = _selectedIds.contains(item.id);
              return Material(
                color: selected
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _toggleSelection(item),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: ImageLibraryPreview(item: item),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: selected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          imageAssetKindLabel(item.kind),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selectedIds.isEmpty ? null : _confirm,
          child: Text(
            widget.allowMultiple ? '选择 ${_selectedIds.length} 张' : '选择',
          ),
        ),
      ],
    );
  }

  void _toggleSelection(ImageLibraryItem item) {
    setState(() {
      if (widget.allowMultiple) {
        if (!_selectedIds.add(item.id)) {
          _selectedIds.remove(item.id);
        }
      } else {
        _selectedIds
          ..clear()
          ..add(item.id);
      }
    });
  }

  void _confirm() {
    if (widget.allowMultiple) {
      Navigator.of(context).pop([
        for (final item in widget.items)
          if (_selectedIds.contains(item.id)) item,
      ]);
      return;
    }

    final selectedId = _selectedIds.first;
    for (final item in widget.items) {
      if (item.id == selectedId) {
        Navigator.of(context).pop(item);
        return;
      }
    }
  }
}
