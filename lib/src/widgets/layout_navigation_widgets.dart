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
  });

  final String title;
  final String description;
  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.all(workspacePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: sectionGap),
          ...children,
        ],
      ),
    );
  }
}

class ResponsiveWorkspaceSplit extends StatelessWidget {
  const ResponsiveWorkspaceSplit({
    super.key,
    required this.controls,
    required this.preview,
  });

  static const double _controlsWidth = 392;
  static const double _breakpoint = 900;

  final Widget controls;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _breakpoint) {
          return Column(
            children: [
              controls,
              const SizedBox(height: layoutGap),
              preview,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: _controlsWidth, child: controls),
            const SizedBox(width: layoutGap),
            Expanded(child: preview),
          ],
        );
      },
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
    required this.onFeatureSelected,
    required this.onOpenSettings,
  });

  final WorkspaceFeature selectedFeature;
  final bool extended;
  final ValueChanged<WorkspaceFeature> onFeatureSelected;
  final VoidCallback onOpenSettings;

  int? get _selectedDestinationIndex {
    return switch (selectedFeature) {
      WorkspaceFeature.imageGeneration => 0,
      WorkspaceFeature.frameAnimation => 1,
      WorkspaceFeature.imageEditor => 2,
      WorkspaceFeature.gifComposer => 3,
      WorkspaceFeature.imageLibrary => 4,
      WorkspaceFeature.apiSettings => null,
      WorkspaceFeature.localSettings => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedDestinationIndex,
      extended: extended,
      minWidth: 92,
      minExtendedWidth: 208,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.image_outlined),
          selectedIcon: Icon(Icons.image),
          label: Text('文本生图'),
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
          1 => WorkspaceFeature.frameAnimation,
          2 => WorkspaceFeature.imageEditor,
          3 => WorkspaceFeature.gifComposer,
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
              width: extended ? 184 : 72,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 24),
                  _NavigationRailAction(
                    extended: extended,
                    selected: selectedFeature == WorkspaceFeature.apiSettings,
                    icon: Icons.tune_outlined,
                    selectedIcon: Icons.tune,
                    label: '接口配置',
                    onPressed: () =>
                        onFeatureSelected(WorkspaceFeature.apiSettings),
                  ),
                  const SizedBox(height: 4),
                  _NavigationRailAction(
                    extended: extended,
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
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onPressed,
  });

  final bool extended;
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  const SizedBox(width: 14),
                  Icon(currentIcon, color: foreground),
                  const SizedBox(width: 12),
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

    return Tooltip(
      message: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: SizedBox(
            width: 72,
            height: 56,
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
