import 'package:flutter/material.dart';

import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../models/image_advanced_settings.dart';
import '../theme/layout_constants.dart';
import '../widgets/api_settings_widgets.dart';
import '../widgets/common_form_widgets.dart';
import '../widgets/image_advanced_settings_widgets.dart';
import '../widgets/image_size_widgets.dart';
import '../widgets/layout_navigation_widgets.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.providerKind,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.imageCount,
    required this.advancedSettings,
    required this.userController,
    required this.isGenerating,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onImageCountChanged,
    required this.onAdvancedSettingsChanged,
    required this.onGenerate,
    super.key,
  });

  final List<ApiConfig> apiConfigs;
  final String selectedApiConfigId;
  final ApiProviderKind providerKind;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final bool isGenerating;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onImageCountChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: '生成配置',
      child: Column(
        children: [
          ApiConfigSelector(
            apiConfigs: apiConfigs,
            selectedApiConfigId: selectedApiConfigId,
            onChanged: onApiConfigChanged,
            onOpenSettings: onOpenApiSettings,
          ),
          const SizedBox(height: fieldGap),
          TextField(
            controller: promptController,
            minLines: 5,
            maxLines: 9,
            decoration: const InputDecoration(
              labelText: '正向提示词',
              hintText: '描述你想生成的图片',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: fieldGap),
          TextField(
            controller: negativePromptController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '负向提示词',
              hintText: '会合并到 prompt 中，不额外发送非 OpenAI 字段',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: fieldGap),
          ImageSizeInput(
            size: size,
            providerKind: providerKind,
            onChanged: onSizeChanged,
          ),
          const SizedBox(height: fieldGap),
          ImageAdvancedSettingsSection(
            settings: advancedSettings,
            userController: userController,
            hasTemplateImage: false,
            onChanged: onAdvancedSettingsChanged,
          ),
          const SizedBox(height: fieldGap),
          OptionDropdown<int>(
            label: '数量',
            value: imageCount,
            options: const [1, 2, 3, 4],
            labelBuilder: (value) => '$value 张',
            onChanged: onImageCountChanged,
          ),
          const SizedBox(height: sectionGap),
          PrimaryActionButton(
            onPressed: isGenerating ? null : onGenerate,
            icon: Icons.auto_awesome,
            label: '生成图片',
            busyLabel: '生成中',
            isBusy: isGenerating,
          ),
        ],
      ),
    );
  }
}

class FrameAnimationPanel extends StatelessWidget {
  const FrameAnimationPanel({
    required this.apiConfigs,
    required this.selectedApiConfigId,
    required this.providerKind,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.rows,
    required this.columns,
    required this.templateImagePath,
    required this.advancedSettings,
    required this.userController,
    required this.isGenerating,
    required this.onApiConfigChanged,
    required this.onOpenApiSettings,
    required this.onSizeChanged,
    required this.onRowsChanged,
    required this.onColumnsChanged,
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
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final int rows;
  final int columns;
  final String? templateImagePath;
  final ImageAdvancedSettings advancedSettings;
  final TextEditingController userController;
  final bool isGenerating;
  final ValueChanged<String> onApiConfigChanged;
  final VoidCallback onOpenApiSettings;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onRowsChanged;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<ImageAdvancedSettings> onAdvancedSettingsChanged;
  final VoidCallback onPickTemplateImage;
  final VoidCallback onClearTemplateImage;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final frameTotal = rows * columns;

    return AppPanel(
      title: '帧动画配置',
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
            decoration: const InputDecoration(
              labelText: '提示词内容',
              hintText: '把主体、场景、风格、动作变化写在这里即可',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: fieldGap),
          TextField(
            controller: negativePromptController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '负向提示词',
              hintText: '会应用到每一帧',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: fieldGap),
          ImageSizeInput(
            size: size,
            providerKind: providerKind,
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
              label: '行数',
              value: rows,
              options: _gridSizes,
              labelBuilder: (value) => '$value 行',
              onChanged: onRowsChanged,
            ),
            second: OptionDropdown<int>(
              label: '列数',
              value: columns,
              options: _gridSizes,
              labelBuilder: (value) => '$value 列',
              helperText:
                  '生成 1 张 $rows x $columns 的 Sprite Sheet，共 $frameTotal 格',
              onChanged: onColumnsChanged,
            ),
          ),
          const SizedBox(height: sectionGap),
          PrimaryActionButton(
            onPressed: isGenerating ? null : onGenerate,
            icon: Icons.movie_filter_outlined,
            label: '生成 Sprite Sheet',
            busyLabel: '生成 Sprite Sheet 中',
            isBusy: isGenerating,
          ),
        ],
      ),
    );
  }
}
