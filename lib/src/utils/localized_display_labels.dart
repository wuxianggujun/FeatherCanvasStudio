import '../l10n/generated/app_localizations.dart';
import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../models/image_asset_kind.dart';
import '../models/sprite_sheet_frame_fit.dart';
import '../models/ui_state.dart';
import '../services/api_config_service.dart';
import '../services/gif_composer_service.dart';
import 'image_dimensions.dart';

String localizedImageQualityLabel(AppLocalizations l10n, String value) {
  return switch (value) {
    'auto' => l10n.displayLabelAuto,
    'low' => l10n.displayLabelLow,
    'medium' => l10n.displayLabelMedium,
    'high' => l10n.displayLabelHigh,
    'standard' => l10n.displayLabelStandard,
    'hd' => l10n.displayLabelHd,
    _ => value,
  };
}

String localizedImageBackgroundLabel(AppLocalizations l10n, String value) {
  return switch (value) {
    'auto' => l10n.displayLabelAuto,
    'transparent' => l10n.displayLabelTransparent,
    'opaque' => l10n.displayLabelOpaque,
    _ => value,
  };
}

String localizedImageOutputFormatLabel(String value) {
  return switch (value) {
    'png' => 'PNG',
    'jpeg' => 'JPEG',
    'webp' => 'WebP',
    _ => value,
  };
}

String localizedImageModerationLabel(AppLocalizations l10n, String value) {
  return switch (value) {
    'auto' => l10n.displayLabelAuto,
    'low' => l10n.displayLabelLow,
    _ => value,
  };
}

String localizedApiProviderKindLabel(
  AppLocalizations l10n,
  ApiProviderKind kind,
) {
  return switch (kind) {
    ApiProviderKind.official => l10n.apiProviderOfficial,
    ApiProviderKind.compatible => l10n.apiProviderCompatible,
    ApiProviderKind.gemini => 'Gemini',
  };
}

String localizedApiProviderKindDescription(
  AppLocalizations l10n,
  ApiProviderKind kind,
) {
  return switch (kind) {
    ApiProviderKind.official => l10n.apiProviderOfficialDescription,
    ApiProviderKind.compatible => l10n.apiProviderCompatibleDescription,
    ApiProviderKind.gemini => l10n.apiProviderGeminiDescription,
  };
}

String localizedApiModelHintForProviderKind(
  AppLocalizations l10n,
  ApiProviderKind kind,
) {
  final defaultModel = defaultModelForProviderKind(kind);
  if (defaultModel.isNotEmpty) {
    return defaultModel;
  }
  return l10n.apiModelManualHint;
}

String localizedImageAssetKindLabel(
  AppLocalizations l10n,
  ImageAssetKind kind,
) {
  return switch (kind) {
    ImageAssetKind.generatedImage => l10n.imageAssetKindGenerated,
    ImageAssetKind.spriteSheet => l10n.imageAssetKindSpriteSheet,
    ImageAssetKind.spriteFrame => l10n.imageAssetKindSpriteFrame,
    ImageAssetKind.editedImage => l10n.imageAssetKindEdited,
    ImageAssetKind.animationProject => l10n.imageAssetKindAnimationProject,
    ImageAssetKind.gif => l10n.imageAssetKindGif,
  };
}

String localizedImageLibraryKindFilterLabel(
  AppLocalizations l10n,
  ImageLibraryKindFilter filter,
) {
  return switch (filter) {
    ImageLibraryKindFilter.all => l10n.imageLibraryFilterAll,
    ImageLibraryKindFilter.generated => l10n.imageLibraryFilterGenerated,
    ImageLibraryKindFilter.sprite => l10n.imageLibraryFilterSprite,
    ImageLibraryKindFilter.edited => l10n.imageLibraryFilterEdited,
    ImageLibraryKindFilter.animation => l10n.imageLibraryFilterAnimation,
    ImageLibraryKindFilter.gif => l10n.imageLibraryFilterGif,
  };
}

String localizedImageLibrarySortOrderLabel(
  AppLocalizations l10n,
  ImageLibrarySortOrder sortOrder,
) {
  return switch (sortOrder) {
    ImageLibrarySortOrder.newest => l10n.imageLibrarySortNewest,
    ImageLibrarySortOrder.oldest => l10n.imageLibrarySortOldest,
    ImageLibrarySortOrder.titleAscending => l10n.imageLibrarySortTitleAsc,
  };
}

String localizedEditorFrameOptionLabel(
  AppLocalizations l10n,
  int index,
  int columns,
) {
  final row = index ~/ columns + 1;
  final column = index % columns + 1;
  return l10n.editorFrameOptionLabel(index + 1, row, column);
}

String localizedSpriteSheetFrameFitLabel(
  AppLocalizations l10n,
  SpriteSheetFrameFit fit,
) {
  return switch (fit) {
    SpriteSheetFrameFit.contain => l10n.spriteSheetEditorFrameFitContain,
    SpriteSheetFrameFit.cover => l10n.spriteSheetEditorFrameFitCover,
    SpriteSheetFrameFit.stretch => l10n.spriteSheetEditorFrameFitStretch,
  };
}

String localizedGifPlaybackModeLabel(
  AppLocalizations l10n,
  GifPlaybackMode mode,
) {
  return switch (mode) {
    GifPlaybackMode.normal => l10n.gifPlaybackModeNormal,
    GifPlaybackMode.reverse => l10n.gifPlaybackModeReverse,
    GifPlaybackMode.pingPong => l10n.gifPlaybackModePingPong,
  };
}

