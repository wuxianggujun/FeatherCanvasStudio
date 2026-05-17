import 'dart:convert';
import 'dart:io';

import 'package:feather_canvas_studio/main.dart';
import 'package:feather_canvas_studio/src/models/image_asset_kind.dart';
import 'package:feather_canvas_studio/src/models/image_library_item.dart';
import 'package:feather_canvas_studio/src/services/app_local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

void main() {
  testWidgets('opens image library item more menu without hanging', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final tempDir = Directory(
      '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
      '${Platform.pathSeparator}image_library_menu_test',
    )..createSync(recursive: true);
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    final imagePath = '${tempDir.path}${Platform.pathSeparator}library.png';
    File(imagePath).writeAsBytesSync(base64Decode(_onePixelPngBase64));

    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final store = AppLocalStore();
    await store.saveOnboardingCompleted(true);
    await store.saveImageLibrary([
      ImageLibraryItem(
        id: 'library-item',
        path: imagePath,
        createdAt: DateTime(2026, 5, 17),
        kind: ImageAssetKind.generatedImage,
        title: 'Menu target',
        source: '测试',
      ),
    ]);

    await tester.pumpWidget(const FeatherCanvasApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byIcon(Icons.collections_outlined));
    await tester.pumpAndSettle();

    final menuButton = find.byTooltip('更多操作');
    expect(menuButton, findsOneWidget);
    await tester.ensureVisible(menuButton);
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('复制图片'), findsOneWidget);
    expect(find.text('导出图片'), findsOneWidget);
    expect(find.text('删除作品'), findsOneWidget);
  });
}
