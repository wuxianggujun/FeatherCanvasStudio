part of 'editor_gif_widgets.dart';

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
            hasFrames ? '已选择 ${frames.length} 张图片' : '尚未选择图片',
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
                              child: _GifFrameImage(
                                frame: frame,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}. ${frame.displayLabel}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                _GifDelayField(
                                  label: '帧时长',
                                  value: frame.delayMs,
                                  enabled: !isComposing,
                                  onChanged: (value) =>
                                      onFrameDelayForImageChanged(index, value),
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
                child: _GifDelayField(
                  label: '默认帧时长',
                  value: defaultFrameDelayMs,
                  enabled: !isComposing,
                  onChanged: onFrameDelayChanged,
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
            labelBuilder: (value) => value == 0 ? '无限循环' : '播放 $value 次',
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
            SelectableText('输出：$outputPath', style: theme.textTheme.bodySmall),
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
                      '${index + 1}. ${frame.displayLabel}',
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
                        child: _GifFrameImage(
                          frame: frame,
                          width: double.infinity,
                          fit: BoxFit.cover,
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

class _GifFrameImage extends StatelessWidget {
  const _GifFrameImage({required this.frame, required this.fit, this.width});

  final GifSourceFrame frame;
  final BoxFit fit;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final inlineBytes = frame.inlineBytes;
    if (inlineBytes != null) {
      return Image.memory(
        inlineBytes,
        width: width,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: _buildError,
      );
    }

    return Image.file(
      File(frame.path),
      width: width,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: _buildError,
    );
  }

  Widget _buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.errorContainer,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '加载失败',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _GifDelayField extends StatefulWidget {
  const _GifDelayField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  State<_GifDelayField> createState() => _GifDelayFieldState();
}

class _GifDelayFieldState extends State<_GifDelayField> {
  static const int _minValue = 10;
  static const int _maxValue = 60000;
  static const int _step = 10;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode()..addListener(_normalizeWhenUnfocused);
  }

  @override
  void didUpdateWidget(covariant _GifDelayField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) {
      return;
    }

    final currentValue = int.tryParse(_controller.text);
    if (!_focusNode.hasFocus || currentValue != widget.value) {
      _setText(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_normalizeWhenUnfocused)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _normalizeWhenUnfocused() {
    if (!_focusNode.hasFocus) {
      _setText(_normalizedValue(_controller.text));
    }
  }

  void _handleTextChanged(String text) {
    if (text.isEmpty) {
      return;
    }
    final value = _normalizedValue(text);
    if (value != widget.value) {
      widget.onChanged(value);
    }
  }

  void _changeBy(int delta) {
    final value = (widget.value + delta).clamp(_minValue, _maxValue).toInt();
    _setText(value);
    if (value != widget.value) {
      widget.onChanged(value);
    }
  }

  int _normalizedValue(String text) {
    final value = int.tryParse(text) ?? widget.value;
    return value.clamp(_minValue, _maxValue).toInt();
  }

  void _setText(int value) {
    final text = value.toString();
    if (_controller.text == text) {
      return;
    }
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: widget.label,
              suffixText: 'ms',
              isDense: true,
            ),
            onChanged: _handleTextChanged,
            onSubmitted: (value) => _setText(_normalizedValue(value)),
          ),
        ),
        const SizedBox(width: 6),
        _GifDelayStepButton(
          tooltip: '${widget.label}减少 10ms',
          icon: Icons.remove,
          onPressed: !widget.enabled || widget.value <= _minValue
              ? null
              : () => _changeBy(-_step),
        ),
        _GifDelayStepButton(
          tooltip: '${widget.label}增加 10ms',
          icon: Icons.add,
          onPressed: !widget.enabled || widget.value >= _maxValue
              ? null
              : () => _changeBy(_step),
        ),
      ],
    );
  }
}

class _GifDelayStepButton extends StatelessWidget {
  const _GifDelayStepButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 40,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
