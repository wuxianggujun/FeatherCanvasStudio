List<T> reorderListItems<T>(List<T> items, int oldIndex, int newIndex) {
  if (items.isEmpty) {
    return <T>[];
  }
  if (oldIndex < 0 ||
      oldIndex >= items.length ||
      newIndex < 0 ||
      newIndex > items.length) {
    return List<T>.from(items);
  }

  final reordered = List<T>.from(items);
  final normalizedNewIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
  final item = reordered.removeAt(oldIndex);
  reordered.insert(normalizedNewIndex, item);
  return reordered;
}
