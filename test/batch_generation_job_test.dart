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
    expect(job.hasMultipleBatches, isTrue);
    expect(job.canDelete, isTrue);
    expect(job.isTerminal, isFalse);
    expect(batchGenerationJobStatusLabel(job.status), '等待中');

    final running = job.copyWith(status: BatchGenerationJobStatus.running);

    expect(running.canDelete, isFalse);
    expect(running.isTerminal, isFalse);
    expect(batchGenerationJobStatusLabel(running.status), '生成中');

    final failed = running.copyWith(
      status: BatchGenerationJobStatus.failed,
      errorMessage: 'network error',
    );

    expect(failed.isTerminal, isTrue);
    expect(failed.errorMessage, 'network error');
    expect(batchGenerationJobStatusLabel(failed.status), '失败');

    final succeeded = failed.copyWith(
      status: BatchGenerationJobStatus.succeeded,
      clearErrorMessage: true,
    );

    expect(succeeded.isTerminal, isTrue);
    expect(succeeded.errorMessage, isNull);
    expect(batchGenerationJobStatusLabel(succeeded.status), '已完成');
  });
}
