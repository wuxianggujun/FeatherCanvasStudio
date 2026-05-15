import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/api_provider.dart';
import '../theme/layout_constants.dart';
import '../utils/image_dimensions.dart';

enum _ImageAspectPreset { square, landscape, portrait, custom }

String _imageAspectPresetLabel(_ImageAspectPreset preset) {
  return switch (preset) {
    _ImageAspectPreset.square => '方图',
    _ImageAspectPreset.landscape => '横图',
    _ImageAspectPreset.portrait => '竖图',
    _ImageAspectPreset.custom => '自定义',
  };
}

class ImageSizeInput extends StatefulWidget {
  const ImageSizeInput({
    required this.size,
    required this.providerKind,
    required this.onChanged,
    this.compact = false,
    super.key,
  });

  final String size;
  final ApiProviderKind providerKind;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  State<ImageSizeInput> createState() => _ImageSizeInputState();
}

class _ImageSizeInputState extends State<ImageSizeInput> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late _ImageAspectPreset _preset;

  @override
  void initState() {
    super.initState();
    final dimensions = imageDimensionsFromSize(widget.size);
    _widthController = TextEditingController(text: dimensions.width.toString());
    _heightController = TextEditingController(
      text: dimensions.height.toString(),
    );
    _preset = _presetFromDimensions(dimensions);
  }

  @override
  void didUpdateWidget(covariant ImageSizeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size == widget.size) {
      return;
    }

    final dimensions = imageDimensionsFromSize(widget.size);
    final widthText = dimensions.width.toString();
    final heightText = dimensions.height.toString();
    if (_widthController.text != widthText) {
      _widthController.value = TextEditingValue(
        text: widthText,
        selection: TextSelection.collapsed(offset: widthText.length),
      );
    }
    if (_heightController.text != heightText) {
      _heightController.value = TextEditingValue(
        text: heightText,
        selection: TextSelection.collapsed(offset: heightText.length),
      );
    }
    _preset = _presetFromDimensions(dimensions);
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = int.tryParse(_widthController.text);
    final height = int.tryParse(_heightController.text);
    final helperText = _buildHelperText(width, height);

    final aspectPicker = DropdownButtonFormField<_ImageAspectPreset>(
      decoration: const InputDecoration(labelText: '画幅'),
      initialValue: _preset,
      items: [
        for (final preset in _ImageAspectPreset.values)
          DropdownMenuItem<_ImageAspectPreset>(
            value: preset,
            child: Text(_imageAspectPresetLabel(preset)),
          ),
      ],
      onChanged: (value) {
        if (value != null) {
          _applyPreset(value);
        }
      },
    );

    final widthInput = TextField(
      controller: _widthController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(labelText: '宽度'),
      onChanged: (_) => _commitManualSize(),
    );
    final heightInput = TextField(
      controller: _heightController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(labelText: '高度'),
      onChanged: (_) => _commitManualSize(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.compact) ...[
          aspectPicker,
          const SizedBox(height: fieldGap),
          ResponsivePair(first: widthInput, second: heightInput),
        ] else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 520) {
                return Column(
                  children: [
                    aspectPicker,
                    const SizedBox(height: fieldGap),
                    ResponsivePair(first: widthInput, second: heightInput),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: aspectPicker),
                  const SizedBox(width: fieldGap),
                  Expanded(child: widthInput),
                  const SizedBox(width: fieldGap),
                  Expanded(child: heightInput),
                ],
              );
            },
          ),
        const SizedBox(height: 6),
        Text(helperText, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _applyPreset(_ImageAspectPreset preset) {
    final next = switch (preset) {
      _ImageAspectPreset.square => const ImageDimensions(1024, 1024),
      _ImageAspectPreset.landscape => const ImageDimensions(1536, 1024),
      _ImageAspectPreset.portrait => const ImageDimensions(1024, 1536),
      _ImageAspectPreset.custom => _readCurrentDimensions(),
    };

    setState(() {
      _preset = preset;
      _widthController.text = next.width.toString();
      _heightController.text = next.height.toString();
    });
    widget.onChanged(next.size);
  }

  void _commitManualSize() {
    final width = int.tryParse(_widthController.text);
    final height = int.tryParse(_heightController.text);
    if (width == null || height == null || width <= 0 || height <= 0) {
      setState(() => _preset = _ImageAspectPreset.custom);
      return;
    }

    final dimensions = ImageDimensions(width, height);
    setState(() => _preset = _ImageAspectPreset.custom);
    widget.onChanged(dimensions.size);
  }

  ImageDimensions _readCurrentDimensions() {
    final width = int.tryParse(_widthController.text);
    final height = int.tryParse(_heightController.text);
    if (width == null || height == null || width <= 0 || height <= 0) {
      return const ImageDimensions(
        openAIDefaultImageSide,
        openAIDefaultImageSide,
      );
    }
    return ImageDimensions(width, height);
  }

  _ImageAspectPreset _presetFromDimensions(ImageDimensions dimensions) {
    if (dimensions == const ImageDimensions(1024, 1024)) {
      return _ImageAspectPreset.square;
    }
    if (dimensions == const ImageDimensions(1536, 1024)) {
      return _ImageAspectPreset.landscape;
    }
    if (dimensions == const ImageDimensions(1024, 1536)) {
      return _ImageAspectPreset.portrait;
    }
    return _ImageAspectPreset.custom;
  }

  String _buildHelperText(int? width, int? height) {
    if (width == null || height == null || width <= 0 || height <= 0) {
      return '请输入有效的宽度和高度';
    }

    final dimensions = ImageDimensions(width, height);
    final aspectName = imageAspectName(width, height);
    if (widget.providerKind == ApiProviderKind.gemini) {
      final aspectRatio = geminiAspectRatioForDimensions(dimensions);
      return '$aspectName · Gemini 画幅比例 $aspectRatio';
    }

    final requestDimensions = normalizeOpenAIImageDimensions(dimensions);
    if (requestDimensions == dimensions) {
      return '$aspectName · 请求尺寸 ${requestDimensions.size}';
    }

    return '$aspectName · 输入值保持 ${dimensions.size}，'
        '生成时请求 ${requestDimensions.size}';
  }
}

String imageAspectName(int width, int height) {
  if (width == height) {
    return '方图';
  }
  return width > height ? '横图' : '竖图';
}

class ResponsivePair extends StatelessWidget {
  const ResponsivePair({required this.first, required this.second, super.key});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              first,
              const SizedBox(height: fieldGap),
              second,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: fieldGap),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
