import 'dart:convert';
import 'dart:io';

import 'package:feather_canvas_studio/main.dart';
import 'package:feather_canvas_studio/src/models/api_provider.dart';
import 'package:feather_canvas_studio/src/models/app_config.dart';
import 'package:feather_canvas_studio/src/models/app_preset.dart';
import 'package:feather_canvas_studio/src/models/image_advanced_settings.dart';
import 'package:feather_canvas_studio/src/models/image_asset_kind.dart';
import 'package:feather_canvas_studio/src/models/image_library_item.dart';
import 'package:feather_canvas_studio/src/services/app_local_store.dart';
import 'package:feather_canvas_studio/src/services/gif_composer_service.dart';
import 'package:feather_canvas_studio/src/utils/app_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _initialSettings = AppSettings(
  baseUrl: 'https://api.openai.com/v1',
  apiKey: '',
  model: '',
  prompt: 'before prompt',
  negativePrompt: 'before negative',
  size: '1024x1024',
  imageCount: 1,
);
const _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

Future<void> _pumpApp(
  WidgetTester tester, {
  AppSettings settings = _initialSettings,
  List<AppPreset> presets = const [],
  List<ImageLibraryItem> libraryItems = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});

  final store = AppLocalStore();
  await store.saveOnboardingCompleted(true);
  await store.saveSettings(settings);
  if (presets.isNotEmpty) {
    await store.savePresets(presets);
  }
  if (libraryItems.isNotEmpty) {
    await store.saveImageLibrary(libraryItems);
  }

  await tester.pumpWidget(const FeatherCanvasApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  final expandButton = find.byTooltip('展开侧栏');
  if (expandButton.evaluate().isNotEmpty) {
    await tester.tap(expandButton);
    await tester.pumpAndSettle();
  }
}

Future<void> _openWorkspace(WidgetTester tester, String label) async {
  await _dismissSnackBars(tester);
  final textFinder = find.text(label);
  final target = textFinder.evaluate().isNotEmpty
      ? textFinder.first
      : find.byTooltip(label).first;
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _dismissSnackBars(WidgetTester tester) async {
  if (find.byType(SnackBar).evaluate().isEmpty) {
    return;
  }

  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await _openWorkspace(tester, '设置');
}

Finder _textFieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
}

String _textFieldValue(WidgetTester tester, String label) {
  final field = tester.widget<TextField>(_textFieldWithLabel(label));
  return field.controller?.text ?? '';
}

Future<void> _enterTextByLabel(
  WidgetTester tester,
  String label,
  String value,
) async {
  final finder = _textFieldWithLabel(label);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pump();
}

Future<void> _applyOnlyVisiblePreset(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.text(name));
  await tester.tap(find.widgetWithText(TextButton, '应用'));
  await tester.pumpAndSettle();
}

