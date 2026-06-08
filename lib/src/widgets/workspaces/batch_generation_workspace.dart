import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/api_provider.dart';
import '../../models/app_config.dart';
import '../../models/batch_generation_job.dart';
import '../../models/generated_image.dart';
import '../../models/image_advanced_settings.dart';
import '../../state/batch_generation_notifier.dart';
import '../../l10n/app_l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/layout_constants.dart';
import '../../utils/batch_generation_view_data.dart';
import '../../utils/generation_limits.dart';
import '../../utils/image_dimensions.dart';
import '../../utils/localized_display_labels.dart';
import '../api_settings_widgets.dart';
import '../common_form_widgets.dart';
import '../image_advanced_settings_widgets.dart';
import '../image_size_widgets.dart';
import '../layout_navigation_widgets.dart';
import '../preview_widgets.dart';

class BatchGenerationWorkspace extends StatelessWidget {
  const BatchGenerationWorkspace({
    required this.promptController,
    required this.negativePromptController,
    required this.userController,
    required this.apiConfigs,
    required this.selectedApiConfig,
    required this.selectedApiConfigId,
    required this.providerKind,
    required this.imageSizeCapabilityOverride,
    required this.size,
    required this.advancedSettings,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onAdvancedSettingsChanged,
    required this.onTargetCountChanged,
    required this.onRequestCountChanged,
    required this.onAddPrompts,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onCancelQueued,
    required this.onRetryFailed,
    required this.onRemoveJob,
    required this.onRetryJob,
    required this.onClearFinished,
    required this.onCopyImage,
    required this.onExportImage,
    required this.onMakeBackgroundTransparent,
    super.key,
  });

  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final TextEditingController userController;
  final List<ApiConfig> apiConfigs;
  final ApiConfig selectedApiConfig;
  final String selectedApiConfigId;
  final ApiProviderKind providerKind;
  final ImageSizeCapabilityOverride imageSizeCapabilityOverride;
  final String size;
  final ImageAdvancedSettings advancedSettings;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final ValueChanged<int> onTargetCountChanged;
  final ValueChanged<int> onRequestCountChanged;
  final VoidCallback onAddPrompts;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancelQueued;
  final VoidCallback onRetryFailed;
  final ValueChanged<BatchGenerationJob> onRemoveJob;
  final ValueChanged<BatchGenerationJob> onRetryJob;
  final VoidCallback onClearFinished;
  final void Function(int index, GeneratedImage image) onCopyImage;
  final void Function(int index, GeneratedImage image) onExportImage;
  final void Function(int index, GeneratedImage image)
  onMakeBackgroundTransparent;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    return WorkspacePage(
      title: l10n.batchGenerationWorkspaceTitle,
      description: l10n.batchGenerationWorkspaceDescription,
      scrollable: false,
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: _BatchGenerationWorkspaceLayout(
              controls: _BatchGenerationControls(
                promptController: promptController,
                negativePromptController: negativePromptController,
                userController: userController,
                apiConfigs: apiConfigs,
                selectedApiConfig: selectedApiConfig,
                selectedApiConfigId: selectedApiConfigId,
                providerKind: providerKind,
                imageSizeCapabilityOverride: imageSizeCapabilityOverride,
                size: size,
                advancedSettings: advancedSettings,
                onApiConfigChanged: onApiConfigChanged,
                onOpenApiSettings: onOpenApiSettings,
                onSizeChanged: onSizeChanged,
                onAdvancedSettingsChanged: onAdvancedSettingsChanged,
                onTargetCountChanged: onTargetCountChanged,
                onRequestCountChanged: onRequestCountChanged,
                onAddPrompts: onAddPrompts,
                onStart: onStart,
                onPause: onPause,
                onResume: onResume,
                onCancelQueued: onCancelQueued,
                onRetryFailed: onRetryFailed,
                onClearFinished: onClearFinished,
              ),
              preview: Consumer<BatchGenerationNotifier>(
                builder: (context, notifier, _) {
                  final jobs = notifier.jobs;
                  final summary = summarizeBatchGenerationJobs(
                    jobs,
                    fallbackSize: size,
                  );
                  return _BatchGenerationPreviewPane(
                    jobs: jobs,
                    summary: summary,
                    isRunning: notifier.isRunning,
                    onStart: onStart,
                    onRemoveJob: onRemoveJob,
                    onRetryJob: onRetryJob,
                    onPreviewJobImages: (job) =>
                        _showBatchJobImagesPreviewDialog(
                          context,
                          l10n,
                          jobs,
                          job,
                        ),
                    onCopyImage: onCopyImage,
                    onExportImage: onExportImage,
                    onMakeBackgroundTransparent: onMakeBackgroundTransparent,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showBatchJobImagesPreviewDialog(
    BuildContext context,
    AppLocalizations l10n,
    List<BatchGenerationJob> jobs,
    BatchGenerationJob job,
  ) {
    final images = job.resultImages;
    if (images.isEmpty) {
      return;
    }

    final jobNumber = _batchJobDisplayNumber(jobs, job);
    showGeneratedImagePreviewDialog(
      context,
      image: images.first,
      images: images,
      title: _batchJobImagePreviewTitle(l10n, job, jobNumber, 0),
      titleBuilder: (index, _) =>
          _batchJobImagePreviewTitle(l10n, job, jobNumber, index),
      onCopyImageAt: (index, image) =>
          onCopyImage(_batchResultImageGlobalIndex(jobs, job, index), image),
      onExportImageAt: (index, image) =>
          onExportImage(_batchResultImageGlobalIndex(jobs, job, index), image),
    );
  }
}

class _BatchGenerationWorkspaceLayout extends StatelessWidget {
  const _BatchGenerationWorkspaceLayout({
    required this.controls,
    required this.preview,
  });

  final Widget controls;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.medium) {
          return _ScrollableWorkspacePane(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                controls,
                const SizedBox(height: layoutGap),
                preview,
              ],
            ),
          );
        }

        return ResponsiveWorkspaceSplit(
          storageKey: 'batch_generation',
          controls: _ScrollableWorkspacePane(child: controls),
          preview: preview,
        );
      },
    );
  }
}

