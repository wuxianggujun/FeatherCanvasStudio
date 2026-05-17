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

  /// 工作区分隔条提示
  ///
  /// In zh, this message translates to:
  /// **'拖动调整宽度，双击复位'**
  String get splitHandleTooltip;
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
