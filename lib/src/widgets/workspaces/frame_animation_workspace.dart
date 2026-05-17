import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/app_config.dart';
import '../../models/generated_image.dart';
import '../../models/image_advanced_settings.dart';
import '../../models/sprite_sheet_grid_spec.dart';
import '../../services/image_api_client.dart';
import '../../services/sprite_sheet_service.dart';
import '../../utils/sprite_sheet_text.dart';
import '../generation_form_widgets.dart';
import '../layout_navigation_widgets.dart';
import '../preview_widgets.dart';

class FrameAnimationWorkspace extends StatelessWidget {
  const FrameAnimationWorkspace({
    required this.apiConfigs,
    required this.selectedApiConfig,
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
    required this.errorMessage,
    required this.debugRecord,
    required this.generatedImages,
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
    required this.onExportSpriteSheet,
    required this.onSendToGif,
    required this.onOpenInEditor,
    super.key,
  });

  final List<ApiConfig> apiConfigs;
  final ApiConfig selectedApiConfig;
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
  final String? errorMessage;
  final ImageRequestDebugRecord? debugRecord;
  final List<GeneratedImage> generatedImages;
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
  final ValueChanged<Uint8List> onExportSpriteSheet;
  final ValueChanged<SpriteSheetPreviewData> onSendToGif;
  final ValueChanged<SpriteSheetPreviewData> onOpenInEditor;

  @override
  Widget build(BuildContext context) {
    return WorkspacePage(
      title: '帧动画生成',
      description: '一次生成完整 Sprite Sheet，再按行列切片预览动作连续性',
      children: [
        ResponsiveWorkspaceSplit(
          controls: FrameAnimationPanel(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfig.id,
            providerKind: selectedApiConfig.providerKind,
            model: selectedApiConfig.model,
            imageSizeCapabilityOverride:
                selectedApiConfig.imageSizeCapabilityOverride,
            promptController: promptController,
            negativePromptController: negativePromptController,
            size: size,
            rows: rows,
            columns: columns,
            gridSpec: gridSpec,
            templateImagePath: templateImagePath,
            advancedSettings: advancedSettings,
            userController: userController,
            isGenerating: isGenerating,
            onApiConfigChanged: onApiConfigChanged,
            onOpenApiSettings: onOpenApiSettings,
            onSizeChanged: onSizeChanged,
            onRowsChanged: onRowsChanged,
            onColumnsChanged: onColumnsChanged,
            onGridSpecChanged: onGridSpecChanged,
            onAdvancedSettingsChanged: onAdvancedSettingsChanged,
            onPickTemplateImage: onPickTemplateImage,
            onClearTemplateImage: onClearTemplateImage,
            onGenerate: onGenerate,
          ),
          preview: FrameAnimationPreviewPanel(
            title: 'Sprite Sheet 预览',
            emptyMessage: '生成后的整张 Sprite Sheet 会显示在这里',
            errorMessage: errorMessage,
            debugRecord: debugRecord,
            generatedImages: generatedImages,
            isGenerating: isGenerating,
            rows: rows,
            columns: columns,
            gridSpec: gridSpec,
            labelBuilder: (index) =>
                animationFrameGridLabel(index, columns: columns),
            onRetry: onGenerate,
            onExportSpriteSheet: onExportSpriteSheet,
            onSendToGif: onSendToGif,
            onOpenInEditor: onOpenInEditor,
          ),
        ),
      ],
    );
  }
}
