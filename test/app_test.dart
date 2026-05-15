import 'package:feather_canvas_studio/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders the OpenAI-compatible workspace shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FeatherCanvasApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('FeatherCanvas Studio'), findsNothing);
    expect(find.text('文本生图'), findsWidgets);
    expect(find.text('帧动画'), findsOneWidget);
    expect(find.text('图片编辑器'), findsOneWidget);
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
    expect(find.text('画幅'), findsOneWidget);
    expect(find.text('宽度'), findsOneWidget);
    expect(find.text('高度'), findsOneWidget);
    expect(find.text('方图 · 请求尺寸 1024x1024'), findsOneWidget);
    expect(find.text('生成图片'), findsOneWidget);

    await tester.tap(find.text('方图'));
    await tester.pumpAndSettle();
    expect(find.text('横图'), findsOneWidget);
    expect(find.text('竖图'), findsOneWidget);
    expect(find.text('自定义'), findsOneWidget);
    await tester.tap(find.text('横图'));
    await tester.pumpAndSettle();
    expect(find.text('横图 · 请求尺寸 1536x1024'), findsOneWidget);

    await tester.tap(find.text('帧动画'));
    await tester.pumpAndSettle();

    expect(find.text('帧动画生成'), findsOneWidget);
    expect(find.text('帧动画配置'), findsOneWidget);
    expect(find.text('模板图片'), findsOneWidget);
    expect(find.text('提示词内容'), findsOneWidget);
    expect(find.text('风格'), findsNothing);
    expect(find.text('核心描述'), findsNothing);
    expect(find.text('运动变化'), findsNothing);
    expect(find.text('4 向'), findsNothing);
    expect(find.text('8 向'), findsNothing);
    expect(find.text('画幅'), findsOneWidget);
    expect(find.text('宽度'), findsOneWidget);
    expect(find.text('高度'), findsOneWidget);
    expect(find.text('行数'), findsOneWidget);
    expect(find.text('列数'), findsOneWidget);
    expect(find.textContaining('K 方图'), findsNothing);
    expect(find.text('生成 Sprite Sheet'), findsOneWidget);
    expect(find.text('Base URL'), findsNothing);
    expect(find.text('API Key'), findsNothing);

    await tester.ensureVisible(find.text('生成 Sprite Sheet'));
    await tester.tap(find.text('生成 Sprite Sheet'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('生成失败'));
    expect(find.text('生成失败'), findsOneWidget);
    expect(find.text('请先在接口配置页填写 API Key。'), findsOneWidget);
    expect(find.text('重试生成'), findsOneWidget);

    await tester.tap(find.text('图片编辑器'));
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('GIF 合成'));
    await tester.pumpAndSettle();

    expect(find.text('GIF 合成'), findsWidgets);
    expect(find.text('GIF 配置'), findsOneWidget);
    expect(find.text('选择图片'), findsOneWidget);
    expect(find.text('播放模式'), findsOneWidget);
    expect(find.text('生成 GIF'), findsOneWidget);

    await tester.tap(find.text('作品库').first);
    await tester.pumpAndSettle();

    expect(find.text('应用内作品'), findsOneWidget);
    expect(find.text('暂无作品。生成、导出、编辑或合成后的图片会保存到这里。'), findsOneWidget);
    expect(find.text('删除作品'), findsNothing);

    await tester.tap(find.text('接口配置').first);
    await tester.pumpAndSettle();

    expect(find.text('接口名称'), findsOneWidget);
    expect(find.text('供应商'), findsOneWidget);
    expect(find.text('OpenAI 官方'), findsOneWidget);
    expect(find.text('Base URL'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('模型'), findsOneWidget);
    expect(find.byTooltip('获取模型列表'), findsOneWidget);
    expect(find.text('保存配置'), findsOneWidget);
    expect(find.text('测试接口'), findsOneWidget);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    expect(find.text('本地设置'), findsOneWidget);
    expect(find.text('本地状态'), findsOneWidget);
    expect(find.text('打开接口配置'), findsOneWidget);
    expect(find.text('恢复默认表单'), findsOneWidget);
    expect(find.text('恢复默认表单？'), findsNothing);
  });
}
