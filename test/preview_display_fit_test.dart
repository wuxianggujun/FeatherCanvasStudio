import 'dart:convert';
import 'dart:io';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

void main() {
  testWidgets('template image picker previews without cropping', (
    tester,
  ) async {
    final imagePath = _writeTempPng('template_preview_fit.png');
    addTearDown(() => File(imagePath).deleteSync());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TemplateImagePicker(
            imagePath: imagePath,
            onPick: () {},
            onClear: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
  });

  testWidgets('template image picker can preview multiple images', (
    tester,
  ) async {
    final firstPath = _writeTempPng('template_preview_multi_a.png');
    final secondPath = _writeTempPng('template_preview_multi_b.png');
    addTearDown(() => File(firstPath).deleteSync());
    addTearDown(() => File(secondPath).deleteSync());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TemplateImagePicker(
            imagePaths: [firstPath, secondPath],
            selectedSummary: '2 张参考图',
            onPick: () {},
            onClear: () {},
            onRemoveImage: (_) {},
            removeImageTooltipBuilder: (path) =>
                '移除：${path.split(RegExp(r'[\\/]+')).last}',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2 张参考图'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    expect(
      find.bySemanticsLabel('template_preview_multi_a.png'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('template_preview_multi_b.png'),
      findsOneWidget,
    );
    expect(
      tester.widgetList<Image>(find.byType(Image)).map((image) => image.fit),
      everyElement(BoxFit.contain),
    );
  });

  testWidgets('image library previews preserve the full image', (tester) async {
    final imagePath = _writeTempPng('library_preview_fit.png');
    addTearDown(() => File(imagePath).deleteSync());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 120,
            child: ImageLibraryPreview(
              item: ImageLibraryItem(
                id: 'library-preview',
                path: imagePath,
                createdAt: DateTime(2026, 5, 17),
                kind: ImageAssetKind.generatedImage,
                title: 'Library preview',
                source: '测试',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
  });
}

String _writeTempPng(String fileName) {
  final directory = Directory(
    '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
    '${Platform.pathSeparator}preview_display_fit_test',
  )..createSync(recursive: true);
  final path = '${directory.path}${Platform.pathSeparator}$fileName';
  File(path).writeAsBytesSync(base64Decode(_onePixelPngBase64));
  return path;
}
