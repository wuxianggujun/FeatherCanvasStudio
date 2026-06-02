import 'dart:convert';
import 'dart:ui' show Tristate;

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

  testWidgets('preview images expose semantic labels in tiles and dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
              targetAspectRatio: 1,
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

    final tileImage = tester.widget<Image>(find.byType(Image).first);
    expect(tileImage.semanticLabel, '结果 1');
    expect(find.bySemanticsLabel('结果 1'), findsWidgets);

    for (final label in ['复制图片', '导出图片', '背景转透明']) {
      final semantics = tester.getSemantics(find.byTooltip(label).first);
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isEnabled, Tristate.isTrue);
    }

    await tester.tap(find.bySemanticsLabel('结果 1').first);
    await tester.pumpAndSettle();

    expect(find.byType(FocusTraversalGroup), findsWidgets);
    expect(find.text('结果 1'), findsWidgets);
    final dialogImages = tester.widgetList<Image>(find.byType(Image));
    expect(
      dialogImages.map((widget) => widget.semanticLabel),
      contains('结果 1'),
    );
    for (final label in ['复制图片', '导出图片', '关闭']) {
      final semantics = tester.getSemantics(find.byTooltip(label).last);
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isEnabled, Tristate.isTrue);
    }
  });

  testWidgets('preview dialog navigates between generated images', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final images = [
      GeneratedImage.bytes(base64Decode(_onePixelPngBase64)),
      GeneratedImage.bytes(base64Decode(_onePixelPngBase64)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: PreviewPanel(
              errorMessage: null,
              generatedImages: images,
              isGenerating: false,
              debugRecord: null,
              targetAspectRatio: 1,
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

    await tester.tap(find.bySemanticsLabel('结果 1').first);
    await tester.pumpAndSettle();

    expect(find.text('结果 1'), findsWidgets);
    expect(find.text('结果 2'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('结果 1'), findsNothing);
    expect(find.text('结果 2'), findsWidgets);
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .map((widget) => widget.semanticLabel),
      contains('结果 2'),
    );
  });

  testWidgets('preview panel uses a lazy grid for large result sets', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final images = [
      for (var index = 0; index < 180; index++)
        GeneratedImage.bytes(base64Decode(_onePixelPngBase64)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: PreviewPanel(
              errorMessage: null,
              generatedImages: images,
              isGenerating: true,
              targetImageCount: 10000,
              debugRecord: null,
              targetAspectRatio: 1,
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

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-grid')), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.byType(Image).evaluate().length, lessThan(images.length));
    expect(find.byType(AspectRatio).evaluate().length, lessThan(images.length));
  });

  testWidgets('preview panel can expand a single tall image to the viewport', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
              targetAspectRatio: 1024 / 1536,
              expandTallPreview: true,
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

    final grid = find.byKey(const ValueKey('preview-grid'));
    expect(grid, findsOneWidget);
    expect(tester.getSize(grid).height, greaterThan(620));
  });

  testWidgets('preview panel shows optional source labels and notice', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
              targetAspectRatio: 1,
              imageSourceLabels: const ['第 21/21 批 · 第 4/4 张'],
              noticeMessage: '已成功返回 124 张，当前仅预览 120 张，还有 4 张未在预览区显示。',
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

    expect(find.text('第 21/21 批 · 第 4/4 张'), findsOneWidget);
    expect(find.text('已成功返回 124 张，当前仅预览 120 张，还有 4 张未在预览区显示。'), findsOneWidget);

    final tileImage = tester.widget<Image>(find.byType(Image).first);
    expect(tileImage.semanticLabel, '结果 1 · 第 21/21 批 · 第 4/4 张');

    await tester.tap(find.bySemanticsLabel('结果 1 · 第 21/21 批 · 第 4/4 张'));
    await tester.pumpAndSettle();

    expect(find.text('结果 1 · 第 21/21 批 · 第 4/4 张'), findsWidgets);
  });

  testWidgets('preview state surfaces expose empty and error semantics', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: PreviewPanel(
              errorMessage: null,
              generatedImages: const [],
              isGenerating: false,
              debugRecord: null,
              targetAspectRatio: 1,
              onRetry: () => retryCount++,
              onCopyImage: (_, _) {},
              onExportImage: (_, _) {},
              onMakeBackgroundTransparent: (_, _) {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((widget) => widget.properties.label),
      contains('生成后的图片会显示在这里'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: PreviewPanel(
              errorMessage: 'network error',
              generatedImages: const [],
              isGenerating: false,
              debugRecord: null,
              targetAspectRatio: 1,
              onRetry: () => retryCount++,
              onCopyImage: (_, _) {},
              onExportImage: (_, _) {},
              onMakeBackgroundTransparent: (_, _) {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((widget) => widget.properties.label),
      contains('生成失败 · network error'),
    );
    await tester.tap(find.widgetWithText(FilledButton, '重试生成'));
    await tester.pump();

    expect(retryCount, 1);
  });
}
