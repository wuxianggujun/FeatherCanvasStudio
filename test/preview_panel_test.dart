import 'dart:convert';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

void main() {
  testWidgets('preview tiles preserve requested image aspect ratio', (
    tester,
  ) async {
    final image = GeneratedImage.bytes(base64Decode(_onePixelPngBase64));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: PreviewPanel(
              errorMessage: null,
              generatedImages: [image],
              isGenerating: false,
              debugRecord: null,
              targetAspectRatio: 16 / 9,
              onRetry: () {},
              onCopyImage: (_, _) {},
              onExportImage: (_, _) {},
              onMakeBackgroundTransparent: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final aspectRatios = tester
        .widgetList<AspectRatio>(find.byType(AspectRatio))
        .map((widget) => widget.aspectRatio);
    expect(aspectRatios, contains(moreOrLessEquals(16 / 9)));

    final previewImage = tester.widget<Image>(find.byType(Image).first);
    expect(previewImage.fit, BoxFit.contain);
  });
}
