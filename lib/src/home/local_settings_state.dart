part of 'package:feather_canvas_studio/main.dart';

const Duration _generationFormHistoryMergeWindow = Duration(milliseconds: 800);
const Duration _generationTextHistoryDebounce = Duration(milliseconds: 650);
const String _textPromptHistoryKey = 'text-prompt';
const String _animationPromptHistoryKey = 'animation-prompt';
const String _negativePromptHistoryKey = 'negative-prompt';
const String _sizeHistoryKey = 'generation-size';
const String _imageCountHistoryKey = 'generation-count';
const String _advancedSettingsHistoryKey = 'generation-advanced-settings';

class _PendingGenerationTextHistory {
  const _PendingGenerationTextHistory({
    required this.feature,
    required this.key,
    required this.label,
    required this.before,
    required this.after,
    required this.restore,
  });

  final WorkspaceFeature feature;
  final String key;
  final String label;
  final String before;
  final String after;
  final FutureOr<void> Function(String value) restore;
}

class _LocalGenerationPresetSnapshot {
  const _LocalGenerationPresetSnapshot({
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
    required this.advancedSettings,
  });

  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _LocalGenerationPresetSnapshot &&
            prompt == other.prompt &&
            negativePrompt == other.negativePrompt &&
            size == other.size &&
            imageCount == other.imageCount &&
            advancedSettings == other.advancedSettings;
  }

  @override
  int get hashCode =>
      Object.hash(prompt, negativePrompt, size, imageCount, advancedSettings);
}

class _SpriteSheetPresetSnapshot {
  const _SpriteSheetPresetSnapshot({
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.spriteSheetImportConfig,
    required this.advancedSettings,
  });

  final String prompt;
  final String negativePrompt;
  final String size;
  final SpriteSheetImportConfig spriteSheetImportConfig;
  final ImageAdvancedSettings advancedSettings;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _SpriteSheetPresetSnapshot &&
            prompt == other.prompt &&
            negativePrompt == other.negativePrompt &&
            size == other.size &&
            spriteSheetImportConfig == other.spriteSheetImportConfig &&
            advancedSettings == other.advancedSettings;
  }

  @override
  int get hashCode => Object.hash(
    prompt,
    negativePrompt,
    size,
    spriteSheetImportConfig,
    advancedSettings,
  );
}

class _GifPresetSnapshot {
  const _GifPresetSnapshot({
    required this.delayMs,
    required this.loopCount,
    required this.playbackMode,
  });

  final int delayMs;
  final int loopCount;
  final GifPlaybackMode playbackMode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _GifPresetSnapshot &&
            delayMs == other.delayMs &&
            loopCount == other.loopCount &&
            playbackMode == other.playbackMode;
  }

  @override
  int get hashCode => Object.hash(delayMs, loopCount, playbackMode);
}