ImageSizeDisplayLabels localizedImageSizeDisplayLabels(AppLocalizations l10n) {
  return _LocalizedImageSizeDisplayLabels(l10n);
}

ApiConfigServiceLabels localizedApiConfigServiceLabels(AppLocalizations l10n) {
  return _LocalizedApiConfigServiceLabels(l10n);
}

String localizedImageSizePresetLabel(
  AppLocalizations l10n,
  ImageSizePreset preset,
) {
  final scale = imageSizePresetScaleLabel(preset);
  final orientation = localizedImageOrientationLabel(l10n, preset.dimensions);
  if (scale == '21:9') {
    return l10n.imageSizePresetWide(scale);
  }
  return l10n.imageSizePresetLabel(scale, orientation);
}

String localizedImageOrientationLabel(
  AppLocalizations l10n,
  ImageDimensions dimensions,
) {
  if (dimensions.width == dimensions.height) {
    return l10n.imageAspectSquare;
  }
  return dimensions.width > dimensions.height
      ? l10n.imageAspectLandscape
      : l10n.imageAspectPortrait;
}

class _LocalizedImageSizeDisplayLabels extends ImageSizeDisplayLabels {
  const _LocalizedImageSizeDisplayLabels(this.l10n);

  final AppLocalizations l10n;

  @override
  String get invalidSizeFallback => l10n.imageSizeInvalidFallback;

  @override
  String get invalidDimensions => l10n.imageSizeInvalidDimensions;

  @override
  String fixedPresetsOnly(String presetSizes) {
    return l10n.imageSizeFixedPresetsOnly(presetSizes);
  }

  @override
  String sideTooSmall(int minSide) {
    return l10n.imageSizeSideTooSmall(minSide);
  }

  @override
  String sideTooLarge(int maxSide) {
    return l10n.imageSizeSideTooLarge(maxSide);
  }

  @override
  String sideStepMismatch(int step) {
    return l10n.imageSizeSideStepMismatch(step);
  }

  @override
  String aspectRatioTooLarge(int maxAspectRatio) {
    return l10n.imageSizeAspectRatioTooLarge(maxAspectRatio);
  }

  @override
  String totalPixelsTooSmall(int minPixels) {
    return l10n.imageSizeTotalPixelsTooSmall(minPixels);
  }

  @override
  String totalPixelsTooLarge(int maxPixels) {
    return l10n.imageSizeTotalPixelsTooLarge(maxPixels);
  }

  @override
  String capabilityLabel(ImageSizeMode mode) {
    return switch (mode) {
      ImageSizeMode.fixedPresets => l10n.imageSizeCapabilityFixedPresets,
      ImageSizeMode.customPixels => l10n.imageSizeCapabilityCustomPixels,
      ImageSizeMode.aspectRatio => l10n.imageSizeCapabilityAspectRatio,
    };
  }

  @override
  String capabilityOverrideLabel(ImageSizeCapabilityOverride override) {
    return switch (override) {
      ImageSizeCapabilityOverride.auto => l10n.imageSizeCapabilityAuto,
      ImageSizeCapabilityOverride.fixedPresets =>
        l10n.imageSizeCapabilityFixedPresets,
      ImageSizeCapabilityOverride.customPixels =>
        l10n.imageSizeCapabilityCustomPixels,
      ImageSizeCapabilityOverride.aspectRatio =>
        l10n.imageSizeCapabilityGeminiAspectRatio,
    };
  }

  @override
  String capabilityDescription(ImageModelCapabilities capabilities) {
    final presetSizes = capabilities.presets
        .map((preset) => preset.size)
        .join(' / ');
    return switch (capabilities.sizeMode) {
      ImageSizeMode.fixedPresets => l10n.imageSizeCapabilityFixedDescription(
        presetSizes,
      ),
      ImageSizeMode.customPixels => l10n.imageSizeCapabilityCustomDescription(
        capabilities.constraints!.step,
      ),
      ImageSizeMode.aspectRatio => l10n.imageSizeCapabilityAspectDescription,
    };
  }
}

class _LocalizedApiConfigServiceLabels extends ApiConfigServiceLabels {
  const _LocalizedApiConfigServiceLabels(this.l10n);

  final AppLocalizations l10n;

  @override
  String get apiKeyRequired => l10n.apiTestApiKeyRequired;

  @override
  String get basicTestSuccess => l10n.apiBasicTestSuccess;

  @override
  String get fullTestSuccess => l10n.apiTestSuccess;

  @override
  String get basicTestFailed => l10n.apiBasicTestFailed;

  @override
  String get fullTestFailed => l10n.apiTestFailed;

  @override
  String get officialCompatibilityHint => l10n.apiOfficialCompatibilityHint;

  @override
  String get testTimeout => l10n.apiTestTimeout;

  @override
  String fullTestFailedWithError(Object error) {
    return l10n.apiTestFailedWithError(error);
  }

  @override
  String get modelFetchApiKeyRequired => l10n.apiModelFetchApiKeyRequired;

  @override
  String get modelFetchTimeout => l10n.apiModelFetchTimeout;

  @override
  String get modelFetchEmpty => l10n.apiModelFetchEmpty;

  @override
  String modelFetchFailed(Object error) {
    return l10n.apiModelFetchFailedWithError(error);
  }

  @override
  String modelFetchSelected(int count, String modelId) {
    return l10n.apiModelFetchSelected(count, modelId);
  }

  @override
  String modelFetchSuccess(int count) {
    return l10n.apiModelFetchSuccess(count);
  }
}
