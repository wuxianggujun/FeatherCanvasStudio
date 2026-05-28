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
      children: [
        ResponsiveWorkspaceSplit(
          storageKey: 'batch_generation',
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
              final isRunning = notifier.isRunning;
              final summary = summarizeBatchGenerationJobs(
                jobs,
                fallbackSize: size,
              );
              return Column(
                children: [
                  _BatchGenerationJobList(
                    jobs: jobs,
                    onRemoveJob: onRemoveJob,
                    onRetryJob: onRetryJob,
                  ),
                  const SizedBox(height: 16),
                  PreviewPanel(
                    errorMessage: null,
                    generatedImages: summary.previewImages,
                    isGenerating: isRunning,
                    targetImageCount: summary.targetImageCount,
                    targetAspectRatio: summary.previewAspectRatio,
                    debugRecord: summary.latestDebugRecord,
                    onRetry: onStart,
                    onCopyImage: onCopyImage,
                    onExportImage: onExportImage,
                    onMakeBackgroundTransparent: onMakeBackgroundTransparent,
                  ),
                ],
              );
            },
          ),
        ),
      ],
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
  });

  final List<BatchGenerationJob> jobs;
  final ValueChanged<BatchGenerationJob> onRemoveJob;
  final ValueChanged<BatchGenerationJob> onRetryJob;

  @override
  State<_BatchGenerationJobList> createState() =>
      _BatchGenerationJobListState();
}

class _BatchGenerationJobListState extends State<_BatchGenerationJobList> {
  final ScrollController _controller = ScrollController();

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

    return AppPanel(
      title: l10n.batchJobListTitle,
      trailing: Text(
        l10n.batchJobCount(jobs.length),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: SizedBox(
        height: _batchJobListHeight(jobs.length),
        child: Scrollbar(
          controller: _controller,
          child: ListView.separated(
            controller: _controller,
            primary: false,
            itemCount: jobs.length,
            separatorBuilder: (context, index) => const Divider(height: 18),
            itemBuilder: (context, index) {
              return _BatchGenerationJobTile(
                job: jobs[index],
                onRemove: widget.onRemoveJob,
                onRetry: widget.onRetryJob,
              );
            },
          ),
        ),
      ),
    );
  }
}

double _batchJobListHeight(int jobCount) {
  const estimatedTileHeight = 74.0;
  const separatorHeight = 18.0;
  const maxHeight = 320.0;
  final contentHeight =
      jobCount * estimatedTileHeight + (jobCount - 1) * separatorHeight;
  return contentHeight.clamp(96.0, maxHeight).toDouble();
}

class _BatchGenerationJobTile extends StatelessWidget {
  const _BatchGenerationJobTile({
    required this.job,
    required this.onRemove,
    required this.onRetry,
  });

  final BatchGenerationJob job;
  final ValueChanged<BatchGenerationJob> onRemove;
  final ValueChanged<BatchGenerationJob> onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);
    final statusColor = switch (job.status) {
      BatchGenerationJobStatus.succeeded => Colors.green,
      BatchGenerationJobStatus.failed => theme.colorScheme.error,
      BatchGenerationJobStatus.running => theme.colorScheme.primary,
      BatchGenerationJobStatus.skipped => theme.colorScheme.outline,
      BatchGenerationJobStatus.queued => theme.colorScheme.onSurfaceVariant,
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
                  _jobStatusLabel(l10n, job.status),
                  batchLabel,
                  job.size,
                  job.imageCount,
                  job.apiConfig.name,
                  retryLabel,
                ),
                style: theme.textTheme.bodySmall,
              ),
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
        IconButton(
          tooltip: l10n.batchRemoveJobTooltip,
          onPressed: job.canDelete ? () => onRemove(job) : null,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
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
