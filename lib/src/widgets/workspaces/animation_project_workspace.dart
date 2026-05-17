import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/animation_project.dart';
import '../../models/app_config.dart';
import '../../models/generated_image.dart';
import '../../models/image_advanced_settings.dart';
import '../../models/sprite_sheet_grid_spec.dart';
import '../../services/animation_project_service.dart';
import '../../services/gif_composer_service.dart';
import '../../services/image_api_client.dart';
import '../../utils/display_labels.dart';
import '../../utils/sprite_sheet_text.dart';
import '../common_form_widgets.dart';
import '../generation_form_widgets.dart';
import '../layout_navigation_widgets.dart';
import '../preview_widgets.dart';

class AnimationProjectWorkspace extends StatelessWidget {
  const AnimationProjectWorkspace({
    required this.apiConfigs,
    required this.selectedApiConfig,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.rows,
    required this.columns,
    required this.gridSpec,
    required this.templateImagePath,
    required this.advancedSettings,
    required this.userController,
    required this.isGenerating,
    required this.errorMessage,
    required this.debugRecord,
    required this.generatedImages,
    required this.project,
    required this.selectedTrackId,
    required this.isProjectBusy,
    required this.projectErrorMessage,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onGridSpecChanged,
    required this.onAdvancedSettingsChanged,
    required this.onPickTemplateImage,
    required this.onClearTemplateImage,
    required this.onGenerate,
    required this.onImportGeneratedSheet,
    required this.onImportImageSequence,
    required this.onClearProject,
    required this.onTrackSelected,
    required this.onTrackAdded,
    required this.onTrackDuplicated,
    required this.onTrackDeleted,
    required this.onTrackMoved,
    required this.onTrackRenamed,
    required this.onProjectDefaultDelayChanged,
    required this.onProjectPlaybackModeChanged,
    required this.onProjectLoopCountChanged,
    required this.onProjectIncludeHiddenTracksChanged,
    required this.onTrackDelayChanged,
    required this.onTrackPlaybackModeChanged,
    required this.onTrackVisibilityChanged,
    required this.onTrackLockChanged,
    required this.onFrameMoved,
    required this.onFrameDuplicated,
    required this.onFrameDeleted,
    required this.onFrameDelayChanged,
    required this.onFrameTransformChanged,
    required this.onFrameAssetRebound,
    required this.onProjectAutoRepaired,
    required this.onExportProjectSpriteSheet,
    required this.onExportProjectGif,
    required this.onExportProjectPngSequence,
    required this.onExportTrackGif,
    required this.onExportTrackPngSequence,
    required this.onExportSourceSpriteSheet,
    required this.onExportRenderedSpriteSheet,
    required this.onSendRenderedToGif,
    required this.onOpenRenderedInEditor,
    this.enablePreviewPlayback = true,
    super.key,
  });

  final List<ApiConfig> apiConfigs;
  final ApiConfig selectedApiConfig;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;
  final String? templateImagePath;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final bool isGenerating;
  final String? errorMessage;
  final ImageRequestDebugRecord? debugRecord;
  final List<GeneratedImage> generatedImages;
  final AnimationProject? project;
  final String? selectedTrackId;
  final bool isProjectBusy;
  final String? projectErrorMessage;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<SpriteSheetGridSpec> onGridSpecChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onPickTemplateImage;
  final VoidCallback onClearTemplateImage;
  final VoidCallback onGenerate;
  final VoidCallback onImportGeneratedSheet;
  final VoidCallback onImportImageSequence;
  final VoidCallback onClearProject;
  final ValueChanged<String> onTrackSelected;
  final VoidCallback onTrackAdded;
  final ValueChanged<String> onTrackDuplicated;
  final ValueChanged<String> onTrackDeleted;
  final void Function(String trackId, int delta) onTrackMoved;
  final void Function(String trackId, String name) onTrackRenamed;
  final ValueChanged<int> onProjectDefaultDelayChanged;
  final ValueChanged<AnimationPlaybackMode> onProjectPlaybackModeChanged;
  final ValueChanged<int> onProjectLoopCountChanged;
  final ValueChanged<bool> onProjectIncludeHiddenTracksChanged;
  final void Function(String trackId, int delayMs) onTrackDelayChanged;
  final void Function(String trackId, AnimationPlaybackMode mode)
  onTrackPlaybackModeChanged;
  final void Function(String trackId, bool visible) onTrackVisibilityChanged;
  final void Function(String trackId, bool locked) onTrackLockChanged;
  final void Function(String trackId, int fromIndex, int toIndex) onFrameMoved;
  final void Function(String trackId, int frameIndex) onFrameDuplicated;
  final void Function(String trackId, int frameIndex) onFrameDeleted;
  final void Function(String trackId, int frameIndex, int delayMs)
  onFrameDelayChanged;
  final void Function(String trackId, int frameIndex, FrameTransform transform)
  onFrameTransformChanged;
  final ValueChanged<String> onFrameAssetRebound;
  final VoidCallback onProjectAutoRepaired;
  final VoidCallback onExportProjectSpriteSheet;
  final VoidCallback onExportProjectGif;
  final VoidCallback onExportProjectPngSequence;
  final VoidCallback onExportTrackGif;
  final VoidCallback onExportTrackPngSequence;
  final ValueChanged<Uint8List> onExportSourceSpriteSheet;
  final ValueChanged<AnimationSpriteSheetRender> onExportRenderedSpriteSheet;
  final ValueChanged<AnimationSpriteSheetRender> onSendRenderedToGif;
  final ValueChanged<AnimationSpriteSheetRender> onOpenRenderedInEditor;
  final bool enablePreviewPlayback;

