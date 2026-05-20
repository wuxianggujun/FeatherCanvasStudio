import 'dart:typed_data';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:feather_canvas_studio/src/widgets/background_transparency_dialog.dart';
import 'package:feather_canvas_studio/src/widgets/patch_image_framing_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

void main() {
  testWidgets(
    'background transparency dialog exposes focus group and slider value',
    (tester) async {
      int? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    result = await showBackgroundTransparencyDialog(
                      context,
                      sourceTitle: '角色.png',
                      initialTolerance: 12,
                    );
                  },
                  child: const Text('打开背景透明'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开背景透明'));
      await tester.pumpAndSettle();

      expect(find.byType(FocusTraversalGroup), findsWidgets);
      expect(find.text('处理「角色.png」，生成一张新的透明 PNG。'), findsOneWidget);
      expect(find.bySemanticsLabel('容差 12'), findsWidgets);

      await tester.tap(find.text('生成透明图'));
      await tester.pumpAndSettle();

      expect(result, 12);
    },
  );

  testWidgets('patch image framing dialog exposes preview semantics', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    PatchImageFraming? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  result = await showPatchImageFramingDialog(
                    context,
                    imageBytes: _solidPng(width: 4, height: 4),
                    targetWidth: 8,
                    targetHeight: 8,
                    sourceTitle: '单帧.png',
                  );
                },
                child: const Text('打开单帧取景'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开单帧取景'));
    await tester.pumpAndSettle();

    expect(find.byType(FocusTraversalGroup), findsWidgets);
    expect(
      find.bySemanticsLabel(
        RegExp(r'单帧取景预览 · 目标 8 x 8 · 缩放 \d+% · 偏移 X 0，Y 0'),
      ),
      findsWidgets,
    );
    expect(find.bySemanticsLabel(RegExp(r'缩放 \d+%')), findsWidgets);

    await tester.tap(find.text('生成取景单帧'));
    await tester.pumpAndSettle();

    expect(result?.scale, moreOrLessEquals(2));
  });

  testWidgets('frame replacement confirmation exposes image semantics', (
    tester,
  ) async {
    bool? confirmed;
    final bytes = _solidPng(width: 2, height: 2);
    final preview = SpriteSheetFrameReplacementPreview(
      originalFrameBytes: bytes,
      patchBytes: bytes,
      resultFrameBytes: bytes,
      editedSheetBytes: bytes,
      frameIndex: 0,
      frameWidth: 2,
      frameHeight: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  confirmed = await confirmSpriteSheetFrameReplacementDialog(
                    context,
                    preview: preview,
                    columns: 2,
                    fitLabel: '完整放入',
                  );
                },
                child: const Text('打开替换确认'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开替换确认'));
    await tester.pumpAndSettle();

    expect(find.byType(FocusTraversalGroup), findsWidgets);
    expect(find.bySemanticsLabel('原帧'), findsWidgets);
    expect(find.bySemanticsLabel('单帧图片'), findsWidgets);
    expect(find.bySemanticsLabel('替换后'), findsWidgets);

    await tester.tap(find.text('确认替换'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });
}

Uint8List _solidPng({required int width, required int height}) {
  final image = image_lib.Image(width: width, height: height, numChannels: 4)
    ..clear(image_lib.ColorRgba8(20, 120, 220, 255));
  return Uint8List.fromList(image_lib.encodePng(image));
}
