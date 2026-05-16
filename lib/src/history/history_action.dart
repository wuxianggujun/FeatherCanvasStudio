import 'dart:async';

class HistoryAction {
  HistoryAction({
    required this.label,
    required this.apply,
    required this.revert,
    this.estimatedBytes = 0,
  });

  final String label;
  final int estimatedBytes;
  final FutureOr<void> Function() apply;
  final FutureOr<void> Function() revert;
}
