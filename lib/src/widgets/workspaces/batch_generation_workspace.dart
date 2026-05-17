import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/api_provider.dart';
import '../../models/app_config.dart';
import '../../models/batch_generation_job.dart';
import '../../models/generated_image.dart';
import '../../models/image_advanced_settings.dart';
import '../../services/image_request_debug_record.dart';
import '../../state/batch_generation_notifier.dart';
import '../../theme/layout_constants.dart';
import '../../utils/generation_limits.dart';
import '../../utils/image_dimensions.dart';
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
    return WorkspacePage(
      title: '批量生成',
      description: '把多条文本生图任务排队串行执行，成功结果会自动进入作品库。',
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
              final previewImages = [
                for (final job in jobs)
                  if (job.resultImages.isNotEmpty) ...job.resultImages,
              ];
              final targetImageCount = jobs.fold<int>(
                previewImages.length,
                (total, job) => job.isRunning ? total + job.imageCount : total,
              );
              final previewAspectRatio = _batchPreviewAspectRatio(
                jobs: jobs,
                fallbackSize: size,
              );
              ImageRequestDebugRecord? latestDebugRecord;
              for (final job in jobs) {
                if (job.debugRecord != null) {
                  latestDebugRecord = job.debugRecord;
                }
              }
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
                    generatedImages: previewImages,
                    isGenerating: isRunning,
                    targetImageCount: targetImageCount,
                    targetAspectRatio: previewAspectRatio,
                    debugRecord: latestDebugRecord,
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

double _batchPreviewAspectRatio({
  required List<BatchGenerationJob> jobs,
  required String fallbackSize,
}) {
  for (final job in jobs) {
    if (job.resultImages.isNotEmpty || job.isRunning) {
      return imageAspectRatioFromSize(job.size);
    }
  }
  return imageAspectRatioFromSize(fallbackSize);
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
    final notifier = context.watch<BatchGenerationNotifier>();
    final jobs = notifier.jobs;
    final targetCount = notifier.targetCount;
    final requestCount = notifier.requestCount;
    final isRunning = notifier.isRunning;
    final isPausing = notifier.pauseAfterCurrent;
    final queuedCount = jobs.where((job) => job.isPending).length;
    final runningCount = jobs.where((job) => job.isRunning).length;
    final finishedCount = jobs.where((job) => job.isTerminal).length;
    final failedCount = jobs.where((job) => job.canRetry).length;
    final batchCount = splitImageGenerationBatches(
      targetCount: targetCount,
      requestCount: requestCount,
    ).length;
    final sizeValidation = validateImageSizeForModel(
      size: size,
      providerKind: providerKind,
      model: selectedApiConfig.model,
      capabilityOverride: imageSizeCapabilityOverride,
    );

    return AppPanel(
      title: '队列控制',
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
            decoration: const InputDecoration(
              labelText: '批量提示词',
              hintText: '每行一条提示词；每条会按目标数量自动拆分',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: fieldGap),
          TextField(
            controller: negativePromptController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '负向提示词',
              hintText: '会应用到每一个批量任务',
              alignLabelWithHint: true,
            ),
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
              label: '目标数量',
              value: targetCount,
              minValue: minImageGenerationCount,
              maxValue: maxBatchGenerationTargetCount,
              suffixText: '张',
              helperText: '每条提示词最终想生成的总数',
              enabled: !isRunning,
              onChanged: onTargetCountChanged,
            ),
            second: IntegerStepperField(
              label: '每批张数',
              value: requestCount,
              minValue: minImageGenerationCount,
              maxValue: maxImageGenerationRequestCount,
              suffixText: '张',
              helperText: '单次请求最多 $maxImageGenerationRequestCount 张',
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
              '当前会把每条提示词拆成 $batchCount 个串行任务',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isRunning ? null : onAddPrompts,
              icon: const Icon(Icons.playlist_add_outlined),
              label: const Text('按行拆分入队'),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryActionButton(
            onPressed: isRunning || queuedCount == 0 || !sizeValidation.isValid
                ? null
                : onStart,
            icon: Icons.auto_awesome_motion_outlined,
            label: finishedCount > 0 ? '继续队列' : '开始队列',
            busyLabel: '队列运行中',
            isBusy: isRunning,
          ),
          const SizedBox(height: 8),
          ResponsivePair(
            first: OutlinedButton.icon(
              onPressed: isRunning && !isPausing ? onPause : null,
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text('暂停后续'),
            ),
            second: OutlinedButton.icon(
              onPressed: isPausing ? onResume : null,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('继续后续'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: queuedCount == 0 ? null : onCancelQueued,
            icon: const Icon(Icons.cancel_schedule_send_outlined),
            label: const Text('取消等待任务'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isRunning || failedCount == 0 ? null : onRetryFailed,
            icon: const Icon(Icons.replay_outlined),
            label: Text(failedCount == 0 ? '重试失败任务' : '重试失败任务 ($failedCount)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isRunning || finishedCount == 0 ? null : onClearFinished,
            icon: const Icon(Icons.clear_all_outlined),
            label: const Text('清理完成 / 失败 / 取消'),
          ),
        ],
      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final message = _message();

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

  String _message() {
    if (isRunning && isPausing) {
      return '已暂停后续任务。正在请求的 $runningCount 个任务会等接口返回或超时后停下，'
          '不会继续启动新的等待任务。';
    }
    if (isRunning) {
      return '正在请求 $runningCount 个任务，后面还有 $queuedCount 个等待任务。'
          '暂停只会阻止下一批开始，不会中断已发出的 HTTP 请求。';
    }
    if (queuedCount > 0) {
      return '队列里有 $queuedCount 个等待任务，可继续执行或取消等待任务。';
    }
    return '没有等待中的任务。';
  }
}

class _BatchGenerationJobList extends StatelessWidget {
  const _BatchGenerationJobList({
    required this.jobs,
    required this.onRemoveJob,
    required this.onRetryJob,
  });

  final List<BatchGenerationJob> jobs;
  final ValueChanged<BatchGenerationJob> onRemoveJob;
  final ValueChanged<BatchGenerationJob> onRetryJob;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (jobs.isEmpty) {
      return AppPanel(
        title: '任务队列',
        child: Text(
          '还没有任务。把提示词加入队列后，会按目标数量拆分并串行生成。',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return AppPanel(
      title: '任务队列',
      trailing: Text(
        '${jobs.length} 个任务',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: SizedBox(
        height: _batchJobListHeight(jobs.length),
        child: ListView.separated(
          primary: false,
          itemCount: jobs.length,
          separatorBuilder: (context, index) => const Divider(height: 18),
          itemBuilder: (context, index) {
            return _BatchGenerationJobTile(
              job: jobs[index],
              onRemove: onRemoveJob,
              onRetry: onRetryJob,
            );
          },
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
    final theme = Theme.of(context);
    final statusColor = switch (job.status) {
      BatchGenerationJobStatus.succeeded => Colors.green,
      BatchGenerationJobStatus.failed => theme.colorScheme.error,
      BatchGenerationJobStatus.running => theme.colorScheme.primary,
      BatchGenerationJobStatus.skipped => theme.colorScheme.outline,
      BatchGenerationJobStatus.queued => theme.colorScheme.onSurfaceVariant,
    };
    final batchLabel = job.hasMultipleBatches
        ? '第 ${job.batchIndex}/${job.batchTotal} 批 · '
        : '';
    final retryLabel = job.retryAttempt > 0
        ? ' · 重试 ${job.retryAttempt}/$maxBatchGenerationAutoRetryAttempts'
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
                '${batchGenerationJobStatusLabel(job.status)} · '
                '$batchLabel${job.size} · '
                '${job.imageCount} 张 · ${job.apiConfig.name}$retryLabel',
                style: theme.textTheme.bodySmall,
              ),
              if (job.errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  job.errorMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (job.canRetry)
          IconButton(
            tooltip: '重试任务',
            onPressed: () => onRetry(job),
            icon: const Icon(Icons.replay_outlined),
          ),
        IconButton(
          tooltip: '移除任务',
          onPressed: job.canDelete ? () => onRemove(job) : null,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
