import '../models/app_config.dart';
import '../models/batch_generation_job.dart';
import '../models/generated_image.dart';
import '../models/image_advanced_settings.dart';
import '../models/image_library_item.dart';
import 'generation_limits.dart';

enum BatchGenerationJobCreationFailure {
  missingPrompts,
  missingApiKey,
  missingModel,
}

class BatchGenerationJobCreationPlan {
  const BatchGenerationJobCreationPlan._({
    required this.prompts,
    required this.jobs,
    this.failure,
  });

  factory BatchGenerationJobCreationPlan.valid({
    required List<String> prompts,
    required List<BatchGenerationJob> jobs,
  }) {
    return BatchGenerationJobCreationPlan._(
      prompts: List<String>.unmodifiable(prompts),
      jobs: List<BatchGenerationJob>.unmodifiable(jobs),
    );
  }

  factory BatchGenerationJobCreationPlan.invalid(
    BatchGenerationJobCreationFailure failure,
  ) {
    return BatchGenerationJobCreationPlan._(
      prompts: const <String>[],
      jobs: const <BatchGenerationJob>[],
      failure: failure,
    );
  }

  final List<String> prompts;
  final List<BatchGenerationJob> jobs;
  final BatchGenerationJobCreationFailure? failure;

  bool get canCreate => failure == null;
}

List<String> splitBatchPromptLines(String value) {
  return List<String>.unmodifiable(
    value
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty),
  );
}

BatchGenerationJobCreationPlan buildBatchGenerationJobCreationPlan({
  required ApiConfig apiConfig,
  required List<String> prompts,
  required String negativePrompt,
  required String size,
  required int targetCount,
  required int requestCount,
  required ImageAdvancedSettings advancedSettings,
  required String user,
}) {
  final normalizedPrompts = prompts
      .map((prompt) => prompt.trim())
      .where((prompt) => prompt.isNotEmpty)
      .toList();
  if (normalizedPrompts.isEmpty) {
    return BatchGenerationJobCreationPlan.invalid(
      BatchGenerationJobCreationFailure.missingPrompts,
    );
  }
  if (apiConfig.apiKey.trim().isEmpty) {
    return BatchGenerationJobCreationPlan.invalid(
      BatchGenerationJobCreationFailure.missingApiKey,
    );
  }
  if (apiConfig.model.trim().isEmpty) {
    return BatchGenerationJobCreationPlan.invalid(
      BatchGenerationJobCreationFailure.missingModel,
    );
  }

  final batches = splitImageGenerationBatches(
    targetCount: targetCount,
    requestCount: requestCount,
  );
  final trimmedNegativePrompt = negativePrompt.trim();
  final trimmedUser = user.trim();
  final jobs = <BatchGenerationJob>[];
  for (final prompt in normalizedPrompts) {
    for (var index = 0; index < batches.length; index++) {
      jobs.add(
        BatchGenerationJob.create(
          apiConfig: apiConfig,
          prompt: prompt,
          negativePrompt: trimmedNegativePrompt,
          size: size,
          imageCount: batches[index],
          advancedSettings: advancedSettings,
          user: trimmedUser,
          batchIndex: index + 1,
          batchTotal: batches.length,
        ),
      );
    }
  }

  return BatchGenerationJobCreationPlan.valid(
    prompts: normalizedPrompts,
    jobs: jobs,
  );
}

class BatchGenerationFailureUpdate {
  const BatchGenerationFailureUpdate({
    required this.jobs,
    required this.queuedForRetry,
  });

  final List<BatchGenerationJob> jobs;
  final bool queuedForRetry;
}

typedef BatchAutoRetryMessageBuilder =
    String Function({
      required int retryAttempt,
      required int maxRetryAttempts,
      required String errorMessage,
    });

BatchGenerationFailureUpdate updateBatchJobAfterFailure({
  required List<BatchGenerationJob> jobs,
  required int jobIndex,
  required Object error,
  BatchAutoRetryMessageBuilder? autoRetryMessageBuilder,
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
    final retryMessageBuilder =
        autoRetryMessageBuilder ?? defaultBatchAutoRetryMessage;
    final retryJob = current.copyWith(
      status: BatchGenerationJobStatus.queued,
      retryAttempt: retryAttempt,
      resultImages: const <GeneratedImage>[],
      libraryItems: const <ImageLibraryItem>[],
      errorMessage: retryMessageBuilder(
        retryAttempt: retryAttempt,
        maxRetryAttempts: maxBatchGenerationAutoRetryAttempts,
        errorMessage: errorMessage,
      ),
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

BatchGenerationJob requeueFailedBatchJob(BatchGenerationJob job) {
  return job.copyWith(
    status: BatchGenerationJobStatus.queued,
    retryAttempt: 0,
    resultImages: const <GeneratedImage>[],
    libraryItems: const <ImageLibraryItem>[],
    clearErrorMessage: true,
    clearDebugRecord: true,
  );
}

List<BatchGenerationJob> replaceBatchGenerationJob(
  List<BatchGenerationJob> jobs,
  int index,
  BatchGenerationJob replacement,
) {
  return [
    for (var i = 0; i < jobs.length; i++)
      if (i == index) replacement else jobs[i],
  ];
}

List<BatchGenerationJob> replaceBatchPreviewImage({
  required List<BatchGenerationJob> jobs,
  required int previewIndex,
  required GeneratedImage replacement,
  required ImageLibraryItem appendedItem,
}) {
  var remainingIndex = previewIndex;
  var replaced = false;
  final updatedJobs = <BatchGenerationJob>[];

  for (final job in jobs) {
    final images = List<GeneratedImage>.of(job.resultImages);
    if (!replaced) {
      for (var imageIndex = 0; imageIndex < images.length; imageIndex++) {
        if (remainingIndex == 0) {
          images[imageIndex] = replacement;
          updatedJobs.add(
            job.copyWith(
              resultImages: List.unmodifiable(images),
              libraryItems: [...job.libraryItems, appendedItem],
            ),
          );
          replaced = true;
          break;
        }
        remainingIndex -= 1;
      }
    }

    if (!replaced || updatedJobs.last.id != job.id) {
      updatedJobs.add(job);
    }
  }

  return updatedJobs;
}

String defaultBatchAutoRetryMessage({
  required int retryAttempt,
  required int maxRetryAttempts,
  required String errorMessage,
}) {
  return '上次失败，已移到队尾自动重试 '
      '($retryAttempt/$maxRetryAttempts)：$errorMessage';
}
