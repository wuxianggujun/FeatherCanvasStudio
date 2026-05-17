import 'package:flutter/foundation.dart';

import '../models/generated_image.dart';
import '../services/image_api_client.dart';

class ImageGenerationNotifier extends ChangeNotifier {
  List<GeneratedImage> _generatedImages = const [];
  bool _isGenerating = false;
  String? _errorMessage;
  ImageRequestDebugRecord? _debugRecord;

  List<GeneratedImage> get generatedImages => _generatedImages;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  ImageRequestDebugRecord? get debugRecord => _debugRecord;

  set generatedImages(List<GeneratedImage> value) {
    if (identical(_generatedImages, value)) return;
    _generatedImages = value;
    notifyListeners();
  }

  set isGenerating(bool value) {
    if (_isGenerating == value) return;
    _isGenerating = value;
    notifyListeners();
  }

  set errorMessage(String? value) {
    if (_errorMessage == value) return;
    _errorMessage = value;
    notifyListeners();
  }

  set debugRecord(ImageRequestDebugRecord? value) {
    if (_debugRecord == value) return;
    _debugRecord = value;
    notifyListeners();
  }
}
