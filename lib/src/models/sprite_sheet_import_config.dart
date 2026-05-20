import '../utils/app_defaults.dart';
import 'sprite_sheet_grid_spec.dart';

class SpriteSheetImportConfig {
  const SpriteSheetImportConfig({
    required this.rows,
    required this.columns,
    required this.gridSpec,
  });

  factory SpriteSheetImportConfig.defaults() {
    return const SpriteSheetImportConfig(
      rows: defaultAnimationRows,
      columns: defaultAnimationColumns,
      gridSpec: SpriteSheetGridSpec(
        rows: defaultAnimationRows,
        columns: defaultAnimationColumns,
      ),
    );
  }

  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;

  int get frameCount => rows * columns;

  SpriteSheetImportConfig withRows(int value) {
    return SpriteSheetImportConfig(
      rows: value,
      columns: columns,
      gridSpec: gridSpec.copyWith(rows: value),
    );
  }

  SpriteSheetImportConfig withColumns(int value) {
    return SpriteSheetImportConfig(
      rows: rows,
      columns: value,
      gridSpec: gridSpec.copyWith(columns: value),
    );
  }

  SpriteSheetImportConfig withGridSpec(SpriteSheetGridSpec value) {
    return SpriteSheetImportConfig(
      rows: value.rows,
      columns: value.columns,
      gridSpec: value,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SpriteSheetImportConfig &&
            rows == other.rows &&
            columns == other.columns &&
            gridSpec == other.gridSpec;
  }

  @override
  int get hashCode => Object.hash(rows, columns, gridSpec);
}
