String buildSpriteSheetPromptText({
  required String prompt,
  required int rows,
  required int columns,
  required bool hasTemplate,
}) {
  return [
    prompt.trim(),
    'Create ONE complete sprite sheet image, not separate files.',
    'The sprite sheet must be arranged as exactly $rows rows x $columns columns, total ${rows * columns} cells.',
    'Each cell must have equal size and align to a clean grid.',
    'Rows may represent separate animation tracks, poses, actions, or variants as implied by the prompt.',
    'Columns represent sequential animation frames from left to right.',
    'Keep the same character, silhouette, scale, camera angle, lighting, palette, and visual style across every cell.',
    if (hasTemplate)
      'Use the provided template image as the core reference and preserve its silhouette, key colors, and subject identity.',
    'Output only the final sprite sheet image. No labels, no text, no decorative border, no extra margin.',
  ].join('\n');
}

String animationFrameGridLabel(int index, {required int columns}) {
  final row = index ~/ columns;
  final column = index % columns + 1;
  return '第 ${row + 1} 行 · 第 $column 列';
}

String animationFrameGridLabelWithText(
  int index, {
  required int columns,
  required String rowLabel,
  required String columnLabel,
}) {
  final row = index ~/ columns;
  final column = index % columns + 1;
  return '$rowLabel ${row + 1} · $columnLabel $column';
}

String editorFrameGridLabel(int index, {required int columns}) {
  final row = index ~/ columns;
  final column = index % columns + 1;
  return '第 ${index + 1} 帧 · 第 ${row + 1} 行 · 第 $column 列';
}

String editorFrameGridLabelWithText(
  int index, {
  required int columns,
  required String Function(int frameIndex, int row, int column) labelBuilder,
}) {
  final row = index ~/ columns;
  final column = index % columns + 1;
  return labelBuilder(index + 1, row + 1, column);
}
