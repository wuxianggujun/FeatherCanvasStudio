import 'dart:ui';

import 'exceptions.dart';

class SpriteSheetGridSpec {
  const SpriteSheetGridSpec({
    required this.rows,
    required this.columns,
    this.marginLeft = 0,
    this.marginTop = 0,
    this.marginRight = 0,
    this.marginBottom = 0,
    this.columnGap = 0,
    this.rowGap = 0,
  });

  factory SpriteSheetGridSpec.fromJson(Map<String, dynamic> json) {
    return SpriteSheetGridSpec(
      rows: _readInt(json, 'rows'),
      columns: _readInt(json, 'columns'),
      marginLeft: _readInt(json, 'marginLeft', defaultValue: 0),
      marginTop: _readInt(json, 'marginTop', defaultValue: 0),
      marginRight: _readInt(json, 'marginRight', defaultValue: 0),
      marginBottom: _readInt(json, 'marginBottom', defaultValue: 0),
      columnGap: _readInt(json, 'columnGap', defaultValue: 0),
      rowGap: _readInt(json, 'rowGap', defaultValue: 0),
    );
  }

  final int rows;
  final int columns;
  final int marginLeft;
  final int marginTop;
  final int marginRight;
  final int marginBottom;
  final int columnGap;
  final int rowGap;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SpriteSheetGridSpec &&
            rows == other.rows &&
            columns == other.columns &&
            marginLeft == other.marginLeft &&
            marginTop == other.marginTop &&
            marginRight == other.marginRight &&
            marginBottom == other.marginBottom &&
            columnGap == other.columnGap &&
            rowGap == other.rowGap;
  }

  @override
  int get hashCode => Object.hash(
    rows,
    columns,
    marginLeft,
    marginTop,
    marginRight,
    marginBottom,
    columnGap,
    rowGap,
  );

  bool get isDefault {
    return marginLeft == 0 &&
        marginTop == 0 &&
        marginRight == 0 &&
        marginBottom == 0 &&
        columnGap == 0 &&
        rowGap == 0;
  }

  int get totalFrameCount => rows * columns;

  SpriteSheetGridSpec copyWith({
    int? rows,
    int? columns,
    int? marginLeft,
    int? marginTop,
    int? marginRight,
    int? marginBottom,
    int? columnGap,
    int? rowGap,
  }) {
    return SpriteSheetGridSpec(
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      marginLeft: marginLeft ?? this.marginLeft,
      marginTop: marginTop ?? this.marginTop,
      marginRight: marginRight ?? this.marginRight,
      marginBottom: marginBottom ?? this.marginBottom,
      columnGap: columnGap ?? this.columnGap,
      rowGap: rowGap ?? this.rowGap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'columns': columns,
      'marginLeft': marginLeft,
      'marginTop': marginTop,
      'marginRight': marginRight,
      'marginBottom': marginBottom,
      'columnGap': columnGap,
      'rowGap': rowGap,
    };
  }

  int frameWidthForSheet(int sheetWidth) {
    if (columns <= 0) {
      return 0;
    }
    final availableWidth =
        sheetWidth - marginLeft - marginRight - columnGap * (columns - 1);
    return (availableWidth / columns).floor();
  }

  int frameHeightForSheet(int sheetHeight) {
    if (rows <= 0) {
      return 0;
    }
    final availableHeight =
        sheetHeight - marginTop - marginBottom - rowGap * (rows - 1);
    return (availableHeight / rows).floor();
  }

  Rect cellRectForSheet({
    required int sheetWidth,
    required int sheetHeight,
    required int row,
    required int column,
  }) {
    final frameWidth = frameWidthForSheet(sheetWidth);
    final frameHeight = frameHeightForSheet(sheetHeight);
    return Rect.fromLTWH(
      (marginLeft + column * (frameWidth + columnGap)).toDouble(),
      (marginTop + row * (frameHeight + rowGap)).toDouble(),
      frameWidth.toDouble(),
      frameHeight.toDouble(),
    );
  }

  void validateForSheet({
    int? sheetWidth,
    int? sheetHeight,
    String context = 'Sprite Sheet',
  }) {
    if (rows <= 0 || columns <= 0) {
      throw ImageGenerationException('$context 需要有效的行列数。');
    }
    if (marginLeft < 0 ||
        marginTop < 0 ||
        marginRight < 0 ||
        marginBottom < 0 ||
        columnGap < 0 ||
        rowGap < 0) {
      throw ImageGenerationException('$context 的边距和间距不能为负数。');
    }
    if (sheetWidth != null && frameWidthForSheet(sheetWidth) <= 0) {
      throw ImageGenerationException('$context 宽度不足，无法按当前网格切片。');
    }
    if (sheetHeight != null && frameHeightForSheet(sheetHeight) <= 0) {
      throw ImageGenerationException('$context 高度不足，无法按当前网格切片。');
    }
  }
}

int _readInt(Map<String, dynamic> json, String key, {int? defaultValue}) {
  final value = json[key];
  if (value == null && defaultValue != null) {
    return defaultValue;
  }
  if (value is int) {
    return value;
  }
  if (value is num && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw ImageGenerationException('Sprite Sheet 网格配置字段 $key 必须是整数。');
}
