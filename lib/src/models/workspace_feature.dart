enum WorkspaceFeature {
  imageGeneration,
  batchGeneration,
  animationProject,
  imageEditor,
  pixelArtEditor,
  imageLibrary,
  apiSettings,
  localSettings,
}

enum WorkspaceCategory { generate, edit, assets, settings }

extension WorkspaceFeatureCategory on WorkspaceFeature {
  WorkspaceCategory get category {
    return switch (this) {
      WorkspaceFeature.imageGeneration ||
      WorkspaceFeature.batchGeneration ||
      WorkspaceFeature.animationProject => WorkspaceCategory.generate,
      WorkspaceFeature.imageEditor ||
      WorkspaceFeature.pixelArtEditor => WorkspaceCategory.edit,
      WorkspaceFeature.imageLibrary => WorkspaceCategory.assets,
      WorkspaceFeature.apiSettings ||
      WorkspaceFeature.localSettings => WorkspaceCategory.settings,
    };
  }

  bool get isPrimary => category != WorkspaceCategory.settings;
}

const List<WorkspaceCategory> primaryWorkspaceCategories = [
  WorkspaceCategory.generate,
  WorkspaceCategory.edit,
  WorkspaceCategory.assets,
];

const Map<WorkspaceCategory, List<WorkspaceFeature>> workspaceCategoryFeatures =
    {
      WorkspaceCategory.generate: [
        WorkspaceFeature.imageGeneration,
        WorkspaceFeature.batchGeneration,
        WorkspaceFeature.animationProject,
      ],
      WorkspaceCategory.edit: [
        WorkspaceFeature.imageEditor,
        WorkspaceFeature.pixelArtEditor,
      ],
      WorkspaceCategory.assets: [WorkspaceFeature.imageLibrary],
      WorkspaceCategory.settings: [
        WorkspaceFeature.apiSettings,
        WorkspaceFeature.localSettings,
      ],
    };
