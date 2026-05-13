import 'package:feather_canvas_studio/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders the OpenAI-compatible workspace shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FeatherCanvasApp());
    await tester.pumpAndSettle();

    expect(find.text('FeatherCanvas Studio'), findsWidgets);
    expect(find.text('OpenAI 兼容生图'), findsOneWidget);
    expect(find.text('生成配置'), findsOneWidget);
    expect(find.text('正向提示词'), findsOneWidget);
    expect(find.text('生成图片'), findsOneWidget);
    expect(find.text('生成历史'), findsOneWidget);
  });
}
