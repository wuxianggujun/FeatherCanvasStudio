import '../models/batch_generation_job.dart';
import '../models/generated_image.dart';
import '../services/image_request_debug_record.dart';
import 'image_dimensions.dart';

const int maxBatchPreviewImages = 120;

class BatchGenerationJobSummary {
  const BatchGenerationJobSummary({
    required this.queuedCount,
    required this.runningCount,
    required this.finishedCount,
    required this.failedCount,
    required this.previewImages,
    required this.targetImageCount,
    required this.previewAspectRatio,
    required this.latestDebugRecord,
  });

  final int queuedCount;
  final int runningCount;
  final int finishedCount;
  final int failedCount;
  final List<GeneratedImage> previewImages;
  final int targetImageCount;
  final double previewAspectRatio;
  final ImageRequestDebugRecord? latestDebugRecord;
}

BatchGenerationJobSummary summarizeBatchGenerationJobs(
  List<BatchGenerationJob> jobs, {
  required String fallbackSize,
}) {
  var queuedCount = 0;
  var runningCount = 0;
  var finishedCount = 0;
  var failedCount = 0;
  var targetImageCount = 0;
  var previewAspectRatio = imageAspectRatioFromSize(fallbackSize);
  var hasPreviewAspectRatio = false;
  ImageRequestDebugRecord? latestDebugRecord;
  final previewImages = <GeneratedImage>[];

  for (final job in jobs) {
    if (job.isPending) {
      queuedCount++;
    }
    if (job.isRunning) {
      runningCount++;
      targetImageCount += job.imageCount;
    }
    if (job.isTerminal) {
      finishedCount++;
    }
    if (job.canRetry) {
      failedCount++;
    }
    if (job.resultImages.isNotEmpty &&
        previewImages.length < maxBatchPreviewImages) {
      final remainingPreviewSlots =
          maxBatchPreviewImages - previewImages.length;
      previewImages.addAll(job.resultImages.take(remainingPreviewSlots));
    }
    if (!hasPreviewAspectRatio &&
        (job.resultImages.isNotEmpty || job.isRunning)) {
      previewAspectRatio = imageAspectRatioFromSize(job.size);
      hasPreviewAspectRatio = true;
    }
    if (job.debugRecord != null) {
      latestDebugRecord = job.debugRecord;
    }
  }

  return BatchGenerationJobSummary(
    queuedCount: queuedCount,
    runningCount: runningCount,
    finishedCount: finishedCount,
    failedCount: failedCount,
    previewImages: List.unmodifiable(previewImages),
    targetImageCount: targetImageCount + previewImages.length,
    previewAspectRatio: previewAspectRatio,
    latestDebugRecord: latestDebugRecord,
  );
}

enum BatchQueueStatusKind { pausing, running, waiting, empty }

BatchQueueStatusKind batchQueueStatusKind({
  required bool isRunning,
  required bool isPausing,
  required int queuedCount,
}) {
  if (isRunning && isPausing) {
    return BatchQueueStatusKind.pausing;
  }
  if (isRunning) {
    return BatchQueueStatusKind.running;
  }
  if (queuedCount > 0) {
    return BatchQueueStatusKind.waiting;
  }
  return BatchQueueStatusKind.empty;
}

enum BatchQueueControlBlocker {
  queueRunning,
  needsQueuedJobs,
  invalidImageSize,
  queueNotRunning,
  queueAlreadyPausing,
  queueNotPaused,
  noQueuedJobs,
  noFailedJobs,
  noFinishedJobs,
}

class BatchQueueControlsState {
  const BatchQueueControlsState({
    required this.addPromptsBlocker,
    required this.startBlocker,
    required this.pauseBlocker,
    required this.resumeBlocker,
    required this.cancelQueuedBlocker,
    required this.retryFailedBlocker,
    required this.clearFinishedBlocker,
  });

  final BatchQueueControlBlocker? addPromptsBlocker;
  final BatchQueueControlBlocker? startBlocker;
  final BatchQueueControlBlocker? pauseBlocker;
  final BatchQueueControlBlocker? resumeBlocker;
  final BatchQueueControlBlocker? cancelQueuedBlocker;
  final BatchQueueControlBlocker? retryFailedBlocker;
  final BatchQueueControlBlocker? clearFinishedBlocker;

  bool get canAddPrompts => addPromptsBlocker == null;
  bool get canStart => startBlocker == null;
  bool get canPause => pauseBlocker == null;
  bool get canResume => resumeBlocker == null;
  bool get canCancelQueued => cancelQueuedBlocker == null;
  bool get canRetryFailed => retryFailedBlocker == null;
  bool get canClearFinished => clearFinishedBlocker == null;
}

BatchQueueControlsState deriveBatchQueueControlsState({
  required bool isRunning,
  required bool isPausing,
  required int queuedCount,
  required int finishedCount,
  required int failedCount,
  required bool isSizeValid,
}) {
  return BatchQueueControlsState(
    addPromptsBlocker: isRunning ? BatchQueueControlBlocker.queueRunning : null,
    startBlocker: isRunning
        ? BatchQueueControlBlocker.queueRunning
        : queuedCount == 0
        ? BatchQueueControlBlocker.needsQueuedJobs
        : !isSizeValid
        ? BatchQueueControlBlocker.invalidImageSize
        : null,
    pauseBlocker: !isRunning
        ? BatchQueueControlBlocker.queueNotRunning
        : isPausing
        ? BatchQueueControlBlocker.queueAlreadyPausing
        : null,
    resumeBlocker: isPausing ? null : BatchQueueControlBlocker.queueNotPaused,
    cancelQueuedBlocker: queuedCount == 0
        ? BatchQueueControlBlocker.noQueuedJobs
        : null,
    retryFailedBlocker: isRunning
        ? BatchQueueControlBlocker.queueRunning
        : failedCount == 0
        ? BatchQueueControlBlocker.noFailedJobs
        : null,
    clearFinishedBlocker: isRunning
        ? BatchQueueControlBlocker.queueRunning
        : finishedCount == 0
        ? BatchQueueControlBlocker.noFinishedJobs
        : null,
  );
}
