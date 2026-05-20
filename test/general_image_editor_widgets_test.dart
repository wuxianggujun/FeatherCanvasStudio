import 'dart:io';

import 'package:feather_canvas_studio/src/services/general_image_editing_service.dart';
import 'package:feather_canvas_studio/src/widgets/general_image_editor_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

Future<void> _pumpBoundedSettle(WidgetTester tester) async {
  await tester.pump();
  for (var index = 0; index < 12; index++) {
    if (!tester.binding.hasScheduledFrame) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _selectEditorPanel(WidgetTester tester, String label) async {
  final labelFinder = find.text(label);
  await tester.ensureVisible(labelFinder);
  await tester.pump();
  await tester.tap(
    find.ancestor(of: labelFinder, matching: find.byType(InkWell)).last,
  );
  await _pumpBoundedSettle(tester);
}

void main() {
  testWidgets('general image editor undo and redo expose disabled reasons', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: GeneralImageEditorContent(
              imagePath: null,
              imageInfo: null,
              isProcessing: false,
              errorMessage: null,
              onPickImage: () {},
              onClearImage: () {},
              onApplyEdit: (_) async {},
            ),
          ),
        ),
      ),
    );
    await _pumpBoundedSettle(tester);

    expect(_semanticsWithValue('暂无可撤销操作'), findsWidgets);
    expect(_semanticsWithValue('暂无可重做操作'), findsWidgets);
  });

  testWidgets(
    'general image editor keeps tool controls outside preview panel',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1400, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tempDir = Directory.systemTemp.createTempSync(
        'feather-general-editor-layout-',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final source = image_lib.Image(width: 80, height: 80, numChannels: 4)
        ..clear(image_lib.ColorRgba8(240, 240, 240, 255));
      final file = File('${tempDir.path}/source.png')
        ..writeAsBytesSync(image_lib.encodePng(source));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1400,
              height: 1600,
              child: GeneralImageEditorContent(
                imagePath: file.path,
                imageInfo: const ImageInspectionResult(
                  width: 80,
                  height: 80,
                  hasAlpha: false,
                ),
                isProcessing: false,
                errorMessage: null,
                onPickImage: () {},
                onClearImage: () {},
                onApplyEdit: (_) async {},
              ),
            ),
          ),
        ),
      );
      await _pumpBoundedSettle(tester);

      final previewPanel = find.byKey(
        const ValueKey('general-image-editor-preview-panel'),
      );
      final panelTabs = find.byKey(
        const ValueKey('general-image-editor-panel-tabs'),
      );
      final previewActions = find.byKey(
        const ValueKey('general-image-editor-preview-actions'),
      );
      final geometryActions = find.byKey(
        const ValueKey('general-image-editor-geometry-actions'),
      );

      expect(previewPanel, findsOneWidget);
      expect(panelTabs, findsOneWidget);
      expect(previewActions, findsOneWidget);
      expect(geometryActions, findsOneWidget);
      expect(
        find.descendant(of: previewPanel, matching: panelTabs),
        findsNothing,
      );
      expect(
        find.descendant(of: previewPanel, matching: previewActions),
        findsNothing,
      );
      expect(
        find.descendant(of: previewPanel, matching: geometryActions),
        findsNothing,
      );
    },
  );

  testWidgets('can select and delete an annotation from the visual preview', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1400, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync(
      'feather-general-editor-',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final source = image_lib.Image(width: 64, height: 64, numChannels: 4)
      ..clear(image_lib.ColorRgba8(240, 240, 240, 255));
    final file = File('${tempDir.path}/source.png')
      ..writeAsBytesSync(image_lib.encodePng(source));
    GeneralImageEditOptions? appliedOptions;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1400,
            height: 2400,
            child: GeneralImageEditorContent(
              imagePath: file.path,
              imageInfo: const ImageInspectionResult(
                width: 64,
                height: 64,
                hasAlpha: false,
              ),
              isProcessing: false,
              errorMessage: null,
              onPickImage: () {},
              onClearImage: () {},
              onApplyEdit: (options) async {
                appliedOptions = options;
              },
            ),
          ),
        ),
      ),
    );
    await _pumpBoundedSettle(tester);

    expect(
      find.byKey(const ValueKey('general-image-editable-preview')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('source.png · 拖拽裁剪框或选区，点击标注可删除'),
      findsAtLeastNWidgets(1),
    );

    await _selectEditorPanel(tester, '标注');
    await tester.tap(find.text('添加标注'));
    await _pumpBoundedSettle(tester);

    expect(find.textContaining('1. 矩形'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('general-image-editable-preview')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('delete-selected-annotation')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('delete-selected-annotation')));
    await tester.pump();

    expect(find.textContaining('1. 矩形'), findsNothing);

    await tester.ensureVisible(find.text('撤销'));
    await tester.pump();
    await tester.tap(find.text('撤销'));
    await tester.pump();
    expect(find.textContaining('1. 矩形'), findsOneWidget);

    await tester.ensureVisible(find.text('重做'));
    await tester.pump();
    await tester.tap(find.text('重做'));
    await tester.pump();
    expect(find.textContaining('1. 矩形'), findsNothing);

    await _selectEditorPanel(tester, '外观');
    await tester.ensureVisible(find.text('效果处理'));
    await tester.pump();
    await tester.tap(find.text('效果处理'));
    await _pumpBoundedSettle(tester);
    await tester.tap(find.text('模糊'));
    await tester.pump();
    await tester.tap(find.text('锐化'));
    await tester.pump();

    await tester.ensureVisible(find.text('局部选区'));
    await tester.pump();
    await tester.tap(find.text('局部选区'));
    await _pumpBoundedSettle(tester);
    await tester.tap(find.text('只处理选区'));
    await tester.pump();

    await tester.drag(
      find.byKey(const ValueKey('general-image-editable-preview')),
      const Offset(80, 0),
    );
    await tester.pump();

    await _selectEditorPanel(tester, '输出');
    await tester.tap(find.text('PNG').last);
    await _pumpBoundedSettle(tester);
    await tester.tap(find.text('JPEG').last);
    await _pumpBoundedSettle(tester);
    await tester.ensureVisible(find.text('应用并保存'));
    await tester.pump();
    await tester.tap(find.text('应用并保存'));
    await tester.pump();

    expect(appliedOptions?.outputFormat, GeneralImageOutputFormat.jpeg);
    expect(appliedOptions?.blurRadius, 2);
    expect(appliedOptions?.sharpenAmount, 50);
    expect(appliedOptions?.effectRegion.enabled, isTrue);
    expect(appliedOptions?.effectRegion.leftRatio, greaterThan(0.15));
    expect(appliedOptions?.effectRegion.rightRatio, greaterThan(0.85));
  });

  testWidgets('geometry tools open from preview toolbar dialogs', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1400, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync(
      'feather-general-editor-geometry-',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final source = image_lib.Image(width: 200, height: 100, numChannels: 4)
      ..clear(image_lib.ColorRgba8(240, 240, 240, 255));
    final file = File('${tempDir.path}/source.png')
      ..writeAsBytesSync(image_lib.encodePng(source));
    GeneralImageEditOptions? appliedOptions;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1400,
            height: 1800,
            child: GeneralImageEditorContent(
              imagePath: file.path,
              imageInfo: const ImageInspectionResult(
                width: 200,
                height: 100,
                hasAlpha: false,
              ),
              isProcessing: false,
              errorMessage: null,
              onPickImage: () {},
              onClearImage: () {},
              onApplyEdit: (options) async {
                appliedOptions = options;
              },
            ),
          ),
        ),
      ),
    );
    await _pumpBoundedSettle(tester);

    expect(
      find.widgetWithIcon(OutlinedButton, Icons.crop_outlined),
      findsOneWidget,
    );
    expect(
      find.widgetWithIcon(
        OutlinedButton,
        Icons.photo_size_select_large_outlined,
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.crop_outlined));
    await _pumpBoundedSettle(tester);
    await tester.tap(find.text('1:1'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await _pumpBoundedSettle(tester);

    await tester.tap(
      find.widgetWithIcon(
        OutlinedButton,
        Icons.photo_size_select_large_outlined,
      ),
    );
    await _pumpBoundedSettle(tester);
    await tester.tap(find.text('调整输出尺寸'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await _pumpBoundedSettle(tester);

    await tester.tap(find.text('应用并保存'));
    await tester.pump();

    expect(appliedOptions?.crop.left, 50);
    expect(appliedOptions?.crop.right, 50);
    expect(appliedOptions?.crop.top, 0);
    expect(appliedOptions?.crop.bottom, 0);
    expect(appliedOptions?.resize.width, 200);
    expect(appliedOptions?.resize.height, 100);
  });

  testWidgets('can apply and undo a common editing preset', (tester) async {
    tester.view
      ..physicalSize = const Size(1400, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync(
      'feather-general-editor-preset-',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final source = image_lib.Image(width: 2000, height: 1000, numChannels: 4)
      ..clear(image_lib.ColorRgba8(240, 240, 240, 255));
    final file = File('${tempDir.path}/source.png')
      ..writeAsBytesSync(image_lib.encodePng(source));
    GeneralImageEditOptions? appliedOptions;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1400,
            height: 1800,
            child: GeneralImageEditorContent(
              imagePath: file.path,
              imageInfo: const ImageInspectionResult(
                width: 2000,
                height: 1000,
                hasAlpha: false,
              ),
              isProcessing: false,
              errorMessage: null,
              onPickImage: () {},
              onClearImage: () {},
              onApplyEdit: (options) async {
                appliedOptions = options;
              },
            ),
          ),
        ),
      ),
    );
    await _pumpBoundedSettle(tester);

    await tester.tap(find.text('社媒 JPEG'));
    await tester.pump();
    await tester.ensureVisible(find.text('应用并保存'));
    await tester.pump();
    await tester.tap(find.text('应用并保存'));
    await tester.pump();

    expect(appliedOptions?.outputFormat, GeneralImageOutputFormat.jpeg);
    expect(appliedOptions?.jpegQuality, 86);
    expect(appliedOptions?.resize.width, 1080);
    expect(appliedOptions?.resize.height, 540);
    expect(appliedOptions?.sharpenAmount, 35);

    await tester.ensureVisible(find.text('撤销'));
    await tester.pump();
    await tester.tap(find.text('撤销'));
    await tester.pump();
    await tester.ensureVisible(find.text('应用并保存'));
    await tester.pump();
    await tester.tap(find.text('应用并保存'));
    await tester.pump();

    expect(appliedOptions?.outputFormat, GeneralImageOutputFormat.png);
    expect(appliedOptions?.resize.isEmpty, isTrue);
    expect(appliedOptions?.sharpenAmount, 0);
  });

  testWidgets('can save and restore an editor version snapshot', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1400, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync(
      'feather-general-editor-version-',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final source = image_lib.Image(width: 1200, height: 800, numChannels: 4)
      ..clear(image_lib.ColorRgba8(240, 240, 240, 255));
    final file = File('${tempDir.path}/source.png')
      ..writeAsBytesSync(image_lib.encodePng(source));
    GeneralImageEditOptions? appliedOptions;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1400,
            height: 1800,
            child: GeneralImageEditorContent(
              imagePath: file.path,
              imageInfo: const ImageInspectionResult(
                width: 1200,
                height: 800,
                hasAlpha: false,
              ),
              isProcessing: false,
              errorMessage: null,
              onPickImage: () {},
              onClearImage: () {},
              onApplyEdit: (options) async {
                appliedOptions = options;
              },
            ),
          ),
        ),
      ),
    );
    await _pumpBoundedSettle(tester);

    await tester.tap(find.text('版本快照'));
    await _pumpBoundedSettle(tester);
    await tester.tap(find.text('保存当前版本'));
    await tester.pump();

    expect(find.text('版本 1'), findsOneWidget);

    await tester.ensureVisible(find.text('社媒 JPEG'));
    await tester.pump();
    await tester.tap(find.text('社媒 JPEG'));
    await tester.pump();
    await tester.ensureVisible(find.text('应用并保存'));
    await tester.pump();
    await tester.tap(find.text('应用并保存'));
    await tester.pump();

    expect(appliedOptions?.outputFormat, GeneralImageOutputFormat.jpeg);
    expect(appliedOptions?.resize.width, 1080);
    expect(appliedOptions?.sharpenAmount, 35);

    await tester.ensureVisible(find.byTooltip('恢复版本'));
    await tester.pump();
    await tester.tap(find.byTooltip('恢复版本'));
    await tester.pump();
    await tester.ensureVisible(find.text('应用并保存'));
    await tester.pump();
    await tester.tap(find.text('应用并保存'));
    await tester.pump();

    expect(appliedOptions?.outputFormat, GeneralImageOutputFormat.png);
    expect(appliedOptions?.resize.isEmpty, isTrue);
    expect(appliedOptions?.sharpenAmount, 0);

    await tester.ensureVisible(find.byTooltip('删除版本'));
    await tester.pump();
    await tester.tap(find.byTooltip('删除版本'));
    await tester.pump();

    expect(find.text('版本 1'), findsNothing);
  });
}

Finder _semanticsWithValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.value == value,
  );
}
