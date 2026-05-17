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
}