  @override
  Widget build(BuildContext context) {
    final currentProject = project;
    return WorkspacePage(
      title: '动画工程',
      description: '用工程、轨道和序列帧管理动画，Sprite Sheet 与 GIF 只作为导入和导出格式。',
      children: [
        ResponsiveWorkspaceSplit(
          storageKey: 'animation_project',
          controls: Column(
            children: [
              _AnimationProjectPanel(
                project: currentProject,
                selectedTrackId: selectedTrackId,
                generatedImages: generatedImages,
                isBusy: isProjectBusy,
                errorMessage: projectErrorMessage,
                onImportGeneratedSheet: onImportGeneratedSheet,
                onImportImageSequence: onImportImageSequence,
                onClearProject: onClearProject,
                onTrackSelected: onTrackSelected,
                onTrackAdded: onTrackAdded,
                onTrackDuplicated: onTrackDuplicated,
                onTrackDeleted: onTrackDeleted,
                onTrackMoved: onTrackMoved,
                onTrackRenamed: onTrackRenamed,
                onProjectDefaultDelayChanged: onProjectDefaultDelayChanged,
                onProjectPlaybackModeChanged: onProjectPlaybackModeChanged,
                onProjectLoopCountChanged: onProjectLoopCountChanged,
                onProjectIncludeHiddenTracksChanged:
                    onProjectIncludeHiddenTracksChanged,
                onTrackDelayChanged: onTrackDelayChanged,
                onTrackPlaybackModeChanged: onTrackPlaybackModeChanged,
                onTrackVisibilityChanged: onTrackVisibilityChanged,
                onTrackLockChanged: onTrackLockChanged,
                onFrameMoved: onFrameMoved,
                onFrameDuplicated: onFrameDuplicated,
                onFrameDeleted: onFrameDeleted,
                onFrameDelayChanged: onFrameDelayChanged,
                onFrameTransformChanged: onFrameTransformChanged,
                onFrameAssetRebound: onFrameAssetRebound,
                onProjectAutoRepaired: onProjectAutoRepaired,
                onExportProjectSpriteSheet: onExportProjectSpriteSheet,
                onExportProjectGif: onExportProjectGif,
                onExportProjectPngSequence: onExportProjectPngSequence,
                onExportTrackGif: onExportTrackGif,
                onExportTrackPngSequence: onExportTrackPngSequence,
              ),
              const SizedBox(height: 16),
              SpriteSheetGenerationPanel(
                apiConfigs: apiConfigs,
                selectedApiConfigId: selectedApiConfig.id,
                providerKind: selectedApiConfig.providerKind,
                model: selectedApiConfig.model,
                imageSizeCapabilityOverride:
                    selectedApiConfig.imageSizeCapabilityOverride,
                promptController: promptController,
                negativePromptController: negativePromptController,
                size: size,
                rows: rows,
                columns: columns,
                gridSpec: gridSpec,
                templateImagePath: templateImagePath,
                advancedSettings: advancedSettings,
                userController: userController,
                isGenerating: isGenerating,
                onApiConfigChanged: onApiConfigChanged,
                onOpenApiSettings: onOpenApiSettings,
                onSizeChanged: onSizeChanged,
                onRowsChanged: onRowsChanged,
                onColumnsChanged: onColumnsChanged,
                onGridSpecChanged: onGridSpecChanged,
                onAdvancedSettingsChanged: onAdvancedSettingsChanged,
                onPickTemplateImage: onPickTemplateImage,
                onClearTemplateImage: onClearTemplateImage,
                onGenerate: onGenerate,
              ),
            ],
          ),
          preview: _AnimationProjectPreview(
            project: currentProject,
            isGenerating: isGenerating,
            generationErrorMessage: errorMessage,
            debugRecord: debugRecord,
            generatedImages: generatedImages,
            sourceRows: rows,
            sourceColumns: columns,
            sourceGridSpec: gridSpec,
            onGenerate: onGenerate,
            onExportSourceSpriteSheet: onExportSourceSpriteSheet,
            onExportRenderedSpriteSheet: onExportRenderedSpriteSheet,
            onSendRenderedToGif: onSendRenderedToGif,
            onOpenRenderedInEditor: onOpenRenderedInEditor,
            enablePlayback: enablePreviewPlayback,
          ),
        ),
      ],
    );
  }
}

class _AnimationProjectPanel extends StatelessWidget {
  const _AnimationProjectPanel({
    required this.project,
    required this.selectedTrackId,
    required this.generatedImages,
    required this.isBusy,
    required this.errorMessage,
    required this.onImportGeneratedSheet,
    required this.onImportImageSequence,
    required this.onClearProject,
    required this.onTrackSelected,
    required this.onTrackAdded,
    required this.onTrackDuplicated,
    required this.onTrackDeleted,
    required this.onTrackMoved,
    required this.onTrackRenamed,
    required this.onProjectDefaultDelayChanged,
    required this.onProjectPlaybackModeChanged,
    required this.onProjectLoopCountChanged,
    required this.onProjectIncludeHiddenTracksChanged,
    required this.onTrackDelayChanged,
    required this.onTrackPlaybackModeChanged,
    required this.onTrackVisibilityChanged,
    required this.onTrackLockChanged,
    required this.onFrameMoved,
    required this.onFrameDuplicated,
    required this.onFrameDeleted,
    required this.onFrameDelayChanged,
    required this.onFrameTransformChanged,
    required this.onFrameAssetRebound,
    required this.onProjectAutoRepaired,
    required this.onExportProjectSpriteSheet,
    required this.onExportProjectGif,
    required this.onExportProjectPngSequence,
    required this.onExportTrackGif,
    required this.onExportTrackPngSequence,
  });

