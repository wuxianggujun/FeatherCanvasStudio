import 'package:flutter/material.dart';

import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../models/image_advanced_settings.dart';
import '../models/sprite_sheet_grid_spec.dart';
import '../l10n/app_l10n.dart';
import '../theme/layout_constants.dart';
import '../utils/display_labels.dart';
import '../utils/generation_limits.dart';
import '../utils/image_dimensions.dart';
import '../utils/localized_display_labels.dart';
import '../widgets/api_settings_widgets.dart';
import '../widgets/common_form_widgets.dart';
import '../widgets/image_advanced_settings_widgets.dart';
import '../widgets/image_size_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';

enum ImageGenerationPanelMode { textToImage, imageToImage }

class ControlPanel extends StatelessWidget {
  const ControlPanel({
    this.mode = ImageGenerationPanelMode.textToImage,
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.providerKind,
    required this.model,
    required this.imageSizeCapabilityOverride,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.imageCount,
    required this.templateImagePaths,
    required this.advancedSettings,
    required this.userController,
    required this.isGenerating,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onImageCountChanged,
    required this.onAdvancedSettingsChanged,
    required this.onPickTemplateImage,
    this.onPasteTemplateImage,
    required this.onClearTemplateImage,
    required this.onRemoveTemplateImage,
    required this.onGenerate,
    super.key,
  });

  final ImageGenerationPanelMode mode;
  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ApiProviderKind providerKind;
  final String model;
  final ImageSizeCapabilityOverride imageSizeCapabilityOverride;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int imageCount;
  final List<String> templateImagePaths;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final bool isGenerating;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onImageCountChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onPickTemplateImage;
  final VoidCallback? onPasteTemplateImage;
  final VoidCallback onClearTemplateImage;
  final ValueChanged<String> onRemoveTemplateImage;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final isImageToImage = mode == ImageGenerationPanelMode.imageToImage;
    final hasTemplateImages = templateImagePaths.isNotEmpty;
    final sizeValidation = validateImageSizeForModel(
      size: size,
      providerKind: providerKind,
      model: model,
      capabilityOverride: imageSizeCapabilityOverride,
      labels: localizedImageSizeDisplayLabels(l10n),
    );

    return AppPanel(
      title: l10n.generationConfigSectionTitle,
      child: Column(
        children: [
          ApiConfigSelector(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfigId,
            onChanged: onApiConfigChanged,
            onOpenSettings: onOpenApiSettings,
          ),
          if (isImageToImage) ...[
            const SizedBox(height: fieldGap),
            TemplateImagePicker(
              imagePaths: templateImagePaths,
              title: l10n.imageToImageReferenceImageTitle,
              pickLabel: hasTemplateImages
                  ? l10n.imageGenerationAddReferenceImagesLabel
                  : l10n.imageToImageReferenceImagePickLabel,
              onPick: isGenerating ? null : onPickTemplateImage,
              onClear: !hasTemplateImages || isGenerating
                  ? null
                  : onClearTemplateImage,
              onRemoveImage: isGenerating ? null : onRemoveTemplateImage,
              removeImageTooltipBuilder: (path) =>
                  l10n.imageGenerationRemoveReferenceImageTooltip(
                    fileNameFromPath(path),
                  ),
              selectedSummary: hasTemplateImages
                  ? l10n.imageGenerationReferenceImageCountLabel(
                      templateImagePaths.length,
                    )
                  : null,
              clearTooltip: l10n.imageGenerationClearReferenceImagesTooltip,
              previewHeight: 132,
              emptyHint: l10n.imageToImageReferenceImageEmptyHint,
              secondaryActionLabel: l10n.imageToImagePasteReferenceImageLabel,
              onSecondaryAction: isGenerating ? null : onPasteTemplateImage,
            ),
          ],
          const SizedBox(height: fieldGap),
          TextField(
            controller: promptController,
            minLines: 5,
            maxLines: 9,
            decoration: InputDecoration(
              labelText: l10n.positivePromptLabel,
              hintText: l10n.positivePromptHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: fieldGap),
          OptionalPromptExclusionSection(
            controller: negativePromptController,
            labelText: l10n.negativePromptLabel,
            hintText: l10n.negativePromptHint,
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: fieldGap),
          ImageSizeInput(
            size: size,
            providerKind: providerKind,
            model: model,
            capabilityOverride: imageSizeCapabilityOverride,
            onChanged: onSizeChanged,
          ),
          const SizedBox(height: fieldGap),
          ImageAdvancedSettingsSection(
            settings: advancedSettings,
            userController: userController,
            hasTemplateImage: isImageToImage && hasTemplateImages,
            onChanged: onAdvancedSettingsChanged,
          ),
          const SizedBox(height: fieldGap),
          IntegerStepperField(
            label: l10n.targetImageCountLabel,
            value: imageCount,
            minValue: minImageGenerationCount,
            maxValue: maxImageGenerationTargetCount,
            suffixText: l10n.imageCountSuffix,
            helperText: l10n.localSettingsDefaultImageCountHelper(
              maxImageGenerationRequestCount,
            ),
            enabled: !isGenerating,
            onChanged: onImageCountChanged,
          ),
          const SizedBox(height: sectionGap),
          PrimaryActionButton(
            onPressed: isGenerating || !sizeValidation.isValid
                ? null
                : onGenerate,
            icon: isImageToImage
                ? Icons.compare_outlined
                : Icons.auto_awesome,
            label: isImageToImage
                ? l10n.imageGenerationGenerateWithReferenceButton
                : l10n.generateImageButton,
            busyLabel: isImageToImage
                ? l10n.imageGenerationGeneratingWithReferenceButton
                : l10n.generatingImageButton,
            isBusy: isGenerating,
          ),
        ],
      ),
    );
  }
}

