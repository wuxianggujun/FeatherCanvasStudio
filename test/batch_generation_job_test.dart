import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits batch prompt lines while preserving order and duplicates', () {
    final prompts = splitBatchPromptLines(
      ' first prompt \r\n\nsecond prompt\nfirst prompt\n  \t\n third ',
    );

    expect(prompts, ['first prompt', 'second prompt', 'first prompt', 'third']);
  });

  test('builds batch generation job creation plan from prompts', () {
    const config = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );
    const advancedSettings = ImageAdvancedSettings(
      quality: 'high',
      outputFormat: 'webp',
    );

    final plan = buildBatchGenerationJobCreationPlan(
      apiConfig: config,
      prompts: const [' first ', '', 'second'],
      negativePrompt: ' blurry ',
      size: '1024x1024',
      targetCount: 10,
      requestCount: 4,
      advancedSettings: advancedSettings,
      user: ' user-1 ',
    );

    expect(plan.canCreate, isTrue);
    expect(plan.failure, isNull);
    expect(plan.prompts, ['first', 'second']);
    expect(plan.jobs.map((job) => job.prompt), [
      'first',
      'first',
      'first',
      'second',
      'second',
      'second',
    ]);
    expect(plan.jobs.map((job) => job.imageCount), [4, 4, 2, 4, 4, 2]);
    expect(plan.jobs.map((job) => job.batchIndex), [1, 2, 3, 1, 2, 3]);
    expect(plan.jobs.map((job) => job.batchTotal).toSet(), {3});
    expect(plan.jobs.first.apiConfig, same(config));
    expect(plan.jobs.first.negativePrompt, 'blurry');
    expect(plan.jobs.first.size, '1024x1024');
    expect(plan.jobs.first.advancedSettings, advancedSettings);
    expect(plan.jobs.first.user, 'user-1');
  });

  test('rejects invalid batch generation job creation plans', () {
    const validConfig = ApiConfig(
      id: 'config',
      name: 'Config',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'gpt-image-2',
    );

    final emptyPrompts = buildBatchGenerationJobCreationPlan(
      apiConfig: validConfig,
      prompts: const [' ', ''],
      negativePrompt: '',
      size: '1024x1024',
      targetCount: 1,
      requestCount: 1,
      advancedSettings: const ImageAdvancedSettings(),
      user: '',
    );
    final missingApiKey = buildBatchGenerationJobCreationPlan(
      apiConfig: validConfig.copyWith(apiKey: ' '),
      prompts: const ['prompt'],
      negativePrompt: '',
      size: '1024x1024',
      targetCount: 1,
      requestCount: 1,
      advancedSettings: const ImageAdvancedSettings(),
      user: '',
    );
    final missingModel = buildBatchGenerationJobCreationPlan(
      apiConfig: validConfig.copyWith(model: ' '),
      prompts: const ['prompt'],
      negativePrompt: '',
      size: '1024x1024',
      targetCount: 1,
      requestCount: 1,
      advancedSettings: const ImageAdvancedSettings(),
      user: '',
    );

    expect(emptyPrompts.canCreate, isFalse);
    expect(
      emptyPrompts.failure,
      BatchGenerationJobCreationFailure.missingPrompts,
    );
    expect(emptyPrompts.jobs, isEmpty);
    expect(
      missingApiKey.failure,
      BatchGenerationJobCreationFailure.missingApiKey,
    );
    expect(missingApiKey.jobs, isEmpty);
    expect(
      missingModel.failure,
      BatchGenerationJobCreationFailure.missingModel,
    );
    expect(missingModel.jobs, isEmpty);
  });

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

  test('batch image service keeps requesting until a job is filled', () async {
    final generationService = _OneImageAtATimeGenerationService();
    final job = _job('under returned').copyWith(imageCount: 4);

    final completed = await const BatchImageGenerationService().runJob(
      job: job,
      client: OpenAICompatibleImageClient(),
      store: AppLocalStore(),
      imageLibraryService: const ImageLibraryService(),
      imageGenerationService: generationService,
      titlePrefix: '批量结果',
      source: '批量生成',
    );

    expect(completed.status, BatchGenerationJobStatus.succeeded);
    expect(completed.resultImages, hasLength(4));
    expect(completed.libraryItems, hasLength(4));
    expect(generationService.requestedCounts, [4, 3, 2, 1]);
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

class _OneImageAtATimeGenerationService extends ImageGenerationService {
  final requestedCounts = <int>[];

  @override
  Future<TextImageGenerationResult> generateTextImages({
    required OpenAICompatibleImageClient client,
    required AppLocalStore store,
    required ImageLibraryService imageLibraryService,
    required ApiConfig apiConfig,
    required String prompt,
    required String negativePrompt,
    required String size,
    required int imageCount,
    required ImageAdvancedSettings advancedSettings,
    required String user,
    String? templateImagePath,
    List<String> templateImagePaths = const <String>[],
    ImageAssetKind libraryKind = ImageAssetKind.generatedImage,
    required String titlePrefix,
    required String source,
    void Function(ImageRequestDebugRecord record)? onDebugRecord,
  }) async {
    requestedCounts.add(imageCount);
    final imageNumber = requestedCounts.length;
    final groupId = 'group-$imageNumber';
    return TextImageGenerationResult(
      groupId: groupId,
      cachedImages: [
        GeneratedImage.bytes(Uint8List.fromList([imageNumber])),
      ],
      generation: buildGenerationSnapshot(
        groupId: groupId,
        apiConfig: apiConfig,
        prompt: prompt,
        negativePrompt: negativePrompt,
        requestSize: size,
        imageCount: imageCount,
        resultCount: 1,
        advancedSettings: advancedSettings,
        user: user,
      ),
      libraryItems: [_libraryItem('result-$imageNumber')],
    );
  }
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
