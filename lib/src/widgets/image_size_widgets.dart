import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../theme/layout_constants.dart';
import '../utils/image_dimensions.dart';
import 'common_form_widgets.dart';

const String _customSizeValue = '__custom_pixels__';

enum _ImagePresetOrientation { square, landscape, portrait }

class ImageSizeInput extends StatefulWidget {
  const ImageSizeInput({
    required this.size,
    required this.providerKind,
    required this.model,
    required this.capabilityOverride,
    required this.onChanged,
    this.compact = false,
    this.enabled = true,
    this.onValidityChanged,
    super.key,
  });

  final String size;
  final ApiProviderKind providerKind;
  final String model;
  final ImageSizeCapabilityOverride capabilityOverride;
  final ValueChanged<String> onChanged;
  final bool compact;
  final bool enabled;
  final ValueChanged<bool>? onValidityChanged;

  @override
  State<ImageSizeInput> createState() => _ImageSizeInputState();
}

class _ImageSizeInputState extends State<ImageSizeInput> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    final dimensions = imageDimensionsFromSize(widget.size);
    _widthController = TextEditingController(text: dimensions.width.toString());
    _heightController = TextEditingController(
      text: dimensions.height.toString(),
    );
    _selectedValue = _selectedValueFor(widget.size);
    _notifyValidity();
  }

  @override
  void didUpdateWidget(covariant ImageSizeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size == widget.size &&
        oldWidget.providerKind == widget.providerKind &&
        oldWidget.model == widget.model &&
        oldWidget.capabilityOverride == widget.capabilityOverride) {
      return;
    }

    final dimensions = tryParseImageDimensions(widget.size);
    if (dimensions != null) {
      _setControllerText(_widthController, dimensions.width.toString());
      _setControllerText(_heightController, dimensions.height.toString());
    }
    _selectedValue = _selectedValueFor(widget.size);
    _notifyValidity();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = imageModelCapabilitiesFor(
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    final validation = validateImageSizeForModel(
      size: widget.size,
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    final isCustom = _selectedValue == _customSizeValue;
    final picker = capabilities.allowsCustomPixels
        ? _customPixelPresetPicker(capabilities)
        : _presetPicker(capabilities);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        picker,
        if (isCustom) ...[
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: _customSideInput(controller: _widthController, label: '宽度'),
            second: _customSideInput(
              controller: _heightController,
              label: '高度',
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          _buildHelperText(capabilities, validation),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: validation.isValid
                ? null
                : Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _presetPicker(ImageModelCapabilities capabilities) {
    return DropdownButtonFormField<String>(
      key: ValueKey(
        '${widget.providerKind}:${widget.model}:'
        '${widget.capabilityOverride}:$_selectedValue',
      ),
      decoration: InputDecoration(labelText: _pickerLabel(capabilities)),
      initialValue: _selectedValue,
      items: [
        for (final preset in capabilities.presets)
          DropdownMenuItem<String>(
            value: preset.size,
            child: Text('${preset.label} · ${preset.size}'),
          ),
        if (capabilities.allowsCustomPixels)
          const DropdownMenuItem<String>(
            value: _customSizeValue,
            child: Text('自定义尺寸'),
          ),
      ],
      onChanged: widget.enabled
          ? (value) {
              if (value != null) {
                _applySelection(value);
              }
            }
          : null,
    );
  }

  Widget _customPixelPresetPicker(ImageModelCapabilities capabilities) {
    final scaleValues = _scaleValuesFor(capabilities);
    final selectedPreset = _selectedPresetFor(capabilities);
    final selectedScale = _selectedValue == _customSizeValue
        ? _customSizeValue
        : selectedPreset == null
        ? scaleValues.first
        : _scaleLabelForPreset(selectedPreset);
    final availableOrientations = selectedScale == _customSizeValue
        ? <_ImagePresetOrientation>[]
        : _orientationsForScale(capabilities, selectedScale);
    final selectedOrientation =
        selectedPreset == null || availableOrientations.isEmpty
        ? null
        : _orientationForDimensions(selectedPreset.dimensions);

    final scaleDropdown = DropdownButtonFormField<String>(
      key: ValueKey(
        '${widget.providerKind}:${widget.model}:'
        '${widget.capabilityOverride}:scale:$selectedScale',
      ),
      decoration: const InputDecoration(labelText: '尺寸档位'),
      initialValue: selectedScale,
      items: [
        for (final scale in scaleValues)
          DropdownMenuItem<String>(value: scale, child: Text(scale)),
        const DropdownMenuItem<String>(
          value: _customSizeValue,
          child: Text('自定义尺寸'),
        ),
      ],
      onChanged: widget.enabled
          ? (value) {
              if (value != null) {
                _applyScaleSelection(value);
              }
            }
          : null,
    );

    if (selectedScale == _customSizeValue) {
      return scaleDropdown;
    }

    final orientationDropdown =
        DropdownButtonFormField<_ImagePresetOrientation>(
          key: ValueKey(
            '${widget.providerKind}:${widget.model}:'
            '${widget.capabilityOverride}:orientation:$selectedScale:'
            '$selectedOrientation',
          ),
          decoration: const InputDecoration(labelText: '方向'),
          initialValue: selectedOrientation,
          items: [
            for (final orientation in availableOrientations)
              DropdownMenuItem<_ImagePresetOrientation>(
                value: orientation,
                child: Text(_orientationLabel(orientation)),
              ),
          ],
          onChanged: !widget.enabled || availableOrientations.length <= 1
              ? null
              : (orientation) {
                  if (orientation != null) {
                    _applyOrientationSelection(selectedScale, orientation);
                  }
                },
        );

    return ResponsivePair(first: scaleDropdown, second: orientationDropdown);
  }

  List<String> _scaleValuesFor(ImageModelCapabilities capabilities) {
    final scales = <String>[];
    for (final preset in capabilities.presets) {
      final scale = _scaleLabelForPreset(preset);
      if (!scales.contains(scale)) {
        scales.add(scale);
      }
    }
    return scales;
  }

  List<_ImagePresetOrientation> _orientationsForScale(
    ImageModelCapabilities capabilities,
    String scale,
  ) {
    final orientations = <_ImagePresetOrientation>[];
    for (final preset in capabilities.presets) {
      if (_scaleLabelForPreset(preset) != scale) {
        continue;
      }
      final orientation = _orientationForDimensions(preset.dimensions);
      if (!orientations.contains(orientation)) {
        orientations.add(orientation);
      }
    }
    return orientations;
  }

  ImageSizePreset? _selectedPresetFor(ImageModelCapabilities capabilities) {
    final dimensions = tryParseImageDimensions(widget.size);
    if (dimensions == null) {
      return null;
    }
    return exactImageSizePresetForDimensions(
      dimensions,
      presets: capabilities.presets,
    );
  }

  ImageSizePreset _presetForScaleAndOrientation({
    required ImageModelCapabilities capabilities,
    required String scale,
    required _ImagePresetOrientation orientation,
  }) {
    return capabilities.presets.firstWhere(
      (preset) =>
          _scaleLabelForPreset(preset) == scale &&
          _orientationForDimensions(preset.dimensions) == orientation,
      orElse: () => capabilities.presets.firstWhere(
        (preset) => _scaleLabelForPreset(preset) == scale,
        orElse: () => capabilities.presets.first,
      ),
    );
  }

  void _applyScaleSelection(String scale) {
    if (scale == _customSizeValue) {
      setState(() => _selectedValue = scale);
      _commitCustomSize();
      return;
    }

    final capabilities = imageModelCapabilitiesFor(
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    final currentPreset = _selectedPresetFor(capabilities);
    final currentOrientation = currentPreset == null
        ? _orientationsForScale(capabilities, scale).first
        : _orientationForDimensions(currentPreset.dimensions);
    final preset = _presetForScaleAndOrientation(
      capabilities: capabilities,
      scale: scale,
      orientation: currentOrientation,
    );
    _applyPreset(preset);
  }

  void _applyOrientationSelection(
    String scale,
    _ImagePresetOrientation orientation,
  ) {
    final capabilities = imageModelCapabilitiesFor(
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    final preset = _presetForScaleAndOrientation(
      capabilities: capabilities,
      scale: scale,
      orientation: orientation,
    );
    _applyPreset(preset);
  }

  void _applyPreset(ImageSizePreset preset) {
    setState(() {
      _selectedValue = preset.size;
      _setControllerText(_widthController, preset.dimensions.width.toString());
      _setControllerText(
        _heightController,
        preset.dimensions.height.toString(),
      );
    });
    widget.onChanged(preset.size);
    _notifyValidityForSize(preset.size);
  }

  String _scaleLabelForPreset(ImageSizePreset preset) {
    final label = preset.label.trim();
    final separatorIndex = label.indexOf(' ');
    if (separatorIndex <= 0) {
      return label;
    }
    return label.substring(0, separatorIndex);
  }

  _ImagePresetOrientation _orientationForDimensions(
    ImageDimensions dimensions,
  ) {
    if (dimensions.width == dimensions.height) {
      return _ImagePresetOrientation.square;
    }
    return dimensions.width > dimensions.height
        ? _ImagePresetOrientation.landscape
        : _ImagePresetOrientation.portrait;
  }

  String _orientationLabel(_ImagePresetOrientation orientation) {
    return switch (orientation) {
      _ImagePresetOrientation.square => '方图',
      _ImagePresetOrientation.landscape => '横图',
      _ImagePresetOrientation.portrait => '竖图',
    };
  }

  TextField _customSideInput({
    required TextEditingController controller,
    required String label,
  }) {
    final constraints =
        imageModelCapabilitiesFor(
          providerKind: widget.providerKind,
          model: widget.model,
          capabilityOverride: widget.capabilityOverride,
        ).constraints ??
        gptImage2SizeConstraints;
    return TextField(
      controller: controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(constraints.maxSide.toString().length),
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText:
            '${constraints.minSide}-${constraints.maxSide}，${constraints.step}px 倍数',
      ),
      onChanged: (_) => _commitCustomSize(),
    );
  }

  void _applySelection(String value) {
    if (value == _customSizeValue) {
      setState(() => _selectedValue = value);
      _commitCustomSize();
      return;
    }

    final capabilities = imageModelCapabilitiesFor(
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    final preset = capabilities.presets.firstWhere(
      (preset) => preset.size == value,
      orElse: () => nearestImageSizePresetInList(
        dimensions: imageDimensionsFromSize(value),
        presets: capabilities.presets,
      ),
    );
    setState(() {
      _selectedValue = preset.size;
      _setControllerText(_widthController, preset.dimensions.width.toString());
      _setControllerText(
        _heightController,
        preset.dimensions.height.toString(),
      );
    });
    widget.onChanged(preset.size);
    _notifyValidityForSize(preset.size);
  }

  void _commitCustomSize() {
    final size =
        '${_widthController.text.trim()}x${_heightController.text.trim()}';
    widget.onChanged(size);
    _notifyValidityForSize(size);
  }

  String _buildHelperText(
    ImageModelCapabilities capabilities,
    ImageSizeValidationResult validation,
  ) {
    if (!validation.isValid) {
      return validation.message ?? '当前图片尺寸无效。';
    }

    final dimensions = validation.dimensions!;
    final preset = exactImageSizePresetForDimensions(
      dimensions,
      presets: capabilities.presets,
    );
    final fallbackLabel = imageAspectName(dimensions.width, dimensions.height);
    if (capabilities.sizeMode == ImageSizeMode.aspectRatio) {
      final aspectRatio = geminiAspectRatioForDimensions(dimensions);
      return '${preset?.label ?? fallbackLabel} · Gemini 画幅比例 $aspectRatio';
    }

    if (capabilities.allowsCustomPixels && preset == null) {
      return '自定义尺寸 · 请求尺寸 ${dimensions.size}';
    }

    return '${preset?.label ?? '固定分辨率'} · 请求尺寸 ${dimensions.size}';
  }

  String _pickerLabel(ImageModelCapabilities capabilities) {
    return switch (capabilities.sizeMode) {
      ImageSizeMode.customPixels => '分辨率',
      ImageSizeMode.aspectRatio => '画幅比例',
      ImageSizeMode.fixedPresets => '分辨率档位',
    };
  }

  String _selectedValueFor(String size) {
    final capabilities = imageModelCapabilitiesFor(
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    final dimensions = tryParseImageDimensions(size);
    final preset = dimensions == null
        ? null
        : exactImageSizePresetForDimensions(
            dimensions,
            presets: capabilities.presets,
          );
    if (preset != null) {
      return preset.size;
    }
    if (capabilities.allowsCustomPixels) {
      return _customSizeValue;
    }
    return nearestImageSizePresetInList(
      dimensions: imageDimensionsFromSize(size),
      presets: capabilities.presets,
    ).size;
  }

  void _notifyValidity() {
    _notifyValidityForSize(widget.size);
  }

  void _notifyValidityForSize(String size) {
    final validation = validateImageSizeForModel(
      size: size,
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    widget.onValidityChanged?.call(validation.isValid);
  }

  static void _setControllerText(
    TextEditingController controller,
    String value,
  ) {
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

String imageAspectName(int width, int height) {
  if (width == height) {
    return '方图';
  }
  return width > height ? '横图' : '竖图';
}
