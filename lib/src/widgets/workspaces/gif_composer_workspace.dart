import 'package:flutter/material.dart';

import '../../services/gif_composer_service.dart';
import '../editor_gif_widgets.dart';
import '../layout_navigation_widgets.dart';

class GifComposerWorkspace extends StatelessWidget {
  const GifComposerWorkspace({
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
    return WorkspacePage(
      title: 'GIF 合成',
      description: '选择多张本地图片，按当前顺序合成为一个 GIF 动图',
      children: [
        ResponsiveWorkspaceSplit(
          controls: GifComposerPanel(
            frames: frames,
            defaultFrameDelayMs: defaultFrameDelayMs,
            loopCount: loopCount,
            playbackMode: playbackMode,
            isComposing: isComposing,
            outputPath: outputPath,
            errorMessage: errorMessage,
            onPickImages: onPickImages,
            onClearImages: onClearImages,
            onReorderImages: onReorderImages,
            onRemoveImageAt: onRemoveImageAt,
            onFrameDelayChanged: onFrameDelayChanged,
            onApplyFrameDelayToAll: onApplyFrameDelayToAll,
            onFrameDelayForImageChanged: onFrameDelayForImageChanged,
            onLoopCountChanged: onLoopCountChanged,
            onPlaybackModeChanged: onPlaybackModeChanged,
            onCompose: onCompose,
          ),
          preview: GifSourcePreviewPanel(
            frames: frames,
            outputPath: outputPath,
          ),
        ),
      ],
    );
  }
}