class _ScrollableWorkspacePane extends StatefulWidget {
  const _ScrollableWorkspacePane({required this.child});

  final Widget child;

  @override
  State<_ScrollableWorkspacePane> createState() =>
      _ScrollableWorkspacePaneState();
}

class _ScrollableWorkspacePaneState extends State<_ScrollableWorkspacePane> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Scrollbar(
        controller: _controller,
        child: SingleChildScrollView(
          controller: _controller,
          child: widget.child,
        ),
      ),
    );
  }
}

class _BatchGenerationPreviewPane extends StatelessWidget {
  const _BatchGenerationPreviewPane({
    required this.jobs,
    required this.summary,
    required this.isRunning,
    required this.onStart,
    required this.onRemoveJob,
    required this.onRetryJob,
    required this.onPreviewJobImages,
    required this.onCopyImage,
    required this.onExportImage,
    required this.onMakeBackgroundTransparent,
  });

  final List<BatchGenerationJob> jobs;
  final BatchGenerationJobSummary summary;
  final bool isRunning;
  final VoidCallback onStart;
  final ValueChanged<BatchGenerationJob> onRemoveJob;
  final ValueChanged<BatchGenerationJob> onRetryJob;
  final ValueChanged<BatchGenerationJob> onPreviewJobImages;
  final void Function(int index, GeneratedImage image) onCopyImage;
  final void Function(int index, GeneratedImage image) onExportImage;
  final void Function(int index, GeneratedImage image)
  onMakeBackgroundTransparent;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    Widget buildPreviewPanel({required bool expandChild}) {
      return PreviewPanel(
        errorMessage: null,
        generatedImages: summary.previewImages,
        isGenerating: isRunning,
        targetImageCount: summary.targetImageCount,
        targetAspectRatio: summary.previewAspectRatio,
        expandTallPreview: true,
        expandChild: expandChild,
        imageSourceLabels: [
          for (final source in summary.previewImageSources)
            _batchPreviewSourceLabel(l10n, source),
        ],
        noticeMessage: summary.isPreviewTruncated
            ? l10n.batchPreviewTruncatedNotice(
                summary.returnedImageCount,
                summary.previewImages.length,
                summary.hiddenPreviewImageCount,
              )
            : null,
        debugRecord: summary.latestDebugRecord,
        onRetry: onStart,
        onCopyImage: onCopyImage,
        onExportImage: onExportImage,
        onMakeBackgroundTransparent: onMakeBackgroundTransparent,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final canUseSplitPreview =
            hasBoundedHeight && constraints.maxWidth >= AppBreakpoints.expanded;

        if (!hasBoundedHeight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BatchGenerationSummaryPanel(summary: summary),
              const SizedBox(height: layoutGap),
              _BatchGenerationJobList(
                jobs: jobs,
                onRemoveJob: onRemoveJob,
                onRetryJob: onRetryJob,
                onPreviewJobImages: onPreviewJobImages,
              ),
              const SizedBox(height: layoutGap),
              buildPreviewPanel(expandChild: false),
            ],
          );
        }

