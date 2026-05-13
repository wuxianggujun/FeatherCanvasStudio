import 'package:feather_canvas_studio/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the OpenAI-compatible workspace shell', (tester) async {
    await tester.pumpWidget(const FeatherCanvasApp());

    expect(find.text('FeatherCanvas Studio'), findsWidgets);
    expect(find.text('OpenAI 兼容生图'), findsOneWidget);
    expect(find.text('生成配置'), findsOneWidget);
    expect(find.text('正向提示词'), findsOneWidget);
    expect(find.text('生成图片'), findsOneWidget);
  });
}
