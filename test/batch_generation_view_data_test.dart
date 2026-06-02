import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('summarizes batch queue jobs and caps preview images', () {
    final debugRecord = ImageRequestDebugRecord.fromRequest(
      const OpenAIImageRequest(
        baseUrl: 'https://example.com/v1',
        apiKey: 'key',
        prompt: 'running prompt',
        negativePrompt: '',
        model: 'gpt-image-2',
        size: '1536x1024',
        imageCount: 2,
      ),
    );
    final jobs = [
      _job('queued prompt'),
      _job('running prompt', size: '1536x1024', imageCount: 2).copyWith(
        status: BatchGenerationJobStatus.running,
        debugRecord: debugRecord,
      ),
      for (var index = 0; index < maxBatchPreviewImages + 4; index++)
        _job('done prompt $index').copyWith(
          status: BatchGenerationJobStatus.succeeded,
          resultImages: [GeneratedImage.bytes(Uint8List(4))],
        ),
      _job('failed prompt').copyWith(status: BatchGenerationJobStatus.failed),
    ];

    final summary = summarizeBatchGenerationJobs(
      jobs,
      fallbackSize: '1024x1024',
    );

    expect(summary.queuedCount, 1);
    expect(summary.runningCount, 1);
    expect(summary.finishedCount, maxBatchPreviewImages + 5);
    expect(summary.failedCount, 1);
    expect(summary.totalJobCount, maxBatchPreviewImages + 7);
    expect(summary.requestedImageCount, maxBatchPreviewImages + 8);
    expect(summary.returnedImageCount, maxBatchPreviewImages + 4);
    expect(summary.previewImages, hasLength(maxBatchPreviewImages));
    expect(summary.previewImageSources, hasLength(maxBatchPreviewImages));
    expect(summary.hiddenPreviewImageCount, 4);
    expect(summary.isPreviewTruncated, isTrue);
    expect(summary.targetImageCount, maxBatchPreviewImages + 2);
    expect(summary.previewAspectRatio, imageAspectRatioFromSize('1536x1024'));
    expect(summary.latestDebugRecord, same(debugRecord));
  });

  test('keeps every image from each batch until preview cap', () {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    final jobs = [
      for (var index = 0; index < 21; index++)
        BatchGenerationJob.create(
          apiConfig: config,
          prompt: 'done prompt $index',
          negativePrompt: '',
          size: '1024x1024',
          imageCount: 4,
          advancedSettings: const ImageAdvancedSettings(),
          user: '',
        ).copyWith(
          status: BatchGenerationJobStatus.succeeded,
          resultImages: [
            for (var imageIndex = 0; imageIndex < 4; imageIndex++)
              GeneratedImage.bytes(Uint8List.fromList([index, imageIndex])),
          ],
        ),
    ];

    final summary = summarizeBatchGenerationJobs(
      jobs,
      fallbackSize: '1024x1024',
    );

    expect(summary.previewImages, hasLength(84));
    expect(summary.targetImageCount, 84);
    expect(summary.requestedImageCount, 84);
    expect(summary.returnedImageCount, 84);
    expect(summary.hiddenPreviewImageCount, 0);
    expect(summary.isPreviewTruncated, isFalse);
    expect(summary.previewImageSources, hasLength(84));
    expect(summary.previewImageSources.first.batchIndex, 1);
    expect(summary.previewImageSources.first.batchTotal, 1);
    expect(summary.previewImageSources.first.imageIndex, 1);
    expect(summary.previewImageSources.first.imageTotal, 4);
    expect(summary.previewImageSources.last.jobNumber, 21);
    expect(summary.previewImageSources.last.imageIndex, 4);
    expect(summary.previewImages.first.bytes, isNotNull);
    expect(summary.previewImages.last.bytes, isNotNull);
  });

  test('derives queue status kind from running and queued state', () {
    expect(
      batchQueueStatusKind(isRunning: true, isPausing: true, queuedCount: 3),
      BatchQueueStatusKind.pausing,
    );
    expect(
      batchQueueStatusKind(isRunning: true, isPausing: false, queuedCount: 3),
      BatchQueueStatusKind.running,
    );
    expect(
      batchQueueStatusKind(isRunning: false, isPausing: false, queuedCount: 3),
      BatchQueueStatusKind.waiting,
    );
    expect(
      batchQueueStatusKind(isRunning: false, isPausing: false, queuedCount: 0),
      BatchQueueStatusKind.empty,
    );
  });

  test('derives batch queue control blockers', () {
    final running = deriveBatchQueueControlsState(
      isRunning: true,
      isPausing: false,
      queuedCount: 2,
      finishedCount: 1,
      failedCount: 1,
      isSizeValid: true,
    );

    expect(running.addPromptsBlocker, BatchQueueControlBlocker.queueRunning);
    expect(running.startBlocker, BatchQueueControlBlocker.queueRunning);
    expect(running.pauseBlocker, isNull);
    expect(running.resumeBlocker, BatchQueueControlBlocker.queueNotPaused);
    expect(running.retryFailedBlocker, BatchQueueControlBlocker.queueRunning);
    expect(running.clearFinishedBlocker, BatchQueueControlBlocker.queueRunning);

    final waiting = deriveBatchQueueControlsState(
      isRunning: false,
      isPausing: false,
      queuedCount: 0,
      finishedCount: 0,
      failedCount: 0,
      isSizeValid: true,
    );

    expect(waiting.startBlocker, BatchQueueControlBlocker.needsQueuedJobs);
    expect(waiting.pauseBlocker, BatchQueueControlBlocker.queueNotRunning);
    expect(waiting.cancelQueuedBlocker, BatchQueueControlBlocker.noQueuedJobs);
    expect(waiting.retryFailedBlocker, BatchQueueControlBlocker.noFailedJobs);
    expect(
      waiting.clearFinishedBlocker,
      BatchQueueControlBlocker.noFinishedJobs,
    );

    final invalidSize = deriveBatchQueueControlsState(
      isRunning: false,
      isPausing: false,
      queuedCount: 1,
      finishedCount: 0,
      failedCount: 0,
      isSizeValid: false,
    );

    expect(invalidSize.startBlocker, BatchQueueControlBlocker.invalidImageSize);
  });
}

BatchGenerationJob _job(
  String prompt, {
  String size = '1024x1024',
  int imageCount = 1,
}) {
  return BatchGenerationJob.create(
    apiConfig: const ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    ),
    prompt: prompt,
    negativePrompt: '',
    size: size,
    imageCount: imageCount,
    advancedSettings: const ImageAdvancedSettings(),
    user: '',
  );
}