mixin _LocalSettingsStateMixin
    on State<FeatherCanvasHomePage>, _ApiConfigStateMixin {
  @override
  AppLocalStore get _store;
  @override
  bool get _isBootstrapping;
  @override
  bool get _isRestoringState;
  @override
  set _isRestoringState(bool value);
  WorkspaceFeature get _selectedFeature;
  List<ImageLibraryItem> get _imageLibrary;
  set _imageLibrary(List<ImageLibraryItem> value);
  List<GeneratedImage> get _generatedImages;
  List<GeneratedImage> get _animationFrames;
  List<AppPreset> get _appPresets;
  set _appPresets(List<AppPreset> value);
  TextEditingController get _animationPromptController;
  SpriteSheetImportConfig get _spriteSheetImportConfig;
  set _spriteSheetImportConfig(SpriteSheetImportConfig value);
  int get _gifDefaultFrameDelayMs;
  set _gifDefaultFrameDelayMs(int value);
  int get _gifLoopCount;
  set _gifLoopCount(int value);
  GifPlaybackMode get _gifPlaybackMode;
  set _gifPlaybackMode(GifPlaybackMode value);
  Future<void> _selectFeature(WorkspaceFeature feature);
  Future<void> _confirmResetToDefaults();
  void _pushHistory(WorkspaceFeature feature, HistoryAction action);
  bool _replaceTopHistory(
    WorkspaceFeature feature, {
    required HistoryAction current,
    required HistoryAction replacement,
  });
  @override
  void _showMessage(String message);
  Widget _buildCompactHistoryControls();

  final TextEditingController _promptController = TextEditingController(
    text: defaultAppSettings.prompt,
  );
  final TextEditingController _negativePromptController =
      TextEditingController();
  final TextEditingController _userController = TextEditingController();

  @override
  String _size = defaultAppSettings.size;
  int _imageCount = defaultAppSettings.imageCount;
  ImageAdvancedSettings _advancedSettings = defaultAppSettings.advancedSettings;
  bool _isCleaningStorage = false;
  bool _isExportingLibrary = false;
  bool _isImportingLibrary = false;
  Timer? _settingsSaveDebounce;
  Timer? _generationTextHistoryDebounceTimer;
  _PendingGenerationTextHistory? _pendingGenerationTextHistory;
  HistoryAction? _lastGenerationFormHistoryAction;
  String? _lastGenerationFormHistoryKey;
  WorkspaceFeature? _lastGenerationFormHistoryFeature;
  DateTime? _lastGenerationFormHistoryAt;
  Object? _lastGenerationFormHistoryBefore;
  String _lastPromptText = defaultAppSettings.prompt;
  String _lastAnimationPromptText = defaultAnimationPrompt;
  String _lastNegativePromptText = '';

  void _initLocalSettingsState() {
    _promptController.addListener(_handlePromptTextChanged);
    _animationPromptController.addListener(_handleAnimationPromptChanged);
    _negativePromptController.addListener(_handleNegativePromptChanged);
    _userController.addListener(_syncUserAndScheduleSettingsSave);
  }

  void _disposeLocalSettingsState() {
    _settingsSaveDebounce?.cancel();
    _generationTextHistoryDebounceTimer?.cancel();
    _animationPromptController.removeListener(_handleAnimationPromptChanged);
    _promptController.dispose();
    _negativePromptController.dispose();
    _userController.dispose();
  }

  void _scheduleSettingsSave() {
    if (_isBootstrapping || _isRestoringState) {
      return;
    }

    _settingsSaveDebounce?.cancel();
    _settingsSaveDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_saveSettings());
    });
  }

  void _syncUserAndScheduleSettingsSave() {
    if (_isBootstrapping || _isRestoringState) {
      _advancedSettings = _advancedSettings.copyWith(
        user: _userController.text.trim(),
      );
      return;
    }

    final before = _advancedSettings;
    final after = _advancedSettings.copyWith(user: _userController.text.trim());
    _advancedSettings = after;
    _scheduleSettingsSave();
    _pushAdvancedSettingsHistoryIfNeeded(before, after);
  }

  @override
  Future<void> _saveSettings() async {
    final apiConfig = _selectedApiConfig;
    final normalizedSize = safeImageSizeForModel(
      size: _size,
      providerKind: apiConfig.providerKind,
      model: apiConfig.model,
      capabilityOverride: apiConfig.imageSizeCapabilityOverride,
    );
    await _store.saveSettings(
      AppSettings(
        baseUrl: apiConfig.baseUrl,
        apiKey: apiConfig.apiKey,
        model: apiConfig.model,
        prompt: _promptController.text,
        negativePrompt: _negativePromptController.text,
        size: normalizedSize,
        imageCount: _imageCount,
        advancedSettings: _advancedSettings.copyWith(
          user: _userController.text.trim(),
        ),
      ),
    );
  }

  void _setSize(String value) {
    _flushPendingGenerationTextHistory();
    final before = _size;
    final after = value.trim();
    if (before == after) {
      return;
    }

    setState(() => _size = after);
    _scheduleSettingsSave();
    final feature = _generationFormHistoryFeature(
      includeAnimationProject: true,
      includeImageGeneration: true,
    );
    if (feature == null) {
      return;
    }
    _pushGenerationFormFieldHistory<String>(
      feature: feature,
      key: _sizeHistoryKey,
      label: appL10nOf(context).localSettingsStateAdjustSizeHistory(after),
      before: before,
      after: after,
      restore: _restoreSize,
    );
  }

  void _setImageCount(int value) {
    _flushPendingGenerationTextHistory();
    final normalized = normalizeImageGenerationTargetCount(value);
    final before = _imageCount;
    if (before == normalized) {
      return;
    }

    setState(() => _imageCount = normalized);
    _scheduleSettingsSave();
    final feature = _generationFormHistoryFeature(
      includeAnimationProject: false,
      includeImageGeneration: true,
    );
    if (feature == null) {
      return;
    }
    _pushGenerationFormFieldHistory<int>(
      feature: feature,
      key: _imageCountHistoryKey,
      label: appL10nOf(
        context,
      ).localSettingsStateAdjustImageCountHistory(normalized),
      before: before,
      after: normalized,
      restore: _restoreImageCount,
    );
  }

  void _setAdvancedSettings(ImageAdvancedSettings value) {
    _flushPendingGenerationTextHistory();
    final before = _advancedSettings;
    if (before == value) {
      return;
    }

    setState(() => _advancedSettings = value);
    if (_userController.text != value.user) {
      _userController.text = value.user;
    }
    _scheduleSettingsSave();
    _pushAdvancedSettingsHistoryIfNeeded(before, value);
  }

  void _handlePromptTextChanged() {
    _handleGenerationTextChanged(
      key: _textPromptHistoryKey,
      label: appL10nOf(context).localSettingsStateEditPositivePromptHistory,
      before: _lastPromptText,
      after: _promptController.text,
      remember: (value) => _lastPromptText = value,
      feature: switch (_selectedFeature) {
        WorkspaceFeature.imageGeneration => WorkspaceFeature.imageGeneration,
        WorkspaceFeature.localSettings => WorkspaceFeature.localSettings,
        _ => null,
      },
      restore: (value) => _restoreTextControllerValue(
        controller: _promptController,
        value: value,
        remember: (value) => _lastPromptText = value,
        saveSettings: true,
      ),
    );
  }

  void _handleAnimationPromptChanged() {
    _handleGenerationTextChanged(
      key: _animationPromptHistoryKey,
      label: appL10nOf(context).localSettingsStateEditAnimationPromptHistory,
      before: _lastAnimationPromptText,
      after: _animationPromptController.text,
      remember: (value) => _lastAnimationPromptText = value,
      feature: switch (_selectedFeature) {
        WorkspaceFeature.animationProject => WorkspaceFeature.animationProject,
        WorkspaceFeature.localSettings => WorkspaceFeature.localSettings,
        _ => null,
      },
      restore: (value) => _restoreTextControllerValue(
        controller: _animationPromptController,
        value: value,
        remember: (value) => _lastAnimationPromptText = value,
        saveSettings: false,
      ),
    );
  }

  void _handleNegativePromptChanged() {
    final feature = _generationFormHistoryFeature(
      includeAnimationProject: true,
      includeImageGeneration: true,
    );
    _handleGenerationTextChanged(
      key: _negativePromptHistoryKey,
      label: appL10nOf(context).localSettingsStateEditNegativePromptHistory,
      before: _lastNegativePromptText,
      after: _negativePromptController.text,
      remember: (value) => _lastNegativePromptText = value,
      feature: feature,
      restore: (value) => _restoreTextControllerValue(
        controller: _negativePromptController,
        value: value,
        remember: (value) => _lastNegativePromptText = value,
        saveSettings: true,
      ),
    );
  }

  void _handleGenerationTextChanged({
    required String key,
    required String label,
    required String before,
    required String after,
    required ValueChanged<String> remember,
    required WorkspaceFeature? feature,
    required FutureOr<void> Function(String value) restore,
  }) {
    remember(after);

    if (_isBootstrapping || _isRestoringState) {
      return;
    }

    if (key != _animationPromptHistoryKey) {
      _scheduleSettingsSave();
    }

    if (before == after || feature == null) {
      return;
    }

    final pending = _pendingGenerationTextHistory;
    if (pending != null && (pending.key != key || pending.feature != feature)) {
      _flushPendingGenerationTextHistory();
    }

    final currentPending = _pendingGenerationTextHistory;
    _pendingGenerationTextHistory = _PendingGenerationTextHistory(
      feature: feature,
      key: key,
      label: label,
      before: currentPending?.key == key && currentPending?.feature == feature
          ? currentPending!.before
          : before,
      after: after,
      restore: restore,
    );
    _generationTextHistoryDebounceTimer?.cancel();
    _generationTextHistoryDebounceTimer = Timer(
      _generationTextHistoryDebounce,
      _flushPendingGenerationTextHistory,
    );
  }

  void _flushPendingGenerationTextHistory() {
    final pending = _pendingGenerationTextHistory;
    if (pending == null) {
      return;
    }

    _generationTextHistoryDebounceTimer?.cancel();
    _generationTextHistoryDebounceTimer = null;
    _pendingGenerationTextHistory = null;
    if (pending.before == pending.after) {
      return;
    }

    _pushGenerationFormFieldHistory<String>(
      feature: pending.feature,
      key: pending.key,
      label: pending.label,
      before: pending.before,
      after: pending.after,
      restore: pending.restore,
    );
  }

  WorkspaceFeature? _generationFormHistoryFeature({
    required bool includeAnimationProject,
    required bool includeImageGeneration,
  }) {
    return switch (_selectedFeature) {
      WorkspaceFeature.imageGeneration when includeImageGeneration =>
        WorkspaceFeature.imageGeneration,
      WorkspaceFeature.animationProject when includeAnimationProject =>
        WorkspaceFeature.animationProject,
      WorkspaceFeature.localSettings
          when includeAnimationProject || includeImageGeneration =>
        WorkspaceFeature.localSettings,
      _ => null,
    };
  }

  void _pushAdvancedSettingsHistoryIfNeeded(
    ImageAdvancedSettings before,
    ImageAdvancedSettings after,
  ) {
    if (before == after || _isBootstrapping || _isRestoringState) {
      return;
    }

    final feature = _generationFormHistoryFeature(
      includeAnimationProject: true,
      includeImageGeneration: true,
    );
    if (feature == null) {
      return;
    }

    _pushGenerationFormFieldHistory<ImageAdvancedSettings>(
      feature: feature,
      key: _advancedSettingsHistoryKey,
      label: _advancedSettingsHistoryLabel(before, after),
      before: before,
      after: after,
      restore: _restoreAdvancedSettings,
    );
  }

  void _pushGenerationFormFieldHistory<T>({
    required WorkspaceFeature feature,
    required String key,
    required String label,
    required T before,
    required T after,
    required FutureOr<void> Function(T value) restore,
  }) {
    if (before == after) {
      return;
    }

    final now = DateTime.now();
    final previousAction = _lastGenerationFormHistoryAction;
    final previousAt = _lastGenerationFormHistoryAt;
    final shouldMerge =
        previousAction != null &&
        previousAt != null &&
        _lastGenerationFormHistoryKey == key &&
        _lastGenerationFormHistoryFeature == feature &&
        now.difference(previousAt) <= _generationFormHistoryMergeWindow;

    if (shouldMerge) {
      final mergedBefore = _lastGenerationFormHistoryBefore is T
          ? _lastGenerationFormHistoryBefore as T
          : before;
      final replacement = _generationFormFieldHistoryAction<T>(
        label: label,
        before: mergedBefore,
        after: after,
        restore: restore,
      );
      final replaced = _replaceTopHistory(
        feature,
        current: previousAction,
        replacement: replacement,
      );
      if (replaced) {
        _rememberGenerationFormHistory(
          action: replacement,
          feature: feature,
          key: key,
          before: mergedBefore as Object,
          now: now,
        );
        return;
      }
    }

    final action = _generationFormFieldHistoryAction<T>(
      label: label,
      before: before,
      after: after,
      restore: restore,
    );
    _pushHistory(feature, action);
    _rememberGenerationFormHistory(
      action: action,
      feature: feature,
      key: key,
      before: before as Object,
      now: now,
    );
  }

  HistoryAction _generationFormFieldHistoryAction<T>({
    required String label,
    required T before,
    required T after,
    required FutureOr<void> Function(T value) restore,
  }) {
    return HistoryAction(
      label: label,
      apply: () => restore(after),
      revert: () => restore(before),
    );
  }

  void _rememberGenerationFormHistory({
    required HistoryAction action,
    required WorkspaceFeature feature,
    required String key,
    required Object before,
    required DateTime now,
  }) {
    _lastGenerationFormHistoryAction = action;
    _lastGenerationFormHistoryFeature = feature;
    _lastGenerationFormHistoryKey = key;
    _lastGenerationFormHistoryBefore = before;
    _lastGenerationFormHistoryAt = now;
  }

  Future<void> _restoreTextControllerValue({
    required TextEditingController controller,
    required String value,
    required ValueChanged<String> remember,
    required bool saveSettings,
  }) async {
    if (!mounted) {
      return;
    }

    _isRestoringState = true;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    remember(value);
    _isRestoringState = false;

    if (saveSettings) {
      await _saveSettings();
    }
  }

  Future<void> _restoreSize(String value) async {
    if (!mounted) {
      return;
    }

    setState(() => _size = value);
    await _saveSettings();
  }

  Future<void> _restoreImageCount(int value) async {
    if (!mounted) {
      return;
    }

    setState(() => _imageCount = normalizeImageGenerationTargetCount(value));
    await _saveSettings();
  }

  Future<void> _restoreAdvancedSettings(ImageAdvancedSettings value) async {
    if (!mounted) {
      return;
    }

    _isRestoringState = true;
    setState(() => _advancedSettings = value);
    if (_userController.text != value.user) {
      _userController.text = value.user;
    }
    _isRestoringState = false;
    await _saveSettings();
  }

  String _advancedSettingsHistoryLabel(
    ImageAdvancedSettings before,
    ImageAdvancedSettings after,
  ) {
    final l10n = appL10nOf(context);
    if (before.quality != after.quality) {
      return l10n.localSettingsStateAdjustQualityHistory(
        localizedImageQualityLabel(l10n, after.quality),
      );
    }
    if (before.background != after.background) {
      return l10n.localSettingsStateAdjustBackgroundHistory(
        localizedImageBackgroundLabel(l10n, after.background),
      );
    }
    if (before.outputFormat != after.outputFormat) {
      return l10n.localSettingsStateAdjustOutputFormatHistory(
        localizedImageOutputFormatLabel(after.outputFormat),
      );
    }
    if (before.outputCompression != after.outputCompression) {
      return l10n.localSettingsStateAdjustOutputCompressionHistory(
        after.outputCompression,
      );
    }
    if (before.moderation != after.moderation) {
      return l10n.localSettingsStateAdjustModerationHistory(
        localizedImageModerationLabel(l10n, after.moderation),
      );
    }
    if (before.inputFidelity != after.inputFidelity) {
      return l10n.localSettingsStateAdjustInputFidelityHistory(
        after.inputFidelity == 'high'
            ? l10n.imageAdvancedSettingsHigh
            : l10n.imageAdvancedSettingsLow,
      );
    }
    if (before.user != after.user) {
      return l10n.localSettingsStateEditFinalUserHistory;
    }
    return l10n.localSettingsStateAdjustAdvancedSettingsHistory;
  }

  Future<void> _savePreset(AppPresetKind kind) async {
    final now = DateTime.now();
    final preset = switch (kind) {
      AppPresetKind.localGeneration => AppPreset(
        id: AppPreset.newId(),
        name: appL10nOf(
          context,
        ).localSettingsStateTextPresetName(_appPresets.length + 1),
        kind: kind,
        prompt: _promptController.text,
        negativePrompt: _negativePromptController.text,
        size: _size,
        imageCount: _imageCount,
        advancedSettings: _advancedSettings,
        createdAt: now,
        updatedAt: now,
      ),
      AppPresetKind.spriteSheet => AppPreset(
        id: AppPreset.newId(),
        name: appL10nOf(
          context,
        ).localSettingsStateAnimationPresetName(_appPresets.length + 1),
        kind: kind,
        prompt: _animationPromptController.text,
        negativePrompt: _negativePromptController.text,
        size: _size,
        rows: _spriteSheetImportConfig.rows,
        columns: _spriteSheetImportConfig.columns,
        advancedSettings: _advancedSettings,
        gridSpec: _spriteSheetImportConfig.gridSpec,
        createdAt: now,
        updatedAt: now,
      ),
      AppPresetKind.gif => AppPreset(
        id: AppPreset.newId(),
        name: 'GIF ${_appPresets.length + 1}',
        kind: kind,
        gifDelayMs: _gifDefaultFrameDelayMs,
        gifLoopCount: _gifLoopCount,
        playbackMode: _gifPlaybackMode,
        createdAt: now,
        updatedAt: now,
      ),
    };

    await _store.addPreset(preset);
    final presets = await _store.loadPresets();
    if (!mounted) {
      return;
    }
    setState(() => _appPresets = presets);
    _showMessage(appL10nOf(context).localSettingsStatePresetSaved(preset.name));
  }

  Future<void> _applyPreset(AppPreset preset) async {
    final l10n = appL10nOf(context);
    _flushPendingGenerationTextHistory();

    switch (preset.kind) {
      case AppPresetKind.localGeneration:
        final before = _captureLocalGenerationPresetSnapshot();
        final after = _LocalGenerationPresetSnapshot(
          prompt: preset.prompt,
          negativePrompt: preset.negativePrompt,
          size: safeImageSizeForModel(
            size: preset.size,
            providerKind: _apiConfigProviderKind,
            model: _modelController.text,
            capabilityOverride: _imageSizeCapabilityOverride,
          ),
          imageCount: normalizeImageGenerationTargetCount(preset.imageCount),
          advancedSettings: preset.advancedSettings,
        );
        await _restoreLocalGenerationPresetSnapshot(after);
        _pushPresetHistory<_LocalGenerationPresetSnapshot>(
          label: l10n.localSettingsStateApplyPresetHistory(preset.name),
          before: before,
          after: after,
          restore: _restoreLocalGenerationPresetSnapshot,
        );
      case AppPresetKind.spriteSheet:
        final before = _captureSpriteSheetPresetSnapshot();
        final after = _SpriteSheetPresetSnapshot(
          prompt: preset.prompt,
          negativePrompt: preset.negativePrompt,
          size: safeImageSizeForModel(
            size: preset.size,
            providerKind: _apiConfigProviderKind,
            model: _modelController.text,
            capabilityOverride: _imageSizeCapabilityOverride,
          ),
          spriteSheetImportConfig: SpriteSheetImportConfig(
            rows: preset.rows,
            columns: preset.columns,
            gridSpec:
                preset.gridSpec ??
                before.spriteSheetImportConfig.gridSpec.copyWith(
                  rows: preset.rows,
                  columns: preset.columns,
                ),
          ),
          advancedSettings: preset.advancedSettings,
        );
        await _restoreSpriteSheetPresetSnapshot(after);
        _pushPresetHistory<_SpriteSheetPresetSnapshot>(
          label: l10n.localSettingsStateApplyPresetHistory(preset.name),
          before: before,
          after: after,
          restore: _restoreSpriteSheetPresetSnapshot,
        );
      case AppPresetKind.gif:
        final before = _captureGifPresetSnapshot();
        final after = _GifPresetSnapshot(
          delayMs: preset.gifDelayMs,
          loopCount: preset.gifLoopCount,
          playbackMode: preset.playbackMode,
        );
        await _restoreGifPresetSnapshot(after);
        _pushPresetHistory<_GifPresetSnapshot>(
          label: l10n.localSettingsStateApplyPresetHistory(preset.name),
          before: before,
          after: after,
          restore: _restoreGifPresetSnapshot,
        );
    }
    _showMessage(l10n.localSettingsStatePresetApplied(preset.name));
  }

  _LocalGenerationPresetSnapshot _captureLocalGenerationPresetSnapshot() {
    return _LocalGenerationPresetSnapshot(
      prompt: _promptController.text,
      negativePrompt: _negativePromptController.text,
      size: _size,
      imageCount: _imageCount,
      advancedSettings: _advancedSettings,
    );
  }

  _SpriteSheetPresetSnapshot _captureSpriteSheetPresetSnapshot() {
    return _SpriteSheetPresetSnapshot(
      prompt: _animationPromptController.text,
      negativePrompt: _negativePromptController.text,
      size: _size,
      spriteSheetImportConfig: _spriteSheetImportConfig,
      advancedSettings: _advancedSettings,
    );
  }

  _GifPresetSnapshot _captureGifPresetSnapshot() {
    return _GifPresetSnapshot(
      delayMs: _gifDefaultFrameDelayMs,
      loopCount: _gifLoopCount,
      playbackMode: _gifPlaybackMode,
    );
  }

  void _pushPresetHistory<T>({
    required String label,
    required T before,
    required T after,
    required FutureOr<void> Function(T value) restore,
  }) {
    if (before == after) {
      return;
    }

    _pushHistory(
      WorkspaceFeature.localSettings,
      HistoryAction(
        label: label,
        apply: () => restore(after),
        revert: () => restore(before),
      ),
    );
  }

  Future<void> _restoreLocalGenerationPresetSnapshot(
    _LocalGenerationPresetSnapshot snapshot,
  ) async {
    if (!mounted) {
      return;
    }

    _isRestoringState = true;
    try {
      setState(() {
        _setControllerText(
          controller: _promptController,
          value: snapshot.prompt,
          remember: (value) => _lastPromptText = value,
        );
        _setControllerText(
          controller: _negativePromptController,
          value: snapshot.negativePrompt,
          remember: (value) => _lastNegativePromptText = value,
        );
        _size = safeImageSizeForModel(
          size: snapshot.size,
          providerKind: _apiConfigProviderKind,
          model: _modelController.text,
          capabilityOverride: _imageSizeCapabilityOverride,
        );
        _imageCount = normalizeImageGenerationTargetCount(snapshot.imageCount);
        _advancedSettings = snapshot.advancedSettings;
        if (_userController.text != snapshot.advancedSettings.user) {
          _userController.text = snapshot.advancedSettings.user;
        }
      });
    } finally {
      _isRestoringState = false;
    }
    await _saveSettings();
  }

  Future<void> _restoreSpriteSheetPresetSnapshot(
    _SpriteSheetPresetSnapshot snapshot,
  ) async {
    if (!mounted) {
      return;
    }

    _isRestoringState = true;
    try {
      setState(() {
        _setControllerText(
          controller: _animationPromptController,
          value: snapshot.prompt,
          remember: (value) => _lastAnimationPromptText = value,
        );
        _setControllerText(
          controller: _negativePromptController,
          value: snapshot.negativePrompt,
          remember: (value) => _lastNegativePromptText = value,
        );
        _size = safeImageSizeForModel(
          size: snapshot.size,
          providerKind: _apiConfigProviderKind,
          model: _modelController.text,
          capabilityOverride: _imageSizeCapabilityOverride,
        );
        _spriteSheetImportConfig = snapshot.spriteSheetImportConfig;
        _advancedSettings = snapshot.advancedSettings;
        if (_userController.text != snapshot.advancedSettings.user) {
          _userController.text = snapshot.advancedSettings.user;
        }
      });
    } finally {
      _isRestoringState = false;
    }
    await _saveSettings();
  }

  Future<void> _restoreGifPresetSnapshot(_GifPresetSnapshot snapshot) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _gifDefaultFrameDelayMs = snapshot.delayMs;
      _gifLoopCount = snapshot.loopCount;
      _gifPlaybackMode = snapshot.playbackMode;
    });
  }

  void _setControllerText({
    required TextEditingController controller,
    required String value,
    required ValueChanged<String> remember,
  }) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    remember(value);
  }

  Future<void> _deletePreset(AppPreset preset) async {
    await _store.deletePreset(preset.id);
    final presets = await _store.loadPresets();
    if (!mounted) {
      return;
    }
    setState(() => _appPresets = presets);
    _showMessage(
      appL10nOf(context).localSettingsStatePresetDeleted(preset.name),
    );
  }

  Future<void> _cleanupLocalStorage() async {
    final l10n = appL10nOf(context);
    if (_isCleaningStorage) {
      return;
    }

    setState(() => _isCleaningStorage = true);
    try {
      final summary = await _store.cleanupGeneratedFiles(
        libraryItems: _imageLibrary,
      );
      if (!mounted) {
        return;
      }
      _showMessage(
        l10n.localSettingsStateCleanupDone(
          summary.removedFiles,
          formatBytes(summary.freedBytes),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.localSettingsStateCleanupFailed(error));
    } finally {
      if (mounted) {
        setState(() => _isCleaningStorage = false);
      }
    }
  }

  Future<void> _exportImageLibraryArchive() async {
    final l10n = appL10nOf(context);
    if (_isExportingLibrary) {
      return;
    }

    final location = await getSaveLocation(
      acceptedTypeGroups: imageLibraryArchiveTypeGroups,
      suggestedName: ImageLibraryArchiveService.suggestedArchiveName(),
    );
    if (location == null || !mounted) {
      return;
    }

    setState(() => _isExportingLibrary = true);
    try {
      final result = await const ImageLibraryArchiveService().exportArchive(
        items: _imageLibrary,
        outputPath: location.path,
      );
      if (!mounted) {
        return;
      }
      final skipped = result.skippedMissingCount == 0
          ? ''
          : l10n.imageLibraryStateSkippedMissingFiles(
              result.skippedMissingCount,
            );
      _showMessage(
        l10n.localSettingsStateLibraryArchiveExported(
          result.exportedCount,
          skipped,
          fileNameFromPath(result.path),
        ),
      );
    } on ImageLibraryArchiveException catch (error) {
      if (!mounted) return;
      _showMessage(l10n.localSettingsStateExportLibraryFailed(error.message));
    } catch (error) {
      if (!mounted) return;
      _showMessage(l10n.localSettingsStateExportLibraryFailed(error));
    } finally {
      if (mounted) {
        setState(() => _isExportingLibrary = false);
      }
    }
  }

  Future<void> _importImageLibraryArchive() async {
    final l10n = appL10nOf(context);
    if (_isImportingLibrary) {
      return;
    }

    final archive = await openFile(
      acceptedTypeGroups: imageLibraryArchiveTypeGroups,
    );
    if (archive == null || !mounted) {
      return;
    }

    setState(() => _isImportingLibrary = true);
    try {
      final result = await const ImageLibraryArchiveService().importArchive(
        store: _store,
        archivePath: archive.path,
      );
      if (!mounted) {
        return;
      }

      final nextLibrary = [...result.importedItems, ..._imageLibrary];
      await _store.saveImageLibrary(nextLibrary);
      if (!mounted) {
        return;
      }
      _imageLibrary = nextLibrary;
      _pushHistory(
        WorkspaceFeature.localSettings,
        HistoryAction(
          label: l10n.localSettingsStateImportLibraryHistory,
          apply: () async {
            final importedIds = {
              for (final item in result.importedItems) item.id,
            };
            final merged = [
              ...result.importedItems,
              for (final item in _imageLibrary)
                if (!importedIds.contains(item.id)) item,
            ];
            await _store.saveImageLibrary(merged);
            if (mounted) {
              _imageLibrary = merged;
            }
          },
          revert: () async {
            final importedIds = {
              for (final item in result.importedItems) item.id,
            };
            final remaining = [
              for (final item in _imageLibrary)
                if (!importedIds.contains(item.id)) item,
            ];
            await _store.saveImageLibrary(remaining);
            if (mounted) {
              _imageLibrary = remaining;
            }
          },
        ),
      );
      final skipped = result.skippedItems == 0
          ? ''
          : l10n.localSettingsStateSkippedInvalidItems(result.skippedItems);
      _showMessage(
        l10n.localSettingsStateLibraryArchiveImported(
          result.importedCount,
          skipped,
        ),
      );
    } on ImageLibraryArchiveException catch (error) {
      if (!mounted) return;
      _showMessage(l10n.localSettingsStateImportLibraryFailed(error.message));
    } catch (error) {
      if (!mounted) return;
      _showMessage(l10n.localSettingsStateImportLibraryFailed(error));
    } finally {
      if (mounted) {
        setState(() => _isImportingLibrary = false);
      }
    }
  }

  Widget _buildLocalSettingsWorkspace() {
    return LocalSettingsWorkspace(
      historyControls: _buildCompactHistoryControls(),
      apiConfigCount: _apiConfigs.length,
      imageLibraryCount: _imageLibrary.length,
      generatedPreviewCount: _generatedImages.length + _animationFrames.length,
      isCleaningStorage: _isCleaningStorage,
      isExportingLibrary: _isExportingLibrary,
      isImportingLibrary: _isImportingLibrary,
      providerKind: _apiConfigProviderKind,
      model: _modelController.text,
      imageSizeCapabilityOverride: _imageSizeCapabilityOverride,
      promptController: _promptController,
      negativePromptController: _negativePromptController,
      size: _size,
      imageCount: _imageCount,
      advancedSettings: _advancedSettings,
      presets: _appPresets,
      userController: _userController,
      onSizeChanged: _setSize,
      onImageCountChanged: _setImageCount,
      onAdvancedSettingsChanged: _setAdvancedSettings,
      onSavePreset: (kind) => unawaited(_savePreset(kind)),
      onApplyPreset: (preset) => unawaited(_applyPreset(preset)),
      onDeletePreset: (preset) => unawaited(_deletePreset(preset)),
      onOpenApiSettings: () =>
          unawaited(_selectFeature(WorkspaceFeature.apiSettings)),
      onExportLibrary: () => unawaited(_exportImageLibraryArchive()),
      onImportLibrary: () => unawaited(_importImageLibraryArchive()),
      onCleanupStorage: () => unawaited(_cleanupLocalStorage()),
      onResetToDefaults: () => unawaited(_confirmResetToDefaults()),
    );
  }
}
