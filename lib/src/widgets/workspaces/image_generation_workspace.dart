import 'package:flutter/material.dart';

import '../../models/app_config.dart';
import '../../models/generated_image.dart';
import '../../models/image_advanced_settings.dart';
import '../../services/image_api_client.dart';
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
    required this.isGenerating,
    required this.errorMessage,
    required this.generatedImages,
    required this.debugRecord,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onImageCountChanged,
    required this.onAdvancedSettingsChanged,
    required this.onGenerate,
    required this.onMakeBackgroundTransparent,
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
  final bool isGenerating;
  final String? errorMessage;
  final List<GeneratedImage> generatedImages;
  final ImageRequestDebugRecord? debugRecord;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onImageCountChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onGenerate;
  final void Function(int index, GeneratedImage image)
  onMakeBackgroundTransparent;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: '文本生图',
      description: '选择已保存的接口配置，再填写提示词生成图片',
      controller: controller,
      children: [
        ResponsiveWorkspaceSplit(
          controls: ControlPanel(
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
          preview: PreviewPanel(
            errorMessage: errorMessage,
            generatedImages: generatedImages,
            isGenerating: isGenerating,
            debugRecord: debugRecord,
            onRetry: onGenerate,
            onMakeBackgroundTransparent: onMakeBackgroundTransparent,
          ),
        ),
      ],
    );
  }
}
