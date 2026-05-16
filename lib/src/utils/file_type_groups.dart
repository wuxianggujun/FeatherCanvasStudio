import 'package:file_selector/file_selector.dart';

import '../models/image_asset_kind.dart';

const List<XTypeGroup> imageTypeGroups = <XTypeGroup>[
  XTypeGroup(
    label: 'Images',
    extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'],
  ),
];

const List<XTypeGroup> templateImageTypeGroups = <XTypeGroup>[
  XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp']),
];

const List<XTypeGroup> imageLibraryArchiveTypeGroups = <XTypeGroup>[
  XTypeGroup(label: 'FeatherCanvas Library Archive', extensions: ['zip']),
];

const List<ImageAssetKind> spriteSheetLibraryKinds = <ImageAssetKind>[
  ImageAssetKind.spriteSheet,
  ImageAssetKind.editedImage,
];

const List<ImageAssetKind> singleFrameLibraryKinds = <ImageAssetKind>[
  ImageAssetKind.generatedImage,
  ImageAssetKind.spriteFrame,
];

const List<ImageAssetKind> templateLibraryKinds = <ImageAssetKind>[
  ImageAssetKind.generatedImage,
  ImageAssetKind.spriteSheet,
  ImageAssetKind.spriteFrame,
  ImageAssetKind.editedImage,
];

const List<ImageAssetKind> gifSourceLibraryKinds = <ImageAssetKind>[
  ImageAssetKind.generatedImage,
  ImageAssetKind.spriteSheet,
  ImageAssetKind.spriteFrame,
];
