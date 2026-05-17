import 'package:flutter/foundation.dart';

import '../models/sprite_sheet_frame_fit.dart';
import '../models/sprite_sheet_grid_spec.dart';
import '../services/general_image_editing_service.dart';
import '../utils/app_defaults.dart';

class ImageEditorNotifier extends ChangeNotifier {
  int _editorRows = defaultEditorRows;
  int _editorColumns = defaultEditorColumns;
  SpriteSheetGridSpec _editorGridSpec = const SpriteSheetGridSpec(
    rows: defaultEditorRows,
    columns: defaultEditorColumns,
  );
  int _editorTargetFrameIndex = defaultEditorTargetFrameIndex;
  SpriteSheetFrameFit _editorFrameFit = defaultEditorFrameFit;
  String? _editorImagePath;
  String? _editorPatchImagePath;
  String? _editorErrorMessage;
  bool _isReplacingEditorFrame = false;

  String? _generalEditorImagePath;
  ImageInspectionResult? _generalEditorImageInfo;
  String? _generalEditorErrorMessage;
  bool _isProcessingGeneralImage = false;

  int get editorRows => _editorRows;
  int get editorColumns => _editorColumns;
  SpriteSheetGridSpec get editorGridSpec => _editorGridSpec;
  int get editorTargetFrameIndex => _editorTargetFrameIndex;
  SpriteSheetFrameFit get editorFrameFit => _editorFrameFit;
  String? get editorImagePath => _editorImagePath;
  String? get editorPatchImagePath => _editorPatchImagePath;
  String? get editorErrorMessage => _editorErrorMessage;
  bool get isReplacingEditorFrame => _isReplacingEditorFrame;

  String? get generalEditorImagePath => _generalEditorImagePath;
  ImageInspectionResult? get generalEditorImageInfo => _generalEditorImageInfo;
  String? get generalEditorErrorMessage => _generalEditorErrorMessage;
  bool get isProcessingGeneralImage => _isProcessingGeneralImage;

  set editorRows(int value) {
    if (_editorRows == value) return;
    _editorRows = value;
    notifyListeners();
  }

  set editorColumns(int value) {
    if (_editorColumns == value) return;
    _editorColumns = value;
    notifyListeners();
  }

  set editorGridSpec(SpriteSheetGridSpec value) {
    if (_editorGridSpec == value) return;
    _editorGridSpec = value;
    notifyListeners();
  }

  set editorTargetFrameIndex(int value) {
    if (_editorTargetFrameIndex == value) return;
    _editorTargetFrameIndex = value;
    notifyListeners();
  }

  set editorFrameFit(SpriteSheetFrameFit value) {
    if (_editorFrameFit == value) return;
    _editorFrameFit = value;
    notifyListeners();
  }

  set editorImagePath(String? value) {
    if (_editorImagePath == value) return;
    _editorImagePath = value;
    notifyListeners();
  }

  set editorPatchImagePath(String? value) {
    if (_editorPatchImagePath == value) return;
    _editorPatchImagePath = value;
    notifyListeners();
  }

  set editorErrorMessage(String? value) {
    if (_editorErrorMessage == value) return;
    _editorErrorMessage = value;
    notifyListeners();
  }

  set isReplacingEditorFrame(bool value) {
    if (_isReplacingEditorFrame == value) return;
    _isReplacingEditorFrame = value;
    notifyListeners();
  }

  set generalEditorImagePath(String? value) {
    if (_generalEditorImagePath == value) return;
    _generalEditorImagePath = value;
    notifyListeners();
  }

  set generalEditorImageInfo(ImageInspectionResult? value) {
    if (identical(_generalEditorImageInfo, value)) return;
    _generalEditorImageInfo = value;
    notifyListeners();
  }

  set generalEditorErrorMessage(String? value) {
    if (_generalEditorErrorMessage == value) return;
    _generalEditorErrorMessage = value;
    notifyListeners();
  }

  set isProcessingGeneralImage(bool value) {
    if (_isProcessingGeneralImage == value) return;
    _isProcessingGeneralImage = value;
    notifyListeners();
  }
}
