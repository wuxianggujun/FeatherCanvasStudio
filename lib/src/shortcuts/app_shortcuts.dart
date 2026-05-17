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

class AppShortcutEntry {
  const AppShortcutEntry({required this.label, required this.keys});

  final String label;
  final List<String> keys;
}

const List<AppShortcutEntry> appShortcutCheatSheet = <AppShortcutEntry>[
  AppShortcutEntry(label: '撤销', keys: ['Ctrl', 'Z']),
  AppShortcutEntry(label: '重做', keys: ['Ctrl', 'Y']),
  AppShortcutEntry(label: '重做（备选）', keys: ['Ctrl', 'Shift', 'Z']),
];
