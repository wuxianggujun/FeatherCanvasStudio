import 'package:flutter/foundation.dart';

import '../models/image_library_item.dart';

class ImageLibraryNotifier extends ChangeNotifier {
  List<ImageLibraryItem> _items = const [];

  List<ImageLibraryItem> get items => _items;

  set items(List<ImageLibraryItem> value) {
    if (identical(_items, value)) return;
    _items = value;
    notifyListeners();
  }
}
