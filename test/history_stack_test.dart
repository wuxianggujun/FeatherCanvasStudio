import 'package:feather_canvas_studio/src/history/history_action.dart';
import 'package:feather_canvas_studio/src/history/history_stack.dart';
import 'package:flutter_test/flutter_test.dart';

HistoryAction _noopAction({String label = 'test', int bytes = 0}) {
  return HistoryAction(
    label: label,
    estimatedBytes: bytes,
    apply: () {},
    revert: () {},
  );
}

void main() {
  group('HistoryStack', () {
    test('starts empty', () {
      final stack = HistoryStack();
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
    });

    test('push enables undo and disables redo', () {
      final stack = HistoryStack();
      stack.push(_noopAction(label: 'a'));
      expect(stack.canUndo, isTrue);
      expect(stack.canRedo, isFalse);
      expect(stack.topUndo?.label, 'a');
    });

    test('popUndo moves action to redo stack', () {
      final stack = HistoryStack();
      stack.push(_noopAction(label: 'a'));
      final action = stack.popUndo();
      expect(action?.label, 'a');
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isTrue);
      expect(stack.topRedo?.label, 'a');
    });

    test('popRedo moves action back to undo stack', () {
      final stack = HistoryStack();
      stack.push(_noopAction(label: 'a'));
      stack.popUndo();
      final action = stack.popRedo();
      expect(action?.label, 'a');
      expect(stack.canUndo, isTrue);
      expect(stack.canRedo, isFalse);
    });

    test('recent actions are exposed newest first with a limit', () {
      final stack = HistoryStack();
      stack.push(_noopAction(label: 'a'));
      stack.push(_noopAction(label: 'b'));
      stack.push(_noopAction(label: 'c'));

      expect(stack.recentUndoActions(limit: 2).map((action) => action.label), [
        'c',
        'b',
      ]);

      stack.popUndo();
      stack.popUndo();

      expect(stack.recentRedoActions(limit: 2).map((action) => action.label), [
        'b',
        'c',
      ]);
    });

    test('push clears redo stack', () {
      final stack = HistoryStack();
      stack.push(_noopAction(label: 'a'));
      stack.popUndo();
      expect(stack.canRedo, isTrue);
      stack.push(_noopAction(label: 'b'));
      expect(stack.canRedo, isFalse);
      expect(stack.topUndo?.label, 'b');
    });

    test('replaceTopUndo replaces only the expected top action', () {
      final stack = HistoryStack();
      final first = _noopAction(label: 'a');
      final second = _noopAction(label: 'b');
      final replacement = _noopAction(label: 'c');
      stack.push(first);
      stack.push(second);

      final replacedWrongAction = stack.replaceTopUndo(
        current: first,
        replacement: replacement,
      );
      expect(replacedWrongAction, isFalse);
      expect(stack.topUndo?.label, 'b');

      final replacedTopAction = stack.replaceTopUndo(
        current: second,
        replacement: replacement,
      );
      expect(replacedTopAction, isTrue);
      expect(stack.undoLength, 2);
      expect(stack.topUndo?.label, 'c');
    });

    test('replaceTopUndo keeps byte budget accounting correct', () {
      final stack = HistoryStack(maxEntries: 100, maxBytes: 100);
      final original = _noopAction(label: 'a', bytes: 60);
      final smaller = _noopAction(label: 'b', bytes: 10);
      stack.push(original);

      final replaced = stack.replaceTopUndo(
        current: original,
        replacement: smaller,
      );
      stack.push(_noopAction(label: 'c', bytes: 60));

      expect(replaced, isTrue);
      expect(stack.undoLength, 2);
      expect(stack.topUndo?.label, 'c');
    });

    test('replaceTopUndo does not replace while redo stack is active', () {
      final stack = HistoryStack();
      final first = _noopAction(label: 'a');
      final second = _noopAction(label: 'b');
      final replacement = _noopAction(label: 'c');
      stack.push(first);
      stack.push(second);
      stack.popUndo();

      final replaced = stack.replaceTopUndo(
        current: first,
        replacement: replacement,
      );

      expect(replaced, isFalse);
      expect(stack.canRedo, isTrue);
      expect(stack.canUndo, isTrue);
      expect(stack.topUndo?.label, 'a');
    });

    test('enforces maxEntries with FIFO eviction', () {
      final stack = HistoryStack(maxEntries: 3);
      stack.push(_noopAction(label: 'a'));
      stack.push(_noopAction(label: 'b'));
      stack.push(_noopAction(label: 'c'));
      stack.push(_noopAction(label: 'd'));
      expect(stack.undoLength, 3);
      // Oldest action 'a' should be evicted; 'b' is now the oldest.
      stack.popUndo(); // d -> redo
      stack.popUndo(); // c -> redo
      final last = stack.popUndo();
      expect(last?.label, 'b');
      expect(stack.canUndo, isFalse);
    });

    test('enforces maxBytes by evicting oldest', () {
      final stack = HistoryStack(maxEntries: 100, maxBytes: 100);
      stack.push(_noopAction(label: 'big-1', bytes: 60));
      stack.push(_noopAction(label: 'big-2', bytes: 60));
      // After pushing big-2 the total is 120 > 100 — big-1 must be evicted.
      expect(stack.undoLength, 1);
      expect(stack.topUndo?.label, 'big-2');
    });

    test('clear removes all actions', () {
      final stack = HistoryStack();
      stack.push(_noopAction(label: 'a'));
      stack.push(_noopAction(label: 'b'));
      stack.popUndo();
      stack.clear();
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
    });

    test('notifies listeners on push/pop/clear', () {
      final stack = HistoryStack();
      var notifications = 0;
      stack.addListener(() => notifications++);

      stack.push(_noopAction(label: 'a'));
      expect(notifications, 1);

      stack.popUndo();
      expect(notifications, 2);

      stack.popRedo();
      expect(notifications, 3);

      stack.clear();
      expect(notifications, 4);
    });

    test('clear on already-empty stack does not notify', () {
      final stack = HistoryStack();
      var notifications = 0;
      stack.addListener(() => notifications++);

      stack.clear();
      expect(notifications, 0);
    });

    test('popUndo on empty stack returns null', () {
      final stack = HistoryStack();
      expect(stack.popUndo(), isNull);
      expect(stack.popRedo(), isNull);
    });
  });
}
