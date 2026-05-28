import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tracks batch generation job lifecycle helpers', () {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );

    final job = BatchGenerationJob.create(
      apiConfig: config,
      prompt: 'a small robot',
      negativePrompt: 'blur',
      size: '1024x1024',
      imageCount: 12,
      advancedSettings: const ImageAdvancedSettings(quality: 'high'),
      user: 'user-1',
      batchIndex: 2,
      batchTotal: 3,
    );

    expect(job.status, BatchGenerationJobStatus.queued);
    expect(job.imageCount, maxImageGenerationRequestCount);
    expect(job.batchIndex, 2);
    expect(job.batchTotal, 3);
    expect(job.retryAttempt, 0);
    expect(job.canAutoRetry, isTrue);
    expect(job.hasMultipleBatches, isTrue);
    expect(job.canDelete, isTrue);
    expect(job.isTerminal, isFalse);
    expect(batchGenerationJobStatusLabel(job.status), '等待中');

    final running = job.copyWith(status: BatchGenerationJobStatus.running);

    expect(running.canDelete, isFalse);
    expect(running.canRetry, isFalse);
    expect(running.isTerminal, isFalse);
    expect(batchGenerationJobStatusLabel(running.status), '生成中');

    final failed = running.copyWith(
      status: BatchGenerationJobStatus.failed,
      errorMessage: 'network error',
      debugRecord: ImageRequestDebugRecord(
        createdAt: DateTime(2024),
        request: const {'prompt': 'a small robot'},
      ),
    );

    expect(failed.isTerminal, isTrue);
    expect(failed.canRetry, isTrue);
    expect(failed.errorMessage, 'network error');
    expect(failed.debugRecord, isNotNull);
    expect(batchGenerationJobStatusLabel(failed.status), '失败');

    final succeeded = failed.copyWith(
      status: BatchGenerationJobStatus.succeeded,
      clearErrorMessage: true,
    );

    expect(succeeded.isTerminal, isTrue);
    expect(succeeded.errorMessage, isNull);
    expect(batchGenerationJobStatusLabel(succeeded.status), '已完成');

    final retried = failed.copyWith(
      status: BatchGenerationJobStatus.queued,
      clearErrorMessage: true,
      clearDebugRecord: true,
    );

    expect(retried.isPending, isTrue);
    expect(retried.canRetry, isFalse);
    expect(retried.errorMessage, isNull);
    expect(retried.debugRecord, isNull);
  });

  test('moves first failed batch job to the end for one automatic retry', () {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    BatchGenerationJob job(String prompt) {
      return BatchGenerationJob.create(
        apiConfig: config,
        prompt: prompt,
        negativePrompt: '',
        size: '3840x2160',
        imageCount: 4,
        advancedSettings: const ImageAdvancedSettings(),
        user: '',
      );
    }

    final first = job(
      'first',
    ).copyWith(status: BatchGenerationJobStatus.running);
    final second = job('second');
    final update = updateBatchJobAfterFailure(
      jobs: [first, second],
      jobIndex: 0,
      error: 'HTTP 502 Bad Gateway',
    );

    expect(update.queuedForRetry, isTrue);
    expect(update.jobs.map((job) => job.prompt), ['second', 'first']);
    expect(update.jobs.last.status, BatchGenerationJobStatus.queued);
    expect(update.jobs.last.retryAttempt, 1);
    expect(update.jobs.last.errorMessage, contains('自动重试'));

    final finalFailure = updateBatchJobAfterFailure(
      jobs: [
        update.jobs.last.copyWith(status: BatchGenerationJobStatus.running),
      ],
      jobIndex: 0,
      error: 'HTTP 502 Bad Gateway',
    );

    expect(finalFailure.queuedForRetry, isFalse);
    expect(finalFailure.jobs.single.status, BatchGenerationJobStatus.failed);
    expect(finalFailure.jobs.single.retryAttempt, 1);
  });

  test('requeues failed batch job for manual retry', () {
    final failed = _job('failed').copyWith(
      status: BatchGenerationJobStatus.failed,
      retryAttempt: 3,
      resultImages: [GeneratedImage.bytes(Uint8List(4))],
      libraryItems: [_libraryItem('result')],
      errorMessage: 'network error',
      debugRecord: ImageRequestDebugRecord(
        createdAt: DateTime(2024),
        request: const {'prompt': 'failed'},
      ),
    );

    final requeued = requeueFailedBatchJob(failed);

    expect(requeued.status, BatchGenerationJobStatus.queued);
    expect(requeued.retryAttempt, 0);
    expect(requeued.resultImages, isEmpty);
    expect(requeued.libraryItems, isEmpty);
    expect(requeued.errorMessage, isNull);
    expect(requeued.debugRecord, isNull);
  });

  test('replaces batch job by index while preserving order', () {
    final first = _job('first');
    final second = _job('second');
    final replacement = _job('replacement');

    final result = replaceBatchGenerationJob([first, second], 1, replacement);

    expect(result, [first, replacement]);
  });

  test('replaces flattened batch preview image and appends library item', () {
    final first = _job('first').copyWith(
      status: BatchGenerationJobStatus.succeeded,
      resultImages: [
        GeneratedImage.bytes(Uint8List.fromList([1])),
        GeneratedImage.bytes(Uint8List.fromList([2])),
      ],
    );
    final second = _job('second').copyWith(
      status: BatchGenerationJobStatus.succeeded,
      resultImages: [
        GeneratedImage.bytes(Uint8List.fromList([3])),
      ],
    );
    final replacement = GeneratedImage.file('replacement.png');
    final appended = _libraryItem('replacement');

    final result = replaceBatchPreviewImage(
      jobs: [first, second],
      previewIndex: 1,
      replacement: replacement,
      appendedItem: appended,
    );

    expect(result.first.resultImages[1], same(replacement));
    expect(result.first.libraryItems, [appended]);
    expect(result.last, same(second));
  });

  test('keeps jobs unchanged when preview index is out of range', () {
    final job = _job('done').copyWith(
      status: BatchGenerationJobStatus.succeeded,
      resultImages: [GeneratedImage.bytes(Uint8List(4))],
    );

    final result = replaceBatchPreviewImage(
      jobs: [job],
      previewIndex: 2,
      replacement: GeneratedImage.file('replacement.png'),
      appendedItem: _libraryItem('replacement'),
    );

    expect(result, [job]);
  });
}

BatchGenerationJob _job(String prompt) {
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
    size: '1024x1024',
    imageCount: 1,
    advancedSettings: const ImageAdvancedSettings(),
    user: '',
  );
}

ImageLibraryItem _libraryItem(String id) {
  return ImageLibraryItem(
    id: id,
    path: '$id.png',
    createdAt: DateTime.parse('2026-05-25T12:00:00Z'),
    kind: ImageAssetKind.generatedImage,
    title: id,
    source: 'test',
  );
}
