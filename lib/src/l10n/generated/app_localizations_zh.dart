// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'FeatherCanvas Studio';

  @override
  String get navImageGeneration => '文本生图';

  @override
  String get navBatchGeneration => '批量生成';

  @override
  String get navAnimationProject => '动画工程';

  @override
  String get navImageEditor => '图片编辑器';

  @override
  String get navPixelArtEditor => '像素画编辑';

  @override
  String get navGifComposer => 'GIF 合成';

  @override
  String get navImageLibrary => '作品库';

  @override
  String get navApiSettings => '接口配置';

  @override
  String get navLocalSettings => '设置';

  @override
  String get navExpandSidebar => '展开侧栏';

  @override
  String get navCollapseSidebar => '收起侧栏';

  @override
  String get navGroupGenerate => '生成';

  @override
  String get navGroupEdit => '编辑';

  @override
  String get navGroupAssets => '资产';

  @override
  String get navSettingsMenu => '设置菜单';

  @override
  String get appearanceSectionTitle => '外观';

  @override
  String get appearanceSectionDescription => '选择应用主题。深色模式适合长时间编辑作业。';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get displayLabelAuto => '自动';

  @override
  String get displayLabelLow => '低';

  @override
  String get displayLabelMedium => '中';

  @override
  String get displayLabelHigh => '高';

  @override
  String get displayLabelStandard => '标准';

  @override
  String get displayLabelHd => '高清';

  @override
  String get displayLabelTransparent => '透明';

  @override
  String get displayLabelOpaque => '不透明';

  @override
  String get historyUndo => '撤销';

  @override
  String get historyRedo => '重做';

  @override
  String get historyUndoUnavailable => '暂无可撤销操作';

  @override
  String get historyRedoUnavailable => '暂无可重做操作';

  @override
  String get historyMenuTitle => '历史记录';

  @override
  String get historyMenuEmpty => '暂无历史';

  @override
  String get historyApplying => '历史操作执行中';

  @override
  String get historyUndoTo => '撤销到';

  @override
  String get historyRedoTo => '重做到';

  @override
  String get historyNextStep => '下一步';

  @override
  String historyStepCount(int count) {
    return '$count 步';
  }

  @override
  String historyUndoSuccess(Object label) {
    return '已撤销：$label';
  }

  @override
  String historyUndoMultiple(int completed, Object label) {
    return '已撤销 $completed 步：$label';
  }

  @override
  String historyUndoFailed(Object error) {
    return '撤销失败：$error';
  }

  @override
  String historyRedoSuccess(Object label) {
    return '已重做：$label';
  }

  @override
  String historyRedoMultiple(int completed, Object label) {
    return '已重做 $completed 步：$label';
  }

  @override
  String historyRedoFailed(Object error) {
    return '重做失败：$error';
  }

  @override
  String get splitHandleTooltip => '拖动调整宽度，双击复位';

  @override
  String get shortcutsSectionTitle => '快捷键';

  @override
  String get shortcutsSectionDescription => '全局快捷键在所有工作区可用，用于撤销和重做最近一次操作。';

  @override
  String get shortcutLabelUndo => '撤销';

  @override
  String get shortcutLabelRedo => '重做';

  @override
  String get shortcutLabelRedoAlt => '重做（备选）';

  @override
  String get localSettingsWorkspaceTitle => '本地设置';

  @override
  String get localSettingsWorkspaceDescription => '管理本机保存的默认生成参数、接口配置入口和恢复默认操作';

  @override
  String get localSettingsStatusSectionTitle => '本地状态';

  @override
  String get localSettingsStatusApiConfigs => '接口配置';

  @override
  String get localSettingsStatusLibraryItems => '作品库记录';

  @override
  String get localSettingsStatusPreviewImages => '当前预览结果';

  @override
  String countApiConfigs(int count) {
    return '$count 个';
  }

  @override
  String countLibraryItems(int count) {
    return '$count 条';
  }

  @override
  String countImages(int count) {
    return '$count 张';
  }

  @override
  String get localSettingsDefaultsSectionTitle => '默认生成设置';

  @override
  String get localSettingsDefaultsSectionDescription =>
      '这些值会保存在本机，并作为文本生图、动画工程等工作区的默认表单状态。';

  @override
  String get localSettingsDefaultPromptLabel => '默认正向提示词';

  @override
  String get localSettingsDefaultPromptHint => '新会话或恢复默认后使用的正向提示词';

  @override
  String get localSettingsDefaultNegativePromptLabel => '默认排除描述（可选）';

  @override
  String get localSettingsDefaultNegativePromptHint =>
      '仅在需要默认避免特定内容时填写，会合并进 prompt';

  @override
  String get localSettingsDefaultImageCountLabel => '默认生成数量';

  @override
  String get imageCountSuffix => '张';

  @override
  String localSettingsDefaultImageCountHelper(int maxCount) {
    return '超过 $maxCount 张会自动拆成多次请求';
  }

  @override
  String get localSettingsPresetSectionTitle => '常用预设';

  @override
  String get localSettingsSaveTextPreset => '保存文本预设';

  @override
  String get localSettingsSaveAnimationPreset => '保存动画工程预设';

  @override
  String get localSettingsSaveGifPreset => '保存 GIF 预设';

  @override
  String get applyPreset => '应用';

  @override
  String applyPresetAction(Object name) {
    return '应用预设：$name';
  }

  @override
  String get deletePresetTooltip => '删除预设';

  @override
  String deletePresetAction(Object name) {
    return '删除预设：$name';
  }

  @override
  String localGenerationPresetSummary(Object size, int imageCount) {
    return '$size · $imageCount 张';
  }

  @override
  String spriteSheetPresetSummary(Object size, int rows, int columns) {
    return '$size · $rows x $columns';
  }

  @override
  String get gifLoopInfinite => '无限循环';

  @override
  String gifLoopCount(int count) {
    return '播放 $count 次';
  }

  @override
  String gifPresetSummary(int delayMs, Object loopLabel) {
    return '$delayMs ms · $loopLabel';
  }

  @override
  String get localSettingsLibraryMigrationSectionTitle => '作品库迁移';

  @override
  String get localSettingsLibraryMigrationSectionDescription =>
      '把作品库元数据和本地图片打包为 ZIP，或从 ZIP 导入到当前作品库。';

  @override
  String get localSettingsExportingLibrary => '导出中';

  @override
  String get localSettingsExportLibrary => '导出作品库';

  @override
  String get localSettingsLibraryExportBusyUnavailable => '作品库正在导出，完成后可继续操作';

  @override
  String get localSettingsLibraryExportEmptyUnavailable => '作品库为空，暂无可导出的内容';

  @override
  String get localSettingsImportingLibrary => '导入中';

  @override
  String get localSettingsImportLibrary => '导入作品库';

  @override
  String get localSettingsLibraryImportBusyUnavailable => '作品库正在导入，完成后可继续操作';

  @override
  String get localSettingsConfigEntrySectionTitle => '配置入口';

  @override
  String get localSettingsConfigEntrySectionDescription =>
      '接口地址、密钥和模型列表统一在接口配置页维护。';

  @override
  String get localSettingsOpenApiSettings => '打开接口配置';

  @override
  String get localSettingsStorageCleanupSectionTitle => '存储清理';

  @override
  String get localSettingsStorageCleanupSectionDescription =>
      '清理作品库不再引用的生成文件，以及临时参考图缓存。不会删除作品库仍在使用的文件。';

  @override
  String get localSettingsCleaningStorage => '清理中';

  @override
  String get localSettingsCleanUnusedFiles => '清理未引用文件';

  @override
  String get localSettingsStorageCleanupBusyUnavailable => '正在清理存储，完成后可继续操作';

  @override
  String get localSettingsResetSectionTitle => '恢复默认';

  @override
  String get localSettingsResetSectionDescription => '仅在需要重新开始配置时使用。恢复前会再次确认。';

  @override
  String get localSettingsResetForm => '恢复默认表单';

  @override
  String get apiSettingsWorkspaceTitle => '接口配置';

  @override
  String get apiSettingsWorkspaceDescription =>
      '集中管理不同供应商的接口，其他功能页只需要选择这里保存的配置';

  @override
  String get apiConfigLabel => '接口配置';

  @override
  String get manageApiConfigTooltip => '管理接口配置';

  @override
  String get apiSettingsPanelTitle => '接口配置';

  @override
  String get apiSettingsAddConfigTooltip => '新增配置';

  @override
  String get apiSettingsDeleteConfigTooltip => '删除当前配置';

  @override
  String get apiSettingsDeleteConfigUnavailable => '至少需要保留一个接口配置';

  @override
  String get apiTimeoutLabel => '请求超时（秒）';

  @override
  String apiTimeoutHelper(int defaultSeconds, int minSeconds, int maxSeconds) {
    return '默认 $defaultSeconds 秒，范围 $minSeconds–$maxSeconds；image-2 等慢模型可调大';
  }

  @override
  String get apiConfigNameLabel => '接口名称';

  @override
  String get apiConfigNameHint => '例如 OpenAI 官方、内网代理、备用接口';

  @override
  String get apiConfigSwitchTooltip => '切换接口配置';

  @override
  String get apiProviderLabel => '供应商';

  @override
  String get apiProviderOfficial => 'OpenAI 官方';

  @override
  String get apiProviderCompatible => 'OpenAI 兼容';

  @override
  String get apiProviderOfficialDescription =>
      '发送完整 GPT Image 参数（quality/background/output_format 等）';

  @override
  String get apiProviderCompatibleDescription =>
      '只发送 model/prompt/size/n，避免兼容层 502';

  @override
  String get apiProviderGeminiDescription =>
      '使用 Gemini generateContent 协议，支持文本生图和带参考图编辑';

  @override
  String get apiSaving => '保存中';

  @override
  String get apiSaveConfig => '保存配置';

  @override
  String get apiTesting => '测试中';

  @override
  String get apiTestConfig => '测试接口';

  @override
  String get apiBasicTestTooltip => '只发送 model/prompt/size/n，先确认接口本身可用';

  @override
  String get apiBasicTest => '基础测试';

  @override
  String get apiTestApiKeyRequired => '请先填写 API Key';

  @override
  String get apiBasicTestSuccess => '基础测试通过：接口可用，可尝试切换到完整测试验证高级参数';

  @override
  String get apiTestSuccess => '接口测试成功，已收到图片数据';

  @override
  String get apiBasicTestFailed => '基础测试失败';

  @override
  String get apiTestFailed => '接口测试失败';

  @override
  String get apiOfficialCompatibilityHint =>
      '提示：当前为「OpenAI 官方」档位，反代/兼容层可能不支持 input_fidelity、output_compression、moderation 等参数，可切换到「OpenAI 兼容」档位再试';

  @override
  String get apiTestTimeout => '接口测试超时，请检查反代或网络';

  @override
  String apiTestFailedWithError(Object error) {
    return '接口测试失败：$error';
  }

  @override
  String get apiSaveStatusSaved => '已保存';

  @override
  String get apiSaveStatusPending => '未保存';

  @override
  String get apiSaveStatusSaving => '保存中';

  @override
  String get apiSaveStatusFailed => '保存失败';

  @override
  String get unknownError => '未知错误';

  @override
  String apiSaveFailedTooltip(Object message) {
    return '保存失败：$message';
  }

  @override
  String get apiImageSizeCapabilityLabel => '生图尺寸能力';

  @override
  String apiImageSizeCapabilityAuto(Object capability) {
    return '自动识别：$capability。';
  }

  @override
  String apiImageSizeCapabilityDescription(
    Object capability,
    Object description,
  ) {
    return '$capability：$description';
  }

  @override
  String get apiRefreshModelList => '刷新模型列表';

  @override
  String get apiFetchModelList => '获取模型列表';

  @override
  String get apiHideKey => '隐藏密钥';

  @override
  String get apiShowKey => '显示密钥';

  @override
  String get apiModelLabel => '模型';

  @override
  String get apiModelManualHint => '先获取模型列表，或手动填写模型名称';

  @override
  String get apiModelFetchApiKeyRequired => '请先填写 API Key 再拉取模型列表';

  @override
  String get apiModelFetchTimeout => '获取模型列表超时，请检查反代或网络';

  @override
  String get apiModelFetchEmpty => '接口没有返回可用模型，仍可手动填写模型名称';

  @override
  String apiModelFetchFailedWithError(Object error) {
    return '获取模型列表失败：$error';
  }

  @override
  String apiModelFetchSelected(int count, Object modelId) {
    return '已获取 $count 个模型，并选择 $modelId';
  }

  @override
  String apiModelFetchSuccess(int count) {
    return '已获取 $count 个模型，可从列表中选择';
  }

  @override
  String get apiModelPickerTooltip => '从已获取列表选择模型，或刷新列表';

  @override
  String apiModelRefreshingCached(int count) {
    return '正在刷新模型列表，当前显示 $count 个缓存模型';
  }

  @override
  String get apiModelRefreshingEmptyCache => '正在刷新模型列表，当前缓存为空';

  @override
  String get apiModelFetching => '正在获取模型列表...';

  @override
  String apiModelLastSuccess(Object time) {
    return '上次成功：$time';
  }

  @override
  String apiModelRefreshFailedUsingCache(int count) {
    return '刷新失败，继续显示 $count 个缓存模型';
  }

  @override
  String apiModelRefreshFailedUsingCacheWithTime(
    int count,
    Object lastSuccess,
  ) {
    return '刷新失败，继续显示 $count 个缓存模型，$lastSuccess';
  }

  @override
  String apiModelFetchedCount(int count) {
    return '已获取 $count 个模型';
  }

  @override
  String apiModelCachedCountWithTime(int count, Object lastSuccess) {
    return '已缓存 $count 个模型，$lastSuccess';
  }

  @override
  String get apiModelRefreshFailedEmptyCache => '模型列表刷新失败，当前缓存为空，可修正配置后重试';

  @override
  String apiModelRefreshFailedEmptyCacheWithTime(Object lastSuccess) {
    return '模型列表刷新失败，当前缓存为空，$lastSuccess';
  }

  @override
  String get apiModelFetchFailed => '模型列表获取失败，可修正配置后重试';

  @override
  String get apiModelNotFetched => '尚未获取模型列表';

  @override
  String get imageGenerationWorkspaceTitle => '文本生图';

  @override
  String get imageGenerationWorkspaceDescription => '选择已保存的接口配置，再填写提示词生成图片';

  @override
  String get generationConfigSectionTitle => '生成配置';

  @override
  String get positivePromptLabel => '正向提示词';

  @override
  String get positivePromptHint => '描述你想生成的图片';

  @override
  String get negativePromptLabel => '排除描述（可选）';

  @override
  String get negativePromptHint => '仅在需要避免特定内容时填写，少量明确描述即可';

  @override
  String get targetImageCountLabel => '目标数量';

  @override
  String get generateImageButton => '生成图片';

  @override
  String get generatingImageButton => '生成中';

  @override
  String get imageGenerationReferenceImageTitle => '参考图（图生图）';

  @override
  String get imageGenerationReferenceImagePickLabel => '选择参考图';

  @override
  String get imageGenerationAddReferenceImagesLabel => '添加参考图';

  @override
  String imageGenerationReferenceImageCountLabel(int count) {
    return '$count 张参考图';
  }

  @override
  String imageGenerationRemoveReferenceImageTooltip(Object fileName) {
    return '移除参考图：$fileName';
  }

  @override
  String get imageGenerationClearReferenceImagesTooltip => '清除全部参考图';

  @override
  String imageGenerationReferenceImagesLimitMessage(int max) {
    return '最多选择 $max 张参考图';
  }

  @override
  String get imageGenerationCompatibleMultiReferenceWarning =>
      '兼容接口将按多文件 image 字段发送参考图，实际是否支持取决于服务商。';

  @override
  String get imageGenerationGenerateWithReferenceButton => '图生图';

  @override
  String get imageGenerationGeneratingWithReferenceButton => '图生图中';

  @override
  String imageGenerationAdjustAnimationRowsHistory(int value) {
    return '调整序列帧行数为 $value 行';
  }

  @override
  String imageGenerationAdjustAnimationColumnsHistory(int value) {
    return '调整序列帧列数为 $value 列';
  }

  @override
  String get imageGenerationAdjustAnimationGridSpecHistory => '调整序列帧切片校准';

  @override
  String get imageGenerationMissingApiKeyMessage => '请先在接口配置页填写 API Key';

  @override
  String get imageGenerationMissingModelMessage => '请先在接口配置页获取模型列表并选择模型';

  @override
  String get imageGenerationMissingApiKeyError => '请先在接口配置页填写 API Key。';

  @override
  String get imageGenerationMissingModelError => '请先在接口配置页获取模型列表并选择模型。';

  @override
  String get imageGenerationMissingPositivePromptMessage => '请先填写正向提示词';

  @override
  String imageGenerationGenerateImagesHistory(int count) {
    return '生成 $count 张图片';
  }

  @override
  String imageGenerationImagesGeneratedMessage(int count) {
    return '图片生成完成，共 $count 张';
  }

  @override
  String imageGenerationReferenceImagesGeneratedMessage(int count) {
    return '图生图完成，共 $count 张';
  }

  @override
  String get imageGenerationRequestTimeoutMessage => '请求超时，请检查接口地址或稍后重试';

  @override
  String get imageGenerationFailedPrefix => '生成失败';

  @override
  String get imageGenerationImageCopiedMessage => '图片已复制到剪贴板';

  @override
  String get imageGenerationImagePathCopiedMessage => '当前平台暂不支持直接复制图片，已复制图片路径';

  @override
  String imageGenerationCopyImageFailedMessage(Object error) {
    return '复制图片失败：$error';
  }

  @override
  String imageGenerationImageExportedMessage(Object fileName) {
    return '图片已导出：$fileName';
  }

  @override
  String imageGenerationExportImageFailedMessage(Object error) {
    return '导出图片失败：$error';
  }

  @override
  String imageGenerationGeneratedResultTitle(int index) {
    return '生成结果 $index';
  }

  @override
  String get imageGenerationTextImageSource => '文本生图';

  @override
  String get imageGenerationReferenceImageSource => '图生图';

  @override
  String get imageGenerationSelectReferenceImageTitle => '选择图生图参考图';

  @override
  String get imageGenerationReferenceLibraryEmpty => '作品库没有可作为参考图的图片';

  @override
  String imageGenerationSelectedReferenceImageMessage(Object fileName) {
    return '已选择参考图：$fileName';
  }

  @override
  String imageGenerationSelectedReferenceImagesMessage(int count) {
    return '已选择 $count 张参考图';
  }

  @override
  String imageGenerationSelectedReferenceSliceMessage(Object label) {
    return '已选择参考切片：$label';
  }

  @override
  String imageGenerationTransparentBackgroundHistory(Object title) {
    return '背景转透明：$title';
  }

  @override
  String imageGenerationTransparentBackgroundSavedMessage(
    Object title,
    int count,
  ) {
    return '已生成透明背景图片：$title · 透明化 $count 个像素';
  }

  @override
  String get imageGenerationMissingAnimationPromptMessage => '请先填写动画描述';

  @override
  String get imageGenerationMissingAnimationPromptError => '请先填写动画描述。';

  @override
  String get imageGenerationInvalidAnimationGridMessage => '请先设置有效的行列数量';

  @override
  String get imageGenerationInvalidAnimationGridError => '请先设置有效的行列数量。';

  @override
  String get imageGenerationTemplateImageMissingMessage => '模板图片不存在，请重新选择';

  @override
  String get imageGenerationTemplateImageMissingError => '模板图片不存在，请重新选择。';

  @override
  String get imageGenerationGenerateSpriteSheetHistory => '生成 Sprite Sheet';

  @override
  String get imageGenerationSpriteSheetSource => '动画工程';

  @override
  String get imageGenerationSpriteSheetGeneratedImportingMessage =>
      'Sprite Sheet 已生成，正在导入动画工程';

  @override
  String get imageGenerationSpriteSheetFailedPrefix => 'Sprite Sheet 生成失败';

  @override
  String imageGenerationStackOverflowMessage(Object prefix) {
    return '$prefix：客户端发生 Stack Overflow，已写入调试详情。如果调试详情里没有 HTTP 状态码，说明请求没有拿到接口响应。';
  }

  @override
  String imageGenerationUnexpectedErrorMessage(Object prefix, Object error) {
    return '$prefix：$error';
  }

  @override
  String get imageGenerationImportSpriteSheetFirstMessage =>
      '请先生成 Sprite Sheet，再导入动画工程';

  @override
  String get imageGenerationImportSpriteSheetProjectHistory =>
      '导入 Sprite Sheet 为动画工程';

  @override
  String imageGenerationImportedAnimationProjectMessage(int count) {
    return '已导入动画工程：$count 条轨道';
  }

  @override
  String imageGenerationImportAnimationProjectFailedMessage(Object error) {
    return '导入动画工程失败：$error';
  }

  @override
  String get imageGenerationCloseAnimationProjectHistory => '关闭动画工程';

  @override
  String get imageGenerationSelectAnimationTrackHistory => '选择动画轨道';

  @override
  String get imageGenerationRenameAnimationTrackHistory => '重命名动画轨道';

  @override
  String get imageGenerationAdjustTrackFrameDelayHistory => '调整轨道帧时长';

  @override
  String get imageGenerationAdjustTrackPlaybackHistory => '调整轨道播放方式';

  @override
  String get imageGenerationAdjustProjectDefaultDelayHistory => '调整工程默认帧时长';

  @override
  String get imageGenerationAdjustProjectPlaybackHistory => '调整工程播放方式';

  @override
  String get imageGenerationAdjustProjectGifLoopHistory => '调整工程 GIF 循环次数';

  @override
  String get imageGenerationExportIncludeHiddenTracksHistory => '导出包含隐藏轨道';

  @override
  String get imageGenerationExportExcludeHiddenTracksHistory => '导出排除隐藏轨道';

  @override
  String get imageGenerationLocalSourceLabel => '本地';

  @override
  String get imageGenerationLibrarySourceLabel => '作品库';

  @override
  String get imageGenerationSelectLibrarySequenceTitle => '选择作品库图片序列';

  @override
  String get imageGenerationLibraryNoImportableImagesMessage => '作品库没有可导入的静态图片';

  @override
  String get imageGenerationImportImageSequenceProjectHistory => '导入图片序列为动画工程';

  @override
  String imageGenerationImportedImagesAsProjectMessage(
    int count,
    Object sourceLabel,
  ) {
    return '已导入 $count 张$sourceLabel图片为动画工程';
  }

  @override
  String imageGenerationImportedSequenceTrackName(int index) {
    return '导入序列 $index';
  }

  @override
  String get imageGenerationImportImageSequenceTrackHistory => '导入图片序列为轨道';

  @override
  String imageGenerationImportedImagesAsTrackMessage(
    int count,
    Object sourceLabel,
  ) {
    return '已导入 $count 张$sourceLabel图片为新轨道';
  }

  @override
  String imageGenerationImportImageSequenceFailedMessage(Object error) {
    return '导入图片序列失败：$error';
  }

  @override
  String get imageGenerationAddAnimationTrackHistory => '新建动画轨道';

  @override
  String get imageGenerationDuplicateAnimationTrackHistory => '复制动画轨道';

  @override
  String get imageGenerationDeleteAnimationTrackHistory => '删除动画轨道';

  @override
  String get imageGenerationMoveAnimationTrackHistory => '调整动画轨道顺序';

  @override
  String get imageGenerationShowAnimationTrackHistory => '显示动画轨道';

  @override
  String get imageGenerationHideAnimationTrackHistory => '隐藏动画轨道';

  @override
  String get imageGenerationLockAnimationTrackHistory => '锁定动画轨道';

  @override
  String get imageGenerationUnlockAnimationTrackHistory => '解锁动画轨道';

  @override
  String get imageGenerationMoveAnimationFrameHistory => '调整序列帧顺序';

  @override
  String get imageGenerationDuplicateAnimationFrameHistory => '复制序列帧';

  @override
  String get imageGenerationDeleteAnimationFrameHistory => '删除序列帧';

  @override
  String get imageGenerationAdjustFrameDelayHistory => '调整单帧时长';

  @override
  String get imageGenerationAdjustFrameTransformHistory => '调整单帧变换';

  @override
  String get imageGenerationRebindFrameAssetHistory => '重新绑定动画帧资源';

  @override
  String imageGenerationReboundFrameAssetMessage(Object fileName) {
    return '已重新绑定帧资源：$fileName';
  }

  @override
  String imageGenerationRebindFrameAssetFailedMessage(Object error) {
    return '重新绑定帧资源失败：$error';
  }

  @override
  String get imageGenerationReplaceAnimationFrameHistory => '替换动画帧';

  @override
  String imageGenerationReplacedAnimationFrameMessage(
    int index,
    Object fileName,
  ) {
    return '已替换第 $index 帧：$fileName';
  }

  @override
  String get imageGenerationReplaceAnimationFrameFailedPrefix => '替换动画帧失败';

  @override
  String get imageGenerationInsertBlankFrameHistory => '插入空白动画帧';

  @override
  String imageGenerationInsertedBlankFrameMessage(int index) {
    return '已在第 $index 帧插入空白帧';
  }

  @override
  String get imageGenerationInsertBlankFrameFailedPrefix => '插入空白动画帧失败';

  @override
  String get imageGenerationInsertImageFrameHistory => '插入图片动画帧';

  @override
  String imageGenerationInsertedImageFrameMessage(int index, Object fileName) {
    return '已在第 $index 帧插入图片帧：$fileName';
  }

  @override
  String get imageGenerationInsertImageFrameFailedPrefix => '插入图片动画帧失败';

  @override
  String get imageGenerationClearAnimationFrameHistory => '清空动画帧';

  @override
  String get imageGenerationClearAnimationFrameFailedPrefix => '清空动画帧失败';

  @override
  String get imageGenerationPixelateAnimationFrameHistory => '像素化动画帧';

  @override
  String imageGenerationPixelatedAnimationFrameMessage(
    int index,
    int blockSize,
  ) {
    return '已像素化第 $index 帧（$blockSize px）';
  }

  @override
  String get imageGenerationPixelateAnimationFrameFailedPrefix => '像素化动画帧失败';

  @override
  String get imageGenerationCurrentFrameNotEditableMessage =>
      '当前帧不能编辑，请确认轨道未锁定';

  @override
  String imageGenerationPrefixedErrorMessage(Object prefix, Object error) {
    return '$prefix：$error';
  }

  @override
  String get imageGenerationNoRepairableProjectIssuesMessage => '没有可自动修复的工程问题';

  @override
  String get imageGenerationRepairProjectConsistencyHistory => '自动修复动画工程一致性';

  @override
  String get imageGenerationRepairedProjectConsistencyMessage => '已自动修复工程一致性问题';

  @override
  String get imageGenerationPleaseImportAnimationProjectMessage => '请先导入动画工程';

  @override
  String get imageGenerationExportAnimationProjectSpriteSheetHistory =>
      '导出动画工程 Sprite Sheet';

  @override
  String imageGenerationExportedProjectSpriteSheetMessage(Object fileName) {
    return '动画工程 Sprite Sheet 已导出：$fileName';
  }

  @override
  String imageGenerationExportFailedMessage(Object error) {
    return '导出失败：$error';
  }

  @override
  String get imageGenerationExportAnimationProjectGifHistory => '导出动画工程 GIF';

  @override
  String imageGenerationExportedProjectGifMessage(Object fileName) {
    return '动画工程 GIF 已导出：$fileName';
  }

  @override
  String imageGenerationExportProjectGifFailedMessage(Object error) {
    return '导出工程 GIF 失败：$error';
  }

  @override
  String get imageGenerationPleaseSelectAnimationTrackMessage => '请先选择动画轨道';

  @override
  String get imageGenerationExportAnimationTrackGifHistory => '导出动画轨道 GIF';

  @override
  String imageGenerationExportedTrackGifMessage(Object fileName) {
    return '当前轨道 GIF 已导出：$fileName';
  }

  @override
  String imageGenerationExportedProjectPngSequenceMessage(int count) {
    return '已导出 $count 张工程合成 PNG 序列帧';
  }

  @override
  String imageGenerationExportProjectPngSequenceFailedMessage(Object error) {
    return '导出工程 PNG 序列失败：$error';
  }

  @override
  String imageGenerationExportedTrackPngSequenceMessage(int count) {
    return '已导出 $count 张 PNG 序列帧';
  }

  @override
  String imageGenerationExportPngSequenceFailedMessage(Object error) {
    return '导出 PNG 序列失败：$error';
  }

  @override
  String get batchGenerationWorkspaceTitle => '批量生成';

  @override
  String get batchGenerationWorkspaceDescription =>
      '把多条文本生图任务排队串行执行，成功结果会自动进入作品库。';

  @override
  String get batchQueueControlTitle => '队列控制';

  @override
  String get batchPromptLabel => '批量提示词';

  @override
  String get batchPromptHint => '每行一条提示词；每条会按目标数量自动拆分';

  @override
  String get batchNegativePromptHint => '可选，填写后会作为排除描述应用到每个批量任务';

  @override
  String get batchTargetCountHelper => '每条提示词最终想生成的总数';

  @override
  String get batchRequestCountLabel => '每批张数';

  @override
  String batchRequestCountHelper(int maxCount) {
    return '单次请求最多 $maxCount 张';
  }

  @override
  String batchSplitStatus(int batchCount) {
    return '当前会把每条提示词拆成 $batchCount 个串行任务';
  }

  @override
  String get batchAddPrompts => '按行拆分入队';

  @override
  String get batchStartQueue => '开始队列';

  @override
  String get batchContinueQueue => '继续队列';

  @override
  String get batchQueueRunning => '队列运行中';

  @override
  String get batchActionQueueBusyUnavailable => '队列运行中，当前不能执行此操作';

  @override
  String get batchActionNeedsQueuedJobs => '没有等待中的任务可执行';

  @override
  String get batchActionQueueNotRunning => '队列未运行';

  @override
  String get batchActionQueueAlreadyPausing => '已请求暂停后续任务';

  @override
  String get batchActionQueueNotPaused => '队列未暂停';

  @override
  String get batchPauseAfterCurrent => '暂停后续';

  @override
  String get batchResumeQueue => '继续后续';

  @override
  String get batchCancelQueued => '取消等待任务';

  @override
  String get batchRetryFailed => '重试失败任务';

  @override
  String batchRetryFailedCount(int count) {
    return '重试失败任务 ($count)';
  }

  @override
  String get batchClearFinished => '清理完成 / 失败 / 取消';

  @override
  String get batchActionNoFinishedJobs => '没有可清理的完成、失败或取消任务';

  @override
  String batchQueuePausingStatus(int runningCount) {
    return '已暂停后续任务。正在请求的 $runningCount 个任务会等接口返回或超时后停下，不会继续启动新的等待任务。';
  }

  @override
  String batchQueueRunningStatus(int runningCount, int queuedCount) {
    return '正在请求 $runningCount 个任务，后面还有 $queuedCount 个等待任务。暂停只会阻止下一批开始，不会中断已发出的 HTTP 请求。';
  }

  @override
  String batchQueueWaitingStatus(int queuedCount) {
    return '队列里有 $queuedCount 个等待任务，可继续执行或取消等待任务。';
  }

  @override
  String get batchQueueEmptyStatus => '没有等待中的任务。';

  @override
  String get batchJobListTitle => '任务队列';

  @override
  String get batchJobListEmpty => '还没有任务。把提示词加入队列后，会按目标数量拆分并串行生成。';

  @override
  String batchJobCount(int count) {
    return '$count 个任务';
  }

  @override
  String batchJobBatchPrefix(int batchIndex, int batchTotal) {
    return '第 $batchIndex/$batchTotal 批 · ';
  }

  @override
  String batchJobRetrySuffix(int retryAttempt, int maxAttempts) {
    return ' · 重试 $retryAttempt/$maxAttempts';
  }

  @override
  String batchJobSummary(
    Object status,
    Object batchLabel,
    Object size,
    int imageCount,
    Object apiConfigName,
    Object retryLabel,
  ) {
    return '$status · $batchLabel$size · $imageCount 张 · $apiConfigName$retryLabel';
  }

  @override
  String get batchRetryJobTooltip => '重试任务';

  @override
  String get batchRemoveJobTooltip => '移除任务';

  @override
  String get batchJobStatusQueued => '等待中';

  @override
  String get batchJobStatusRunning => '生成中';

  @override
  String get batchJobStatusSucceeded => '已完成';

  @override
  String get batchJobStatusFailed => '失败';

  @override
  String get batchJobStatusSkipped => '已取消';

  @override
  String get cancelAction => '取消';

  @override
  String get saveAction => '保存';

  @override
  String get retryAction => '重试';

  @override
  String get playAction => '播放';

  @override
  String get pauseAction => '暂停';

  @override
  String get closeAction => '关闭';

  @override
  String get copyAction => '复制';

  @override
  String get selectAction => '选择';

  @override
  String get replaceAction => '更换';

  @override
  String get confirmSelectionAction => '确认选择';

  @override
  String get confirmDeleteAction => '确认删除';

  @override
  String get imageLibraryWorkspaceTitle => '作品';

  @override
  String get imageLibraryWorkspaceDescription =>
      '集中保存生成、切片、编辑和合成后的图片，其他功能可以直接复用';

  @override
  String get imageLibraryPanelTitle => '应用内作品';

  @override
  String imageLibraryTotalCount(int count) {
    return '$count 个作品';
  }

  @override
  String imageLibraryFilteredCount(int visibleCount, int totalCount) {
    return '$visibleCount / $totalCount';
  }

  @override
  String get imageLibrarySearchLabel => '搜索作品';

  @override
  String get imageLibraryClearSearchTooltip => '清空搜索';

  @override
  String get imageLibraryProjectLabel => '项目';

  @override
  String get imageLibraryAllProjects => '全部项目';

  @override
  String get imageLibraryTagLabel => '标签';

  @override
  String get imageLibraryAllTags => '全部标签';

  @override
  String get imageLibrarySortLabel => '排序';

  @override
  String get imageLibrarySelectVisible => '选择当前结果';

  @override
  String get imageLibrarySelectVisibleEmptyUnavailable => '当前没有可选择的作品';

  @override
  String get imageLibrarySelectVisibleAllSelectedUnavailable => '当前结果已全部选中';

  @override
  String imageLibraryExpandSlices(int count) {
    return '展开切片 ($count)';
  }

  @override
  String imageLibrarySelectedCount(int count) {
    return '已选 $count';
  }

  @override
  String get imageLibraryExportSelected => '导出已选';

  @override
  String get imageLibraryDeleteSelected => '删除已选';

  @override
  String get imageLibraryTileKeyboardHint => '按空格切换选择，按回车打开主要操作';

  @override
  String get imageLibraryEmptyAll => '暂无作品。生成、导出、编辑或合成后的图片会保存到这里。';

  @override
  String get imageLibraryEmptyFiltered => '当前条件下没有作品。';

  @override
  String get imageLibraryPageEmptyRange => '0 / 0';

  @override
  String imageLibraryPageRange(int startIndex, int endIndex, int totalCount) {
    return '$startIndex-$endIndex / $totalCount';
  }

  @override
  String imageLibraryPageStatus(
    int pageIndex,
    int pageCount,
    Object rangeLabel,
  ) {
    return '第 $pageIndex / $pageCount 页 · $rangeLabel';
  }

  @override
  String imageLibraryPaginationSemanticLabel(Object statusLabel, int pageSize) {
    return '作品库分页控制 · $statusLabel · 每页 $pageSize 个';
  }

  @override
  String get imageLibraryFirstPageTooltip => '第一页';

  @override
  String get imageLibraryPreviousPageTooltip => '上一页';

  @override
  String get imageLibraryNextPageTooltip => '下一页';

  @override
  String get imageLibraryLastPageTooltip => '最后一页';

  @override
  String get imageLibraryPageSizePrefix => '每页';

  @override
  String get imageLibraryPageSizeSuffix => '个';

  @override
  String get imageLibraryFilterAll => '全部';

  @override
  String get imageLibraryFilterGenerated => '生图';

  @override
  String get imageLibraryFilterSprite => '切片 / 帧';

  @override
  String get imageLibraryFilterEdited => '编辑';

  @override
  String get imageLibraryFilterAnimation => '动画';

  @override
  String get imageLibraryFilterGif => 'GIF';

  @override
  String get imageLibrarySortNewest => '最新优先';

  @override
  String get imageLibrarySortOldest => '最旧优先';

  @override
  String get imageLibrarySortTitleAsc => '标题 A-Z';

  @override
  String imageLibrarySavedFramesBadge(int savedCount, int totalCount) {
    return '$savedCount/$totalCount 帧';
  }

  @override
  String get imageLibraryActionSlices => '切片';

  @override
  String get imageLibraryActionOpen => '打开';

  @override
  String get imageLibraryActionReuse => '复用';

  @override
  String get imageLibraryActionEdit => '编辑';

  @override
  String get imageLibraryEditMetadataTooltip => '编辑作品信息';

  @override
  String get imageLibraryMoreActionsTooltip => '更多操作';

  @override
  String get imageLibraryMenuOpenAnimation => '打开动画工程';

  @override
  String get imageLibraryMenuOpenInEditor => '在编辑器中打开';

  @override
  String get imageLibraryMenuReuseGeneration => '复用生成参数';

  @override
  String get imageLibraryMenuCopyGeneration => '复制生成参数';

  @override
  String get imageLibraryMenuTransparentBg => '背景转透明';

  @override
  String get imageLibraryMenuCopyImage => '复制图片';

  @override
  String get imageLibraryMenuExportImage => '导出图片';

  @override
  String get imageLibraryMenuExportFile => '导出文件';

  @override
  String get imageLibraryMenuCopyPath => '复制路径';

  @override
  String get imageLibraryMenuOpenLocation => '打开位置';

  @override
  String get imageLibraryMenuDelete => '删除作品';

  @override
  String get imageAssetKindGenerated => '生图';

  @override
  String get imageAssetKindSpriteSheet => '切片';

  @override
  String get imageAssetKindSpriteFrame => '帧图';

  @override
  String get imageAssetKindEdited => '编辑';

  @override
  String get imageAssetKindAnimationProject => '动画';

  @override
  String get imageAssetKindGif => 'GIF';

  @override
  String imageLibraryPickerSelectCount(int count) {
    return '选择 $count 张';
  }

  @override
  String imageLibraryPickerItemSemanticLabel(
    Object kind,
    Object title,
    int index,
    int total,
  ) {
    return '$kind · $title · 第 $index / $total 项';
  }

  @override
  String get imageLibrarySliceMissingGridMetadata => '该 Sprite Sheet 缺少行列元数据。';

  @override
  String imageLibrarySliceLoadFailed(Object error) {
    return '加载切片失败：$error';
  }

  @override
  String imageLibrarySliceExplorerTitle(Object title) {
    return '切片管理 · $title';
  }

  @override
  String imageLibrarySliceSavedStatus(int savedCount, int totalCount) {
    return '已保存 $savedCount / $totalCount';
  }

  @override
  String get imageLibrarySliceSavedBadge => '已保存';

  @override
  String get imageLibrarySliceUnsavedStatus => '未保存';

  @override
  String imageLibrarySliceExplorerFrameSemanticLabel(
    int index,
    int total,
    Object status,
  ) {
    return '切片帧 $index / $total · $status';
  }

  @override
  String get imageLibrarySliceSaveOneTooltip => '保存这一帧';

  @override
  String get imageLibrarySliceAllSaved => '已全部保存';

  @override
  String imageLibrarySliceSaveAll(int count) {
    return '全部保存为切片 ($count)';
  }

  @override
  String get imageLibrarySlicePickerMultiTitle => '挑选切片帧';

  @override
  String get imageLibrarySlicePickerSingleTitle => '挑选一帧作为来源';

  @override
  String imageLibrarySlicePickerTitle(Object title, Object sheetTitle) {
    return '$title · $sheetTitle';
  }

  @override
  String imageLibrarySlicePickerSelectedStatus(
    int selectedCount,
    int totalCount,
  ) {
    return '已选 $selectedCount / $totalCount';
  }

  @override
  String get imageLibrarySlicePickerNotSelected => '尚未选择';

  @override
  String imageLibrarySlicePickerSelectedOne(int index) {
    return '已选 #$index';
  }

  @override
  String imageLibrarySlicePickerConfirmCount(int count) {
    return '确认选择 ($count)';
  }

  @override
  String imageLibrarySliceFrameSemanticLabel(int index, int total) {
    return '切片帧 $index / $total';
  }

  @override
  String get pickSourceLocalFileTitle => '从本地文件选择';

  @override
  String get pickSourceLocalFileSubtitle => '打开电脑文件选择窗口';

  @override
  String get pickSourceImageLibraryTitle => '从作品库选择';

  @override
  String get pickSourceImageLibrarySubtitle => '直接使用已保存到作品库的图片';

  @override
  String get pickSourceImageLibraryEmpty => '作品库还没有可用图片';

  @override
  String get imageLibraryEditMetadataTitle => '编辑作品信息';

  @override
  String get imageLibraryMetadataTitleLabel => '标题';

  @override
  String get imageLibraryMetadataNoteLabel => '备注';

  @override
  String get imageLibraryMetadataNoteHint => '记录用途、版本或修改说明';

  @override
  String get imageLibraryMetadataProjectHint => '例如：角色 A、Demo 游戏、UI 图标集';

  @override
  String get imageLibraryMetadataTagsHint => '用逗号分隔，例如：idle, run, pixel';

  @override
  String imageLibraryDeleteCascade(int count) {
    return '同时会移除 $count 个关联的切片帧。';
  }

  @override
  String imageLibraryDeleteBatchTitle(int count) {
    return '删除 $count 个作品';
  }

  @override
  String get imageLibraryDeleteOneTitle => '删除作品';

  @override
  String imageLibraryDeleteBatchMessage(Object cascadeText) {
    return '将从作品库移除这些作品，并删除应用缓存中的对应文件。$cascadeText\n此操作不可撤销。';
  }

  @override
  String imageLibraryDeleteOneMessage(Object title, Object cascadeText) {
    return '将从作品库移除「$title」，并删除应用缓存中的对应文件。$cascadeText\n此操作不可撤销。';
  }

  @override
  String get pixelArtWorkspaceDescription => '逐格绘制像素画，支持画笔、橡皮、取色和保存到作品库';

  @override
  String get pixelArtEnterFocusTooltip => '进入全屏编辑';

  @override
  String get pixelArtExitFocusTooltip => '退出全屏编辑';

  @override
  String get pixelArtToolsTitle => '像素画工具';

  @override
  String get pixelArtCanvasSizeTitle => '画布尺寸';

  @override
  String get pixelArtCanvasWidthLabel => '画布宽度';

  @override
  String get pixelArtCanvasHeightLabel => '画布高度';

  @override
  String get pixelArtApplyAfterChangeHelper => '修改后应用';

  @override
  String get pixelArtApplyCanvasSize => '应用画布尺寸';

  @override
  String get pixelArtBrushTool => '画笔';

  @override
  String get pixelArtEraserTool => '橡皮';

  @override
  String get pixelArtEyedropperTool => '取色';

  @override
  String get pixelArtBrushSizeLabel => '画笔大小';

  @override
  String get pixelArtCellSuffix => '格';

  @override
  String get pixelArtBrushSizeHelper => '按方形笔刷覆盖像素格';

  @override
  String get pixelArtColorTitle => '颜色';

  @override
  String get pixelArtZoomTitle => '缩放';

  @override
  String get pixelArtNewBlankCanvas => '新建空白';

  @override
  String get pixelArtClearCanvas => '清空';

  @override
  String get pixelArtSaveToLibrary => '保存到作品库';

  @override
  String get pixelArtSaving => '保存中';

  @override
  String get pixelArtExportPng => '导出 PNG';

  @override
  String get pixelArtExporting => '导出中';

  @override
  String get pixelArtCanvasTitle => '像素画画布';

  @override
  String pixelArtCanvasSemanticLabel(
    int width,
    int height,
    int cursorX,
    int cursorY,
  ) {
    return '像素画画布 · $width x $height · 当前键盘光标第 $cursorX 列第 $cursorY 行，方向键移动，空格或回车绘制';
  }

  @override
  String get homeResetDefaultsAction => '恢复默认表单';

  @override
  String get homeResetDefaultsMessage => '表单已重置，可用 Ctrl+Z 撤销';

  @override
  String get homePixelArtTitle => '像素画';

  @override
  String get homePixelArtSource => '像素画编辑';

  @override
  String homePixelArtPrompt(int width, int height) {
    return '像素画编辑 · $width x $height';
  }

  @override
  String get homePixelArtSaveAction => '保存像素画';

  @override
  String homePixelArtSavedMessage(Object fileName) {
    return '像素画已保存到作品库：$fileName';
  }

  @override
  String homePixelArtExportedMessage(Object fileName) {
    return '像素画已导出：$fileName';
  }

  @override
  String homePixelArtExportFailedMessage(Object error) {
    return '导出像素画失败：$error';
  }

  @override
  String homePixelArtSaveFailedMessage(Object error) {
    return '保存像素画失败：$error';
  }

  @override
  String get pixelArtChooseColorTooltip => '选择颜色';

  @override
  String get generalImageEditorTitle => '通用图片编辑';

  @override
  String get generalImageEditorSourceImageTitle => '待编辑图片';

  @override
  String get generalImageEditorReplaceAction => '更换';

  @override
  String get generalImageEditorClearImageTooltip => '清除图片';

  @override
  String get generalImageEditorQuickActionsTitle => '快捷处理';

  @override
  String get generalImageEditorQuickActionsSubtitle => '常用导出风格与版本快照';

  @override
  String get generalImageEditorGeometryTab => '几何';

  @override
  String get generalImageEditorAppearanceTab => '外观';

  @override
  String get generalImageEditorAnnotationTab => '标注';

  @override
  String get generalImageEditorOutputTab => '输出';

  @override
  String get generalImageEditorGeometryTitle => '几何调整';

  @override
  String get generalImageEditorGeometrySubtitle => '旋转、翻转、裁剪和输出尺寸';

  @override
  String get generalImageEditorAppearanceTitle => '外观处理';

  @override
  String get generalImageEditorAppearanceSubtitle => '色彩、滤镜、锐化、透明与局部选区';

  @override
  String get generalImageEditorAnnotationSubtitle => '文字、形状、箭头与标记位置';

  @override
  String get generalImageEditorOutputSubtitle => '保存格式、质量和最终预览';

  @override
  String get generalImageEditorGeneratePreview => '生成完整预览';

  @override
  String get generalImageEditorResetOptions => '重置参数';

  @override
  String get generalImageEditorApplyAndSave => '应用并保存';

  @override
  String get generalImageEditorProcessing => '处理中';

  @override
  String get generalImageEditorPreviewTitle => '编辑预览';

  @override
  String get generalImageEditorPreviewEmpty => '选择图片后开始编辑';

  @override
  String get generalImageEditorPreviewLoading => '正在生成预览';

  @override
  String get generalImageEditorPreviewFailed => '预览失败';

  @override
  String get generalImageEditorNoPreviewResult => '没有可用的预览结果';

  @override
  String generalImageEditorPreviewFooter(Object fileName) {
    return '$fileName · 拖拽裁剪框或选区，点击标注可删除';
  }

  @override
  String get generalImageEditorPresetsTitle => '常用预设';

  @override
  String get generalImageEditorPresetsSubtitle => '快速套用常见输出和处理组合';

  @override
  String get generalImageEditorTransparentPngPreset => '透明 PNG';

  @override
  String get generalImageEditorSocialJpegPreset => '社媒 JPEG';

  @override
  String get generalImageEditorSharpJpegPreset => '清晰 JPEG';

  @override
  String get generalImageEditorPixelPngPreset => '像素风 PNG';

  @override
  String get generalImageEditorVersionTitle => '版本快照';

  @override
  String get generalImageEditorSaveCurrentVersion => '保存当前版本';

  @override
  String get generalImageEditorNoSavedVersions => '暂无保存版本';

  @override
  String generalImageEditorVersionLabel(int index) {
    return '版本 $index';
  }

  @override
  String get generalImageEditorTransformTitle => '旋转与翻转';

  @override
  String get generalImageEditorRotateLeft => '左转';

  @override
  String get generalImageEditorRotateRight => '右转';

  @override
  String get generalImageEditorFlipHorizontal => '水平翻转';

  @override
  String get generalImageEditorFlipVertical => '垂直翻转';

  @override
  String get generalImageEditorCropTitle => '裁剪边距';

  @override
  String get generalImageEditorLeftSide => '左侧';

  @override
  String get generalImageEditorTopSide => '上侧';

  @override
  String get generalImageEditorRightSide => '右侧';

  @override
  String get generalImageEditorBottomSide => '下侧';

  @override
  String get generalImageEditorClearCrop => '清除裁剪';

  @override
  String get generalImageEditorResizeTitle => '输出尺寸';

  @override
  String get generalImageEditorResizeOutput => '调整输出尺寸';

  @override
  String get generalImageEditorLockAspectRatio => '保持比例';

  @override
  String get generalImageEditorWidth => '宽度';

  @override
  String get generalImageEditorHeight => '高度';

  @override
  String get generalImageEditorColorTitle => '色彩调整';

  @override
  String get generalImageEditorBrightness => '亮度';

  @override
  String get generalImageEditorContrast => '对比度';

  @override
  String get generalImageEditorSaturation => '饱和度';

  @override
  String get generalImageEditorWarmth => '冷暖';

  @override
  String get generalImageEditorEffectTitle => '效果处理';

  @override
  String get generalImageEditorFilterLabel => '滤镜';

  @override
  String get generalImageEditorBlur => '模糊';

  @override
  String get generalImageEditorBlurRadius => '模糊半径';

  @override
  String get generalImageEditorSharpen => '锐化';

  @override
  String get generalImageEditorSharpenAmount => '锐化强度';

  @override
  String get generalImageEditorTransparentBackground => '边缘背景转透明';

  @override
  String get generalImageEditorTransparentTolerance => '透明容差';

  @override
  String get generalImageEditorPixelation => '像素化';

  @override
  String get generalImageEditorPixelBlock => '像素块';

  @override
  String get generalImageEditorRegionTitle => '局部选区';

  @override
  String get generalImageEditorProcessRegionOnly => '只处理选区';

  @override
  String get generalImageEditorLeftBoundary => '左边界';

  @override
  String get generalImageEditorTopBoundary => '上边界';

  @override
  String get generalImageEditorRightBoundary => '右边界';

  @override
  String get generalImageEditorBottomBoundary => '下边界';

  @override
  String get generalImageEditorCenterHalfRegion => '居中 50%';

  @override
  String get generalImageEditorFullImageRegion => '全图选区';

  @override
  String get generalImageEditorAnnotationType => '类型';

  @override
  String get generalImageEditorAnnotationText => '文字';

  @override
  String get generalImageEditorAnnotationPositionPercent => '位置百分比';

  @override
  String get generalImageEditorStartX => '起点 X';

  @override
  String get generalImageEditorStartY => '起点 Y';

  @override
  String get generalImageEditorEndX => '终点 X';

  @override
  String get generalImageEditorEndY => '终点 Y';

  @override
  String get generalImageEditorStrokeWidth => '线宽';

  @override
  String get generalImageEditorFontSize => '字号';

  @override
  String get generalImageEditorFillShape => '填充形状';

  @override
  String get generalImageEditorAddAnnotation => '添加标注';

  @override
  String get generalImageEditorClearAnnotations => '清空标注';

  @override
  String get generalImageEditorOutputFormat => '保存格式';

  @override
  String get generalImageEditorJpegQuality => 'JPEG 质量';

  @override
  String generalImageEditorRotatedDegrees(int degrees) {
    return '旋转 $degrees°';
  }

  @override
  String get generalImageEditorNoTransform => '无变换';

  @override
  String generalImageEditorCropLeftSummary(int value) {
    return '左 ${value}px';
  }

  @override
  String generalImageEditorCropTopSummary(int value) {
    return '上 ${value}px';
  }

  @override
  String generalImageEditorCropRightSummary(int value) {
    return '右 ${value}px';
  }

  @override
  String generalImageEditorCropBottomSummary(int value) {
    return '下 ${value}px';
  }

  @override
  String get generalImageEditorNoCrop => '无裁剪';

  @override
  String generalImageEditorCropSummary(Object parts) {
    return '裁剪 $parts';
  }

  @override
  String get generalImageEditorOriginalSize => '原尺寸';

  @override
  String generalImageEditorBrightnessSummary(int value) {
    return '亮度 $value%';
  }

  @override
  String generalImageEditorContrastSummary(int value) {
    return '对比度 $value%';
  }

  @override
  String generalImageEditorSaturationSummary(int value) {
    return '饱和度 $value%';
  }

  @override
  String generalImageEditorWarmthSummary(int value) {
    return '冷暖 $value%';
  }

  @override
  String get generalImageEditorNoColorAdjustment => '无色彩调整';

  @override
  String generalImageEditorBlurSummary(int radius) {
    return '模糊 ${radius}px';
  }

  @override
  String generalImageEditorSharpenSummary(int amount) {
    return '锐化 $amount%';
  }

  @override
  String get generalImageEditorTransparentBackgroundSummary => '背景透明';

  @override
  String generalImageEditorPixelationSummary(int blockSize) {
    return '像素化 ${blockSize}px';
  }

  @override
  String get generalImageEditorNoFilter => '无滤镜';

  @override
  String get generalImageEditorFullImageProcessing => '全图处理';

  @override
  String get generalImageEditorNoSavedVersionSummary => '未保存版本';

  @override
  String generalImageEditorSavedVersionCount(int count) {
    return '$count 个版本';
  }

  @override
  String get generalImageEditorNoAnnotationSummary => '无标注';

  @override
  String generalImageEditorAnnotationCount(int count) {
    return '$count 个标注';
  }

  @override
  String get generalImageEditorPngTransparentSummary => 'PNG · 支持透明';

  @override
  String get generalImageEditorSnapshotOriginalSize => '原尺寸';

  @override
  String get generalImageEditorSnapshotLocalRegion => '局部选区';

  @override
  String generalImageEditorSnapshotAnnotationCount(int count) {
    return '标注 $count';
  }

  @override
  String get generalImageEditorAnnotationKindText => '文字';

  @override
  String get generalImageEditorAnnotationKindRectangle => '矩形';

  @override
  String get generalImageEditorAnnotationKindEllipse => '椭圆';

  @override
  String get generalImageEditorAnnotationKindLine => '直线';

  @override
  String get generalImageEditorAnnotationKindArrow => '箭头';

  @override
  String get generalImageEditorColorRed => '红色';

  @override
  String get generalImageEditorColorYellow => '黄色';

  @override
  String get generalImageEditorColorGreen => '绿色';

  @override
  String get generalImageEditorColorBlue => '蓝色';

  @override
  String get generalImageEditorColorBlack => '黑色';

  @override
  String get generalImageEditorColorWhite => '白色';

  @override
  String get generalImageEditorColorCustom => '自定义';

  @override
  String get generalImageEditorAnnotationFilledSuffix => '填充';

  @override
  String get generalImageEditorRestoreVersionTooltip => '恢复版本';

  @override
  String get generalImageEditorDeleteVersionTooltip => '删除版本';

  @override
  String get generalImageEditorDeleteAnnotationTooltip => '删除标注';

  @override
  String get generalImageEditorDeleteSelectedAnnotationTooltip => '删除选中的标注';

  @override
  String get generalImageEditorImageLoadFailed => '图片加载失败';

  @override
  String get generalImageEditorEffectOriginal => '原色';

  @override
  String get generalImageEditorEffectGrayscale => '灰度';

  @override
  String get generalImageEditorEffectSepia => '复古';

  @override
  String get generalImageEditorEffectInvert => '反相';

  @override
  String get generalImageEditSummaryCrop => '裁剪';

  @override
  String get generalImageEditSummaryRotatePattern => '旋转 %degrees%°';

  @override
  String get generalImageEditSummaryResizePattern => '缩放 %width% x %height%';

  @override
  String get generalImageEditSummaryAnnotationPattern => '标注 %count% 个';

  @override
  String get generalImageEditSummaryJpegQualityPattern => 'JPEG %quality%质量';

  @override
  String get generalImageEditSummarySaveCopy => '保存副本';

  @override
  String get generalImageEditSummarySeparator => ' · ';

  @override
  String get generalImageEditSummaryBlurPattern => '模糊 %radius%px';

  @override
  String get generalImageEditSummarySharpenPattern => '锐化 %amount%%';

  @override
  String get generalImageEditSummaryPixelationPattern => '像素化 %blockSize%px';

  @override
  String get frameCountBadgeDefaultLabel => '帧';

  @override
  String frameCountBadgeTooltip(int count, Object label) {
    return '共 $count $label';
  }

  @override
  String sharedDecreasePxTooltip(Object label) {
    return '$label减少 1px';
  }

  @override
  String sharedIncreasePxTooltip(Object label) {
    return '$label增加 1px';
  }

  @override
  String sharedDecreaseTooltip(Object label) {
    return '$label减少 1';
  }

  @override
  String sharedIncreaseTooltip(Object label) {
    return '$label增加 1';
  }

  @override
  String get spriteSheetGridSpecTitle => '切片校准';

  @override
  String get spriteSheetGridSpecAdjusted => '已调整';

  @override
  String get spriteSheetGridSpecDescription =>
      '用于处理 Sprite Sheet 外边距或格子间隔，预览、切片和替换都会按这里计算。';

  @override
  String get spriteSheetGridMarginLeft => '左边距';

  @override
  String get spriteSheetGridMarginTop => '上边距';

  @override
  String get spriteSheetGridMarginRight => '右边距';

  @override
  String get spriteSheetGridMarginBottom => '下边距';

  @override
  String get spriteSheetGridColumnGap => '列间距';

  @override
  String get spriteSheetGridRowGap => '行间距';

  @override
  String get spriteSheetGridReset => '重置切片校准';

  @override
  String spriteSheetGridMarginLeftSummary(int value) {
    return '左 ${value}px';
  }

  @override
  String spriteSheetGridMarginTopSummary(int value) {
    return '上 ${value}px';
  }

  @override
  String spriteSheetGridMarginRightSummary(int value) {
    return '右 ${value}px';
  }

  @override
  String spriteSheetGridMarginBottomSummary(int value) {
    return '下 ${value}px';
  }

  @override
  String spriteSheetGridColumnGapSummary(int value) {
    return '列间距 ${value}px';
  }

  @override
  String spriteSheetGridRowGapSummary(int value) {
    return '行间距 ${value}px';
  }

  @override
  String get spriteSheetGridSpecDefaultSummary => '默认：无边距 / 无间距';

  @override
  String get requestDebugUnavailableTooltip => '生成后可查看请求和返回值';

  @override
  String get requestDebugAvailableTooltip => '查看请求参数和返回值';

  @override
  String get requestDebugButtonLabel => '调试详情';

  @override
  String get requestDebugDialogTitle => '请求调试详情';

  @override
  String get requestDebugCopied => '调试详情已复制。';

  @override
  String get templateImagePickerDefaultTitle => '模板图片';

  @override
  String get templateImagePickerClearTooltip => '清除模板图片';

  @override
  String get templateImagePickerLoadFailed => '模板图片加载失败。';

  @override
  String get imageAdvancedSettingsTitle => '高级输出参数';

  @override
  String get imageAdvancedSettingsQualitySuffix => '质量';

  @override
  String get imageAdvancedSettingsBackgroundSuffix => '背景';

  @override
  String get imageAdvancedSettingsQuality => '质量';

  @override
  String get imageAdvancedSettingsBackground => '背景';

  @override
  String get imageAdvancedSettingsOutputFormat => '输出格式';

  @override
  String get imageAdvancedSettingsModeration => '审核强度';

  @override
  String get imageAdvancedSettingsFinalUserId => '最终用户 ID';

  @override
  String get imageAdvancedSettingsFinalUserHint => '可选，用于 OpenAI 滥用监控';

  @override
  String get imageAdvancedSettingsInputFidelity => '参考图保真度';

  @override
  String get imageAdvancedSettingsHigh => '高';

  @override
  String get imageAdvancedSettingsLow => '低';

  @override
  String imageAdvancedSettingsCompressionValue(int value) {
    return '输出压缩率 $value%';
  }

  @override
  String get imageAdvancedSettingsCompressionUnavailable =>
      '输出压缩率仅用于 JPEG / WebP';

  @override
  String get imageSizeWidth => '宽度';

  @override
  String get imageSizeHeight => '高度';

  @override
  String get imageSizeCustomSize => '自定义尺寸';

  @override
  String get imageSizeScaleLabel => '尺寸档位';

  @override
  String get imageSizeOrientation => '方向';

  @override
  String get imageAspectSquare => '方图';

  @override
  String get imageAspectLandscape => '横图';

  @override
  String get imageAspectPortrait => '竖图';

  @override
  String imageSizePresetLabel(Object scale, Object orientation) {
    return '$scale $orientation';
  }

  @override
  String imageSizePresetWide(Object scale) {
    return '$scale 宽屏';
  }

  @override
  String imageSizeConstraintHelper(int minSide, int maxSide, int step) {
    return '$minSide-$maxSide，${step}px 倍数';
  }

  @override
  String get imageSizeInvalidFallback => '当前图片尺寸无效。';

  @override
  String get imageSizeInvalidDimensions => '请输入有效的宽度和高度。';

  @override
  String imageSizeFixedPresetsOnly(Object presetSizes) {
    return '当前模型只支持固定分辨率：$presetSizes。';
  }

  @override
  String imageSizeSideTooSmall(int minSide) {
    return '宽高都不能小于 ${minSide}px。';
  }

  @override
  String imageSizeSideTooLarge(int maxSide) {
    return '宽高都不能超过 ${maxSide}px。';
  }

  @override
  String imageSizeSideStepMismatch(int step) {
    return '宽高都必须是 ${step}px 的倍数。';
  }

  @override
  String imageSizeAspectRatioTooLarge(int maxAspectRatio) {
    return '长边不能超过短边的 $maxAspectRatio 倍。';
  }

  @override
  String imageSizeTotalPixelsTooSmall(int minPixels) {
    return '总像素不能低于 $minPixels。';
  }

  @override
  String imageSizeTotalPixelsTooLarge(int maxPixels) {
    return '总像素不能超过 $maxPixels。';
  }

  @override
  String imageSizeGeminiAspectSummary(Object label, Object aspectRatio) {
    return '$label · Gemini 画幅比例 $aspectRatio';
  }

  @override
  String imageSizeCustomRequestSummary(Object size) {
    return '自定义尺寸 · 请求尺寸 $size';
  }

  @override
  String imageSizeRequestSummary(Object label, Object size) {
    return '$label · 请求尺寸 $size';
  }

  @override
  String get imageSizeFixedResolution => '固定分辨率';

  @override
  String get imageSizeModeResolution => '分辨率';

  @override
  String get imageSizeModeAspectRatio => '画幅比例';

  @override
  String get imageSizeModeFixedPresets => '分辨率档位';

  @override
  String get imageSizeCapabilityAuto => '自动识别';

  @override
  String get imageSizeCapabilityFixedPresets => '固定分辨率';

  @override
  String get imageSizeCapabilityCustomPixels => '自定义像素尺寸';

  @override
  String get imageSizeCapabilityAspectRatio => '画幅比例';

  @override
  String get imageSizeCapabilityGeminiAspectRatio => 'Gemini 画幅比例';

  @override
  String imageSizeCapabilityFixedDescription(Object presetSizes) {
    return '仅允许固定档位：$presetSizes。';
  }

  @override
  String imageSizeCapabilityCustomDescription(int step) {
    return '允许固定档位或自定义宽高，宽高必须是 ${step}px 倍数。';
  }

  @override
  String get imageSizeCapabilityAspectDescription =>
      '按所选尺寸换算为最接近的 Gemini 画幅比例。';

  @override
  String get imageEditorWorkspaceTitle => '图片编辑';

  @override
  String get imageEditorWorkspaceGeneralDescription => '裁剪、旋转、缩放、调色和保存图片副本';

  @override
  String get imageEditorWorkspaceSpriteSheetDescription =>
      '载入一张 Sprite Sheet，按行列快速查看第几帧';

  @override
  String get imageEditorGeneralImageTab => '普通图片';

  @override
  String get imageEditorSpriteSheetTab => 'Sprite Sheet';

  @override
  String get imageEditorExitFocusModeTooltip => '退出专注模式';

  @override
  String get imageEditorEnterFocusModeTooltip => '进入专注模式';

  @override
  String get imageEditorSlicePreviewTitle => '切片查看';

  @override
  String get imageEditorSlicePreviewEmpty => '选择一张 Sprite Sheet 后，可以按行列查看第几帧';

  @override
  String editorGifAdjustRowsHistory(int value) {
    return '调整行数为 $value 行';
  }

  @override
  String editorGifAdjustColumnsHistory(int value) {
    return '调整列数为 $value 列';
  }

  @override
  String get editorGifAdjustGridSpecHistory => '调整切片校准';

  @override
  String editorGifAdjustFrameFitHistory(Object label) {
    return '调整适配方式为 $label';
  }

  @override
  String get editorGifSelectSpriteSheetTitle => '选择 Sprite Sheet 图片';

  @override
  String get editorGifSpriteSheetLibraryEmpty => '生成或导出 Sprite Sheet 后可从这里复用';

  @override
  String get editorGifLoadSpriteSheetHistory => '载入 Sprite Sheet';

  @override
  String editorGifLoadedImageMessage(Object fileName) {
    return '已载入图片：$fileName';
  }

  @override
  String get editorGifClearSpriteSheetHistory => '清空 Sprite Sheet';

  @override
  String get editorGifSelectSingleFrameTitle => '选择单帧图片';

  @override
  String get editorGifSingleFrameLibraryEmpty => '保存到作品库后的单帧图片会显示在这里';

  @override
  String get editorGifSelectSingleFrameHistory => '选择单帧图片';

  @override
  String editorGifLoadedSingleFrameMessage(Object fileName) {
    return '已选择单帧图片：$fileName';
  }

  @override
  String get editorGifClearSingleFrameHistory => '清空单帧图片';

  @override
  String get editorGifPleaseSelectSingleFrame => '请先选择一张单帧图片';

  @override
  String get editorGifNoTransparentEdgeMessage => '没有检测到可透明化的边缘背景，可尝试调高容差';

  @override
  String get editorGifTransparentBackgroundTitle => '透明背景单帧';

  @override
  String get editorGifTransparentBackgroundSource => '图片编辑';

  @override
  String editorGifTransparentBackgroundPrompt(
    int tolerance,
    int width,
    int height,
  ) {
    return '背景转透明 · 容差 $tolerance · $width x $height';
  }

  @override
  String get editorGifTransparentBackgroundHistory => '背景转透明单帧';

  @override
  String editorGifTransparentBackgroundSavedMessage(
    Object fileName,
    int count,
  ) {
    return '已生成透明背景单帧：$fileName · 透明化 $count 个像素';
  }

  @override
  String editorGifTransparentBackgroundFailedMessage(Object error) {
    return '背景转透明失败：$error';
  }

  @override
  String get editorGifPleaseSelectSpriteSheet => '请先选择一张 Sprite Sheet';

  @override
  String get editorGifFramedSingleFrameTitle => '取景单帧';

  @override
  String editorGifFramedSingleFramePrompt(int width, int height) {
    return '单帧取景 · $width x $height';
  }

  @override
  String get editorGifAdjustFramingHistory => '调整单帧取景';

  @override
  String editorGifFramedSingleFrameSavedMessage(
    Object fileName,
    int width,
    int height,
  ) {
    return '已生成取景单帧：$fileName · $width x $height';
  }

  @override
  String editorGifAdjustFramingFailedMessage(Object error) {
    return '调整取景失败：$error';
  }

  @override
  String get editorGifSelectTemplateTitle => '选择模板图片';

  @override
  String get editorGifTemplateLibraryEmpty => '保存到作品库后的图片会显示在这里';

  @override
  String editorGifSelectedTemplateSliceMessage(Object sliceLabel) {
    return '已选择模板切片：$sliceLabel';
  }

  @override
  String editorGifSelectedTemplateImageMessage(Object fileName) {
    return '已选择模板图片：$fileName';
  }

  @override
  String get editorGifImageEditorSource => '图片编辑';

  @override
  String editorGifTemplateSliceLabel(Object title, int frame) {
    return '$title · 帧 $frame';
  }

  @override
  String get editorGifNeedAtLeastTwoFrames => '至少需要 2 帧才能合成 GIF';

  @override
  String get editorGifQuickGifProjectTitle => 'Sprite Sheet 快速 GIF';

  @override
  String get editorGifExportSpriteSheetGifHistory => '导出 Sprite Sheet GIF';

  @override
  String editorGifExportGifSavedMessage(Object fileName, Object directoryPath) {
    return 'GIF 已生成：$fileName · 目录：$directoryPath';
  }

  @override
  String editorGifExportGifFailedMessage(Object error) {
    return '导出 GIF 失败：$error';
  }

  @override
  String get editorGifExportSpriteSheetHistory => '导出 Sprite Sheet';

  @override
  String editorGifExportSpriteSheetSavedMessage(
    Object fileName,
    Object directoryPath,
  ) {
    return '已导出 Sprite Sheet：$fileName · 目录：$directoryPath';
  }

  @override
  String get editorGifPleaseSelectPatchForInsert => '请先选择要插入的单帧图片';

  @override
  String editorGifReplaceFrameHistory(int index) {
    return '替换第 $index 帧';
  }

  @override
  String editorGifReplaceFrameSavedMessage(
    int index,
    Object fileName,
    Object directoryPath,
  ) {
    return '已替换第 $index 帧：$fileName · 目录：$directoryPath';
  }

  @override
  String editorGifReplaceFrameFailedMessage(Object error) {
    return '单帧替换失败：$error';
  }

  @override
  String get editorGifFirstFrameNoPrevious => '第 1 帧没有上一帧可复制';

  @override
  String editorGifCopyPreviousFrameHistory(int index) {
    return '复制上一帧到第 $index 帧';
  }

  @override
  String editorGifCopyPreviousFrameMessage(int index) {
    return '已复制上一帧到第 $index 帧';
  }

  @override
  String editorGifCopyFrameFailedMessage(Object error) {
    return '复制帧失败：$error';
  }

  @override
  String editorGifClearFrameHistory(int index) {
    return '清空第 $index 帧';
  }

  @override
  String editorGifClearFrameMessage(int index) {
    return '已清空第 $index 帧';
  }

  @override
  String editorGifClearFrameFailedMessage(Object error) {
    return '清空帧失败：$error';
  }

  @override
  String get editorGifPixelatedSpriteSheetTitle => '像素化 Sprite Sheet';

  @override
  String editorGifPixelatedFramePrompt(
    int index,
    int blockSize,
    int rows,
    int columns,
  ) {
    return '像素化第 $index 帧 · 像素块 ${blockSize}px · $rows x $columns';
  }

  @override
  String editorGifPixelateFrameHistory(int index) {
    return '像素化第 $index 帧';
  }

  @override
  String editorGifPixelateFrameSavedMessage(
    int index,
    Object fileName,
    int blockSize,
  ) {
    return '已像素化第 $index 帧：$fileName · 像素块 ${blockSize}px';
  }

  @override
  String editorGifPixelateCurrentFrameFailedMessage(Object error) {
    return '像素化当前帧失败：$error';
  }

  @override
  String editorGifPixelatedWholeSheetPrompt(
    int blockSize,
    int rows,
    int columns,
  ) {
    return '像素化整张 · 像素块 ${blockSize}px · $rows x $columns';
  }

  @override
  String get editorGifPixelateWholeSheetHistory => '像素化整张 Sprite Sheet';

  @override
  String editorGifPixelateWholeSheetSavedMessage(
    Object fileName,
    int blockSize,
  ) {
    return '已像素化整张 Sprite Sheet：$fileName · 像素块 ${blockSize}px';
  }

  @override
  String editorGifPixelateWholeSheetFailedMessage(Object error) {
    return '像素化整张失败：$error';
  }

  @override
  String get editorGifSelectImageToEditTitle => '选择要编辑的图片';

  @override
  String get editorGifGeneralImageLibraryEmpty => '作品库里保存的图片会显示在这里';

  @override
  String editorGifGeneralImageLoadedMessage(Object fileName) {
    return '已载入图片：$fileName';
  }

  @override
  String editorGifImageReadFailedMessage(Object error) {
    return '图片读取失败：$error';
  }

  @override
  String get editorGifPleaseSelectImage => '请先选择一张图片';

  @override
  String get editorGifEditedImageTitle => '编辑后的图片';

  @override
  String get editorGifEditImageHistory => '编辑图片';

  @override
  String editorGifEditImageSavedMessage(Object fileName, Object summary) {
    return '已保存编辑结果：$fileName · $summary';
  }

  @override
  String editorGifEditImageFailedMessage(Object error) {
    return '图片编辑失败：$error';
  }

  @override
  String framePreviewProgressFailed(Object message) {
    return 'Sprite Sheet 生成失败，可调整参数后重试。$message';
  }

  @override
  String framePreviewProgressGenerating(int totalCount) {
    return '正在生成 1 张 Sprite Sheet，完成后会按 $totalCount 格切片预览。';
  }

  @override
  String framePreviewProgressReady(int totalCount) {
    return '已生成 1 张 Sprite Sheet，并按 $totalCount 格切片预览。';
  }

  @override
  String get framePreviewZoomOutTooltip => '缩小播放帧';

  @override
  String get framePreviewZoomInTooltip => '放大播放帧';

  @override
  String get framePreviewResetZoomTooltip => '重置播放帧缩放';

  @override
  String get framePreviewGeneratingSheet => '正在生成 Sprite Sheet';

  @override
  String get framePreviewGenerationFailedTitle => '生成失败';

  @override
  String get framePreviewBuildingSlices => '正在生成切片预览';

  @override
  String get framePreviewPreviewFailedTitle => '预览失败';

  @override
  String framePreviewPreviewFailedMessage(Object message) {
    return '切片预览失败：$message';
  }

  @override
  String get framePreviewNoPreviewData => '没有可用的预览数据';

  @override
  String get framePreviewPlaybackModeLabel => '切片播放';

  @override
  String get framePreviewTargetSelectionModeLabel => '目标选择';

  @override
  String get framePreviewGridModeLabel => '网格检查';

  @override
  String framePreviewRowTitle(int row) {
    return '第 $row 行';
  }

  @override
  String framePreviewRowSubtitle(int row, int columns) {
    return '第 $row 行 · $columns 列';
  }

  @override
  String get framePreviewTargetFrameLabel => '目标帧';

  @override
  String get framePreviewFrameNumberLabel => '帧号';

  @override
  String framePreviewFrameOption(int frame) {
    return '第 $frame 帧';
  }

  @override
  String get framePreviewRowNumberLabel => '行号';

  @override
  String get framePreviewPlaybackSpeedLabel => '播放速度';

  @override
  String get framePreviewExportPng => '导出 PNG';

  @override
  String get framePreviewConvertGif => '转 GIF';

  @override
  String get framePreviewPixelEdit => '像素化编辑';

  @override
  String get framePreviewPreviousFrameTooltip => '上一帧';

  @override
  String get framePreviewNextFrameTooltip => '下一帧';

  @override
  String get framePreviewPlaybackSingleFrameUnavailable => '当前行只有 1 帧，无法播放或切换帧';

  @override
  String get framePreviewCurrentTargetPrefix => '当前目标';

  @override
  String get framePreviewCurrentPlaybackPrefix => '当前播放';

  @override
  String framePreviewCurrentStatus(
    Object prefix,
    int frame,
    int row,
    int column,
    int columns,
  ) {
    return '$prefix：第 $frame 帧 · 第 $row 行 · 第 $column / $columns 列';
  }

  @override
  String get framePreviewTargetSelectionHint =>
      '点击右侧 Sprite Sheet 或网格切片，可以直接选择要替换的目标帧。';

  @override
  String get framePreviewPlaybackHint => '点击右侧 Sprite Sheet 或网格切片，可以直接查看对应帧。';

  @override
  String get framePreviewPlaybackFrameTitle => '播放帧';

  @override
  String get framePreviewSpriteSheetTitle => 'Sprite Sheet';

  @override
  String framePreviewSpriteSheetSubtitle(int rows, int columns, int count) {
    return '$rows 行 x $columns 列，来源 $count 张结果图';
  }

  @override
  String get backgroundTransparencyTitle => '背景转透明';

  @override
  String get backgroundTransparencyDescription => '从图片边缘识别近似纯色背景，生成一张新的透明 PNG。';

  @override
  String backgroundTransparencyDescriptionForSource(Object sourceTitle) {
    return '处理「$sourceTitle」，生成一张新的透明 PNG。';
  }

  @override
  String get backgroundTransparencyDetail => '只会移除和边缘连通的近似背景色，内部同色细节会保留。';

  @override
  String backgroundTransparencyTolerance(int tolerance) {
    return '容差 $tolerance';
  }

  @override
  String get backgroundTransparencyGenerate => '生成透明图';

  @override
  String get patchImageFramingTitle => '调整单帧取景';

  @override
  String get patchImageFramingContain => '完整显示';

  @override
  String get patchImageFramingCover => '填满格子';

  @override
  String get patchImageFramingCenter => '居中';

  @override
  String patchImageFramingScaleSemanticLabel(int percent) {
    return '缩放 $percent%';
  }

  @override
  String patchImageFramingViewportSemanticLabel(
    int width,
    int height,
    int percent,
    int offsetX,
    int offsetY,
  ) {
    return '单帧取景预览 · 目标 $width x $height · 缩放 $percent% · 偏移 X $offsetX，Y $offsetY';
  }

  @override
  String get patchImageFramingGenerate => '生成取景单帧';

  @override
  String get spriteSheetEditorConfigTitle => '编辑配置';

  @override
  String get spriteSheetEditorSheetImageTitle => 'Sprite Sheet 图片';

  @override
  String get spriteSheetEditorClearSheetImageTooltip => '清除图片';

  @override
  String get spriteSheetEditorRowsLabel => '行数';

  @override
  String spriteSheetEditorRowsValue(int count) {
    return '$count 行';
  }

  @override
  String get spriteSheetEditorColumnsLabel => '列数';

  @override
  String spriteSheetEditorColumnsValue(int count) {
    return '$count 列';
  }

  @override
  String get spriteSheetEditorPatchImageTitle => '单帧图片';

  @override
  String get spriteSheetEditorClearPatchImageTooltip => '清除单帧图片';

  @override
  String get spriteSheetEditorReplacementTargetLabel => '替换目标';

  @override
  String get spriteSheetEditorFrameFitLabel => '适配方式';

  @override
  String get spriteSheetEditorFrameFitContain => '完整放入';

  @override
  String get spriteSheetEditorFrameFitCover => '裁剪填满';

  @override
  String get spriteSheetEditorFrameFitStretch => '拉伸填满';

  @override
  String editorFrameOptionLabel(int index, int row, int column) {
    return '$index 帧 · $row 行 $column 列';
  }

  @override
  String get gifPlaybackModeNormal => '正向';

  @override
  String get gifPlaybackModeReverse => '反向';

  @override
  String get gifPlaybackModePingPong => '乒乓';

  @override
  String get spriteSheetEditorCopyPreviousFrame => '复制上一帧';

  @override
  String get spriteSheetEditorClearCurrentCell => '清空当前格';

  @override
  String get spriteSheetEditorInsertReplaceCurrentCell => '插入 / 替换到当前格';

  @override
  String get spriteSheetEditorReplacing => '替换中';

  @override
  String spriteSheetEditorTargetFrameHelper(
    int row,
    int column,
    int totalCount,
  ) {
    return '第 $row 行 · 第 $column 列 · 共 $totalCount 帧';
  }

  @override
  String get spriteSheetEditorToolFraming => '单帧取景';

  @override
  String get spriteSheetEditorToolTransparent => '透明背景';

  @override
  String get spriteSheetEditorToolPixelate => '像素化';

  @override
  String get spriteSheetEditorToolsTitle => '编辑工具';

  @override
  String get spriteSheetEditorToolsDisabledHint => '选择 Sprite Sheet 或单帧图片后可用';

  @override
  String get spriteSheetEditorProcessing => '处理中';

  @override
  String get spriteSheetEditorGenerateTransparentPatch => '生成透明背景单帧';

  @override
  String get spriteSheetEditorPixelBlockLabel => '像素块';

  @override
  String get spriteSheetEditorPixelBlockHelper => '数值越大，颗粒越粗';

  @override
  String get spriteSheetEditorPixelateCurrentFrame => '像素化当前帧';

  @override
  String get spriteSheetEditorPixelateWholeSheet => '像素化整张';

  @override
  String get spriteSheetGenerationConfigTitle => '序列帧生成配置';

  @override
  String get spriteSheetCell => '格';

  @override
  String get spriteSheetPromptLabel => '提示词内容';

  @override
  String get spriteSheetPromptHint => '把主体、场景、风格、动作变化写在这里即可';

  @override
  String get spriteSheetNegativePromptHint => '可选，填写后会作为排除描述应用到每一帧';

  @override
  String get spriteSheetRowsLabel => '行数';

  @override
  String get spriteSheetRowShortLabel => '行';

  @override
  String get spriteSheetColumnShortLabel => '列';

  @override
  String get spriteSheetFrameShortLabel => '帧';

  @override
  String spriteSheetFrameGridLabel(int frameIndex, int row, int column) {
    return '第 $frameIndex 帧 · 第 $row 行 · 第 $column 列';
  }

  @override
  String spriteSheetRowsValue(int count) {
    return '$count 行';
  }

  @override
  String get spriteSheetColumnsLabel => '列数';

  @override
  String spriteSheetColumnsValue(int count) {
    return '$count 列';
  }

  @override
  String get spriteSheetGenerateButton => '生成 Sprite Sheet';

  @override
  String get spriteSheetGeneratingButton => '生成 Sprite Sheet 中';

  @override
  String get animationProjectWorkspaceDescription =>
      '用工程、轨道和序列帧管理动画，Sprite Sheet 与 GIF 只作为导入和导出格式。';

  @override
  String get animationProjectNoImportSource => '暂无可导入来源';

  @override
  String get animationProjectCreateTitle => '创建动画工程';

  @override
  String get animationProjectImportAsProject => '导入为动画工程';

  @override
  String get animationProjectImportingProject => '正在导入工程';

  @override
  String get animationProjectImportLocalSequence => '导入本地图片序列';

  @override
  String get animationProjectImportLibrarySequence => '从作品库导入序列';

  @override
  String get animationProjectExporting => '正在导出';

  @override
  String get animationProjectExportSourceSpriteSheet => '导出来源 Sprite Sheet';

  @override
  String get animationProjectSourceTitle => '工程来源';

  @override
  String get animationProjectGeneratingSource => '正在生成来源';

  @override
  String get animationProjectControlsTitle => '工程控制';

  @override
  String get animationProjectFrameUnit => '帧';

  @override
  String get animationProjectTrackUnit => '轨道';

  @override
  String animationProjectSummary(
    int trackCount,
    int frameCount,
    int width,
    int height,
  ) {
    return '$trackCount 条轨道 · $frameCount 帧 · $width x $height';
  }

  @override
  String get animationProjectAddTrack => '新建轨道';

  @override
  String get animationProjectExportCompositedSpriteSheet => '导出合成 Sprite Sheet';

  @override
  String get animationProjectExportProjectGif => '导出工程 GIF';

  @override
  String get animationProjectExportProjectPngSequence => '导出工程 PNG 序列';

  @override
  String get animationProjectExportTrackGif => '导出当前轨道 GIF';

  @override
  String get animationProjectExportPngSequence => '导出 PNG 序列';

  @override
  String get animationProjectCloseProject => '关闭工程';

  @override
  String get animationProjectActionBusyUnavailable => '当前工程正在处理任务，完成后可继续操作';

  @override
  String get animationProjectTrackTimelineTitle => '轨道时间轴';

  @override
  String get animationProjectSettingsTitle => '工程设置';

  @override
  String get animationProjectDefaultFrameDelay => '工程默认帧时长';

  @override
  String get animationProjectPlaybackMode => '工程播放方式';

  @override
  String get animationProjectGifLoopCount => 'GIF 循环次数';

  @override
  String get animationProjectLoopCountSuffix => '次';

  @override
  String get animationProjectIncludeHiddenTracks => '导出包含隐藏轨道';

  @override
  String get animationProjectPreviewTitle => '动画工程预览';

  @override
  String get animationProjectRenderingComposite => '正在渲染工程合成';

  @override
  String get animationProjectRenderFailed => '渲染失败';

  @override
  String get animationProjectNoRenderData => '没有可用的渲染数据';

  @override
  String get animationProjectRetryRender => '重新渲染';

  @override
  String get animationProjectNoVisibleFrames => '工程没有可见帧';

  @override
  String get animationProjectPlayPreview => '播放';

  @override
  String get animationProjectPausePreview => '暂停';

  @override
  String get animationProjectPreviousFrame => '上一帧';

  @override
  String get animationProjectNextFrame => '下一帧';

  @override
  String animationProjectCompositeFrameStatus(
    int frameIndex,
    int frameCount,
    int delayMs,
  ) {
    return '合成帧 $frameIndex / $frameCount · $delayMs ms';
  }

  @override
  String animationProjectGeneratedSourceGrid(
    int rows,
    int columns,
    int frameCount,
  ) {
    return '$rows x $columns · $frameCount 格';
  }

  @override
  String animationProjectGeneratedSequenceSource(int count) {
    return '$count 张序列帧';
  }

  @override
  String get animationProjectResizeControlsTooltip => '拖动调整工程控制宽度，双击复位';

  @override
  String get animationProjectResizeTimelineTooltip => '拖动调整时间轴高度，双击复位';

  @override
  String get animationProjectAssetDiagnosticsTitle => '资源诊断';

  @override
  String get animationProjectRecheckAssets => '重新检查';

  @override
  String get animationProjectCheckingFrameAssets => '正在检查帧资源';

  @override
  String get animationProjectCheckingFrameAssetsMessage => '正在验证工程引用的帧文件。';

  @override
  String get animationProjectAssetCheckFailed => '资源检查失败';

  @override
  String get animationProjectNoAssetCheckResult => '没有可用的检查结果';

  @override
  String get animationProjectAssetsHealthy => '资源完整';

  @override
  String animationProjectAssetsHealthyMessage(
    int totalCount,
    int referencedCount,
  ) {
    return '$totalCount 个帧资源可用，$referencedCount 个被时间轴引用。';
  }

  @override
  String get animationProjectMissingAssetsTitle => '缺失资源';

  @override
  String get animationProjectRepairableTitle => '工程可修复';

  @override
  String animationProjectMissingTimelineAssetsMessage(int count) {
    return '$count 个被时间轴引用的资源缺失，预览和导出会失败。';
  }

  @override
  String get animationProjectMissingUnusedAssetsMessage =>
      '发现未引用的缺失资源，当前预览不受影响。';

  @override
  String get animationProjectRepairableMessage => '发现可自动修复的工程一致性问题。';

  @override
  String animationProjectAssetPreviewExtraCount(int count) {
    return ' 等 $count 个';
  }

  @override
  String animationProjectUnusedAssetsDetail(int count) {
    return '未引用资源 $count 个';
  }

  @override
  String animationProjectInvalidFrameRefsDetail(int count) {
    return '空帧引用 $count 个';
  }

  @override
  String animationProjectAutoRepairableCount(int count) {
    return '可自动修复 $count 项';
  }

  @override
  String get animationProjectAutoRepairAction => '自动修复可处理项';

  @override
  String get animationProjectMissingRecordedPath => '未记录路径';

  @override
  String animationProjectAssetIssueTimelineRefs(Object message, int count) {
    return '$message · 时间轴引用 $count 次';
  }

  @override
  String get animationProjectRebindAsset => '重新绑定';

  @override
  String get animationProjectTracksSectionTitle => '轨道';

  @override
  String get animationProjectMoveTrackUp => '上移轨道';

  @override
  String get animationProjectMoveTrackDown => '下移轨道';

  @override
  String get animationProjectDuplicateTrack => '复制轨道';

  @override
  String get animationProjectDeleteTrack => '删除轨道';

  @override
  String get animationProjectHideTrack => '隐藏轨道';

  @override
  String get animationProjectShowTrack => '显示轨道';

  @override
  String get animationProjectUnlockTrack => '解锁轨道';

  @override
  String get animationProjectLockTrack => '锁定轨道';

  @override
  String get animationProjectTrackNameLabel => '轨道名称';

  @override
  String get animationProjectFrameDelayLabel => '帧时长';

  @override
  String animationProjectFrameCount(int count) {
    return '$count 帧';
  }

  @override
  String get animationProjectSelectTrackFirst => '先选择一条轨道';

  @override
  String get animationProjectInsertBlankFrame => '插入空白帧';

  @override
  String get animationProjectInsertImageFrame => '插入图片帧';

  @override
  String get animationProjectTrackLockedNoFrames => '轨道已锁定，当前没有序列帧';

  @override
  String get animationProjectTrackNoFrames => '当前轨道没有序列帧';

  @override
  String get animationProjectSequenceTimelineTitle => '序列帧时间轴';

  @override
  String animationProjectTrackFrameStatus(Object trackName, int frameCount) {
    return '$trackName · $frameCount 帧';
  }

  @override
  String get animationProjectSingleFrameDelay => '单帧时长';

  @override
  String animationProjectCurrentFrame(int index) {
    return '当前帧 $index';
  }

  @override
  String get animationProjectReplaceFrame => '替换帧';

  @override
  String get animationProjectClearFrame => '清空帧';

  @override
  String get animationProjectPixelateCurrentFrame => '像素化当前帧';

  @override
  String get animationProjectPixelateFrame => '像素化帧';

  @override
  String get animationProjectDuplicateFrame => '复制帧';

  @override
  String get animationProjectDeleteFrame => '删除帧';

  @override
  String get animationProjectSingleFrameTransform => '单帧变换';

  @override
  String get animationProjectFlipHorizontal => '水平翻转';

  @override
  String get animationProjectFlipVertical => '垂直翻转';

  @override
  String get animationProjectResetFrameTransform => '重置单帧变换';

  @override
  String get animationProjectOpacity => '不透明度';

  @override
  String get apiConfigDeleteLastMessage => '至少需要保留一个接口配置';

  @override
  String get batchGenerationMissingApiKey => '请先在接口配置页填写 API Key';

  @override
  String get batchGenerationMissingModel => '请先在接口配置页获取模型列表并选择模型';

  @override
  String get batchGenerationMissingPrompts => '请先填写至少一行批量提示词';

  @override
  String batchGenerationJobsAdded(int count) {
    return '已拆分并加入 $count 个批量任务';
  }

  @override
  String batchGenerationAutoRetryMessage(
    int retryAttempt,
    int maxRetryAttempts,
    Object errorMessage,
  ) {
    return '上次失败，已移到队尾自动重试 ($retryAttempt/$maxRetryAttempts)：$errorMessage';
  }

  @override
  String get batchGenerationRetryBlockedRunning => '队列运行中，请等待当前队列停止后再重试失败任务';

  @override
  String get batchGenerationNoFailedJobsToRetry => '没有失败任务可重试';

  @override
  String batchGenerationFailedJobsRequeued(int count) {
    return '已将 $count 个失败任务重新加入等待队列';
  }

  @override
  String get batchGenerationFailedJobRequeued => '已将失败任务重新加入等待队列';

  @override
  String batchGenerationQueuePaused(int count) {
    return '队列已暂停，可继续执行剩余 $count 个任务';
  }

  @override
  String get batchGenerationQueueStopped => '批量队列已停止';

  @override
  String get batchGenerationPauseRequested => '已暂停后续任务；正在请求的一批会等待接口返回';

  @override
  String get batchGenerationResumed => '已恢复后续任务';

  @override
  String get batchGenerationNoQueuedJobsToCancel => '没有等待中的任务可取消';

  @override
  String get batchGenerationUserCanceledQueuedJob => '用户取消等待任务';

  @override
  String get batchGenerationCancelQueuedRunningHint => '；当前正在请求的一批会等待接口返回';

  @override
  String batchGenerationQueuedJobsCanceled(int count, Object runningHint) {
    return '已取消 $count 个等待任务$runningHint';
  }

  @override
  String batchGenerationResultTitle(int index) {
    return '批量结果 $index';
  }

  @override
  String get batchGenerationSourceName => '批量生成';

  @override
  String get batchGenerationLibraryTitlePrefix => '批量生图';

  @override
  String get batchGenerationLibrarySource => '批量生成';

  @override
  String get backgroundTransparencyNoEdgeDetected => '没有检测到可透明化的边缘背景，可尝试调高容差';

  @override
  String batchGenerationTransparentImageSaved(Object title, int count) {
    return '已生成透明背景图片：$title · 透明化 $count 个像素';
  }

  @override
  String backgroundTransparencyFailed(Object error) {
    return '背景转透明失败：$error';
  }

  @override
  String copyImageFailed(Object error) {
    return '复制图片失败：$error';
  }

  @override
  String get retryGenerationAction => '重试生成';

  @override
  String get previewPanelTitle => '结果预览';

  @override
  String get previewGeneratingImage => '正在生成图片';

  @override
  String get previewGenerationFailed => '生成失败';

  @override
  String get previewEmptyMessage => '生成后的图片会显示在这里';

  @override
  String previewResultTitle(int index) {
    return '结果 $index';
  }

  @override
  String get copyImageTooltip => '复制图片';

  @override
  String get exportImageTooltip => '导出图片';

  @override
  String get makeBackgroundTransparentTooltip => '背景转透明';

  @override
  String previewPendingImage(int index) {
    return '等待 $index';
  }

  @override
  String previewImageLoadFailed(Object error) {
    return '图片加载失败：$error';
  }

  @override
  String get firstRunSetupTitle => '完成首次接口配置';

  @override
  String get firstRunSetupMessage =>
      '开始生成前需要先配置供应商、Base URL、API Key 和模型。你可以现在打开接口配置页，也可以稍后从侧边栏的设置入口进入。';

  @override
  String get firstRunSetupLater => '稍后配置';

  @override
  String get firstRunSetupOpenApiSettings => '打开接口配置';

  @override
  String get resetDefaultsTitle => '恢复默认表单';

  @override
  String get resetDefaultsMessage =>
      '会清空当前接口配置、提示词、预览结果和本地临时选择，作品库中的已保存文件不会被删除。';

  @override
  String get resetDefaultsAction => '恢复默认';

  @override
  String spriteSheetReplaceFrameTitle(int frameNumber) {
    return '确认替换第 $frameNumber 帧';
  }

  @override
  String spriteSheetReplaceFrameTarget(
    int row,
    int column,
    int width,
    int height,
    Object fitLabel,
  ) {
    return '目标位置：第 $row 行 · 第 $column 列 · $width x $height · $fitLabel';
  }

  @override
  String get spriteSheetOriginalFrame => '原帧';

  @override
  String get spriteSheetPatchFrame => '单帧图片';

  @override
  String get spriteSheetReplacementResult => '替换后';

  @override
  String get spriteSheetConfirmReplace => '确认替换';

  @override
  String get imageLabel => '图片';

  @override
  String get imageLibraryStateNoAvailableImages => '作品库还没有可用图片';

  @override
  String get imageLibraryStateSpriteSheetMissingGrid =>
      '该 Sprite Sheet 缺少行列元数据，无法切片';

  @override
  String get imageLibraryStateSpriteSheetMissingGroup =>
      '该 Sprite Sheet 缺少 groupId，无法保存切片';

  @override
  String imageLibraryGifPrompt(int count) {
    return '$count 张图片合成';
  }

  @override
  String get imageLibrarySpriteSheetGifTitle => 'Sprite Sheet GIF';

  @override
  String get imageLibraryAnimationProjectGifTitle => '动画工程 GIF';

  @override
  String get imageLibraryAnimationTrackGifTitle => '动画轨道 GIF';

  @override
  String imageLibraryAnimationProjectPrompt(
    int trackCount,
    int frameCount,
    int width,
    int height,
  ) {
    return '$trackCount 条轨道 · $frameCount 帧 · $width x $height';
  }

  @override
  String get imageLibraryExportedSpriteSheetTitle => '导出 Sprite Sheet';

  @override
  String get imageLibraryExportedSpriteSheetSource => 'Sprite Sheet 导出';

  @override
  String get imageLibraryAnimationProjectSpriteSheetTitle =>
      '动画工程 Sprite Sheet';

  @override
  String get imageLibraryAnimationProjectSpriteSheetSource => '动画工程导出';

  @override
  String imageLibrarySpriteSheetPrompt(int rows, int columns) {
    return '$rows x $columns';
  }

  @override
  String get imageLibraryEditedSpriteSheetTitle => '编辑后的 Sprite Sheet';

  @override
  String imageLibraryEditedSpriteSheetPrompt(
    int frameIndex,
    int rows,
    int columns,
  ) {
    return '替换第 $frameIndex 帧 · $rows x $columns';
  }

  @override
  String imageLibrarySpriteFrameTitle(Object sheetTitle, int frameIndex) {
    return '$sheetTitle · 帧 $frameIndex';
  }

  @override
  String imageLibraryStateSaveSliceHistory(Object title, int index) {
    return '保存「$title」第 $index 帧';
  }

  @override
  String imageLibraryStateSaveSliceFailed(Object error) {
    return '保存切片失败：$error';
  }

  @override
  String imageLibraryStateSaveSlicesHistory(Object title, int count) {
    return '保存「$title」$count 个切片帧';
  }

  @override
  String imageLibraryStateSavedSlicesMessage(int count) {
    return '已保存 $count 个切片帧到作品集';
  }

  @override
  String get imageLibraryStateItemMissingGrid => '该作品缺少行列元数据，无法切片';

  @override
  String imageLibraryStateEditMetadataHistory(Object title) {
    return '编辑「$title」';
  }

  @override
  String get imageLibraryStateMetadataUpdated => '作品信息已更新';

  @override
  String get imageLibraryStatePathCopied => '作品路径已复制';

  @override
  String get imageLibraryStateFileMissing => '作品文件不存在';

  @override
  String get imageLibraryStateImageCopied => '图片已复制到剪贴板';

  @override
  String get imageLibraryStateImagePathCopied => '当前平台暂不支持直接复制图片，已复制图片路径';

  @override
  String imageLibraryStateAnimationProjectExported(Object fileName) {
    return '动画工程文件已导出：$fileName';
  }

  @override
  String imageLibraryStateImageExported(Object fileName) {
    return '图片已导出：$fileName';
  }

  @override
  String get imageLibraryStateSelectItemsToExport => '请先选择要导出的作品';

  @override
  String get imageLibraryStateExportHere => '导出到这里';

  @override
  String get imageLibraryStateSelectedFilesMissing => '选中的作品文件都不存在';

  @override
  String imageLibraryStateSkippedMissingFiles(int count) {
    return '，跳过 $count 个缺失文件';
  }

  @override
  String imageLibraryStateExportedSelected(int count, Object skipped) {
    return '已导出 $count 个作品$skipped';
  }

  @override
  String imageLibraryStateExportSelectedFailed(Object error) {
    return '导出已选作品失败：$error';
  }

  @override
  String get imageLibraryStateLocationOpened => '已打开作品所在位置';

  @override
  String get imageLibraryStateDirectoryMissing => '作品所在目录不存在';

  @override
  String get imageLibraryStateDirectoryPathCopied => '已复制作品目录路径';

  @override
  String get imageLibraryStateDirectoryOpenFailedPathCopied =>
      '无法打开目录，已复制作品目录路径';

  @override
  String get imageLibraryStateNotAnimationProject => '这个作品不是动画工程';

  @override
  String imageLibraryStateAnimationProjectFileMissingDetail(Object path) {
    return '动画工程文件不存在：$path';
  }

  @override
  String get imageLibraryStateAnimationProjectFileMissing => '动画工程文件不存在';

  @override
  String imageLibraryStateOpenAnimationProjectHistory(Object title) {
    return '打开动画工程「$title」';
  }

  @override
  String imageLibraryStateAnimationProjectOpened(Object title) {
    return '已打开动画工程：$title';
  }

  @override
  String imageLibraryStateOpenAnimationProjectFailed(Object error) {
    return '打开动画工程失败：$error';
  }

  @override
  String imageLibraryStateTransparentBackgroundTitle(Object title) {
    return '透明背景：$title';
  }

  @override
  String imageLibraryStateTransparentBackgroundPrompt(
    int tolerance,
    int width,
    int height,
  ) {
    return '背景转透明 · 容差 $tolerance · $width x $height';
  }

  @override
  String get imageLibraryStateNotProcessableStaticImage => '该作品不是可处理的静态图片';

  @override
  String imageLibraryStateDeleteOneHistory(Object title) {
    return '删除「$title」';
  }

  @override
  String imageLibraryStateDeleteManyHistory(int count) {
    return '删除 $count 个作品';
  }

  @override
  String get imageLibraryStateDeletedOne => '作品已删除';

  @override
  String imageLibraryStateDeletedMany(int count) {
    return '已删除 $count 个作品';
  }

  @override
  String get imageLibraryStateUnsupportedEditorSource => '这类作品不能作为图片编辑源';

  @override
  String imageLibraryStateOpenedInEditor(Object title) {
    return '已在图片编辑器中打开：$title';
  }

  @override
  String imageLibraryStateOpenInEditorHistory(Object title) {
    return '在编辑器中打开「$title」';
  }

  @override
  String get imageLibraryStateNoReusableGeneration => '这个作品没有可复用的生成参数';

  @override
  String imageLibraryStateReuseGenerationHistory(Object title) {
    return '复用「$title」生成参数';
  }

  @override
  String get imageLibraryStateGenerationLoadedNeedsApiConfig =>
      '已载入作品参数，接口配置需要手动选择';

  @override
  String get imageLibraryStateGenerationLoaded => '已载入作品参数';

  @override
  String get imageLibraryStateNoCopyableGeneration => '这个作品没有可复制的生成参数';

  @override
  String get imageLibraryStateGenerationCopied => '作品参数已复制';

  @override
  String localSettingsStateAdjustSizeHistory(Object size) {
    return '调整分辨率为 $size';
  }

  @override
  String localSettingsStateAdjustImageCountHistory(int count) {
    return '调整生成数量为 $count 张';
  }

  @override
  String get localSettingsStateEditPositivePromptHistory => '修改正向提示词';

  @override
  String get localSettingsStateEditAnimationPromptHistory => '修改动画工程提示词';

  @override
  String get localSettingsStateEditNegativePromptHistory => '修改排除描述';

  @override
  String localSettingsStateAdjustQualityHistory(Object label) {
    return '调整质量为 $label';
  }

  @override
  String localSettingsStateAdjustBackgroundHistory(Object label) {
    return '调整背景为 $label';
  }

  @override
  String localSettingsStateAdjustOutputFormatHistory(Object label) {
    return '调整输出格式为 $label';
  }

  @override
  String localSettingsStateAdjustOutputCompressionHistory(int value) {
    return '调整输出压缩率为 $value%';
  }

  @override
  String localSettingsStateAdjustModerationHistory(Object label) {
    return '调整审核强度为 $label';
  }

  @override
  String localSettingsStateAdjustInputFidelityHistory(Object label) {
    return '调整参考图保真度为 $label';
  }

  @override
  String get localSettingsStateEditFinalUserHistory => '修改最终用户 ID';

  @override
  String get localSettingsStateAdjustAdvancedSettingsHistory => '调整高级输出参数';

  @override
  String localSettingsStateTextPresetName(int index) {
    return '文本生图 $index';
  }

  @override
  String localSettingsStateAnimationPresetName(int index) {
    return '动画工程 $index';
  }

  @override
  String localSettingsStatePresetSaved(Object name) {
    return '已保存预设：$name';
  }

  @override
  String localSettingsStateApplyPresetHistory(Object name) {
    return '应用预设：$name';
  }

  @override
  String localSettingsStatePresetApplied(Object name) {
    return '已应用预设：$name';
  }

  @override
  String localSettingsStatePresetDeleted(Object name) {
    return '已删除预设：$name';
  }

  @override
  String localSettingsStateCleanupDone(int count, Object size) {
    return '已清理 $count 个文件，释放 $size';
  }

  @override
  String localSettingsStateCleanupFailed(Object error) {
    return '清理失败：$error';
  }

  @override
  String localSettingsStateLibraryArchiveExported(
    int count,
    Object skipped,
    Object fileName,
  ) {
    return '已导出 $count 个作品$skipped：$fileName';
  }

  @override
  String localSettingsStateExportLibraryFailed(Object error) {
    return '导出作品库失败：$error';
  }

  @override
  String get localSettingsStateImportLibraryHistory => '导入作品库';

  @override
  String localSettingsStateSkippedInvalidItems(int count) {
    return '，跳过 $count 个无效条目';
  }

  @override
  String localSettingsStateLibraryArchiveImported(int count, Object skipped) {
    return '已导入 $count 个作品$skipped';
  }

  @override
  String localSettingsStateImportLibraryFailed(Object error) {
    return '导入作品库失败：$error';
  }
}
