import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../history/history_intents.dart';

class AppShortcuts {
  const AppShortcuts._();

  static const Map<ShortcutActivator, Intent> global =
      <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true): UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, meta: true): RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            RedoIntent(),
      };
}

enum AppShortcutId { undo, redo, redoAlt }

class AppShortcutEntry {
  const AppShortcutEntry({required this.id, required this.keys});

  final AppShortcutId id;
  final List<String> keys;
}

const List<AppShortcutEntry> appShortcutCheatSheet = <AppShortcutEntry>[
  AppShortcutEntry(id: AppShortcutId.undo, keys: ['Ctrl', 'Z']),
  AppShortcutEntry(id: AppShortcutId.redo, keys: ['Ctrl', 'Y']),
  AppShortcutEntry(id: AppShortcutId.redoAlt, keys: ['Ctrl', 'Shift', 'Z']),
];
