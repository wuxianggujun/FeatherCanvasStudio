part of 'package:feather_canvas_studio/main.dart';

mixin _BatchGenerationStateMixin
    on
        State<FeatherCanvasHomePage>,
        _ApiConfigStateMixin,
        _LocalSettingsStateMixin,
        _ImageLibraryStateMixin,
        _ImageGenerationStateMixin {
  @override
  OpenAICompatibleImageClient get _client;
  @override
  AppLocalStore get _store;
  @override
  ImageLibraryService get _imageLibraryService;
  @override
  List<ImageLibraryItem> get _imageLibrary;
  @override
  set _imageLibrary(List<ImageLibraryItem> value);
  @override
  TextEditingController get _promptController;
  @override
  TextEditingController get _negativePromptController;
  @override
  TextEditingController get _userController;
  @override
  List<ApiConfig> get _apiConfigs;
  @override
  ApiConfig get _selectedApiConfig;
  @override
  String? get _selectedApiConfigId;
  @override
  ApiProviderKind get _apiConfigProviderKind;
  @override
  ImageSizeCapabilityOverride get _imageSizeCapabilityOverride;
  @override
  String get _size;
  @override
  ImageAdvancedSettings get _advancedSettings;
  @override
  Future<void> _selectApiConfig(String id);
  @override
  Future<void> _selectFeature(WorkspaceFeature feature);
  @override
  void _setSize(String value);
  @override
  void _setAdvancedSettings(ImageAdvancedSettings value);
  @override
  Future<ApiConfig> _prepareSelectedApiConfigForRequest();
  @override
  void _showMessage(String message);

  BatchGenerationNotifier get _batchGenerationNotifier;

  final TextEditingController _batchPromptController = TextEditingController();
  final BatchImageGenerationService _batchGenerationService =
      const BatchImageGenerationService();

  // ignore: unused_element
  List<BatchGenerationJob> get _batchJobs => _batchGenerationNotifier.jobs;
  set _batchJobs(List<BatchGenerationJob> value) =>
      _batchGenerationNotifier.jobs = value;
  // ignore: unused_element
  int get _batchTargetCount => _batchGenerationNotifier.targetCount;
  set _batchTargetCount(int value) =>
      _batchGenerationNotifier.targetCount = value;
  // ignore: unused_element
  int get _batchRequestCount => _batchGenerationNotifier.requestCount;
  set _batchRequestCount(int value) =>
      _batchGenerationNotifier.requestCount = value;
  // ignore: unused_element
  bool get _isBatchGenerationRunning => _batchGenerationNotifier.isRunning;
  set _isBatchGenerationRunning(bool value) =>
      _batchGenerationNotifier.isRunning = value;
  // ignore: unused_element
  bool get _pauseBatchGenerationAfterCurrent =>
      _batchGenerationNotifier.pauseAfterCurrent;
  set _pauseBatchGenerationAfterCurrent(bool value) =>
      _batchGenerationNotifier.pauseAfterCurrent = value;

  void _disposeBatchGenerationState() {
    _batchPromptController.dispose();
  }

  Future<List<BatchGenerationJob>?> _createBatchJobs(String prompt) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      return null;
    }

    final l10n = appL10nOf(context);
    final apiConfig = await _prepareSelectedApiConfigForRequest();
    if (apiConfig.apiKey.trim().isEmpty) {
      _showMessage(l10n.batchGenerationMissingApiKey);
      return null;
    }
    if (apiConfig.model.trim().isEmpty) {
      _showMessage(l10n.batchGenerationMissingModel);
      return null;
    }

    final batches = splitImageGenerationBatches(
      targetCount: _batchTargetCount,
      requestCount: _batchRequestCount,
    );
    return [
      for (var index = 0; index < batches.length; index++)
        BatchGenerationJob.create(
          apiConfig: apiConfig,
          prompt: trimmedPrompt,
          negativePrompt: _negativePromptController.text.trim(),
          size: _size,
          imageCount: batches[index],
          advancedSettings: _advancedSettings,
          user: _userController.text.trim(),
          batchIndex: index + 1,
          batchTotal: batches.length,
        ),
    ];
  }

  Future<void> _addBatchPromptLinesToQueue() async {
    final prompts = _batchPromptController.text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final l10n = appL10nOf(context);
    if (prompts.isEmpty) {
      _showMessage(l10n.batchGenerationMissingPrompts);
      return;
    }

    final jobs = <BatchGenerationJob>[];
    for (final prompt in prompts) {
      final promptJobs = await _createBatchJobs(prompt);
      if (promptJobs == null) {
        return;
      }
      jobs.addAll(promptJobs);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _batchJobs = [..._batchJobs, ...jobs];
      _batchPromptController.clear();
    });
    _showMessage(l10n.batchGenerationJobsAdded(jobs.length));
  }

  void _setBatchTargetCount(int value) {
    setState(() {
      _batchTargetCount = normalizeBatchGenerationTargetCount(value);
    });
  }

  void _setBatchRequestCount(int value) {
    setState(() {
      _batchRequestCount = normalizeImageGenerationRequestCount(value);
    });
  }

  void _removeBatchJob(BatchGenerationJob job) {
    if (!job.canDelete) {
      return;
    }
    setState(() {
      _batchJobs = [
        for (final current in _batchJobs)
          if (current.id != job.id) current,
      ];
    });
  }

  void _clearFinishedBatchJobs() {
    setState(() {
      _batchJobs = [
        for (final job in _batchJobs)
          if (!job.isTerminal) job,
      ];
    });
  }

  void _retryFailedBatchJobs() {
    if (_isBatchGenerationRunning) {
      _showMessage(appL10nOf(context).batchGenerationRetryBlockedRunning);
      return;
    }

    final failedCount = _batchJobs.where((job) => job.canRetry).length;
    if (failedCount == 0) {
      _showMessage(appL10nOf(context).batchGenerationNoFailedJobsToRetry);
      return;
    }

    setState(() {
      _batchJobs = [
        for (final job in _batchJobs)
          if (job.canRetry) _requeueFailedBatchJob(job) else job,
      ];
    });
    _showMessage(
      appL10nOf(context).batchGenerationFailedJobsRequeued(failedCount),
    );
  }

  void _retryFailedBatchJob(BatchGenerationJob job) {
    if (_isBatchGenerationRunning) {
      _showMessage(appL10nOf(context).batchGenerationRetryBlockedRunning);
      return;
    }
    if (!job.canRetry) {
      return;
    }

    final jobIndex = _batchJobs.indexWhere((current) => current.id == job.id);
    if (jobIndex < 0 || !_batchJobs[jobIndex].canRetry) {
      return;
    }

    setState(() {
      _batchJobs = _replaceBatchJob(
        _batchJobs,
        jobIndex,
        _requeueFailedBatchJob(_batchJobs[jobIndex]),
      );
    });
    _showMessage(appL10nOf(context).batchGenerationFailedJobRequeued);
  }

  BatchGenerationJob _requeueFailedBatchJob(BatchGenerationJob job) {
    return job.copyWith(
      status: BatchGenerationJobStatus.queued,
      retryAttempt: 0,
      resultImages: const <GeneratedImage>[],
      libraryItems: const <ImageLibraryItem>[],
      clearErrorMessage: true,
      clearDebugRecord: true,
    );
  }

  Future<void> _startBatchGenerationQueue() async {
    if (_isBatchGenerationRunning) {
      return;
    }
    final l10n = appL10nOf(context);

    setState(() {
      _isBatchGenerationRunning = true;
      _pauseBatchGenerationAfterCurrent = false;
    });

    while (mounted && !_pauseBatchGenerationAfterCurrent) {
      final jobIndex = _batchJobs.indexWhere((job) => job.isPending);
      if (jobIndex < 0) {
        break;
      }

      final job = _batchJobs[jobIndex];
      setState(() {
        _batchJobs = _replaceBatchJob(
          _batchJobs,
          jobIndex,
          job.copyWith(
            status: BatchGenerationJobStatus.running,
            clearErrorMessage: true,
            clearDebugRecord: true,
          ),
        );
      });

      try {
        ImageRequestDebugRecord? debugRecord;
        final completed = await _batchGenerationService.runJob(
          job: job,
          client: _client,
          store: _store,
          imageLibraryService: _imageLibraryService,
          imageGenerationService: _imageGenerationService,
          titlePrefix: l10n.batchGenerationLibraryTitlePrefix,
          source: l10n.batchGenerationLibrarySource,
          onDebugRecord: (record) {
            debugRecord = record;
            if (!mounted) {
              return;
            }
            final currentIndex = _batchJobs.indexWhere(
              (current) => current.id == job.id,
            );
            if (currentIndex >= 0) {
              setState(() {
                _batchJobs = _replaceBatchJob(
                  _batchJobs,
                  currentIndex,
                  _batchJobs[currentIndex].copyWith(debugRecord: record),
                );
              });
            }
          },
        );
        if (!mounted) {
          return;
        }
        final currentIndex = _batchJobs.indexWhere(
          (current) => current.id == job.id,
        );
        if (currentIndex >= 0) {
          setState(() {
            _batchJobs = _replaceBatchJob(
              _batchJobs,
              currentIndex,
              completed.copyWith(debugRecord: debugRecord),
            );
            _imageLibrary = [...completed.libraryItems, ..._imageLibrary];
          });
        }
      } catch (error) {
        if (!mounted) {
          return;
        }
        final currentIndex = _batchJobs.indexWhere(
          (current) => current.id == job.id,
        );
        if (currentIndex >= 0) {
          setState(() {
            final update = updateBatchJobAfterFailure(
              jobs: _batchJobs,
              jobIndex: currentIndex,
              error: error,
              autoRetryMessageBuilder:
                  ({
                    required errorMessage,
                    required maxRetryAttempts,
                    required retryAttempt,
                  }) => l10n.batchGenerationAutoRetryMessage(
                    retryAttempt,
                    maxRetryAttempts,
                    errorMessage,
                  ),
            );
            _batchJobs = update.jobs;
          });
        }
      }
    }

    if (mounted) {
      final pausedByUser = _pauseBatchGenerationAfterCurrent;
      final queuedCount = _batchJobs.where((job) => job.isPending).length;
      setState(() {
        _isBatchGenerationRunning = false;
        _pauseBatchGenerationAfterCurrent = false;
      });
      if (pausedByUser && queuedCount > 0) {
        _showMessage(
          appL10nOf(context).batchGenerationQueuePaused(queuedCount),
        );
      } else {
        _showMessage(appL10nOf(context).batchGenerationQueueStopped);
      }
    }
  }

  void _pauseBatchGenerationQueue() {
    if (!_isBatchGenerationRunning) {
      return;
    }
    setState(() => _pauseBatchGenerationAfterCurrent = true);
    _showMessage(appL10nOf(context).batchGenerationPauseRequested);
  }

  void _resumeBatchGenerationQueue() {
    if (!_pauseBatchGenerationAfterCurrent) {
      if (!_isBatchGenerationRunning) {
        unawaited(_startBatchGenerationQueue());
      }
      return;
    }
    setState(() => _pauseBatchGenerationAfterCurrent = false);
    _showMessage(appL10nOf(context).batchGenerationResumed);
  }

  void _cancelQueuedBatchJobs() {
    final queuedCount = _batchJobs.where((job) => job.isPending).length;
    final l10n = appL10nOf(context);
    if (queuedCount == 0) {
      _showMessage(l10n.batchGenerationNoQueuedJobsToCancel);
      return;
    }
    setState(() {
      _pauseBatchGenerationAfterCurrent = _isBatchGenerationRunning;
      _batchJobs = [
        for (final job in _batchJobs)
          if (job.isPending)
            job.copyWith(
              status: BatchGenerationJobStatus.skipped,
              errorMessage: l10n.batchGenerationUserCanceledQueuedJob,
            )
          else
            job,
      ];
    });
    final runningHint = _isBatchGenerationRunning
        ? l10n.batchGenerationCancelQueuedRunningHint
        : '';
    _showMessage(
      l10n.batchGenerationQueuedJobsCanceled(queuedCount, runningHint),
    );
  }

  Future<void> _makeBatchImageBackgroundTransparent(
    int previewIndex,
    GeneratedImage image,
  ) async {
    final sourceItem = _findImageLibraryItemByPath(image.filePath);
    final l10n = appL10nOf(context);
    final fallbackTitle = l10n.batchGenerationResultTitle(previewIndex + 1);
    final tolerance = await showBackgroundTransparencyDialog(
      context,
      sourceTitle: sourceItem?.displayTitle ?? fallbackTitle,
    );
    if (tolerance == null || !mounted) {
      return;
    }

    try {
      final sourceBytes = await _resolveGeneratedPreviewBytes(image);
      final saved = await _saveTransparentBackgroundImage(
        sourceBytes: sourceBytes,
        tolerance: tolerance,
        sourceItem: sourceItem,
        fallbackTitle: fallbackTitle,
        source: l10n.batchGenerationSourceName,
      );
      if (!mounted) {
        return;
      }
      if (saved == null) {
        _showMessage(l10n.backgroundTransparencyNoEdgeDetected);
        return;
      }

      setState(() {
        _batchJobs = _replaceBatchPreviewImage(
          jobs: _batchJobs,
          previewIndex: previewIndex,
          replacement: GeneratedImage.file(
            saved.item.path,
            revisedPrompt: image.revisedPrompt,
          ),
          appendedItem: saved.item,
        );
      });
      _showMessage(
        l10n.batchGenerationTransparentImageSaved(
          saved.item.displayTitle,
          saved.transparentPixelCount,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(appL10nOf(context).backgroundTransparencyFailed(error));
    }
  }

  Future<void> _copyBatchPreviewImage(GeneratedImage image) async {
    try {
      final result = await _copyGeneratedImageToClipboard(image);
      if (!mounted) {
        return;
      }
      _showImageClipboardCopyResult(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(appL10nOf(context).copyImageFailed(error));
    }
  }

  List<BatchGenerationJob> _replaceBatchJob(
    List<BatchGenerationJob> jobs,
    int index,
    BatchGenerationJob replacement,
  ) {
    return [
      for (var i = 0; i < jobs.length; i++)
        if (i == index) replacement else jobs[i],
    ];
  }

  List<BatchGenerationJob> _replaceBatchPreviewImage({
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

  Widget _buildBatchGenerationWorkspace() {
    return BatchGenerationWorkspace(
      promptController: _batchPromptController,
      negativePromptController: _negativePromptController,
      userController: _userController,
      apiConfigs: _apiConfigs,
      selectedApiConfig: _selectedApiConfig,
      selectedApiConfigId: _selectedApiConfigId ?? _selectedApiConfig.id,
      providerKind: _apiConfigProviderKind,
      imageSizeCapabilityOverride: _imageSizeCapabilityOverride,
      size: _size,
      advancedSettings: _advancedSettings,
      onApiConfigChanged: _selectApiConfig,
      onOpenApiSettings: () =>
          unawaited(_selectFeature(WorkspaceFeature.apiSettings)),
      onSizeChanged: _setSize,
      onAdvancedSettingsChanged: _setAdvancedSettings,
      onTargetCountChanged: _setBatchTargetCount,
      onRequestCountChanged: _setBatchRequestCount,
      onAddPrompts: () => unawaited(_addBatchPromptLinesToQueue()),
      onStart: () => unawaited(_startBatchGenerationQueue()),
      onPause: _pauseBatchGenerationQueue,
      onResume: _resumeBatchGenerationQueue,
      onCancelQueued: _cancelQueuedBatchJobs,
      onRetryFailed: _retryFailedBatchJobs,
      onRemoveJob: _removeBatchJob,
      onRetryJob: _retryFailedBatchJob,
      onClearFinished: _clearFinishedBatchJobs,
      onCopyImage: (index, image) => unawaited(_copyBatchPreviewImage(image)),
      onExportImage: (index, image) =>
          unawaited(_exportGeneratedPreviewImage(index, image)),
      onMakeBackgroundTransparent: (index, image) =>
          unawaited(_makeBatchImageBackgroundTransparent(index, image)),
    );
  }
}
