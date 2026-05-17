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

  final TextEditingController _batchPromptController = TextEditingController();
  final BatchImageGenerationService _batchGenerationService =
      const BatchImageGenerationService();

  List<BatchGenerationJob> _batchJobs = const [];
  int _batchTargetCount = defaultBatchGenerationTargetCount;
  int _batchRequestCount = defaultBatchGenerationRequestCount;
  bool _isBatchGenerationRunning = false;
  bool _pauseBatchGenerationAfterCurrent = false;

  void _disposeBatchGenerationState() {
    _batchPromptController.dispose();
  }

  Future<List<BatchGenerationJob>?> _createBatchJobs(String prompt) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      return null;
    }

    final apiConfig = await _prepareSelectedApiConfigForRequest();
    if (apiConfig.apiKey.trim().isEmpty) {
      _showMessage('请先在接口配置页填写 API Key');
      return null;
    }
    if (apiConfig.model.trim().isEmpty) {
      _showMessage('请先在接口配置页获取模型列表并选择模型');
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
    if (prompts.isEmpty) {
      _showMessage('请先填写至少一行批量提示词');
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
    _showMessage('已拆分并加入 ${jobs.length} 个批量任务');
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
      _showMessage('队列运行中，请等待当前队列停止后再重试失败任务');
      return;
    }

    final failedCount = _batchJobs.where((job) => job.canRetry).length;
    if (failedCount == 0) {
      _showMessage('没有失败任务可重试');
      return;
    }

    setState(() {
      _batchJobs = [
        for (final job in _batchJobs)
          if (job.canRetry) _requeueFailedBatchJob(job) else job,
      ];
    });
    _showMessage('已将 $failedCount 个失败任务重新加入等待队列');
  }

  void _retryFailedBatchJob(BatchGenerationJob job) {
    if (_isBatchGenerationRunning) {
      _showMessage('队列运行中，请等待当前队列停止后再重试失败任务');
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
    _showMessage('已将失败任务重新加入等待队列');
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
        _showMessage('队列已暂停，可继续执行剩余 $queuedCount 个任务');
      } else {
        _showMessage('批量队列已停止');
      }
    }
  }

  void _pauseBatchGenerationQueue() {
    if (!_isBatchGenerationRunning) {
      return;
    }
    setState(() => _pauseBatchGenerationAfterCurrent = true);
    _showMessage('已暂停后续任务；正在请求的一批会等待接口返回');
  }

  void _resumeBatchGenerationQueue() {
    if (!_pauseBatchGenerationAfterCurrent) {
      if (!_isBatchGenerationRunning) {
        unawaited(_startBatchGenerationQueue());
      }
      return;
    }
    setState(() => _pauseBatchGenerationAfterCurrent = false);
    _showMessage('已恢复后续任务');
  }

  void _cancelQueuedBatchJobs() {
    final queuedCount = _batchJobs.where((job) => job.isPending).length;
    if (queuedCount == 0) {
      _showMessage('没有等待中的任务可取消');
      return;
    }
    setState(() {
      _pauseBatchGenerationAfterCurrent = _isBatchGenerationRunning;
      _batchJobs = [
        for (final job in _batchJobs)
          if (job.isPending)
            job.copyWith(
              status: BatchGenerationJobStatus.skipped,
              errorMessage: '用户取消等待任务',
            )
          else
            job,
      ];
    });
    final runningHint = _isBatchGenerationRunning ? '；当前正在请求的一批会等待接口返回' : '';
    _showMessage('已取消 $queuedCount 个等待任务$runningHint');
  }

  Future<void> _makeBatchImageBackgroundTransparent(
    int previewIndex,
    GeneratedImage image,
  ) async {
    final sourceItem = _findImageLibraryItemByPath(image.filePath);
    final fallbackTitle = '批量结果 ${previewIndex + 1}';
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
        source: '批量生成',
      );
      if (!mounted) {
        return;
      }
      if (saved == null) {
        _showMessage('没有检测到可透明化的边缘背景，可尝试调高容差');
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
        '已生成透明背景图片：${saved.item.displayTitle} · '
        '透明化 ${saved.transparentPixelCount} 个像素',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('背景转透明失败：$error');
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
      _showMessage('复制图片失败：$error');
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
      jobs: _batchJobs,
      targetCount: _batchTargetCount,
      requestCount: _batchRequestCount,
      isRunning: _isBatchGenerationRunning,
      isPausing: _pauseBatchGenerationAfterCurrent,
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