        if (canUseSplitPreview) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BatchGenerationSummaryPanel(summary: summary),
              const SizedBox(height: layoutGap),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      flex: 5,
                      child: _BatchGenerationJobList(
                        jobs: jobs,
                        expandList: true,
                        onRemoveJob: onRemoveJob,
                        onRetryJob: onRetryJob,
                        onPreviewJobImages: onPreviewJobImages,
                      ),
                    ),
                    const SizedBox(width: layoutGap),
                    Flexible(
                      flex: 6,
                      child: buildPreviewPanel(expandChild: true),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BatchGenerationSummaryPanel(summary: summary),
            const SizedBox(height: layoutGap),
            Flexible(
              flex: 4,
              child: _BatchGenerationJobList(
                jobs: jobs,
                expandList: true,
                onRemoveJob: onRemoveJob,
                onRetryJob: onRetryJob,
                onPreviewJobImages: onPreviewJobImages,
              ),
            ),
            const SizedBox(height: layoutGap),
            Flexible(flex: 6, child: buildPreviewPanel(expandChild: true)),
          ],
        );
      },
    );
  }
}

class _BatchGenerationSummaryPanel extends StatelessWidget {
  const _BatchGenerationSummaryPanel({required this.summary});

  final BatchGenerationJobSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = [
      _BatchSummaryStat(
        label: l10n.batchSummaryTotalJobsLabel,
        value: '${summary.totalJobCount}',
        icon: Icons.format_list_bulleted_outlined,
      ),
      _BatchSummaryStat(
        label: l10n.batchSummaryRequestedImagesLabel,
        value: '${summary.requestedImageCount}',
        icon: Icons.all_inclusive_outlined,
      ),
      _BatchSummaryStat(
        label: l10n.batchSummaryReturnedImagesLabel,
        value: '${summary.returnedImageCount}',
        icon: Icons.image_outlined,
      ),
      _BatchSummaryStat(
        label: l10n.batchSummaryPreviewImagesLabel,
        value: '${summary.previewImages.length}',
        icon: Icons.grid_view_outlined,
      ),
      _BatchSummaryStat(
        label: l10n.batchSummaryFailedJobsLabel,
        value: '${summary.failedCount}',
        icon: Icons.error_outline,
      ),
    ];

