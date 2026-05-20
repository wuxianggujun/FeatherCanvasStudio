import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Tristate;

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

Future<void> _pumpBoundedSettle(WidgetTester tester) async {
  await tester.pump();
  for (var index = 0; index < 12; index++) {
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (!tester.binding.hasScheduledFrame &&
        find.bySemanticsLabel('切片帧 1 / 4').evaluate().isNotEmpty) {
      return;
    }
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
  testWidgets('slice picker exposes frame semantics and selection state', (
    tester,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'feather-slice-picker-',
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpriteSheetSlicePickerDialog(sheet: sheet, allowMultiple: true),
        ),
      ),
    );

    await _pumpBoundedSettle(tester);

    expect(find.textContaining('加载切片失败'), findsNothing);
    expect(find.text('#1'), findsOneWidget);
    expect(find.bySemanticsLabel('切片帧 1 / 4'), findsWidgets);

    Finder frameSemantics() => find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == '切片帧 1 / 4' &&
          widget.properties.button == true,
    );
    final semantics = tester.getSemantics(frameSemantics());
    expect(semantics.flagsCollection.isSelected, Tristate.isFalse);

    await tester.tap(frameSemantics());
    await tester.pump();

    final selectedSemantics = tester.getSemantics(frameSemantics());
    expect(selectedSemantics.flagsCollection.isSelected, Tristate.isTrue);
    expect(find.text('已选 1 / 4'), findsOneWidget);
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
