enum ImagePickSource { localFile, imageLibrary }

enum ImageLibraryKindFilter { all, generated, sprite, edited, gif }

enum ImageLibrarySortOrder { newest, oldest, titleAscending }

enum ImageLibraryTileMenuAction {
  useInEditor,
  reuseGeneration,
  copyGeneration,
  copyPath,
  openLocation,
  delete,
}

enum ApiConfigSaveStatus { saved, pending, saving, failed }
