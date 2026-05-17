import 'package:flutter/foundation.dart';

import '../services/gif_composer_service.dart';
import '../utils/app_defaults.dart';

class GifComposerNotifier extends ChangeNotifier {
  List<GifSourceFrame> _frames = const [];
  int _defaultFrameDelayMs = defaultGifFrameDelayMs;
  int _loopCount = defaultGifLoopCount;
  GifPlaybackMode _playbackMode = defaultGifPlaybackMode;
  bool _isComposing = false;
  String? _outputPath;
  String? _errorMessage;

  List<GifSourceFrame> get frames => _frames;
  int get defaultFrameDelayMs => _defaultFrameDelayMs;
  int get loopCount => _loopCount;
  GifPlaybackMode get playbackMode => _playbackMode;
  bool get isComposing => _isComposing;
  String? get outputPath => _outputPath;
  String? get errorMessage => _errorMessage;

  set frames(List<GifSourceFrame> value) {
    if (identical(_frames, value)) return;
    _frames = value;
    notifyListeners();
  }

  set defaultFrameDelayMs(int value) {
    if (_defaultFrameDelayMs == value) return;
    _defaultFrameDelayMs = value;
    notifyListeners();
  }

  set loopCount(int value) {
    if (_loopCount == value) return;
    _loopCount = value;
    notifyListeners();
  }

  set playbackMode(GifPlaybackMode value) {
    if (_playbackMode == value) return;
    _playbackMode = value;
    notifyListeners();
  }

  set isComposing(bool value) {
    if (_isComposing == value) return;
    _isComposing = value;
    notifyListeners();
  }

  set outputPath(String? value) {
    if (_outputPath == value) return;
    _outputPath = value;
    notifyListeners();
  }

  set errorMessage(String? value) {
    if (_errorMessage == value) return;
    _errorMessage = value;
    notifyListeners();
  }
}