  final AnimationProject? project;
  final String? selectedTrackId;
  final List<GeneratedImage> generatedImages;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onImportGeneratedSheet;
  final VoidCallback onImportImageSequence;
  final VoidCallback onClearProject;
  final ValueChanged<String> onTrackSelected;
  final VoidCallback onTrackAdded;
  final ValueChanged<String> onTrackDuplicated;
  final ValueChanged<String> onTrackDeleted;
  final void Function(String trackId, int delta) onTrackMoved;
  final void Function(String trackId, String name) onTrackRenamed;
  final ValueChanged<int> onProjectDefaultDelayChanged;
  final ValueChanged<AnimationPlaybackMode> onProjectPlaybackModeChanged;
  final ValueChanged<int> onProjectLoopCountChanged;
  final ValueChanged<bool> onProjectIncludeHiddenTracksChanged;
  final void Function(String trackId, int delayMs) onTrackDelayChanged;
  final void Function(String trackId, AnimationPlaybackMode mode)
  onTrackPlaybackModeChanged;
  final void Function(String trackId, bool visible) onTrackVisibilityChanged;
  final void Function(String trackId, bool locked) onTrackLockChanged;
  final void Function(String trackId, int fromIndex, int toIndex) onFrameMoved;
  final void Function(String trackId, int frameIndex) onFrameDuplicated;
  final void Function(String trackId, int frameIndex) onFrameDeleted;
  final void Function(String trackId, int frameIndex, int delayMs)
  onFrameDelayChanged;
  final void Function(String trackId, int frameIndex, FrameTransform transform)
  onFrameTransformChanged;
  final ValueChanged<String> onFrameAssetRebound;
  final VoidCallback onProjectAutoRepaired;
  final VoidCallback onExportProjectSpriteSheet;
  final VoidCallback onExportProjectGif;
  final VoidCallback onExportProjectPngSequence;
  final VoidCallback onExportTrackGif;
  final VoidCallback onExportTrackPngSequence;

