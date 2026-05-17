import 'package:flutter/foundation.dart';

import '../models/batch_generation_job.dart';
import '../utils/generation_limits.dart';

class BatchGenerationNotifier extends ChangeNotifier {
  List<BatchGenerationJob> _jobs = const [];
  int _targetCount = defaultBatchGenerationTargetCount;
  int _requestCount = defaultBatchGenerationRequestCount;
  bool _isRunning = false;
  bool _pauseAfterCurrent = false;

  List<BatchGenerationJob> get jobs => _jobs;
  int get targetCount => _targetCount;
  int get requestCount => _requestCount;
  bool get isRunning => _isRunning;
  bool get pauseAfterCurrent => _pauseAfterCurrent;

  set jobs(List<BatchGenerationJob> value) {
    if (identical(_jobs, value)) return;
    _jobs = value;
    notifyListeners();
  }

  set targetCount(int value) {
    if (_targetCount == value) return;
    _targetCount = value;
    notifyListeners();
  }

  set requestCount(int value) {
    if (_requestCount == value) return;
    _requestCount = value;
    notifyListeners();
  }

  set isRunning(bool value) {
    if (_isRunning == value) return;
    _isRunning = value;
    notifyListeners();
  }

  set pauseAfterCurrent(bool value) {
    if (_pauseAfterCurrent == value) return;
    _pauseAfterCurrent = value;
    notifyListeners();
  }
}
