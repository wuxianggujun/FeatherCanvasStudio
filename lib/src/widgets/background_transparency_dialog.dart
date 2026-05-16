import 'package:flutter/material.dart';

Future<int?> showBackgroundTransparencyDialog(
  BuildContext context, {
  String? sourceTitle,
  int initialTolerance = 28,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) {
      var tolerance = initialTolerance.clamp(0, 80).toInt();
      final theme = Theme.of(context);

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('背景转透明'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sourceTitle == null || sourceTitle.trim().isEmpty
                        ? '从图片边缘识别近似纯色背景，生成一张新的透明 PNG。'
                        : '处理「$sourceTitle」，生成一张新的透明 PNG。',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '只会移除和边缘连通的近似背景色，内部同色细节会保留。',
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
                          label: '容差 $tolerance',
                          onChanged: (value) =>
                              setState(() => tolerance = value.round()),
                        ),
                      ),
                      SizedBox(
                        width: 74,
                        child: Text(
                          '容差 $tolerance',
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
                child: const Text('取消'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(tolerance),
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('生成透明图'),
              ),
            ],
          );
        },
      );
    },
  );
}
