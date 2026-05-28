import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selected export items keep image library order', () {
    final first = _item('first');
    final second = _item('second');
    final third = _item('third');

    final selectedItems = selectedImageLibraryItemsForExport(
      library: [first, second, third],
      selectedItemIds: {'third', 'first'},
    );

    expect(selectedItems, [first, third]);
  });

  test('selected export plan separates existing and missing files', () async {
    final first = _item('first');
    final second = _item('second');
    final third = _item('third');

    final plan = await buildImageLibrarySelectedExportPlan(
      selectedItems: [first, second, third],
      itemExists: (item) => item.id != 'second',
    );

    expect(plan.selectedItems, [first, second, third]);
    expect(plan.existingItems, [first, third]);
    expect(plan.missingCount, 1);
    expect(plan.hasExistingFiles, isTrue);
  });

  test('selected export plan reports when all files are missing', () async {
    final plan = await buildImageLibrarySelectedExportPlan(
      selectedItems: [_item('missing')],
      itemExists: (_) => false,
    );

    expect(plan.existingItems, isEmpty);
    expect(plan.missingCount, 1);
    expect(plan.hasExistingFiles, isFalse);
  });
}

ImageLibraryItem _item(String id) {
  return ImageLibraryItem(
    id: id,
    path: '$id.png',
    createdAt: DateTime.parse('2026-05-25T12:00:00Z'),
    kind: ImageAssetKind.generatedImage,
    title: id,
    source: 'test',
  );
}
