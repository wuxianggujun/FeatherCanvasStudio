import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';
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

    final padding = EdgeInsets.all(compactHeader ? 8 : workspacePadding);

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final trailing = this.trailing;
            if (trailing != null &&
                constraints.maxWidth < AppBreakpoints.compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: headlineStyle),
                  const SizedBox(height: fieldGap),
                  Align(alignment: Alignment.centerLeft, child: trailing),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: Text(title, style: headlineStyle)),
                if (trailing != null) ...[
                  const SizedBox(width: fieldGap),
                  trailing,
                ],
              ],
            );
          },
        ),
        if (!compactHeader) ...[
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyLarge),
        ],
      ],
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(height: compactHeader ? fieldGap : sectionGap),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
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
    this.storageKey,
  });

  static const double _breakpoint = AppBreakpoints.medium;

  final Widget controls;
  final Widget preview;
  final double controlsWidth;
  final double minControlsWidth;
  final double maxControlsWidth;
  final bool resizable;
  final String? storageKey;

  @override
  State<ResponsiveWorkspaceSplit> createState() =>
      _ResponsiveWorkspaceSplitState();
}

class _ResponsiveWorkspaceSplitState extends State<ResponsiveWorkspaceSplit> {
  static const double _minPreviewWidth = 360;
  static const String _prefsPrefix = 'workspaceSplit.controlsWidth.';

  double? _controlsWidth;

  @override
  void initState() {
    super.initState();
    _restoreWidth();
  }

  Future<void> _restoreWidth() async {
    final key = widget.storageKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble('$_prefsPrefix$key');
    if (saved != null && mounted) {
      setState(() => _controlsWidth = saved);
    }
  }

  Future<void> _persistWidth(double width) async {
    final key = widget.storageKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_prefsPrefix$key', width);
  }

  void _resetWidth() {
    setState(() => _controlsWidth = widget.controlsWidth);
    final key = widget.storageKey;
    if (key != null) {
      SharedPreferences.getInstance().then(
        (prefs) => prefs.remove('$_prefsPrefix$key'),
      );
    }
  }

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
                onDragEnd: () {
                  final w = _controlsWidth;
                  if (w != null) _persistWidth(w);
                },
                onDoubleTap: _resetWidth,
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
  const _WorkspaceSplitHandle({
    required this.onDragUpdate,
    this.onDragEnd,
    this.onDoubleTap,
  });

  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: onDragUpdate,
        onHorizontalDragEnd: onDragEnd == null
            ? null
            : (_) => onDragEnd!(),
        onDoubleTap: onDoubleTap,
        child: Tooltip(
          message: '拖动调整宽度，双击复位',
          waitDuration: const Duration(milliseconds: 600),
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
      WorkspaceFeature.animationProject => 2,
      WorkspaceFeature.imageEditor => 3,
      WorkspaceFeature.pixelArtEditor => 4,
      WorkspaceFeature.gifComposer => 5,
      WorkspaceFeature.imageLibrary => 6,
      WorkspaceFeature.apiSettings => null,
      WorkspaceFeature.localSettings => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final railExtended = extended && !compact;
    final l10n = AppLocalizations.of(context);

    return NavigationRail(
      selectedIndex: _selectedDestinationIndex,
      extended: railExtended,
      minWidth: compact ? 56 : 80,
      minExtendedWidth: 168,
      labelType: railExtended || compact
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.image_outlined),
          selectedIcon: const Icon(Icons.image),
          label: Text(l10n.navImageGeneration),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.auto_awesome_motion_outlined),
          selectedIcon: const Icon(Icons.auto_awesome_motion),
          label: Text(l10n.navBatchGeneration),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.movie_creation_outlined),
          selectedIcon: const Icon(Icons.movie_creation),
          label: Text(l10n.navAnimationProject),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.grid_on_outlined),
          selectedIcon: const Icon(Icons.grid_on),
          label: Text(l10n.navImageEditor),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.brush_outlined),
          selectedIcon: const Icon(Icons.brush),
          label: Text(l10n.navPixelArtEditor),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.gif_box_outlined),
          selectedIcon: const Icon(Icons.gif_box),
          label: Text(l10n.navGifComposer),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.collections_outlined),
          selectedIcon: const Icon(Icons.collections),
          label: Text(l10n.navImageLibrary),
        ),
      ],
      onDestinationSelected: (index) {
        final feature = switch (index) {
          0 => WorkspaceFeature.imageGeneration,
          1 => WorkspaceFeature.batchGeneration,
          2 => WorkspaceFeature.animationProject,
          3 => WorkspaceFeature.imageEditor,
          4 => WorkspaceFeature.pixelArtEditor,
          5 => WorkspaceFeature.gifComposer,
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
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(height: 20),
                          _NavigationRailAction(
                            extended: railExtended,
                            compact: compact,
                            selected:
                                selectedFeature == WorkspaceFeature.apiSettings,
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
                            selected:
                                selectedFeature ==
                                WorkspaceFeature.localSettings,
                            icon: Icons.settings_outlined,
                            selectedIcon: Icons.settings,
                            label: '设置',
                            onPressed: onOpenSettings,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 20),
                  _NavigationRailAction(
                    extended: railExtended,
                    compact: compact,
                    selected: false,
                    icon: compact
                        ? Icons.menu_open_outlined
                        : Icons.menu_outlined,
                    selectedIcon: compact
                        ? Icons.menu_open_outlined
                        : Icons.menu_outlined,
                    label: compact ? '展开侧栏' : '收起侧栏',
                    onPressed: onToggleCompact,
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