  @override
  Widget build(BuildContext context) {
    final currentProject = project;
    return AppPanel(
      title: '工程控制',
      trailing: currentProject == null
          ? null
          : FrameCountBadge(count: currentProject.totalFrameRefs, label: '帧'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentProject == null)
            Text(
              '先生成 Sprite Sheet，再导入为动画工程。导入后每一行会成为一条真实轨道。',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            Text(
              currentProject.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${currentProject.tracks.length} 条轨道 · '
              '${currentProject.totalFrameRefs} 帧 · '
              '${currentProject.canvasWidth} x ${currentProject.canvasHeight}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          PrimaryActionButton(
            onPressed: generatedImages.isEmpty || isBusy
                ? null
                : onImportGeneratedSheet,
            icon: Icons.account_tree_outlined,
            label: '导入为动画工程',
            busyLabel: '正在导入工程',
            isBusy: isBusy,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onImportImageSequence,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('导入图片序列'),
          ),
          if (currentProject != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onTrackAdded,
                  icon: const Icon(Icons.add),
                  label: const Text('新建轨道'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onExportProjectSpriteSheet,
                  icon: const Icon(Icons.grid_on_outlined),
                  label: const Text('导出合成 Sprite Sheet'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onExportProjectGif,
                  icon: const Icon(Icons.movie_outlined),
                  label: const Text('导出工程 GIF'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onExportProjectPngSequence,
                  icon: const Icon(Icons.collections_outlined),
                  label: const Text('导出工程 PNG 序列'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onExportTrackGif,
                  icon: const Icon(Icons.gif_box_outlined),
                  label: const Text('导出当前轨道 GIF'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onExportTrackPngSequence,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('导出 PNG 序列'),
                ),
                TextButton.icon(
                  onPressed: isBusy ? null : onClearProject,
                  icon: const Icon(Icons.close),
                  label: const Text('关闭工程'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProjectSettingsSection(
              project: currentProject,
              enabled: !isBusy,
              onDefaultDelayChanged: onProjectDefaultDelayChanged,
              onPlaybackModeChanged: onProjectPlaybackModeChanged,
              onLoopCountChanged: onProjectLoopCountChanged,
              onIncludeHiddenTracksChanged: onProjectIncludeHiddenTracksChanged,
            ),
            const SizedBox(height: 16),
            _AssetDiagnosticsSection(
              project: currentProject,
              enabled: !isBusy,
              onAssetRebound: onFrameAssetRebound,
              onProjectAutoRepaired: onProjectAutoRepaired,
            ),
            const SizedBox(height: 16),
            _TrackList(
              project: currentProject,
              selectedTrackId: selectedTrackId,
              onTrackSelected: onTrackSelected,
              onTrackDuplicated: onTrackDuplicated,
              onTrackDeleted: onTrackDeleted,
              onTrackMoved: onTrackMoved,
              onTrackRenamed: onTrackRenamed,
              onTrackDelayChanged: onTrackDelayChanged,
              onTrackPlaybackModeChanged: onTrackPlaybackModeChanged,
              onTrackVisibilityChanged: onTrackVisibilityChanged,
              onTrackLockChanged: onTrackLockChanged,
            ),
            const SizedBox(height: 16),
            _AnimationTimelinePanel(
              project: currentProject,
              track: _selectedTrack(currentProject, selectedTrackId),
              onFrameMoved: onFrameMoved,
              onFrameDuplicated: onFrameDuplicated,
              onFrameDeleted: onFrameDeleted,
              onFrameDelayChanged: onFrameDelayChanged,
              onFrameTransformChanged: onFrameTransformChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectSettingsSection extends StatelessWidget {
  const _ProjectSettingsSection({
    required this.project,
    required this.enabled,
    required this.onDefaultDelayChanged,
    required this.onPlaybackModeChanged,
    required this.onLoopCountChanged,
    required this.onIncludeHiddenTracksChanged,
  });

  final AnimationProject project;
  final bool enabled;
  final ValueChanged<int> onDefaultDelayChanged;
  final ValueChanged<AnimationPlaybackMode> onPlaybackModeChanged;
  final ValueChanged<int> onLoopCountChanged;
  final ValueChanged<bool> onIncludeHiddenTracksChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('工程设置', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ResponsivePair(
          first: IntegerStepperField(
            label: '工程默认帧时长',
            value: project.timeline.defaultFrameDelayMs,
            minValue: 20,
            maxValue: 2000,
            suffixText: 'ms',
            enabled: enabled,
            onChanged: onDefaultDelayChanged,
          ),
          second: OptionDropdown<AnimationPlaybackMode>(
            label: '工程播放方式',
            value: project.timeline.playbackMode,
            options: AnimationPlaybackMode.values,
            labelBuilder: _animationPlaybackModeLabel,
            onChanged: enabled ? onPlaybackModeChanged : null,
          ),
        ),
        const SizedBox(height: 8),
        ResponsivePair(
          first: IntegerStepperField(
            label: 'GIF 循环次数',
            value: project.exportSettings.loopCount,
            minValue: 0,
            maxValue: 99,
            suffixText: '次',
            enabled: enabled,
            onChanged: onLoopCountChanged,
          ),
          second: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('导出包含隐藏轨道'),
            value: project.exportSettings.includeHiddenTracks,
            onChanged: enabled ? onIncludeHiddenTracksChanged : null,
          ),
        ),
      ],
    );
  }
}

class _AssetDiagnosticsSection extends StatefulWidget {
  const _AssetDiagnosticsSection({
    required this.project,
    required this.enabled,
    required this.onAssetRebound,
    required this.onProjectAutoRepaired,
  });

  final AnimationProject project;
  final bool enabled;
  final ValueChanged<String> onAssetRebound;
  final VoidCallback onProjectAutoRepaired;

  @override
  State<_AssetDiagnosticsSection> createState() =>
      _AssetDiagnosticsSectionState();
}

class _AssetDiagnosticsSectionState extends State<_AssetDiagnosticsSection> {
  Future<AnimationProjectAssetDiagnostics>? _future;
  AnimationProject? _lastProject;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _AssetDiagnosticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshIfNeeded();
  }

  void _refreshIfNeeded() {
    if (identical(_lastProject, widget.project)) {
      return;
    }
    _lastProject = widget.project;
    _future = _inspect(widget.project);
  }

  Future<AnimationProjectAssetDiagnostics> _inspect(AnimationProject project) {
    return const AnimationProjectAssetInspector().inspect(project);
  }

  void _refresh() {
    setState(() {
      _future = _inspect(widget.project);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('资源诊断', style: theme.textTheme.titleSmall)),
            TextButton.icon(
              onPressed: widget.enabled ? _refresh : null,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('重新检查'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<AnimationProjectAssetDiagnostics>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _AssetDiagnosticsSurface(
                icon: Icons.manage_search_outlined,
                title: '正在检查帧资源',
                message: '正在验证工程引用的帧文件。',
                color: theme.colorScheme.primary,
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _AssetDiagnosticsSurface(
                icon: Icons.error_outline,
                title: '资源检查失败',
                message: '${snapshot.error ?? '没有可用的检查结果'}',
                color: theme.colorScheme.error,
              );
            }

            final diagnostics = snapshot.data!;
            if (!diagnostics.hasIssues) {
              return _AssetDiagnosticsSurface(
                icon: Icons.check_circle_outline,
                title: '资源完整',
                message:
                    '${diagnostics.totalAssetCount} 个帧资源可用，'
                    '${diagnostics.referencedAssetCount} 个被时间轴引用。',
                color: theme.colorScheme.primary,
              );
            }

            final missingTimelineCount =
                diagnostics.missingReferencedAssetCount;
            final hasMissingAssets = diagnostics.hasMissingAssets;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (hasMissingAssets
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.secondaryContainer)
                        .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasMissingAssets
                      ? theme.colorScheme.error
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasMissingAssets
                            ? Icons.warning_amber_outlined
                            : Icons.inventory_2_outlined,
                        color: hasMissingAssets
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasMissingAssets ? '缺失资源' : '工程可修复',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: hasMissingAssets
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasMissingAssets && missingTimelineCount > 0
                        ? '$missingTimelineCount 个被时间轴引用的资源缺失，预览和导出会失败。'
                        : hasMissingAssets
                        ? '发现未引用的缺失资源，当前预览不受影响。'
                        : '发现可自动修复的工程一致性问题。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasMissingAssets
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (diagnostics.hasAutoRepairableIssues) ...[
                    const SizedBox(height: 8),
                    _AutoRepairSummary(
                      diagnostics: diagnostics,
                      enabled: widget.enabled,
                      onProjectAutoRepaired: widget.onProjectAutoRepaired,
                    ),
                  ],
                  if (diagnostics.hasMissingAssets) ...[
                    const SizedBox(height: 10),
                    for (final issue in diagnostics.missingAssets) ...[
                      _AssetIssueRow(
                        issue: issue,
                        enabled: widget.enabled,
                        onAssetRebound: widget.onAssetRebound,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AssetDiagnosticsSurface extends StatelessWidget {
  const _AssetDiagnosticsSurface({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoRepairSummary extends StatelessWidget {
  const _AutoRepairSummary({
    required this.diagnostics,
    required this.enabled,
    required this.onProjectAutoRepaired,
  });

  final AnimationProjectAssetDiagnostics diagnostics;
  final bool enabled;
  final VoidCallback onProjectAutoRepaired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assets = diagnostics.unusedAssets;
    final previewNames = assets
        .take(3)
        .map((asset) {
          final path = asset.path.trim();
          return path.isEmpty ? asset.id : fileNameFromPath(path);
        })
        .join('、');
    final extraCount = assets.length > 3 ? ' 等 ${assets.length} 个' : '';
    final details = [
      if (diagnostics.unusedAssetCount > 0)
        '未引用资源 ${diagnostics.unusedAssetCount} 个',
      if (diagnostics.invalidFrameReferenceCount > 0)
        '空帧引用 ${diagnostics.invalidFrameReferenceCount} 个',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '可自动修复 ${diagnostics.autoRepairableIssueCount} 项',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    details.join(' · '),
                    if (previewNames.isNotEmpty) '$previewNames$extraCount',
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: enabled ? onProjectAutoRepaired : null,
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('自动修复可处理项'),
          ),
        ],
      ),
    );
  }
}

class _AssetIssueRow extends StatelessWidget {
  const _AssetIssueRow({
    required this.issue,
    required this.enabled,
    required this.onAssetRebound,
  });

  final AnimationProjectAssetIssue issue;
  final bool enabled;
  final ValueChanged<String> onAssetRebound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = issue.asset;
    final fileName = asset.path.trim().isEmpty
        ? '未记录路径'
        : fileNameFromPath(asset.path);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.broken_image_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${issue.message} · 时间轴引用 ${issue.referenceCount} 次',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: enabled ? () => onAssetRebound(asset.id) : null,
            icon: const Icon(Icons.link_outlined),
            label: const Text('重新绑定'),
          ),
        ],
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({
    required this.project,
    required this.selectedTrackId,
    required this.onTrackSelected,
    required this.onTrackDuplicated,
    required this.onTrackDeleted,
    required this.onTrackMoved,
    required this.onTrackRenamed,
    required this.onTrackDelayChanged,
    required this.onTrackPlaybackModeChanged,
    required this.onTrackVisibilityChanged,
    required this.onTrackLockChanged,
  });

  final AnimationProject project;
  final String? selectedTrackId;
  final ValueChanged<String> onTrackSelected;
  final ValueChanged<String> onTrackDuplicated;
  final ValueChanged<String> onTrackDeleted;
  final void Function(String trackId, int delta) onTrackMoved;
  final void Function(String trackId, String name) onTrackRenamed;
  final void Function(String trackId, int delayMs) onTrackDelayChanged;
  final void Function(String trackId, AnimationPlaybackMode mode)
  onTrackPlaybackModeChanged;
  final void Function(String trackId, bool visible) onTrackVisibilityChanged;
  final void Function(String trackId, bool locked) onTrackLockChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('轨道', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (var index = 0; index < project.tracks.length; index++) ...[
          Builder(
            builder: (context) {
              final track = project.tracks[index];
              return _TrackTile(
                track: track,
                selected: track.id == selectedTrackId,
                canMoveUp: index > 0,
                canMoveDown: index < project.tracks.length - 1,
                canDelete: project.tracks.length > 1,
                onSelected: () => onTrackSelected(track.id),
                onDuplicated: () => onTrackDuplicated(track.id),
                onDeleted: () => onTrackDeleted(track.id),
                onMoveUp: () => onTrackMoved(track.id, -1),
                onMoveDown: () => onTrackMoved(track.id, 1),
                onRenamed: (name) => onTrackRenamed(track.id, name),
                onDelayChanged: (delay) => onTrackDelayChanged(track.id, delay),
                onPlaybackModeChanged: (mode) =>
                    onTrackPlaybackModeChanged(track.id, mode),
                onVisibilityChanged: (visible) =>
                    onTrackVisibilityChanged(track.id, visible),
                onLockChanged: (locked) => onTrackLockChanged(track.id, locked),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TrackTile extends StatefulWidget {
  const _TrackTile({
    required this.track,
    required this.selected,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canDelete,
    required this.onSelected,
    required this.onDuplicated,
    required this.onDeleted,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRenamed,
    required this.onDelayChanged,
    required this.onPlaybackModeChanged,
    required this.onVisibilityChanged,
    required this.onLockChanged,
  });

  final AnimationTrack track;
  final bool selected;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool canDelete;
  final VoidCallback onSelected;
  final VoidCallback onDuplicated;
  final VoidCallback onDeleted;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final ValueChanged<String> onRenamed;
  final ValueChanged<int> onDelayChanged;
  final ValueChanged<AnimationPlaybackMode> onPlaybackModeChanged;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<bool> onLockChanged;

  @override
  State<_TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<_TrackTile> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.track.name);
  }

  @override
  void didUpdateWidget(covariant _TrackTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.track.name != oldWidget.track.name &&
        _controller.text != widget.track.name) {
      _controller.text = widget.track.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: widget.onSelected,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      IconButton.filledTonal(
                        tooltip: '上移轨道',
                        onPressed: widget.canMoveUp ? widget.onMoveUp : null,
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton.filledTonal(
                        tooltip: '下移轨道',
                        onPressed: widget.canMoveDown
                            ? widget.onMoveDown
                            : null,
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      IconButton.filledTonal(
                        tooltip: '复制轨道',
                        onPressed: widget.onDuplicated,
                        icon: const Icon(Icons.content_copy_outlined),
                      ),
                      IconButton.filledTonal(
                        tooltip: '删除轨道',
                        onPressed: widget.canDelete ? widget.onDeleted : null,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: widget.track.visible ? '隐藏轨道' : '显示轨道',
                  onPressed: () =>
                      widget.onVisibilityChanged(!widget.track.visible),
                  icon: Icon(
                    widget.track.visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                IconButton(
                  tooltip: widget.track.locked ? '解锁轨道' : '锁定轨道',
                  onPressed: () => widget.onLockChanged(!widget.track.locked),
                  icon: Icon(
                    widget.track.locked
                        ? Icons.lock_outline
                        : Icons.lock_open_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '轨道名称',
                isDense: true,
              ),
              onSubmitted: widget.onRenamed,
              onEditingComplete: () => widget.onRenamed(_controller.text),
            ),
            const SizedBox(height: 8),
            ResponsivePair(
              first: IntegerStepperField(
                label: '帧时长',
                value: widget.track.defaultDelayMs,
                minValue: 20,
                maxValue: 2000,
                suffixText: 'ms',
                onChanged: widget.onDelayChanged,
              ),
              second: OptionDropdown<AnimationPlaybackMode>(
                label: '播放方式',
                value: widget.track.playbackMode,
                options: AnimationPlaybackMode.values,
                labelBuilder: _animationPlaybackModeLabel,
                onChanged: widget.onPlaybackModeChanged,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.track.totalFrameRefs} 帧',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimationTimelinePanel extends StatefulWidget {
  const _AnimationTimelinePanel({
    required this.project,
    required this.track,
    required this.onFrameMoved,
    required this.onFrameDuplicated,
    required this.onFrameDeleted,
    required this.onFrameDelayChanged,
    required this.onFrameTransformChanged,
  });

  final AnimationProject project;
  final AnimationTrack? track;
  final void Function(String trackId, int fromIndex, int toIndex) onFrameMoved;
  final void Function(String trackId, int frameIndex) onFrameDuplicated;
  final void Function(String trackId, int frameIndex) onFrameDeleted;
  final void Function(String trackId, int frameIndex, int delayMs)
  onFrameDelayChanged;
  final void Function(String trackId, int frameIndex, FrameTransform transform)
  onFrameTransformChanged;

  @override
  State<_AnimationTimelinePanel> createState() =>
      _AnimationTimelinePanelState();
}

class _AnimationTimelinePanelState extends State<_AnimationTimelinePanel> {
  int _selectedFrameIndex = 0;

  @override
  void didUpdateWidget(covariant _AnimationTimelinePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track?.id != widget.track?.id) {
      _selectedFrameIndex = 0;
      return;
    }
    _selectedFrameIndex = _clampedSelectedIndex;
  }

  int get _clampedSelectedIndex {
    final frames = widget.track?.orderedFrames ?? const <FrameRef>[];
    if (frames.isEmpty) {
      return 0;
    }
    return _selectedFrameIndex.clamp(0, frames.length - 1).toInt();
  }

  void _selectFrame(int index) {
    setState(() => _selectedFrameIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final theme = Theme.of(context);
    if (track == null) {
      return _TimelineEmptyState(message: '先选择一条轨道');
    }

    final frames = track.orderedFrames;
    if (frames.isEmpty) {
      return _TimelineEmptyState(
        message: track.locked ? '轨道已锁定，当前没有序列帧' : '当前轨道没有序列帧',
      );
    }

    final selectedIndex = _clampedSelectedIndex;
    final selectedFrame = frames[selectedIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('序列帧时间轴', style: theme.textTheme.titleSmall)),
            Text(
              '${track.name} · ${frames.length} 帧',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SelectedFrameEditor(
          enabled: !track.locked,
          frameIndex: selectedIndex,
          frame: selectedFrame,
          canvasWidth: widget.project.canvasWidth,
          canvasHeight: widget.project.canvasHeight,
          onDelayChanged: (delayMs) =>
              widget.onFrameDelayChanged(track.id, selectedIndex, delayMs),
          onTransformChanged: (transform) => widget.onFrameTransformChanged(
            track.id,
            selectedIndex,
            transform,
          ),
          onDuplicated: () => widget.onFrameDuplicated(track.id, selectedIndex),
          onDeleted: frames.length <= 1
              ? null
              : () => widget.onFrameDeleted(track.id, selectedIndex),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 148,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            itemCount: frames.length,
            onReorder: (oldIndex, newIndex) {
              if (track.locked) {
                return;
              }
              final targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
              widget.onFrameMoved(track.id, oldIndex, targetIndex);
              setState(() => _selectedFrameIndex = targetIndex);
            },
            itemBuilder: (context, index) {
              final frame = frames[index];
              return _TimelineFrameTile(
                key: ValueKey('${track.id}_${frame.assetId}_$index'),
                project: widget.project,
                frame: frame,
                index: index,
                selected: index == selectedIndex,
                locked: track.locked,
                onSelected: () => _selectFrame(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelectedFrameEditor extends StatelessWidget {
  const _SelectedFrameEditor({
    required this.enabled,
    required this.frameIndex,
    required this.frame,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.onDelayChanged,
    required this.onTransformChanged,
    required this.onDuplicated,
    required this.onDeleted,
  });

  final bool enabled;
  final int frameIndex;
  final FrameRef frame;
  final int canvasWidth;
  final int canvasHeight;
  final ValueChanged<int> onDelayChanged;
  final ValueChanged<FrameTransform> onTransformChanged;
  final VoidCallback onDuplicated;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transform = frame.transform;
    final xLimit = canvasWidth <= 0 ? 1.0 : canvasWidth.toDouble();
    final yLimit = canvasHeight <= 0 ? 1.0 : canvasHeight.toDouble();
    final offsetX = transform.offsetX.clamp(-xLimit, xLimit).toDouble();
    final offsetY = transform.offsetY.clamp(-yLimit, yLimit).toDouble();
    final opacity = transform.opacity.clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsivePair(
          first: IntegerStepperField(
            label: '单帧时长',
            value: frame.delayMs,
            minValue: 20,
            maxValue: 2000,
            suffixText: 'ms',
            enabled: enabled,
            onChanged: onDelayChanged,
          ),
          second: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('当前帧 ${frameIndex + 1}'),
                FilledButton.tonalIcon(
                  onPressed: enabled ? onDuplicated : null,
                  icon: const Icon(Icons.content_copy_outlined),
                  label: const Text('复制帧'),
                ),
                FilledButton.tonalIcon(
                  onPressed: enabled ? onDeleted : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除帧'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Text('单帧变换', style: theme.textTheme.labelLarge)),
            Tooltip(
              message: '水平翻转',
              child: IconButton(
                onPressed: enabled
                    ? () => onTransformChanged(
                        transform.copyWith(flipX: !transform.flipX),
                      )
                    : null,
                color: transform.flipX ? theme.colorScheme.primary : null,
                icon: const Icon(Icons.swap_horiz),
              ),
            ),
            Tooltip(
              message: '垂直翻转',
              child: IconButton(
                onPressed: enabled
                    ? () => onTransformChanged(
                        transform.copyWith(flipY: !transform.flipY),
                      )
                    : null,
                color: transform.flipY ? theme.colorScheme.primary : null,
                icon: const Icon(Icons.swap_vert),
              ),
            ),
            Tooltip(
              message: '重置单帧变换',
              child: IconButton(
                onPressed: enabled && !transform.isIdentity
                    ? () => onTransformChanged(const FrameTransform())
                    : null,
                icon: const Icon(Icons.restart_alt),
              ),
            ),
          ],
        ),
        _FrameTransformSlider(
          label: 'X',
          valueLabel: '${offsetX.round()}px',
          value: offsetX,
          min: -xLimit,
          max: xLimit,
          divisions: (xLimit * 2).round(),
          enabled: enabled,
          onChanged: (value) => onTransformChanged(
            transform.copyWith(offsetX: value.roundToDouble()),
          ),
        ),
        _FrameTransformSlider(
          label: 'Y',
          valueLabel: '${offsetY.round()}px',
          value: offsetY,
          min: -yLimit,
          max: yLimit,
          divisions: (yLimit * 2).round(),
          enabled: enabled,
          onChanged: (value) => onTransformChanged(
            transform.copyWith(offsetY: value.roundToDouble()),
          ),
        ),
        _FrameTransformSlider(
          label: '不透明度',
          valueLabel: '${(opacity * 100).round()}%',
          value: opacity,
          min: 0,
          max: 1,
          divisions: 20,
          enabled: enabled,
          onChanged: (value) =>
              onTransformChanged(transform.copyWith(opacity: value)),
        ),
      ],
    );
  }
}

class _FrameTransformSlider extends StatelessWidget {
  const _FrameTransformSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 88, child: Text('$label $valueLabel')),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions <= 0 ? null : divisions,
            label: valueLabel,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

class _TimelineFrameTile extends StatelessWidget {
  const _TimelineFrameTile({
    required super.key,
    required this.project,
    required this.frame,
    required this.index,
    required this.selected,
    required this.locked,
    required this.onSelected,
  });

  final AnimationProject project;
  final FrameRef frame;
  final int index;
  final bool selected;
  final bool locked;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = project.assetById(frame.assetId);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 104,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.58)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: double.infinity,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: asset == null || asset.path.isEmpty
                        ? const Icon(Icons.broken_image_outlined)
                        : Image.file(
                            File(asset.path),
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'F${index + 1} · ${frame.delayMs}ms',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  if (!locked)
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_indicator, size: 18),
                    )
                  else
                    const Icon(Icons.lock_outline, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(message, style: theme.textTheme.bodyMedium),
    );
  }
}

class _AnimationProjectPreview extends StatefulWidget {
  const _AnimationProjectPreview({
    required this.project,
    required this.isGenerating,
    required this.generationErrorMessage,
    required this.debugRecord,
    required this.generatedImages,
    required this.sourceRows,
    required this.sourceColumns,
    required this.sourceGridSpec,
    required this.onGenerate,
    required this.onExportSourceSpriteSheet,
    required this.onExportRenderedSpriteSheet,
    required this.onSendRenderedToGif,
    required this.onOpenRenderedInEditor,
    required this.enablePlayback,
  });

  final AnimationProject? project;
  final bool isGenerating;
  final String? generationErrorMessage;
  final ImageRequestDebugRecord? debugRecord;
  final List<GeneratedImage> generatedImages;
  final int sourceRows;
  final int sourceColumns;
  final SpriteSheetGridSpec sourceGridSpec;
  final VoidCallback onGenerate;
  final ValueChanged<Uint8List> onExportSourceSpriteSheet;
  final ValueChanged<AnimationSpriteSheetRender> onExportRenderedSpriteSheet;
  final ValueChanged<AnimationSpriteSheetRender> onSendRenderedToGif;
  final ValueChanged<AnimationSpriteSheetRender> onOpenRenderedInEditor;
  final bool enablePlayback;

  @override
  State<_AnimationProjectPreview> createState() =>
      _AnimationProjectPreviewState();
}

class _AnimationProjectPreviewState extends State<_AnimationProjectPreview> {
  Future<AnimationSpriteSheetRender>? _renderFuture;
  AnimationProject? _lastProject;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshRenderFutureIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _AnimationProjectPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshRenderFutureIfNeeded();
  }

  void _refreshRenderFutureIfNeeded() {
    final project = widget.project;
    if (project == null) {
      _renderFuture = null;
      _lastProject = project;
      return;
    }
    if (identical(_lastProject, project)) {
      return;
    }
    _lastProject = project;
    _renderFuture = _renderProject(project);
  }

  Future<AnimationSpriteSheetRender> _renderProject(AnimationProject project) {
    return const AnimationProjectRenderer().renderProjectSpriteSheet(
      project: project,
    );
  }

  void _retryRender() {
    final project = widget.project;
    if (project == null) {
      return;
    }
    setState(() {
      _renderFuture = _renderProject(project);
    });
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    if (project == null || _renderFuture == null) {
      return FrameAnimationPreviewPanel(
        title: 'Sprite Sheet 来源预览',
        emptyMessage: '生成 Sprite Sheet 后，可以导入为动画工程。',
        errorMessage: widget.generationErrorMessage,
        debugRecord: widget.debugRecord,
        generatedImages: widget.generatedImages,
        isGenerating: widget.isGenerating,
        rows: widget.sourceRows,
        columns: widget.sourceColumns,
        gridSpec: widget.sourceGridSpec,
        labelBuilder: (index) =>
            animationFrameGridLabel(index, columns: widget.sourceColumns),
        onRetry: widget.onGenerate,
        onExportSpriteSheet: widget.onExportSourceSpriteSheet,
        enablePlayback: widget.enablePlayback,
      );
    }

    return FutureBuilder<AnimationSpriteSheetRender>(
      future: _renderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PreviewPanelShell(
            title: '动画工程预览',
            child: PreviewStateSurface.loading(message: '正在渲染工程合成'),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return PreviewPanelShell(
            title: '动画工程预览',
            child: PreviewStateSurface.error(
              title: '渲染失败',
              message: '${snapshot.error ?? '没有可用的渲染数据'}',
              onRetry: _retryRender,
              retryLabel: '重新渲染',
            ),
          );
        }
        final render = snapshot.data!;
        return FrameAnimationPreviewPanel(
          title: '动画工程预览',
          emptyMessage: '工程没有可见帧',
          errorMessage: null,
          debugRecord: null,
          generatedImages: [GeneratedImage.bytes(render.bytes)],
          isGenerating: false,
          rows: render.rows,
          columns: render.columns,
          gridSpec: render.gridSpec,
          labelBuilder: (index) => '合成帧 ${index + 1}',
          onExportSpriteSheet: (_) =>
              widget.onExportRenderedSpriteSheet(render),
          onSendToGif: (_) => widget.onSendRenderedToGif(render),
          onOpenInEditor: (_) => widget.onOpenRenderedInEditor(render),
          enablePlayback: widget.enablePlayback,
          frameDelayMsByIndex: render.frameDelayMs,
        );
      },
    );
  }
}

String _animationPlaybackModeLabel(AnimationPlaybackMode mode) {
  final gifMode = switch (mode) {
    AnimationPlaybackMode.normal => GifPlaybackMode.normal,
    AnimationPlaybackMode.reverse => GifPlaybackMode.reverse,
    AnimationPlaybackMode.pingPong => GifPlaybackMode.pingPong,
  };
  return gifPlaybackModeLabel(gifMode);
}

AnimationTrack? _selectedTrack(AnimationProject project, String? selectedId) {
  if (selectedId != null) {
    final selected = project.trackById(selectedId);
    if (selected != null) {
      return selected;
    }
  }
  return project.tracks.isEmpty ? null : project.tracks.first;
}
