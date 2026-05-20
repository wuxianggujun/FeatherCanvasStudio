import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Tristate;

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 16,
}) async {
  await tester.pump();
  for (var index = 0; index < maxPumps; index++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _deleteTempDir(Directory directory) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  }
}

void main() {
  testWidgets('library picker exposes item labels and selection state', (
    tester,
  ) async {
    final item = ImageLibraryItem(
      id: 'image-1',
      path: 'missing.png',
      createdAt: DateTime(2026, 5, 19),
      kind: ImageAssetKind.generatedImage,
      title: '测试作品',
      source: '测试',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImageLibraryPickerDialog(
            title: '选择作品',
            items: [item],
            allowMultiple: true,
          ),
        ),
      ),
    );

    const itemLabel = '生图 · 测试作品 · 第 1 / 1 项';
    Finder itemSemantics() => find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == itemLabel &&
          widget.properties.button == true,
    );

    expect(find.byType(FocusTraversalGroup), findsWidgets);
    expect(find.bySemanticsLabel(itemLabel), findsOneWidget);
    expect(
      tester.getSemantics(itemSemantics()).flagsCollection.isSelected,
      Tristate.isFalse,
    );

    await tester.tap(itemSemantics());
    await tester.pump();

    expect(find.text('选择 1 张'), findsOneWidget);
    expect(
      tester.getSemantics(itemSemantics()).flagsCollection.isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('slice explorer exposes saved and unsaved frame labels', (
    tester,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'feather-slice-explorer-',
    );
    addTearDown(() => _deleteTempDir(tempDir));

    final file = File('${tempDir.path}/sheet.png')
      ..writeAsBytesSync(_spriteSheetPng());
    final sheet = ImageLibraryItem(
      id: 'sheet-1',
      path: file.path,
      createdAt: DateTime(2026, 5, 19),
      kind: ImageAssetKind.spriteSheet,
      title: 'Sheet',
      source: 'test',
      gridSpec: const SpriteSheetGridSpec(rows: 2, columns: 2),
    );

    final firstFrame = find.bySemanticsLabel('切片帧 1 / 4 · 已保存');
    final secondFrame = find.bySemanticsLabel('切片帧 2 / 4 · 未保存');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpriteSheetSliceExplorerDialog(
            sheet: sheet,
            savedFrameIndexes: const {0},
            onSaveSlice: (_, _) async => true,
            onSaveAllSlices: (_) async => 0,
          ),
        ),
      ),
    );

    await _pumpUntilFound(tester, firstFrame);

    expect(find.byType(FocusTraversalGroup), findsWidgets);
    expect(find.textContaining('加载切片失败'), findsNothing);
    expect(firstFrame, findsWidgets);
    expect(secondFrame, findsWidgets);

    final savedImage = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image && widget.semanticLabel == '切片帧 1 / 4 · 已保存',
      ),
    );
    expect(savedImage.fit, BoxFit.contain);

    final unsavedSemantics = tester.getSemantics(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == '切片帧 2 / 4 · 未保存' &&
            widget.properties.button == true,
      ),
    );
    expect(unsavedSemantics.flagsCollection.isEnabled, Tristate.isTrue);
  });
}

Uint8List _spriteSheetPng() {
  final image = image_lib.Image(width: 4, height: 4);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final isRight = x >= 2;
      final isBottom = y >= 2;
      image.setPixelRgb(
        x,
        y,
        isRight ? 0 : 255,
        isBottom ? 255 : 0,
        isRight && isBottom ? 255 : 0,
      );
    }
  }
  return Uint8List.fromList(image_lib.encodePng(image));
}
