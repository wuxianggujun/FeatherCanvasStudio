// ignore_for_file: annotate_overrides

part of 'package:feather_canvas_studio/main.dart';

const int _historyDefaultMaxEntries = 50;
const int _historyGifByteBudget = 64 * 1024 * 1024;

mixin _HistoryStateMixin
    on
        State<FeatherCanvasHomePage>,
        _ApiConfigStateMixin,
        _LocalSettingsStateMixin,
        _ImageLibraryStateMixin,
        _EditorGifStateMixin {
  WorkspaceFeature get _selectedFeature;
  void _showMessage(String message);

  final Map<WorkspaceFeature, HistoryStack> _historyStacks =
      <WorkspaceFeature, HistoryStack>{};
  bool _isApplyingHistory = false;

  HistoryStack _historyStackFor(WorkspaceFeature feature) {
    return _historyStacks.putIfAbsent(feature, () {
      if (feature == WorkspaceFeature.gifComposer) {
        return HistoryStack(
          maxEntries: _historyDefaultMaxEntries,
          maxBytes: _historyGifByteBudget,
        );
      }
      return HistoryStack(maxEntries: _historyDefaultMaxEntries);
    });
  }

  HistoryStack? _peekHistoryStack(WorkspaceFeature feature) =>
      _historyStacks[feature];

  void _pushHistory(WorkspaceFeature feature, HistoryAction action) {
    final hadStack = _historyStacks.containsKey(feature);
    _historyStackFor(feature).push(action);
    if (!hadStack && mounted) {
      setState(() {});
    }
  }

  bool _replaceTopHistory(
    WorkspaceFeature feature, {
    required HistoryAction current,
    required HistoryAction replacement,
  }) {
    final stack = _historyStacks[feature];
    if (stack == null) {
      return false;
    }
    return stack.replaceTopUndo(current: current, replacement: replacement);
  }

  Future<void> _undoCurrentWorkspace({int steps = 1}) async {
    if (_isApplyingHistory || steps <= 0) {
      return;
    }

    var completed = 0;
    String? lastLabel;
    setState(() => _isApplyingHistory = true);
    try {
      for (var index = 0; index < steps; index++) {
        final stack = _historyStacks[_selectedFeature];
        if (stack == null || !stack.canUndo) break;
        final action = stack.topUndo;
        if (action == null) break;
        await action.revert();
        stack.popUndo();
        completed++;
        lastLabel = action.label;
      }
      if (completed == 1 && lastLabel != null) {
        _showMessage('已撤销：$lastLabel');
      } else if (completed > 1 && lastLabel != null) {
        _showMessage('已撤销 $completed 步：$lastLabel');
      }
    } catch (error) {
      _showMessage('撤销失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isApplyingHistory = false);
      }
    }
  }

  Future<void> _redoCurrentWorkspace({int steps = 1}) async {
    if (_isApplyingHistory || steps <= 0) {
      return;
    }

    var completed = 0;
    String? lastLabel;
    setState(() => _isApplyingHistory = true);
    try {
      for (var index = 0; index < steps; index++) {
        final stack = _historyStacks[_selectedFeature];
        if (stack == null || !stack.canRedo) break;
        final action = stack.topRedo;
        if (action == null) break;
        await action.apply();
        stack.popRedo();
        completed++;
        lastLabel = action.label;
      }
      if (completed == 1 && lastLabel != null) {
        _showMessage('已重做：$lastLabel');
      } else if (completed > 1 && lastLabel != null) {
        _showMessage('已重做 $completed 步：$lastLabel');
      }
    } catch (error) {
      _showMessage('重做失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isApplyingHistory = false);
      }
    }
  }

  void _disposeHistoryState() {
    for (final stack in _historyStacks.values) {
      stack.dispose();
    }
    _historyStacks.clear();
  }
}
