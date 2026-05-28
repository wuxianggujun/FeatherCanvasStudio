import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('image library merge prepends appended items and removes ids', () {
    final kept = _item('kept');
    final replaced = _item('replaced');
    final removed = _item('removed');
    final replacement = _item('replaced', title: 'replacement');
    final appended = _item('appended');

    final result = mergeImageLibraryItems(
      currentLibrary: [kept, replaced, removed],
      appendedItems: [replacement, appended],
      removedItemIds: {'removed'},
    );

    expect(result, [replacement, appended, kept]);
  });

  test('image library merge keeps current order without changes', () {
    final first = _item('first');
    final second = _item('second');

    final result = mergeImageLibraryItems(currentLibrary: [first, second]);

    expect(result, [first, second]);
  });
}

ImageLibraryItem _item(String id, {String? title}) {
  return ImageLibraryItem(
    id: id,
    path: '$id.png',
    createdAt: DateTime.parse('2026-05-21T12:00:00Z'),
    kind: ImageAssetKind.generatedImage,
    title: title ?? id,
    source: 'test',
  );
}
