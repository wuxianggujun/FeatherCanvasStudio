part of 'image_library_dialog_widgets.dart';

class ImageLibraryPickerDialog extends StatefulWidget {
  const ImageLibraryPickerDialog({
    required this.title,
    required this.items,
    required this.allowMultiple,
    super.key,
  });

  final String title;
  final List<ImageLibraryItem> items;
  final bool allowMultiple;

  @override
  State<ImageLibraryPickerDialog> createState() =>
      ImageLibraryPickerDialogState();
}

class ImageLibraryPickerDialogState extends State<ImageLibraryPickerDialog> {
  final Set<String> _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final theme = Theme.of(context);

    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: 760,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 560),
            child: GridView.builder(
              primary: false,
              itemCount: widget.items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final selected = _selectedIds.contains(item.id);
                final semanticLabel = l10n.imageLibraryPickerItemSemanticLabel(
                  localizedImageAssetKindLabel(l10n, item.kind),
                  item.displayTitle,
                  index + 1,
                  widget.items.length,
                );
                return Semantics(
                  container: true,
                  label: semanticLabel,
                  button: true,
                  selected: selected,
                  onTap: () => _toggleSelection(item),
                  child: Material(
                    color: selected
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _toggleSelection(item),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: ImageLibraryPreview(item: item),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Icon(
                                      selected
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: selected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              localizedImageAssetKindLabel(l10n, item.kind),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: _selectedIds.isEmpty ? null : _confirm,
            child: Text(
              widget.allowMultiple
                  ? l10n.imageLibraryPickerSelectCount(_selectedIds.length)
                  : l10n.selectAction,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(ImageLibraryItem item) {
    setState(() {
      if (widget.allowMultiple) {
        if (!_selectedIds.add(item.id)) {
          _selectedIds.remove(item.id);
        }
      } else {
        _selectedIds
          ..clear()
          ..add(item.id);
      }
    });
  }

  void _confirm() {
    if (widget.allowMultiple) {
      Navigator.of(context).pop([
        for (final item in widget.items)
          if (_selectedIds.contains(item.id)) item,
      ]);
      return;
    }

    final selectedId = _selectedIds.first;
    for (final item in widget.items) {
      if (item.id == selectedId) {
        Navigator.of(context).pop(item);
        return;
      }
    }
  }
}
