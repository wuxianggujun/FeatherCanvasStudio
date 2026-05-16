import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/workspace_feature.dart';
import '../theme/layout_constants.dart';

class WorkspacePage extends StatelessWidget {
  const WorkspacePage({
    super.key,
    required this.title,
    required this.description,
    required this.children,
    this.controller,
    this.trailing,
    this.compactHeader = false,
  });

  final String title;
  final String description;
  final List<Widget> children;
  final ScrollController? controller;
  final Widget? trailing;
  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final headlineStyle = compactHeader
        ? theme.textTheme.titleLarge
        : theme.textTheme.headlineMedium;

    return SingleChildScrollView(
      controller: controller,
      padding: EdgeInsets.all(compactHeader ? 8 : workspacePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: headlineStyle)),
              if (trailing != null) ...[
                const SizedBox(width: fieldGap),
                trailing!,
              ],
            ],
          ),
          if (!compactHeader) ...[
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyLarge),
          ],
          SizedBox(height: compactHeader ? fieldGap : sectionGap),
          ...children,
        ],
      ),
    );
  }
}

class ResponsiveWorkspaceSplit extends StatefulWidget {
  const ResponsiveWorkspaceSplit({
    super.key,
    required this.controls,
    required this.preview,
    this.controlsWidth = 392,
    this.minControlsWidth = 304,
    this.maxControlsWidth = 520,
    this.resizable = true,
  });

  static const double _breakpoint = 900;

  final Widget controls;
  final Widget preview;
  final double controlsWidth;
  final double minControlsWidth;
  final double maxControlsWidth;
  final bool resizable;

  @override
  State<ResponsiveWorkspaceSplit> createState() =>
      _ResponsiveWorkspaceSplitState();
}

class _ResponsiveWorkspaceSplitState extends State<ResponsiveWorkspaceSplit> {
  static const double _minPreviewWidth = 360;

  double? _controlsWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < ResponsiveWorkspaceSplit._breakpoint) {
          return Column(
            children: [
              widget.controls,
              const SizedBox(height: layoutGap),
              widget.preview,
            ],
          );
        }

        final availableControlsWidth = math.max(
          widget.minControlsWidth,
          constraints.maxWidth - layoutGap - _minPreviewWidth,
        );
        final maxControlsWidth = math.min(
          widget.maxControlsWidth,
          availableControlsWidth,
        );
        final controlsWidth = (_controlsWidth ?? widget.controlsWidth)
            .clamp(widget.minControlsWidth, maxControlsWidth)
            .toDouble();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: controlsWidth, child: widget.controls),
            if (widget.resizable)
              _WorkspaceSplitHandle(
                onDragUpdate: (details) {
                  setState(() {
                    _controlsWidth = (controlsWidth + details.delta.dx)
                        .clamp(widget.minControlsWidth, maxControlsWidth)
                        .toDouble();
                  });
                },
              )
            else
              const SizedBox(width: layoutGap),
            Expanded(child: widget.preview),
          ],
        );
      },
    );
  }
}

class _WorkspaceSplitHandle extends StatelessWidget {
  const _WorkspaceSplitHandle({required this.onDragUpdate});

  final GestureDragUpdateCallback onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: onDragUpdate,
        child: SizedBox(
          width: layoutGap,
          child: Center(
            child: Container(
              width: 2,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.busyLabel,
    this.isBusy = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final String? busyLabel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: ButtonProgressIcon(isBusy: isBusy, icon: icon),
        label: Text(isBusy ? busyLabel ?? label : label),
      ),
    );
  }
}

class ButtonProgressIcon extends StatelessWidget {
  const ButtonProgressIcon({
    super.key,
    required this.isBusy,
    required this.icon,
  });

