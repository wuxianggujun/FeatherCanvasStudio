import 'dart:io';

import 'package:flutter/material.dart';

import '../models/sprite_sheet_frame_fit.dart';
import '../services/gif_composer_service.dart';
import '../theme/layout_constants.dart';
import '../utils/display_labels.dart';
import '../widgets/common_form_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';
import '../widgets/preview_widgets.dart';

class SpriteSheetEditorPanel extends StatelessWidget {
  const SpriteSheetEditorPanel({
    required this.imagePath,
    required this.patchImagePath,
    required this.rows,
    required this.columns,
    required this.targetFrameIndex,
    required this.frameFit,
    required this.isReplacingFrame,
    required this.onPickImage,
    required this.onClearImage,
    required this.onPickPatchImage,
    required this.onClearPatchImage,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onTargetFrameChanged,
    required this.onFrameFitChanged,
    required this.onReplaceFrame,
    super.key,
  });

  static const List<int> _gridSizes = <int>[1, 2, 3, 4, 5, 6, 7, 8];

  final String? imagePath;
  final String? patchImagePath;
  final int rows;
  final int columns;
  final int targetFrameIndex;
  final SpriteSheetFrameFit frameFit;
  final bool isReplacingFrame;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onPickPatchImage;
  final VoidCallback onClearPatchImage;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<int> onTargetFrameChanged;
  final ValueChanged<SpriteSheetFrameFit> onFrameFitChanged;
  final VoidCallback onReplaceFrame;

  @override
  Widget build(BuildContext context) {
    final frameTotal = rows * columns;
    final safeFrameIndex = targetFrameIndex.clamp(0, frameTotal - 1);
    final canReplace =
        imagePath != null && patchImagePath != null && !isReplacingFrame;

    return AppPanel(
      title: '编辑配置',
      child: Column(
        children: [
          TemplateImagePicker(
            imagePath: imagePath,
            title: 'Sprite Sheet 图片',
            pickLabel: imagePath == null ? '选择' : '更换',
            clearTooltip: '清除图片',
            onPick: onPickImage,
            onClear: imagePath == null ? null : onClearImage,
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: OptionDropdown<int>(
              label: '行数',
              value: rows,
              options: _gridSizes,
              labelBuilder: (value) => '$value 行',
              onChanged: onRowsChanged,
            ),
            second: OptionDropdown<int>(
              label: '列数',
              value: columns,
              options: _gridSizes,
              labelBuilder: (value) => '$value 列',
              helperText: '共 $frameTotal 帧',
              onChanged: onColumnsChanged,
            ),
          ),
          const SizedBox(height: fieldGap),
          TemplateImagePicker(
            imagePath: patchImagePath,
            title: '单帧图片',
            pickLabel: patchImagePath == null ? '选择' : '更换',
            clearTooltip: '清除单帧图片',
            previewHeight: 148,
            onPick: onPickPatchImage,
            onClear: patchImagePath == null ? null : onClearPatchImage,
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: OptionDropdown<int>(
              fieldKey: ValueKey(
                'editor-target-frame-$safeFrameIndex-$frameTotal',
              ),
              label: '替换目标',
              value: safeFrameIndex,
              options: [for (var index = 0; index < frameTotal; index++) index],
              labelBuilder: (index) => editorFrameOptionLabel(index, columns),
              onChanged: onTargetFrameChanged,
            ),
            second: OptionDropdown<SpriteSheetFrameFit>(
              label: '适配方式',
              value: frameFit,
              options: SpriteSheetFrameFit.values,
              labelBuilder: spriteSheetFrameFitLabel,
              onChanged: onFrameFitChanged,
            ),
          ),
          const SizedBox(height: fieldGap),
          PrimaryActionButton(
            onPressed: canReplace ? onReplaceFrame : null,
            icon: Icons.published_with_changes_outlined,
            label: '插入 / 替换到当前格',
            busyLabel: '替换中',
            isBusy: isReplacingFrame,
          ),
        ],
      ),
    );
  }
}

class GifComposerPanel extends StatelessWidget {
  const GifComposerPanel({
    required this.frames,
    required this.defaultFrameDelayMs,
    required this.loopCount,
    required this.playbackMode,
    required this.isComposing,
    required this.outputPath,
    required this.errorMessage,
    required this.onPickImages,
    required this.onClearImages,
    required this.onReorderImages,
    required this.onRemoveImageAt,
    required this.onFrameDelayChanged,
    required this.onApplyFrameDelayToAll,
    required this.onFrameDelayForImageChanged,
    required this.onLoopCountChanged,
    required this.onPlaybackModeChanged,
    required this.onCompose,
    super.key,
  });

