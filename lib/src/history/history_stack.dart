import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'history_action.dart';

class HistoryStack extends ChangeNotifier {
  HistoryStack({this.maxEntries = 50, this.maxBytes})
    : assert(maxEntries > 0),
      assert(maxBytes == null || maxBytes > 0);

  final int maxEntries;
  final int? maxBytes;

  final Queue<HistoryAction> _undo = Queue<HistoryAction>();
  final Queue<HistoryAction> _redo = Queue<HistoryAction>();
  int _undoBytes = 0;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get undoLength => _undo.length;
  int get redoLength => _redo.length;

  HistoryAction? get topUndo => _undo.isEmpty ? null : _undo.last;
  HistoryAction? get topRedo => _redo.isEmpty ? null : _redo.last;

  List<HistoryAction> recentUndoActions({int limit = 8}) {
    return List<HistoryAction>.unmodifiable(
      _undo.toList().reversed.take(limit),
    );
  }

  List<HistoryAction> recentRedoActions({int limit = 8}) {
    return List<HistoryAction>.unmodifiable(
      _redo.toList().reversed.take(limit),
    );
  }

  void push(HistoryAction action) {
    _undo.addLast(action);
    _undoBytes += action.estimatedBytes;
    _discardRedo();
    _enforceCapacity();
    notifyListeners();
  }

  bool replaceTopUndo({
    required HistoryAction current,
    required HistoryAction replacement,
  }) {
    if (_undo.isEmpty || _redo.isNotEmpty || !identical(_undo.last, current)) {
      return false;
    }

    final removed = _undo.removeLast();
    _undoBytes -= removed.estimatedBytes;
    _undo.addLast(replacement);
    _undoBytes += replacement.estimatedBytes;
    _enforceCapacity();
    notifyListeners();
    return true;
  }

  HistoryAction? popUndo() {
    if (_undo.isEmpty) return null;
    final action = _undo.removeLast();
    _undoBytes -= action.estimatedBytes;
    _redo.addLast(action);
    notifyListeners();
    return action;
  }

  HistoryAction? popRedo() {
    if (_redo.isEmpty) return null;
    final action = _redo.removeLast();
    _undo.addLast(action);
    _undoBytes += action.estimatedBytes;
    _enforceCapacity();
    notifyListeners();
    return action;
  }

  void clear() {
    if (_undo.isEmpty && _redo.isEmpty) return;
    _undo.clear();
    _redo.clear();
    _undoBytes = 0;
    notifyListeners();
  }

  void _discardRedo() {
    if (_redo.isEmpty) return;
    _redo.clear();
  }

  void _enforceCapacity() {
    while (_undo.length > maxEntries) {
      final dropped = _undo.removeFirst();
      _undoBytes -= dropped.estimatedBytes;
    }
    final budget = maxBytes;
    if (budget != null) {
      while (_undoBytes > budget && _undo.length > 1) {
        final dropped = _undo.removeFirst();
        _undoBytes -= dropped.estimatedBytes;
      }
    }
    if (_undoBytes < 0) _undoBytes = 0;
  }
}