  final bool isBusy;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (!isBusy) {
      return Icon(icon);
    }

    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class FeatureNavigationRail extends StatelessWidget {
  const FeatureNavigationRail({
    super.key,
    required this.selectedFeature,
    required this.extended,
    required this.compact,
    required this.onFeatureSelected,
    required this.onOpenSettings,
    required this.onToggleCompact,
  });

  final WorkspaceFeature selectedFeature;
  final bool extended;
  final bool compact;
  final ValueChanged<WorkspaceFeature> onFeatureSelected;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleCompact;

  int? get _selectedDestinationIndex {
    return switch (selectedFeature) {
      WorkspaceFeature.imageGeneration => 0,
      WorkspaceFeature.batchGeneration => 1,
      WorkspaceFeature.frameAnimation => 2,
      WorkspaceFeature.imageEditor => 3,
      WorkspaceFeature.gifComposer => 4,
      WorkspaceFeature.imageLibrary => 5,
      WorkspaceFeature.apiSettings => null,
      WorkspaceFeature.localSettings => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final railExtended = extended && !compact;

    return NavigationRail(
      selectedIndex: _selectedDestinationIndex,
      extended: railExtended,
      minWidth: compact ? 56 : 80,
      minExtendedWidth: 168,
      labelType: railExtended || compact
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: IconButton(
          tooltip: compact ? '展开侧栏' : '收起侧栏',
          onPressed: onToggleCompact,
          icon: Icon(compact ? Icons.menu_open_outlined : Icons.menu_outlined),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.image_outlined),
          selectedIcon: Icon(Icons.image),
          label: Text('文本生图'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.auto_awesome_motion_outlined),
          selectedIcon: Icon(Icons.auto_awesome_motion),
          label: Text('批量生成'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.movie_creation_outlined),
          selectedIcon: Icon(Icons.movie_creation),
          label: Text('帧动画'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.grid_on_outlined),
          selectedIcon: Icon(Icons.grid_on),
          label: Text('图片编辑器'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.gif_box_outlined),
          selectedIcon: Icon(Icons.gif_box),
          label: Text('GIF 合成'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.collections_outlined),
          selectedIcon: Icon(Icons.collections),
          label: Text('作品库'),
        ),
      ],
      onDestinationSelected: (index) {
        final feature = switch (index) {
          0 => WorkspaceFeature.imageGeneration,
          1 => WorkspaceFeature.batchGeneration,
          2 => WorkspaceFeature.frameAnimation,
          3 => WorkspaceFeature.imageEditor,
          4 => WorkspaceFeature.gifComposer,
          _ => WorkspaceFeature.imageLibrary,
        };
        onFeatureSelected(feature);
      },
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: railExtended
                  ? 148
                  : compact
                  ? 56
                  : 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 20),
                  _NavigationRailAction(
                    extended: railExtended,
                    compact: compact,
                    selected: selectedFeature == WorkspaceFeature.apiSettings,
                    icon: Icons.tune_outlined,
                    selectedIcon: Icons.tune,
                    label: '接口配置',
                    onPressed: () =>
                        onFeatureSelected(WorkspaceFeature.apiSettings),
                  ),
                  const SizedBox(height: 2),
                  _NavigationRailAction(
                    extended: railExtended,
                    compact: compact,
                    selected: selectedFeature == WorkspaceFeature.localSettings,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: '设置',
                    onPressed: onOpenSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationRailAction extends StatelessWidget {
  const _NavigationRailAction({
    required this.extended,
    required this.compact,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onPressed,
  });

  final bool extended;
  final bool compact;
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;
    final background = selected
        ? colors.secondaryContainer
        : Colors.transparent;
    final currentIcon = selected ? selectedIcon : icon;

    if (extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(currentIcon, color: foreground),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (compact) {
      return Tooltip(
        message: label,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(currentIcon, color: foreground),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: SizedBox(
            width: 64,
            height: 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(currentIcon, color: foreground),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DesktopPickSourceTile extends StatelessWidget {
  const DesktopPickSourceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    final foreground = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Material(
      color: enabled
          ? theme.colorScheme.surfaceContainerLowest
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: enabled ? 0.72 : 1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
