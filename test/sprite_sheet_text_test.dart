import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds sprite sheet prompt with grid and template instructions', () {
    final prompt = buildSpriteSheetPromptText(
      prompt: ' walk cycle ',
      rows: 2,
      columns: 3,
      hasTemplate: true,
    );

    expect(prompt, startsWith('walk cycle'));
    expect(prompt, contains('2 rows x 3 columns'));
    expect(prompt, contains('total 6 cells'));
    expect(prompt, contains('provided template image'));
    expect(prompt, contains('No labels, no text'));
  });

  test('formats animation and editor frame labels', () {
    expect(animationFrameGridLabel(5, columns: 4), '第 2 行 · 第 2 列');
    expect(editorFrameGridLabel(5, columns: 4), '第 6 帧 · 第 2 行 · 第 2 列');
  });
}
