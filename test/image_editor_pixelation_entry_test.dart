import 'dart:convert';
import 'dart:io';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

void main() {
  testWidgets('选择 Sprite Sheet 后自动露出像素化入口', (tester) async {
    final imagePath = _writeTempPng('editor_pixelation_entry.png');
    addTearDown(() => File(imagePath).deleteSync());

    String? selectedImagePath;
    int? pixelatedFrameBlockSize;
    int? pixelatedSheetBlockSize;
    late StateSetter setHarnessState;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setHarnessState = setState;
              return SingleChildScrollView(
                child: SpriteSheetEditorPanel(
                  imagePath: selectedImagePath,
                  patchImagePath: null,
                  rows: 2,
                  columns: 2,
                  gridSpec: const SpriteSheetGridSpec(rows: 2, columns: 2),
                  targetFrameIndex: 0,
                  frameFit: SpriteSheetFrameFit.contain,
                  isReplacingFrame: false,
                  onPickImage: () {},
                  onClearImage: () {},
                  onPickPatchImage: () {},
                  onClearPatchImage: () {},
                  onAdjustPatchFraming: () {},
                  onMakePatchBackgroundTransparent: (_) {},
                  onPixelateCurrentFrame: (blockSize) {
                    pixelatedFrameBlockSize = blockSize;
                  },
                  onPixelateWholeSheet: (blockSize) {
                    pixelatedSheetBlockSize = blockSize;
                  },
                  onRowsChanged: (_) {},
                  onColumnsChanged: (_) {},
                  onGridSpecChanged: (_) {},
                  onTargetFrameChanged: (_) {},
                  onFrameFitChanged: (_) {},
                  onReplaceFrame: () {},
                  onCopyPreviousFrame: () {},
                  onClearTargetFrame: () {},
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('像素化当前帧'), findsNothing);
    expect(find.text('像素化整张'), findsNothing);

    setHarnessState(() {
      selectedImagePath = imagePath;
    });
    await tester.pumpAndSettle();

    expect(find.text('像素化当前帧'), findsOneWidget);
    expect(find.text('像素化整张'), findsOneWidget);

    await tester.ensureVisible(find.text('像素化当前帧'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('像素化当前帧'));
    await tester.ensureVisible(find.text('像素化整张'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('像素化整张'));

    expect(pixelatedFrameBlockSize, 8);
    expect(pixelatedSheetBlockSize, 8);
  });
}

String _writeTempPng(String fileName) {
  final directory = Directory(
    '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
    '${Platform.pathSeparator}image_editor_pixelation_entry_test',
  )..createSync(recursive: true);
  final path = '${directory.path}${Platform.pathSeparator}$fileName';
  File(path).writeAsBytesSync(base64Decode(_onePixelPngBase64));
  return path;
}