Future<void> _tapHistoryButton(
  WidgetTester tester,
  String tooltipPrefix,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is IconButton &&
        widget.onPressed != null &&
        (widget.tooltip?.startsWith(tooltipPrefix) ?? false),
  );
  expect(finder, findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pressUndo(WidgetTester tester) =>
    _tapHistoryButton(tester, '撤销 (Ctrl+Z)');

Future<void> _pressRedo(WidgetTester tester) =>
    _tapHistoryButton(tester, '重做 (Ctrl+Y)');

Future<void> _confirmResetToDefaults(WidgetTester tester) async {
  await tester.ensureVisible(find.text('恢复默认表单'));
  await tester.tap(find.text('恢复默认表单'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, '恢复默认'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('local generation preset can be undone and redone', (
    tester,
  ) async {
    const preset = AppPreset(
      id: 'preset-local',
      name: 'Character sketch',
      kind: AppPresetKind.localGeneration,
      prompt: 'preset prompt',
      negativePrompt: 'preset negative',
      size: '1536x1024',
      imageCount: 3,
    );
    await _pumpApp(tester, presets: [preset]);
    await _openSettings(tester);

    expect(_textFieldValue(tester, '默认正向提示词'), 'before prompt');

    await _applyOnlyVisiblePreset(tester, preset.name);

    expect(_textFieldValue(tester, '默认正向提示词'), 'preset prompt');
    expect(_textFieldValue(tester, '默认负向提示词'), 'preset negative');
    expect(find.text('1.5K 横图 · 请求尺寸 1536x1024'), findsOneWidget);
    expect(_textFieldValue(tester, '默认生成数量'), '3');

    await _pressUndo(tester);

    expect(_textFieldValue(tester, '默认正向提示词'), 'before prompt');
    expect(_textFieldValue(tester, '默认负向提示词'), 'before negative');
    expect(find.text('1K 方图 · 请求尺寸 1024x1024'), findsOneWidget);
    expect(_textFieldValue(tester, '默认生成数量'), '1');

    await _pressRedo(tester);

    expect(_textFieldValue(tester, '默认正向提示词'), 'preset prompt');
    expect(_textFieldValue(tester, '默认负向提示词'), 'preset negative');
    expect(find.text('1.5K 横图 · 请求尺寸 1536x1024'), findsOneWidget);
    expect(_textFieldValue(tester, '默认生成数量'), '3');
  });

  testWidgets('sprite sheet preset restores frame animation settings', (
    tester,
  ) async {
    const preset = AppPreset(
      id: 'preset-sheet',
      name: 'Six column walk',
      kind: AppPresetKind.spriteSheet,
      prompt: 'walk cycle prompt',
      negativePrompt: 'no blur',
      size: '1536x1024',
      rows: 5,
      columns: 6,
    );
    await _pumpApp(tester, presets: [preset]);
    await _openSettings(tester);

    await _applyOnlyVisiblePreset(tester, preset.name);
    await _openWorkspace(tester, '帧动画');

    expect(_textFieldValue(tester, '提示词内容'), 'walk cycle prompt');
    expect(_textFieldValue(tester, '负向提示词'), 'no blur');
    expect(find.text('5 行'), findsOneWidget);
    expect(find.text('6 列'), findsOneWidget);

    await _openSettings(tester);
    await _pressUndo(tester);
    await _openWorkspace(tester, '帧动画');

    expect(_textFieldValue(tester, '提示词内容'), defaultAnimationPrompt);
    expect(_textFieldValue(tester, '负向提示词'), 'before negative');
    expect(find.text('4 行'), findsOneWidget);
    expect(find.text('4 列'), findsOneWidget);

    await _openSettings(tester);
    await _pressRedo(tester);
    await _openWorkspace(tester, '帧动画');

    expect(_textFieldValue(tester, '提示词内容'), 'walk cycle prompt');
    expect(_textFieldValue(tester, '负向提示词'), 'no blur');
    expect(find.text('5 行'), findsOneWidget);
    expect(find.text('6 列'), findsOneWidget);
  });

  testWidgets('gif preset restores composer timing settings', (tester) async {
    const preset = AppPreset(
      id: 'preset-gif',
      name: 'Fast ping pong',
      kind: AppPresetKind.gif,
      gifDelayMs: 80,
      gifLoopCount: 3,
      playbackMode: GifPlaybackMode.pingPong,
    );
    await _pumpApp(tester, presets: [preset]);
    await _openSettings(tester);

    await _applyOnlyVisiblePreset(tester, preset.name);
    await _openWorkspace(tester, 'GIF 合成');

    expect(_textFieldValue(tester, '默认帧时长'), '80');
    expect(find.text('播放 3 次'), findsOneWidget);
    expect(find.text('乒乓'), findsOneWidget);

    await _openSettings(tester);
    await _pressUndo(tester);
    await _openWorkspace(tester, 'GIF 合成');

    expect(_textFieldValue(tester, '默认帧时长'), '120');
    expect(find.text('无限循环'), findsOneWidget);
    expect(find.text('正向'), findsOneWidget);

    await _openSettings(tester);
    await _pressRedo(tester);
    await _openWorkspace(tester, 'GIF 合成');

    expect(_textFieldValue(tester, '默认帧时长'), '80');
    expect(find.text('播放 3 次'), findsOneWidget);
    expect(find.text('乒乓'), findsOneWidget);
  });

  testWidgets('gif composer config changes are undoable', (tester) async {
    await _pumpApp(tester);
    await _openWorkspace(tester, 'GIF 合成');

    await _enterTextByLabel(tester, '默认帧时长', '90');
    await tester.pumpAndSettle();
    expect(_textFieldValue(tester, '默认帧时长'), '90');

    await _pressUndo(tester);
    expect(_textFieldValue(tester, '默认帧时长'), '120');

    await _pressRedo(tester);
    expect(_textFieldValue(tester, '默认帧时长'), '90');

    await tester.tap(find.text('无限循环'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('播放 3 次').last);
    await tester.pumpAndSettle();
    expect(find.text('播放 3 次'), findsOneWidget);

    await _pressUndo(tester);
    expect(find.text('无限循环'), findsOneWidget);

    await _pressRedo(tester);
    expect(find.text('播放 3 次'), findsOneWidget);

    await tester.tap(find.text('正向'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('乒乓').last);
    await tester.pumpAndSettle();
    expect(find.text('乒乓'), findsOneWidget);

    await _pressUndo(tester);
    expect(find.text('正向'), findsOneWidget);

    await _pressRedo(tester);
    expect(find.text('乒乓'), findsOneWidget);
  });

  testWidgets('library generation reuse is undoable and redoable', (
    tester,
  ) async {
    final tempDir = Directory(
      '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
      '${Platform.pathSeparator}history_widget_test',
    )..createSync(recursive: true);
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    final imagePath =
        '${tempDir.path}${Platform.pathSeparator}library-generated-1.png';
    File(imagePath).writeAsBytesSync(base64Decode(_onePixelPngBase64));

    final item = ImageLibraryItem(
      id: 'library-generated-1',
      path: imagePath,
      createdAt: DateTime(2026, 1, 2),
      kind: ImageAssetKind.generatedImage,
      title: 'Saved generation',
      source: '测试',
      generation: GenerationSnapshot(
        id: 'generation-1',
        createdAt: DateTime(2026, 1, 2),
        baseUrl: 'https://api.openai.com/v1',
        model: '',
        providerKind: ApiProviderKind.official,
        prompt: 'library prompt',
        negativePrompt: 'library negative',
        size: '1536x1024',
        imageCount: 2,
        resultCount: 1,
        advancedSettings: const ImageAdvancedSettings(user: 'library-user'),
      ),
    );
    await _pumpApp(tester, libraryItems: [item]);
    await _dismissSnackBars(tester);
    await tester.tap(find.text('作品库'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final reuseButton = find.widgetWithText(OutlinedButton, '复用');
    expect(reuseButton, findsOneWidget);
    await tester.ensureVisible(reuseButton);
    await tester.pumpAndSettle();
    await tester.tap(reuseButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(_textFieldValue(tester, '正向提示词'), 'library prompt');
    expect(_textFieldValue(tester, '负向提示词'), 'library negative');
    expect(_textFieldValue(tester, '目标数量'), '2');

    await _pressUndo(tester);

    expect(_textFieldValue(tester, '正向提示词'), 'before prompt');
    expect(_textFieldValue(tester, '负向提示词'), 'before negative');
    expect(_textFieldValue(tester, '目标数量'), '1');

    await _pressRedo(tester);

    expect(_textFieldValue(tester, '正向提示词'), 'library prompt');
    expect(_textFieldValue(tester, '负向提示词'), 'library negative');
    expect(_textFieldValue(tester, '目标数量'), '2');
  });

  testWidgets('reset to defaults is undoable and keeps saved presets', (
    tester,
  ) async {
    const preset = AppPreset(
      id: 'preset-kept',
      name: 'Keep me',
      kind: AppPresetKind.localGeneration,
      prompt: 'kept preset',
      size: '1024x1024',
      imageCount: 1,
    );
    const settings = AppSettings(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      model: '',
      prompt: 'custom prompt',
      negativePrompt: 'custom negative',
      size: '1024x1536',
      imageCount: 4,
    );
    await _pumpApp(tester, settings: settings, presets: [preset]);
    await _openSettings(tester);

    await _confirmResetToDefaults(tester);

    expect(_textFieldValue(tester, '默认正向提示词'), defaultAppSettings.prompt);
    expect(_textFieldValue(tester, '默认负向提示词'), '');
    expect(find.text(preset.name), findsOneWidget);

    await _pressUndo(tester);

    expect(_textFieldValue(tester, '默认正向提示词'), 'custom prompt');
    expect(_textFieldValue(tester, '默认负向提示词'), 'custom negative');
    expect(find.text('1.5K 竖图 · 请求尺寸 1024x1536'), findsOneWidget);
    expect(_textFieldValue(tester, '默认生成数量'), '4');
    expect(find.text(preset.name), findsOneWidget);

    await _pressRedo(tester);

    expect(_textFieldValue(tester, '默认正向提示词'), defaultAppSettings.prompt);
    expect(_textFieldValue(tester, '默认负向提示词'), '');
    expect(find.text(preset.name), findsOneWidget);
  });

  testWidgets('prompt edits are merged into one undo step', (tester) async {
    await _pumpApp(tester);
    await _openSettings(tester);

    await _enterTextByLabel(tester, '默认正向提示词', 'draft one');
    await tester.pump(const Duration(milliseconds: 200));
    await _enterTextByLabel(tester, '默认正向提示词', 'draft two');
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(_textFieldValue(tester, '默认正向提示词'), 'draft two');

    await _pressUndo(tester);

    expect(_textFieldValue(tester, '默认正向提示词'), 'before prompt');

    await _pressRedo(tester);

    expect(_textFieldValue(tester, '默认正向提示词'), 'draft two');
  });
}
