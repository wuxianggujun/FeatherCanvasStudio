import 'package:feather_canvas_studio/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps app defaults aligned with persisted settings defaults', () {
    final settingsDefaults = AppSettings.defaults();

    expect(defaultAppSettings.toJson(), settingsDefaults.toJson());
    expect(ApiConfig.defaults().model, defaultAppSettings.model);
    expect(defaultAnimationRows, 4);
    expect(defaultAnimationColumns, 4);
    expect(defaultEditorFrameFit, SpriteSheetFrameFit.contain);
    expect(defaultGifFrameDelayMs, 120);
    expect(defaultGifPlaybackMode, GifPlaybackMode.normal);
    expect(defaultAnimationPrompt, isNotEmpty);
  });
}
