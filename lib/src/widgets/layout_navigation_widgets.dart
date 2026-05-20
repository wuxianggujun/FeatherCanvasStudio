import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/workspace_feature.dart';
import '../theme/layout_constants.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({
    super.key,
    required this.title,
    required this.description,
    required this.children,
    this.controller,
    this.trailing,
    this.compactHeader = false,
    this.scrollable = true,
  });

  final String title;
  final String description;
  final List<Widget> children;
  final ScrollController? controller;
  final Widget? trailing;
  final bool compactHeader;
  final bool scrollable;

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  ScrollController? _ownedController;

  ScrollController get _effectiveController =>
      widget.controller ?? (_ownedController ??= ScrollController());

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final headlineStyle = widget.compactHeader
        ? theme.textTheme.titleLarge
        : theme.textTheme.headlineMedium;

    final padding = EdgeInsets.all(widget.compactHeader ? 8 : workspacePadding);

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final trailing = widget.trailing;
            if (trailing != null &&
                constraints.maxWidth < AppBreakpoints.compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: headlineStyle),
                  const SizedBox(height: fieldGap),
                  Align(alignment: Alignment.centerLeft, child: trailing),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: Text(widget.title, style: headlineStyle)),
                if (trailing != null) ...[
                  const SizedBox(width: fieldGap),
                  trailing,
                ],
              ],
            );
          },
        ),
        if (!widget.compactHeader) ...[
          const SizedBox(height: 8),
          Text(widget.description, style: theme.textTheme.bodyLarge),
        ],
      ],
    );

    final controller = _effectiveController;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.children,
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(height: widget.compactHeader ? fieldGap : sectionGap),
          Expanded(
            child: widget.scrollable
                ? Scrollbar(
                    controller: controller,
                    child: SingleChildScrollView(
                      controller: controller,
                      child: content,
                    ),
                  )
                : content,
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
              WorkspaceResizeHandle(
                axis: Axis.vertical,
                tooltip: _splitHandleTooltip(context),
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

String _splitHandleTooltip(BuildContext context) {
  return Localizations.of<AppLocalizations>(
        context,
        AppLocalizations,
      )?.splitHandleTooltip ??
      lookupAppLocalizations(const Locale('zh')).splitHandleTooltip;
}

class WorkspaceResizeHandle extends StatelessWidget {
  const WorkspaceResizeHandle({
    super.key,
    required this.axis,
    required this.tooltip,
    required this.onDragUpdate,
    this.onDragEnd,
    this.onDoubleTap,
  });

  final Axis axis;
  final String tooltip;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDoubleTap;
  static const double _hitExtent = 20;
  static const double _fallbackExtent = 128;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVertical = axis == Axis.vertical;
    final handleColor = theme.colorScheme.outlineVariant;
    final hoverColor = theme.colorScheme.primary.withValues(alpha: 0.18);
    final cursor = isVertical
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;

    return LayoutBuilder(
      builder: (context, constraints) {
        final handleWidth = isVertical ? _hitExtent : double.infinity;
        final handleHeight = isVertical
            ? (constraints.hasBoundedHeight ? double.infinity : _fallbackExtent)
            : _hitExtent;

        return MouseRegion(
          cursor: cursor,
          child: Semantics(
            label: tooltip,
            button: true,
            enabled: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: isVertical ? onDragUpdate : null,
              onHorizontalDragEnd: isVertical && onDragEnd != null
                  ? (_) => onDragEnd!()
                  : null,
              onVerticalDragUpdate: isVertical ? null : onDragUpdate,
              onVerticalDragEnd: !isVertical && onDragEnd != null
                  ? (_) => onDragEnd!()
                  : null,
              onDoubleTap: onDoubleTap,
              child: Tooltip(
                message: tooltip,
                waitDuration: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: handleWidth,
                  height: handleHeight,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: hoverColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: SizedBox(
                        width: isVertical ? 6 : 72,
                        height: isVertical ? 72 : 6,
                        child: Center(
                          child: Container(
                            width: isVertical ? 2 : 52,
                            height: isVertical ? 52 : 2,
                            decoration: BoxDecoration(
                              color: handleColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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

  static String _featureLabel(AppLocalizations l10n, WorkspaceFeature feature) {
    return switch (feature) {
      WorkspaceFeature.imageGeneration => l10n.navImageGeneration,
      WorkspaceFeature.batchGeneration => l10n.navBatchGeneration,
      WorkspaceFeature.animationProject => l10n.navAnimationProject,
      WorkspaceFeature.imageEditor => l10n.navImageEditor,
      WorkspaceFeature.pixelArtEditor => l10n.navPixelArtEditor,
      WorkspaceFeature.imageLibrary => l10n.navImageLibrary,
      WorkspaceFeature.apiSettings => l10n.navApiSettings,
      WorkspaceFeature.localSettings => l10n.navLocalSettings,
    };
  }

  static (IconData, IconData) _featureIcons(WorkspaceFeature feature) {
    return switch (feature) {
      WorkspaceFeature.imageGeneration => (Icons.image_outlined, Icons.image),
      WorkspaceFeature.batchGeneration => (
        Icons.auto_awesome_motion_outlined,
        Icons.auto_awesome_motion,
      ),
      WorkspaceFeature.animationProject => (
        Icons.movie_creation_outlined,
        Icons.movie_creation,
      ),
      WorkspaceFeature.imageEditor => (Icons.grid_on_outlined, Icons.grid_on),
      WorkspaceFeature.pixelArtEditor => (Icons.brush_outlined, Icons.brush),
      WorkspaceFeature.imageLibrary => (
        Icons.collections_outlined,
        Icons.collections,
      ),
      WorkspaceFeature.apiSettings => (Icons.tune_outlined, Icons.tune),
      WorkspaceFeature.localSettings => (
        Icons.settings_outlined,
        Icons.settings,
      ),
    };
  }

  static String _categoryLabel(
    AppLocalizations l10n,
    WorkspaceCategory category,
  ) {
    return switch (category) {
      WorkspaceCategory.generate => l10n.navGroupGenerate,
      WorkspaceCategory.edit => l10n.navGroupEdit,
      WorkspaceCategory.assets => l10n.navGroupAssets,
      WorkspaceCategory.settings => l10n.navSettingsMenu,
    };
  }

  @override
  Widget build(BuildContext context) {
    final railExtended = extended && !compact;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final railWidth = railExtended ? 168.0 : (compact ? 56.0 : 80.0);

    return Material(
      color: theme.colorScheme.surface,
      child: SizedBox(
        width: railWidth,
        child: SafeArea(
          right: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (
                        var i = 0;
                        i < primaryWorkspaceCategories.length;
                        i++
                      ) ...[
                        _NavigationGroupHeader(
                          label: _categoryLabel(
                            l10n,
                            primaryWorkspaceCategories[i],
                          ),
                          extended: railExtended,
                          compact: compact,
                          showLeadingDivider: i > 0,
                        ),
                        for (final feature
                            in workspaceCategoryFeatures[primaryWorkspaceCategories[i]]!) ...[
                          _NavigationRailAction(
                            extended: railExtended,
                            compact: compact,
                            selected: selectedFeature == feature,
                            icon: _featureIcons(feature).$1,
                            selectedIcon: _featureIcons(feature).$2,
                            label: _featureLabel(l10n, feature),
                            onPressed: () => onFeatureSelected(feature),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),
              _SettingsMenuButton(
                extended: railExtended,
                compact: compact,
                selectedFeature: selectedFeature,
                l10n: l10n,
                onFeatureSelected: onFeatureSelected,
              ),
              const SizedBox(height: 8),
              _NavigationRailAction(
                extended: railExtended,
                compact: compact,
                selected: false,
                icon: compact ? Icons.menu_open_outlined : Icons.menu_outlined,
                selectedIcon: compact
                    ? Icons.menu_open_outlined
                    : Icons.menu_outlined,
                label: compact
                    ? l10n.navExpandSidebar
                    : l10n.navCollapseSidebar,
                onPressed: onToggleCompact,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationGroupHeader extends StatelessWidget {
  const _NavigationGroupHeader({
    required this.label,
    required this.extended,
    required this.compact,
    required this.showLeadingDivider,
  });

  final String label;
  final bool extended;
  final bool compact;
  final bool showLeadingDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (extended) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, showLeadingDivider ? 14 : 4, 16, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );
    }

    if (!showLeadingDivider) {
      return const SizedBox(height: 4);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: 8),
      child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
    );
  }
}

class _SettingsMenuButton extends StatelessWidget {
  const _SettingsMenuButton({
    required this.extended,
    required this.compact,
    required this.selectedFeature,
    required this.l10n,
    required this.onFeatureSelected,
  });

  final bool extended;
  final bool compact;
  final WorkspaceFeature selectedFeature;
  final AppLocalizations l10n;
  final ValueChanged<WorkspaceFeature> onFeatureSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = !selectedFeature.isPrimary;
    final colors = theme.colorScheme;
    final foreground = isSelected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;
    final background = isSelected
        ? colors.secondaryContainer
        : Colors.transparent;
    final icon = isSelected ? Icons.settings : Icons.settings_outlined;

    final settingsFeatures =
        workspaceCategoryFeatures[WorkspaceCategory.settings]!;

    final menu = PopupMenuButton<WorkspaceFeature>(
      tooltip: l10n.navSettingsMenu,
      position: PopupMenuPosition.over,
      onSelected: onFeatureSelected,
      itemBuilder: (context) => [
        for (final feature in settingsFeatures)
          PopupMenuItem<WorkspaceFeature>(
            value: feature,
            child: Row(
              children: [
                Icon(
                  selectedFeature == feature
                      ? FeatureNavigationRail._featureIcons(feature).$2
                      : FeatureNavigationRail._featureIcons(feature).$1,
                  size: 18,
                  color: selectedFeature == feature
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(FeatureNavigationRail._featureLabel(l10n, feature)),
              ],
            ),
          ),
      ],
      child: _SettingsMenuChild(
        extended: extended,
        compact: compact,
        background: background,
        foreground: foreground,
        icon: icon,
        label: l10n.navSettingsMenu,
      ),
    );

    return Semantics(
      container: true,
      label: l10n.navSettingsMenu,
      button: true,
      selected: isSelected,
      enabled: true,
      child: menu,
    );
  }
}

class _SettingsMenuChild extends StatelessWidget {
  const _SettingsMenuChild({
    required this.extended,
    required this.compact,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
  });

  final bool extended;
  final bool compact;
  final Color background;
  final Color foreground;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(icon, color: foreground),
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
                Icon(Icons.arrow_drop_down, color: foreground, size: 20),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      );
    }

    if (compact) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox.square(
          dimension: 48,
          child: Icon(icon, color: foreground),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 64,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: foreground),
            ),
          ],
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
        child: Semantics(
          label: label,
          button: true,
          selected: selected,
          enabled: true,
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
        ),
      );
    }

    if (compact) {
      return Tooltip(
        message: label,
        child: Semantics(
          label: label,
          button: true,
          selected: selected,
          enabled: true,
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPressed,
              child: SizedBox.square(
                dimension: 48,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Icon(currentIcon, color: foreground),
                    Opacity(
                      opacity: 0,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        enabled: true,
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

    return Semantics(
      label: '$title · $subtitle',
      button: true,
      enabled: enabled,
      child: Material(
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
                          color: foreground.withValues(
                            alpha: enabled ? 0.72 : 1,
                          ),
                        ),
                      ),
                    ],
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
