import '../models/batch_generation_job.dart';
import '../models/generated_image.dart';
import '../models/image_library_item.dart';

class BatchGenerationFailureUpdate {
  const BatchGenerationFailureUpdate({
    required this.jobs,
    required this.queuedForRetry,
  });

  final List<BatchGenerationJob> jobs;
  final bool queuedForRetry;
}

BatchGenerationFailureUpdate updateBatchJobAfterFailure({
  required List<BatchGenerationJob> jobs,
  required int jobIndex,
  required Object error,
}) {
  if (jobIndex < 0 || jobIndex >= jobs.length) {
    return BatchGenerationFailureUpdate(
      jobs: List<BatchGenerationJob>.unmodifiable(jobs),
      queuedForRetry: false,
    );
  }

  final current = jobs[jobIndex];
  final errorMessage = error.toString();
  if (current.canAutoRetry) {
    final retryAttempt = current.retryAttempt + 1;
    final retryJob = current.copyWith(
      status: BatchGenerationJobStatus.queued,
      retryAttempt: retryAttempt,
      resultImages: const <GeneratedImage>[],
      libraryItems: const <ImageLibraryItem>[],
      errorMessage:
          '上次失败，已移到队尾自动重试 '
          '($retryAttempt/$maxBatchGenerationAutoRetryAttempts)：$errorMessage',
    );
    return BatchGenerationFailureUpdate(
      jobs: [
        for (var i = 0; i < jobs.length; i++)
          if (i != jobIndex) jobs[i],
        retryJob,
      ],
      queuedForRetry: true,
    );
  }

  return BatchGenerationFailureUpdate(
    jobs: [
      for (var i = 0; i < jobs.length; i++)
        if (i == jobIndex)
          current.copyWith(
            status: BatchGenerationJobStatus.failed,
            errorMessage: errorMessage,
          )
        else
          jobs[i],
    ],
    queuedForRetry: false,
  );
}