  final List<GifSourceFrame> frames;
  final int defaultFrameDelayMs;
  final int loopCount;
  final GifPlaybackMode playbackMode;
  final bool isComposing;
  final String? outputPath;
  final String? errorMessage;
  final VoidCallback onPickImages;
  final VoidCallback onClearImages;
  final void Function(int oldIndex, int newIndex) onReorderImages;
  final ValueChanged<int> onRemoveImageAt;
  final ValueChanged<int> onFrameDelayChanged;
  final VoidCallback onApplyFrameDelayToAll;
  final void Function(int index, int delayMs) onFrameDelayForImageChanged;
  final ValueChanged<int> onLoopCountChanged;
  final ValueChanged<GifPlaybackMode> onPlaybackModeChanged;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFrames = frames.isNotEmpty;

    return AppPanel(
      title: 'GIF 配置',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isComposing ? null : onPickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('选择图片'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: '清空图片',
                onPressed: hasFrames && !isComposing ? onClearImages : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: fieldGap),
          Text(
            hasFrames ? '已选择  张图片' : '尚未选择图片',
            style: theme.textTheme.bodyMedium,
          ),
          if (hasFrames) ...[
            const SizedBox(height: fieldGap),
            Text('拖拽排序', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('从上到下就是 GIF 的播放顺序。', style: theme.textTheme.bodySmall),
            const SizedBox(height: fieldGap),
            SizedBox(
              height: frames.length < 4 ? frames.length * 122.0 : 320.0,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: frames.length,
                onReorder: onReorderImages,
                itemBuilder: (context, index) {
                  final frame = frames[index];
                  return Container(
                    key: ValueKey(frame.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Image.file(
                                File(frame.path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return ColoredBox(
                                    color: theme.colorScheme.errorContainer,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}. ${fileNameFromPath(frame.path)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                OptionDropdown<int>(
                                  label: '帧时长',
                                  value: frame.delayMs,
                                  options: gifFrameDelayOptions,
                                  labelBuilder: (value) => '$value ms',
                                  isDense: true,
                                  onChanged: isComposing
                                      ? null
                                      : (value) => onFrameDelayForImageChanged(
                                          index,
                                          value,
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: '移除图片',
                                child: IconButton(
                                  onPressed: isComposing
                                      ? null
                                      : () => onRemoveImageAt(index),
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                enabled: !isComposing,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(Icons.drag_indicator),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: fieldGap),
          Row(
            children: [
              Expanded(
                child: OptionDropdown<int>(
                  label: '默认帧时长',
                  value: defaultFrameDelayMs,
                  options: gifFrameDelayOptions,
                  labelBuilder: (value) => '$value ms',
                  onChanged: isComposing ? null : onFrameDelayChanged,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '应用到全部',
                onPressed: isComposing || !hasFrames
                    ? null
                    : onApplyFrameDelayToAll,
                icon: const Icon(Icons.playlist_add_check_outlined),
              ),
            ],
          ),
          const SizedBox(height: fieldGap),
          OptionDropdown<int>(
            label: '循环次数',
            value: loopCount,
            options: const [0, 1, 3, 5],
            labelBuilder: (value) => value == 0 ? '无限循环' : '播放  次',
            onChanged: isComposing ? null : onLoopCountChanged,
          ),
          const SizedBox(height: fieldGap),
          OptionDropdown<GifPlaybackMode>(
            label: '播放模式',
            value: playbackMode,
            options: GifPlaybackMode.values,
            labelBuilder: gifPlaybackModeLabel,
            onChanged: isComposing ? null : onPlaybackModeChanged,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: fieldGap),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
          if (outputPath != null) ...[
            const SizedBox(height: fieldGap),
            SelectableText('输出：', style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: sectionGap),
          PrimaryActionButton(
            onPressed: isComposing || frames.length < 2 ? null : onCompose,
            icon: Icons.gif_box_outlined,
            label: '生成 GIF',
            busyLabel: '合成中',
            isBusy: isComposing,
          ),
        ],
      ),
    );
  }
}

class GifSourcePreviewPanel extends StatelessWidget {
  const GifSourcePreviewPanel({
    required this.frames,
    required this.outputPath,
    super.key,
  });

  final List<GifSourceFrame> frames;
  final String? outputPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PreviewPanelShell(
      title: outputPath == null ? '图片序列预览' : 'GIF 预览',
      child: outputPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(outputPath!), fit: BoxFit.contain),
            )
          : frames.isEmpty
          ? const PreviewStateSurface.empty(message: '选择多张图片后会显示在这里')
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: frames.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final frame = frames[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${fileNameFromPath(frame.path)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${frame.delayMs} ms',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(frame.path),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return ColoredBox(
                              color: theme.colorScheme.errorContainer,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    '加载失败',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