class SpriteSheetGenerationPanel extends StatelessWidget {
  const SpriteSheetGenerationPanel({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.providerKind,
    required this.model,
    required this.imageSizeCapabilityOverride,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.rows,
    required this.columns,
    required this.gridSpec,
    required this.templateImagePath,
    required this.advancedSettings,
    required this.userController,
    required this.isGenerating,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onRowsChanged,
    required this.onColumnsChanged,
    required this.onGridSpecChanged,
    required this.onAdvancedSettingsChanged,
    required this.onPickTemplateImage,
    required this.onClearTemplateImage,
    required this.onGenerate,
    super.key,
  });

  static const List<int> _gridSizes = <int>[1, 2, 3, 4, 5, 6, 7, 8];

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ApiProviderKind providerKind;
  final String model;
  final ImageSizeCapabilityOverride imageSizeCapabilityOverride;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int rows;
  final int columns;
  final SpriteSheetGridSpec gridSpec;
  final String? templateImagePath;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final bool isGenerating;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<SpriteSheetGridSpec> onGridSpecChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onPickTemplateImage;
  final VoidCallback onClearTemplateImage;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final frameTotal = rows * columns;
    final sizeValidation = validateImageSizeForModel(
      size: size,
      providerKind: providerKind,
      model: model,
      capabilityOverride: imageSizeCapabilityOverride,
      labels: localizedImageSizeDisplayLabels(l10n),
    );

    return AppPanel(
      title: l10n.spriteSheetGenerationConfigTitle,
      trailing: FrameCountBadge(count: frameTotal, label: l10n.spriteSheetCell),
      child: Column(
        children: [
          ApiConfigSelector(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfigId,
            onChanged: onApiConfigChanged,
            onOpenSettings: onOpenApiSettings,
          ),
          const SizedBox(height: fieldGap),
          TemplateImagePicker(
            imagePath: templateImagePath,
            onPick: isGenerating ? null : onPickTemplateImage,
            onClear: templateImagePath == null || isGenerating
                ? null
                : onClearTemplateImage,
          ),
          const SizedBox(height: fieldGap),
          TextField(
            controller: promptController,
            minLines: 7,
            maxLines: 12,
            decoration: InputDecoration(
              labelText: l10n.spriteSheetPromptLabel,
              hintText: l10n.spriteSheetPromptHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: fieldGap),
          OptionalPromptExclusionSection(
            controller: negativePromptController,
            labelText: l10n.negativePromptLabel,
            hintText: l10n.spriteSheetNegativePromptHint,
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: fieldGap),
          ImageSizeInput(
            size: size,
            providerKind: providerKind,
            model: model,
            capabilityOverride: imageSizeCapabilityOverride,
            onChanged: onSizeChanged,
            compact: true,
          ),
          const SizedBox(height: fieldGap),
          ImageAdvancedSettingsSection(
            settings: advancedSettings,
            userController: userController,
            hasTemplateImage: templateImagePath != null,
            onChanged: onAdvancedSettingsChanged,
          ),
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: OptionDropdown<int>(
              label: l10n.spriteSheetRowsLabel,
              value: rows,
              options: _gridSizes,
              labelBuilder: l10n.spriteSheetRowsValue,
              onChanged: onRowsChanged,
            ),
            second: OptionDropdown<int>(
              label: l10n.spriteSheetColumnsLabel,
              value: columns,
              options: _gridSizes,
              labelBuilder: l10n.spriteSheetColumnsValue,
              onChanged: onColumnsChanged,
            ),
          ),
          const SizedBox(height: fieldGap),
          SpriteSheetGridSpecControls(
            gridSpec: gridSpec,
            onChanged: onGridSpecChanged,
          ),
          const SizedBox(height: sectionGap),
          PrimaryActionButton(
            onPressed: isGenerating || !sizeValidation.isValid
                ? null
                : onGenerate,
            icon: Icons.movie_filter_outlined,
            label: l10n.spriteSheetGenerateButton,
            busyLabel: l10n.spriteSheetGeneratingButton,
            isBusy: isGenerating,
          ),
        ],
      ),
    );
  }
}
