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
  String get historyUndo => '撤销';

  @override
  String get historyRedo => '重做';

  @override
  String get historyMenuTitle => '历史记录';

  @override
  String get historyMenuEmpty => '暂无历史';

  @override
  String get historyApplying => '历史操作执行中';

  @override
  String get splitHandleTooltip => '拖动调整宽度，双击复位';
}
