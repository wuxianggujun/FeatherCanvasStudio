import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';

Future<int?> showBackgroundTransparencyDialog(
  BuildContext context, {
  String? sourceTitle,
  int initialTolerance = 28,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) {
      var tolerance = initialTolerance.clamp(0, 80).toInt();
      final l10n = appL10nOf(context);
      final theme = Theme.of(context);

      return StatefulBuilder(
        builder: (context, setState) {
          return FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: AlertDialog(
              title: Text(l10n.backgroundTransparencyTitle),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sourceTitle == null || sourceTitle.trim().isEmpty
                          ? l10n.backgroundTransparencyDescription
                          : l10n.backgroundTransparencyDescriptionForSource(
                              sourceTitle,
                            ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.backgroundTransparencyDetail,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: tolerance.toDouble(),
                            min: 0,
                            max: 80,
                            divisions: 80,
                            label: l10n.backgroundTransparencyTolerance(
                              tolerance,
                            ),
                            semanticFormatterCallback: (value) => l10n
                                .backgroundTransparencyTolerance(value.round()),
                            onChanged: (value) =>
                                setState(() => tolerance = value.round()),
                          ),
                        ),
                        SizedBox(
                          width: 74,
                          child: Text(
                            l10n.backgroundTransparencyTolerance(tolerance),
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancelAction),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(tolerance),
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: Text(l10n.backgroundTransparencyGenerate),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
