import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/gif_composer_service.dart';
import '../../state/gif_composer_notifier.dart';
import '../editor_gif_widgets.dart';
import '../layout_navigation_widgets.dart';

class GifComposerWorkspace extends StatelessWidget {
  const GifComposerWorkspace({
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
          storageKey: 'gif_composer',
          controls: Consumer<GifComposerNotifier>(
            builder: (context, notifier, _) => GifComposerPanel(
              frames: notifier.frames,
              defaultFrameDelayMs: notifier.defaultFrameDelayMs,
              loopCount: notifier.loopCount,
              playbackMode: notifier.playbackMode,
              isComposing: notifier.isComposing,
              outputPath: notifier.outputPath,
              errorMessage: notifier.errorMessage,
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
          ),
          preview: Selector<GifComposerNotifier,
              ({List<GifSourceFrame> frames, String? outputPath})>(
            selector: (_, n) => (frames: n.frames, outputPath: n.outputPath),
            builder: (context, data, _) => GifSourcePreviewPanel(
              frames: data.frames,
              outputPath: data.outputPath,
            ),
          ),
        ),
      ],
    );
  }
}
