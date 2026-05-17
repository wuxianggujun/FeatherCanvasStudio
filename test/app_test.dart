import 'package:feather_canvas_studio/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpBoundedSettle(
  WidgetTester tester, {
  int maxPumps = 12,
}) async {
  await tester.pump();
  for (var index = 0; index < maxPumps; index++) {
    if (!tester.binding.hasScheduledFrame) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('renders the OpenAI-compatible workspace shell', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding.completed': true});
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const FeatherCanvasApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('FeatherCanvas Studio'), findsNothing);
    expect(find.text('文本生图'), findsWidgets);
    expect(find.text('批量生成'), findsOneWidget);
    expect(find.text('动画工程'), findsWidgets);
    expect(find.text('图片编辑器'), findsOneWidget);
    expect(find.text('像素画编辑'), findsOneWidget);
    expect(find.text('GIF 合成'), findsOneWidget);
    expect(find.text('作品库'), findsOneWidget);
    expect(find.text('接口配置'), findsWidgets);
    expect(find.text('文本生图'), findsWidgets);
    expect(find.text('生成配置'), findsOneWidget);
    expect(find.text('Base URL'), findsNothing);
    expect(find.text('API Key'), findsNothing);
    expect(find.text('模型'), findsNothing);
    expect(find.byTooltip('管理接口配置'), findsOneWidget);
    expect(find.text('正向提示词'), findsOneWidget);
    expect(find.text('分辨率档位'), findsOneWidget);
    expect(find.text('宽度'), findsNothing);
    expect(find.text('高度'), findsNothing);
    expect(find.text('1K 方图 · 请求尺寸 1024x1024'), findsOneWidget);
    expect(find.text('生成图片'), findsOneWidget);

    await tester.tap(find.byTooltip('展开侧栏'));
    await _pumpBoundedSettle(tester);

    await tester.tap(find.text('批量生成'));
    await _pumpBoundedSettle(tester);

    expect(find.text('批量生成'), findsWidgets);
    expect(find.text('队列控制'), findsOneWidget);
    expect(find.text('接口配置'), findsWidgets);
    expect(find.text('批量提示词'), findsOneWidget);
    expect(find.text('负向提示词'), findsOneWidget);
    expect(find.text('分辨率档位'), findsOneWidget);
    expect(find.text('高级输出参数'), findsOneWidget);
    expect(find.text('目标数量'), findsOneWidget);
    expect(find.text('每批张数'), findsOneWidget);
    expect(find.text('当前会把每条提示词拆成 25 个串行任务'), findsOneWidget);
    expect(find.text('任务队列'), findsOneWidget);
    expect(find.text('当前表单拆分入队'), findsNothing);

    await tester.tap(find.text('文本生图').first);
    await _pumpBoundedSettle(tester);

    await tester.tap(find.text('1K 方图 · 1024x1024'));
    await _pumpBoundedSettle(tester);
    expect(find.text('1.5K 横图 · 1536x1024'), findsOneWidget);
    expect(find.text('1.5K 竖图 · 1024x1536'), findsOneWidget);
    expect(find.text('自定义'), findsNothing);
    await tester.tap(find.text('1.5K 横图 · 1536x1024').last);
    await _pumpBoundedSettle(tester);
    expect(find.text('1.5K 横图 · 请求尺寸 1536x1024'), findsOneWidget);

    await tester.tap(find.text('动画工程'));
    await _pumpBoundedSettle(tester);

    expect(find.text('动画工程'), findsWidgets);
    expect(find.text('工程控制'), findsOneWidget);
    expect(find.text('序列帧生成配置'), findsOneWidget);
    expect(find.text('模板图片'), findsOneWidget);
    expect(find.text('提示词内容'), findsOneWidget);
    expect(find.text('风格'), findsNothing);
    expect(find.text('核心描述'), findsNothing);
    expect(find.text('运动变化'), findsNothing);
    expect(find.text('4 向'), findsNothing);
    expect(find.text('8 向'), findsNothing);
    expect(find.text('分辨率档位'), findsOneWidget);
    expect(find.text('宽度'), findsNothing);
    expect(find.text('高度'), findsNothing);
    expect(find.text('行数'), findsOneWidget);
    expect(find.text('列数'), findsOneWidget);
    expect(find.textContaining('请求尺寸 1536x1024'), findsWidgets);
    expect(find.text('生成 Sprite Sheet'), findsOneWidget);
    expect(find.text('Base URL'), findsNothing);
    expect(find.text('API Key'), findsNothing);

    await tester.ensureVisible(find.text('生成 Sprite Sheet'));
    await tester.tap(find.text('生成 Sprite Sheet'));
    await _pumpBoundedSettle(tester);

    await tester.ensureVisible(find.text('生成失败'));
    expect(find.text('生成失败'), findsOneWidget);
    expect(find.text('请先在接口配置页填写 API Key。'), findsOneWidget);
    expect(find.text('重试生成'), findsOneWidget);

    await tester.tap(find.text('图片编辑器'));
    await _pumpBoundedSettle(tester);

    expect(find.text('通用编辑'), findsOneWidget);
    expect(find.text('待编辑图片'), findsOneWidget);
    expect(find.text('预览效果'), findsOneWidget);
    expect(find.text('标注'), findsOneWidget);
    expect(find.text('输出'), findsOneWidget);

    await tester.tap(find.text('Sprite Sheet'));
    await _pumpBoundedSettle(tester);

    expect(find.text('编辑配置'), findsOneWidget);
    expect(find.text('Sprite Sheet 图片'), findsOneWidget);
    expect(find.text('单帧图片'), findsOneWidget);
    expect(find.text('4 向'), findsNothing);
    expect(find.text('8 向'), findsNothing);
    expect(find.text('替换目标'), findsOneWidget);
    expect(find.text('适配方式'), findsOneWidget);
    expect(find.text('插入 / 替换到当前格'), findsOneWidget);
    expect(find.text('切片查看'), findsOneWidget);
    expect(find.text('选择一张 Sprite Sheet 后，可以按行列查看第几帧'), findsOneWidget);

    await tester.tap(find.text('像素画编辑'));
    await _pumpBoundedSettle(tester);

    expect(find.text('像素画工具'), findsOneWidget);
    expect(find.text('像素画画布'), findsOneWidget);
    expect(find.text('画笔'), findsOneWidget);
    expect(find.text('橡皮'), findsOneWidget);
    expect(find.text('保存到作品库'), findsOneWidget);

    await tester.tap(find.text('GIF 合成'));
    await _pumpBoundedSettle(tester);

    expect(find.text('GIF 合成'), findsWidgets);
    expect(find.text('GIF 配置'), findsOneWidget);
    expect(find.text('选择图片'), findsOneWidget);
    expect(find.text('播放模式'), findsOneWidget);
    expect(find.text('生成 GIF'), findsOneWidget);

    await tester.tap(find.text('作品库').first);
    await _pumpBoundedSettle(tester);

    expect(find.text('应用内作品'), findsOneWidget);
    expect(find.text('暂无作品。生成、导出、编辑或合成后的图片会保存到这里。'), findsOneWidget);
    expect(find.text('删除作品'), findsNothing);

    await tester.tap(find.text('接口配置').first);
    await _pumpBoundedSettle(tester);

    expect(find.text('接口名称'), findsOneWidget);
    expect(find.text('供应商'), findsOneWidget);
    expect(find.text('OpenAI 官方'), findsOneWidget);
    expect(find.text('Base URL'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('模型'), findsOneWidget);
    expect(find.text('尚未获取模型列表'), findsOneWidget);
    expect(find.byTooltip('获取模型列表'), findsOneWidget);
    expect(find.text('保存配置'), findsOneWidget);
    expect(find.text('测试接口'), findsOneWidget);

    await tester.tap(find.text('设置'));
    await _pumpBoundedSettle(tester);

    expect(find.text('本地设置'), findsOneWidget);
    expect(find.text('本地状态'), findsOneWidget);
    expect(find.text('默认生成设置'), findsOneWidget);
    expect(find.text('默认正向提示词'), findsOneWidget);
    expect(find.text('默认负向提示词'), findsOneWidget);
    expect(find.text('默认生成数量'), findsOneWidget);
    expect(find.text('高级输出参数'), findsOneWidget);
    expect(find.text('打开接口配置'), findsOneWidget);
    expect(find.text('恢复默认表单'), findsOneWidget);
    expect(find.text('恢复默认表单？'), findsNothing);
  });
}
