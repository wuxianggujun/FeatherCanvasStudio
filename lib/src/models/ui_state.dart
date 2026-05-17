enum ImagePickSource { localFile, imageLibrary }

enum ImageLibraryKindFilter { all, generated, sprite, edited, animation, gif }

enum ImageLibrarySortOrder { newest, oldest, titleAscending }

enum ImageLibraryTileMenuAction {
  openAnimationProject,
  useInEditor,
  reuseGeneration,
  copyGeneration,
  makeBackgroundTransparent,
  copyImage,
  exportImage,
  copyPath,
  openLocation,
  delete,
}

enum ApiConfigSaveStatus { saved, pending, saving, failed }
