import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('delete confirmation dialog keeps readable focus order', (
    tester,
  ) async {
    bool? confirmed;
    final item = ImageLibraryItem(
      id: 'item-1',
      path: 'missing.png',
      createdAt: DateTime(2026, 5, 19),
      kind: ImageAssetKind.generatedImage,
      title: '待删除作品',
      source: '测试',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  confirmed = await confirmDeleteImageLibraryItemsDialog(
                    context,
                    items: [item],
                    cascadeCount: 0,
                  );
                },
                child: const Text('打开确认'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开确认'));
    await tester.pumpAndSettle();

    expect(find.byType(FocusTraversalGroup), findsWidgets);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确认删除'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });
}
