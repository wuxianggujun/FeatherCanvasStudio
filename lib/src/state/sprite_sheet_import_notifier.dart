import 'package:flutter/foundation.dart';

import '../models/sprite_sheet_import_config.dart';
import '../models/sprite_sheet_grid_spec.dart';

class SpriteSheetImportNotifier extends ChangeNotifier {
  SpriteSheetImportConfig _config = SpriteSheetImportConfig.defaults();

  SpriteSheetImportConfig get config => _config;
  int get rows => _config.rows;
  int get columns => _config.columns;
  SpriteSheetGridSpec get gridSpec => _config.gridSpec;

  set config(SpriteSheetImportConfig value) {
    if (_config == value) return;
    _config = value;
    notifyListeners();
  }

  set rows(int value) => config = _config.withRows(value);
  set columns(int value) => config = _config.withColumns(value);
  set gridSpec(SpriteSheetGridSpec value) =>
      config = _config.withGridSpec(value);
}
