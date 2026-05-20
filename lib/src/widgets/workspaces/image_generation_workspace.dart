import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_config.dart';
import '../../models/generated_image.dart';
import '../../models/image_advanced_settings.dart';
import '../../state/image_generation_notifier.dart';
import '../../l10n/app_l10n.dart';
import '../../utils/image_dimensions.dart';
import '../generation_form_widgets.dart';
import '../layout_navigation_widgets.dart';
import '../preview_widgets.dart';

class ImageGenerationWorkspace extends StatelessWidget {
  const ImageGenerationWorkspace({
    required this.controller,
    required this.apiConfigs,
    required this.selectedApiConfig,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.imageCount,
    required this.advancedSettings,
    required this.userController,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onImageCountChanged,
    required this.onAdvancedSettingsChanged,
    required this.onGenerate,
    required this.onCopyImage,
    required this.onExportImage,
    required this.onMakeBackgroundTransparent,
    this.historyControls,
    super.key,
  });

  final ScrollController controller;
  final List<ApiConfig> apiConfigs;
  final ApiConfig selectedApiConfig;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onImageCountChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onGenerate;
  final void Function(int index, GeneratedImage image) onCopyImage;
  final void Function(int index, GeneratedImage image) onExportImage;
  final void Function(int index, GeneratedImage image)
  onMakeBackgroundTransparent;
  final Widget? historyControls;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    return WorkspacePage(
      title: l10n.imageGenerationWorkspaceTitle,
      description: l10n.imageGenerationWorkspaceDescription,
      controller: controller,
      trailing: historyControls,
      children: [
        ResponsiveWorkspaceSplit(
          storageKey: 'image_generation',
          controls: Selector<ImageGenerationNotifier, bool>(
            selector: (_, n) => n.isGenerating,
            builder: (context, isGenerating, _) => ControlPanel(
              apiConfigs: apiConfigs,
              selectedApiConfigId: selectedApiConfig.id,
              providerKind: selectedApiConfig.providerKind,
              model: selectedApiConfig.model,
              imageSizeCapabilityOverride:
                  selectedApiConfig.imageSizeCapabilityOverride,
              promptController: promptController,
              negativePromptController: negativePromptController,
              size: size,
              imageCount: imageCount,
              advancedSettings: advancedSettings,
              userController: userController,
              isGenerating: isGenerating,
              onApiConfigChanged: onApiConfigChanged,
              onOpenApiSettings: onOpenApiSettings,
              onSizeChanged: onSizeChanged,
              onImageCountChanged: onImageCountChanged,
              onAdvancedSettingsChanged: onAdvancedSettingsChanged,
              onGenerate: onGenerate,
            ),
          ),
          preview: Consumer<ImageGenerationNotifier>(
            builder: (context, notifier, _) => PreviewPanel(
              errorMessage: notifier.errorMessage,
              generatedImages: notifier.generatedImages,
              isGenerating: notifier.isGenerating,
              targetImageCount: imageCount,
              targetAspectRatio: imageAspectRatioFromSize(size),
              debugRecord: notifier.debugRecord,
              onRetry: onGenerate,
              onCopyImage: onCopyImage,
              onExportImage: onExportImage,
              onMakeBackgroundTransparent: onMakeBackgroundTransparent,
            ),
          ),
        ),
      ],
    );
  }
}
