import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('zh')];

  /// 应用标题
  ///
  /// In zh, this message translates to:
  /// **'FeatherCanvas Studio'**
  String get appTitle;

  /// 导航：文本生图工作区
  ///
  /// In zh, this message translates to:
  /// **'文本生图'**
  String get navImageGeneration;

  /// 导航：批量生成工作区
  ///
  /// In zh, this message translates to:
  /// **'批量生成'**
  String get navBatchGeneration;

  /// 导航：动画工程工作区
  ///
  /// In zh, this message translates to:
  /// **'动画工程'**
  String get navAnimationProject;

  /// 导航：图片编辑工作区
  ///
  /// In zh, this message translates to:
  /// **'图片编辑器'**
  String get navImageEditor;

  /// 导航：像素画编辑工作区
  ///
  /// In zh, this message translates to:
  /// **'像素画编辑'**
  String get navPixelArtEditor;

  /// 导航：GIF 合成工作区
  ///
  /// In zh, this message translates to:
  /// **'GIF 合成'**
  String get navGifComposer;

  /// 导航：作品库工作区
  ///
  /// In zh, this message translates to:
  /// **'作品库'**
  String get navImageLibrary;

  /// 导航：API 配置工作区
  ///
  /// In zh, this message translates to:
  /// **'接口配置'**
  String get navApiSettings;

  /// 导航：本地设置工作区
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navLocalSettings;

  /// 导航：展开侧栏按钮
  ///
  /// In zh, this message translates to:
  /// **'展开侧栏'**
  String get navExpandSidebar;

  /// 导航：收起侧栏按钮
  ///
  /// In zh, this message translates to:
  /// **'收起侧栏'**
  String get navCollapseSidebar;

  /// 导航分组：生成（文本生图、批量、动画工程）
  ///
  /// In zh, this message translates to:
  /// **'生成'**
  String get navGroupGenerate;

  /// 导航分组：编辑（图片、像素画、GIF）
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get navGroupEdit;

  /// 导航分组：资产（作品库）
  ///
  /// In zh, this message translates to:
  /// **'资产'**
  String get navGroupAssets;

  /// 导航：设置齿轮菜单 tooltip
  ///
  /// In zh, this message translates to:
  /// **'设置菜单'**
  String get navSettingsMenu;

  /// 外观设置区块标题
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearanceSectionTitle;

  /// 外观设置区块说明
  ///
  /// In zh, this message translates to:
  /// **'选择应用主题。深色模式适合长时间编辑作业。'**
  String get appearanceSectionDescription;

  /// 主题模式：跟随系统
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeModeSystem;

  /// 主题模式：浅色
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeModeLight;

  /// 主题模式：深色
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeModeDark;

  /// 通用显示标签：自动
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get displayLabelAuto;

  /// 通用显示标签：低
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get displayLabelLow;

  /// 通用显示标签：中
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get displayLabelMedium;

  /// 通用显示标签：高
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get displayLabelHigh;

  /// 通用显示标签：标准
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get displayLabelStandard;

  /// 通用显示标签：高清
  ///
  /// In zh, this message translates to:
  /// **'高清'**
  String get displayLabelHd;

  /// 通用显示标签：透明
  ///
  /// In zh, this message translates to:
  /// **'透明'**
  String get displayLabelTransparent;

  /// 通用显示标签：不透明
  ///
  /// In zh, this message translates to:
  /// **'不透明'**
  String get displayLabelOpaque;

  /// 历史：撤销按钮
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get historyUndo;

  /// 历史：重做按钮
  ///
  /// In zh, this message translates to:
  /// **'重做'**
  String get historyRedo;

  /// 历史：撤销按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'暂无可撤销操作'**
  String get historyUndoUnavailable;

  /// 历史：重做按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'暂无可重做操作'**
  String get historyRedoUnavailable;

  /// 历史：菜单标题（有历史时）
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get historyMenuTitle;

  /// 历史：菜单标题（无历史时）
  ///
  /// In zh, this message translates to:
  /// **'暂无历史'**
  String get historyMenuEmpty;

  /// 历史：操作执行中提示
  ///
  /// In zh, this message translates to:
  /// **'历史操作执行中'**
  String get historyApplying;

  /// 历史：撤销到菜单标题
  ///
  /// In zh, this message translates to:
  /// **'撤销到'**
  String get historyUndoTo;

  /// 历史：重做到菜单标题
  ///
  /// In zh, this message translates to:
  /// **'重做到'**
  String get historyRedoTo;

  /// 历史：下一步标签
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get historyNextStep;

  /// 历史：步数标签
  ///
  /// In zh, this message translates to:
  /// **'{count} 步'**
  String historyStepCount(int count);

  /// 历史：撤销成功提示
  ///
  /// In zh, this message translates to:
  /// **'已撤销：{label}'**
  String historyUndoSuccess(Object label);

  /// 历史：多步撤销成功提示
  ///
  /// In zh, this message translates to:
  /// **'已撤销 {completed} 步：{label}'**
  String historyUndoMultiple(int completed, Object label);

  /// 历史：撤销失败提示
  ///
  /// In zh, this message translates to:
  /// **'撤销失败：{error}'**
  String historyUndoFailed(Object error);

  /// 历史：重做成功提示
  ///
  /// In zh, this message translates to:
  /// **'已重做：{label}'**
  String historyRedoSuccess(Object label);

  /// 历史：多步重做成功提示
  ///
  /// In zh, this message translates to:
  /// **'已重做 {completed} 步：{label}'**
  String historyRedoMultiple(int completed, Object label);

  /// 历史：重做失败提示
  ///
  /// In zh, this message translates to:
  /// **'重做失败：{error}'**
  String historyRedoFailed(Object error);

  /// 工作区分隔条提示
  ///
  /// In zh, this message translates to:
  /// **'拖动调整宽度，双击复位'**
  String get splitHandleTooltip;

  /// 本地设置：快捷键速查表区块标题
  ///
  /// In zh, this message translates to:
  /// **'快捷键'**
  String get shortcutsSectionTitle;

  /// 本地设置：快捷键速查表说明文案
  ///
  /// In zh, this message translates to:
  /// **'全局快捷键在所有工作区可用，用于撤销和重做最近一次操作。'**
  String get shortcutsSectionDescription;

  /// 快捷键：撤销
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get shortcutLabelUndo;

  /// 快捷键：重做
  ///
  /// In zh, this message translates to:
  /// **'重做'**
  String get shortcutLabelRedo;

  /// 快捷键：重做（备选 Ctrl+Shift+Z）
  ///
  /// In zh, this message translates to:
  /// **'重做（备选）'**
  String get shortcutLabelRedoAlt;

  /// 本地设置工作区标题
  ///
  /// In zh, this message translates to:
  /// **'本地设置'**
  String get localSettingsWorkspaceTitle;

  /// 本地设置工作区说明
  ///
  /// In zh, this message translates to:
  /// **'管理本机保存的默认生成参数、接口配置入口和恢复默认操作'**
  String get localSettingsWorkspaceDescription;

  /// 本地设置：状态区块标题
  ///
  /// In zh, this message translates to:
  /// **'本地状态'**
  String get localSettingsStatusSectionTitle;

  /// 本地设置：接口配置数量标签
  ///
  /// In zh, this message translates to:
  /// **'接口配置'**
  String get localSettingsStatusApiConfigs;

  /// 本地设置：作品库记录数量标签
  ///
  /// In zh, this message translates to:
  /// **'作品库记录'**
  String get localSettingsStatusLibraryItems;

  /// 本地设置：当前预览结果数量标签
  ///
  /// In zh, this message translates to:
  /// **'当前预览结果'**
  String get localSettingsStatusPreviewImages;

  /// 接口配置数量
  ///
  /// In zh, this message translates to:
  /// **'{count} 个'**
  String countApiConfigs(int count);

  /// 作品库记录数量
  ///
  /// In zh, this message translates to:
  /// **'{count} 条'**
  String countLibraryItems(int count);

  /// 图片数量
  ///
  /// In zh, this message translates to:
  /// **'{count} 张'**
  String countImages(int count);

  /// 本地设置：默认生成设置区块标题
  ///
  /// In zh, this message translates to:
  /// **'默认生成设置'**
  String get localSettingsDefaultsSectionTitle;

  /// 本地设置：默认生成设置区块说明
  ///
  /// In zh, this message translates to:
  /// **'这些值会保存在本机，并作为文本生图、动画工程等工作区的默认表单状态。'**
  String get localSettingsDefaultsSectionDescription;

  /// 本地设置：默认正向提示词字段标签
  ///
  /// In zh, this message translates to:
  /// **'默认正向提示词'**
  String get localSettingsDefaultPromptLabel;

  /// 本地设置：默认正向提示词字段提示
  ///
  /// In zh, this message translates to:
  /// **'新会话或恢复默认后使用的正向提示词'**
  String get localSettingsDefaultPromptHint;

  /// 本地设置：默认负向提示词字段标签
  ///
  /// In zh, this message translates to:
  /// **'默认负向提示词'**
  String get localSettingsDefaultNegativePromptLabel;

  /// 本地设置：默认负向提示词字段提示
  ///
  /// In zh, this message translates to:
  /// **'可选，会合并到 prompt 中'**
  String get localSettingsDefaultNegativePromptHint;

  /// 本地设置：默认生成数量字段标签
  ///
  /// In zh, this message translates to:
  /// **'默认生成数量'**
  String get localSettingsDefaultImageCountLabel;

  /// 图片数量后缀
  ///
  /// In zh, this message translates to:
  /// **'张'**
  String get imageCountSuffix;

  /// 本地设置：默认生成数量字段说明
  ///
  /// In zh, this message translates to:
  /// **'超过 {maxCount} 张会自动拆成多次请求'**
  String localSettingsDefaultImageCountHelper(int maxCount);

  /// 本地设置：常用预设区块标题
  ///
  /// In zh, this message translates to:
  /// **'常用预设'**
  String get localSettingsPresetSectionTitle;

  /// 本地设置：保存文本预设按钮
  ///
  /// In zh, this message translates to:
  /// **'保存文本预设'**
  String get localSettingsSaveTextPreset;

  /// 本地设置：保存动画工程预设按钮
  ///
  /// In zh, this message translates to:
  /// **'保存动画工程预设'**
  String get localSettingsSaveAnimationPreset;

  /// 本地设置：保存 GIF 预设按钮
  ///
  /// In zh, this message translates to:
  /// **'保存 GIF 预设'**
  String get localSettingsSaveGifPreset;

  /// 预设列表：应用预设按钮
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get applyPreset;

  /// 预设列表：应用指定预设按钮语义标签
  ///
  /// In zh, this message translates to:
  /// **'应用预设：{name}'**
  String applyPresetAction(Object name);

  /// 预设列表：删除预设 tooltip
  ///
  /// In zh, this message translates to:
  /// **'删除预设'**
  String get deletePresetTooltip;

  /// 预设列表：删除指定预设按钮语义标签
  ///
  /// In zh, this message translates to:
  /// **'删除预设：{name}'**
  String deletePresetAction(Object name);

  /// 文本生图预设摘要
  ///
  /// In zh, this message translates to:
  /// **'{size} · {imageCount} 张'**
  String localGenerationPresetSummary(Object size, int imageCount);

  /// 动画工程预设摘要
  ///
  /// In zh, this message translates to:
  /// **'{size} · {rows} x {columns}'**
  String spriteSheetPresetSummary(Object size, int rows, int columns);

  /// GIF 预设摘要：无限循环
  ///
  /// In zh, this message translates to:
  /// **'无限循环'**
  String get gifLoopInfinite;

  /// GIF 预设摘要：播放次数
  ///
  /// In zh, this message translates to:
  /// **'播放 {count} 次'**
  String gifLoopCount(int count);

  /// GIF 预设摘要
  ///
  /// In zh, this message translates to:
  /// **'{delayMs} ms · {loopLabel}'**
  String gifPresetSummary(int delayMs, Object loopLabel);

  /// 本地设置：作品库迁移区块标题
  ///
  /// In zh, this message translates to:
  /// **'作品库迁移'**
  String get localSettingsLibraryMigrationSectionTitle;

  /// 本地设置：作品库迁移区块说明
  ///
  /// In zh, this message translates to:
  /// **'把作品库元数据和本地图片打包为 ZIP，或从 ZIP 导入到当前作品库。'**
  String get localSettingsLibraryMigrationSectionDescription;

  /// 本地设置：作品库导出进行中按钮
  ///
  /// In zh, this message translates to:
  /// **'导出中'**
  String get localSettingsExportingLibrary;

  /// 本地设置：导出作品库按钮
  ///
  /// In zh, this message translates to:
  /// **'导出作品库'**
  String get localSettingsExportLibrary;

  /// 本地设置：作品库导出中按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'作品库正在导出，完成后可继续操作'**
  String get localSettingsLibraryExportBusyUnavailable;

  /// 本地设置：作品库为空时导出按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'作品库为空，暂无可导出的内容'**
  String get localSettingsLibraryExportEmptyUnavailable;

  /// 本地设置：作品库导入进行中按钮
  ///
  /// In zh, this message translates to:
  /// **'导入中'**
  String get localSettingsImportingLibrary;

  /// 本地设置：导入作品库按钮
  ///
  /// In zh, this message translates to:
  /// **'导入作品库'**
  String get localSettingsImportLibrary;

  /// 本地设置：作品库导入中按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'作品库正在导入，完成后可继续操作'**
  String get localSettingsLibraryImportBusyUnavailable;

  /// 本地设置：配置入口区块标题
  ///
  /// In zh, this message translates to:
  /// **'配置入口'**
  String get localSettingsConfigEntrySectionTitle;

  /// 本地设置：配置入口区块说明
  ///
  /// In zh, this message translates to:
  /// **'接口地址、密钥和模型列表统一在接口配置页维护。'**
  String get localSettingsConfigEntrySectionDescription;

  /// 本地设置：打开接口配置按钮
  ///
  /// In zh, this message translates to:
  /// **'打开接口配置'**
  String get localSettingsOpenApiSettings;

  /// 本地设置：存储清理区块标题
  ///
  /// In zh, this message translates to:
  /// **'存储清理'**
  String get localSettingsStorageCleanupSectionTitle;

  /// 本地设置：存储清理区块说明
  ///
  /// In zh, this message translates to:
  /// **'清理作品库不再引用的生成文件，以及临时参考图缓存。不会删除作品库仍在使用的文件。'**
  String get localSettingsStorageCleanupSectionDescription;

  /// 本地设置：存储清理进行中按钮
  ///
  /// In zh, this message translates to:
  /// **'清理中'**
  String get localSettingsCleaningStorage;

  /// 本地设置：清理未引用文件按钮
  ///
  /// In zh, this message translates to:
  /// **'清理未引用文件'**
  String get localSettingsCleanUnusedFiles;

  /// 本地设置：存储清理中按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'正在清理存储，完成后可继续操作'**
  String get localSettingsStorageCleanupBusyUnavailable;

  /// 本地设置：恢复默认区块标题
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get localSettingsResetSectionTitle;

  /// 本地设置：恢复默认区块说明
  ///
  /// In zh, this message translates to:
  /// **'仅在需要重新开始配置时使用。恢复前会再次确认。'**
  String get localSettingsResetSectionDescription;

  /// 本地设置：恢复默认表单按钮
  ///
  /// In zh, this message translates to:
  /// **'恢复默认表单'**
  String get localSettingsResetForm;

  /// 接口配置工作区标题
  ///
  /// In zh, this message translates to:
  /// **'接口配置'**
  String get apiSettingsWorkspaceTitle;

  /// 接口配置工作区说明
  ///
  /// In zh, this message translates to:
  /// **'集中管理不同供应商的接口，其他功能页只需要选择这里保存的配置'**
  String get apiSettingsWorkspaceDescription;

  /// 接口配置选择器字段标签
  ///
  /// In zh, this message translates to:
  /// **'接口配置'**
  String get apiConfigLabel;

  /// 接口配置选择器：管理配置 tooltip
  ///
  /// In zh, this message translates to:
  /// **'管理接口配置'**
  String get manageApiConfigTooltip;

  /// 接口配置面板标题
  ///
  /// In zh, this message translates to:
  /// **'接口配置'**
  String get apiSettingsPanelTitle;

  /// 接口配置面板：新增配置 tooltip
  ///
  /// In zh, this message translates to:
  /// **'新增配置'**
  String get apiSettingsAddConfigTooltip;

  /// 接口配置面板：删除当前配置 tooltip
  ///
  /// In zh, this message translates to:
  /// **'删除当前配置'**
  String get apiSettingsDeleteConfigTooltip;

  /// 接口配置面板：删除当前配置按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'至少需要保留一个接口配置'**
  String get apiSettingsDeleteConfigUnavailable;

  /// 接口配置：请求超时字段标签
  ///
  /// In zh, this message translates to:
  /// **'请求超时（秒）'**
  String get apiTimeoutLabel;

  /// 接口配置：请求超时字段说明
  ///
  /// In zh, this message translates to:
  /// **'默认 {defaultSeconds} 秒，范围 {minSeconds}–{maxSeconds}；image-2 等慢模型可调大'**
  String apiTimeoutHelper(int defaultSeconds, int minSeconds, int maxSeconds);

  /// 接口配置：接口名称字段标签
  ///
  /// In zh, this message translates to:
  /// **'接口名称'**
  String get apiConfigNameLabel;

  /// 接口配置：接口名称字段提示
  ///
  /// In zh, this message translates to:
  /// **'例如 OpenAI 官方、内网代理、备用接口'**
  String get apiConfigNameHint;

  /// 接口配置：切换接口配置 tooltip
  ///
  /// In zh, this message translates to:
  /// **'切换接口配置'**
  String get apiConfigSwitchTooltip;

  /// 接口配置：供应商字段标签
  ///
  /// In zh, this message translates to:
  /// **'供应商'**
  String get apiProviderLabel;

  /// 接口配置：OpenAI 官方供应商标签
  ///
  /// In zh, this message translates to:
  /// **'OpenAI 官方'**
  String get apiProviderOfficial;

  /// 接口配置：OpenAI 兼容供应商标签
  ///
  /// In zh, this message translates to:
  /// **'OpenAI 兼容'**
  String get apiProviderCompatible;

  /// 接口配置：OpenAI 官方供应商说明
  ///
  /// In zh, this message translates to:
  /// **'发送完整 GPT Image 参数（quality/background/output_format 等）'**
  String get apiProviderOfficialDescription;

  /// 接口配置：OpenAI 兼容供应商说明
  ///
  /// In zh, this message translates to:
  /// **'只发送 model/prompt/size/n，避免兼容层 502'**
  String get apiProviderCompatibleDescription;

  /// 接口配置：Gemini 供应商说明
  ///
  /// In zh, this message translates to:
  /// **'使用 Gemini generateContent 协议，支持文本生图和带参考图编辑'**
  String get apiProviderGeminiDescription;

  /// 接口配置：保存中按钮状态
  ///
  /// In zh, this message translates to:
  /// **'保存中'**
  String get apiSaving;

  /// 接口配置：保存配置按钮
  ///
  /// In zh, this message translates to:
  /// **'保存配置'**
  String get apiSaveConfig;

  /// 接口配置：测试中按钮状态
  ///
  /// In zh, this message translates to:
  /// **'测试中'**
  String get apiTesting;

  /// 接口配置：测试接口按钮
  ///
  /// In zh, this message translates to:
  /// **'测试接口'**
  String get apiTestConfig;

  /// 接口配置：基础测试按钮 tooltip
  ///
  /// In zh, this message translates to:
  /// **'只发送 model/prompt/size/n，先确认接口本身可用'**
  String get apiBasicTestTooltip;

  /// 接口配置：基础测试按钮
  ///
  /// In zh, this message translates to:
  /// **'基础测试'**
  String get apiBasicTest;

  /// 接口配置：测试接口前缺少 API Key
  ///
  /// In zh, this message translates to:
  /// **'请先填写 API Key'**
  String get apiTestApiKeyRequired;

  /// 接口配置：基础测试成功提示
  ///
  /// In zh, this message translates to:
  /// **'基础测试通过：接口可用，可尝试切换到完整测试验证高级参数'**
  String get apiBasicTestSuccess;

  /// 接口配置：完整测试成功提示
  ///
  /// In zh, this message translates to:
  /// **'接口测试成功，已收到图片数据'**
  String get apiTestSuccess;

  /// 接口配置：基础测试失败前缀
  ///
  /// In zh, this message translates to:
  /// **'基础测试失败'**
  String get apiBasicTestFailed;

  /// 接口配置：完整测试失败前缀
  ///
  /// In zh, this message translates to:
  /// **'接口测试失败'**
  String get apiTestFailed;

  /// 接口配置：官方档位遇到兼容层错误时的提示
  ///
  /// In zh, this message translates to:
  /// **'提示：当前为「OpenAI 官方」档位，反代/兼容层可能不支持 input_fidelity、output_compression、moderation 等参数，可切换到「OpenAI 兼容」档位再试'**
  String get apiOfficialCompatibilityHint;

  /// 接口配置：测试接口超时提示
  ///
  /// In zh, this message translates to:
  /// **'接口测试超时，请检查反代或网络'**
  String get apiTestTimeout;

  /// 接口配置：测试接口未知错误提示
  ///
  /// In zh, this message translates to:
  /// **'接口测试失败：{error}'**
  String apiTestFailedWithError(Object error);

  /// 接口配置：已保存状态
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get apiSaveStatusSaved;

  /// 接口配置：未保存状态
  ///
  /// In zh, this message translates to:
  /// **'未保存'**
  String get apiSaveStatusPending;

  /// 接口配置：保存中状态
  ///
  /// In zh, this message translates to:
  /// **'保存中'**
  String get apiSaveStatusSaving;

  /// 接口配置：保存失败状态
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get apiSaveStatusFailed;

  /// 通用：未知错误
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get unknownError;

  /// 接口配置：保存失败 tooltip
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{message}'**
  String apiSaveFailedTooltip(Object message);

  /// 接口配置：生图尺寸能力字段标签
  ///
  /// In zh, this message translates to:
  /// **'生图尺寸能力'**
  String get apiImageSizeCapabilityLabel;

  /// 接口配置：自动识别生图尺寸能力说明
  ///
  /// In zh, this message translates to:
  /// **'自动识别：{capability}。'**
  String apiImageSizeCapabilityAuto(Object capability);

  /// 接口配置：生图尺寸能力说明
  ///
  /// In zh, this message translates to:
  /// **'{capability}：{description}'**
  String apiImageSizeCapabilityDescription(
    Object capability,
    Object description,
  );

  /// 接口配置：刷新模型列表操作
  ///
  /// In zh, this message translates to:
  /// **'刷新模型列表'**
  String get apiRefreshModelList;

  /// 接口配置：获取模型列表操作
  ///
  /// In zh, this message translates to:
  /// **'获取模型列表'**
  String get apiFetchModelList;

  /// 接口配置：隐藏 API Key tooltip
  ///
  /// In zh, this message translates to:
  /// **'隐藏密钥'**
  String get apiHideKey;

  /// 接口配置：显示 API Key tooltip
  ///
  /// In zh, this message translates to:
  /// **'显示密钥'**
  String get apiShowKey;

  /// 接口配置：模型字段标签
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get apiModelLabel;

  /// 接口配置：模型字段无默认模型时的提示
  ///
  /// In zh, this message translates to:
  /// **'先获取模型列表，或手动填写模型名称'**
  String get apiModelManualHint;

  /// 接口配置：拉取模型前缺少 API Key
  ///
  /// In zh, this message translates to:
  /// **'请先填写 API Key 再拉取模型列表'**
  String get apiModelFetchApiKeyRequired;

  /// 接口配置：获取模型列表超时提示
  ///
  /// In zh, this message translates to:
  /// **'获取模型列表超时，请检查反代或网络'**
  String get apiModelFetchTimeout;

  /// 接口配置：模型列表为空提示
  ///
  /// In zh, this message translates to:
  /// **'接口没有返回可用模型，仍可手动填写模型名称'**
  String get apiModelFetchEmpty;

  /// 接口配置：获取模型列表失败提示
  ///
  /// In zh, this message translates to:
  /// **'获取模型列表失败：{error}'**
  String apiModelFetchFailedWithError(Object error);

  /// 接口配置：获取模型列表并自动选择模型提示
  ///
  /// In zh, this message translates to:
  /// **'已获取 {count} 个模型，并选择 {modelId}'**
  String apiModelFetchSelected(int count, Object modelId);

  /// 接口配置：获取模型列表成功提示
  ///
  /// In zh, this message translates to:
  /// **'已获取 {count} 个模型，可从列表中选择'**
  String apiModelFetchSuccess(int count);

  /// 接口配置：模型选择菜单 tooltip
  ///
  /// In zh, this message translates to:
  /// **'从已获取列表选择模型，或刷新列表'**
  String get apiModelPickerTooltip;

  /// 接口配置：模型列表刷新中且有缓存
  ///
  /// In zh, this message translates to:
  /// **'正在刷新模型列表，当前显示 {count} 个缓存模型'**
  String apiModelRefreshingCached(int count);

  /// 接口配置：模型列表刷新中且缓存为空
  ///
  /// In zh, this message translates to:
  /// **'正在刷新模型列表，当前缓存为空'**
  String get apiModelRefreshingEmptyCache;

  /// 接口配置：首次获取模型列表
  ///
  /// In zh, this message translates to:
  /// **'正在获取模型列表...'**
  String get apiModelFetching;

  /// 接口配置：模型列表上次成功时间
  ///
  /// In zh, this message translates to:
  /// **'上次成功：{time}'**
  String apiModelLastSuccess(Object time);

  /// 接口配置：刷新失败但继续使用缓存模型
  ///
  /// In zh, this message translates to:
  /// **'刷新失败，继续显示 {count} 个缓存模型'**
  String apiModelRefreshFailedUsingCache(int count);

  /// 接口配置：刷新失败但继续使用缓存模型，并显示上次成功时间
  ///
  /// In zh, this message translates to:
  /// **'刷新失败，继续显示 {count} 个缓存模型，{lastSuccess}'**
  String apiModelRefreshFailedUsingCacheWithTime(int count, Object lastSuccess);

  /// 接口配置：模型获取数量
  ///
  /// In zh, this message translates to:
  /// **'已获取 {count} 个模型'**
  String apiModelFetchedCount(int count);

  /// 接口配置：模型缓存数量和上次成功时间
  ///
  /// In zh, this message translates to:
  /// **'已缓存 {count} 个模型，{lastSuccess}'**
  String apiModelCachedCountWithTime(int count, Object lastSuccess);

  /// 接口配置：模型列表刷新失败且缓存为空
  ///
  /// In zh, this message translates to:
  /// **'模型列表刷新失败，当前缓存为空，可修正配置后重试'**
  String get apiModelRefreshFailedEmptyCache;

  /// 接口配置：模型列表刷新失败且缓存为空，并显示上次成功时间
  ///
  /// In zh, this message translates to:
  /// **'模型列表刷新失败，当前缓存为空，{lastSuccess}'**
  String apiModelRefreshFailedEmptyCacheWithTime(Object lastSuccess);

  /// 接口配置：模型列表首次获取失败
  ///
  /// In zh, this message translates to:
  /// **'模型列表获取失败，可修正配置后重试'**
  String get apiModelFetchFailed;

  /// 接口配置：尚未获取模型列表
  ///
  /// In zh, this message translates to:
  /// **'尚未获取模型列表'**
  String get apiModelNotFetched;

  /// 文本生图工作区标题
  ///
  /// In zh, this message translates to:
  /// **'文本生图'**
  String get imageGenerationWorkspaceTitle;

  /// 文本生图工作区说明
  ///
  /// In zh, this message translates to:
  /// **'选择已保存的接口配置，再填写提示词生成图片'**
  String get imageGenerationWorkspaceDescription;

  /// 文本生图：生成配置面板标题
  ///
  /// In zh, this message translates to:
  /// **'生成配置'**
  String get generationConfigSectionTitle;

  /// 生成表单：正向提示词字段标签
  ///
  /// In zh, this message translates to:
  /// **'正向提示词'**
  String get positivePromptLabel;

  /// 文本生图：正向提示词字段提示
  ///
  /// In zh, this message translates to:
  /// **'描述你想生成的图片'**
  String get positivePromptHint;

  /// 生成表单：负向提示词字段标签
  ///
  /// In zh, this message translates to:
  /// **'负向提示词'**
  String get negativePromptLabel;

  /// 文本生图：负向提示词字段提示
  ///
  /// In zh, this message translates to:
  /// **'会合并到 prompt 中，不额外发送非 OpenAI 字段'**
  String get negativePromptHint;

  /// 生成表单：目标数量字段标签
  ///
  /// In zh, this message translates to:
  /// **'目标数量'**
  String get targetImageCountLabel;

  /// 文本生图：生成图片按钮
  ///
  /// In zh, this message translates to:
  /// **'生成图片'**
  String get generateImageButton;

  /// 文本生图：生成中按钮状态
  ///
  /// In zh, this message translates to:
  /// **'生成中'**
  String get generatingImageButton;

  /// 文本生图：图生图参考图选择器标题
  ///
  /// In zh, this message translates to:
  /// **'参考图（图生图）'**
  String get imageGenerationReferenceImageTitle;

  /// 文本生图：选择图生图参考图按钮
  ///
  /// In zh, this message translates to:
  /// **'选择参考图'**
  String get imageGenerationReferenceImagePickLabel;

  /// 文本生图：已有参考图时继续添加参考图按钮
  ///
  /// In zh, this message translates to:
  /// **'添加参考图'**
  String get imageGenerationAddReferenceImagesLabel;

  /// 文本生图：已选择参考图数量摘要
  ///
  /// In zh, this message translates to:
  /// **'{count} 张参考图'**
  String imageGenerationReferenceImageCountLabel(int count);

  /// 文本生图：移除单张参考图 tooltip
  ///
  /// In zh, this message translates to:
  /// **'移除参考图：{fileName}'**
  String imageGenerationRemoveReferenceImageTooltip(Object fileName);

  /// 文本生图：清除全部参考图 tooltip
  ///
  /// In zh, this message translates to:
  /// **'清除全部参考图'**
  String get imageGenerationClearReferenceImagesTooltip;

  /// 文本生图：参考图数量超过上限提示
  ///
  /// In zh, this message translates to:
  /// **'最多选择 {max} 张参考图'**
  String imageGenerationReferenceImagesLimitMessage(int max);

  /// 文本生图：兼容接口多参考图能力提示
  ///
  /// In zh, this message translates to:
  /// **'兼容接口将按多文件 image 字段发送参考图，实际是否支持取决于服务商。'**
  String get imageGenerationCompatibleMultiReferenceWarning;

  /// 文本生图：带参考图生成按钮
  ///
  /// In zh, this message translates to:
  /// **'图生图'**
  String get imageGenerationGenerateWithReferenceButton;

  /// 文本生图：带参考图生成中的按钮状态
  ///
  /// In zh, this message translates to:
  /// **'图生图中'**
  String get imageGenerationGeneratingWithReferenceButton;

  /// 文本生图状态：调整动画序列行数历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整序列帧行数为 {value} 行'**
  String imageGenerationAdjustAnimationRowsHistory(int value);

  /// 文本生图状态：调整动画序列列数历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整序列帧列数为 {value} 列'**
  String imageGenerationAdjustAnimationColumnsHistory(int value);

  /// 文本生图状态：调整动画序列切片校准历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整序列帧切片校准'**
  String get imageGenerationAdjustAnimationGridSpecHistory;

  /// 文本生图状态：缺少 API Key 提示
  ///
  /// In zh, this message translates to:
  /// **'请先在接口配置页填写 API Key'**
  String get imageGenerationMissingApiKeyMessage;

  /// 文本生图状态：缺少模型提示
  ///
  /// In zh, this message translates to:
  /// **'请先在接口配置页获取模型列表并选择模型'**
  String get imageGenerationMissingModelMessage;

  /// 动画工程状态：缺少 API Key 错误
  ///
  /// In zh, this message translates to:
  /// **'请先在接口配置页填写 API Key。'**
  String get imageGenerationMissingApiKeyError;

  /// 动画工程状态：缺少模型错误
  ///
  /// In zh, this message translates to:
  /// **'请先在接口配置页获取模型列表并选择模型。'**
  String get imageGenerationMissingModelError;

  /// 文本生图状态：缺少正向提示词提示
  ///
  /// In zh, this message translates to:
  /// **'请先填写正向提示词'**
  String get imageGenerationMissingPositivePromptMessage;

  /// 文本生图状态：生成图片历史动作
  ///
  /// In zh, this message translates to:
  /// **'生成 {count} 张图片'**
  String imageGenerationGenerateImagesHistory(int count);

  /// 文本生图状态：图片生成完成提示
  ///
  /// In zh, this message translates to:
  /// **'图片生成完成，共 {count} 张'**
  String imageGenerationImagesGeneratedMessage(int count);

  /// 文本生图：带参考图生成完成提示
  ///
  /// In zh, this message translates to:
  /// **'图生图完成，共 {count} 张'**
  String imageGenerationReferenceImagesGeneratedMessage(int count);

  /// 文本生图状态：请求超时错误
  ///
  /// In zh, this message translates to:
  /// **'请求超时，请检查接口地址或稍后重试'**
  String get imageGenerationRequestTimeoutMessage;

  /// 文本生图状态：生成失败错误前缀
  ///
  /// In zh, this message translates to:
  /// **'生成失败'**
  String get imageGenerationFailedPrefix;

  /// 文本生图状态：图片复制成功提示
  ///
  /// In zh, this message translates to:
  /// **'图片已复制到剪贴板'**
  String get imageGenerationImageCopiedMessage;

  /// 文本生图状态：复制图片路径兜底提示
  ///
  /// In zh, this message translates to:
  /// **'当前平台暂不支持直接复制图片，已复制图片路径'**
  String get imageGenerationImagePathCopiedMessage;

  /// 文本生图状态：复制图片失败提示
  ///
  /// In zh, this message translates to:
  /// **'复制图片失败：{error}'**
  String imageGenerationCopyImageFailedMessage(Object error);

  /// 文本生图状态：图片导出成功提示
  ///
  /// In zh, this message translates to:
  /// **'图片已导出：{fileName}'**
  String imageGenerationImageExportedMessage(Object fileName);

  /// 文本生图状态：图片导出失败提示
  ///
  /// In zh, this message translates to:
  /// **'导出图片失败：{error}'**
  String imageGenerationExportImageFailedMessage(Object error);

  /// 文本生图状态：生成结果默认标题
  ///
  /// In zh, this message translates to:
  /// **'生成结果 {index}'**
  String imageGenerationGeneratedResultTitle(int index);

  /// 文本生图状态：作品库来源字段
  ///
  /// In zh, this message translates to:
  /// **'文本生图'**
  String get imageGenerationTextImageSource;

  /// 文本生图状态：带参考图生成的作品库来源字段
  ///
  /// In zh, this message translates to:
  /// **'图生图'**
  String get imageGenerationReferenceImageSource;

  /// 文本生图状态：选择图生图参考图弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'选择图生图参考图'**
  String get imageGenerationSelectReferenceImageTitle;

  /// 文本生图状态：参考图作品库为空提示
  ///
  /// In zh, this message translates to:
  /// **'作品库没有可作为参考图的图片'**
  String get imageGenerationReferenceLibraryEmpty;

  /// 文本生图状态：选择参考图成功提示
  ///
  /// In zh, this message translates to:
  /// **'已选择参考图：{fileName}'**
  String imageGenerationSelectedReferenceImageMessage(Object fileName);

  /// 文本生图状态：选择多张参考图成功提示
  ///
  /// In zh, this message translates to:
  /// **'已选择 {count} 张参考图'**
  String imageGenerationSelectedReferenceImagesMessage(int count);

  /// 文本生图状态：选择 Sprite Sheet 切片作为参考图成功提示
  ///
  /// In zh, this message translates to:
  /// **'已选择参考切片：{label}'**
  String imageGenerationSelectedReferenceSliceMessage(Object label);

  /// 文本生图状态：背景转透明历史动作
  ///
  /// In zh, this message translates to:
  /// **'背景转透明：{title}'**
  String imageGenerationTransparentBackgroundHistory(Object title);

  /// 文本生图状态：透明背景图片生成成功提示
  ///
  /// In zh, this message translates to:
  /// **'已生成透明背景图片：{title} · 透明化 {count} 个像素'**
  String imageGenerationTransparentBackgroundSavedMessage(
    Object title,
    int count,
  );

  /// 文本生图状态：缺少动画描述提示
  ///
  /// In zh, this message translates to:
  /// **'请先填写动画描述'**
  String get imageGenerationMissingAnimationPromptMessage;

  /// 动画工程状态：缺少动画描述错误
  ///
  /// In zh, this message translates to:
  /// **'请先填写动画描述。'**
  String get imageGenerationMissingAnimationPromptError;

  /// 文本生图状态：动画行列数量无效提示
  ///
  /// In zh, this message translates to:
  /// **'请先设置有效的行列数量'**
  String get imageGenerationInvalidAnimationGridMessage;

  /// 动画工程状态：动画行列数量无效错误
  ///
  /// In zh, this message translates to:
  /// **'请先设置有效的行列数量。'**
  String get imageGenerationInvalidAnimationGridError;

  /// 文本生图状态：动画模板图片不存在提示
  ///
  /// In zh, this message translates to:
  /// **'模板图片不存在，请重新选择'**
  String get imageGenerationTemplateImageMissingMessage;

  /// 动画工程状态：动画模板图片不存在错误
  ///
  /// In zh, this message translates to:
  /// **'模板图片不存在，请重新选择。'**
  String get imageGenerationTemplateImageMissingError;

  /// 文本生图状态：生成 Sprite Sheet 历史动作
  ///
  /// In zh, this message translates to:
  /// **'生成 Sprite Sheet'**
  String get imageGenerationGenerateSpriteSheetHistory;

  /// 文本生图状态：Sprite Sheet 作品库来源字段
  ///
  /// In zh, this message translates to:
  /// **'动画工程'**
  String get imageGenerationSpriteSheetSource;

  /// 文本生图状态：Sprite Sheet 生成完成并开始导入工程提示
  ///
  /// In zh, this message translates to:
  /// **'Sprite Sheet 已生成，正在导入动画工程'**
  String get imageGenerationSpriteSheetGeneratedImportingMessage;

  /// 文本生图状态：Sprite Sheet 生成失败前缀
  ///
  /// In zh, this message translates to:
  /// **'Sprite Sheet 生成失败'**
  String get imageGenerationSpriteSheetFailedPrefix;

  /// 文本生图状态：Stack Overflow 兜底错误提示
  ///
  /// In zh, this message translates to:
  /// **'{prefix}：客户端发生 Stack Overflow，已写入调试详情。如果调试详情里没有 HTTP 状态码，说明请求没有拿到接口响应。'**
  String imageGenerationStackOverflowMessage(Object prefix);

  /// 文本生图状态：未知错误提示
  ///
  /// In zh, this message translates to:
  /// **'{prefix}：{error}'**
  String imageGenerationUnexpectedErrorMessage(Object prefix, Object error);

  /// 动画工程状态：导入工程前缺少 Sprite Sheet 提示
  ///
  /// In zh, this message translates to:
  /// **'请先生成 Sprite Sheet，再导入动画工程'**
  String get imageGenerationImportSpriteSheetFirstMessage;

  /// 动画工程状态：导入 Sprite Sheet 为工程历史动作
  ///
  /// In zh, this message translates to:
  /// **'导入 Sprite Sheet 为动画工程'**
  String get imageGenerationImportSpriteSheetProjectHistory;

  /// 动画工程状态：导入工程成功提示
  ///
  /// In zh, this message translates to:
  /// **'已导入动画工程：{count} 条轨道'**
  String imageGenerationImportedAnimationProjectMessage(int count);

  /// 动画工程状态：导入工程失败提示
  ///
  /// In zh, this message translates to:
  /// **'导入动画工程失败：{error}'**
  String imageGenerationImportAnimationProjectFailedMessage(Object error);

  /// 动画工程状态：关闭工程历史动作
  ///
  /// In zh, this message translates to:
  /// **'关闭动画工程'**
  String get imageGenerationCloseAnimationProjectHistory;

  /// 动画工程状态：选择轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'选择动画轨道'**
  String get imageGenerationSelectAnimationTrackHistory;

  /// 动画工程状态：重命名轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'重命名动画轨道'**
  String get imageGenerationRenameAnimationTrackHistory;

  /// 动画工程状态：调整轨道帧时长历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整轨道帧时长'**
  String get imageGenerationAdjustTrackFrameDelayHistory;

  /// 动画工程状态：调整轨道播放方式历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整轨道播放方式'**
  String get imageGenerationAdjustTrackPlaybackHistory;

  /// 动画工程状态：调整工程默认帧时长历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整工程默认帧时长'**
  String get imageGenerationAdjustProjectDefaultDelayHistory;

  /// 动画工程状态：调整工程播放方式历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整工程播放方式'**
  String get imageGenerationAdjustProjectPlaybackHistory;

  /// 动画工程状态：调整工程 GIF 循环次数历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整工程 GIF 循环次数'**
  String get imageGenerationAdjustProjectGifLoopHistory;

  /// 动画工程状态：导出包含隐藏轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'导出包含隐藏轨道'**
  String get imageGenerationExportIncludeHiddenTracksHistory;

  /// 动画工程状态：导出排除隐藏轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'导出排除隐藏轨道'**
  String get imageGenerationExportExcludeHiddenTracksHistory;

  /// 动画工程状态：本地导入来源标签
  ///
  /// In zh, this message translates to:
  /// **'本地'**
  String get imageGenerationLocalSourceLabel;

  /// 动画工程状态：作品库导入来源标签
  ///
  /// In zh, this message translates to:
  /// **'作品库'**
  String get imageGenerationLibrarySourceLabel;

  /// 动画工程状态：选择作品库图片序列弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'选择作品库图片序列'**
  String get imageGenerationSelectLibrarySequenceTitle;

  /// 动画工程状态：作品库没有可导入图片提示
  ///
  /// In zh, this message translates to:
  /// **'作品库没有可导入的静态图片'**
  String get imageGenerationLibraryNoImportableImagesMessage;

  /// 动画工程状态：导入图片序列为工程历史动作
  ///
  /// In zh, this message translates to:
  /// **'导入图片序列为动画工程'**
  String get imageGenerationImportImageSequenceProjectHistory;

  /// 动画工程状态：图片序列导入为工程成功提示
  ///
  /// In zh, this message translates to:
  /// **'已导入 {count} 张{sourceLabel}图片为动画工程'**
  String imageGenerationImportedImagesAsProjectMessage(
    int count,
    Object sourceLabel,
  );

  /// 动画工程状态：导入序列默认轨道名
  ///
  /// In zh, this message translates to:
  /// **'导入序列 {index}'**
  String imageGenerationImportedSequenceTrackName(int index);

  /// 动画工程状态：导入图片序列为轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'导入图片序列为轨道'**
  String get imageGenerationImportImageSequenceTrackHistory;

  /// 动画工程状态：图片序列导入为新轨道成功提示
  ///
  /// In zh, this message translates to:
  /// **'已导入 {count} 张{sourceLabel}图片为新轨道'**
  String imageGenerationImportedImagesAsTrackMessage(
    int count,
    Object sourceLabel,
  );

  /// 动画工程状态：导入图片序列失败提示
  ///
  /// In zh, this message translates to:
  /// **'导入图片序列失败：{error}'**
  String imageGenerationImportImageSequenceFailedMessage(Object error);

  /// 动画工程状态：新建轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'新建动画轨道'**
  String get imageGenerationAddAnimationTrackHistory;

  /// 动画工程状态：复制轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'复制动画轨道'**
  String get imageGenerationDuplicateAnimationTrackHistory;

  /// 动画工程状态：删除轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'删除动画轨道'**
  String get imageGenerationDeleteAnimationTrackHistory;

  /// 动画工程状态：调整轨道顺序历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整动画轨道顺序'**
  String get imageGenerationMoveAnimationTrackHistory;

  /// 动画工程状态：显示轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'显示动画轨道'**
  String get imageGenerationShowAnimationTrackHistory;

  /// 动画工程状态：隐藏轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'隐藏动画轨道'**
  String get imageGenerationHideAnimationTrackHistory;

  /// 动画工程状态：锁定轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'锁定动画轨道'**
  String get imageGenerationLockAnimationTrackHistory;

  /// 动画工程状态：解锁轨道历史动作
  ///
  /// In zh, this message translates to:
  /// **'解锁动画轨道'**
  String get imageGenerationUnlockAnimationTrackHistory;

  /// 动画工程状态：调整序列帧顺序历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整序列帧顺序'**
  String get imageGenerationMoveAnimationFrameHistory;

  /// 动画工程状态：复制序列帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'复制序列帧'**
  String get imageGenerationDuplicateAnimationFrameHistory;

  /// 动画工程状态：删除序列帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'删除序列帧'**
  String get imageGenerationDeleteAnimationFrameHistory;

  /// 动画工程状态：调整单帧时长历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整单帧时长'**
  String get imageGenerationAdjustFrameDelayHistory;

  /// 动画工程状态：调整单帧变换历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整单帧变换'**
  String get imageGenerationAdjustFrameTransformHistory;

  /// 动画工程状态：重新绑定帧资源历史动作
  ///
  /// In zh, this message translates to:
  /// **'重新绑定动画帧资源'**
  String get imageGenerationRebindFrameAssetHistory;

  /// 动画工程状态：重新绑定帧资源成功提示
  ///
  /// In zh, this message translates to:
  /// **'已重新绑定帧资源：{fileName}'**
  String imageGenerationReboundFrameAssetMessage(Object fileName);

  /// 动画工程状态：重新绑定帧资源失败提示
  ///
  /// In zh, this message translates to:
  /// **'重新绑定帧资源失败：{error}'**
  String imageGenerationRebindFrameAssetFailedMessage(Object error);

  /// 动画工程状态：替换动画帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'替换动画帧'**
  String get imageGenerationReplaceAnimationFrameHistory;

  /// 动画工程状态：替换动画帧成功提示
  ///
  /// In zh, this message translates to:
  /// **'已替换第 {index} 帧：{fileName}'**
  String imageGenerationReplacedAnimationFrameMessage(
    int index,
    Object fileName,
  );

  /// 动画工程状态：替换动画帧失败前缀
  ///
  /// In zh, this message translates to:
  /// **'替换动画帧失败'**
  String get imageGenerationReplaceAnimationFrameFailedPrefix;

  /// 动画工程状态：插入空白动画帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'插入空白动画帧'**
  String get imageGenerationInsertBlankFrameHistory;

  /// 动画工程状态：插入空白帧成功提示
  ///
  /// In zh, this message translates to:
  /// **'已在第 {index} 帧插入空白帧'**
  String imageGenerationInsertedBlankFrameMessage(int index);

  /// 动画工程状态：插入空白动画帧失败前缀
  ///
  /// In zh, this message translates to:
  /// **'插入空白动画帧失败'**
  String get imageGenerationInsertBlankFrameFailedPrefix;

  /// 动画工程状态：插入图片动画帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'插入图片动画帧'**
  String get imageGenerationInsertImageFrameHistory;

  /// 动画工程状态：插入图片帧成功提示
  ///
  /// In zh, this message translates to:
  /// **'已在第 {index} 帧插入图片帧：{fileName}'**
  String imageGenerationInsertedImageFrameMessage(int index, Object fileName);

  /// 动画工程状态：插入图片动画帧失败前缀
  ///
  /// In zh, this message translates to:
  /// **'插入图片动画帧失败'**
  String get imageGenerationInsertImageFrameFailedPrefix;

  /// 动画工程状态：清空动画帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'清空动画帧'**
  String get imageGenerationClearAnimationFrameHistory;

  /// 动画工程状态：清空动画帧失败前缀
  ///
  /// In zh, this message translates to:
  /// **'清空动画帧失败'**
  String get imageGenerationClearAnimationFrameFailedPrefix;

  /// 动画工程状态：像素化动画帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'像素化动画帧'**
  String get imageGenerationPixelateAnimationFrameHistory;

  /// 动画工程状态：像素化动画帧成功提示
  ///
  /// In zh, this message translates to:
  /// **'已像素化第 {index} 帧（{blockSize} px）'**
  String imageGenerationPixelatedAnimationFrameMessage(
    int index,
    int blockSize,
  );

  /// 动画工程状态：像素化动画帧失败前缀
  ///
  /// In zh, this message translates to:
  /// **'像素化动画帧失败'**
  String get imageGenerationPixelateAnimationFrameFailedPrefix;

  /// 动画工程状态：当前帧不可编辑提示
  ///
  /// In zh, this message translates to:
  /// **'当前帧不能编辑，请确认轨道未锁定'**
  String get imageGenerationCurrentFrameNotEditableMessage;

  /// 动画工程状态：带前缀错误提示
  ///
  /// In zh, this message translates to:
  /// **'{prefix}：{error}'**
  String imageGenerationPrefixedErrorMessage(Object prefix, Object error);

  /// 动画工程状态：没有可自动修复问题提示
  ///
  /// In zh, this message translates to:
  /// **'没有可自动修复的工程问题'**
  String get imageGenerationNoRepairableProjectIssuesMessage;

  /// 动画工程状态：自动修复工程一致性历史动作
  ///
  /// In zh, this message translates to:
  /// **'自动修复动画工程一致性'**
  String get imageGenerationRepairProjectConsistencyHistory;

  /// 动画工程状态：自动修复工程一致性成功提示
  ///
  /// In zh, this message translates to:
  /// **'已自动修复工程一致性问题'**
  String get imageGenerationRepairedProjectConsistencyMessage;

  /// 动画工程状态：未导入工程提示
  ///
  /// In zh, this message translates to:
  /// **'请先导入动画工程'**
  String get imageGenerationPleaseImportAnimationProjectMessage;

  /// 动画工程状态：导出工程 Sprite Sheet 历史动作
  ///
  /// In zh, this message translates to:
  /// **'导出动画工程 Sprite Sheet'**
  String get imageGenerationExportAnimationProjectSpriteSheetHistory;

  /// 动画工程状态：导出工程 Sprite Sheet 成功提示
  ///
  /// In zh, this message translates to:
  /// **'动画工程 Sprite Sheet 已导出：{fileName}'**
  String imageGenerationExportedProjectSpriteSheetMessage(Object fileName);

  /// 动画工程状态：导出失败提示
  ///
  /// In zh, this message translates to:
  /// **'导出失败：{error}'**
  String imageGenerationExportFailedMessage(Object error);

  /// 动画工程状态：导出工程 GIF 历史动作
  ///
  /// In zh, this message translates to:
  /// **'导出动画工程 GIF'**
  String get imageGenerationExportAnimationProjectGifHistory;

  /// 动画工程状态：导出工程 GIF 成功提示
  ///
  /// In zh, this message translates to:
  /// **'动画工程 GIF 已导出：{fileName}'**
  String imageGenerationExportedProjectGifMessage(Object fileName);

  /// 动画工程状态：导出工程 GIF 失败提示
  ///
  /// In zh, this message translates to:
  /// **'导出工程 GIF 失败：{error}'**
  String imageGenerationExportProjectGifFailedMessage(Object error);

  /// 动画工程状态：未选择轨道提示
  ///
  /// In zh, this message translates to:
  /// **'请先选择动画轨道'**
  String get imageGenerationPleaseSelectAnimationTrackMessage;

  /// 动画工程状态：导出轨道 GIF 历史动作
  ///
  /// In zh, this message translates to:
  /// **'导出动画轨道 GIF'**
  String get imageGenerationExportAnimationTrackGifHistory;

  /// 动画工程状态：导出轨道 GIF 成功提示
  ///
  /// In zh, this message translates to:
  /// **'当前轨道 GIF 已导出：{fileName}'**
  String imageGenerationExportedTrackGifMessage(Object fileName);

  /// 动画工程状态：导出工程 PNG 序列成功提示
  ///
  /// In zh, this message translates to:
  /// **'已导出 {count} 张工程合成 PNG 序列帧'**
  String imageGenerationExportedProjectPngSequenceMessage(int count);

  /// 动画工程状态：导出工程 PNG 序列失败提示
  ///
  /// In zh, this message translates to:
  /// **'导出工程 PNG 序列失败：{error}'**
  String imageGenerationExportProjectPngSequenceFailedMessage(Object error);

  /// 动画工程状态：导出轨道 PNG 序列成功提示
  ///
  /// In zh, this message translates to:
  /// **'已导出 {count} 张 PNG 序列帧'**
  String imageGenerationExportedTrackPngSequenceMessage(int count);

  /// 动画工程状态：导出 PNG 序列失败提示
  ///
  /// In zh, this message translates to:
  /// **'导出 PNG 序列失败：{error}'**
  String imageGenerationExportPngSequenceFailedMessage(Object error);

  /// 批量生成工作区标题
  ///
  /// In zh, this message translates to:
  /// **'批量生成'**
  String get batchGenerationWorkspaceTitle;

  /// 批量生成工作区说明
  ///
  /// In zh, this message translates to:
  /// **'把多条文本生图任务排队串行执行，成功结果会自动进入作品库。'**
  String get batchGenerationWorkspaceDescription;

  /// 批量生成：队列控制面板标题
  ///
  /// In zh, this message translates to:
  /// **'队列控制'**
  String get batchQueueControlTitle;

  /// 批量生成：批量提示词字段标签
  ///
  /// In zh, this message translates to:
  /// **'批量提示词'**
  String get batchPromptLabel;

  /// 批量生成：批量提示词字段提示
  ///
  /// In zh, this message translates to:
  /// **'每行一条提示词；每条会按目标数量自动拆分'**
  String get batchPromptHint;

  /// 批量生成：负向提示词字段提示
  ///
  /// In zh, this message translates to:
  /// **'会应用到每一个批量任务'**
  String get batchNegativePromptHint;

  /// 批量生成：目标数量字段说明
  ///
  /// In zh, this message translates to:
  /// **'每条提示词最终想生成的总数'**
  String get batchTargetCountHelper;

  /// 批量生成：每批张数字段标签
  ///
  /// In zh, this message translates to:
  /// **'每批张数'**
  String get batchRequestCountLabel;

  /// 批量生成：每批张数字段说明
  ///
  /// In zh, this message translates to:
  /// **'单次请求最多 {maxCount} 张'**
  String batchRequestCountHelper(int maxCount);

  /// 批量生成：当前拆分任务数量说明
  ///
  /// In zh, this message translates to:
  /// **'当前会把每条提示词拆成 {batchCount} 个串行任务'**
  String batchSplitStatus(int batchCount);

  /// 批量生成：按行拆分入队按钮
  ///
  /// In zh, this message translates to:
  /// **'按行拆分入队'**
  String get batchAddPrompts;

  /// 批量生成：开始队列按钮
  ///
  /// In zh, this message translates to:
  /// **'开始队列'**
  String get batchStartQueue;

  /// 批量生成：继续队列按钮
  ///
  /// In zh, this message translates to:
  /// **'继续队列'**
  String get batchContinueQueue;

  /// 批量生成：队列运行中按钮状态
  ///
  /// In zh, this message translates to:
  /// **'队列运行中'**
  String get batchQueueRunning;

  /// 批量生成：队列运行时操作不可用原因
  ///
  /// In zh, this message translates to:
  /// **'队列运行中，当前不能执行此操作'**
  String get batchActionQueueBusyUnavailable;

  /// 批量生成：开始或继续队列不可用原因
  ///
  /// In zh, this message translates to:
  /// **'没有等待中的任务可执行'**
  String get batchActionNeedsQueuedJobs;

  /// 批量生成：暂停按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'队列未运行'**
  String get batchActionQueueNotRunning;

  /// 批量生成：重复暂停不可用原因
  ///
  /// In zh, this message translates to:
  /// **'已请求暂停后续任务'**
  String get batchActionQueueAlreadyPausing;

  /// 批量生成：继续后续按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'队列未暂停'**
  String get batchActionQueueNotPaused;

  /// 批量生成：暂停后续按钮
  ///
  /// In zh, this message translates to:
  /// **'暂停后续'**
  String get batchPauseAfterCurrent;

  /// 批量生成：继续后续按钮
  ///
  /// In zh, this message translates to:
  /// **'继续后续'**
  String get batchResumeQueue;

  /// 批量生成：取消等待任务按钮
  ///
  /// In zh, this message translates to:
  /// **'取消等待任务'**
  String get batchCancelQueued;

  /// 批量生成：重试失败任务按钮
  ///
  /// In zh, this message translates to:
  /// **'重试失败任务'**
  String get batchRetryFailed;

  /// 批量生成：带数量的重试失败任务按钮
  ///
  /// In zh, this message translates to:
  /// **'重试失败任务 ({count})'**
  String batchRetryFailedCount(int count);

  /// 批量生成：清理完成失败取消任务按钮
  ///
  /// In zh, this message translates to:
  /// **'清理完成 / 失败 / 取消'**
  String get batchClearFinished;

  /// 批量生成：清理按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'没有可清理的完成、失败或取消任务'**
  String get batchActionNoFinishedJobs;

  /// 批量生成：暂停后续任务状态说明
  ///
  /// In zh, this message translates to:
  /// **'已暂停后续任务。正在请求的 {runningCount} 个任务会等接口返回或超时后停下，不会继续启动新的等待任务。'**
  String batchQueuePausingStatus(int runningCount);

  /// 批量生成：队列运行中状态说明
  ///
  /// In zh, this message translates to:
  /// **'正在请求 {runningCount} 个任务，后面还有 {queuedCount} 个等待任务。暂停只会阻止下一批开始，不会中断已发出的 HTTP 请求。'**
  String batchQueueRunningStatus(int runningCount, int queuedCount);

  /// 批量生成：队列有等待任务状态说明
  ///
  /// In zh, this message translates to:
  /// **'队列里有 {queuedCount} 个等待任务，可继续执行或取消等待任务。'**
  String batchQueueWaitingStatus(int queuedCount);

  /// 批量生成：队列空状态说明
  ///
  /// In zh, this message translates to:
  /// **'没有等待中的任务。'**
  String get batchQueueEmptyStatus;

  /// 批量生成：任务队列面板标题
  ///
  /// In zh, this message translates to:
  /// **'任务队列'**
  String get batchJobListTitle;

  /// 批量生成：任务队列空状态
  ///
  /// In zh, this message translates to:
  /// **'还没有任务。把提示词加入队列后，会按目标数量拆分并串行生成。'**
  String get batchJobListEmpty;

  /// 批量生成：任务队列数量
  ///
  /// In zh, this message translates to:
  /// **'{count} 个任务'**
  String batchJobCount(int count);

  /// 批量生成：任务摘要中的批次前缀
  ///
  /// In zh, this message translates to:
  /// **'第 {batchIndex}/{batchTotal} 批 · '**
  String batchJobBatchPrefix(int batchIndex, int batchTotal);

  /// 批量生成：任务摘要中的重试后缀
  ///
  /// In zh, this message translates to:
  /// **' · 重试 {retryAttempt}/{maxAttempts}'**
  String batchJobRetrySuffix(int retryAttempt, int maxAttempts);

  /// 批量生成：任务摘要
  ///
  /// In zh, this message translates to:
  /// **'{status} · {batchLabel}{size} · {imageCount} 张 · {apiConfigName}{retryLabel}'**
  String batchJobSummary(
    Object status,
    Object batchLabel,
    Object size,
    int imageCount,
    Object apiConfigName,
    Object retryLabel,
  );

  /// 批量生成：单个任务重试 tooltip
  ///
  /// In zh, this message translates to:
  /// **'重试任务'**
  String get batchRetryJobTooltip;

  /// 批量生成：单个任务移除 tooltip
  ///
  /// In zh, this message translates to:
  /// **'移除任务'**
  String get batchRemoveJobTooltip;

  /// 批量生成：任务状态等待中
  ///
  /// In zh, this message translates to:
  /// **'等待中'**
  String get batchJobStatusQueued;

  /// 批量生成：任务状态生成中
  ///
  /// In zh, this message translates to:
  /// **'生成中'**
  String get batchJobStatusRunning;

  /// 批量生成：任务状态已完成
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get batchJobStatusSucceeded;

  /// 批量生成：任务状态失败
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get batchJobStatusFailed;

  /// 批量生成：任务状态已取消
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get batchJobStatusSkipped;

  /// 通用：取消操作
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancelAction;

  /// 通用：保存操作
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get saveAction;

  /// 通用：重试操作
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retryAction;

  /// 通用：播放操作
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get playAction;

  /// 通用：暂停操作
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pauseAction;

  /// 通用：关闭操作
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get closeAction;

  /// 通用：复制操作
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copyAction;

  /// 通用：选择操作
  ///
  /// In zh, this message translates to:
  /// **'选择'**
  String get selectAction;

  /// 通用：更换操作
  ///
  /// In zh, this message translates to:
  /// **'更换'**
  String get replaceAction;

  /// 通用：确认选择操作
  ///
  /// In zh, this message translates to:
  /// **'确认选择'**
  String get confirmSelectionAction;

  /// 通用：确认删除操作
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get confirmDeleteAction;

  /// 作品库工作区标题
  ///
  /// In zh, this message translates to:
  /// **'作品'**
  String get imageLibraryWorkspaceTitle;

  /// 作品库工作区说明
  ///
  /// In zh, this message translates to:
  /// **'集中保存生成、切片、编辑和合成后的图片，其他功能可以直接复用'**
  String get imageLibraryWorkspaceDescription;

  /// 作品库面板标题
  ///
  /// In zh, this message translates to:
  /// **'应用内作品'**
  String get imageLibraryPanelTitle;

  /// 作品库：总作品数量
  ///
  /// In zh, this message translates to:
  /// **'{count} 个作品'**
  String imageLibraryTotalCount(int count);

  /// 作品库：筛选后数量 / 总数量
  ///
  /// In zh, this message translates to:
  /// **'{visibleCount} / {totalCount}'**
  String imageLibraryFilteredCount(int visibleCount, int totalCount);

  /// 作品库：搜索框标签
  ///
  /// In zh, this message translates to:
  /// **'搜索作品'**
  String get imageLibrarySearchLabel;

  /// 作品库：清空搜索 tooltip
  ///
  /// In zh, this message translates to:
  /// **'清空搜索'**
  String get imageLibraryClearSearchTooltip;

  /// 作品库：项目字段标签
  ///
  /// In zh, this message translates to:
  /// **'项目'**
  String get imageLibraryProjectLabel;

  /// 作品库：全部项目筛选项
  ///
  /// In zh, this message translates to:
  /// **'全部项目'**
  String get imageLibraryAllProjects;

  /// 作品库：标签字段标签
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get imageLibraryTagLabel;

  /// 作品库：全部标签筛选项
  ///
  /// In zh, this message translates to:
  /// **'全部标签'**
  String get imageLibraryAllTags;

  /// 作品库：排序字段标签
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get imageLibrarySortLabel;

  /// 作品库：选择当前可见结果按钮
  ///
  /// In zh, this message translates to:
  /// **'选择当前结果'**
  String get imageLibrarySelectVisible;

  /// 作品库：空结果时选择当前结果按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'当前没有可选择的作品'**
  String get imageLibrarySelectVisibleEmptyUnavailable;

  /// 作品库：当前结果全选时选择当前结果按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'当前结果已全部选中'**
  String get imageLibrarySelectVisibleAllSelectedUnavailable;

  /// 作品库：展开切片筛选按钮
  ///
  /// In zh, this message translates to:
  /// **'展开切片 ({count})'**
  String imageLibraryExpandSlices(int count);

  /// 作品库：已选数量按钮
  ///
  /// In zh, this message translates to:
  /// **'已选 {count}'**
  String imageLibrarySelectedCount(int count);

  /// 作品库：导出已选按钮
  ///
  /// In zh, this message translates to:
  /// **'导出已选'**
  String get imageLibraryExportSelected;

  /// 作品库：删除已选按钮
  ///
  /// In zh, this message translates to:
  /// **'删除已选'**
  String get imageLibraryDeleteSelected;

  /// 作品库：作品卡片键盘操作语义提示
  ///
  /// In zh, this message translates to:
  /// **'按空格切换选择，按回车打开主要操作'**
  String get imageLibraryTileKeyboardHint;

  /// 作品库：无任何作品空状态
  ///
  /// In zh, this message translates to:
  /// **'暂无作品。生成、导出、编辑或合成后的图片会保存到这里。'**
  String get imageLibraryEmptyAll;

  /// 作品库：筛选后无结果空状态
  ///
  /// In zh, this message translates to:
  /// **'当前条件下没有作品。'**
  String get imageLibraryEmptyFiltered;

  /// 作品库：空分页范围
  ///
  /// In zh, this message translates to:
  /// **'0 / 0'**
  String get imageLibraryPageEmptyRange;

  /// 作品库：分页范围
  ///
  /// In zh, this message translates to:
  /// **'{startIndex}-{endIndex} / {totalCount}'**
  String imageLibraryPageRange(int startIndex, int endIndex, int totalCount);

  /// 作品库：分页状态
  ///
  /// In zh, this message translates to:
  /// **'第 {pageIndex} / {pageCount} 页 · {rangeLabel}'**
  String imageLibraryPageStatus(
    int pageIndex,
    int pageCount,
    Object rangeLabel,
  );

  /// 作品库：分页控制区域语义标签
  ///
  /// In zh, this message translates to:
  /// **'作品库分页控制 · {statusLabel} · 每页 {pageSize} 个'**
  String imageLibraryPaginationSemanticLabel(Object statusLabel, int pageSize);

  /// 作品库：第一页 tooltip
  ///
  /// In zh, this message translates to:
  /// **'第一页'**
  String get imageLibraryFirstPageTooltip;

  /// 作品库：上一页 tooltip
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get imageLibraryPreviousPageTooltip;

  /// 作品库：下一页 tooltip
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get imageLibraryNextPageTooltip;

  /// 作品库：最后一页 tooltip
  ///
  /// In zh, this message translates to:
  /// **'最后一页'**
  String get imageLibraryLastPageTooltip;

  /// 作品库：每页数量前缀
  ///
  /// In zh, this message translates to:
  /// **'每页'**
  String get imageLibraryPageSizePrefix;

  /// 作品库：每页数量后缀
  ///
  /// In zh, this message translates to:
  /// **'个'**
  String get imageLibraryPageSizeSuffix;

  /// 作品库：筛选全部
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get imageLibraryFilterAll;

  /// 作品库：筛选生图
  ///
  /// In zh, this message translates to:
  /// **'生图'**
  String get imageLibraryFilterGenerated;

  /// 作品库：筛选切片或帧图
  ///
  /// In zh, this message translates to:
  /// **'切片 / 帧'**
  String get imageLibraryFilterSprite;

  /// 作品库：筛选编辑图
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get imageLibraryFilterEdited;

  /// 作品库：筛选动画工程
  ///
  /// In zh, this message translates to:
  /// **'动画'**
  String get imageLibraryFilterAnimation;

  /// 作品库：筛选 GIF
  ///
  /// In zh, this message translates to:
  /// **'GIF'**
  String get imageLibraryFilterGif;

  /// 作品库：最新优先排序
  ///
  /// In zh, this message translates to:
  /// **'最新优先'**
  String get imageLibrarySortNewest;

  /// 作品库：最旧优先排序
  ///
  /// In zh, this message translates to:
  /// **'最旧优先'**
  String get imageLibrarySortOldest;

  /// 作品库：标题升序排序
  ///
  /// In zh, this message translates to:
  /// **'标题 A-Z'**
  String get imageLibrarySortTitleAsc;

  /// 作品库：已保存切片数量徽标
  ///
  /// In zh, this message translates to:
  /// **'{savedCount}/{totalCount} 帧'**
  String imageLibrarySavedFramesBadge(int savedCount, int totalCount);

  /// 作品库卡片：切片主操作
  ///
  /// In zh, this message translates to:
  /// **'切片'**
  String get imageLibraryActionSlices;

  /// 作品库卡片：打开主操作
  ///
  /// In zh, this message translates to:
  /// **'打开'**
  String get imageLibraryActionOpen;

  /// 作品库卡片：复用主操作
  ///
  /// In zh, this message translates to:
  /// **'复用'**
  String get imageLibraryActionReuse;

  /// 作品库卡片：编辑主操作
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get imageLibraryActionEdit;

  /// 作品库卡片：编辑作品信息 tooltip
  ///
  /// In zh, this message translates to:
  /// **'编辑作品信息'**
  String get imageLibraryEditMetadataTooltip;

  /// 作品库卡片：更多操作 tooltip
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get imageLibraryMoreActionsTooltip;

  /// 作品库菜单：打开动画工程
  ///
  /// In zh, this message translates to:
  /// **'打开动画工程'**
  String get imageLibraryMenuOpenAnimation;

  /// 作品库菜单：在编辑器中打开
  ///
  /// In zh, this message translates to:
  /// **'在编辑器中打开'**
  String get imageLibraryMenuOpenInEditor;

  /// 作品库菜单：复用生成参数
  ///
  /// In zh, this message translates to:
  /// **'复用生成参数'**
  String get imageLibraryMenuReuseGeneration;

  /// 作品库菜单：复制生成参数
  ///
  /// In zh, this message translates to:
  /// **'复制生成参数'**
  String get imageLibraryMenuCopyGeneration;

  /// 作品库菜单：背景转透明
  ///
  /// In zh, this message translates to:
  /// **'背景转透明'**
  String get imageLibraryMenuTransparentBg;

  /// 作品库菜单：复制图片
  ///
  /// In zh, this message translates to:
  /// **'复制图片'**
  String get imageLibraryMenuCopyImage;

  /// 作品库菜单：导出图片
  ///
  /// In zh, this message translates to:
  /// **'导出图片'**
  String get imageLibraryMenuExportImage;

  /// 作品库菜单：导出文件
  ///
  /// In zh, this message translates to:
  /// **'导出文件'**
  String get imageLibraryMenuExportFile;

  /// 作品库菜单：复制路径
  ///
  /// In zh, this message translates to:
  /// **'复制路径'**
  String get imageLibraryMenuCopyPath;

  /// 作品库菜单：打开位置
  ///
  /// In zh, this message translates to:
  /// **'打开位置'**
  String get imageLibraryMenuOpenLocation;

  /// 作品库菜单：删除作品
  ///
  /// In zh, this message translates to:
  /// **'删除作品'**
  String get imageLibraryMenuDelete;

  /// 图片资产类型：生图
  ///
  /// In zh, this message translates to:
  /// **'生图'**
  String get imageAssetKindGenerated;

  /// 图片资产类型：Sprite Sheet
  ///
  /// In zh, this message translates to:
  /// **'切片'**
  String get imageAssetKindSpriteSheet;

  /// 图片资产类型：帧图
  ///
  /// In zh, this message translates to:
  /// **'帧图'**
  String get imageAssetKindSpriteFrame;

  /// 图片资产类型：编辑图
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get imageAssetKindEdited;

  /// 图片资产类型：动画工程
  ///
  /// In zh, this message translates to:
  /// **'动画'**
  String get imageAssetKindAnimationProject;

  /// 图片资产类型：GIF
  ///
  /// In zh, this message translates to:
  /// **'GIF'**
  String get imageAssetKindGif;

  /// 作品库选择器：选择多张按钮
  ///
  /// In zh, this message translates to:
  /// **'选择 {count} 张'**
  String imageLibraryPickerSelectCount(int count);

  /// 作品库选择器：单个作品项语义标签
  ///
  /// In zh, this message translates to:
  /// **'{kind} · {title} · 第 {index} / {total} 项'**
  String imageLibraryPickerItemSemanticLabel(
    Object kind,
    Object title,
    int index,
    int total,
  );

  /// 作品库切片：缺少行列元数据错误
  ///
  /// In zh, this message translates to:
  /// **'该 Sprite Sheet 缺少行列元数据。'**
  String get imageLibrarySliceMissingGridMetadata;

  /// 作品库切片：加载失败错误
  ///
  /// In zh, this message translates to:
  /// **'加载切片失败：{error}'**
  String imageLibrarySliceLoadFailed(Object error);

  /// 作品库切片管理弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'切片管理 · {title}'**
  String imageLibrarySliceExplorerTitle(Object title);

  /// 作品库切片：已保存数量状态
  ///
  /// In zh, this message translates to:
  /// **'已保存 {savedCount} / {totalCount}'**
  String imageLibrarySliceSavedStatus(int savedCount, int totalCount);

  /// 作品库切片：已保存徽标
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get imageLibrarySliceSavedBadge;

  /// 作品库切片：未保存状态
  ///
  /// In zh, this message translates to:
  /// **'未保存'**
  String get imageLibrarySliceUnsavedStatus;

  /// 作品库切片管理：单帧语义标签
  ///
  /// In zh, this message translates to:
  /// **'切片帧 {index} / {total} · {status}'**
  String imageLibrarySliceExplorerFrameSemanticLabel(
    int index,
    int total,
    Object status,
  );

  /// 作品库切片：保存单帧 tooltip
  ///
  /// In zh, this message translates to:
  /// **'保存这一帧'**
  String get imageLibrarySliceSaveOneTooltip;

  /// 作品库切片：全部已保存按钮
  ///
  /// In zh, this message translates to:
  /// **'已全部保存'**
  String get imageLibrarySliceAllSaved;

  /// 作品库切片：全部保存按钮
  ///
  /// In zh, this message translates to:
  /// **'全部保存为切片 ({count})'**
  String imageLibrarySliceSaveAll(int count);

  /// 作品库切片选择器：多选默认标题
  ///
  /// In zh, this message translates to:
  /// **'挑选切片帧'**
  String get imageLibrarySlicePickerMultiTitle;

  /// 作品库切片选择器：单选默认标题
  ///
  /// In zh, this message translates to:
  /// **'挑选一帧作为来源'**
  String get imageLibrarySlicePickerSingleTitle;

  /// 作品库切片选择器标题
  ///
  /// In zh, this message translates to:
  /// **'{title} · {sheetTitle}'**
  String imageLibrarySlicePickerTitle(Object title, Object sheetTitle);

  /// 作品库切片选择器：多选已选状态
  ///
  /// In zh, this message translates to:
  /// **'已选 {selectedCount} / {totalCount}'**
  String imageLibrarySlicePickerSelectedStatus(
    int selectedCount,
    int totalCount,
  );

  /// 作品库切片选择器：未选择状态
  ///
  /// In zh, this message translates to:
  /// **'尚未选择'**
  String get imageLibrarySlicePickerNotSelected;

  /// 作品库切片选择器：单选已选状态
  ///
  /// In zh, this message translates to:
  /// **'已选 #{index}'**
  String imageLibrarySlicePickerSelectedOne(int index);

  /// 作品库切片选择器：确认多选按钮
  ///
  /// In zh, this message translates to:
  /// **'确认选择 ({count})'**
  String imageLibrarySlicePickerConfirmCount(int count);

  /// 作品库切片选择器：单帧语义标签
  ///
  /// In zh, this message translates to:
  /// **'切片帧 {index} / {total}'**
  String imageLibrarySliceFrameSemanticLabel(int index, int total);

  /// 图片来源选择：本地文件标题
  ///
  /// In zh, this message translates to:
  /// **'从本地文件选择'**
  String get pickSourceLocalFileTitle;

  /// 图片来源选择：本地文件说明
  ///
  /// In zh, this message translates to:
  /// **'打开电脑文件选择窗口'**
  String get pickSourceLocalFileSubtitle;

  /// 图片来源选择：作品库标题
  ///
  /// In zh, this message translates to:
  /// **'从作品库选择'**
  String get pickSourceImageLibraryTitle;

  /// 图片来源选择：作品库说明
  ///
  /// In zh, this message translates to:
  /// **'直接使用已保存到作品库的图片'**
  String get pickSourceImageLibrarySubtitle;

  /// 图片来源选择：作品库无可用图片说明
  ///
  /// In zh, this message translates to:
  /// **'作品库还没有可用图片'**
  String get pickSourceImageLibraryEmpty;

  /// 作品库：编辑作品信息弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'编辑作品信息'**
  String get imageLibraryEditMetadataTitle;

  /// 作品库：作品标题字段标签
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get imageLibraryMetadataTitleLabel;

  /// 作品库：备注字段标签
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get imageLibraryMetadataNoteLabel;

  /// 作品库：备注字段提示
  ///
  /// In zh, this message translates to:
  /// **'记录用途、版本或修改说明'**
  String get imageLibraryMetadataNoteHint;

  /// 作品库：项目字段提示
  ///
  /// In zh, this message translates to:
  /// **'例如：角色 A、Demo 游戏、UI 图标集'**
  String get imageLibraryMetadataProjectHint;

  /// 作品库：标签字段提示
  ///
  /// In zh, this message translates to:
  /// **'用逗号分隔，例如：idle, run, pixel'**
  String get imageLibraryMetadataTagsHint;

  /// 作品库：删除时级联切片数量提示
  ///
  /// In zh, this message translates to:
  /// **'同时会移除 {count} 个关联的切片帧。'**
  String imageLibraryDeleteCascade(int count);

  /// 作品库：批量删除标题
  ///
  /// In zh, this message translates to:
  /// **'删除 {count} 个作品'**
  String imageLibraryDeleteBatchTitle(int count);

  /// 作品库：删除单个作品标题
  ///
  /// In zh, this message translates to:
  /// **'删除作品'**
  String get imageLibraryDeleteOneTitle;

  /// 作品库：批量删除确认内容
  ///
  /// In zh, this message translates to:
  /// **'将从作品库移除这些作品，并删除应用缓存中的对应文件。{cascadeText}\n此操作不可撤销。'**
  String imageLibraryDeleteBatchMessage(Object cascadeText);

  /// 作品库：删除单个作品确认内容
  ///
  /// In zh, this message translates to:
  /// **'将从作品库移除「{title}」，并删除应用缓存中的对应文件。{cascadeText}\n此操作不可撤销。'**
  String imageLibraryDeleteOneMessage(Object title, Object cascadeText);

  /// 像素画工作区说明
  ///
  /// In zh, this message translates to:
  /// **'逐格绘制像素画，支持画笔、橡皮、取色和保存到作品库'**
  String get pixelArtWorkspaceDescription;

  /// 像素画：进入全屏编辑 tooltip
  ///
  /// In zh, this message translates to:
  /// **'进入全屏编辑'**
  String get pixelArtEnterFocusTooltip;

  /// 像素画：退出全屏编辑 tooltip
  ///
  /// In zh, this message translates to:
  /// **'退出全屏编辑'**
  String get pixelArtExitFocusTooltip;

  /// 像素画：工具面板标题
  ///
  /// In zh, this message translates to:
  /// **'像素画工具'**
  String get pixelArtToolsTitle;

  /// 像素画：画布尺寸区块标题
  ///
  /// In zh, this message translates to:
  /// **'画布尺寸'**
  String get pixelArtCanvasSizeTitle;

  /// 像素画：画布宽度字段
  ///
  /// In zh, this message translates to:
  /// **'画布宽度'**
  String get pixelArtCanvasWidthLabel;

  /// 像素画：画布高度字段
  ///
  /// In zh, this message translates to:
  /// **'画布高度'**
  String get pixelArtCanvasHeightLabel;

  /// 像素画：画布尺寸修改后应用提示
  ///
  /// In zh, this message translates to:
  /// **'修改后应用'**
  String get pixelArtApplyAfterChangeHelper;

  /// 像素画：应用画布尺寸按钮
  ///
  /// In zh, this message translates to:
  /// **'应用画布尺寸'**
  String get pixelArtApplyCanvasSize;

  /// 像素画：画笔工具
  ///
  /// In zh, this message translates to:
  /// **'画笔'**
  String get pixelArtBrushTool;

  /// 像素画：橡皮工具
  ///
  /// In zh, this message translates to:
  /// **'橡皮'**
  String get pixelArtEraserTool;

  /// 像素画：取色工具
  ///
  /// In zh, this message translates to:
  /// **'取色'**
  String get pixelArtEyedropperTool;

  /// 像素画：画笔大小字段
  ///
  /// In zh, this message translates to:
  /// **'画笔大小'**
  String get pixelArtBrushSizeLabel;

  /// 像素画：像素格数量后缀
  ///
  /// In zh, this message translates to:
  /// **'格'**
  String get pixelArtCellSuffix;

  /// 像素画：画笔大小说明
  ///
  /// In zh, this message translates to:
  /// **'按方形笔刷覆盖像素格'**
  String get pixelArtBrushSizeHelper;

  /// 像素画：颜色区块标题
  ///
  /// In zh, this message translates to:
  /// **'颜色'**
  String get pixelArtColorTitle;

  /// 像素画：缩放区块标题
  ///
  /// In zh, this message translates to:
  /// **'缩放'**
  String get pixelArtZoomTitle;

  /// 像素画：新建空白画布按钮
  ///
  /// In zh, this message translates to:
  /// **'新建空白'**
  String get pixelArtNewBlankCanvas;

  /// 像素画：清空画布按钮
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get pixelArtClearCanvas;

  /// 像素画：保存到作品库按钮
  ///
  /// In zh, this message translates to:
  /// **'保存到作品库'**
  String get pixelArtSaveToLibrary;

  /// 像素画：保存忙碌状态
  ///
  /// In zh, this message translates to:
  /// **'保存中'**
  String get pixelArtSaving;

  /// 像素画：导出 PNG 按钮
  ///
  /// In zh, this message translates to:
  /// **'导出 PNG'**
  String get pixelArtExportPng;

  /// 像素画：导出忙碌状态
  ///
  /// In zh, this message translates to:
  /// **'导出中'**
  String get pixelArtExporting;

  /// 像素画：画布面板标题
  ///
  /// In zh, this message translates to:
  /// **'像素画画布'**
  String get pixelArtCanvasTitle;

  /// 像素画：画布键盘操作语义标签
  ///
  /// In zh, this message translates to:
  /// **'像素画画布 · {width} x {height} · 当前键盘光标第 {cursorX} 列第 {cursorY} 行，方向键移动，空格或回车绘制'**
  String pixelArtCanvasSemanticLabel(
    int width,
    int height,
    int cursorX,
    int cursorY,
  );

  /// 首页：恢复默认表单历史动作标题
  ///
  /// In zh, this message translates to:
  /// **'恢复默认表单'**
  String get homeResetDefaultsAction;

  /// 首页：恢复默认表单提示
  ///
  /// In zh, this message translates to:
  /// **'表单已重置，可用 Ctrl+Z 撤销'**
  String get homeResetDefaultsMessage;

  /// 首页：像素画保存到作品库时的标题
  ///
  /// In zh, this message translates to:
  /// **'像素画'**
  String get homePixelArtTitle;

  /// 首页：像素画保存到作品库时的来源字段
  ///
  /// In zh, this message translates to:
  /// **'像素画编辑'**
  String get homePixelArtSource;

  /// 首页：像素画保存到作品库时的提示词摘要
  ///
  /// In zh, this message translates to:
  /// **'像素画编辑 · {width} x {height}'**
  String homePixelArtPrompt(int width, int height);

  /// 首页：像素画保存历史动作标题
  ///
  /// In zh, this message translates to:
  /// **'保存像素画'**
  String get homePixelArtSaveAction;

  /// 首页：像素画保存成功提示
  ///
  /// In zh, this message translates to:
  /// **'像素画已保存到作品库：{fileName}'**
  String homePixelArtSavedMessage(Object fileName);

  /// 首页：像素画导出成功提示
  ///
  /// In zh, this message translates to:
  /// **'像素画已导出：{fileName}'**
  String homePixelArtExportedMessage(Object fileName);

  /// 首页：像素画导出失败提示
  ///
  /// In zh, this message translates to:
  /// **'导出像素画失败：{error}'**
  String homePixelArtExportFailedMessage(Object error);

  /// 首页：像素画保存失败提示
  ///
  /// In zh, this message translates to:
  /// **'保存像素画失败：{error}'**
  String homePixelArtSaveFailedMessage(Object error);

  /// 像素画：色板按钮 tooltip
  ///
  /// In zh, this message translates to:
  /// **'选择颜色'**
  String get pixelArtChooseColorTooltip;

  /// 通用图片编辑：控制面板标题
  ///
  /// In zh, this message translates to:
  /// **'通用图片编辑'**
  String get generalImageEditorTitle;

  /// 通用图片编辑：待编辑图片选择器标题
  ///
  /// In zh, this message translates to:
  /// **'待编辑图片'**
  String get generalImageEditorSourceImageTitle;

  /// 通用图片编辑：更换图片按钮
  ///
  /// In zh, this message translates to:
  /// **'更换'**
  String get generalImageEditorReplaceAction;

  /// 通用图片编辑：清除图片 tooltip
  ///
  /// In zh, this message translates to:
  /// **'清除图片'**
  String get generalImageEditorClearImageTooltip;

  /// 通用图片编辑：快捷处理区块标题
  ///
  /// In zh, this message translates to:
  /// **'快捷处理'**
  String get generalImageEditorQuickActionsTitle;

  /// 通用图片编辑：快捷处理区块说明
  ///
  /// In zh, this message translates to:
  /// **'常用导出风格与版本快照'**
  String get generalImageEditorQuickActionsSubtitle;

  /// 通用图片编辑：几何面板标签
  ///
  /// In zh, this message translates to:
  /// **'几何'**
  String get generalImageEditorGeometryTab;

  /// 通用图片编辑：外观面板标签
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get generalImageEditorAppearanceTab;

  /// 通用图片编辑：标注面板标签
  ///
  /// In zh, this message translates to:
  /// **'标注'**
  String get generalImageEditorAnnotationTab;

  /// 通用图片编辑：输出面板标签
  ///
  /// In zh, this message translates to:
  /// **'输出'**
  String get generalImageEditorOutputTab;

  /// 通用图片编辑：几何调整区块标题
  ///
  /// In zh, this message translates to:
  /// **'几何调整'**
  String get generalImageEditorGeometryTitle;

  /// 通用图片编辑：几何调整区块说明
  ///
  /// In zh, this message translates to:
  /// **'旋转、翻转、裁剪和输出尺寸'**
  String get generalImageEditorGeometrySubtitle;

  /// 通用图片编辑：外观处理区块标题
  ///
  /// In zh, this message translates to:
  /// **'外观处理'**
  String get generalImageEditorAppearanceTitle;

  /// 通用图片编辑：外观处理区块说明
  ///
  /// In zh, this message translates to:
  /// **'色彩、滤镜、锐化、透明与局部选区'**
  String get generalImageEditorAppearanceSubtitle;

  /// 通用图片编辑：标注区块说明
  ///
  /// In zh, this message translates to:
  /// **'文字、形状、箭头与标记位置'**
  String get generalImageEditorAnnotationSubtitle;

  /// 通用图片编辑：输出区块说明
  ///
  /// In zh, this message translates to:
  /// **'保存格式、质量和最终预览'**
  String get generalImageEditorOutputSubtitle;

  /// 通用图片编辑：生成完整预览按钮
  ///
  /// In zh, this message translates to:
  /// **'生成完整预览'**
  String get generalImageEditorGeneratePreview;

  /// 通用图片编辑：重置参数按钮
  ///
  /// In zh, this message translates to:
  /// **'重置参数'**
  String get generalImageEditorResetOptions;

  /// 通用图片编辑：应用并保存按钮
  ///
  /// In zh, this message translates to:
  /// **'应用并保存'**
  String get generalImageEditorApplyAndSave;

  /// 通用图片编辑：处理忙碌状态
  ///
  /// In zh, this message translates to:
  /// **'处理中'**
  String get generalImageEditorProcessing;

  /// 通用图片编辑：预览面板标题
  ///
  /// In zh, this message translates to:
  /// **'编辑预览'**
  String get generalImageEditorPreviewTitle;

  /// 通用图片编辑：未选择图片时的预览空状态
  ///
  /// In zh, this message translates to:
  /// **'选择图片后开始编辑'**
  String get generalImageEditorPreviewEmpty;

  /// 通用图片编辑：预览生成中
  ///
  /// In zh, this message translates to:
  /// **'正在生成预览'**
  String get generalImageEditorPreviewLoading;

  /// 通用图片编辑：预览失败标题
  ///
  /// In zh, this message translates to:
  /// **'预览失败'**
  String get generalImageEditorPreviewFailed;

  /// 通用图片编辑：预览无结果错误
  ///
  /// In zh, this message translates to:
  /// **'没有可用的预览结果'**
  String get generalImageEditorNoPreviewResult;

  /// 通用图片编辑：可编辑预览底部提示
  ///
  /// In zh, this message translates to:
  /// **'{fileName} · 拖拽裁剪框或选区，点击标注可删除'**
  String generalImageEditorPreviewFooter(Object fileName);

  /// 通用图片编辑：预设区块标题
  ///
  /// In zh, this message translates to:
  /// **'常用预设'**
  String get generalImageEditorPresetsTitle;

  /// 通用图片编辑：预设区块说明
  ///
  /// In zh, this message translates to:
  /// **'快速套用常见输出和处理组合'**
  String get generalImageEditorPresetsSubtitle;

  /// 通用图片编辑：透明 PNG 预设
  ///
  /// In zh, this message translates to:
  /// **'透明 PNG'**
  String get generalImageEditorTransparentPngPreset;

  /// 通用图片编辑：社媒 JPEG 预设
  ///
  /// In zh, this message translates to:
  /// **'社媒 JPEG'**
  String get generalImageEditorSocialJpegPreset;

  /// 通用图片编辑：清晰 JPEG 预设
  ///
  /// In zh, this message translates to:
  /// **'清晰 JPEG'**
  String get generalImageEditorSharpJpegPreset;

  /// 通用图片编辑：像素风 PNG 预设
  ///
  /// In zh, this message translates to:
  /// **'像素风 PNG'**
  String get generalImageEditorPixelPngPreset;

  /// 通用图片编辑：版本快照区块标题
  ///
  /// In zh, this message translates to:
  /// **'版本快照'**
  String get generalImageEditorVersionTitle;

  /// 通用图片编辑：保存当前版本按钮
  ///
  /// In zh, this message translates to:
  /// **'保存当前版本'**
  String get generalImageEditorSaveCurrentVersion;

  /// 通用图片编辑：无保存版本空状态
  ///
  /// In zh, this message translates to:
  /// **'暂无保存版本'**
  String get generalImageEditorNoSavedVersions;

  /// 通用图片编辑：自动版本标签
  ///
  /// In zh, this message translates to:
  /// **'版本 {index}'**
  String generalImageEditorVersionLabel(int index);

  /// 通用图片编辑：变换区块标题
  ///
  /// In zh, this message translates to:
  /// **'旋转与翻转'**
  String get generalImageEditorTransformTitle;

  /// 通用图片编辑：左转按钮
  ///
  /// In zh, this message translates to:
  /// **'左转'**
  String get generalImageEditorRotateLeft;

  /// 通用图片编辑：右转按钮
  ///
  /// In zh, this message translates to:
  /// **'右转'**
  String get generalImageEditorRotateRight;

  /// 通用图片编辑：水平翻转按钮和摘要
  ///
  /// In zh, this message translates to:
  /// **'水平翻转'**
  String get generalImageEditorFlipHorizontal;

  /// 通用图片编辑：垂直翻转按钮和摘要
  ///
  /// In zh, this message translates to:
  /// **'垂直翻转'**
  String get generalImageEditorFlipVertical;

  /// 通用图片编辑：裁剪区块标题
  ///
  /// In zh, this message translates to:
  /// **'裁剪边距'**
  String get generalImageEditorCropTitle;

  /// 通用图片编辑：左侧边距字段
  ///
  /// In zh, this message translates to:
  /// **'左侧'**
  String get generalImageEditorLeftSide;

  /// 通用图片编辑：上侧边距字段
  ///
  /// In zh, this message translates to:
  /// **'上侧'**
  String get generalImageEditorTopSide;

  /// 通用图片编辑：右侧边距字段
  ///
  /// In zh, this message translates to:
  /// **'右侧'**
  String get generalImageEditorRightSide;

  /// 通用图片编辑：下侧边距字段
  ///
  /// In zh, this message translates to:
  /// **'下侧'**
  String get generalImageEditorBottomSide;

  /// 通用图片编辑：清除裁剪按钮
  ///
  /// In zh, this message translates to:
  /// **'清除裁剪'**
  String get generalImageEditorClearCrop;

  /// 通用图片编辑：尺寸区块标题
  ///
  /// In zh, this message translates to:
  /// **'输出尺寸'**
  String get generalImageEditorResizeTitle;

  /// 通用图片编辑：启用尺寸调整开关
  ///
  /// In zh, this message translates to:
  /// **'调整输出尺寸'**
  String get generalImageEditorResizeOutput;

  /// 通用图片编辑：保持比例开关
  ///
  /// In zh, this message translates to:
  /// **'保持比例'**
  String get generalImageEditorLockAspectRatio;

  /// 通用图片编辑：宽度字段
  ///
  /// In zh, this message translates to:
  /// **'宽度'**
  String get generalImageEditorWidth;

  /// 通用图片编辑：高度字段
  ///
  /// In zh, this message translates to:
  /// **'高度'**
  String get generalImageEditorHeight;

  /// 通用图片编辑：色彩区块标题
  ///
  /// In zh, this message translates to:
  /// **'色彩调整'**
  String get generalImageEditorColorTitle;

  /// 通用图片编辑：亮度滑块
  ///
  /// In zh, this message translates to:
  /// **'亮度'**
  String get generalImageEditorBrightness;

  /// 通用图片编辑：对比度滑块
  ///
  /// In zh, this message translates to:
  /// **'对比度'**
  String get generalImageEditorContrast;

  /// 通用图片编辑：饱和度滑块
  ///
  /// In zh, this message translates to:
  /// **'饱和度'**
  String get generalImageEditorSaturation;

  /// 通用图片编辑：冷暖滑块
  ///
  /// In zh, this message translates to:
  /// **'冷暖'**
  String get generalImageEditorWarmth;

  /// 通用图片编辑：效果区块标题
  ///
  /// In zh, this message translates to:
  /// **'效果处理'**
  String get generalImageEditorEffectTitle;

  /// 通用图片编辑：滤镜下拉字段
  ///
  /// In zh, this message translates to:
  /// **'滤镜'**
  String get generalImageEditorFilterLabel;

  /// 通用图片编辑：模糊开关
  ///
  /// In zh, this message translates to:
  /// **'模糊'**
  String get generalImageEditorBlur;

  /// 通用图片编辑：模糊半径滑块
  ///
  /// In zh, this message translates to:
  /// **'模糊半径'**
  String get generalImageEditorBlurRadius;

  /// 通用图片编辑：锐化开关
  ///
  /// In zh, this message translates to:
  /// **'锐化'**
  String get generalImageEditorSharpen;

  /// 通用图片编辑：锐化强度滑块
  ///
  /// In zh, this message translates to:
  /// **'锐化强度'**
  String get generalImageEditorSharpenAmount;

  /// 通用图片编辑：背景透明开关
  ///
  /// In zh, this message translates to:
  /// **'边缘背景转透明'**
  String get generalImageEditorTransparentBackground;

  /// 通用图片编辑：透明容差滑块
  ///
  /// In zh, this message translates to:
  /// **'透明容差'**
  String get generalImageEditorTransparentTolerance;

  /// 通用图片编辑：像素化开关
  ///
  /// In zh, this message translates to:
  /// **'像素化'**
  String get generalImageEditorPixelation;

  /// 通用图片编辑：像素块尺寸滑块
  ///
  /// In zh, this message translates to:
  /// **'像素块'**
  String get generalImageEditorPixelBlock;

  /// 通用图片编辑：局部选区区块标题
  ///
  /// In zh, this message translates to:
  /// **'局部选区'**
  String get generalImageEditorRegionTitle;

  /// 通用图片编辑：只处理选区开关
  ///
  /// In zh, this message translates to:
  /// **'只处理选区'**
  String get generalImageEditorProcessRegionOnly;

  /// 通用图片编辑：局部选区左边界字段
  ///
  /// In zh, this message translates to:
  /// **'左边界'**
  String get generalImageEditorLeftBoundary;

  /// 通用图片编辑：局部选区上边界字段
  ///
  /// In zh, this message translates to:
  /// **'上边界'**
  String get generalImageEditorTopBoundary;

  /// 通用图片编辑：局部选区右边界字段
  ///
  /// In zh, this message translates to:
  /// **'右边界'**
  String get generalImageEditorRightBoundary;

  /// 通用图片编辑：局部选区下边界字段
  ///
  /// In zh, this message translates to:
  /// **'下边界'**
  String get generalImageEditorBottomBoundary;

  /// 通用图片编辑：设置居中半幅选区按钮
  ///
  /// In zh, this message translates to:
  /// **'居中 50%'**
  String get generalImageEditorCenterHalfRegion;

  /// 通用图片编辑：设置全图选区按钮
  ///
  /// In zh, this message translates to:
  /// **'全图选区'**
  String get generalImageEditorFullImageRegion;

  /// 通用图片编辑：标注类型字段
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get generalImageEditorAnnotationType;

  /// 通用图片编辑：标注文字字段
  ///
  /// In zh, this message translates to:
  /// **'文字'**
  String get generalImageEditorAnnotationText;

  /// 通用图片编辑：标注位置百分比说明
  ///
  /// In zh, this message translates to:
  /// **'位置百分比'**
  String get generalImageEditorAnnotationPositionPercent;

  /// 通用图片编辑：标注起点 X 字段
  ///
  /// In zh, this message translates to:
  /// **'起点 X'**
  String get generalImageEditorStartX;

  /// 通用图片编辑：标注起点 Y 字段
  ///
  /// In zh, this message translates to:
  /// **'起点 Y'**
  String get generalImageEditorStartY;

  /// 通用图片编辑：标注终点 X 字段
  ///
  /// In zh, this message translates to:
  /// **'终点 X'**
  String get generalImageEditorEndX;

  /// 通用图片编辑：标注终点 Y 字段
  ///
  /// In zh, this message translates to:
  /// **'终点 Y'**
  String get generalImageEditorEndY;

  /// 通用图片编辑：标注线宽字段
  ///
  /// In zh, this message translates to:
  /// **'线宽'**
  String get generalImageEditorStrokeWidth;

  /// 通用图片编辑：标注字号字段
  ///
  /// In zh, this message translates to:
  /// **'字号'**
  String get generalImageEditorFontSize;

  /// 通用图片编辑：填充形状开关
  ///
  /// In zh, this message translates to:
  /// **'填充形状'**
  String get generalImageEditorFillShape;

  /// 通用图片编辑：添加标注按钮
  ///
  /// In zh, this message translates to:
  /// **'添加标注'**
  String get generalImageEditorAddAnnotation;

  /// 通用图片编辑：清空标注按钮
  ///
  /// In zh, this message translates to:
  /// **'清空标注'**
  String get generalImageEditorClearAnnotations;

  /// 通用图片编辑：输出格式字段
  ///
  /// In zh, this message translates to:
  /// **'保存格式'**
  String get generalImageEditorOutputFormat;

  /// 通用图片编辑：JPEG 质量滑块
  ///
  /// In zh, this message translates to:
  /// **'JPEG 质量'**
  String get generalImageEditorJpegQuality;

  /// 通用图片编辑：旋转角度摘要
  ///
  /// In zh, this message translates to:
  /// **'旋转 {degrees}°'**
  String generalImageEditorRotatedDegrees(int degrees);

  /// 通用图片编辑：无旋转翻转摘要
  ///
  /// In zh, this message translates to:
  /// **'无变换'**
  String get generalImageEditorNoTransform;

  /// 通用图片编辑：左侧裁剪摘要
  ///
  /// In zh, this message translates to:
  /// **'左 {value}px'**
  String generalImageEditorCropLeftSummary(int value);

  /// 通用图片编辑：上侧裁剪摘要
  ///
  /// In zh, this message translates to:
  /// **'上 {value}px'**
  String generalImageEditorCropTopSummary(int value);

  /// 通用图片编辑：右侧裁剪摘要
  ///
  /// In zh, this message translates to:
  /// **'右 {value}px'**
  String generalImageEditorCropRightSummary(int value);

  /// 通用图片编辑：下侧裁剪摘要
  ///
  /// In zh, this message translates to:
  /// **'下 {value}px'**
  String generalImageEditorCropBottomSummary(int value);

  /// 通用图片编辑：无裁剪摘要
  ///
  /// In zh, this message translates to:
  /// **'无裁剪'**
  String get generalImageEditorNoCrop;

  /// 通用图片编辑：裁剪摘要
  ///
  /// In zh, this message translates to:
  /// **'裁剪 {parts}'**
  String generalImageEditorCropSummary(Object parts);

  /// 通用图片编辑：原尺寸摘要
  ///
  /// In zh, this message translates to:
  /// **'原尺寸'**
  String get generalImageEditorOriginalSize;

  /// 通用图片编辑：亮度摘要
  ///
  /// In zh, this message translates to:
  /// **'亮度 {value}%'**
  String generalImageEditorBrightnessSummary(int value);

  /// 通用图片编辑：对比度摘要
  ///
  /// In zh, this message translates to:
  /// **'对比度 {value}%'**
  String generalImageEditorContrastSummary(int value);

  /// 通用图片编辑：饱和度摘要
  ///
  /// In zh, this message translates to:
  /// **'饱和度 {value}%'**
  String generalImageEditorSaturationSummary(int value);

  /// 通用图片编辑：冷暖摘要
  ///
  /// In zh, this message translates to:
  /// **'冷暖 {value}%'**
  String generalImageEditorWarmthSummary(int value);

  /// 通用图片编辑：无色彩调整摘要
  ///
  /// In zh, this message translates to:
  /// **'无色彩调整'**
  String get generalImageEditorNoColorAdjustment;

  /// 通用图片编辑：模糊摘要
  ///
  /// In zh, this message translates to:
  /// **'模糊 {radius}px'**
  String generalImageEditorBlurSummary(int radius);

  /// 通用图片编辑：锐化摘要
  ///
  /// In zh, this message translates to:
  /// **'锐化 {amount}%'**
  String generalImageEditorSharpenSummary(int amount);

  /// 通用图片编辑：背景透明摘要
  ///
  /// In zh, this message translates to:
  /// **'背景透明'**
  String get generalImageEditorTransparentBackgroundSummary;

  /// 通用图片编辑：像素化摘要
  ///
  /// In zh, this message translates to:
  /// **'像素化 {blockSize}px'**
  String generalImageEditorPixelationSummary(int blockSize);

  /// 通用图片编辑：无效果摘要
  ///
  /// In zh, this message translates to:
  /// **'无滤镜'**
  String get generalImageEditorNoFilter;

  /// 通用图片编辑：全图处理摘要
  ///
  /// In zh, this message translates to:
  /// **'全图处理'**
  String get generalImageEditorFullImageProcessing;

  /// 通用图片编辑：无版本摘要
  ///
  /// In zh, this message translates to:
  /// **'未保存版本'**
  String get generalImageEditorNoSavedVersionSummary;

  /// 通用图片编辑：保存版本数量摘要
  ///
  /// In zh, this message translates to:
  /// **'{count} 个版本'**
  String generalImageEditorSavedVersionCount(int count);

  /// 通用图片编辑：无标注摘要
  ///
  /// In zh, this message translates to:
  /// **'无标注'**
  String get generalImageEditorNoAnnotationSummary;

  /// 通用图片编辑：标注数量摘要
  ///
  /// In zh, this message translates to:
  /// **'{count} 个标注'**
  String generalImageEditorAnnotationCount(int count);

  /// 通用图片编辑：PNG 输出摘要
  ///
  /// In zh, this message translates to:
  /// **'PNG · 支持透明'**
  String get generalImageEditorPngTransparentSummary;

  /// 通用图片编辑：版本快照原尺寸摘要
  ///
  /// In zh, this message translates to:
  /// **'原尺寸'**
  String get generalImageEditorSnapshotOriginalSize;

  /// 通用图片编辑：版本快照局部选区摘要
  ///
  /// In zh, this message translates to:
  /// **'局部选区'**
  String get generalImageEditorSnapshotLocalRegion;

  /// 通用图片编辑：版本快照标注数量摘要
  ///
  /// In zh, this message translates to:
  /// **'标注 {count}'**
  String generalImageEditorSnapshotAnnotationCount(int count);

  /// 通用图片编辑：文字标注类型
  ///
  /// In zh, this message translates to:
  /// **'文字'**
  String get generalImageEditorAnnotationKindText;

  /// 通用图片编辑：矩形标注类型
  ///
  /// In zh, this message translates to:
  /// **'矩形'**
  String get generalImageEditorAnnotationKindRectangle;

  /// 通用图片编辑：椭圆标注类型
  ///
  /// In zh, this message translates to:
  /// **'椭圆'**
  String get generalImageEditorAnnotationKindEllipse;

  /// 通用图片编辑：直线标注类型
  ///
  /// In zh, this message translates to:
  /// **'直线'**
  String get generalImageEditorAnnotationKindLine;

  /// 通用图片编辑：箭头标注类型
  ///
  /// In zh, this message translates to:
  /// **'箭头'**
  String get generalImageEditorAnnotationKindArrow;

  /// 通用图片编辑：红色色板
  ///
  /// In zh, this message translates to:
  /// **'红色'**
  String get generalImageEditorColorRed;

  /// 通用图片编辑：黄色色板
  ///
  /// In zh, this message translates to:
  /// **'黄色'**
  String get generalImageEditorColorYellow;

  /// 通用图片编辑：绿色色板
  ///
  /// In zh, this message translates to:
  /// **'绿色'**
  String get generalImageEditorColorGreen;

  /// 通用图片编辑：蓝色色板
  ///
  /// In zh, this message translates to:
  /// **'蓝色'**
  String get generalImageEditorColorBlue;

  /// 通用图片编辑：黑色色板
  ///
  /// In zh, this message translates to:
  /// **'黑色'**
  String get generalImageEditorColorBlack;

  /// 通用图片编辑：白色色板
  ///
  /// In zh, this message translates to:
  /// **'白色'**
  String get generalImageEditorColorWhite;

  /// 通用图片编辑：自定义颜色
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get generalImageEditorColorCustom;

  /// 通用图片编辑：标注描述的填充后缀
  ///
  /// In zh, this message translates to:
  /// **'填充'**
  String get generalImageEditorAnnotationFilledSuffix;

  /// 通用图片编辑：恢复版本 tooltip
  ///
  /// In zh, this message translates to:
  /// **'恢复版本'**
  String get generalImageEditorRestoreVersionTooltip;

  /// 通用图片编辑：删除版本 tooltip
  ///
  /// In zh, this message translates to:
  /// **'删除版本'**
  String get generalImageEditorDeleteVersionTooltip;

  /// 通用图片编辑：删除标注 tooltip
  ///
  /// In zh, this message translates to:
  /// **'删除标注'**
  String get generalImageEditorDeleteAnnotationTooltip;

  /// 通用图片编辑：删除选中标注 tooltip
  ///
  /// In zh, this message translates to:
  /// **'删除选中的标注'**
  String get generalImageEditorDeleteSelectedAnnotationTooltip;

  /// 通用图片编辑：预览图片加载失败
  ///
  /// In zh, this message translates to:
  /// **'图片加载失败'**
  String get generalImageEditorImageLoadFailed;

  /// 通用图片编辑：原色滤镜标签
  ///
  /// In zh, this message translates to:
  /// **'原色'**
  String get generalImageEditorEffectOriginal;

  /// 通用图片编辑：灰度滤镜标签
  ///
  /// In zh, this message translates to:
  /// **'灰度'**
  String get generalImageEditorEffectGrayscale;

  /// 通用图片编辑：复古滤镜标签
  ///
  /// In zh, this message translates to:
  /// **'复古'**
  String get generalImageEditorEffectSepia;

  /// 通用图片编辑：反相滤镜标签
  ///
  /// In zh, this message translates to:
  /// **'反相'**
  String get generalImageEditorEffectInvert;

  /// 通用图片编辑摘要：裁剪
  ///
  /// In zh, this message translates to:
  /// **'裁剪'**
  String get generalImageEditSummaryCrop;

  /// 通用图片编辑摘要：旋转模板，%degrees% 会替换为角度
  ///
  /// In zh, this message translates to:
  /// **'旋转 %degrees%°'**
  String get generalImageEditSummaryRotatePattern;

  /// 通用图片编辑摘要：缩放模板，%width%/%height% 会替换为尺寸
  ///
  /// In zh, this message translates to:
  /// **'缩放 %width% x %height%'**
  String get generalImageEditSummaryResizePattern;

  /// 通用图片编辑摘要：标注数量模板，%count% 会替换为数量
  ///
  /// In zh, this message translates to:
  /// **'标注 %count% 个'**
  String get generalImageEditSummaryAnnotationPattern;

  /// 通用图片编辑摘要：JPEG 质量模板，%quality% 会替换为质量
  ///
  /// In zh, this message translates to:
  /// **'JPEG %quality%质量'**
  String get generalImageEditSummaryJpegQualityPattern;

  /// 通用图片编辑摘要：未做编辑时的保存副本摘要
  ///
  /// In zh, this message translates to:
  /// **'保存副本'**
  String get generalImageEditSummarySaveCopy;

  /// 通用图片编辑摘要：多个摘要片段之间的分隔符
  ///
  /// In zh, this message translates to:
  /// **' · '**
  String get generalImageEditSummarySeparator;

  /// 通用图片编辑摘要：模糊半径模板，%radius% 会替换为半径
  ///
  /// In zh, this message translates to:
  /// **'模糊 %radius%px'**
  String get generalImageEditSummaryBlurPattern;

  /// 通用图片编辑摘要：锐化强度模板，%amount% 会替换为百分比
  ///
  /// In zh, this message translates to:
  /// **'锐化 %amount%%'**
  String get generalImageEditSummarySharpenPattern;

  /// 通用图片编辑摘要：像素化块大小模板，%blockSize% 会替换为像素块
  ///
  /// In zh, this message translates to:
  /// **'像素化 %blockSize%px'**
  String get generalImageEditSummaryPixelationPattern;

  /// 通用：帧数量徽标默认单位
  ///
  /// In zh, this message translates to:
  /// **'帧'**
  String get frameCountBadgeDefaultLabel;

  /// 通用：数量徽标 tooltip
  ///
  /// In zh, this message translates to:
  /// **'共 {count} {label}'**
  String frameCountBadgeTooltip(int count, Object label);

  /// 通用：像素数字步进减少 tooltip
  ///
  /// In zh, this message translates to:
  /// **'{label}减少 1px'**
  String sharedDecreasePxTooltip(Object label);

  /// 通用：像素数字步进增加 tooltip
  ///
  /// In zh, this message translates to:
  /// **'{label}增加 1px'**
  String sharedIncreasePxTooltip(Object label);

  /// 通用：数字步进减少 tooltip
  ///
  /// In zh, this message translates to:
  /// **'{label}减少 1'**
  String sharedDecreaseTooltip(Object label);

  /// 通用：数字步进增加 tooltip
  ///
  /// In zh, this message translates to:
  /// **'{label}增加 1'**
  String sharedIncreaseTooltip(Object label);

  /// Sprite Sheet 网格校准标题
  ///
  /// In zh, this message translates to:
  /// **'切片校准'**
  String get spriteSheetGridSpecTitle;

  /// Sprite Sheet 网格校准已调整徽标
  ///
  /// In zh, this message translates to:
  /// **'已调整'**
  String get spriteSheetGridSpecAdjusted;

  /// Sprite Sheet 网格校准说明
  ///
  /// In zh, this message translates to:
  /// **'用于处理 Sprite Sheet 外边距或格子间隔，预览、切片和替换都会按这里计算。'**
  String get spriteSheetGridSpecDescription;

  /// Sprite Sheet 网格校准左边距字段
  ///
  /// In zh, this message translates to:
  /// **'左边距'**
  String get spriteSheetGridMarginLeft;

  /// Sprite Sheet 网格校准上边距字段
  ///
  /// In zh, this message translates to:
  /// **'上边距'**
  String get spriteSheetGridMarginTop;

  /// Sprite Sheet 网格校准右边距字段
  ///
  /// In zh, this message translates to:
  /// **'右边距'**
  String get spriteSheetGridMarginRight;

  /// Sprite Sheet 网格校准下边距字段
  ///
  /// In zh, this message translates to:
  /// **'下边距'**
  String get spriteSheetGridMarginBottom;

  /// Sprite Sheet 网格校准列间距字段
  ///
  /// In zh, this message translates to:
  /// **'列间距'**
  String get spriteSheetGridColumnGap;

  /// Sprite Sheet 网格校准行间距字段
  ///
  /// In zh, this message translates to:
  /// **'行间距'**
  String get spriteSheetGridRowGap;

  /// Sprite Sheet 网格校准重置按钮
  ///
  /// In zh, this message translates to:
  /// **'重置切片校准'**
  String get spriteSheetGridReset;

  /// Sprite Sheet 网格校准左边距摘要
  ///
  /// In zh, this message translates to:
  /// **'左 {value}px'**
  String spriteSheetGridMarginLeftSummary(int value);

  /// Sprite Sheet 网格校准上边距摘要
  ///
  /// In zh, this message translates to:
  /// **'上 {value}px'**
  String spriteSheetGridMarginTopSummary(int value);

  /// Sprite Sheet 网格校准右边距摘要
  ///
  /// In zh, this message translates to:
  /// **'右 {value}px'**
  String spriteSheetGridMarginRightSummary(int value);

  /// Sprite Sheet 网格校准下边距摘要
  ///
  /// In zh, this message translates to:
  /// **'下 {value}px'**
  String spriteSheetGridMarginBottomSummary(int value);

  /// Sprite Sheet 网格校准列间距摘要
  ///
  /// In zh, this message translates to:
  /// **'列间距 {value}px'**
  String spriteSheetGridColumnGapSummary(int value);

  /// Sprite Sheet 网格校准行间距摘要
  ///
  /// In zh, this message translates to:
  /// **'行间距 {value}px'**
  String spriteSheetGridRowGapSummary(int value);

  /// Sprite Sheet 网格校准默认摘要
  ///
  /// In zh, this message translates to:
  /// **'默认：无边距 / 无间距'**
  String get spriteSheetGridSpecDefaultSummary;

  /// 请求调试按钮不可用 tooltip
  ///
  /// In zh, this message translates to:
  /// **'生成后可查看请求和返回值'**
  String get requestDebugUnavailableTooltip;

  /// 请求调试按钮可用 tooltip
  ///
  /// In zh, this message translates to:
  /// **'查看请求参数和返回值'**
  String get requestDebugAvailableTooltip;

  /// 请求调试按钮标签
  ///
  /// In zh, this message translates to:
  /// **'调试详情'**
  String get requestDebugButtonLabel;

  /// 请求调试弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'请求调试详情'**
  String get requestDebugDialogTitle;

  /// 请求调试详情复制成功提示
  ///
  /// In zh, this message translates to:
  /// **'调试详情已复制。'**
  String get requestDebugCopied;

  /// 模板图片选择器默认标题
  ///
  /// In zh, this message translates to:
  /// **'模板图片'**
  String get templateImagePickerDefaultTitle;

  /// 模板图片选择器清除 tooltip
  ///
  /// In zh, this message translates to:
  /// **'清除模板图片'**
  String get templateImagePickerClearTooltip;

  /// 模板图片选择器加载失败提示
  ///
  /// In zh, this message translates to:
  /// **'模板图片加载失败。'**
  String get templateImagePickerLoadFailed;

  /// 图片高级输出参数标题
  ///
  /// In zh, this message translates to:
  /// **'高级输出参数'**
  String get imageAdvancedSettingsTitle;

  /// 图片高级输出参数摘要质量后缀
  ///
  /// In zh, this message translates to:
  /// **'质量'**
  String get imageAdvancedSettingsQualitySuffix;

  /// 图片高级输出参数摘要背景后缀
  ///
  /// In zh, this message translates to:
  /// **'背景'**
  String get imageAdvancedSettingsBackgroundSuffix;

  /// 图片高级输出参数质量字段
  ///
  /// In zh, this message translates to:
  /// **'质量'**
  String get imageAdvancedSettingsQuality;

  /// 图片高级输出参数背景字段
  ///
  /// In zh, this message translates to:
  /// **'背景'**
  String get imageAdvancedSettingsBackground;

  /// 图片高级输出参数输出格式字段
  ///
  /// In zh, this message translates to:
  /// **'输出格式'**
  String get imageAdvancedSettingsOutputFormat;

  /// 图片高级输出参数审核强度字段
  ///
  /// In zh, this message translates to:
  /// **'审核强度'**
  String get imageAdvancedSettingsModeration;

  /// 图片高级输出参数最终用户 ID 字段
  ///
  /// In zh, this message translates to:
  /// **'最终用户 ID'**
  String get imageAdvancedSettingsFinalUserId;

  /// 图片高级输出参数最终用户 ID 提示
  ///
  /// In zh, this message translates to:
  /// **'可选，用于 OpenAI 滥用监控'**
  String get imageAdvancedSettingsFinalUserHint;

  /// 图片高级输出参数参考图保真度字段
  ///
  /// In zh, this message translates to:
  /// **'参考图保真度'**
  String get imageAdvancedSettingsInputFidelity;

  /// 图片高级输出参数高选项
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get imageAdvancedSettingsHigh;

  /// 图片高级输出参数低选项
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get imageAdvancedSettingsLow;

  /// 图片高级输出参数压缩率当前值
  ///
  /// In zh, this message translates to:
  /// **'输出压缩率 {value}%'**
  String imageAdvancedSettingsCompressionValue(int value);

  /// 图片高级输出参数压缩率不可用提示
  ///
  /// In zh, this message translates to:
  /// **'输出压缩率仅用于 JPEG / WebP'**
  String get imageAdvancedSettingsCompressionUnavailable;

  /// 图片尺寸输入宽度字段
  ///
  /// In zh, this message translates to:
  /// **'宽度'**
  String get imageSizeWidth;

  /// 图片尺寸输入高度字段
  ///
  /// In zh, this message translates to:
  /// **'高度'**
  String get imageSizeHeight;

  /// 图片尺寸输入自定义尺寸选项
  ///
  /// In zh, this message translates to:
  /// **'自定义尺寸'**
  String get imageSizeCustomSize;

  /// 图片尺寸输入尺寸档位字段
  ///
  /// In zh, this message translates to:
  /// **'尺寸档位'**
  String get imageSizeScaleLabel;

  /// 图片尺寸输入方向字段
  ///
  /// In zh, this message translates to:
  /// **'方向'**
  String get imageSizeOrientation;

  /// 图片尺寸方向：方图
  ///
  /// In zh, this message translates to:
  /// **'方图'**
  String get imageAspectSquare;

  /// 图片尺寸方向：横图
  ///
  /// In zh, this message translates to:
  /// **'横图'**
  String get imageAspectLandscape;

  /// 图片尺寸方向：竖图
  ///
  /// In zh, this message translates to:
  /// **'竖图'**
  String get imageAspectPortrait;

  /// 图片尺寸预设标签
  ///
  /// In zh, this message translates to:
  /// **'{scale} {orientation}'**
  String imageSizePresetLabel(Object scale, Object orientation);

  /// 图片尺寸预设超宽屏标签
  ///
  /// In zh, this message translates to:
  /// **'{scale} 宽屏'**
  String imageSizePresetWide(Object scale);

  /// 图片尺寸输入约束说明
  ///
  /// In zh, this message translates to:
  /// **'{minSide}-{maxSide}，{step}px 倍数'**
  String imageSizeConstraintHelper(int minSide, int maxSide, int step);

  /// 图片尺寸输入无效兜底提示
  ///
  /// In zh, this message translates to:
  /// **'当前图片尺寸无效。'**
  String get imageSizeInvalidFallback;

  /// 图片尺寸输入宽高无法解析提示
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的宽度和高度。'**
  String get imageSizeInvalidDimensions;

  /// 图片尺寸输入固定分辨率校验提示
  ///
  /// In zh, this message translates to:
  /// **'当前模型只支持固定分辨率：{presetSizes}。'**
  String imageSizeFixedPresetsOnly(Object presetSizes);

  /// 图片尺寸输入边长过小提示
  ///
  /// In zh, this message translates to:
  /// **'宽高都不能小于 {minSide}px。'**
  String imageSizeSideTooSmall(int minSide);

  /// 图片尺寸输入边长过大提示
  ///
  /// In zh, this message translates to:
  /// **'宽高都不能超过 {maxSide}px。'**
  String imageSizeSideTooLarge(int maxSide);

  /// 图片尺寸输入步长不匹配提示
  ///
  /// In zh, this message translates to:
  /// **'宽高都必须是 {step}px 的倍数。'**
  String imageSizeSideStepMismatch(int step);

  /// 图片尺寸输入长宽比过大提示
  ///
  /// In zh, this message translates to:
  /// **'长边不能超过短边的 {maxAspectRatio} 倍。'**
  String imageSizeAspectRatioTooLarge(int maxAspectRatio);

  /// 图片尺寸输入总像素过低提示
  ///
  /// In zh, this message translates to:
  /// **'总像素不能低于 {minPixels}。'**
  String imageSizeTotalPixelsTooSmall(int minPixels);

  /// 图片尺寸输入总像素过高提示
  ///
  /// In zh, this message translates to:
  /// **'总像素不能超过 {maxPixels}。'**
  String imageSizeTotalPixelsTooLarge(int maxPixels);

  /// 图片尺寸输入 Gemini 画幅比例摘要
  ///
  /// In zh, this message translates to:
  /// **'{label} · Gemini 画幅比例 {aspectRatio}'**
  String imageSizeGeminiAspectSummary(Object label, Object aspectRatio);

  /// 图片尺寸输入自定义请求尺寸摘要
  ///
  /// In zh, this message translates to:
  /// **'自定义尺寸 · 请求尺寸 {size}'**
  String imageSizeCustomRequestSummary(Object size);

  /// 图片尺寸输入请求尺寸摘要
  ///
  /// In zh, this message translates to:
  /// **'{label} · 请求尺寸 {size}'**
  String imageSizeRequestSummary(Object label, Object size);

  /// 图片尺寸输入固定分辨率兜底标签
  ///
  /// In zh, this message translates to:
  /// **'固定分辨率'**
  String get imageSizeFixedResolution;

  /// 图片尺寸模式：分辨率
  ///
  /// In zh, this message translates to:
  /// **'分辨率'**
  String get imageSizeModeResolution;

  /// 图片尺寸模式：画幅比例
  ///
  /// In zh, this message translates to:
  /// **'画幅比例'**
  String get imageSizeModeAspectRatio;

  /// 图片尺寸模式：分辨率档位
  ///
  /// In zh, this message translates to:
  /// **'分辨率档位'**
  String get imageSizeModeFixedPresets;

  /// 图片尺寸能力：自动识别
  ///
  /// In zh, this message translates to:
  /// **'自动识别'**
  String get imageSizeCapabilityAuto;

  /// 图片尺寸能力：固定分辨率
  ///
  /// In zh, this message translates to:
  /// **'固定分辨率'**
  String get imageSizeCapabilityFixedPresets;

  /// 图片尺寸能力：自定义像素尺寸
  ///
  /// In zh, this message translates to:
  /// **'自定义像素尺寸'**
  String get imageSizeCapabilityCustomPixels;

  /// 图片尺寸能力：画幅比例
  ///
  /// In zh, this message translates to:
  /// **'画幅比例'**
  String get imageSizeCapabilityAspectRatio;

  /// 图片尺寸能力：Gemini 画幅比例
  ///
  /// In zh, this message translates to:
  /// **'Gemini 画幅比例'**
  String get imageSizeCapabilityGeminiAspectRatio;

  /// 图片尺寸能力固定档位说明
  ///
  /// In zh, this message translates to:
  /// **'仅允许固定档位：{presetSizes}。'**
  String imageSizeCapabilityFixedDescription(Object presetSizes);

  /// 图片尺寸能力自定义像素说明
  ///
  /// In zh, this message translates to:
  /// **'允许固定档位或自定义宽高，宽高必须是 {step}px 倍数。'**
  String imageSizeCapabilityCustomDescription(int step);

  /// 图片尺寸能力 Gemini 画幅比例说明
  ///
  /// In zh, this message translates to:
  /// **'按所选尺寸换算为最接近的 Gemini 画幅比例。'**
  String get imageSizeCapabilityAspectDescription;

  /// 图片编辑工作区标题
  ///
  /// In zh, this message translates to:
  /// **'图片编辑'**
  String get imageEditorWorkspaceTitle;

  /// 图片编辑工作区普通图片模式说明
  ///
  /// In zh, this message translates to:
  /// **'裁剪、旋转、缩放、调色和保存图片副本'**
  String get imageEditorWorkspaceGeneralDescription;

  /// 图片编辑工作区 Sprite Sheet 模式说明
  ///
  /// In zh, this message translates to:
  /// **'载入一张 Sprite Sheet，按行列快速查看第几帧'**
  String get imageEditorWorkspaceSpriteSheetDescription;

  /// 图片编辑工作区普通图片模式标签
  ///
  /// In zh, this message translates to:
  /// **'普通图片'**
  String get imageEditorGeneralImageTab;

  /// 图片编辑工作区 Sprite Sheet 模式标签
  ///
  /// In zh, this message translates to:
  /// **'Sprite Sheet'**
  String get imageEditorSpriteSheetTab;

  /// 图片编辑工作区退出专注模式 tooltip
  ///
  /// In zh, this message translates to:
  /// **'退出专注模式'**
  String get imageEditorExitFocusModeTooltip;

  /// 图片编辑工作区进入专注模式 tooltip
  ///
  /// In zh, this message translates to:
  /// **'进入专注模式'**
  String get imageEditorEnterFocusModeTooltip;

  /// 图片编辑工作区切片预览标题
  ///
  /// In zh, this message translates to:
  /// **'切片查看'**
  String get imageEditorSlicePreviewTitle;

  /// 图片编辑工作区切片预览空状态
  ///
  /// In zh, this message translates to:
  /// **'选择一张 Sprite Sheet 后，可以按行列查看第几帧'**
  String get imageEditorSlicePreviewEmpty;

  /// 图片编辑：调整行数历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整行数为 {value} 行'**
  String editorGifAdjustRowsHistory(int value);

  /// 图片编辑：调整列数历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整列数为 {value} 列'**
  String editorGifAdjustColumnsHistory(int value);

  /// 图片编辑：调整切片校准历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整切片校准'**
  String get editorGifAdjustGridSpecHistory;

  /// 图片编辑：调整适配方式历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整适配方式为 {label}'**
  String editorGifAdjustFrameFitHistory(Object label);

  /// 图片编辑：选择 Sprite Sheet 图片标题
  ///
  /// In zh, this message translates to:
  /// **'选择 Sprite Sheet 图片'**
  String get editorGifSelectSpriteSheetTitle;

  /// 图片编辑：Sprite Sheet 作品库为空提示
  ///
  /// In zh, this message translates to:
  /// **'生成或导出 Sprite Sheet 后可从这里复用'**
  String get editorGifSpriteSheetLibraryEmpty;

  /// 图片编辑：载入 Sprite Sheet 历史动作
  ///
  /// In zh, this message translates to:
  /// **'载入 Sprite Sheet'**
  String get editorGifLoadSpriteSheetHistory;

  /// 图片编辑：载入图片成功提示
  ///
  /// In zh, this message translates to:
  /// **'已载入图片：{fileName}'**
  String editorGifLoadedImageMessage(Object fileName);

  /// 图片编辑：清空 Sprite Sheet 历史动作
  ///
  /// In zh, this message translates to:
  /// **'清空 Sprite Sheet'**
  String get editorGifClearSpriteSheetHistory;

  /// 图片编辑：选择单帧图片标题
  ///
  /// In zh, this message translates to:
  /// **'选择单帧图片'**
  String get editorGifSelectSingleFrameTitle;

  /// 图片编辑：单帧图片作品库为空提示
  ///
  /// In zh, this message translates to:
  /// **'保存到作品库后的单帧图片会显示在这里'**
  String get editorGifSingleFrameLibraryEmpty;

  /// 图片编辑：选择单帧图片历史动作
  ///
  /// In zh, this message translates to:
  /// **'选择单帧图片'**
  String get editorGifSelectSingleFrameHistory;

  /// 图片编辑：选择单帧图片成功提示
  ///
  /// In zh, this message translates to:
  /// **'已选择单帧图片：{fileName}'**
  String editorGifLoadedSingleFrameMessage(Object fileName);

  /// 图片编辑：清空单帧图片历史动作
  ///
  /// In zh, this message translates to:
  /// **'清空单帧图片'**
  String get editorGifClearSingleFrameHistory;

  /// 图片编辑：未选择单帧图片提示
  ///
  /// In zh, this message translates to:
  /// **'请先选择一张单帧图片'**
  String get editorGifPleaseSelectSingleFrame;

  /// 图片编辑：背景转透明无可处理像素提示
  ///
  /// In zh, this message translates to:
  /// **'没有检测到可透明化的边缘背景，可尝试调高容差'**
  String get editorGifNoTransparentEdgeMessage;

  /// 图片编辑：透明背景单帧作品标题
  ///
  /// In zh, this message translates to:
  /// **'透明背景单帧'**
  String get editorGifTransparentBackgroundTitle;

  /// 图片编辑：透明背景单帧来源字段
  ///
  /// In zh, this message translates to:
  /// **'图片编辑'**
  String get editorGifTransparentBackgroundSource;

  /// 图片编辑：透明背景单帧提示词摘要
  ///
  /// In zh, this message translates to:
  /// **'背景转透明 · 容差 {tolerance} · {width} x {height}'**
  String editorGifTransparentBackgroundPrompt(
    int tolerance,
    int width,
    int height,
  );

  /// 图片编辑：透明背景单帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'背景转透明单帧'**
  String get editorGifTransparentBackgroundHistory;

  /// 图片编辑：透明背景单帧成功提示
  ///
  /// In zh, this message translates to:
  /// **'已生成透明背景单帧：{fileName} · 透明化 {count} 个像素'**
  String editorGifTransparentBackgroundSavedMessage(Object fileName, int count);

  /// 图片编辑：透明背景单帧失败提示
  ///
  /// In zh, this message translates to:
  /// **'背景转透明失败：{error}'**
  String editorGifTransparentBackgroundFailedMessage(Object error);

  /// 图片编辑：未选择 Sprite Sheet 提示
  ///
  /// In zh, this message translates to:
  /// **'请先选择一张 Sprite Sheet'**
  String get editorGifPleaseSelectSpriteSheet;

  /// 图片编辑：取景单帧作品标题
  ///
  /// In zh, this message translates to:
  /// **'取景单帧'**
  String get editorGifFramedSingleFrameTitle;

  /// 图片编辑：取景单帧提示词摘要
  ///
  /// In zh, this message translates to:
  /// **'单帧取景 · {width} x {height}'**
  String editorGifFramedSingleFramePrompt(int width, int height);

  /// 图片编辑：调整单帧取景历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整单帧取景'**
  String get editorGifAdjustFramingHistory;

  /// 图片编辑：取景单帧成功提示
  ///
  /// In zh, this message translates to:
  /// **'已生成取景单帧：{fileName} · {width} x {height}'**
  String editorGifFramedSingleFrameSavedMessage(
    Object fileName,
    int width,
    int height,
  );

  /// 图片编辑：调整取景失败提示
  ///
  /// In zh, this message translates to:
  /// **'调整取景失败：{error}'**
  String editorGifAdjustFramingFailedMessage(Object error);

  /// 图片编辑：选择模板图片标题
  ///
  /// In zh, this message translates to:
  /// **'选择模板图片'**
  String get editorGifSelectTemplateTitle;

  /// 图片编辑：模板图片作品库为空提示
  ///
  /// In zh, this message translates to:
  /// **'保存到作品库后的图片会显示在这里'**
  String get editorGifTemplateLibraryEmpty;

  /// 图片编辑：选择模板切片成功提示
  ///
  /// In zh, this message translates to:
  /// **'已选择模板切片：{sliceLabel}'**
  String editorGifSelectedTemplateSliceMessage(Object sliceLabel);

  /// 图片编辑：选择模板图片成功提示
  ///
  /// In zh, this message translates to:
  /// **'已选择模板图片：{fileName}'**
  String editorGifSelectedTemplateImageMessage(Object fileName);

  /// 图片编辑：作品库来源字段
  ///
  /// In zh, this message translates to:
  /// **'图片编辑'**
  String get editorGifImageEditorSource;

  /// 图片编辑：模板切片选择标签
  ///
  /// In zh, this message translates to:
  /// **'{title} · 帧 {frame}'**
  String editorGifTemplateSliceLabel(Object title, int frame);

  /// 图片编辑：导出 GIF 帧数不足提示
  ///
  /// In zh, this message translates to:
  /// **'至少需要 2 帧才能合成 GIF'**
  String get editorGifNeedAtLeastTwoFrames;

  /// 图片编辑：快速 GIF 临时工程标题
  ///
  /// In zh, this message translates to:
  /// **'Sprite Sheet 快速 GIF'**
  String get editorGifQuickGifProjectTitle;

  /// 图片编辑：导出 Sprite Sheet GIF 历史动作
  ///
  /// In zh, this message translates to:
  /// **'导出 Sprite Sheet GIF'**
  String get editorGifExportSpriteSheetGifHistory;

  /// 图片编辑：GIF 导出成功提示
  ///
  /// In zh, this message translates to:
  /// **'GIF 已生成：{fileName} · 目录：{directoryPath}'**
  String editorGifExportGifSavedMessage(Object fileName, Object directoryPath);

  /// 图片编辑：GIF 导出失败提示
  ///
  /// In zh, this message translates to:
  /// **'导出 GIF 失败：{error}'**
  String editorGifExportGifFailedMessage(Object error);

  /// 图片编辑：导出 Sprite Sheet 历史动作
  ///
  /// In zh, this message translates to:
  /// **'导出 Sprite Sheet'**
  String get editorGifExportSpriteSheetHistory;

  /// 图片编辑：Sprite Sheet 导出成功提示
  ///
  /// In zh, this message translates to:
  /// **'已导出 Sprite Sheet：{fileName} · 目录：{directoryPath}'**
  String editorGifExportSpriteSheetSavedMessage(
    Object fileName,
    Object directoryPath,
  );

  /// 图片编辑：替换帧前未选择单帧图片提示
  ///
  /// In zh, this message translates to:
  /// **'请先选择要插入的单帧图片'**
  String get editorGifPleaseSelectPatchForInsert;

  /// 图片编辑：替换帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'替换第 {index} 帧'**
  String editorGifReplaceFrameHistory(int index);

  /// 图片编辑：替换帧成功提示
  ///
  /// In zh, this message translates to:
  /// **'已替换第 {index} 帧：{fileName} · 目录：{directoryPath}'**
  String editorGifReplaceFrameSavedMessage(
    int index,
    Object fileName,
    Object directoryPath,
  );

  /// 图片编辑：替换帧失败提示
  ///
  /// In zh, this message translates to:
  /// **'单帧替换失败：{error}'**
  String editorGifReplaceFrameFailedMessage(Object error);

  /// 图片编辑：第一帧无法复制上一帧提示
  ///
  /// In zh, this message translates to:
  /// **'第 1 帧没有上一帧可复制'**
  String get editorGifFirstFrameNoPrevious;

  /// 图片编辑：复制上一帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'复制上一帧到第 {index} 帧'**
  String editorGifCopyPreviousFrameHistory(int index);

  /// 图片编辑：复制上一帧成功提示
  ///
  /// In zh, this message translates to:
  /// **'已复制上一帧到第 {index} 帧'**
  String editorGifCopyPreviousFrameMessage(int index);

  /// 图片编辑：复制帧失败提示
  ///
  /// In zh, this message translates to:
  /// **'复制帧失败：{error}'**
  String editorGifCopyFrameFailedMessage(Object error);

  /// 图片编辑：清空帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'清空第 {index} 帧'**
  String editorGifClearFrameHistory(int index);

  /// 图片编辑：清空帧成功提示
  ///
  /// In zh, this message translates to:
  /// **'已清空第 {index} 帧'**
  String editorGifClearFrameMessage(int index);

  /// 图片编辑：清空帧失败提示
  ///
  /// In zh, this message translates to:
  /// **'清空帧失败：{error}'**
  String editorGifClearFrameFailedMessage(Object error);

  /// 图片编辑：像素化 Sprite Sheet 作品标题
  ///
  /// In zh, this message translates to:
  /// **'像素化 Sprite Sheet'**
  String get editorGifPixelatedSpriteSheetTitle;

  /// 图片编辑：像素化单帧提示词摘要
  ///
  /// In zh, this message translates to:
  /// **'像素化第 {index} 帧 · 像素块 {blockSize}px · {rows} x {columns}'**
  String editorGifPixelatedFramePrompt(
    int index,
    int blockSize,
    int rows,
    int columns,
  );

  /// 图片编辑：像素化单帧历史动作
  ///
  /// In zh, this message translates to:
  /// **'像素化第 {index} 帧'**
  String editorGifPixelateFrameHistory(int index);

  /// 图片编辑：像素化单帧成功提示
  ///
  /// In zh, this message translates to:
  /// **'已像素化第 {index} 帧：{fileName} · 像素块 {blockSize}px'**
  String editorGifPixelateFrameSavedMessage(
    int index,
    Object fileName,
    int blockSize,
  );

  /// 图片编辑：像素化当前帧失败提示
  ///
  /// In zh, this message translates to:
  /// **'像素化当前帧失败：{error}'**
  String editorGifPixelateCurrentFrameFailedMessage(Object error);

  /// 图片编辑：像素化整张 Sprite Sheet 提示词摘要
  ///
  /// In zh, this message translates to:
  /// **'像素化整张 · 像素块 {blockSize}px · {rows} x {columns}'**
  String editorGifPixelatedWholeSheetPrompt(
    int blockSize,
    int rows,
    int columns,
  );

  /// 图片编辑：像素化整张 Sprite Sheet 历史动作
  ///
  /// In zh, this message translates to:
  /// **'像素化整张 Sprite Sheet'**
  String get editorGifPixelateWholeSheetHistory;

  /// 图片编辑：像素化整张 Sprite Sheet 成功提示
  ///
  /// In zh, this message translates to:
  /// **'已像素化整张 Sprite Sheet：{fileName} · 像素块 {blockSize}px'**
  String editorGifPixelateWholeSheetSavedMessage(
    Object fileName,
    int blockSize,
  );

  /// 图片编辑：像素化整张 Sprite Sheet 失败提示
  ///
  /// In zh, this message translates to:
  /// **'像素化整张失败：{error}'**
  String editorGifPixelateWholeSheetFailedMessage(Object error);

  /// 图片编辑：选择通用编辑图片标题
  ///
  /// In zh, this message translates to:
  /// **'选择要编辑的图片'**
  String get editorGifSelectImageToEditTitle;

  /// 图片编辑：通用图片作品库为空提示
  ///
  /// In zh, this message translates to:
  /// **'作品库里保存的图片会显示在这里'**
  String get editorGifGeneralImageLibraryEmpty;

  /// 图片编辑：通用图片载入成功提示
  ///
  /// In zh, this message translates to:
  /// **'已载入图片：{fileName}'**
  String editorGifGeneralImageLoadedMessage(Object fileName);

  /// 图片编辑：通用图片读取失败提示
  ///
  /// In zh, this message translates to:
  /// **'图片读取失败：{error}'**
  String editorGifImageReadFailedMessage(Object error);

  /// 图片编辑：未选择通用图片提示
  ///
  /// In zh, this message translates to:
  /// **'请先选择一张图片'**
  String get editorGifPleaseSelectImage;

  /// 图片编辑：通用编辑结果作品标题
  ///
  /// In zh, this message translates to:
  /// **'编辑后的图片'**
  String get editorGifEditedImageTitle;

  /// 图片编辑：通用图片编辑历史动作
  ///
  /// In zh, this message translates to:
  /// **'编辑图片'**
  String get editorGifEditImageHistory;

  /// 图片编辑：通用图片编辑成功提示
  ///
  /// In zh, this message translates to:
  /// **'已保存编辑结果：{fileName} · {summary}'**
  String editorGifEditImageSavedMessage(Object fileName, Object summary);

  /// 图片编辑：通用图片编辑失败提示
  ///
  /// In zh, this message translates to:
  /// **'图片编辑失败：{error}'**
  String editorGifEditImageFailedMessage(Object error);

  /// Sprite Sheet 预览：生成失败进度提示
  ///
  /// In zh, this message translates to:
  /// **'Sprite Sheet 生成失败，可调整参数后重试。{message}'**
  String framePreviewProgressFailed(Object message);

  /// Sprite Sheet 预览：生成中进度提示
  ///
  /// In zh, this message translates to:
  /// **'正在生成 1 张 Sprite Sheet，完成后会按 {totalCount} 格切片预览。'**
  String framePreviewProgressGenerating(int totalCount);

  /// Sprite Sheet 预览：生成完成进度提示
  ///
  /// In zh, this message translates to:
  /// **'已生成 1 张 Sprite Sheet，并按 {totalCount} 格切片预览。'**
  String framePreviewProgressReady(int totalCount);

  /// Sprite Sheet 预览：缩小播放帧 tooltip
  ///
  /// In zh, this message translates to:
  /// **'缩小播放帧'**
  String get framePreviewZoomOutTooltip;

  /// Sprite Sheet 预览：放大播放帧 tooltip
  ///
  /// In zh, this message translates to:
  /// **'放大播放帧'**
  String get framePreviewZoomInTooltip;

  /// Sprite Sheet 预览：重置播放帧缩放 tooltip
  ///
  /// In zh, this message translates to:
  /// **'重置播放帧缩放'**
  String get framePreviewResetZoomTooltip;

  /// Sprite Sheet 预览：生成中空状态
  ///
  /// In zh, this message translates to:
  /// **'正在生成 Sprite Sheet'**
  String get framePreviewGeneratingSheet;

  /// Sprite Sheet 预览：生成失败标题
  ///
  /// In zh, this message translates to:
  /// **'生成失败'**
  String get framePreviewGenerationFailedTitle;

  /// Sprite Sheet 预览：切片预览生成中
  ///
  /// In zh, this message translates to:
  /// **'正在生成切片预览'**
  String get framePreviewBuildingSlices;

  /// Sprite Sheet 预览：预览失败标题
  ///
  /// In zh, this message translates to:
  /// **'预览失败'**
  String get framePreviewPreviewFailedTitle;

  /// Sprite Sheet 预览：预览失败内容
  ///
  /// In zh, this message translates to:
  /// **'切片预览失败：{message}'**
  String framePreviewPreviewFailedMessage(Object message);

  /// Sprite Sheet 预览：无预览数据兜底
  ///
  /// In zh, this message translates to:
  /// **'没有可用的预览数据'**
  String get framePreviewNoPreviewData;

  /// Sprite Sheet 预览：播放模式标签
  ///
  /// In zh, this message translates to:
  /// **'切片播放'**
  String get framePreviewPlaybackModeLabel;

  /// Sprite Sheet 预览：目标选择模式标签
  ///
  /// In zh, this message translates to:
  /// **'目标选择'**
  String get framePreviewTargetSelectionModeLabel;

  /// Sprite Sheet 预览：网格检查模式标签
  ///
  /// In zh, this message translates to:
  /// **'网格检查'**
  String get framePreviewGridModeLabel;

  /// Sprite Sheet 预览：行标题
  ///
  /// In zh, this message translates to:
  /// **'第 {row} 行'**
  String framePreviewRowTitle(int row);

  /// Sprite Sheet 预览：行摘要
  ///
  /// In zh, this message translates to:
  /// **'第 {row} 行 · {columns} 列'**
  String framePreviewRowSubtitle(int row, int columns);

  /// Sprite Sheet 预览：目标帧字段
  ///
  /// In zh, this message translates to:
  /// **'目标帧'**
  String get framePreviewTargetFrameLabel;

  /// Sprite Sheet 预览：帧号字段
  ///
  /// In zh, this message translates to:
  /// **'帧号'**
  String get framePreviewFrameNumberLabel;

  /// Sprite Sheet 预览：帧选项
  ///
  /// In zh, this message translates to:
  /// **'第 {frame} 帧'**
  String framePreviewFrameOption(int frame);

  /// Sprite Sheet 预览：行号字段
  ///
  /// In zh, this message translates to:
  /// **'行号'**
  String get framePreviewRowNumberLabel;

  /// Sprite Sheet 预览：播放速度字段
  ///
  /// In zh, this message translates to:
  /// **'播放速度'**
  String get framePreviewPlaybackSpeedLabel;

  /// Sprite Sheet 预览：导出 PNG 按钮
  ///
  /// In zh, this message translates to:
  /// **'导出 PNG'**
  String get framePreviewExportPng;

  /// Sprite Sheet 预览：转 GIF 按钮
  ///
  /// In zh, this message translates to:
  /// **'转 GIF'**
  String get framePreviewConvertGif;

  /// Sprite Sheet 预览：像素化编辑按钮
  ///
  /// In zh, this message translates to:
  /// **'像素化编辑'**
  String get framePreviewPixelEdit;

  /// Sprite Sheet 预览：上一帧 tooltip
  ///
  /// In zh, this message translates to:
  /// **'上一帧'**
  String get framePreviewPreviousFrameTooltip;

  /// Sprite Sheet 预览：下一帧 tooltip
  ///
  /// In zh, this message translates to:
  /// **'下一帧'**
  String get framePreviewNextFrameTooltip;

  /// Sprite Sheet 预览：单帧行播放和切换按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'当前行只有 1 帧，无法播放或切换帧'**
  String get framePreviewPlaybackSingleFrameUnavailable;

  /// Sprite Sheet 预览：当前目标状态前缀
  ///
  /// In zh, this message translates to:
  /// **'当前目标'**
  String get framePreviewCurrentTargetPrefix;

  /// Sprite Sheet 预览：当前播放状态前缀
  ///
  /// In zh, this message translates to:
  /// **'当前播放'**
  String get framePreviewCurrentPlaybackPrefix;

  /// Sprite Sheet 预览：当前播放或目标状态
  ///
  /// In zh, this message translates to:
  /// **'{prefix}：第 {frame} 帧 · 第 {row} 行 · 第 {column} / {columns} 列'**
  String framePreviewCurrentStatus(
    Object prefix,
    int frame,
    int row,
    int column,
    int columns,
  );

  /// Sprite Sheet 预览：目标选择提示
  ///
  /// In zh, this message translates to:
  /// **'点击右侧 Sprite Sheet 或网格切片，可以直接选择要替换的目标帧。'**
  String get framePreviewTargetSelectionHint;

  /// Sprite Sheet 预览：播放查看提示
  ///
  /// In zh, this message translates to:
  /// **'点击右侧 Sprite Sheet 或网格切片，可以直接查看对应帧。'**
  String get framePreviewPlaybackHint;

  /// Sprite Sheet 预览：播放帧卡片标题
  ///
  /// In zh, this message translates to:
  /// **'播放帧'**
  String get framePreviewPlaybackFrameTitle;

  /// Sprite Sheet 预览：Sprite Sheet 卡片标题
  ///
  /// In zh, this message translates to:
  /// **'Sprite Sheet'**
  String get framePreviewSpriteSheetTitle;

  /// Sprite Sheet 预览：Sprite Sheet 卡片摘要
  ///
  /// In zh, this message translates to:
  /// **'{rows} 行 x {columns} 列，来源 {count} 张结果图'**
  String framePreviewSpriteSheetSubtitle(int rows, int columns, int count);

  /// 背景转透明弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'背景转透明'**
  String get backgroundTransparencyTitle;

  /// 背景转透明弹窗默认说明
  ///
  /// In zh, this message translates to:
  /// **'从图片边缘识别近似纯色背景，生成一张新的透明 PNG。'**
  String get backgroundTransparencyDescription;

  /// 背景转透明弹窗带来源说明
  ///
  /// In zh, this message translates to:
  /// **'处理「{sourceTitle}」，生成一张新的透明 PNG。'**
  String backgroundTransparencyDescriptionForSource(Object sourceTitle);

  /// 背景转透明弹窗细节说明
  ///
  /// In zh, this message translates to:
  /// **'只会移除和边缘连通的近似背景色，内部同色细节会保留。'**
  String get backgroundTransparencyDetail;

  /// 背景转透明弹窗容差标签
  ///
  /// In zh, this message translates to:
  /// **'容差 {tolerance}'**
  String backgroundTransparencyTolerance(int tolerance);

  /// 背景转透明弹窗生成按钮
  ///
  /// In zh, this message translates to:
  /// **'生成透明图'**
  String get backgroundTransparencyGenerate;

  /// 单帧取景弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'调整单帧取景'**
  String get patchImageFramingTitle;

  /// 单帧取景弹窗完整显示按钮
  ///
  /// In zh, this message translates to:
  /// **'完整显示'**
  String get patchImageFramingContain;

  /// 单帧取景弹窗填满格子按钮
  ///
  /// In zh, this message translates to:
  /// **'填满格子'**
  String get patchImageFramingCover;

  /// 单帧取景弹窗居中按钮
  ///
  /// In zh, this message translates to:
  /// **'居中'**
  String get patchImageFramingCenter;

  /// 单帧取景缩放滑杆语义值
  ///
  /// In zh, this message translates to:
  /// **'缩放 {percent}%'**
  String patchImageFramingScaleSemanticLabel(int percent);

  /// 单帧取景预览区域语义标签
  ///
  /// In zh, this message translates to:
  /// **'单帧取景预览 · 目标 {width} x {height} · 缩放 {percent}% · 偏移 X {offsetX}，Y {offsetY}'**
  String patchImageFramingViewportSemanticLabel(
    int width,
    int height,
    int percent,
    int offsetX,
    int offsetY,
  );

  /// 单帧取景弹窗生成按钮
  ///
  /// In zh, this message translates to:
  /// **'生成取景单帧'**
  String get patchImageFramingGenerate;

  /// Sprite Sheet 编辑器配置面板标题
  ///
  /// In zh, this message translates to:
  /// **'编辑配置'**
  String get spriteSheetEditorConfigTitle;

  /// Sprite Sheet 编辑器：整张 Sprite Sheet 图片选择标题
  ///
  /// In zh, this message translates to:
  /// **'Sprite Sheet 图片'**
  String get spriteSheetEditorSheetImageTitle;

  /// Sprite Sheet 编辑器：清除 Sprite Sheet 图片 tooltip
  ///
  /// In zh, this message translates to:
  /// **'清除图片'**
  String get spriteSheetEditorClearSheetImageTooltip;

  /// Sprite Sheet 编辑器：行数字段
  ///
  /// In zh, this message translates to:
  /// **'行数'**
  String get spriteSheetEditorRowsLabel;

  /// Sprite Sheet 编辑器：行数下拉选项
  ///
  /// In zh, this message translates to:
  /// **'{count} 行'**
  String spriteSheetEditorRowsValue(int count);

  /// Sprite Sheet 编辑器：列数字段
  ///
  /// In zh, this message translates to:
  /// **'列数'**
  String get spriteSheetEditorColumnsLabel;

  /// Sprite Sheet 编辑器：列数下拉选项
  ///
  /// In zh, this message translates to:
  /// **'{count} 列'**
  String spriteSheetEditorColumnsValue(int count);

  /// Sprite Sheet 编辑器：单帧图片选择标题
  ///
  /// In zh, this message translates to:
  /// **'单帧图片'**
  String get spriteSheetEditorPatchImageTitle;

  /// Sprite Sheet 编辑器：清除单帧图片 tooltip
  ///
  /// In zh, this message translates to:
  /// **'清除单帧图片'**
  String get spriteSheetEditorClearPatchImageTooltip;

  /// Sprite Sheet 编辑器：替换目标字段
  ///
  /// In zh, this message translates to:
  /// **'替换目标'**
  String get spriteSheetEditorReplacementTargetLabel;

  /// Sprite Sheet 编辑器：单帧适配方式字段
  ///
  /// In zh, this message translates to:
  /// **'适配方式'**
  String get spriteSheetEditorFrameFitLabel;

  /// Sprite Sheet 编辑器：完整放入适配方式
  ///
  /// In zh, this message translates to:
  /// **'完整放入'**
  String get spriteSheetEditorFrameFitContain;

  /// Sprite Sheet 编辑器：裁剪填满适配方式
  ///
  /// In zh, this message translates to:
  /// **'裁剪填满'**
  String get spriteSheetEditorFrameFitCover;

  /// Sprite Sheet 编辑器：拉伸填满适配方式
  ///
  /// In zh, this message translates to:
  /// **'拉伸填满'**
  String get spriteSheetEditorFrameFitStretch;

  /// Sprite Sheet 编辑器：帧下拉选项标签
  ///
  /// In zh, this message translates to:
  /// **'{index} 帧 · {row} 行 {column} 列'**
  String editorFrameOptionLabel(int index, int row, int column);

  /// GIF/动画播放模式：正向
  ///
  /// In zh, this message translates to:
  /// **'正向'**
  String get gifPlaybackModeNormal;

  /// GIF/动画播放模式：反向
  ///
  /// In zh, this message translates to:
  /// **'反向'**
  String get gifPlaybackModeReverse;

  /// GIF/动画播放模式：乒乓
  ///
  /// In zh, this message translates to:
  /// **'乒乓'**
  String get gifPlaybackModePingPong;

  /// Sprite Sheet 编辑器：复制上一帧按钮
  ///
  /// In zh, this message translates to:
  /// **'复制上一帧'**
  String get spriteSheetEditorCopyPreviousFrame;

  /// Sprite Sheet 编辑器：清空当前格按钮
  ///
  /// In zh, this message translates to:
  /// **'清空当前格'**
  String get spriteSheetEditorClearCurrentCell;

  /// Sprite Sheet 编辑器：插入或替换当前格按钮
  ///
  /// In zh, this message translates to:
  /// **'插入 / 替换到当前格'**
  String get spriteSheetEditorInsertReplaceCurrentCell;

  /// Sprite Sheet 编辑器：替换中忙碌按钮文案
  ///
  /// In zh, this message translates to:
  /// **'替换中'**
  String get spriteSheetEditorReplacing;

  /// Sprite Sheet 编辑器：替换目标帧位置说明
  ///
  /// In zh, this message translates to:
  /// **'第 {row} 行 · 第 {column} 列 · 共 {totalCount} 帧'**
  String spriteSheetEditorTargetFrameHelper(
    int row,
    int column,
    int totalCount,
  );

  /// Sprite Sheet 编辑器：工具区单帧取景摘要
  ///
  /// In zh, this message translates to:
  /// **'单帧取景'**
  String get spriteSheetEditorToolFraming;

  /// Sprite Sheet 编辑器：工具区透明背景摘要
  ///
  /// In zh, this message translates to:
  /// **'透明背景'**
  String get spriteSheetEditorToolTransparent;

  /// Sprite Sheet 编辑器：工具区像素化摘要
  ///
  /// In zh, this message translates to:
  /// **'像素化'**
  String get spriteSheetEditorToolPixelate;

  /// Sprite Sheet 编辑器：编辑工具折叠区标题
  ///
  /// In zh, this message translates to:
  /// **'编辑工具'**
  String get spriteSheetEditorToolsTitle;

  /// Sprite Sheet 编辑器：编辑工具不可用提示
  ///
  /// In zh, this message translates to:
  /// **'选择 Sprite Sheet 或单帧图片后可用'**
  String get spriteSheetEditorToolsDisabledHint;

  /// Sprite Sheet 编辑器：处理中的短状态
  ///
  /// In zh, this message translates to:
  /// **'处理中'**
  String get spriteSheetEditorProcessing;

  /// Sprite Sheet 编辑器：生成透明背景单帧按钮
  ///
  /// In zh, this message translates to:
  /// **'生成透明背景单帧'**
  String get spriteSheetEditorGenerateTransparentPatch;

  /// Sprite Sheet 编辑器：像素块字段
  ///
  /// In zh, this message translates to:
  /// **'像素块'**
  String get spriteSheetEditorPixelBlockLabel;

  /// Sprite Sheet 编辑器：像素块字段说明
  ///
  /// In zh, this message translates to:
  /// **'数值越大，颗粒越粗'**
  String get spriteSheetEditorPixelBlockHelper;

  /// Sprite Sheet 编辑器：像素化当前帧按钮
  ///
  /// In zh, this message translates to:
  /// **'像素化当前帧'**
  String get spriteSheetEditorPixelateCurrentFrame;

  /// Sprite Sheet 编辑器：像素化整张 Sprite Sheet 按钮
  ///
  /// In zh, this message translates to:
  /// **'像素化整张'**
  String get spriteSheetEditorPixelateWholeSheet;

  /// Sprite Sheet 生成面板标题
  ///
  /// In zh, this message translates to:
  /// **'序列帧生成配置'**
  String get spriteSheetGenerationConfigTitle;

  /// Sprite Sheet 生成：网格数量单位
  ///
  /// In zh, this message translates to:
  /// **'格'**
  String get spriteSheetCell;

  /// Sprite Sheet 生成：提示词字段标签
  ///
  /// In zh, this message translates to:
  /// **'提示词内容'**
  String get spriteSheetPromptLabel;

  /// Sprite Sheet 生成：提示词字段提示
  ///
  /// In zh, this message translates to:
  /// **'把主体、场景、风格、动作变化写在这里即可'**
  String get spriteSheetPromptHint;

  /// Sprite Sheet 生成：负向提示词字段提示
  ///
  /// In zh, this message translates to:
  /// **'会应用到每一帧'**
  String get spriteSheetNegativePromptHint;

  /// Sprite Sheet 生成：行数字段
  ///
  /// In zh, this message translates to:
  /// **'行数'**
  String get spriteSheetRowsLabel;

  /// Sprite Sheet：网格短标签，行
  ///
  /// In zh, this message translates to:
  /// **'行'**
  String get spriteSheetRowShortLabel;

  /// Sprite Sheet：网格短标签，列
  ///
  /// In zh, this message translates to:
  /// **'列'**
  String get spriteSheetColumnShortLabel;

  /// Sprite Sheet：网格短标签，帧
  ///
  /// In zh, this message translates to:
  /// **'帧'**
  String get spriteSheetFrameShortLabel;

  /// Sprite Sheet：编辑器帧网格标签
  ///
  /// In zh, this message translates to:
  /// **'第 {frameIndex} 帧 · 第 {row} 行 · 第 {column} 列'**
  String spriteSheetFrameGridLabel(int frameIndex, int row, int column);

  /// Sprite Sheet 生成：行数选项值
  ///
  /// In zh, this message translates to:
  /// **'{count} 行'**
  String spriteSheetRowsValue(int count);

  /// Sprite Sheet 生成：列数字段
  ///
  /// In zh, this message translates to:
  /// **'列数'**
  String get spriteSheetColumnsLabel;

  /// Sprite Sheet 生成：列数选项值
  ///
  /// In zh, this message translates to:
  /// **'{count} 列'**
  String spriteSheetColumnsValue(int count);

  /// Sprite Sheet 生成按钮
  ///
  /// In zh, this message translates to:
  /// **'生成 Sprite Sheet'**
  String get spriteSheetGenerateButton;

  /// Sprite Sheet 生成忙碌状态
  ///
  /// In zh, this message translates to:
  /// **'生成 Sprite Sheet 中'**
  String get spriteSheetGeneratingButton;

  /// 动画工程工作区说明
  ///
  /// In zh, this message translates to:
  /// **'用工程、轨道和序列帧管理动画，Sprite Sheet 与 GIF 只作为导入和导出格式。'**
  String get animationProjectWorkspaceDescription;

  /// 动画工程：无可导入来源状态
  ///
  /// In zh, this message translates to:
  /// **'暂无可导入来源'**
  String get animationProjectNoImportSource;

  /// 动画工程：创建态面板标题
  ///
  /// In zh, this message translates to:
  /// **'创建动画工程'**
  String get animationProjectCreateTitle;

  /// 动画工程：导入为工程按钮
  ///
  /// In zh, this message translates to:
  /// **'导入为动画工程'**
  String get animationProjectImportAsProject;

  /// 动画工程：导入工程忙碌状态
  ///
  /// In zh, this message translates to:
  /// **'正在导入工程'**
  String get animationProjectImportingProject;

  /// 动画工程：导入本地图片序列按钮
  ///
  /// In zh, this message translates to:
  /// **'导入本地图片序列'**
  String get animationProjectImportLocalSequence;

  /// 动画工程：从作品库导入序列按钮
  ///
  /// In zh, this message translates to:
  /// **'从作品库导入序列'**
  String get animationProjectImportLibrarySequence;

  /// 动画工程：导出忙碌状态
  ///
  /// In zh, this message translates to:
  /// **'正在导出'**
  String get animationProjectExporting;

  /// 动画工程：导出来源 Sprite Sheet 按钮
  ///
  /// In zh, this message translates to:
  /// **'导出来源 Sprite Sheet'**
  String get animationProjectExportSourceSpriteSheet;

  /// 动画工程：来源摘要标题
  ///
  /// In zh, this message translates to:
  /// **'工程来源'**
  String get animationProjectSourceTitle;

  /// 动画工程：来源生成中状态
  ///
  /// In zh, this message translates to:
  /// **'正在生成来源'**
  String get animationProjectGeneratingSource;

  /// 动画工程：工程控制面板标题
  ///
  /// In zh, this message translates to:
  /// **'工程控制'**
  String get animationProjectControlsTitle;

  /// 动画工程：帧数量单位
  ///
  /// In zh, this message translates to:
  /// **'帧'**
  String get animationProjectFrameUnit;

  /// 动画工程：轨道数量单位
  ///
  /// In zh, this message translates to:
  /// **'轨道'**
  String get animationProjectTrackUnit;

  /// 动画工程：工程摘要
  ///
  /// In zh, this message translates to:
  /// **'{trackCount} 条轨道 · {frameCount} 帧 · {width} x {height}'**
  String animationProjectSummary(
    int trackCount,
    int frameCount,
    int width,
    int height,
  );

  /// 动画工程：新建轨道按钮
  ///
  /// In zh, this message translates to:
  /// **'新建轨道'**
  String get animationProjectAddTrack;

  /// 动画工程：导出合成 Sprite Sheet 按钮
  ///
  /// In zh, this message translates to:
  /// **'导出合成 Sprite Sheet'**
  String get animationProjectExportCompositedSpriteSheet;

  /// 动画工程：导出工程 GIF 按钮
  ///
  /// In zh, this message translates to:
  /// **'导出工程 GIF'**
  String get animationProjectExportProjectGif;

  /// 动画工程：导出工程 PNG 序列按钮
  ///
  /// In zh, this message translates to:
  /// **'导出工程 PNG 序列'**
  String get animationProjectExportProjectPngSequence;

  /// 动画工程：导出当前轨道 GIF 按钮
  ///
  /// In zh, this message translates to:
  /// **'导出当前轨道 GIF'**
  String get animationProjectExportTrackGif;

  /// 动画工程：导出 PNG 序列按钮
  ///
  /// In zh, this message translates to:
  /// **'导出 PNG 序列'**
  String get animationProjectExportPngSequence;

  /// 动画工程：关闭工程按钮
  ///
  /// In zh, this message translates to:
  /// **'关闭工程'**
  String get animationProjectCloseProject;

  /// 动画工程：工程忙碌时操作按钮不可用原因
  ///
  /// In zh, this message translates to:
  /// **'当前工程正在处理任务，完成后可继续操作'**
  String get animationProjectActionBusyUnavailable;

  /// 动画工程：轨道时间轴面板标题
  ///
  /// In zh, this message translates to:
  /// **'轨道时间轴'**
  String get animationProjectTrackTimelineTitle;

  /// 动画工程：工程设置区块标题
  ///
  /// In zh, this message translates to:
  /// **'工程设置'**
  String get animationProjectSettingsTitle;

  /// 动画工程：默认帧时长字段
  ///
  /// In zh, this message translates to:
  /// **'工程默认帧时长'**
  String get animationProjectDefaultFrameDelay;

  /// 动画工程：工程播放方式字段
  ///
  /// In zh, this message translates to:
  /// **'工程播放方式'**
  String get animationProjectPlaybackMode;

  /// 动画工程：GIF 循环次数字段
  ///
  /// In zh, this message translates to:
  /// **'GIF 循环次数'**
  String get animationProjectGifLoopCount;

  /// 动画工程：循环次数后缀
  ///
  /// In zh, this message translates to:
  /// **'次'**
  String get animationProjectLoopCountSuffix;

  /// 动画工程：导出包含隐藏轨道开关
  ///
  /// In zh, this message translates to:
  /// **'导出包含隐藏轨道'**
  String get animationProjectIncludeHiddenTracks;

  /// 动画工程：预览面板标题
  ///
  /// In zh, this message translates to:
  /// **'动画工程预览'**
  String get animationProjectPreviewTitle;

  /// 动画工程：工程合成渲染中
  ///
  /// In zh, this message translates to:
  /// **'正在渲染工程合成'**
  String get animationProjectRenderingComposite;

  /// 动画工程：渲染失败标题
  ///
  /// In zh, this message translates to:
  /// **'渲染失败'**
  String get animationProjectRenderFailed;

  /// 动画工程：无渲染数据错误
  ///
  /// In zh, this message translates to:
  /// **'没有可用的渲染数据'**
  String get animationProjectNoRenderData;

  /// 动画工程：重新渲染按钮
  ///
  /// In zh, this message translates to:
  /// **'重新渲染'**
  String get animationProjectRetryRender;

  /// 动画工程：无可见帧空状态
  ///
  /// In zh, this message translates to:
  /// **'工程没有可见帧'**
  String get animationProjectNoVisibleFrames;

  /// 动画工程：播放预览按钮
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get animationProjectPlayPreview;

  /// 动画工程：暂停预览按钮
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get animationProjectPausePreview;

  /// 动画工程：上一帧 tooltip
  ///
  /// In zh, this message translates to:
  /// **'上一帧'**
  String get animationProjectPreviousFrame;

  /// 动画工程：下一帧 tooltip
  ///
  /// In zh, this message translates to:
  /// **'下一帧'**
  String get animationProjectNextFrame;

  /// 动画工程：合成帧状态
  ///
  /// In zh, this message translates to:
  /// **'合成帧 {frameIndex} / {frameCount} · {delayMs} ms'**
  String animationProjectCompositeFrameStatus(
    int frameIndex,
    int frameCount,
    int delayMs,
  );

  /// 动画工程：来源为单张 Sprite Sheet 时的网格摘要
  ///
  /// In zh, this message translates to:
  /// **'{rows} x {columns} · {frameCount} 格'**
  String animationProjectGeneratedSourceGrid(
    int rows,
    int columns,
    int frameCount,
  );

  /// 动画工程：来源为图片序列时的摘要
  ///
  /// In zh, this message translates to:
  /// **'{count} 张序列帧'**
  String animationProjectGeneratedSequenceSource(int count);

  /// 动画工程：工程控制宽度拖拽把手 tooltip
  ///
  /// In zh, this message translates to:
  /// **'拖动调整工程控制宽度，双击复位'**
  String get animationProjectResizeControlsTooltip;

  /// 动画工程：时间轴高度拖拽把手 tooltip
  ///
  /// In zh, this message translates to:
  /// **'拖动调整时间轴高度，双击复位'**
  String get animationProjectResizeTimelineTooltip;

  /// 动画工程：资源诊断区块标题
  ///
  /// In zh, this message translates to:
  /// **'资源诊断'**
  String get animationProjectAssetDiagnosticsTitle;

  /// 动画工程：重新检查资源按钮
  ///
  /// In zh, this message translates to:
  /// **'重新检查'**
  String get animationProjectRecheckAssets;

  /// 动画工程：资源诊断检查中标题
  ///
  /// In zh, this message translates to:
  /// **'正在检查帧资源'**
  String get animationProjectCheckingFrameAssets;

  /// 动画工程：资源诊断检查中说明
  ///
  /// In zh, this message translates to:
  /// **'正在验证工程引用的帧文件。'**
  String get animationProjectCheckingFrameAssetsMessage;

  /// 动画工程：资源诊断失败标题
  ///
  /// In zh, this message translates to:
  /// **'资源检查失败'**
  String get animationProjectAssetCheckFailed;

  /// 动画工程：资源诊断无结果兜底
  ///
  /// In zh, this message translates to:
  /// **'没有可用的检查结果'**
  String get animationProjectNoAssetCheckResult;

  /// 动画工程：资源完整标题
  ///
  /// In zh, this message translates to:
  /// **'资源完整'**
  String get animationProjectAssetsHealthy;

  /// 动画工程：资源完整说明
  ///
  /// In zh, this message translates to:
  /// **'{totalCount} 个帧资源可用，{referencedCount} 个被时间轴引用。'**
  String animationProjectAssetsHealthyMessage(
    int totalCount,
    int referencedCount,
  );

  /// 动画工程：资源缺失标题
  ///
  /// In zh, this message translates to:
  /// **'缺失资源'**
  String get animationProjectMissingAssetsTitle;

  /// 动画工程：工程可修复标题
  ///
  /// In zh, this message translates to:
  /// **'工程可修复'**
  String get animationProjectRepairableTitle;

  /// 动画工程：时间轴引用资源缺失说明
  ///
  /// In zh, this message translates to:
  /// **'{count} 个被时间轴引用的资源缺失，预览和导出会失败。'**
  String animationProjectMissingTimelineAssetsMessage(int count);

  /// 动画工程：未引用资源缺失说明
  ///
  /// In zh, this message translates to:
  /// **'发现未引用的缺失资源，当前预览不受影响。'**
  String get animationProjectMissingUnusedAssetsMessage;

  /// 动画工程：工程可修复说明
  ///
  /// In zh, this message translates to:
  /// **'发现可自动修复的工程一致性问题。'**
  String get animationProjectRepairableMessage;

  /// 动画工程：自动修复资源预览超出数量
  ///
  /// In zh, this message translates to:
  /// **' 等 {count} 个'**
  String animationProjectAssetPreviewExtraCount(int count);

  /// 动画工程：未引用资源数量明细
  ///
  /// In zh, this message translates to:
  /// **'未引用资源 {count} 个'**
  String animationProjectUnusedAssetsDetail(int count);

  /// 动画工程：空帧引用数量明细
  ///
  /// In zh, this message translates to:
  /// **'空帧引用 {count} 个'**
  String animationProjectInvalidFrameRefsDetail(int count);

  /// 动画工程：可自动修复数量
  ///
  /// In zh, this message translates to:
  /// **'可自动修复 {count} 项'**
  String animationProjectAutoRepairableCount(int count);

  /// 动画工程：自动修复按钮
  ///
  /// In zh, this message translates to:
  /// **'自动修复可处理项'**
  String get animationProjectAutoRepairAction;

  /// 动画工程：资源未记录路径兜底
  ///
  /// In zh, this message translates to:
  /// **'未记录路径'**
  String get animationProjectMissingRecordedPath;

  /// 动画工程：资源问题被时间轴引用次数
  ///
  /// In zh, this message translates to:
  /// **'{message} · 时间轴引用 {count} 次'**
  String animationProjectAssetIssueTimelineRefs(Object message, int count);

  /// 动画工程：重新绑定资源按钮
  ///
  /// In zh, this message translates to:
  /// **'重新绑定'**
  String get animationProjectRebindAsset;

  /// 动画工程：轨道列表标题
  ///
  /// In zh, this message translates to:
  /// **'轨道'**
  String get animationProjectTracksSectionTitle;

  /// 动画工程：上移轨道 tooltip
  ///
  /// In zh, this message translates to:
  /// **'上移轨道'**
  String get animationProjectMoveTrackUp;

  /// 动画工程：下移轨道 tooltip
  ///
  /// In zh, this message translates to:
  /// **'下移轨道'**
  String get animationProjectMoveTrackDown;

  /// 动画工程：复制轨道 tooltip
  ///
  /// In zh, this message translates to:
  /// **'复制轨道'**
  String get animationProjectDuplicateTrack;

  /// 动画工程：删除轨道 tooltip
  ///
  /// In zh, this message translates to:
  /// **'删除轨道'**
  String get animationProjectDeleteTrack;

  /// 动画工程：隐藏轨道 tooltip
  ///
  /// In zh, this message translates to:
  /// **'隐藏轨道'**
  String get animationProjectHideTrack;

  /// 动画工程：显示轨道 tooltip
  ///
  /// In zh, this message translates to:
  /// **'显示轨道'**
  String get animationProjectShowTrack;

  /// 动画工程：解锁轨道 tooltip
  ///
  /// In zh, this message translates to:
  /// **'解锁轨道'**
  String get animationProjectUnlockTrack;

  /// 动画工程：锁定轨道 tooltip
  ///
  /// In zh, this message translates to:
  /// **'锁定轨道'**
  String get animationProjectLockTrack;

  /// 动画工程：轨道名称字段
  ///
  /// In zh, this message translates to:
  /// **'轨道名称'**
  String get animationProjectTrackNameLabel;

  /// 动画工程：轨道帧时长字段
  ///
  /// In zh, this message translates to:
  /// **'帧时长'**
  String get animationProjectFrameDelayLabel;

  /// 动画工程：帧数量
  ///
  /// In zh, this message translates to:
  /// **'{count} 帧'**
  String animationProjectFrameCount(int count);

  /// 动画工程：未选择轨道空状态
  ///
  /// In zh, this message translates to:
  /// **'先选择一条轨道'**
  String get animationProjectSelectTrackFirst;

  /// 动画工程：插入空白帧按钮
  ///
  /// In zh, this message translates to:
  /// **'插入空白帧'**
  String get animationProjectInsertBlankFrame;

  /// 动画工程：插入图片帧按钮
  ///
  /// In zh, this message translates to:
  /// **'插入图片帧'**
  String get animationProjectInsertImageFrame;

  /// 动画工程：锁定轨道无帧空状态
  ///
  /// In zh, this message translates to:
  /// **'轨道已锁定，当前没有序列帧'**
  String get animationProjectTrackLockedNoFrames;

  /// 动画工程：轨道无帧空状态
  ///
  /// In zh, this message translates to:
  /// **'当前轨道没有序列帧'**
  String get animationProjectTrackNoFrames;

  /// 动画工程：序列帧时间轴标题
  ///
  /// In zh, this message translates to:
  /// **'序列帧时间轴'**
  String get animationProjectSequenceTimelineTitle;

  /// 动画工程：当前轨道帧数量状态
  ///
  /// In zh, this message translates to:
  /// **'{trackName} · {frameCount} 帧'**
  String animationProjectTrackFrameStatus(Object trackName, int frameCount);

  /// 动画工程：单帧时长字段
  ///
  /// In zh, this message translates to:
  /// **'单帧时长'**
  String get animationProjectSingleFrameDelay;

  /// 动画工程：当前帧标签
  ///
  /// In zh, this message translates to:
  /// **'当前帧 {index}'**
  String animationProjectCurrentFrame(int index);

  /// 动画工程：替换帧按钮
  ///
  /// In zh, this message translates to:
  /// **'替换帧'**
  String get animationProjectReplaceFrame;

  /// 动画工程：清空帧按钮
  ///
  /// In zh, this message translates to:
  /// **'清空帧'**
  String get animationProjectClearFrame;

  /// 动画工程：像素化当前帧 tooltip
  ///
  /// In zh, this message translates to:
  /// **'像素化当前帧'**
  String get animationProjectPixelateCurrentFrame;

  /// 动画工程：像素化帧按钮
  ///
  /// In zh, this message translates to:
  /// **'像素化帧'**
  String get animationProjectPixelateFrame;

  /// 动画工程：复制帧按钮
  ///
  /// In zh, this message translates to:
  /// **'复制帧'**
  String get animationProjectDuplicateFrame;

  /// 动画工程：删除帧按钮
  ///
  /// In zh, this message translates to:
  /// **'删除帧'**
  String get animationProjectDeleteFrame;

  /// 动画工程：单帧变换标题
  ///
  /// In zh, this message translates to:
  /// **'单帧变换'**
  String get animationProjectSingleFrameTransform;

  /// 动画工程：水平翻转 tooltip
  ///
  /// In zh, this message translates to:
  /// **'水平翻转'**
  String get animationProjectFlipHorizontal;

  /// 动画工程：垂直翻转 tooltip
  ///
  /// In zh, this message translates to:
  /// **'垂直翻转'**
  String get animationProjectFlipVertical;

  /// 动画工程：重置单帧变换 tooltip
  ///
  /// In zh, this message translates to:
  /// **'重置单帧变换'**
  String get animationProjectResetFrameTransform;

  /// 动画工程：不透明度滑块
  ///
  /// In zh, this message translates to:
  /// **'不透明度'**
  String get animationProjectOpacity;

  /// 接口配置：阻止删除最后一个配置的提示
  ///
  /// In zh, this message translates to:
  /// **'至少需要保留一个接口配置'**
  String get apiConfigDeleteLastMessage;

  /// 批量生成：缺少 API Key 提示
  ///
  /// In zh, this message translates to:
  /// **'请先在接口配置页填写 API Key'**
  String get batchGenerationMissingApiKey;

  /// 批量生成：缺少模型提示
  ///
  /// In zh, this message translates to:
  /// **'请先在接口配置页获取模型列表并选择模型'**
  String get batchGenerationMissingModel;

  /// 批量生成：批量提示词为空提示
  ///
  /// In zh, this message translates to:
  /// **'请先填写至少一行批量提示词'**
  String get batchGenerationMissingPrompts;

  /// 批量生成：批量任务加入队列提示
  ///
  /// In zh, this message translates to:
  /// **'已拆分并加入 {count} 个批量任务'**
  String batchGenerationJobsAdded(int count);

  /// 批量生成：任务自动重试错误提示
  ///
  /// In zh, this message translates to:
  /// **'上次失败，已移到队尾自动重试 ({retryAttempt}/{maxRetryAttempts})：{errorMessage}'**
  String batchGenerationAutoRetryMessage(
    int retryAttempt,
    int maxRetryAttempts,
    Object errorMessage,
  );

  /// 批量生成：队列运行中禁止重试提示
  ///
  /// In zh, this message translates to:
  /// **'队列运行中，请等待当前队列停止后再重试失败任务'**
  String get batchGenerationRetryBlockedRunning;

  /// 批量生成：没有可重试失败任务提示
  ///
  /// In zh, this message translates to:
  /// **'没有失败任务可重试'**
  String get batchGenerationNoFailedJobsToRetry;

  /// 批量生成：多个失败任务重新入队提示
  ///
  /// In zh, this message translates to:
  /// **'已将 {count} 个失败任务重新加入等待队列'**
  String batchGenerationFailedJobsRequeued(int count);

  /// 批量生成：单个失败任务重新入队提示
  ///
  /// In zh, this message translates to:
  /// **'已将失败任务重新加入等待队列'**
  String get batchGenerationFailedJobRequeued;

  /// 批量生成：队列暂停后剩余任务提示
  ///
  /// In zh, this message translates to:
  /// **'队列已暂停，可继续执行剩余 {count} 个任务'**
  String batchGenerationQueuePaused(int count);

  /// 批量生成：队列停止提示
  ///
  /// In zh, this message translates to:
  /// **'批量队列已停止'**
  String get batchGenerationQueueStopped;

  /// 批量生成：请求暂停提示
  ///
  /// In zh, this message translates to:
  /// **'已暂停后续任务；正在请求的一批会等待接口返回'**
  String get batchGenerationPauseRequested;

  /// 批量生成：恢复队列提示
  ///
  /// In zh, this message translates to:
  /// **'已恢复后续任务'**
  String get batchGenerationResumed;

  /// 批量生成：没有可取消等待任务提示
  ///
  /// In zh, this message translates to:
  /// **'没有等待中的任务可取消'**
  String get batchGenerationNoQueuedJobsToCancel;

  /// 批量生成：等待任务被用户取消的错误信息
  ///
  /// In zh, this message translates to:
  /// **'用户取消等待任务'**
  String get batchGenerationUserCanceledQueuedJob;

  /// 批量生成：取消等待任务时仍有请求中的补充提示
  ///
  /// In zh, this message translates to:
  /// **'；当前正在请求的一批会等待接口返回'**
  String get batchGenerationCancelQueuedRunningHint;

  /// 批量生成：取消等待任务提示
  ///
  /// In zh, this message translates to:
  /// **'已取消 {count} 个等待任务{runningHint}'**
  String batchGenerationQueuedJobsCanceled(int count, Object runningHint);

  /// 批量生成：批量结果默认标题
  ///
  /// In zh, this message translates to:
  /// **'批量结果 {index}'**
  String batchGenerationResultTitle(int index);

  /// 批量生成：作品来源名称
  ///
  /// In zh, this message translates to:
  /// **'批量生成'**
  String get batchGenerationSourceName;

  /// 批量生成：作品库结果标题前缀
  ///
  /// In zh, this message translates to:
  /// **'批量生图'**
  String get batchGenerationLibraryTitlePrefix;

  /// 批量生成：作品库来源字段
  ///
  /// In zh, this message translates to:
  /// **'批量生成'**
  String get batchGenerationLibrarySource;

  /// 背景转透明：没有可透明化边缘背景提示
  ///
  /// In zh, this message translates to:
  /// **'没有检测到可透明化的边缘背景，可尝试调高容差'**
  String get backgroundTransparencyNoEdgeDetected;

  /// 批量生成：透明背景图片生成成功提示
  ///
  /// In zh, this message translates to:
  /// **'已生成透明背景图片：{title} · 透明化 {count} 个像素'**
  String batchGenerationTransparentImageSaved(Object title, int count);

  /// 背景转透明：处理失败提示
  ///
  /// In zh, this message translates to:
  /// **'背景转透明失败：{error}'**
  String backgroundTransparencyFailed(Object error);

  /// 通用：复制图片失败提示
  ///
  /// In zh, this message translates to:
  /// **'复制图片失败：{error}'**
  String copyImageFailed(Object error);

  /// 通用预览：重试生成按钮
  ///
  /// In zh, this message translates to:
  /// **'重试生成'**
  String get retryGenerationAction;

  /// 结果预览面板标题
  ///
  /// In zh, this message translates to:
  /// **'结果预览'**
  String get previewPanelTitle;

  /// 结果预览：生成中提示
  ///
  /// In zh, this message translates to:
  /// **'正在生成图片'**
  String get previewGeneratingImage;

  /// 结果预览：生成失败标题
  ///
  /// In zh, this message translates to:
  /// **'生成失败'**
  String get previewGenerationFailed;

  /// 结果预览：空状态提示
  ///
  /// In zh, this message translates to:
  /// **'生成后的图片会显示在这里'**
  String get previewEmptyMessage;

  /// 结果预览：单张结果标题
  ///
  /// In zh, this message translates to:
  /// **'结果 {index}'**
  String previewResultTitle(int index);

  /// 通用：复制图片 tooltip
  ///
  /// In zh, this message translates to:
  /// **'复制图片'**
  String get copyImageTooltip;

  /// 通用：导出图片 tooltip
  ///
  /// In zh, this message translates to:
  /// **'导出图片'**
  String get exportImageTooltip;

  /// 通用：背景转透明 tooltip
  ///
  /// In zh, this message translates to:
  /// **'背景转透明'**
  String get makeBackgroundTransparentTooltip;

  /// 结果预览：等待中的图片占位
  ///
  /// In zh, this message translates to:
  /// **'等待 {index}'**
  String previewPendingImage(int index);

  /// 结果预览：图片加载失败提示
  ///
  /// In zh, this message translates to:
  /// **'图片加载失败：{error}'**
  String previewImageLoadFailed(Object error);

  /// 首次启动：接口配置弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'完成首次接口配置'**
  String get firstRunSetupTitle;

  /// 首次启动：接口配置弹窗说明
  ///
  /// In zh, this message translates to:
  /// **'开始生成前需要先配置供应商、Base URL、API Key 和模型。你可以现在打开接口配置页，也可以稍后从侧边栏的设置入口进入。'**
  String get firstRunSetupMessage;

  /// 首次启动：稍后配置按钮
  ///
  /// In zh, this message translates to:
  /// **'稍后配置'**
  String get firstRunSetupLater;

  /// 首次启动：打开接口配置按钮
  ///
  /// In zh, this message translates to:
  /// **'打开接口配置'**
  String get firstRunSetupOpenApiSettings;

  /// 恢复默认表单弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'恢复默认表单'**
  String get resetDefaultsTitle;

  /// 恢复默认表单弹窗说明
  ///
  /// In zh, this message translates to:
  /// **'会清空当前接口配置、提示词、预览结果和本地临时选择，作品库中的已保存文件不会被删除。'**
  String get resetDefaultsMessage;

  /// 恢复默认表单确认按钮
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get resetDefaultsAction;

  /// Sprite Sheet：替换帧确认弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'确认替换第 {frameNumber} 帧'**
  String spriteSheetReplaceFrameTitle(int frameNumber);

  /// Sprite Sheet：替换帧目标位置说明
  ///
  /// In zh, this message translates to:
  /// **'目标位置：第 {row} 行 · 第 {column} 列 · {width} x {height} · {fitLabel}'**
  String spriteSheetReplaceFrameTarget(
    int row,
    int column,
    int width,
    int height,
    Object fitLabel,
  );

  /// Sprite Sheet：替换预览原帧标题
  ///
  /// In zh, this message translates to:
  /// **'原帧'**
  String get spriteSheetOriginalFrame;

  /// Sprite Sheet：替换预览单帧图片标题
  ///
  /// In zh, this message translates to:
  /// **'单帧图片'**
  String get spriteSheetPatchFrame;

  /// Sprite Sheet：替换预览结果标题
  ///
  /// In zh, this message translates to:
  /// **'替换后'**
  String get spriteSheetReplacementResult;

  /// Sprite Sheet：确认替换按钮
  ///
  /// In zh, this message translates to:
  /// **'确认替换'**
  String get spriteSheetConfirmReplace;

  /// 通用：图片兜底名称
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get imageLabel;

  /// 作品库状态：没有可用图片提示
  ///
  /// In zh, this message translates to:
  /// **'作品库还没有可用图片'**
  String get imageLibraryStateNoAvailableImages;

  /// 作品库状态：Sprite Sheet 缺少行列元数据提示
  ///
  /// In zh, this message translates to:
  /// **'该 Sprite Sheet 缺少行列元数据，无法切片'**
  String get imageLibraryStateSpriteSheetMissingGrid;

  /// 作品库状态：Sprite Sheet 缺少 groupId 提示
  ///
  /// In zh, this message translates to:
  /// **'该 Sprite Sheet 缺少 groupId，无法保存切片'**
  String get imageLibraryStateSpriteSheetMissingGroup;

  /// 作品库条目：GIF 帧数摘要
  ///
  /// In zh, this message translates to:
  /// **'{count} 张图片合成'**
  String imageLibraryGifPrompt(int count);

  /// 作品库条目：从 Sprite Sheet 导出的 GIF 标题
  ///
  /// In zh, this message translates to:
  /// **'Sprite Sheet GIF'**
  String get imageLibrarySpriteSheetGifTitle;

  /// 作品库条目：动画工程导出 GIF 标题
  ///
  /// In zh, this message translates to:
  /// **'动画工程 GIF'**
  String get imageLibraryAnimationProjectGifTitle;

  /// 作品库条目：动画轨道导出 GIF 标题
  ///
  /// In zh, this message translates to:
  /// **'动画轨道 GIF'**
  String get imageLibraryAnimationTrackGifTitle;

  /// 作品库条目：动画工程摘要
  ///
  /// In zh, this message translates to:
  /// **'{trackCount} 条轨道 · {frameCount} 帧 · {width} x {height}'**
  String imageLibraryAnimationProjectPrompt(
    int trackCount,
    int frameCount,
    int width,
    int height,
  );

  /// 作品库条目：导出的 Sprite Sheet 标题
  ///
  /// In zh, this message translates to:
  /// **'导出 Sprite Sheet'**
  String get imageLibraryExportedSpriteSheetTitle;

  /// 作品库条目：导出的 Sprite Sheet 来源
  ///
  /// In zh, this message translates to:
  /// **'Sprite Sheet 导出'**
  String get imageLibraryExportedSpriteSheetSource;

  /// 作品库条目：动画工程导出的 Sprite Sheet 标题
  ///
  /// In zh, this message translates to:
  /// **'动画工程 Sprite Sheet'**
  String get imageLibraryAnimationProjectSpriteSheetTitle;

  /// 作品库条目：动画工程导出的 Sprite Sheet 来源
  ///
  /// In zh, this message translates to:
  /// **'动画工程导出'**
  String get imageLibraryAnimationProjectSpriteSheetSource;

  /// 作品库条目：Sprite Sheet 行列摘要
  ///
  /// In zh, this message translates to:
  /// **'{rows} x {columns}'**
  String imageLibrarySpriteSheetPrompt(int rows, int columns);

  /// 作品库条目：编辑后的 Sprite Sheet 标题
  ///
  /// In zh, this message translates to:
  /// **'编辑后的 Sprite Sheet'**
  String get imageLibraryEditedSpriteSheetTitle;

  /// 作品库条目：编辑后的 Sprite Sheet 摘要
  ///
  /// In zh, this message translates to:
  /// **'替换第 {frameIndex} 帧 · {rows} x {columns}'**
  String imageLibraryEditedSpriteSheetPrompt(
    int frameIndex,
    int rows,
    int columns,
  );

  /// 作品库条目：保存切片帧标题
  ///
  /// In zh, this message translates to:
  /// **'{sheetTitle} · 帧 {frameIndex}'**
  String imageLibrarySpriteFrameTitle(Object sheetTitle, int frameIndex);

  /// 作品库状态：保存单个切片历史动作
  ///
  /// In zh, this message translates to:
  /// **'保存「{title}」第 {index} 帧'**
  String imageLibraryStateSaveSliceHistory(Object title, int index);

  /// 作品库状态：保存切片失败提示
  ///
  /// In zh, this message translates to:
  /// **'保存切片失败：{error}'**
  String imageLibraryStateSaveSliceFailed(Object error);

  /// 作品库状态：批量保存切片历史动作
  ///
  /// In zh, this message translates to:
  /// **'保存「{title}」{count} 个切片帧'**
  String imageLibraryStateSaveSlicesHistory(Object title, int count);

  /// 作品库状态：切片保存成功提示
  ///
  /// In zh, this message translates to:
  /// **'已保存 {count} 个切片帧到作品集'**
  String imageLibraryStateSavedSlicesMessage(int count);

  /// 作品库状态：作品缺少行列元数据提示
  ///
  /// In zh, this message translates to:
  /// **'该作品缺少行列元数据，无法切片'**
  String get imageLibraryStateItemMissingGrid;

  /// 作品库状态：编辑作品信息历史动作
  ///
  /// In zh, this message translates to:
  /// **'编辑「{title}」'**
  String imageLibraryStateEditMetadataHistory(Object title);

  /// 作品库状态：作品信息更新成功提示
  ///
  /// In zh, this message translates to:
  /// **'作品信息已更新'**
  String get imageLibraryStateMetadataUpdated;

  /// 作品库状态：作品路径复制成功提示
  ///
  /// In zh, this message translates to:
  /// **'作品路径已复制'**
  String get imageLibraryStatePathCopied;

  /// 作品库状态：作品文件不存在提示
  ///
  /// In zh, this message translates to:
  /// **'作品文件不存在'**
  String get imageLibraryStateFileMissing;

  /// 作品库状态：图片复制成功提示
  ///
  /// In zh, this message translates to:
  /// **'图片已复制到剪贴板'**
  String get imageLibraryStateImageCopied;

  /// 作品库状态：图片复制退化为路径复制提示
  ///
  /// In zh, this message translates to:
  /// **'当前平台暂不支持直接复制图片，已复制图片路径'**
  String get imageLibraryStateImagePathCopied;

  /// 作品库状态：动画工程文件导出成功提示
  ///
  /// In zh, this message translates to:
  /// **'动画工程文件已导出：{fileName}'**
  String imageLibraryStateAnimationProjectExported(Object fileName);

  /// 作品库状态：图片导出成功提示
  ///
  /// In zh, this message translates to:
  /// **'图片已导出：{fileName}'**
  String imageLibraryStateImageExported(Object fileName);

  /// 作品库状态：导出前未选择作品提示
  ///
  /// In zh, this message translates to:
  /// **'请先选择要导出的作品'**
  String get imageLibraryStateSelectItemsToExport;

  /// 作品库状态：目录选择确认按钮
  ///
  /// In zh, this message translates to:
  /// **'导出到这里'**
  String get imageLibraryStateExportHere;

  /// 作品库状态：选中作品文件全部缺失提示
  ///
  /// In zh, this message translates to:
  /// **'选中的作品文件都不存在'**
  String get imageLibraryStateSelectedFilesMissing;

  /// 作品库状态：导出时跳过缺失文件提示后缀
  ///
  /// In zh, this message translates to:
  /// **'，跳过 {count} 个缺失文件'**
  String imageLibraryStateSkippedMissingFiles(int count);

  /// 作品库状态：批量导出成功提示
  ///
  /// In zh, this message translates to:
  /// **'已导出 {count} 个作品{skipped}'**
  String imageLibraryStateExportedSelected(int count, Object skipped);

  /// 作品库状态：批量导出失败提示
  ///
  /// In zh, this message translates to:
  /// **'导出已选作品失败：{error}'**
  String imageLibraryStateExportSelectedFailed(Object error);

  /// 作品库状态：打开作品所在位置成功提示
  ///
  /// In zh, this message translates to:
  /// **'已打开作品所在位置'**
  String get imageLibraryStateLocationOpened;

  /// 作品库状态：作品目录不存在提示
  ///
  /// In zh, this message translates to:
  /// **'作品所在目录不存在'**
  String get imageLibraryStateDirectoryMissing;

  /// 作品库状态：作品目录路径已复制提示
  ///
  /// In zh, this message translates to:
  /// **'已复制作品目录路径'**
  String get imageLibraryStateDirectoryPathCopied;

  /// 作品库状态：打开目录失败后复制路径提示
  ///
  /// In zh, this message translates to:
  /// **'无法打开目录，已复制作品目录路径'**
  String get imageLibraryStateDirectoryOpenFailedPathCopied;

  /// 作品库状态：作品不是动画工程提示
  ///
  /// In zh, this message translates to:
  /// **'这个作品不是动画工程'**
  String get imageLibraryStateNotAnimationProject;

  /// 作品库状态：动画工程文件不存在详细错误
  ///
  /// In zh, this message translates to:
  /// **'动画工程文件不存在：{path}'**
  String imageLibraryStateAnimationProjectFileMissingDetail(Object path);

  /// 作品库状态：动画工程文件不存在提示
  ///
  /// In zh, this message translates to:
  /// **'动画工程文件不存在'**
  String get imageLibraryStateAnimationProjectFileMissing;

  /// 作品库状态：打开动画工程历史动作
  ///
  /// In zh, this message translates to:
  /// **'打开动画工程「{title}」'**
  String imageLibraryStateOpenAnimationProjectHistory(Object title);

  /// 作品库状态：打开动画工程成功提示
  ///
  /// In zh, this message translates to:
  /// **'已打开动画工程：{title}'**
  String imageLibraryStateAnimationProjectOpened(Object title);

  /// 作品库状态：打开动画工程失败提示
  ///
  /// In zh, this message translates to:
  /// **'打开动画工程失败：{error}'**
  String imageLibraryStateOpenAnimationProjectFailed(Object error);

  /// 作品库状态：透明背景生成作品标题
  ///
  /// In zh, this message translates to:
  /// **'透明背景：{title}'**
  String imageLibraryStateTransparentBackgroundTitle(Object title);

  /// 作品库状态：透明背景生成作品提示词摘要
  ///
  /// In zh, this message translates to:
  /// **'背景转透明 · 容差 {tolerance} · {width} x {height}'**
  String imageLibraryStateTransparentBackgroundPrompt(
    int tolerance,
    int width,
    int height,
  );

  /// 作品库状态：作品不能背景转透明提示
  ///
  /// In zh, this message translates to:
  /// **'该作品不是可处理的静态图片'**
  String get imageLibraryStateNotProcessableStaticImage;

  /// 作品库状态：删除单个作品历史动作
  ///
  /// In zh, this message translates to:
  /// **'删除「{title}」'**
  String imageLibraryStateDeleteOneHistory(Object title);

  /// 作品库状态：批量删除作品历史动作
  ///
  /// In zh, this message translates to:
  /// **'删除 {count} 个作品'**
  String imageLibraryStateDeleteManyHistory(int count);

  /// 作品库状态：删除单个作品成功提示
  ///
  /// In zh, this message translates to:
  /// **'作品已删除'**
  String get imageLibraryStateDeletedOne;

  /// 作品库状态：批量删除作品成功提示
  ///
  /// In zh, this message translates to:
  /// **'已删除 {count} 个作品'**
  String imageLibraryStateDeletedMany(int count);

  /// 作品库状态：作品不能作为图片编辑源提示
  ///
  /// In zh, this message translates to:
  /// **'这类作品不能作为图片编辑源'**
  String get imageLibraryStateUnsupportedEditorSource;

  /// 作品库状态：普通图片已在编辑器打开提示
  ///
  /// In zh, this message translates to:
  /// **'已在图片编辑器中打开：{title}'**
  String imageLibraryStateOpenedInEditor(Object title);

  /// 作品库状态：在编辑器打开作品历史动作
  ///
  /// In zh, this message translates to:
  /// **'在编辑器中打开「{title}」'**
  String imageLibraryStateOpenInEditorHistory(Object title);

  /// 作品库状态：没有可复用生成参数提示
  ///
  /// In zh, this message translates to:
  /// **'这个作品没有可复用的生成参数'**
  String get imageLibraryStateNoReusableGeneration;

  /// 作品库状态：复用生成参数历史动作
  ///
  /// In zh, this message translates to:
  /// **'复用「{title}」生成参数'**
  String imageLibraryStateReuseGenerationHistory(Object title);

  /// 作品库状态：已载入生成参数但需手动选择接口配置
  ///
  /// In zh, this message translates to:
  /// **'已载入作品参数，接口配置需要手动选择'**
  String get imageLibraryStateGenerationLoadedNeedsApiConfig;

  /// 作品库状态：已载入生成参数提示
  ///
  /// In zh, this message translates to:
  /// **'已载入作品参数'**
  String get imageLibraryStateGenerationLoaded;

  /// 作品库状态：没有可复制生成参数提示
  ///
  /// In zh, this message translates to:
  /// **'这个作品没有可复制的生成参数'**
  String get imageLibraryStateNoCopyableGeneration;

  /// 作品库状态：生成参数复制成功提示
  ///
  /// In zh, this message translates to:
  /// **'作品参数已复制'**
  String get imageLibraryStateGenerationCopied;

  /// 本地设置状态：调整分辨率历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整分辨率为 {size}'**
  String localSettingsStateAdjustSizeHistory(Object size);

  /// 本地设置状态：调整生成数量历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整生成数量为 {count} 张'**
  String localSettingsStateAdjustImageCountHistory(int count);

  /// 本地设置状态：修改正向提示词历史动作
  ///
  /// In zh, this message translates to:
  /// **'修改正向提示词'**
  String get localSettingsStateEditPositivePromptHistory;

  /// 本地设置状态：修改动画工程提示词历史动作
  ///
  /// In zh, this message translates to:
  /// **'修改动画工程提示词'**
  String get localSettingsStateEditAnimationPromptHistory;

  /// 本地设置状态：修改负向提示词历史动作
  ///
  /// In zh, this message translates to:
  /// **'修改负向提示词'**
  String get localSettingsStateEditNegativePromptHistory;

  /// 本地设置状态：调整质量历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整质量为 {label}'**
  String localSettingsStateAdjustQualityHistory(Object label);

  /// 本地设置状态：调整背景历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整背景为 {label}'**
  String localSettingsStateAdjustBackgroundHistory(Object label);

  /// 本地设置状态：调整输出格式历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整输出格式为 {label}'**
  String localSettingsStateAdjustOutputFormatHistory(Object label);

  /// 本地设置状态：调整输出压缩率历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整输出压缩率为 {value}%'**
  String localSettingsStateAdjustOutputCompressionHistory(int value);

  /// 本地设置状态：调整审核强度历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整审核强度为 {label}'**
  String localSettingsStateAdjustModerationHistory(Object label);

  /// 本地设置状态：调整参考图保真度历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整参考图保真度为 {label}'**
  String localSettingsStateAdjustInputFidelityHistory(Object label);

  /// 本地设置状态：修改最终用户 ID 历史动作
  ///
  /// In zh, this message translates to:
  /// **'修改最终用户 ID'**
  String get localSettingsStateEditFinalUserHistory;

  /// 本地设置状态：调整高级输出参数历史动作
  ///
  /// In zh, this message translates to:
  /// **'调整高级输出参数'**
  String get localSettingsStateAdjustAdvancedSettingsHistory;

  /// 本地设置状态：文本生图预设默认名称
  ///
  /// In zh, this message translates to:
  /// **'文本生图 {index}'**
  String localSettingsStateTextPresetName(int index);

  /// 本地设置状态：动画工程预设默认名称
  ///
  /// In zh, this message translates to:
  /// **'动画工程 {index}'**
  String localSettingsStateAnimationPresetName(int index);

  /// 本地设置状态：预设保存成功提示
  ///
  /// In zh, this message translates to:
  /// **'已保存预设：{name}'**
  String localSettingsStatePresetSaved(Object name);

  /// 本地设置状态：应用预设历史动作
  ///
  /// In zh, this message translates to:
  /// **'应用预设：{name}'**
  String localSettingsStateApplyPresetHistory(Object name);

  /// 本地设置状态：预设应用成功提示
  ///
  /// In zh, this message translates to:
  /// **'已应用预设：{name}'**
  String localSettingsStatePresetApplied(Object name);

  /// 本地设置状态：预设删除成功提示
  ///
  /// In zh, this message translates to:
  /// **'已删除预设：{name}'**
  String localSettingsStatePresetDeleted(Object name);

  /// 本地设置状态：存储清理成功提示
  ///
  /// In zh, this message translates to:
  /// **'已清理 {count} 个文件，释放 {size}'**
  String localSettingsStateCleanupDone(int count, Object size);

  /// 本地设置状态：存储清理失败提示
  ///
  /// In zh, this message translates to:
  /// **'清理失败：{error}'**
  String localSettingsStateCleanupFailed(Object error);

  /// 本地设置状态：作品库归档导出成功提示
  ///
  /// In zh, this message translates to:
  /// **'已导出 {count} 个作品{skipped}：{fileName}'**
  String localSettingsStateLibraryArchiveExported(
    int count,
    Object skipped,
    Object fileName,
  );

  /// 本地设置状态：作品库导出失败提示
  ///
  /// In zh, this message translates to:
  /// **'导出作品库失败：{error}'**
  String localSettingsStateExportLibraryFailed(Object error);

  /// 本地设置状态：导入作品库历史动作
  ///
  /// In zh, this message translates to:
  /// **'导入作品库'**
  String get localSettingsStateImportLibraryHistory;

  /// 本地设置状态：导入作品库时跳过无效条目提示后缀
  ///
  /// In zh, this message translates to:
  /// **'，跳过 {count} 个无效条目'**
  String localSettingsStateSkippedInvalidItems(int count);

  /// 本地设置状态：作品库归档导入成功提示
  ///
  /// In zh, this message translates to:
  /// **'已导入 {count} 个作品{skipped}'**
  String localSettingsStateLibraryArchiveImported(int count, Object skipped);

  /// 本地设置状态：作品库导入失败提示
  ///
  /// In zh, this message translates to:
  /// **'导入作品库失败：{error}'**
  String localSettingsStateImportLibraryFailed(Object error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
