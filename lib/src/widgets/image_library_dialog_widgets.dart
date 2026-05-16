import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/exceptions.dart';
import '../models/image_library_item.dart';
import '../services/sprite_sheet_service.dart';
import '../utils/display_labels.dart';
import 'image_library_common_widgets.dart';

part 'image_library_picker_dialog.dart';
part 'sprite_sheet_slice_picker_dialog.dart';

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
    final totalCount = widget.sheet.effectiveGridSpec.totalFrameCount;
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
