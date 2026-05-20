import '../models/animation_project.dart';
import '../services/general_image_editing_service.dart';
import '../services/image_library_service.dart';
import 'generated/app_localizations.dart';

GeneralImageEditSummaryLabels generalImageEditSummaryLabels(
  AppLocalizations l10n,
) {
  return GeneralImageEditSummaryLabels(
    crop: l10n.generalImageEditSummaryCrop,
    rotatePattern: l10n.generalImageEditSummaryRotatePattern,
    flipHorizontal: l10n.generalImageEditorFlipHorizontal,
    flipVertical: l10n.generalImageEditorFlipVertical,
    resizePattern: l10n.generalImageEditSummaryResizePattern,
    annotationPattern: l10n.generalImageEditSummaryAnnotationPattern,
    jpegQualityPattern: l10n.generalImageEditSummaryJpegQualityPattern,
    saveCopy: l10n.generalImageEditSummarySaveCopy,
    partSeparator: l10n.generalImageEditSummarySeparator,
    localRegion: l10n.generalImageEditorRegionTitle,
    transparentBackground: l10n.generalImageEditorTransparentBackground,
    colorAdjustment: l10n.generalImageEditorColorTitle,
    blurPattern: l10n.generalImageEditSummaryBlurPattern,
    sharpenPattern: l10n.generalImageEditSummarySharpenPattern,
    pixelationPattern: l10n.generalImageEditSummaryPixelationPattern,
    effectOriginal: l10n.generalImageEditorEffectOriginal,
    effectGrayscale: l10n.generalImageEditorEffectGrayscale,
    effectSepia: l10n.generalImageEditorEffectSepia,
    effectInvert: l10n.generalImageEditorEffectInvert,
  );
}

ImageLibraryGifLabels imageLibraryGifLabels(
  AppLocalizations l10n, {
  required String title,
  required String source,
  required int frameCount,
}) {
  return ImageLibraryGifLabels(
    title: title,
    source: source,
    prompt: l10n.imageLibraryGifPrompt(frameCount),
  );
}

ImageLibraryAnimationProjectLabels imageLibraryAnimationProjectLabels(
  AppLocalizations l10n,
  AnimationProject project,
) {
  final summary = AnimationProjectSummary.fromProject(project);
  return ImageLibraryAnimationProjectLabels(
    source: l10n.navAnimationProject,
    prompt: l10n.imageLibraryAnimationProjectPrompt(
      summary.trackCount,
      summary.frameCount,
      summary.canvasWidth,
      summary.canvasHeight,
    ),
  );
}

ImageLibrarySpriteSheetLabels imageLibrarySpriteSheetLabels(
  AppLocalizations l10n, {
  required String title,
  required String source,
  required int rows,
  required int columns,
}) {
  return ImageLibrarySpriteSheetLabels(
    title: title,
    source: source,
    prompt: l10n.imageLibrarySpriteSheetPrompt(rows, columns),
  );
}

ImageLibraryEditedSpriteSheetLabels imageLibraryEditedSpriteSheetLabels(
  AppLocalizations l10n, {
  required int frameIndex,
  required int rows,
  required int columns,
}) {
  return ImageLibraryEditedSpriteSheetLabels(
    title: l10n.imageLibraryEditedSpriteSheetTitle,
    source: l10n.editorGifImageEditorSource,
    prompt: l10n.imageLibraryEditedSpriteSheetPrompt(frameIndex, rows, columns),
  );
}

ImageLibrarySpriteFrameLabels imageLibrarySpriteFrameLabels(
  AppLocalizations l10n, {
  required String sheetTitle,
  required int frameIndex,
}) {
  return ImageLibrarySpriteFrameLabels(
    title: l10n.imageLibrarySpriteFrameTitle(sheetTitle, frameIndex),
  );
}