    return AppPanel(
      title: l10n.batchSummaryPanelTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720
                  ? 5
                  : constraints.maxWidth >= 420
                  ? 2
                  : 1;
              const statHeight = 64.0;
              final rowCount = (stats.length / columns).ceil();

              return SizedBox(
                height: rowCount * statHeight + (rowCount - 1) * 8,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  primary: false,
                  itemCount: stats.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: statHeight,
                  ),
                  itemBuilder: (context, index) => stats[index],
                ),
              );
            },
          ),
          if (summary.isPreviewTruncated) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.batchPreviewTruncatedNotice(
                          summary.returnedImageCount,
                          summary.previewImages.length,
                          summary.hiddenPreviewImageCount,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchSummaryStat extends StatelessWidget {
  const _BatchSummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: 30,
              child: Center(
                child: Icon(icon, size: 20, color: colorScheme.primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchGenerationControls extends StatelessWidget {
  const _BatchGenerationControls({
    required this.promptController,
    required this.negativePromptController,
    required this.userController,
    required this.apiConfigs,
    required this.selectedApiConfig,
    required this.selectedApiConfigId,
    required this.providerKind,
    required this.imageSizeCapabilityOverride,
    required this.size,
    required this.advancedSettings,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onAdvancedSettingsChanged,
    required this.onTargetCountChanged,
    required this.onRequestCountChanged,
    required this.onAddPrompts,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onCancelQueued,
    required this.onRetryFailed,
    required this.onClearFinished,
  });

  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final TextEditingController userController;
  final List<ApiConfig> apiConfigs;
  final ApiConfig selectedApiConfig;
  final String selectedApiConfigId;
  final ApiProviderKind providerKind;
  final ImageSizeCapabilityOverride imageSizeCapabilityOverride;
  final String size;
  final ImageAdvancedSettings advancedSettings;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final ValueChanged<int> onTargetCountChanged;
  final ValueChanged<int> onRequestCountChanged;
  final VoidCallback onAddPrompts;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancelQueued;
  final VoidCallback onRetryFailed;
  final VoidCallback onClearFinished;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final notifier = context.watch<BatchGenerationNotifier>();
    final jobs = notifier.jobs;
    final targetCount = notifier.targetCount;
    final requestCount = notifier.requestCount;
    final isRunning = notifier.isRunning;
    final isPausing = notifier.pauseAfterCurrent;
    final summary = summarizeBatchGenerationJobs(jobs, fallbackSize: size);
    final sizeValidation = validateImageSizeForModel(
      size: size,
      providerKind: providerKind,
      model: selectedApiConfig.model,
      capabilityOverride: imageSizeCapabilityOverride,
      labels: localizedImageSizeDisplayLabels(l10n),
    );
    final controlsState = deriveBatchQueueControlsState(
      isRunning: isRunning,
      isPausing: isPausing,
      queuedCount: summary.queuedCount,
      finishedCount: summary.finishedCount,
      failedCount: summary.failedCount,
      isSizeValid: sizeValidation.isValid,
    );
    final queuedCount = summary.queuedCount;
    final runningCount = summary.runningCount;
    final finishedCount = summary.finishedCount;
    final failedCount = summary.failedCount;
    final batchCount = splitImageGenerationBatches(
      targetCount: targetCount,
      requestCount: requestCount,
    ).length;
    final startQueueLabel = finishedCount > 0
        ? l10n.batchContinueQueue
        : l10n.batchStartQueue;
    final startDisabledReason = _batchQueueControlDisabledReason(
      l10n: l10n,
      blocker: controlsState.startBlocker,
      validationMessage: sizeValidation.message,
    );
    final pauseDisabledReason = _batchQueueControlDisabledReason(
      l10n: l10n,
      blocker: controlsState.pauseBlocker,
    );
    final retryFailedLabel = failedCount == 0
        ? l10n.batchRetryFailed
        : l10n.batchRetryFailedCount(failedCount);
    final retryDisabledReason = _batchQueueControlDisabledReason(
      l10n: l10n,
      blocker: controlsState.retryFailedBlocker,
    );
    final clearFinishedDisabledReason = _batchQueueControlDisabledReason(
      l10n: l10n,
      blocker: controlsState.clearFinishedBlocker,
    );

    return AppPanel(
      title: l10n.batchQueueControlTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ApiConfigSelector(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfigId,
            enabled: !isRunning,
            onChanged: onApiConfigChanged,
            onOpenSettings: onOpenApiSettings,
          ),
          const SizedBox(height: fieldGap),
          TextField(
            controller: promptController,
            minLines: 7,
            maxLines: 12,
            decoration: InputDecoration(
              labelText: l10n.batchPromptLabel,
              hintText: l10n.batchPromptHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: fieldGap),
          OptionalPromptExclusionSection(
            controller: negativePromptController,
            labelText: l10n.negativePromptLabel,
            hintText: l10n.batchNegativePromptHint,
            enabled: !isRunning,
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: fieldGap),
          ImageSizeInput(
            size: size,
            providerKind: providerKind,
            model: selectedApiConfig.model,
            capabilityOverride: imageSizeCapabilityOverride,
            enabled: !isRunning,
            onChanged: onSizeChanged,
            compact: true,
          ),
          const SizedBox(height: fieldGap),
          ImageAdvancedSettingsSection(
            settings: advancedSettings,
            userController: userController,
            hasTemplateImage: false,
            enabled: !isRunning,
            onChanged: onAdvancedSettingsChanged,
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: IntegerStepperField(
              label: l10n.targetImageCountLabel,
              value: targetCount,
              minValue: minImageGenerationCount,
              maxValue: maxBatchGenerationTargetCount,
              suffixText: l10n.imageCountSuffix,
              helperText: l10n.batchTargetCountHelper,
              enabled: !isRunning,
              onChanged: onTargetCountChanged,
            ),
            second: IntegerStepperField(
              label: l10n.batchRequestCountLabel,
              value: requestCount,
              minValue: minImageGenerationCount,
              maxValue: maxImageGenerationRequestCount,
              suffixText: l10n.imageCountSuffix,
              helperText: l10n.batchRequestCountHelper(
                maxImageGenerationRequestCount,
              ),
              enabled: !isRunning,
              onChanged: onRequestCountChanged,
            ),
          ),
          const SizedBox(height: 8),
          _BatchQueueStatusNote(
            isRunning: isRunning,
            isPausing: isPausing,
            runningCount: runningCount,
            queuedCount: queuedCount,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.batchSplitStatus(batchCount),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _DisabledActionSemantics(
              label: l10n.batchAddPrompts,
              disabledReason: _batchQueueControlDisabledReason(
                l10n: l10n,
                blocker: controlsState.addPromptsBlocker,
              ),
              child: OutlinedButton.icon(
                onPressed: controlsState.canAddPrompts ? onAddPrompts : null,
                icon: const Icon(Icons.playlist_add_outlined),
                label: Text(l10n.batchAddPrompts),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DisabledActionSemantics(
            label: isRunning ? l10n.batchQueueRunning : startQueueLabel,
            disabledReason: startDisabledReason,
            child: PrimaryActionButton(
              onPressed: controlsState.canStart ? onStart : null,
              icon: Icons.auto_awesome_motion_outlined,
              label: startQueueLabel,
              busyLabel: l10n.batchQueueRunning,
              isBusy: isRunning,
            ),
          ),
          const SizedBox(height: 8),
          ResponsivePair(
            first: _DisabledActionSemantics(
              label: l10n.batchPauseAfterCurrent,
              disabledReason: pauseDisabledReason,
              child: OutlinedButton.icon(
                onPressed: controlsState.canPause ? onPause : null,
                icon: const Icon(Icons.pause_circle_outline),
                label: Text(l10n.batchPauseAfterCurrent),
              ),
            ),
            second: _DisabledActionSemantics(
              label: l10n.batchResumeQueue,
              disabledReason: _batchQueueControlDisabledReason(
                l10n: l10n,
                blocker: controlsState.resumeBlocker,
              ),
              child: OutlinedButton.icon(
                onPressed: controlsState.canResume ? onResume : null,
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l10n.batchResumeQueue),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DisabledActionSemantics(
            label: l10n.batchCancelQueued,
            disabledReason: _batchQueueControlDisabledReason(
              l10n: l10n,
              blocker: controlsState.cancelQueuedBlocker,
            ),
            child: OutlinedButton.icon(
              onPressed: controlsState.canCancelQueued ? onCancelQueued : null,
              icon: const Icon(Icons.cancel_schedule_send_outlined),
              label: Text(l10n.batchCancelQueued),
            ),
          ),
          const SizedBox(height: 8),
          _DisabledActionSemantics(
            label: retryFailedLabel,
            disabledReason: retryDisabledReason,
            child: OutlinedButton.icon(
              onPressed: controlsState.canRetryFailed ? onRetryFailed : null,
              icon: const Icon(Icons.replay_outlined),
              label: Text(retryFailedLabel),
            ),
          ),
          const SizedBox(height: 8),
          _DisabledActionSemantics(
            label: l10n.batchClearFinished,
            disabledReason: clearFinishedDisabledReason,
            child: OutlinedButton.icon(
              onPressed: controlsState.canClearFinished
                  ? onClearFinished
                  : null,
              icon: const Icon(Icons.clear_all_outlined),
              label: Text(l10n.batchClearFinished),
            ),
          ),
        ],
      ),
    );
  }
}

String? _batchQueueControlDisabledReason({
  required AppLocalizations l10n,
  required BatchQueueControlBlocker? blocker,
  String? validationMessage,
}) {
  return switch (blocker) {
    null => null,
    BatchQueueControlBlocker.queueRunning =>
      l10n.batchActionQueueBusyUnavailable,
    BatchQueueControlBlocker.needsQueuedJobs => l10n.batchActionNeedsQueuedJobs,
    BatchQueueControlBlocker.invalidImageSize => validationMessage,
    BatchQueueControlBlocker.queueNotRunning => l10n.batchActionQueueNotRunning,
    BatchQueueControlBlocker.queueAlreadyPausing =>
      l10n.batchActionQueueAlreadyPausing,
    BatchQueueControlBlocker.queueNotPaused => l10n.batchActionQueueNotPaused,
    BatchQueueControlBlocker.noQueuedJobs =>
      l10n.batchGenerationNoQueuedJobsToCancel,
    BatchQueueControlBlocker.noFailedJobs =>
      l10n.batchGenerationNoFailedJobsToRetry,
    BatchQueueControlBlocker.noFinishedJobs => l10n.batchActionNoFinishedJobs,
  };
}

class _DisabledActionSemantics extends StatelessWidget {
  const _DisabledActionSemantics({
    required this.label,
    required this.disabledReason,
    required this.child,
  });

  final String label;
  final String? disabledReason;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (disabledReason == null) {
      return child;
    }

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      value: disabledReason,
      button: true,
      enabled: false,
      child: child,
    );
  }
}

class _BatchQueueStatusNote extends StatelessWidget {
  const _BatchQueueStatusNote({
    required this.isRunning,
    required this.isPausing,
    required this.runningCount,
    required this.queuedCount,
  });

  final bool isRunning;
  final bool isPausing;
  final int runningCount;
  final int queuedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final message = _message(l10n);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isRunning ? Icons.sync_outlined : Icons.info_outline,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _message(AppLocalizations l10n) {
    return switch (batchQueueStatusKind(
      isRunning: isRunning,
      isPausing: isPausing,
      queuedCount: queuedCount,
    )) {
      BatchQueueStatusKind.pausing => l10n.batchQueuePausingStatus(
        runningCount,
      ),
      BatchQueueStatusKind.running => l10n.batchQueueRunningStatus(
        runningCount,
        queuedCount,
      ),
      BatchQueueStatusKind.waiting => l10n.batchQueueWaitingStatus(queuedCount),
      BatchQueueStatusKind.empty => l10n.batchQueueEmptyStatus,
    };
  }
}

class _BatchGenerationJobList extends StatefulWidget {
  const _BatchGenerationJobList({
    required this.jobs,
    required this.onRemoveJob,
    required this.onRetryJob,
    required this.onPreviewJobImages,
    this.expandList = false,
  });

  final List<BatchGenerationJob> jobs;
  final ValueChanged<BatchGenerationJob> onRemoveJob;
  final ValueChanged<BatchGenerationJob> onRetryJob;
  final ValueChanged<BatchGenerationJob> onPreviewJobImages;
  final bool expandList;

  @override
  State<_BatchGenerationJobList> createState() =>
      _BatchGenerationJobListState();
}

class _BatchGenerationJobListState extends State<_BatchGenerationJobList> {
  final ScrollController _controller = ScrollController();
  var _filter = _BatchJobListFilter.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final jobs = widget.jobs;
    if (jobs.isEmpty) {
      return AppPanel(
        title: l10n.batchJobListTitle,
        expandChild: widget.expandList,
        child: Semantics(
          container: true,
          readOnly: true,
          label: l10n.batchJobListEmpty,
          child: Text(
            l10n.batchJobListEmpty,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final visibleJobs = _visibleBatchJobs(jobs, _filter);
    final attentionCount = jobs.where(_batchJobNeedsAttention).length;
    final returnedCount = jobs
        .where((job) => job.resultImages.isNotEmpty)
        .length;

    return AppPanel(
      title: l10n.batchJobListTitle,
      expandChild: widget.expandList,
      trailing: Text(
        visibleJobs.length == jobs.length
            ? l10n.batchJobCount(jobs.length)
            : l10n.batchJobFilteredCount(visibleJobs.length, jobs.length),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BatchJobListFilterControl(
            selectedFilter: _filter,
            allCount: jobs.length,
            attentionCount: attentionCount,
            returnedCount: returnedCount,
            onFilterChanged: (filter) {
              setState(() {
                _filter = filter;
                if (_controller.hasClients) {
                  _controller.jumpTo(0);
                }
              });
            },
          ),
          const SizedBox(height: 12),
          if (widget.expandList)
            Expanded(
              child: _BatchGenerationJobListBody(
                visibleJobs: visibleJobs,
                controller: _controller,
                emptyLabel: l10n.batchJobFilterEmpty,
                onRemove: widget.onRemoveJob,
                onRetry: widget.onRetryJob,
                onPreviewImages: widget.onPreviewJobImages,
              ),
            )
          else
            _BatchGenerationJobListBody(
              visibleJobs: visibleJobs,
              controller: _controller,
              emptyLabel: l10n.batchJobFilterEmpty,
              maxHeight: _batchJobListHeight(visibleJobs.length),
              onRemove: widget.onRemoveJob,
              onRetry: widget.onRetryJob,
              onPreviewImages: widget.onPreviewJobImages,
            ),
        ],
      ),
    );
  }
}

class _BatchGenerationJobListBody extends StatelessWidget {
  const _BatchGenerationJobListBody({
    required this.visibleJobs,
    required this.controller,
    required this.emptyLabel,
    required this.onRemove,
    required this.onRetry,
    required this.onPreviewImages,
    this.maxHeight,
  });

  final List<_VisibleBatchJob> visibleJobs;
  final ScrollController controller;
  final String emptyLabel;
  final ValueChanged<BatchGenerationJob> onRemove;
  final ValueChanged<BatchGenerationJob> onRetry;
  final ValueChanged<BatchGenerationJob> onPreviewImages;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (visibleJobs.isEmpty) {
      final empty = Semantics(
        container: true,
        readOnly: true,
        label: emptyLabel,
        child: Text(
          emptyLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
      return maxHeight == null
          ? empty
          : SizedBox(height: maxHeight, child: empty);
    }

    final list = Scrollbar(
      controller: controller,
      child: ListView.separated(
        key: const ValueKey('batch-job-list'),
        controller: controller,
        primary: false,
        itemCount: visibleJobs.length,
        separatorBuilder: (context, index) => const Divider(height: 18),
        itemBuilder: (context, index) {
          final visibleJob = visibleJobs[index];
          return _BatchGenerationJobTile(
            job: visibleJob.job,
            jobNumber: visibleJob.jobNumber,
            onRemove: onRemove,
            onRetry: onRetry,
            onPreviewImages: onPreviewImages,
          );
        },
      ),
    );

    return maxHeight == null ? list : SizedBox(height: maxHeight, child: list);
  }
}

enum _BatchJobListFilter { all, attention, returned }

class _VisibleBatchJob {
  const _VisibleBatchJob({required this.job, required this.jobNumber});

  final BatchGenerationJob job;
  final int jobNumber;
}

class _BatchJobListFilterControl extends StatelessWidget {
  const _BatchJobListFilterControl({
    required this.selectedFilter,
    required this.allCount,
    required this.attentionCount,
    required this.returnedCount,
    required this.onFilterChanged,
  });

  final _BatchJobListFilter selectedFilter;
  final int allCount;
  final int attentionCount;
  final int returnedCount;
  final ValueChanged<_BatchJobListFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final options = [
      _BatchJobFilterOption(
        value: _BatchJobListFilter.all,
        icon: Icons.format_list_bulleted_outlined,
        label: l10n.batchJobFilterAll(allCount),
      ),
      _BatchJobFilterOption(
        value: _BatchJobListFilter.attention,
        icon: Icons.report_problem_outlined,
        label: l10n.batchJobFilterAttention(attentionCount),
      ),
      _BatchJobFilterOption(
        value: _BatchJobListFilter.returned,
        icon: Icons.photo_library_outlined,
        label: l10n.batchJobFilterReturned(returnedCount),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            showCheckmark: false,
            selected: selectedFilter == option.value,
            avatar: Icon(option.icon, size: 18),
            label: Text(option.label),
            onSelected: (_) => onFilterChanged(option.value),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}

class _BatchJobFilterOption {
  const _BatchJobFilterOption({
    required this.value,
    required this.icon,
    required this.label,
  });

  final _BatchJobListFilter value;
  final IconData icon;
  final String label;
}

double _batchJobListHeight(int jobCount) {
  const estimatedTileHeight = 84.0;
  const separatorHeight = 18.0;
  const maxHeight = 320.0;
  final contentHeight =
      jobCount * estimatedTileHeight + (jobCount - 1) * separatorHeight;
  return contentHeight.clamp(96.0, maxHeight).toDouble();
}

class _BatchGenerationJobTile extends StatelessWidget {
  const _BatchGenerationJobTile({
    required this.job,
    required this.jobNumber,
    required this.onRemove,
    required this.onRetry,
    required this.onPreviewImages,
  });

  final BatchGenerationJob job;
  final int jobNumber;
  final ValueChanged<BatchGenerationJob> onRemove;
  final ValueChanged<BatchGenerationJob> onRetry;
  final ValueChanged<BatchGenerationJob> onPreviewImages;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final attentionMessage = _batchJobAttentionMessage(l10n, job);
    final statusColor = attentionMessage != null
        ? theme.colorScheme.error
        : switch (job.status) {
            BatchGenerationJobStatus.succeeded => Colors.green,
            BatchGenerationJobStatus.failed => theme.colorScheme.error,
            BatchGenerationJobStatus.running => theme.colorScheme.primary,
            BatchGenerationJobStatus.skipped => theme.colorScheme.outline,
            BatchGenerationJobStatus.queued =>
              theme.colorScheme.onSurfaceVariant,
          };
    final batchLabel = job.hasMultipleBatches
        ? l10n.batchJobBatchPrefix(job.batchIndex, job.batchTotal)
        : '';
    final retryLabel = job.retryAttempt > 0
        ? l10n.batchJobRetrySuffix(
            job.retryAttempt,
            maxBatchGenerationAutoRetryAttempts,
          )
        : '';
    final hasReturnedImages = job.resultImages.isNotEmpty;
    final returnSummaryColor = attentionMessage == null
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.error;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.circle, size: 10, color: statusColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.prompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.batchJobSummary(
                  _batchJobStatusLabel(l10n, job),
                  batchLabel,
                  job.size,
                  job.imageCount,
                  job.apiConfig.name,
                  retryLabel,
                ),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                l10n.batchJobReturnSummary(
                  job.imageCount,
                  job.resultImages.length,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: returnSummaryColor,
                ),
              ),
              if (attentionMessage != null) ...[
                const SizedBox(height: 2),
                Semantics(
                  container: true,
                  liveRegion: true,
                  label: attentionMessage,
                  readOnly: true,
                  child: Text(
                    attentionMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (job.errorMessage != null) ...[
                const SizedBox(height: 4),
                Semantics(
                  container: true,
                  liveRegion: true,
                  label: job.errorMessage!,
                  readOnly: true,
                  child: Text(
                    job.errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (job.canRetry)
          IconButton(
            tooltip: l10n.batchRetryJobTooltip,
            onPressed: () => onRetry(job),
            icon: const Icon(Icons.replay_outlined),
          ),
        if (hasReturnedImages)
          IconButton(
            tooltip: _batchJobImagesTooltip(
              l10n,
              job,
              jobNumber,
              job.resultImages.length,
            ),
            onPressed: () => onPreviewImages(job),
            icon: const Icon(Icons.photo_library_outlined),
          ),
        IconButton(
          tooltip: l10n.batchRemoveJobTooltip,
          onPressed: job.canDelete ? () => onRemove(job) : null,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

String _batchJobStatusLabel(AppLocalizations l10n, BatchGenerationJob job) {
  if (job.status == BatchGenerationJobStatus.succeeded &&
      _batchJobMissingImageCount(job) > 0) {
    return l10n.batchJobStatusUnderReturned;
  }
  return _jobStatusLabel(l10n, job.status);
}

String _jobStatusLabel(AppLocalizations l10n, BatchGenerationJobStatus status) {
  return switch (status) {
    BatchGenerationJobStatus.queued => l10n.batchJobStatusQueued,
    BatchGenerationJobStatus.running => l10n.batchJobStatusRunning,
    BatchGenerationJobStatus.succeeded => l10n.batchJobStatusSucceeded,
    BatchGenerationJobStatus.failed => l10n.batchJobStatusFailed,
    BatchGenerationJobStatus.skipped => l10n.batchJobStatusSkipped,
  };
}

List<_VisibleBatchJob> _visibleBatchJobs(
  List<BatchGenerationJob> jobs,
  _BatchJobListFilter filter,
) {
  final visibleJobs = <_VisibleBatchJob>[];
  for (var index = 0; index < jobs.length; index++) {
    final job = jobs[index];
    final isVisible = switch (filter) {
      _BatchJobListFilter.all => true,
      _BatchJobListFilter.attention => _batchJobNeedsAttention(job),
      _BatchJobListFilter.returned => job.resultImages.isNotEmpty,
    };
    if (isVisible) {
      visibleJobs.add(_VisibleBatchJob(job: job, jobNumber: index + 1));
    }
  }
  return visibleJobs;
}

bool _batchJobNeedsAttention(BatchGenerationJob job) {
  return job.canRetry ||
      job.status == BatchGenerationJobStatus.skipped ||
      _batchJobMissingImageCount(job) > 0;
}

int _batchJobMissingImageCount(BatchGenerationJob job) {
  if (!job.isTerminal ||
      job.status == BatchGenerationJobStatus.failed ||
      job.status == BatchGenerationJobStatus.skipped) {
    return 0;
  }
  return (job.imageCount - job.resultImages.length)
      .clamp(0, job.imageCount)
      .toInt();
}

String? _batchJobAttentionMessage(
  AppLocalizations l10n,
  BatchGenerationJob job,
) {
  if (job.canRetry) {
    return l10n.batchJobAttentionFailed;
  }
  if (job.status == BatchGenerationJobStatus.skipped) {
    return l10n.batchJobAttentionSkipped;
  }
  final missingImageCount = _batchJobMissingImageCount(job);
  if (missingImageCount > 0) {
    return l10n.batchJobAttentionUnderReturned(missingImageCount);
  }
  return null;
}

String _batchPreviewSourceLabel(
  AppLocalizations l10n,
  BatchPreviewImageSource source,
) {
  if (source.hasMultipleBatches) {
    return l10n.batchPreviewImageSource(
      source.batchIndex,
      source.batchTotal,
      source.imageIndex,
      source.imageTotal,
    );
  }

  return l10n.batchPreviewSingleJobImageSource(
    source.jobNumber,
    source.imageIndex,
    source.imageTotal,
  );
}

String _batchJobImagePreviewTitle(
  AppLocalizations l10n,
  BatchGenerationJob job,
  int jobNumber,
  int imageIndex,
) {
  final imageNumber = imageIndex + 1;
  final imageTotal = job.resultImages.length;
  if (job.hasMultipleBatches) {
    return l10n.batchPreviewImageSource(
      job.batchIndex,
      job.batchTotal,
      imageNumber,
      imageTotal,
    );
  }

  return l10n.batchPreviewSingleJobImageSource(
    jobNumber,
    imageNumber,
    imageTotal,
  );
}

String _batchJobImagesTooltip(
  AppLocalizations l10n,
  BatchGenerationJob job,
  int jobNumber,
  int imageCount,
) {
  if (job.hasMultipleBatches) {
    return l10n.batchPreviewJobImagesTooltip(
      job.batchIndex,
      job.batchTotal,
      imageCount,
    );
  }

  return l10n.batchPreviewSingleJobImagesTooltip(jobNumber, imageCount);
}

int _batchJobDisplayNumber(
  List<BatchGenerationJob> jobs,
  BatchGenerationJob job,
) {
  final index = jobs.indexWhere((candidate) => candidate.id == job.id);
  return index < 0 ? 1 : index + 1;
}

int _batchResultImageGlobalIndex(
  List<BatchGenerationJob> jobs,
  BatchGenerationJob job,
  int jobImageIndex,
) {
  var globalIndex = 0;
  for (final candidate in jobs) {
    if (candidate.id == job.id) {
      return globalIndex + jobImageIndex;
    }
    globalIndex += candidate.resultImages.length;
  }
  return jobImageIndex;
}
